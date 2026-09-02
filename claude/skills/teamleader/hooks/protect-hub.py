# protect-hub.py — 훅 본체. 호출은 짝 .sh 래퍼가 한다(stdin의 훅 JSON을 그대로 넘긴다).
import json, sys, os
try:
    d = json.load(sys.stdin)
except Exception as e:
    sys.stderr.write('[팀 규칙] 훅 입력 JSON 파싱 실패(%s) — 훅 스크립트 결함이다. 팀장에게 즉시 보고하라.' % e)
    sys.exit(2)
p = d.get('tool_input', {}).get('file_path', '') or ''
name = os.path.basename(p)
if name in ('TASKS.md', 'PROGRESS.md'):
    sys.stderr.write('[팀 규칙] 허브 문서(' + name + ')는 팀장 단일 작성자 — 팀원은 읽기 전용. '
                     '변경이 필요하면 보고/컨펌 요청에 내용을 담아 팀장에게 요청할 것.')
    sys.exit(2)
sys.exit(0)
