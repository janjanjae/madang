#!/usr/bin/env bash
# team-context — 프로젝트의 팀 문서(.claude/ 의 TASKS.md·PROGRESS.md·team/·archive/)를
# 비공개 레포의 "프로젝트별 브랜치"로 기기 간에 옮긴다. 앱 레포에는 심링크만 남고 그 링크는 exclude된다.
#
#   team-context.sh status [--check]   동기화 상태 판정 (종료 코드가 상태)
#   team-context.sh init   [--yes]     이 프로젝트를 연결 (원격 브랜치가 있으면 clone, 없으면 현재 문서로 orphan 생성)
#   team-context.sh push               변경을 커밋해 원격으로 (원격이 앞서거나 분기면 거부)
#   team-context.sh pull               원격 변경을 fast-forward로 가져옴 (분기면 거부)
#
# 공통 옵션: --app PATH(앱 레포, 기본=현재 위치의 레포 루트) --project NAME(브랜치명, 기본=앱 레포 폴더명)
#            --yes(확인 질문 자동 y — 비대화형은 이게 없으면 파괴적 동작 안 함)
#
# 설정 (특정 인프라 이름은 코드에 없다 — 전부 사용자 설정):
#   원격 URL : 환경변수 TEAM_CONTEXT_REMOTE, 없으면 ~/.claude/madang-team-remote 의 첫 줄
#   베이스   : 환경변수 TEAM_CONTEXT_BASE (기본 ~/team-context) — 클론은 <베이스>/<프로젝트>/ 에 놓인다
#
# 종료 코드(status): 0 동기화됨 · 10 원격이 앞섬(pull 필요) · 11 로컬이 앞섬(push 필요) · 12 분기
#                    · 20 설정 없음 · 21 이 프로젝트 미연결 · 22 판정 불가(오프라인 등)
#   그 외: 1 실행 중 실패/취소 · 2 사용법 오류. init/push/pull도 같은 코드를 쓴다(20·21·22).
#
# 원칙: 덮어쓰지 않는다. 링크 자리의 실파일은 지우지 않고 .claude/.pre-link-<시각>/ 로 옮긴다.
set -uo pipefail

ITEM_DIRS=(team archive)
ITEM_FILES=(TASKS.md PROGRESS.md)
IMG_PATTERNS=('*.png' '*.jpg' '*.jpeg' '*.gif' '*.webp' '*.heic' '*.bmp' '*.ico' '*.tiff')
MAX_BYTES=1048576

YES=0 CHECK=0 APP="" PROJECT=""

say()  { echo "team-context: $*"; }
err()  { echo "team-context: $*" >&2; }

ask() { # ask "질문" → 0=yes
  if [ "$YES" = 1 ]; then echo "$1 [y/N] y (--yes)"; return 0; fi
  if [ ! -t 0 ]; then echo "$1 [y/N] → 비대화형이라 n (--yes로 허용)"; return 1; fi
  local a; read -r -p "$1 [y/N] " a; [ "$a" = y ] || [ "$a" = Y ]
}

# ── 설정 해석 ───────────────────────────────────────────────────────────────
load_config() {
  REMOTE="${TEAM_CONTEXT_REMOTE:-}"
  if [ -z "$REMOTE" ] && [ -f "$HOME/.claude/madang-team-remote" ]; then
    REMOTE="$(head -1 "$HOME/.claude/madang-team-remote" | tr -d '\r')"
  fi
  [ -n "$REMOTE" ] || return 1
  BASE="${TEAM_CONTEXT_BASE:-$HOME/team-context}"
  return 0
}

# 앱 레포 루트: 워크트리 안에서 불러도 메인 체크아웃을 가리키게 git-common-dir 기준으로 푼다.
resolve_app() {
  local start="${APP:-$PWD}" d
  git -C "$start" rev-parse --git-dir >/dev/null 2>&1 || { err "git 레포가 아니다: $start (--app PATH 로 지정)"; return 1; }
  d="$(git -C "$start" rev-parse --git-common-dir)"
  case "$d" in /*) ;; *) d="$start/$d" ;; esac
  COMMON="$(cd "$d" && pwd -P)"
  if [ "$(basename "$COMMON")" = ".git" ]; then APP="$(dirname "$COMMON")"; else APP="$(cd "$start" && git rev-parse --show-toplevel)"; fi
  [ -n "$PROJECT" ] || PROJECT="$(basename "$APP")"
  CLONE="$BASE/$PROJECT"
  CLAUDE="$APP/.claude"
  return 0
}

CG() { git -C "$CLONE" "$@"; }

is_cloned() { [ -d "$CLONE/.git" ]; }
is_linked() { is_cloned && [ -L "$CLAUDE/team" ] && [ "$(readlink "$CLAUDE/team")" = "$CLONE/team" ]; }

# 이 기기에 커밋 신원이 없어도 커밋·push가 되게(클론 한정 -c, 전역 설정은 건드리지 않는다).
# 신원은 <사용자>@<호스트> 로 조립한다 — 빈 orphan 커밋도 같은 경로를 쓴다.
commit_with_identity() { # commit_with_identity <msg> [commit 옵션...]
  local msg="$1"; shift
  local -a id=()
  [ -n "$(CG config user.email)" ] || id=(-c "user.name=${USER:-user}" -c "user.email=${USER:-user}@$(hostname -s)")
  CG ${id[@]+"${id[@]}"} commit -q -m "$msg" "$@"      # macOS bash 3.2: set -u + 빈 배열 전개 보호
}

# ── push 제외 규칙: 이미지 + 1MB 초과 파일(클론 로컬 exclude에 블록으로 유지) ──────────
refresh_excludes() {
  local ex="$CLONE/.git/info/exclude" tmp; mkdir -p "$CLONE/.git/info"
  tmp="$(mktemp -t team-context-ex.XXXXXX)"
  [ -f "$ex" ] && awk '/^# team-context:begin/{skip=1} !skip{print} /^# team-context:end/{skip=0}' "$ex" > "$tmp"
  {
    echo "# team-context:begin (자동 생성 — 이미지·${MAX_BYTES}바이트 초과 파일은 동기화하지 않는다)"
    printf '%s\n' "${IMG_PATTERNS[@]}"
    ( cd "$CLONE" && find . -name .git -prune -o -type f -size +"${MAX_BYTES}"c -print ) \
      | sed 's|^\./|/|; s/[][*?\\]/\\&/g'
    echo "# team-context:end"
  } >> "$tmp"
  mv "$tmp" "$ex"
}

counts() { # → AHEAD BEHIND DIRTY (fetch 성공 전제)
  read -r AHEAD BEHIND < <(CG rev-list --left-right --count "HEAD...origin/$PROJECT" 2>/dev/null || echo "0 0")
  DIRTY="$(CG status --porcelain | wc -l | tr -d ' ')"
}

# 상태를 STATE/CODE/MSG에 계산한다 (원격 fetch 포함)
judge() {
  if ! load_config; then STATE=noconfig CODE=20; MSG="설정 없음 — 원격 URL을 ~/.claude/madang-team-remote 한 줄 또는 TEAM_CONTEXT_REMOTE 로 지정"; return; fi
  resolve_app || { STATE=error CODE=1; MSG="앱 레포를 못 찾음"; return; }
  if ! is_linked; then STATE=unlinked CODE=21; MSG="이 프로젝트($PROJECT)는 아직 연결되지 않았다 — team-context init"; return; fi
  refresh_excludes
  if ! CG fetch -q origin "$PROJECT" 2>/dev/null; then STATE=offline CODE=22; MSG="판정 불가 — 원격에 접근할 수 없다(오프라인·권한·브랜치 삭제)"; return; fi
  counts
  if   [ "$BEHIND" -gt 0 ] && { [ "$AHEAD" -gt 0 ] || [ "$DIRTY" -gt 0 ]; }; then STATE=diverged CODE=12; MSG="분기 — 원격 +$BEHIND, 로컬 커밋 +$AHEAD, 미커밋 ${DIRTY}건. 한쪽을 먼저 정리해야 한다(자동 병합 안 함)"
  elif [ "$BEHIND" -gt 0 ];                                                       then STATE=behind   CODE=10; MSG="원격이 앞섬 (+$BEHIND) — team-context pull"
  elif [ "$AHEAD" -gt 0 ] || [ "$DIRTY" -gt 0 ];                                  then STATE=ahead    CODE=11; MSG="로컬이 앞섬 (미push 커밋 $AHEAD, 미커밋 ${DIRTY}건) — team-context push"
  else STATE=current CODE=0; MSG="동기화됨"; fi
}

# 사람이 읽는 변경 목록 — 올라갈 것(로컬) / 내려올 것(원격). /checkpoint 문서가 이 출력에 기댄다.
show_changes() {
  local out
  if [ "$BEHIND" -gt 0 ]; then
    echo "  원격에서 바뀐 파일 (pull 하면 들어옴):"
    CG diff --name-status "HEAD...origin/$PROJECT" | sed 's/^/    /'
  fi
  if [ "$AHEAD" -gt 0 ]; then
    echo "  로컬 커밋에서 바뀐 파일 (push 하면 올라감):"
    CG diff --name-status "origin/$PROJECT...HEAD" | sed 's/^/    /'
  fi
  if [ "$DIRTY" -gt 0 ]; then
    echo "  미커밋 변경 (push 하면 함께 올라감):"
    CG status --porcelain | sed 's/^/    /'
  fi
}

cmd_status() {
  judge
  echo "상태: $MSG  [exit $CODE]"
  if [ "$CHECK" != 1 ]; then
    if [ "$STATE" != noconfig ] && [ -n "${PROJECT:-}" ]; then echo "프로젝트: $PROJECT · 클론: ${CLONE:-?}"; fi
    case "$STATE" in behind|ahead|diverged) show_changes ;; esac
  fi
  return "$CODE"
}

# ── init ───────────────────────────────────────────────────────────────────
# 항목별 동작: keep(이미 링크) | skip(소스가 없는 파일) | move-aside+link(실파일은 옮겨 둠) | link
# src_known: 소스 존재를 지금 알 수 있나(yes/no) — 원격에서 받기 전(clone 예정)에는 알 수 없어 unknown
plan_link() { # plan_link <item> <file|dir> <src_exists: yes|no|unknown>
  local item="$1" kind="$2" has="$3" src="$CLONE/$1" dst="$CLAUDE/$1" n
  if [ "$kind" = file ] && [ "$has" = no ]; then echo "skip(소스에 없음 — 문서가 생기면 init을 다시)"; return; fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then echo keep; return; fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    n="$(find -L "$dst" -type f 2>/dev/null | wc -l | tr -d ' ')"
    echo "move-aside+link (옮겨 둘 파일 ${n}개)"
  else echo link; fi
}

is_dir_item() { case " ${ITEM_DIRS[*]} " in *" $1 "*) return 0 ;; esac; return 1; }

cmd_init() {
  load_config || { err "설정 없음 — 원격 URL을 ~/.claude/madang-team-remote 한 줄 또는 TEAM_CONTEXT_REMOTE 로 지정"; return 20; }
  resolve_app || return 1
  local remote_has=no
  if is_cloned; then
    remote_has=cloned
  else
    local out
    out="$(git ls-remote --heads "$REMOTE" "refs/heads/$PROJECT" 2>/dev/null)" || { err "원격에 접근할 수 없다 — 판정 불가"; return 22; }
    [ -n "$out" ] && remote_has=yes
  fi

  echo "앱 레포 : $APP"
  echo "프로젝트: $PROJECT (원격 브랜치 이름)"
  echo "클론    : $CLONE"
  case "$remote_has" in
    cloned) echo "원격    : 이미 이 기기에 클론됨 — 링크만 확인" ;;
    yes)    echo "원격    : 브랜치 있음 → single-branch clone (다른 프로젝트 브랜치는 내려오지 않는다)" ;;
    no)     echo "원격    : 브랜치 없음 → 현재 .claude/ 문서로 orphan 브랜치를 만들어 push" ;;
  esac
  echo "링크 계획 (.claude/ ← 클론):"
  local item act any_move=0 has kind
  for item in "${ITEM_FILES[@]}" "${ITEM_DIRS[@]}"; do
    if is_dir_item "$item"; then kind=dir; else kind=file; fi
    case "$remote_has" in
      no)     if [ -e "$CLAUDE/$item" ]; then has=yes; else has=no; fi ;;     # 현재 로컬 문서가 소스
      cloned) if [ -e "$CLONE/$item" ]; then has=yes; else has=no; fi ;;
      *)      has=unknown ;;                                                  # 받기 전이라 모른다
    esac
    act="$(plan_link "$item" "$kind" "$has")"
    echo "    $item : $act"
    case "$act" in move-aside*) any_move=1 ;; esac
  done
  [ "$any_move" = 1 ] && echo "  ※ move-aside = 지우지 않고 $CLAUDE/.pre-link-<시각>/ 로 옮긴다"
  echo ""
  if ! ask "연결할까요?"; then echo "취소 — 아무것도 바꾸지 않았다."; return 1; fi

  # 1) 클론 확보
  mkdir -p "$BASE" || return 1
  case "$remote_has" in
    yes)
      # --no-local: 원격이 로컬 경로여도 객체 저장소를 통째로 복사(하드링크)하지 않고 전송 프로토콜로 받는다 —
        # 안 그러면 --single-branch여도 다른 프로젝트 브랜치의 객체(파일명 포함)가 .git/objects에 들어온다.
        git clone -q --single-branch --no-local --no-tags -b "$PROJECT" "$REMOTE" "$CLONE" || { err "clone 실패"; return 1; } ;;
    no)
      mkdir -p "$CLONE" && git -C "$CLONE" init -q && git -C "$CLONE" symbolic-ref HEAD "refs/heads/$PROJECT" || return 1
      for item in "${ITEM_FILES[@]}" "${ITEM_DIRS[@]}"; do
        # -H: 명령행의 심링크(예: team → 다른 폴더)는 내용을 따라 복사한다 — 빈 브랜치가 되는 걸 막는다
        if [ -e "$CLAUDE/$item" ]; then cp -RH "$CLAUDE/$item" "$CLONE/$item" || { err "복사 실패: $item"; return 1; }; fi
      done
      git -C "$CLONE" remote add -t "$PROJECT" origin "$REMOTE"   # 단일 브랜치 — 다른 프로젝트 브랜치를 fetch하지 않는다
      refresh_excludes
      CG add -A
      if [ -z "$(CG status --porcelain)" ]; then commit_with_identity "init: 빈 팀 문서" --allow-empty || return 1
      else commit_with_identity "init: $(hostname -s) $(date +%Y-%m-%d\ %H:%M)" || return 1; fi
      CG push -q -u origin "$PROJECT" || { err "push 실패 — 클론은 $CLONE 에 남아 있다"; return 22; } ;;
  esac
  refresh_excludes

  # 2) 링크 (실파일은 .pre-link 로 이동 — 삭제·덮어쓰기 없음)
  mkdir -p "$CLAUDE"
  local pre="$CLAUDE/.pre-link-$(date +%Y%m%d-%H%M%S)" moved=0
  for item in "${ITEM_FILES[@]}" "${ITEM_DIRS[@]}"; do
    if [ ! -e "$CLONE/$item" ]; then
      case " ${ITEM_DIRS[*]} " in *" $item "*) mkdir -p "$CLONE/$item" ;; *) echo "  skip   : $item (클론에 없음 — 문서가 생기면 init을 다시)"; continue ;; esac
    fi
    if [ -L "$CLAUDE/$item" ] && [ "$(readlink "$CLAUDE/$item")" = "$CLONE/$item" ]; then echo "  keep   : $item"; continue; fi
    if [ -e "$CLAUDE/$item" ] || [ -L "$CLAUDE/$item" ]; then
      mkdir -p "$pre" && mv "$CLAUDE/$item" "$pre/" || { err "이동 실패: $item"; return 1; }
      moved=$((moved + 1)); echo "  moved  : $item → ${pre#"$APP"/}/"
    fi
    ln -s "$CLONE/$item" "$CLAUDE/$item" && echo "  linked : .claude/$item → $CLONE/$item"
  done

  # 3) 앱 레포 exclude (공개 여부 무관하게 앱 레포엔 절대 안 올라간다)
  mkdir -p "$COMMON/info"
  local ex="$COMMON/info/exclude" pat
  for pat in .claude/TASKS.md .claude/PROGRESS.md .claude/team .claude/archive '.claude/.pre-link-*'; do
    grep -qxF -- "$pat" "$ex" 2>/dev/null || echo "$pat" >> "$ex"
  done
  echo "✅ 연결 완료 — 앱 레포 exclude 등록됨"
  [ "$moved" -gt 0 ] && echo "   옮겨 둔 원본: $pre (확인 후 직접 지워도 된다)"
  return 0
}

# 분기(12)로 push·pull을 거부할 때 붙이는 출구 안내 — 안내만 한다, 아무것도 자동 실행하지 않는다.
diverged_exit_help() {
  if [ "$DIRTY" -gt 0 ]; then
    err "  ↳ 미커밋 ${DIRTY}건: $CLONE 의 해당 파일을 다른 곳에 복사해 두고(git stash 대신 파일 복사 권장) 되돌린 뒤 team-context pull → 복사해 둔 내용을 다시 반영한다"
  fi
  if [ "$AHEAD" -gt 0 ]; then
    err "  ↳ 로컬 커밋 ${AHEAD}건: 어느 쪽을 살릴지 사람이 정한다 — 자동 병합 안 함"
  fi
}

cmd_push() {
  judge
  case "$STATE" in noconfig|unlinked|offline|error) err "$MSG"; return "$CODE" ;; esac
  case "$STATE" in
    behind)   err "원격이 앞선다 — 먼저 team-context pull"; return 10 ;;
    diverged) err "$MSG"; diverged_exit_help; return 12 ;;
    current)  say "변경 없음 — push할 것이 없다"; return 0 ;;
  esac
  if [ "$DIRTY" -gt 0 ]; then
    CG add -A
    if [ -z "$(CG diff --cached --name-only)" ]; then say "제외 규칙(이미지·1MB 초과)에 걸리는 변경뿐 — 커밋할 것이 없다"; else
      commit_with_identity "sync: $(hostname -s) $(date +%Y-%m-%d\ %H:%M)" || return 1
    fi
  fi
  CG push -q origin "HEAD:refs/heads/$PROJECT" || { err "push 실패"; return 22; }
  say "✅ push 완료 ($(CG rev-parse --short HEAD))"
  return 0
}

cmd_pull() {
  judge
  case "$STATE" in noconfig|unlinked|offline|error) err "$MSG"; return "$CODE" ;; esac
  case "$STATE" in
    diverged) err "$MSG"; diverged_exit_help; return 12 ;;
    ahead)    say "로컬이 앞선다 — pull할 것이 없다 (team-context push)"; return 0 ;;
    current)  say "이미 최신"; return 0 ;;
  esac
  if CG merge --ff-only -q "origin/$PROJECT"; then say "✅ pull 완료 (+$BEHIND, $(CG rev-parse --short HEAD))"; return 0; fi
  err "fast-forward 실패 — 미커밋 변경이 들어올 파일과 충돌한다. 변경을 push한 뒤 다시"; return 1
}

main() {
  local cmd="${1:-}"; shift || true
  local -a rest=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --yes|-y) YES=1 ;;
      --check) CHECK=1 ;;               # 판정 한 줄만(종료 코드가 곧 결과) — 변경 목록은 생략
      --app) shift; APP="${1:-}" ;;
      --project) shift; PROJECT="${1:-}" ;;
      -h|--help) awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) err "알 수 없는 옵션: $1"; exit 2 ;;
    esac
    shift
  done
  case "$cmd" in
    status) cmd_status ;;
    init)   cmd_init ;;
    push)   cmd_push ;;
    pull)   cmd_pull ;;
    -h|--help|help) awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) err "사용: team-context.sh status [--check] | init [--yes] | push | pull"; exit 2 ;;
  esac
}
main "$@"
exit $?
