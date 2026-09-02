#!/usr/bin/env bash
# PreToolUse(Edit|Write) — 허브 문서(TASKS.md/PROGRESS.md) 팀원 수정 차단
# 팀 규칙: 허브 문서는 팀장 단일 작성자 (ways-of-working "문서 규율")
#
# 🔴 훅 입력 JSON은 stdin으로 온다. 파이썬 코드를 heredoc(`python3 - <<PY`)으로 넘기면 JSON이 밀려나
#    매번 JSONDecodeError → exit 1(비차단) → 보호가 조용히 무력화된다(2026-07-28~09-02 실사고, incidents.md 「훅」).
#    코드는 짝 .py 파일로 분리하고 stdin은 JSON에 남긴다(macOS bash 3.2는 $(cat <<PY …) 안의 긴 코드도 못 파싱한다). 파싱 실패는 fail-closed(차단)다 — 조용한 무력화가 더 비싸다.
exec python3 "${0%.sh}.py"
