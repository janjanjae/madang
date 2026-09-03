# gate-commit.py — 훅 본체. 호출은 짝 .sh 래퍼가 한다(stdin의 훅 JSON을 그대로 넘긴다).
import json, sys, os, re, subprocess, collections

def block(msg):
    sys.stderr.write('[커밋 게이트] ' + msg)
    sys.exit(2)

try:
    d = json.load(sys.stdin)
except Exception as e:
    block('훅 입력 JSON 파싱 실패(%s) — 훅 스크립트 결함이다. 팀장에게 즉시 보고하고 커밋하지 마라.' % e)

cmd = d.get('tool_input', {}).get('command', '') or ''

def commit_targets(cmd):
    """각 명령 세그먼트에서 첫 서브커맨드가 commit인 git 호출을 찾아 (-C 경로 or None) 목록을 돌려준다."""
    out = []
    for seg in re.split(r'&&|\|\||;|\|', cmd):
        toks = seg.strip().split()
        if 'git' not in toks:
            continue
        i = toks.index('git'); j = i + 1; cdir = None
        while j < len(toks) and toks[j].startswith('-'):
            if toks[j] in ('-C', '-c', '--git-dir', '--work-tree', '--namespace'):
                if toks[j] == '-C' and j + 1 < len(toks):
                    cdir = toks[j + 1]
                j += 2
            else:
                j += 1
        if j < len(toks) and toks[j] == 'commit':
            out.append(cdir)
    return out

targets = commit_targets(cmd)
if not targets:
    sys.exit(0)

cwd = d.get('cwd') or os.getcwd()

def main_root(path):
    """워크트리면 메인 트리 루트, 아니면 자기 루트. git이 아니면 None."""
    try:
        r = subprocess.run(['git', '-C', path, 'rev-parse', '--path-format=absolute', '--git-common-dir'],
                           capture_output=True, text=True, timeout=5)
        g = r.stdout.strip()
        if not g:
            return None
        return g[:-5] if g.endswith('/.git') else os.path.dirname(g)
    except Exception:
        return None

cands = []
for t in targets:
    if t:
        cands.append(main_root(os.path.join(cwd, t)))
cands += [main_root(cwd), os.environ.get('CLAUDE_PROJECT_DIR'), cwd]
team = None
for c in cands:
    if c and os.path.isdir(os.path.join(c, '.claude', 'team')):
        team = os.path.join(c, '.claude', 'team'); break
if not team:
    block('.claude/team 디렉토리를 찾지 못했다(cwd=%s). 메인 트리 경로에서 커밋하거나 팀장에게 보고하라.' % cwd)
confirm = os.path.join(team, 'confirm')

def detect_instance(d):
    tp = d.get('transcript_path')
    if not tp or not os.path.isfile(tp):
        return None
    names = collections.Counter()
    pat = re.compile(r'(?:briefs|confirm|reports)/((?:solver|builder|sketcher)\d*)\.(?:request\.md|reply\.md|md)')
    inst = re.compile(r'인스턴스:\s*\{?((?:solver|builder|sketcher)\d*)\}?')
    try:
        with open(tp, encoding='utf-8', errors='ignore') as f:
            for line in f:
                if '.claude/team' in line or 'briefs/' in line or 'confirm/' in line or 'reports/' in line:
                    for m in pat.findall(line):
                        names[m] += 1
                if '인스턴스' in line:
                    for m in inst.findall(line):
                        names[m] += 3
    except OSError:
        return None
    return names.most_common(1)[0][0] if names else None

inst = detect_instance(d)
if not inst:
    # --agent로 띄운 세션은 훅 입력에 agent_type이 온다(번호 없는 기본 인스턴스로 간주)
    at = d.get('agent_type') or ''
    if re.fullmatch(r'(solver|builder|sketcher)\d*', at):
        inst = at

# 2) waiver
if os.path.exists(os.path.join(confirm, 'commit-waiver')):
    sys.exit(0)
if inst and os.path.exists(os.path.join(confirm, 'commit-waiver-' + inst)):
    sys.exit(0)

# 3) 슥슥 실험 커밋
if '[proto]' in cmd and (inst is None or inst.startswith('sketcher')):
    sys.exit(0)

def approved(path):
    try:
        with open(path, encoding='utf-8') as f:
            return f.readline().strip().startswith('APPROVE')
    except OSError:
        return False

# 4) 내 인스턴스의 APPROVE reply
if inst:
    if approved(os.path.join(confirm, inst + '.reply.md')):
        sys.exit(0)
    block('%s의 APPROVE reply(.claude/team/confirm/%s.reply.md)가 없다 — 검증(테스트/빌드/린트) 통과 후 '
          '컨펌 요청(confirm/%s.request.md)을 보내고 APPROVE를 받아라. 다른 인스턴스의 reply로는 통과하지 않는다. '
          '브리프에 "컨펌 생략"이 명시된 태스크는 팀장이 commit-waiver 파일을 만들어준다.' % (inst, inst, inst))

# 인스턴스 추정 실패 — 구 동작(아무 APPROVE)으로 완화, 단 경고
try:
    for fn in os.listdir(confirm):
        if fn.endswith('.reply.md') and approved(os.path.join(confirm, fn)):
            sys.exit(0)
except OSError:
    pass
block('APPROVE reply가 없다(인스턴스 추정 실패 — 아무 reply.md도 APPROVE가 아님). 검증 통과 후 '
      '컨펌 요청(.claude/team/confirm/{인스턴스}.request.md)을 먼저 보내고 APPROVE를 받아라. '
      '브리프에 "컨펌 생략"이 명시된 태스크는 팀장이 commit-waiver 파일을 만들어준다.')
