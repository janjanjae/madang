#!/usr/bin/env zsh
# go-functions.zsh 자가진단 — go-madang(#27) · go-teamleader 오버레이 자동 기동(#26)
# 실제 오버레이·실제 claude는 건드리지 않는다: go-functions.zsh를 임시 트리로 복사하고
# 오버레이 바이너리·claude·pkill·pgrep은 전부 가짜(스텁)로 바꿔 부른다.
# 종료 코드: 0 = 전부 통과, 1 = 실패 있음
setopt no_unset 2>/dev/null
SRC="${${(%):-%x}:A:h}/go-functions.zsh"
T="$(mktemp -d /tmp/go-functions-test.XXXXXX)"
trap 'rm -rf "$T"' EXIT
FAIL=0
ok()  { echo "  ✅ $*"; }
bad() { echo "  ❌ $*"; FAIL=1; }
eq()  { [ "$2" = "$3" ] && ok "$1 ($3)" || bad "$1 — 기대 '$3' 실제 '$2'"; }
has() { [[ "$2" == *"$3"* ]] && ok "$1" || bad "$1 — '$3' 없음 (출력: ${2:0:200})"; }

# 임시 트리: <T>/claude/shell/go-functions.zsh + <T>/claude/tools/madang/madang(가짜)
mkdir -p "$T/claude/shell" "$T/claude/tools/madang" "$T/proj/.claude/team" "$T/bare"
cp "$SRC" "$T/claude/shell/go-functions.zsh"
FAKE="$T/claude/tools/madang/madang"

fake_madang() { # fake_madang <exit|stay> — 인자 기록 후 즉시 에러 종료 / 계속 실행
  if [ "$1" = exit ]; then
    printf '#!/bin/sh\necho "madang: 가짜 바이너리 오류 출력" >&2\nexit 3\n' > "$FAKE"
  else
    printf '#!/bin/sh\necho "$@" > "%s/madang.args"\nexec sleep 30\n' "$T" > "$FAKE"
  fi
  chmod +x "$FAKE"
}

# 스텁 환경에서 함수 실행: run_in <cwd> <명령...> → 표준출력에 stdout+stderr, 종료 코드는 $RC
run_in() {
  local cwd="$1"; shift
  OUT="$(cd "$cwd" && zsh -c '
    source "'"$T"'/claude/shell/go-functions.zsh"
    pkill()  { echo "pkill $*" >> "'"$T"'/pkill.log"; }
    claude() { echo "claude $*" >> "'"$T"'/claude.log"; }
    pgrep()  { [ -e "'"$T"'/overlay.running" ]; }
    '"$*"'
  ' 2>&1)"
  RC=$?
}
reset() { rm -f "$T"/pkill.log "$T"/claude.log "$T"/madang.args "$T"/overlay.running; rm -rf "$T/proj/.claude/team/briefs"; }
reap() { pkill -f "$T/claude/tools/madang/madang" 2>/dev/null; sleep 0.3; }

echo "== #27 go-madang: briefs/ 없음 → 조용히 죽지 않고 안내 =="
reset; fake_madang stay
run_in "$T/proj" go-madang
eq "종료 코드 1" "$RC" 1
has "원인(briefs) 안내" "$OUT" "briefs 가 없다"
has "/start 안내" "$OUT" "/start"
[ ! -e "$T/madang.args" ] && ok "오버레이를 띄우지 않았다" || bad "briefs 없는데 오버레이가 떴다"
[ ! -e "$T/pkill.log" ] && ok "기존 오버레이를 죽이지 않았다(pkill 미호출)" || bad "pkill이 호출됐다"

echo "== #27 go-madang: 바이너리가 즉시 죽으면 그 출력을 보여준다 =="
reset; mkdir -p "$T/proj/.claude/team/briefs"; fake_madang exit
run_in "$T/proj" go-madang
eq "종료 코드 1" "$RC" 1
has "가짜 바이너리의 stderr가 터미널에 보인다" "$OUT" "가짜 바이너리 오류 출력"
has "시작 직후 종료 안내" "$OUT" "시작 직후 종료"

echo "== #27 go-madang: 정상 기동은 조용히 성공하고 인자(감시 경로)를 넘긴다 =="
reset; mkdir -p "$T/proj/.claude/team/briefs"; fake_madang stay
run_in "$T/proj" go-madang
eq "종료 코드 0" "$RC" 0
sleep 0.3
eq "정상 기동은 출력 없음" "$OUT" ""
eq "감시 경로 인자" "$(cat "$T/madang.args" 2>/dev/null)" "$T/proj/.claude/team"
reap

echo ""
[ "$FAIL" = 0 ] && echo "=== go-functions self-test 전체 통과 ===" || echo "=== 실패 있음 ==="
exit "$FAIL"
