#!/usr/bin/env bash
# update-madang — madang 로컬 클론을 origin과 비교해 안전하게 최신으로 맞춘다.
#
#   update-madang.sh [--check] [--yes] [--repo PATH]
#
#   (기본)   fetch → 판정 → behind면 fast-forward, diverged면 보존 백업 후 새 클론으로 교체(확인 필수)
#            → 마지막에 install.sh --dry-run 으로 심링크·힌트가 바뀔 항목을 보여주고 확인 후 적용
#   --check  판정만(아무것도 안 바꾼다). 종료 코드로 상태를 알린다 — 스킬·훅이 부른다.
#   --yes    확인 질문(y/N)에 자동 y. 비대화형(tty 없음)에서는 이게 없으면 파괴적 동작을 하지 않는다.
#   --repo   대상 클론. 기본은 이 스크립트가 들어 있는 레포.
#
# 종료 코드: 0 최신 · 10 behind(뒤처짐) · 11 diverged(갈라짐/히스토리 재작성) · 12 ahead(미push 커밋만)
#            · 20 판정 불가(origin 없음·오프라인·detached 등) · 1 실행 중 실패 · 2 사용법 오류
#
# 절차 근거: plans/release-runbook-v05.md §8 (사람이 손으로 하던 "로컬 레포를 공개본으로 교체")
#
# 첫 도입(닭과 달걀): 이 스크립트가 없는 낡은 클론은 update-madang 함수를 못 부른다. 이미 이 스크립트가
# 있는 다른 클론(또는 새로 받은 clone)의 것을 낡은 클론에 겨눠 실행한다:
#   bash <새 클론>/claude/tools/update/update-madang.sh --repo <낡은 클론> [--check]
# 교체가 끝나면 낡은 클론 자리에 새 클론이 들어서므로 이후엔 셸 함수 update-madang 을 쓴다.
#
# 교체(diverged) 후 로컬 전용 파일(.claude/ 팀 문서 등) 복원이 일부라도 빠지면 누락 목록을 출력하고
# 종료 코드 1로 끝난다(옛 클론은 백업 폴더에 그대로 있다).
set -uo pipefail

EXIT_OK=0 EXIT_BEHIND=10 EXIT_DIVERGED=11 EXIT_AHEAD=12 EXIT_UNKNOWN=20

CHECK=0 YES=0 REPO="" RESTORE_RC=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

die()  { echo "update-madang: $*" >&2; exit 1; }
unk()  { echo "update-madang: $*" >&2; exit $EXIT_UNKNOWN; }

ask() { # ask "질문" → 0=yes
  if [ "$YES" = 1 ]; then echo "$1 [y/N] y (--yes)"; return 0; fi
  if [ ! -t 0 ]; then echo "$1 [y/N] → 비대화형이라 n (--yes로 허용)"; return 1; fi
  local a; read -r -p "$1 [y/N] " a; [ "$a" = y ] || [ "$a" = Y ]
}

# 대상 클론의 위치(force-push 후에도 같은 경로여야 심링크가 산다)
resolve_repo() {
  [ -n "$REPO" ] || REPO="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  REPO="$(cd "$REPO" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null)" || unk "git 클론이 아니다"
}
G() { git -C "$REPO" "$@"; }

# ── 판정 ────────────────────────────────────────────────────────────────────
judge() {
  G remote get-url origin >/dev/null 2>&1 || unk "origin 리모트가 없다"
  BRANCH="$(G symbolic-ref --short -q HEAD)" || unk "detached HEAD — 브랜치로 돌아간 뒤 다시 실행"
  UPSTREAM="$(G rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || UPSTREAM=""
  G fetch --quiet origin 2>/dev/null || unk "git fetch 실패 — 오프라인이거나 접근 권한 없음"
  if [ -z "$UPSTREAM" ]; then
    G rev-parse -q --verify "origin/$BRANCH" >/dev/null || unk "'$BRANCH'의 upstream이 없다 (origin/$BRANCH 없음)"
    UPSTREAM="origin/$BRANCH"
  fi
  read -r AHEAD BEHIND < <(G rev-list --left-right --count "HEAD...$UPSTREAM")
  DIRTY="$(G status --porcelain | wc -l | tr -d ' ')"
  if   [ "$AHEAD" = 0 ] && [ "$BEHIND" = 0 ]; then STATE=current;  CODE=$EXIT_OK
  elif [ "$AHEAD" = 0 ];                      then STATE=behind;   CODE=$EXIT_BEHIND
  elif [ "$BEHIND" = 0 ];                     then STATE=ahead;    CODE=$EXIT_AHEAD
  else                                             STATE=diverged; CODE=$EXIT_DIVERGED; fi
  NOBASE=0; G merge-base HEAD "$UPSTREAM" >/dev/null 2>&1 || NOBASE=1
}

report_state() {
  echo "클론   : $REPO"
  echo "브랜치 : $BRANCH  ↔  $UPSTREAM"
  case "$STATE" in
    current)  echo "판정   : ✅ 최신 (up-to-date)" ;;
    behind)   echo "판정   : ⬇️  뒤처짐 (behind $BEHIND) — fast-forward 가능" ;;
    ahead)    echo "판정   : ⬆️  origin보다 앞섬 (미push 커밋 ${AHEAD}개)" ;;
    diverged)
      echo "판정   : 🔴 갈라짐 (diverged) — 로컬 앞 $AHEAD / 뒤 $BEHIND"
      [ "$NOBASE" = 1 ] && echo "         공통 조상 없음 → origin 히스토리가 재작성된 것 (merge/rebase 금지: 옛 커밋이 되살아난다)" ;;
  esac
  [ "$DIRTY" != 0 ] && echo "작업트리: 미커밋 변경 ${DIRTY}건"
  return 0
}

# ── 보존 대상 수집 ─────────────────────────────────────────────────────────
# 새 클론에 없는 로컬 전용 파일(untracked + gitignored). 워크트리·node_modules·큰 파일(>1MB) 제외.
collect_preserve() {
  PRESERVE_LIST="$(mktemp -t update-madang-preserve.XXXXXX)"
  {
    G ls-files -z -o --exclude-standard
    G ls-files -z -o -i --exclude-standard
  } | tr '\0' '\n' | sort -u | while IFS= read -r f; do
    case "$f" in .claude/worktrees/*|*/node_modules/*|node_modules/*|*/.build/*|.DS_Store|*/.DS_Store) continue ;; esac
    [ -f "$REPO/$f" ] || continue
    # 읽을 수 없는 파일은 크기를 못 재므로 "큰 파일"로 오분류돼 조용히 빠졌다 — 목록에 남겨 복원 단계에서 걸리게 한다.
    if [ -r "$REPO/$f" ] && [ "$(wc -c < "$REPO/$f")" -gt 1048576 ]; then echo "$f" >> "$PRESERVE_LIST.skipped"; continue; fi
    echo "$f"
  done > "$PRESERVE_LIST"
}

summarize_loss() {
  local n
  echo ""
  echo "── 교체 전 보존 현황 ──"
  n="$(G status --porcelain | wc -l | tr -d ' ')"
  echo "미커밋 변경      : ${n}건$([ "$n" != 0 ] && echo ' → uncommitted.patch + 상태 목록으로 백업')"
  [ "$n" != 0 ] && G status --porcelain | head -15 | sed 's/^/    /'
  echo "미push 커밋      : ${AHEAD}개 (origin에 없는 로컬 히스토리 → all.bundle로 백업)"
  G log --format='    %h %s' "$UPSTREAM..HEAD" 2>/dev/null | head -10
  local nb; nb="$(G for-each-ref --format='%(refname:short)' refs/heads | wc -l | tr -d ' ')"
  echo "로컬 브랜치      : ${nb}개 (전부 all.bundle에 들어간다 — 새 클론엔 기본 브랜치만 생긴다)"
  echo "stash            : $(G stash list | wc -l | tr -d ' ')개 (bundle에 포함)"
  local nw; nw="$(G worktree list | tail -n +2 | wc -l | tr -d ' ')"
  [ "$nw" != 0 ] && { echo "추가 워크트리    : ${nw}개 — 옛 클론(백업 폴더)에 그대로 남는다. 새 클론에선 다시 만들어야 한다:"; G worktree list | tail -n +2 | sed 's/^/    /'; }
  echo "로컬 전용 파일   : $(wc -l < "$PRESERVE_LIST" | tr -d ' ')개를 새 클론으로 복사 (.claude/ 팀 문서·gitignore된 설정 등)"
  grep -c . "$PRESERVE_LIST.skipped" >/dev/null 2>&1 && echo "    (1MB 초과로 복사 제외: $(wc -l < "$PRESERVE_LIST.skipped" | tr -d ' ')개 — 백업 폴더에서 직접 꺼낸다)"
  head -12 "$PRESERVE_LIST" | sed 's/^/    /'
  [ "$(wc -l < "$PRESERVE_LIST" | tr -d ' ')" -gt 12 ] && echo "    …"
}

# ── 교체 (diverged) ─────────────────────────────────────────────────────────
replace_clone() {
  local default url ts bak new art
  url="$(G remote get-url origin)"
  default="$(G ls-remote --symref origin HEAD 2>/dev/null | awk '/^ref:/ {sub("refs/heads/","",$2); print $2; exit}')"
  [ -n "$default" ] || die "origin의 기본 브랜치를 알 수 없다 — 교체를 중단한다"
  if [ "$BRANCH" != "$default" ]; then
    die "현재 브랜치($BRANCH)가 기본 브랜치($default)가 아니다 — 자동 교체는 기본 브랜치에서만 한다. 수동으로 처리하거나 '$default'로 돌아가 다시 실행."
  fi
  collect_preserve
  summarize_loss
  ts="$(date +%Y%m%d-%H%M%S)"
  bak="${REPO}.pre-update-$ts"
  new="${REPO}.update-new-$ts"
  echo ""
  echo "── 실행할 일 ──"
  echo "  1) origin에서 새로 clone → $new"
  echo "  2) 옛 클론 전체를 $bak 로 이동 (삭제 아님 — 최소 1주 보관)"
  echo "  3) 새 클론을 $REPO 자리에 둔다 (경로가 같아 심링크는 유지)"
  echo "  4) 로컬 전용 파일 복사 → install.sh (훅 설정 재적용)"
  echo "  ⚠️  이 셸의 현재 디렉토리가 $REPO 안이면 이동 후 'cd $REPO' 다시 해야 한다."
  echo ""
  if ! ask "교체할까요?"; then echo "취소 — 아무것도 바꾸지 않았다."; rm -f "$PRESERVE_LIST" "$PRESERVE_LIST.skipped"; exit 1; fi

  # 실패해도 옛 클론이 멀쩡하도록: 새 클론을 먼저 받고, 백업 산출물을 만든 뒤에야 이동한다.
  git clone --quiet "$url" "$new" || { rm -rf "$new"; die "새 clone 실패 — 아무것도 바꾸지 않았다"; }
  art="$REPO/.git/update-madang-backup"
  mkdir -p "$art"
  G bundle create "$art/all.bundle" --all >/dev/null 2>&1 || { rm -rf "$new"; die "bundle 백업 실패 — 아무것도 바꾸지 않았다"; }
  G diff HEAD --binary > "$art/uncommitted.patch" 2>/dev/null
  G status --porcelain > "$art/status.txt"
  G log --format='%H %s' "$UPSTREAM..HEAD" > "$art/unpushed.txt" 2>/dev/null
  G stash list > "$art/stash.txt"
  cp "$PRESERVE_LIST" "$art/preserved-files.txt"

  mv "$REPO" "$bak" || { rm -rf "$new"; die "옛 클론 이동 실패 — 아무것도 바꾸지 않았다"; }
  if ! mv "$new" "$REPO"; then mv "$bak" "$REPO"; die "새 클론 배치 실패 — 옛 클론을 원위치로 되돌렸다"; fi

  # 로컬 전용 파일 복원 (새 클론의 추적 파일은 -k로 덮어쓰지 않는다)
  # 복원은 조용히 실패하면 안 된다 — #29가 지키려는 게 바로 이 파일들이다.
  # 양쪽 종료 코드를 보고, 끝난 뒤 목록의 모든 경로가 새 클론에 있는지 대조한다.
  local rc_c rc_x missing=0
  ( cd "$bak" && tar -cf - -T "$PRESERVE_LIST" ) | ( cd "$REPO" && tar -xkf - )
  rc_c="${PIPESTATUS[0]}" rc_x="${PIPESTATUS[1]}"
  RESTORE_RC=0
  while IFS= read -r f; do
    [ -e "$REPO/$f" ] || { [ "$missing" = 0 ] && echo "" ; echo "  ❌ 복원 누락: $f"; missing=$((missing + 1)); }
  done < "$PRESERVE_LIST"
  if [ "$missing" != 0 ] || [ "$rc_c" != 0 ] || [ "$rc_x" != 0 ]; then
    RESTORE_RC=1
    echo "🔴 로컬 전용 파일 복원이 불완전하다 (tar 종료 코드: 읽기 $rc_c / 쓰기 $rc_x, 누락 ${missing}개)."
    echo "   옛 클론은 그대로 있다 — 누락분은 직접 복사: $bak/<경로> → $REPO/<경로>"
  fi
  rm -f "$PRESERVE_LIST" "$PRESERVE_LIST.skipped"

  echo ""
  echo "✅ 교체 완료"
  echo "  새 클론 : $REPO ($(G rev-parse --short HEAD))"
  echo "  백업    : $bak"
  echo "            └ .git/update-madang-backup/{all.bundle,uncommitted.patch,status.txt,unpushed.txt,stash.txt,preserved-files.txt}"
  echo "  🔴 옛 미커밋 변경을 새 클론에 옮길 때는 커밋 전에 claude/tools/sanitize/verify-tree.sh 를 먼저 돌려라(옛 히스토리 기준 변경이라 식별정보가 섞였을 수 있다)."
  echo "     시도: git -C $REPO apply --3way $bak/.git/update-madang-backup/uncommitted.patch"
  echo "  🔴 옛 브랜치·커밋은 push하지 마라 — 재작성 전 히스토리라 그대로 올라간다."
}

# ── ④ 심링크·셸 함수 재확인 (install.sh와 같은 기준) ─────────────────────────
recheck_links() {
  echo ""
  echo "── 심링크·셸 함수 재확인 ──"
  local out changes rc
  [ -f "$REPO/install.sh" ] || { echo "install.sh 없음 — 건너뜀"; return 0; }
  out="$(HOME="$HOME" bash "$REPO/install.sh" --dry-run 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then echo "install.sh --dry-run 실패($rc):"; echo "$out" | head -5 | sed 's/^/    /'; return 0; fi
  changes="$(echo "$out" | grep '^would-' || true)"
  if [ -z "$changes" ]; then
    echo "심링크·힌트: 변경 없음 (모두 이 레포를 가리킨다)"
  else
    echo "install.sh를 실행하면 아래가 바뀐다 (기존 항목은 .bak 으로 백업):"
    echo "$changes" | sed 's/^/    /'
    if ask "install.sh를 실행할까요?"; then
      bash "$REPO/install.sh" | sed 's/^/    /'
    else
      echo "건너뜀 — 나중에: $REPO/install.sh"
    fi
  fi
  # 셸 함수: ~/.zshrc가 이 레포의 go-functions.zsh를 source하는지 (수정은 하지 않는다 — 안내만)
  local want="$REPO/claude/shell/go-functions.zsh" zrc="$HOME/.zshrc"
  if [ -f "$zrc" ] && grep -Fq "$want" "$zrc"; then
    echo "셸 함수    : ~/.zshrc가 이 레포의 go-functions.zsh를 source한다 ✅ (새 탭 또는 'exec zsh'로 반영)"
  elif [ -f "$zrc" ] && grep -q 'go-functions.zsh' "$zrc"; then
    echo "셸 함수    : ⚠️ ~/.zshrc가 다른 경로의 go-functions.zsh를 source한다:"
    grep -n 'go-functions.zsh' "$zrc" | sed 's/^/    /'
    echo "             이 레포 것을 쓰려면 위 줄을 아래로 바꾼다:  source $want"
  else
    echo "셸 함수    : ⚠️ ~/.zshrc에 go-functions.zsh source 줄이 없다. 추가:"
    echo "             echo 'source $want' >> ~/.zshrc && exec zsh"
  fi
}

# ── 메인 (bash는 스크립트를 증분으로 읽는다 — git이 이 파일을 갈아치워도 안전하도록 main 안에서만 실행) ──
main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --check) CHECK=1 ;;
      --yes|-y) YES=1 ;;
      --repo) shift; REPO="${1:-}"; [ -n "$REPO" ] || { echo "--repo에 경로 필요" >&2; exit 2; } ;;
      -h|--help) awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "${BASH_SOURCE[0]}"; exit 0 ;;
      *) echo "알 수 없는 옵션: $1 (--check|--yes|--repo PATH)" >&2; exit 2 ;;
    esac
    shift
  done
  resolve_repo
  judge
  report_state
  if [ "$CHECK" = 1 ]; then exit "$CODE"; fi

  case "$STATE" in
    current) ;;
    ahead)
      echo "미push 커밋:"; G log --format='    %h %s' "$UPSTREAM..HEAD" | head -10
      echo "→ 교체할 것 없음. (push는 사람이 판단)" ;;
    behind)
      local before after
      before="$(G rev-parse --short HEAD)"
      if [ "$DIRTY" != 0 ]; then echo "미커밋 변경이 있지만 fast-forward는 충돌하는 파일만 막는다 — 시도한다."; fi
      if G merge --ff-only --quiet "$UPSTREAM"; then
        after="$(G rev-parse --short HEAD)"
        echo "✅ fast-forward 완료: $before → $after (+$BEHIND 커밋)"
      else
        die "fast-forward 실패 — 미커밋 변경이 들어올 파일과 충돌하는 것으로 보인다. 변경을 커밋/stash한 뒤 다시 실행."
      fi ;;
    diverged) replace_clone ;;
  esac
  recheck_links
  exit "${RESTORE_RC:-0}"
}
main "$@"
exit $?
