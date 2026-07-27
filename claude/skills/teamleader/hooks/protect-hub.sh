#!/bin/bash
# PreToolUse(Edit|Write) — 허브 문서(TASKS.md/PROGRESS.md) 팀원 수정 차단
# 팀 규칙: 허브 문서는 팀장 단일 작성자 (ways-of-working "문서 규율")
python3 - <<'PY'
import json,sys,os
d=json.load(sys.stdin)
p=d.get('tool_input',{}).get('file_path','')
if os.path.basename(p) in ('TASKS.md','PROGRESS.md'):
    sys.stderr.write('[팀 규칙] 허브 문서('+os.path.basename(p)+')는 팀장 단일 작성자 — 팀원은 읽기 전용. 변경이 필요하면 보고/컨펌 요청에 내용을 담아 팀장에게 요청할 것.')
    sys.exit(2)
sys.exit(0)
PY
