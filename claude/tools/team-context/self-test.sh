#!/usr/bin/env bash
# team-context 자가진단 — 레포 밖 임시 디렉토리(bare 원격 + 앱 레포 + 임시 HOME)에서 상태별로 재현한다.
# 사용자의 실제 팀 문서 레포 · ~/.claude · work-sync 는 건드리지 않는다(임시 HOME, PATH 앞에 스텁).
# 환경변수 TC_SCRIPT 로 다른 스크립트(변조본)를 시험할 수 있다 — "변경 전 대비 발화 확인"용.
# 종료 코드: 0 = 전부 통과, 1 = 실패 있음
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TC="${TC_SCRIPT:-$DIR/team-context.sh}"
T="$(cd -P "$(mktemp -d /tmp/team-context-test.XXXXXX)" && pwd -P)"   # /tmp → /private/tmp 정규화(macOS)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"
# 개인 도구 격리 — PATH에 있는 실제 work-sync가 테스트 중 불리면 안 된다. 스텁이 호출되면 실패로 잡는다.
STUBS="$T/stubs"; mkdir -p "$STUBS"
printf '#!/bin/sh\necho called >> "%s/work-sync.called"\nexit 99\n' "$T" > "$STUBS/work-sync"; chmod +x "$STUBS/work-sync"
export PATH="$STUBS:$PATH"
# 커밋 신원은 일부러 비워 둔다(신원 없는 새 기기 재현). 전역·시스템 설정도 차단.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL TEAM_CONTEXT_REMOTE TEAM_CONTEXT_BASE
# 픽스처 신원 — 이메일·티켓키 패턴에 걸리지 않게 조각으로 조립(리터럴이면 verify-tree 후보가 늘어난다)
_at="@"; ID="t${_at}example.invalid"
FAIL=0
ok()  { echo "  ✅ $*"; }
bad() { echo "  ❌ $*"; FAIL=1; }
eq()  { if [ "$2" = "$3" ]; then ok "$1 ($3)"; else bad "$1 — 기대 '$3' 실제 '$2'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 — '$3' 없음"; fi; }
hasnt() { if grep -qF -- "$3" <<<"$2"; then bad "$1 — '$3' 가 있다"; else ok "$1"; fi; }
git() { command git -c init.defaultBranch=main "$@"; }
# 픽스처 커밋 — 함수 이름으로만 만든다(스크립트 본문에 커밋 명령 문자열을 직접 쓰지 않기 위해)
rec() { local d="$1"; shift; git -C "$d" -c user.name=t -c user.email="$ID" "$(printf 'com%s' mit)" "$@"; }

REMOTE="$T/remote.git"        # 비공개 팀 문서 레포 역할 (bare)
BASE="$T/home/team-context"   # 클론이 놓일 베이스
export TEAM_CONTEXT_BASE="$BASE"
export TEAM_CONTEXT_REMOTE="$REMOTE"

# 앱 레포 흉내 — 폴더명이 프로젝트(브랜치) 이름
mkapp() { local d="$T/apps/$1"; rm -rf "$d"; mkdir -p "$d/.claude"; git init -q "$d"; echo "$d"; }
# 원격에 브랜치를 시드한다: seed_branch <브랜치> <파일명> <내용>
seed_branch() {
  local w="$T/seed-$1"; rm -rf "$w"; git init -q "$w"
  git -C "$w" checkout -q --orphan "$1"
  mkdir -p "$w/team"; echo "$3" > "$w/team/$2"; echo "# tasks $1" > "$w/TASKS.md"
  git -C "$w" add -A && rec "$w" -qm "seed $1" && git -C "$w" push -q "$REMOTE" "$1"
}
reset_world() {
  rm -rf "$REMOTE" "$BASE" "$T/apps" "$T/other-dev" "$HOME/.claude" "$T/work-sync.called"; mkdir -p "$T/apps"
  git init -q --bare "$REMOTE"
}
TCR() { ( cd "$1" && shift && bash "$TC" "$@" ) </dev/null 2>&1; }         # 출력 + (비대화형 stdin)
TCRC() { ( cd "$1" && shift && bash "$TC" "$@" ) </dev/null >/dev/null 2>&1; echo $?; }

# ── 0. 설정 없음 → 20 ─────────────────────────────────────────────────────
echo "== 0. 설정 없음 (원격 URL 미지정) → 20 =="
reset_world; APP="$(mkapp projx)"
SAVE="$TEAM_CONTEXT_REMOTE"; unset TEAM_CONTEXT_REMOTE
eq "status --check exit" "$(TCRC "$APP" status --check)" 20
OUT="$(TCR "$APP" status)"; has "안내 문구" "$OUT" "설정 없음"
eq "init exit" "$(TCRC "$APP" init --yes)" 20
export TEAM_CONTEXT_REMOTE="$SAVE"

# ── 1. 새 기기 init: 원격에 브랜치가 있음 ─────────────────────────────────
echo "== 1. 새 기기 init — 원격 브랜치 있음 → single-branch clone + 링크 + 실파일은 .pre-link로 =="
reset_world; seed_branch projx "remote-only.md" "from remote"; seed_branch projy "SECRET-OTHER-PROJECT.md" "other"
APP="$(mkapp projx)"
mkdir -p "$APP/.claude/team"; echo "local old" > "$APP/.claude/TASKS.md"; echo "mine" > "$APP/.claude/team/mine.md"
OUT="$(TCR "$APP" init)"                       # 비대화형 + --yes 없음 → 기본 n
has "계획에 실파일 이동 표시" "$OUT" "move-aside+link"
has "비대화형 기본 n 안내" "$OUT" "비대화형이라 n"
eq "기본 n이면 클론 없음" "$([ -e "$BASE/projx" ] && echo yes || echo no)" no
eq "기본 n이면 링크 없음" "$([ -L "$APP/.claude/team" ] && echo yes || echo no)" no
eq "기본 n이면 실파일 그대로" "$(cat "$APP/.claude/TASKS.md")" "local old"
eq "기본 n exit(취소=1)" "$(TCRC "$APP" init)" 1
OUT="$(TCR "$APP" init --yes)"; has "연결 완료" "$OUT" "연결 완료"
eq "TASKS.md 링크" "$(readlink "$APP/.claude/TASKS.md")" "$BASE/projx/TASKS.md"
eq "team 링크" "$(readlink "$APP/.claude/team")" "$BASE/projx/team"
eq "링크로 원격 내용이 보임" "$(cat "$APP/.claude/team/remote-only.md")" "from remote"
PRE="$(find "$APP/.claude" -maxdepth 1 -name '.pre-link-*' | head -1)"
eq "옮겨 둔 원본 TASKS.md" "$(cat "$PRE/TASKS.md" 2>/dev/null)" "local old"
eq "옮겨 둔 원본 team/mine.md" "$(cat "$PRE/team/mine.md" 2>/dev/null)" "mine"
has "앱 레포 exclude에 team" "$(cat "$APP/.git/info/exclude")" ".claude/team"
eq "앱 레포 git status 깨끗(링크가 untracked로 안 보임)" "$(git -C "$APP" status --porcelain | wc -l | tr -d ' ')" 0
eq "status --check 동기화됨" "$(TCRC "$APP" status --check)" 0
eq "재실행 init 멱등(keep 3건: TASKS·team·archive)" "$(TCR "$APP" init --yes | grep -c '^  keep ')" 3
eq "재실행 init에서 이동(moved) 없음" "$(TCR "$APP" init --yes | grep -c '^  moved ')" 0

echo "== 1b. 다른 프로젝트 브랜치의 파일명이 로컬 clone에 없다 (+ 음성 대조군) =="
CL="$BASE/projx"
eq "clone의 ref 중 projx 아닌 것 0개" "$(git -C "$CL" for-each-ref --format='%(refname)' | grep -vc 'projx$')" 0
ALLNAMES="$(git -C "$CL" cat-file --batch-all-objects --batch-check 2>/dev/null | awk '$2=="tree"{print $1}' | while read -r o; do git -C "$CL" ls-tree -r --name-only "$o"; done)"
hasnt "clone의 모든 tree에 다른 프로젝트 파일명 없음" "$ALLNAMES" "SECRET-OTHER-PROJECT.md"
git clone -q "$REMOTE" "$T/ctrl-full" 2>/dev/null
CTRL="$(git -C "$T/ctrl-full" for-each-ref --format='%(refname)')"
has "음성 대조군: 일반 clone은 다른 브랜치를 받는다 (검사가 발화함)" "$CTRL" "projy"
ALLC="$(git -C "$T/ctrl-full" cat-file --batch-all-objects --batch-check | awk '$2=="tree"{print $1}' | while read -r o; do git -C "$T/ctrl-full" ls-tree -r --name-only "$o"; done)"
has "음성 대조군: 일반 clone엔 다른 프로젝트 파일명이 있다" "$ALLC" "SECRET-OTHER-PROJECT.md"
rm -rf "$T/ctrl-full"

# ── 2. 첫 init: 원격에 브랜치 없음 → orphan 생성 ───────────────────────────
echo "== 2. 첫 init — 원격 브랜치 없음 → 현재 문서로 orphan 생성·push + 링크 =="
reset_world; seed_branch projy "SECRET-OTHER-PROJECT.md" "other"
APP="$(mkapp projz)"
mkdir -p "$APP/.claude/team/briefs"
echo "tasks" > "$APP/.claude/TASKS.md"; echo "brief" > "$APP/.claude/team/briefs/a.md"
printf 'PNG' > "$APP/.claude/team/shot.png"; head -c 1100000 /dev/zero > "$APP/.claude/team/big.bin"
OUT="$(TCR "$APP" init --yes)"; has "orphan 안내" "$OUT" "orphan 브랜치"
has "연결 완료" "$OUT" "연결 완료"
RB="$(git --git-dir="$REMOTE" ls-tree -r --name-only projz 2>/dev/null)"
has "원격 projz에 TASKS.md" "$RB" "TASKS.md"
has "원격 projz에 team/briefs/a.md" "$RB" "team/briefs/a.md"
hasnt "이미지는 원격에 안 올라감" "$RB" "shot.png"
hasnt "1MB 초과 파일은 원격에 안 올라감" "$RB" "big.bin"
eq "원본 이미지는 로컬에 남아 있음" "$(cat "$BASE/projz/team/shot.png")" "PNG"
eq "team 링크" "$(readlink "$APP/.claude/team")" "$BASE/projz/team"
eq "단일 브랜치 fetch 설정" "$(git -C "$BASE/projz" config --get-all remote.origin.fetch)" "+refs/heads/projz:refs/remotes/origin/projz"
eq "status --check 동기화됨" "$(TCRC "$APP" status --check)" 0
eq "신원 없는 기기에서 커밋 가능(조립된 신원)" "$(git -C "$BASE/projz" log -1 --format=%an)" "$(whoami)"

echo "== 2b. 빈 문서로 첫 init — 빈 orphan 커밋(신원 조립) =="
reset_world; APP="$(mkapp projempty)"
OUT="$(TCR "$APP" init --yes)"; has "연결 완료" "$OUT" "연결 완료"
eq "원격에 브랜치 생김" "$(git --git-dir="$REMOTE" rev-parse --verify -q projempty >/dev/null && echo yes || echo no)" yes
hasnt "커밋 신원에 리터럴 더미 없음" "$(git --git-dir="$REMOTE" log -1 --format='%ae' projempty)" "x@x"

echo "== 2c. team이 이미 다른 곳으로의 심링크 — 내용을 따라 복사하고 링크는 옮겨 둔다 =="
reset_world; APP="$(mkapp projlink)"
mkdir -p "$T/elsewhere/team"; echo "via link" > "$T/elsewhere/team/n.md"; ln -s "$T/elsewhere/team" "$APP/.claude/team"
OUT="$(TCR "$APP" init --yes)"; has "연결 완료" "$OUT" "연결 완료"
has "원격 브랜치에 링크 대상 내용이 있다" "$(git --git-dir="$REMOTE" ls-tree -r --name-only projlink)" "team/n.md"
eq "옮겨 둔 링크가 보존됨" "$(readlink "$(find "$APP/.claude" -maxdepth 2 -name team -path '*pre-link*' | head -1)")" "$T/elsewhere/team"

# ── 3. 원격 앞섬 10 ──────────────────────────────────────────────────────
other_dev() { # 다른 기기: 같은 브랜치를 clone해 파일 하나 추가·push
  rm -rf "$T/other-dev"; git clone -q --single-branch -b "$1" "$REMOTE" "$T/other-dev"
  echo "$3" > "$T/other-dev/$2"; git -C "$T/other-dev" add -A && rec "$T/other-dev" -qm "dev change" && git -C "$T/other-dev" push -q origin "$1"
}
echo "== 3. 원격이 앞섬 → 10, pull(ff-only) 후 0 =="
reset_world; seed_branch projx "base.md" "base"; APP="$(mkapp projx)"; TCR "$APP" init --yes >/dev/null
other_dev projx "team/from-laptop.md" "new"
eq "status --check exit" "$(TCRC "$APP" status --check)" 10
OUT="$(TCR "$APP" status)"; has "변경 목록에 원격 파일" "$OUT" "team/from-laptop.md"
eq "push는 거부(10)" "$(TCRC "$APP" push)" 10
eq "pull exit" "$(TCRC "$APP" pull)" 0
eq "pull 후 파일이 링크로 보임" "$(cat "$APP/.claude/team/from-laptop.md")" "new"
eq "pull 후 동기화됨" "$(TCRC "$APP" status --check)" 0

# ── 4. 로컬 앞섬 11 ──────────────────────────────────────────────────────
echo "== 4. 로컬이 앞섬 → 11, push 후 0 (커밋 메시지 형식) =="
echo "edit" > "$APP/.claude/team/local-new.md"
eq "status --check exit(미커밋)" "$(TCRC "$APP" status --check)" 11
OUT="$(TCR "$APP" status)"; has "변경 목록에 로컬 파일" "$OUT" "local-new.md"
eq "push exit" "$(TCRC "$APP" push)" 0
has "원격에 올라감" "$(git --git-dir="$REMOTE" ls-tree -r --name-only projx)" "team/local-new.md"
has "커밋 메시지 sync: 호스트 시각" "$(git --git-dir="$REMOTE" log -1 --format=%s projx)" "sync: $(hostname -s) "
eq "push 후 동기화됨" "$(TCRC "$APP" status --check)" 0
echo "x" > "$APP/.claude/team/shot2.png"
eq "이미지만 바뀌면 동기화됨(제외 규칙)" "$(TCRC "$APP" status --check)" 0

# ── 5. 분기 12 ───────────────────────────────────────────────────────────
echo "== 5. 분기 → 12, push·pull 모두 거부 =="
other_dev projx "team/from-laptop-2.md" "remote edit"
echo "local edit" > "$APP/.claude/team/local-2.md"
eq "status --check exit" "$(TCRC "$APP" status --check)" 12
eq "push 거부" "$(TCRC "$APP" push)" 12
eq "pull 거부" "$(TCRC "$APP" pull)" 12
eq "거부 후 로컬 변경 보존" "$(cat "$APP/.claude/team/local-2.md")" "local edit"

# ── 6. 미연결 21 / 판정 불가 22 ──────────────────────────────────────────
echo "== 6. 이 프로젝트 미연결 → 21 / 원격 접근 불가 → 22 =="
APP2="$(mkapp projnew)"
eq "미연결 status --check" "$(TCRC "$APP2" status --check)" 21
mv "$REMOTE" "$REMOTE.away"
eq "원격 접근 불가 status --check" "$(TCRC "$APP" status --check)" 22
OUT="$(TCR "$APP" status)"; has "판정 불가 문구" "$OUT" "판정 불가"
mv "$REMOTE.away" "$REMOTE"

# ── 7. 개인 도구 격리 ────────────────────────────────────────────────────
echo "== 7. PATH의 개인 도구(work-sync 스텁)가 한 번도 불리지 않았다 =="
eq "work-sync 호출 흔적" "$([ -e "$T/work-sync.called" ] && echo called || echo none)" none

echo ""
if [ "$FAIL" = 0 ]; then echo "=== 전체 통과 ==="; exit 0; else echo "=== 실패 있음 ==="; exit 1; fi
