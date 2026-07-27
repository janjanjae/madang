#!/bin/bash
# PreToolUse(Bash) — 커밋 게이트: APPROVE reply 또는 waiver 없이 git commit 차단
# 팀 규칙: 커밋 전 테스트+컨펌 필수 (ways-of-working "팀원 작업 규율")
python3 - <<'PY'
import json,sys,os,glob
d=json.load(sys.stdin)
cmd=d.get('tool_input',{}).get('command','')
if 'git commit' not in cmd:
    sys.exit(0)
root=os.environ.get('CLAUDE_PROJECT_DIR', os.getcwd())
confirm=os.path.join(root,'.claude','team','confirm')
# 허용 1: 팀장이 배분 시 만든 waiver (컨펌 생략 태스크)
if os.path.exists(os.path.join(confirm,'commit-waiver')):
    sys.exit(0)
# 허용 2: APPROVE reply 존재 (컨펌 사이클 통과 직후)
for f in glob.glob(os.path.join(confirm,'*.reply.md')):
    try:
        first=open(f,encoding='utf-8').readline().strip()
        if first.startswith('APPROVE'):
            sys.exit(0)
    except OSError:
        pass
sys.stderr.write('[커밋 게이트] APPROVE reply가 없다 — 검증(테스트/빌드/린트) 통과 후 컨펌 요청(.claude/team/confirm/{인스턴스}.request.md)을 먼저 보내고 APPROVE를 받아라. 브리프에 "컨펌 생략"이 명시된 태스크는 팀장이 commit-waiver 파일을 만들어준다.')
sys.exit(2)
PY
