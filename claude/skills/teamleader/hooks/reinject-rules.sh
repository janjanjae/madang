#!/usr/bin/env bash
# SessionStart(compact) 훅 — 컴팩션 뒤 ways-of-working 「이것만은」 절만 자동 재주입 (2026-08-31, 강의 2차 패스 D4-b)
# 공식 문서: hooks-guide "Re-inject context after compaction" — stdout이 그대로 컨텍스트에 붙는다.
f="$HOME/.claude/skills/teamleader/ways-of-working.md"
[ -f "$f" ] || exit 0
echo "[teamleader] 컴팩션 후 재주입 — ways-of-working 「이것만은」. 나머지 절은 필요할 때만 다시 읽어라 (전체 재독 금지)."
awk '/^## 🔴 이것만은/{p=1} /^---$/ && p && NR>20 {exit} p' "$f"
