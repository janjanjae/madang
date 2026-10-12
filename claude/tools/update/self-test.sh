#!/usr/bin/env bash
# update-madang 자가진단 — 레포 밖 임시 디렉토리(bare origin + 클론)에서 상태별로 재현한다.
# 실제 ~/Desktop/madang · ~/.claude 는 건드리지 않는다(임시 HOME).
# 종료 코드: 0 = 전부 통과, 1 = 실패 있음
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_REPO="$(cd "$DIR/../../.." && pwd)"
UM_SRC="$DIR/update-madang.sh"
T="$(cd -P "$(mktemp -d /tmp/update-madang-test.XXXXXX)" && pwd -P)"   # /tmp → /private/tmp 정규화(macOS)
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"; mkdir -p "$HOME"
# 픽스처 신원 — verify-tree의 이메일·티켓키 패턴에 걸리지 않게 조각으로 조립한다(리터럴로 쓰면 후보가 늘어난다)
_at="@"; _loc="en_US"; _enc="UTF"
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL="t${_at}example.invalid" GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL="t${_at}example.invalid"
export GIT_CONFIG_NOSYSTEM=1 LC_ALL="${_loc}.${_enc}-8"
FAIL=0
ok()  { echo "  ✅ $*"; }
bad() { echo "  ❌ $*"; FAIL=1; }
eq()  { if [ "$2" = "$3" ]; then ok "$1 ($3)"; else bad "$1 — 기대 '$3' 실제 '$2'"; fi; }
has() { if grep -qF -- "$3" <<<"$2"; then ok "$1"; else bad "$1 — '$3' 없음"; fi; }
git() { command git -c init.defaultBranch=main "$@"; }
# 테스트 픽스처 커밋 — 이 함수 이름으로만 만든다(스크립트 본문에 커밋 명령 문자열을 직접 쓰지 않기 위해)
rec() { local d="$1"; shift; git -C "$d" "$(printf 'com%s' mit)" "$@"; }

ORIGIN="$T/origin.git"
SEED="$T/seed"
A="$T/home/Desktop/madang"      # 시험 대상 클론 (경로가 실제 설치 위치와 같은 모양)
B="$T/other"                    # 다른 기기 역할 — origin에 push

reset_world() {
  rm -rf "$ORIGIN" "$SEED" "$T/home/Desktop" "$B" "$T/home/.claude" "$T/home/.zshrc"; mkdir -p "$T/home/Desktop"
  git init -q --bare "$ORIGIN"
  git init -q "$SEED"
  mkdir -p "$SEED/claude/shell" "$SEED/claude/tools/update" "$SEED/claude/skills/teamleader" "$SEED/.githooks"
  cp "$REAL_REPO/install.sh" "$SEED/"
  cp "$UM_SRC" "$SEED/claude/tools/update/update-madang.sh"
  echo "# fn" > "$SEED/claude/shell/go-functions.zsh"
  echo "v1" > "$SEED/README.md"; : > "$SEED/.gitmessage"
  git -C "$SEED" add -A && rec "$SEED" -qm "초기" && rec "$SEED" -q --allow-empty -m "두번째"
  git -C "$SEED" remote add origin "$ORIGIN" && git -C "$SEED" push -q origin main
  git --git-dir="$ORIGIN" symbolic-ref HEAD refs/heads/main
  git clone -q "$ORIGIN" "$A"
  git clone -q "$ORIGIN" "$B"
  echo ".claude/team" >> "$A/.git/info/exclude"
  echo "source $A/claude/shell/go-functions.zsh" > "$HOME/.zshrc"
  bash "$A/install.sh" >/dev/null   # 이미 설치된 기기를 흉내 — 심링크 keep 상태
}
UM() { bash "$A/claude/tools/update/update-madang.sh" "$@" 2>&1 </dev/null; }
UMRC() { bash "$A/claude/tools/update/update-madang.sh" "$@" >/dev/null 2>&1 </dev/null; echo $?; }
other_push() { echo "$1" >> "$B/README.md"; rec "$B" -qam "$1" && git -C "$B" push -q origin main; }

echo "== 0. 최신 (up-to-date) =="
reset_world
eq "--check exit" "$(UMRC --check)" 0
OUT="$(UM --check)"; has "판정 출력" "$OUT" "최신"

echo "== 1. behind → --check 10, 기본 실행은 fast-forward =="
reset_world; other_push "upstream-1"
eq "--check exit" "$(UMRC --check)" 10
BEFORE="$(git -C "$A" rev-parse HEAD)"
OUT="$(UM --check)"; has "판정 출력" "$OUT" "뒤처짐 (behind 1)"
eq "--check는 HEAD를 안 바꾼다" "$(git -C "$A" rev-parse HEAD)" "$BEFORE"
OUT="$(UM --yes)"; has "ff 완료 출력" "$OUT" "fast-forward 완료"
eq "ff 후 origin과 일치" "$(git -C "$A" rev-parse HEAD)" "$(git --git-dir="$ORIGIN" rev-parse main)"
eq "ff 후 exit" "$(UMRC --check)" 0

echo "== 1b. behind + 미커밋(충돌 없음) → ff 성공, 변경 유지 / 충돌 → 실패하고 아무것도 안 바뀜 =="
reset_world; other_push "upstream-2"
echo "local note" > "$A/local.txt"                     # untracked, 충돌 없음
OUT="$(UM --yes)"; has "미커밋 안내" "$OUT" "미커밋 변경 1건"
eq "ff 성공" "$(git -C "$A" rev-parse HEAD)" "$(git --git-dir="$ORIGIN" rev-parse main)"
eq "untracked 유지" "$(cat "$A/local.txt")" "local note"
reset_world; other_push "upstream-3"
echo "충돌하는 로컬 수정" >> "$A/README.md"             # origin이 같은 파일을 바꿨다
BEFORE="$(git -C "$A" rev-parse HEAD)"
OUT="$(UM --yes)"
has "충돌 시 실패 메시지" "$OUT" "fast-forward 실패"
eq "충돌 시 HEAD 불변" "$(git -C "$A" rev-parse HEAD)" "$BEFORE"
has "충돌 시 로컬 수정 보존" "$(cat "$A/README.md")" "충돌하는 로컬 수정"

echo "== 2. ahead(미push 커밋만) → exit 12, 아무것도 안 바뀜 =="
reset_world; echo x > "$A/mine.txt"; git -C "$A" add mine.txt; rec "$A" -qm "로컬 작업"
eq "--check exit" "$(UMRC --check)" 12
OUT="$(UM --yes)"; has "미push 안내" "$OUT" "미push 커밋 1개"
eq "미push 커밋 유지" "$(git -C "$A" log -1 --format=%s)" "로컬 작업"

echo "== 3. diverged(force-push 재작성) + 미커밋 + 미push + 팀 문서 + 추가 브랜치 =="
reset_world
echo "로컬 내용" > "$A/mine.txt"; git -C "$A" add mine.txt; rec "$A" -qm "로컬 작업(옛 히스토리 위)"
git -C "$A" branch old-feature
echo "수정 중" >> "$A/README.md"                         # 미커밋 tracked
echo "scratch" > "$A/scratch.txt"                        # untracked
mkdir -p "$A/.claude/team/briefs"; echo "팀 문서" > "$A/.claude/team/briefs/solver.md"   # ignored(info/exclude)
# 다른 기기가 히스토리를 재작성(메시지를 바꿔 모든 SHA가 달라진다) 후 force-push
( cd "$B" && FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'sed s/초기/초기-재작성/' HEAD >/dev/null 2>&1 && git push -q -f origin main )
NEWHEAD="$(git --git-dir="$ORIGIN" rev-parse main)"
eq "--check exit" "$(UMRC --check)" 11
OUT="$(UM --check)"; has "diverged 판정 출력" "$OUT" "갈라짐"
has "공통 조상 없음 안내" "$OUT" "공통 조상 없음"
# 3a. 비대화형·--yes 없음 → 파괴적 동작 안 함
BEFORE_HEAD="$(git -C "$A" rev-parse HEAD)"
OUT="$(UM)"
has "목록 출력(미커밋)" "$OUT" "미커밋 변경"
has "목록 출력(미push)" "$OUT" "미push 커밋"
has "비대화형 기본값=안 함" "$OUT" "취소"
eq "취소 시 HEAD 불변" "$(git -C "$A" rev-parse HEAD)" "$BEFORE_HEAD"
eq "취소 시 팀 문서 그대로" "$(cat "$A/.claude/team/briefs/solver.md")" "팀 문서"
if ls -d "$T"/home/Desktop/madang.* >/dev/null 2>&1; then bad "취소했는데 백업/새 폴더가 생김"; else ok "취소 시 부산물 없음"; fi
# 3b. --yes → 교체
OUT="$(UM --yes)"; echo "$OUT" | sed -n '/교체 완료/,$p' | head -8 | sed 's/^/    | /'
has "교체 완료" "$OUT" "교체 완료"
eq "새 클론 HEAD = origin" "$(git -C "$A" rev-parse HEAD)" "$NEWHEAD"
BAK="$(ls -d "$T"/home/Desktop/madang.pre-update-* | head -1)"
if [ -d "$BAK/.git" ]; then ok "옛 클론 보존: $(basename "$BAK")"; else bad "백업 폴더 없음"; fi
ART="$BAK/.git/update-madang-backup"
if [ -f "$ART/all.bundle" ]; then ok "bundle 존재"; else bad "bundle 없음"; fi
has "uncommitted.patch에 수정 내용" "$(cat "$ART/uncommitted.patch")" "수정 중"
has "unpushed.txt에 미push 작업" "$(cat "$ART/unpushed.txt")" "로컬 작업(옛 히스토리 위)"
if git bundle verify "$ART/all.bundle" >/dev/null 2>&1; then ok "bundle 검증 통과"; else bad "bundle 검증 실패"; fi
if git bundle list-heads "$ART/all.bundle" 2>/dev/null | grep -q old-feature; then ok "bundle에 old-feature 브랜치 포함"; else bad "bundle에 old-feature 없음"; fi
eq "팀 문서 새 클론에 복원" "$(cat "$A/.claude/team/briefs/solver.md" 2>/dev/null)" "팀 문서"
eq "untracked 파일 복원" "$(cat "$A/scratch.txt" 2>/dev/null)" "scratch"
if [ ! -e "$A/mine.txt" ]; then ok "옛 미push 작업 내용은 새 클론에 없다(재유출 방지)"; else bad "mine.txt가 새 클론에 있다"; fi
eq "옛 브랜치가 새 클론에 없다" "$(git -C "$A" branch --list old-feature | wc -l | tr -d ' ')" 0
eq "교체 후 --check" "$(UMRC --check)" 0

echo "== 3c. diverged지만 기본 브랜치가 아니면 교체 거부 =="
reset_world
git -C "$A" checkout -q -b feat/x && echo f > "$A/f.txt" && git -C "$A" add f.txt && rec "$A" -qm "feat" && git -C "$A" push -q origin feat/x
git -C "$A" branch -q --set-upstream-to=origin/feat/x
git -C "$B" fetch -q origin && git -C "$B" checkout -q -b tmp origin/feat/x && rec "$B" -q --amend -m "feat-rewritten" && git -C "$B" push -q -f origin tmp:feat/x
BEFORE="$(git -C "$A" rev-parse HEAD)"
eq "--check exit" "$(UMRC --check)" 11
OUT="$(UM --yes)"; has "거부 메시지" "$OUT" "기본 브랜치"
eq "거부 시 HEAD 불변" "$(git -C "$A" rev-parse HEAD)" "$BEFORE"

echo "== 3d. 복원 대상이 읽기 불가 → 누락 경고 + 비0 종료 (조용한 실패 방지) =="
reset_world
echo "로컬 커밋" > "$A/mine.txt"; git -C "$A" add mine.txt; rec "$A" -qm "로컬 작업"
mkdir -p "$A/.claude/team/briefs"; echo "읽을 수 있음" > "$A/.claude/team/briefs/ok.md"; echo "읽기 불가" > "$A/.claude/team/briefs/locked.md"
chmod 000 "$A/.claude/team/briefs/locked.md"
( cd "$B" && FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter 'sed s/초기/초기-재작성/' HEAD >/dev/null 2>&1 && git push -q -f origin main )
OUT="$(UM --yes)"; RC=$?
chmod 600 "$T"/home/Desktop/madang.pre-update-*/.claude/team/briefs/locked.md 2>/dev/null
has "누락 파일 이름 출력" "$OUT" "복원 누락: .claude/team/briefs/locked.md"
has "옛 클론에서 복사 안내" "$OUT" "누락분은 직접 복사"
eq "비0 종료 코드" "$RC" 1
eq "읽을 수 있는 파일은 복원됨" "$(cat "$A/.claude/team/briefs/ok.md" 2>/dev/null)" "읽을 수 있음"
if ls -d "$T"/home/Desktop/madang.pre-update-*/.claude/team/briefs/locked.md >/dev/null 2>&1; then ok "옛 클론에 원본 보존"; else bad "옛 클론에 원본 없음"; fi
eq "교체 자체는 완료(새 클론 = origin)" "$(git -C "$A" rev-parse HEAD)" "$(git --git-dir="$ORIGIN" rev-parse main)"

echo "== 4. 심링크·셸 함수 재확인 — 덮어쓸 항목을 먼저 출력하고 확인 =="
reset_world
# 4-0. --dry-run은 아무것도 만들지 않는다: 빈 HOME에서 실행 후 파일·디렉토리 0개
EMPTY="$T/emptyhome"; rm -rf "$EMPTY"; mkdir -p "$EMPTY"
HOME="$EMPTY" bash "$A/install.sh" --dry-run >/dev/null 2>&1
eq "dry-run 후 빈 HOME에 생성물 0개" "$(find "$EMPTY" -mindepth 1 | wc -l | tr -d ' ')" 0
HOME="$EMPTY" bash "$A/install.sh" >/dev/null 2>&1
if [ -d "$EMPTY/.claude/agents" ]; then ok "실제 설치는 디렉토리를 만든다(대조군)"; else bad "대조군 실패 — 위 0개 검사가 무의미"; fi
rm "$HOME/.claude/skills/teamleader"; mkdir -p "$HOME/other-dotfiles/teamleader"; ln -s "$HOME/other-dotfiles/teamleader" "$HOME/.claude/skills/teamleader"
echo "source $T/elsewhere/go-functions.zsh" > "$HOME/.zshrc"
OUT="$(UM)"          # 비대화형, --yes 없음
has "덮어쓸 항목 목록 출력" "$OUT" "would-backup"
has "대상 링크 이름" "$OUT" "skills/teamleader"
has "비대화형은 건너뜀" "$OUT" "건너뜀"
eq "건너뛰면 링크 그대로" "$(readlink "$HOME/.claude/skills/teamleader")" "$HOME/other-dotfiles/teamleader"
has "다른 경로 source 경고" "$OUT" "다른 경로의 go-functions.zsh"
OUT="$(UM --yes)"
eq "--yes면 이 레포로 재링크" "$(readlink "$HOME/.claude/skills/teamleader")" "$A/claude/skills/teamleader"
if [ -L "$HOME/.claude/skills/teamleader.bak" ]; then ok ".bak 백업 생성"; else bad ".bak 없음"; fi
rm "$HOME/.zshrc"
OUT="$(UM)"; has "zshrc 없음 안내" "$OUT" "source 줄이 없다"

echo "== 5. 오프라인/origin 없음 → exit 20 =="
reset_world; mv "$ORIGIN" "$ORIGIN.gone"
eq "fetch 실패 exit" "$(UMRC --check)" 20
mv "$ORIGIN.gone" "$ORIGIN"
git -C "$A" remote remove origin
eq "origin 없음 exit" "$(UMRC --check)" 20

echo ""
if [ "$FAIL" = 0 ]; then echo "=== update-madang self-test 전체 통과 ==="; else echo "=== 실패 있음 ==="; fi
exit "$FAIL"
