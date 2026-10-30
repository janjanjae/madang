#!/usr/bin/env bash
# madang Codex판 설치 — 작업 공간 루트에서 실행한다.
#   git clone https://github.com/janjanjae/madang /tmp/madang
#   bash /tmp/madang/codex/install.sh              # 기본판
#   bash /tmp/madang/codex/install.sh --restricted # 감독·폐쇄 환경용 (push 차단 + 제한 규칙)
#
# 하는 일: 현재 폴더에만 파일을 만든다. 이미 있는 파일은 덮어쓰지 않고 건너뛴다.
# 하지 않는 일: ~/.codex 등 전역 설정 수정 · Codex 업데이트 · 네트워크 접속 · 기존 파일 덮어쓰기
set -eu

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="$(pwd)"
RESTRICTED=0
for a in "$@"; do
  case "$a" in
    --restricted) RESTRICTED=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "모르는 옵션: $a (--restricted 만 있다)" >&2; exit 1 ;;
  esac
done

if [ "$DST" = "$SRC" ] || [ "$DST" = "$(dirname "$SRC")" ]; then
  echo "madang 폴더 안이 아니라 작업 공간 루트에서 실행하세요 (cd 로 돌아간 뒤 bash /tmp/madang/codex/install.sh)" >&2
  exit 1
fi

added=0; skipped=0
put() { # put <원본> <대상>
  if [ -e "$2" ]; then
    echo "  건너뜀  $2 (이미 있음)"; skipped=$((skipped + 1))
  else
    mkdir -p "$(dirname "$2")"; cp "$1" "$2"
    echo "  추가    $2"; added=$((added + 1))
  fi
}

echo "madang Codex판 설치 → $DST"

# 1) 스킬
for d in "$SRC"/skills/*/; do
  name=$(basename "$d")
  for f in "$d"*; do put "$f" ".agents/skills/$name/$(basename "$f")"; done
done

# 2) 팀원(커스텀 에이전트)
for f in "$SRC"/agents/*.toml; do put "$f" ".codex/agents/$(basename "$f")"; done

# 3) 훅 (Codex가 /hooks 에서 신뢰 승인을 받아야 동작한다)
put "$SRC/hooks/hooks.json" ".codex/hooks.json"
put "$SRC/hooks/madang_hook.py" ".codex/hooks/madang_hook.py"

# 4) AGENTS.md
if [ -e AGENTS.md ]; then
  echo "  건너뜀  AGENTS.md (이미 있음 — $SRC/AGENTS.md 에서 필요한 절만 옮기세요)"; skipped=$((skipped + 1))
else
  cp "$SRC/AGENTS.md" AGENTS.md
  [ "$RESTRICTED" = 1 ] && cat "$SRC/AGENTS.restricted.md" >> AGENTS.md
  echo "  추가    AGENTS.md"; added=$((added + 1))
fi

# 5) 팀 신호 폴더 + 허브 문서
mkdir -p .team/briefs .team/confirm .team/reports .team/plans
put "$SRC/templates/team/TASKS.md" ".team/TASKS.md"
put "$SRC/templates/team/PROGRESS.md" ".team/PROGRESS.md"

# 6) 제한 환경 표식 (훅이 이 파일을 보고 git push 를 막는다)
if [ "$RESTRICTED" = 1 ]; then
  if [ -e .codex/madang-restricted ]; then
    echo "  건너뜀  .codex/madang-restricted (이미 있음)"; skipped=$((skipped + 1))
  else
    mkdir -p .codex; echo "madang --restricted: git push 차단" > .codex/madang-restricted
    echo "  추가    .codex/madang-restricted"; added=$((added + 1))
  fi
  if [ -e AGENTS.md ] && ! grep -q '제한 환경 규칙' AGENTS.md; then
    echo "  ⚠️  기존 AGENTS.md 에 제한 환경 규칙이 없습니다 — $SRC/AGENTS.restricted.md 를 붙이세요"
  fi
fi

cat <<EOF

완료: 추가 $added · 건너뜀 $skipped$( [ "$RESTRICTED" = 1 ] && echo ' · 제한 환경(--restricted)')

다음 단계
  1. codex 를 다시 켠다 (exit → codex). 스킬·에이전트·AGENTS.md 는 세션 시작 때 읽힌다.
  2. /skills 에 teamleader·planning-and-task-breakdown 등이 보이는지 확인한다.
  3. /hooks 에서 madang 훅을 검토·신뢰한다 (신뢰 전에는 훅이 돌지 않는다 — 규칙은 AGENTS.md 로도 걸려 있다).
  4. AGENTS.md 의 과제별 칸(실행·테스트 명령, 포트)을 채운다.
  5. 혼자 진행하면 그대로, 팀으로 나눌 땐 \$teamleader. 팀원 탭은: MADANG_INSTANCE=builder codex
문서: cat $SRC/README.md
EOF
