#!/usr/bin/env python3
# madang Codex 훅 — PreToolUse 하나로 세 가지를 막는다 (Claude판 gate-commit·protect-hub 이식 + 제한 환경 push 차단)
#
#   1) push 차단   : `.codex/madang-restricted` 표식이 있으면 `git push`를 막는다 (--restricted 설치 시 생김)
#   2) 커밋 게이트 : MADANG_INSTANCE가 팀원(solver/builder/sketcher…)이면 자기 APPROVE reply 또는 waiver 없이 `git commit` 차단
#   3) 허브 보호   : 팀원 세션이 `.team/TASKS.md`·`.team/PROGRESS.md`를 apply_patch로 고치면 차단
#
# 인스턴스 식별: 탭을 `MADANG_INSTANCE=solver codex`처럼 띄운다. 훅은 Codex 프로세스의 환경변수를 물려받는다.
#   비어 있거나 lead/teamleader면 팀장(또는 혼자 쓰는 세션) — 게이트·허브 보호를 적용하지 않는다.
#   서브에이전트는 부모 세션의 환경을 쓰므로 서브에이전트에는 게이트가 걸리지 않는다(지시로만 규율).
#
# 차단 = exit 2 + stderr (Codex 공식 문서 PreToolUse 절). 훅 입력 JSON은 stdin.
# 🔴 입력 파싱 실패는 통과(fail-open)한다 — Claude판은 fail-closed였지만, 여기서 막으면 모든 셸 명령이 멈춰
#    시간 제한이 있는 작업이 통째로 멈춘다. 대신 stderr에 경고를 남긴다(Codex가 훅 실패로 표시).
import json, os, re, sys

def block(msg):
    sys.stderr.write('[madang] ' + msg + '\n')
    sys.exit(2)

try:
    d = json.load(sys.stdin)
except Exception as e:
    sys.stderr.write('[madang] 훅 입력 JSON 파싱 실패(%s) — 이번 호출은 검사 없이 통과\n' % e)
    sys.exit(1)

tool = d.get('tool_name', '') or ''
cmd = (d.get('tool_input') or {}).get('command', '') or ''
if not isinstance(cmd, str):
    cmd = ' '.join(map(str, cmd))
root = d.get('cwd') or os.getcwd()
inst = (os.environ.get('MADANG_INSTANCE') or '').strip()
is_worker = inst not in ('', 'lead', 'teamleader', 'dodam')
team = os.path.join(root, '.team')

def git_subcommands(cmd):
    """명령 세그먼트마다 git의 첫 서브커맨드를 돌려준다 (`git -C dir commit` 포함)."""
    out = []
    for seg in re.split(r'&&|\|\||;|\||\n', cmd):
        toks = seg.strip().split()
        if 'git' not in toks:
            continue
        j = toks.index('git') + 1
        while j < len(toks) and toks[j].startswith('-'):
            j += 2 if toks[j] in ('-C', '-c', '--git-dir', '--work-tree', '--namespace') else 1
        if j < len(toks):
            out.append((toks[j], seg))
    return out

if tool == 'Bash':
    subs = git_subcommands(cmd)
    # 1) push 차단
    if os.path.exists(os.path.join(root, '.codex', 'madang-restricted')) and any(s == 'push' for s, _ in subs):
        block('제한 환경: push 금지 — 로컬 커밋까지만')
    # 2) 커밋 게이트 (팀원 탭만)
    if is_worker and any(s == 'commit' for s, _ in subs):
        conf = os.path.join(team, 'confirm')
        if os.path.exists(os.path.join(conf, 'commit-waiver')) or os.path.exists(os.path.join(conf, 'commit-waiver-' + inst)):
            sys.exit(0)
        if inst.startswith('sketcher') and '[proto]' in cmd:
            sys.exit(0)
        reply = os.path.join(conf, inst + '.reply.md')
        try:
            with open(reply, encoding='utf-8') as f:
                first = f.readline().strip()
        except OSError:
            first = ''
        if not first.startswith('APPROVE'):
            block('커밋 게이트: %s 의 APPROVE가 없다. 검증 증거를 담아 .team/confirm/%s.request.md 를 쓰고 팀장 reply를 기다려라.' % (inst, inst))
    sys.exit(0)

if tool == 'apply_patch' and is_worker:
    # 3) 허브 보호 — 패치 머리(*** Update/Add/Delete File: 경로)에서 대상 파일을 읽는다
    for m in re.finditer(r'^\*\*\* (?:Update|Add|Delete) File: (.+)$', cmd, re.M):
        p = m.group(1).strip().replace('\\', '/')
        if re.search(r'(^|/)\.team/(TASKS|PROGRESS)\.md$', p):
            block('허브 문서(%s)는 팀장 전용이다. 필요한 변경은 보고 파일에 적어라.' % p)
sys.exit(0)
