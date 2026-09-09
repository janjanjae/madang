#!/usr/bin/env python3
"""worker-activity.py — 워커 활동 신호 (팀장 감시용, 읽기 전용)

오버레이 `madang`(claude/tools/madang/madang.swift)이 화면에 그리는 것과 **같은 판정 근거**로
인스턴스별 상태를 한 줄씩 출력한다. 판정 로직은 madang.swift의 SSOT를 1:1로 옮긴 것이다
(discoverInstances / sessionTitle / lastRealTurn / lastSessionActivity / snapshot).

왜 필요한가: 보고 파일 mtime만 보면 긴 슬라이스를 조용히 파는 워커가 유휴로 오판된다.
Claude Code는 매 턴 세션 기록(~/.claude/projects/{인코딩된 프로젝트 경로}/{세션}.jsonl)을 갱신하고
그 안에 `-n` 세션명(customTitle)이 남는다 → 세션명이 이 워커 이름으로 시작하는 기록의
"모델이 실제로 산출한 마지막 턴"이 곧 "탭이 실제로 움직인 시각"이다.
사용자가 "이어서"를 친 것, 529 Overloaded 같은 오류 턴은 활동이 아니다.

사용법: python3 worker-activity.py --team-dir <프로젝트>/.claude/team [--json]
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

# ── madang.swift 상수 그대로 (값을 새로 정하지 않는다) ───────────────────────
IDLE_MINUTES = 25          # madang.swift: let idleMinutes = 25
TAIL_SPAN = 128 * 1024     # lastRealTurn: let span: UInt64 = 128 * 1024
TITLE_HEAD = 256 * 1024    # sessionTitle: h.readData(ofLength: 256 * 1024)
SESSION_WINDOW_SEC = 12 * 3600   # lastSessionActivity: 오늘 것만 훑는다
NUMBERED_BRIEF_WINDOW_SEC = 24 * 3600   # discoverInstances: 분신은 24시간 내 브리프만

# roster.json을 못 읽을 때의 대체 — madang.swift의 fallback과 같은 값
FALLBACK_ROLES = [
    {"id": "solver", "key": "solver", "name": "번뜩", "aliases": ["번뜩"]},
    {"id": "builder", "key": "builder", "name": "몽글", "aliases": ["몽글"]},
    {"id": "sketcher", "key": "sketcher", "name": "슥슥", "aliases": ["슥슥"]},
]

VERBOSE = False


def warn(msg):
    if VERBOSE:
        print("worker-activity: %s" % msg, file=sys.stderr)


# ── 시각 헬퍼 ────────────────────────────────────────────────────────────────

def mtime(path):
    """madang.swift: func mtime(_ url: URL) -> Date?"""
    try:
        return datetime.fromtimestamp(os.stat(str(path)).st_mtime, tz=timezone.utc)
    except OSError:
        return None


def parse_ts(s):
    """madang.swift: parseTS — ISO8601(소수 초 있음/없음) 둘 다."""
    if not isinstance(s, str):
        return None
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        return None


def hhmm(dt):
    return dt.astimezone().strftime("%H:%M") if dt else "-"


# ── roster / 역할 ────────────────────────────────────────────────────────────

class Role:
    __slots__ = ("id", "key", "name", "aliases")

    def __init__(self, id, key, name, aliases):
        self.id, self.key, self.name, self.aliases = id, key, name, aliases


def default_roster_path():
    """이 스크립트는 claude/skills/teamleader/scripts/ 안에 있다 → claude/roster.json."""
    return Path(__file__).resolve().parents[3] / "roster.json"


def load_roles(roster_path=None):
    """madang.swift: let roles — roster.json에서 `pet: true`인 항목만, 순서 그대로."""
    path = Path(roster_path) if roster_path else default_roster_path()
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        entries = data["roster"]
    except (OSError, ValueError, KeyError, TypeError):
        warn("roster.json을 못 읽음: %s — 대체 목록 사용" % path)
        entries = FALLBACK_ROLES
    roles = []
    for r in entries:
        if not isinstance(r, dict):
            continue
        # 대체 목록에는 pet 키가 없다 — 그때는 전부 채택(Swift fallback과 같은 3인)
        if entries is not FALLBACK_ROLES and r.get("pet") is not True:
            continue
        if not (r.get("id") and r.get("key") and r.get("name")):
            continue
        roles.append(Role(r["id"], r["key"], r["name"], list(r.get("aliases") or [])))
    return roles


# ── 인스턴스 탐색 ────────────────────────────────────────────────────────────

class Instance:
    __slots__ = ("key", "role", "suffix")

    def __init__(self, key, role, suffix):
        self.key, self.role, self.suffix = key, role, suffix


def discover_instances(team_dir, roles, now=None):
    """madang.swift: func discoverInstances()

    기본 인스턴스(무번호)는 브리프 유무와 무관하게 항상 나오고, 분신(builder2 …)은
    briefs/ 에 있고 24시간 내에 갱신된 것만. 8월 브리프가 남아 있어도 안 띄운다.
    """
    now = now or datetime.now(timezone.utc)
    briefs = Path(team_dir) / "briefs"
    try:
        names = os.listdir(str(briefs))
    except OSError:
        names = []
    out = []
    for role in roles:
        out.append(Instance(role.key, role, ""))
        numbered = []
        for n in names:
            if not (n.startswith(role.key) and n.endswith(".md")):
                continue
            mid = n[len(role.key):-3]
            if not mid or not mid.isdigit():
                continue
            m = mtime(briefs / n)
            if m is None or (now - m).total_seconds() >= NUMBERED_BRIEF_WINDOW_SEC:
                continue
            numbered.append(Instance(role.key + mid, role, mid))
        out.extend(sorted(numbered, key=lambda i: i.key))
    return out


# ── 세션 기록 ────────────────────────────────────────────────────────────────

def sessions_dir_for(team_dir):
    """madang.swift: let sessionsDir — 프로젝트 루트 경로의 비영숫자를 '-'로 바꾼 폴더명."""
    project_root = Path(team_dir).resolve().parent.parent   # .claude/team → .claude → 루트
    enc = "".join(c if (c.isalpha() or c.isdigit()) else "-" for c in str(project_root))
    return Path.home() / ".claude" / "projects" / enc


_title_cache = {}


def session_title(path):
    """madang.swift: func sessionTitle — 앞 256KB에서 customTitle 값을 그대로 꺼낸다."""
    key = str(path)
    if key in _title_cache:
        return _title_cache[key]
    try:
        with open(key, "rb") as f:
            head = f.read(TITLE_HEAD).decode("utf-8", "replace")
    except OSError:
        return ""
    marker = '"customTitle":"'
    i = head.find(marker)
    if i < 0:
        return ""
    rest = head[i + len(marker):]
    end = rest.find('"')
    title = rest if end < 0 else rest[:end]
    if title:
        _title_cache[key] = title
    return title


def last_real_turn(path):
    """madang.swift: func lastRealTurn — 꼬리 128KB만 읽어 거꾸로 훑는다.

    반환 (work, error): 모델이 실제로 산출한 마지막 턴 / 그 뒤의 마지막 API 오류.
    도구 호출 또는 빈 문자열이 아닌 텍스트 = 산출. "API Error"로 시작하는 텍스트 = 오류.
    """
    try:
        with open(str(path), "rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(size - TAIL_SPAN if size > TAIL_SPAN else 0)
            tail = f.read().decode("utf-8", "replace")
    except OSError:
        return (None, None)

    work = err = None
    for line in reversed(tail.split("\n")):
        if '"type":"assistant"' not in line:
            continue
        try:
            j = json.loads(line)
        except ValueError:
            continue          # 꼬리 첫 줄은 잘려 있다 — 조용히 건너뛴다
        if not isinstance(j, dict):
            continue
        ts = parse_ts(j.get("timestamp"))
        msg = j.get("message")
        if ts is None or not isinstance(msg, dict):
            continue

        is_error = is_work = False
        content = msg.get("content")
        if isinstance(content, list):
            for p in content:
                if not isinstance(p, dict):
                    continue
                if p.get("type") == "tool_use":
                    is_work = True
                if p.get("type") == "text":
                    t = p.get("text")
                    if isinstance(t, str):
                        if t.startswith("API Error"):
                            is_error = True
                        elif t:
                            is_work = True
        elif isinstance(content, str):
            if content.startswith("API Error"):
                is_error = True
            elif content:
                is_work = True

        if is_error and err is None:
            err = ts
        if is_work:
            work = ts
            break
    return (work, err)


def _title_names(inst):
    """madang.swift: let names = ([role.name, role.key] + role.aliases).map { $0 + suffix }"""
    return [n + inst.suffix for n in ([inst.role.name, inst.role.key] + inst.role.aliases)]


def _strip_leading_symbols(t):
    """madang.swift: t.drop(while: { !$0.isLetter && !$0.isNumber }) — 앞의 이모지를 뗀다."""
    i = 0
    while i < len(t) and not (t[i].isalpha() or t[i].isdigit()):
        i += 1
    return t[i:]


def last_session_activity(inst, sessions_dir, now=None):
    """madang.swift: func lastSessionActivity — 이 인스턴스 이름으로 *시작*하는 세션들 중 최신."""
    now = now or datetime.now(timezone.utc)
    try:
        files = sorted(Path(sessions_dir).iterdir())
    except OSError:
        warn("세션 폴더 없음: %s" % sessions_dir)
        return (None, None)

    names = _title_names(inst)
    best_work = best_err = None
    for f in files:
        if f.suffix != ".jsonl":
            continue
        m = mtime(f)
        if m is None or (now - m).total_seconds() >= SESSION_WINDOW_SEC:
            continue      # 오늘 것만 훑는다
        t = _strip_leading_symbols(session_title(f))
        matched = False
        for n in names:
            if not t.startswith(n):
                continue
            after = t[len(n):len(n) + 1]
            if after == "" or not after.isdigit():   # 이름 뒤 숫자 = 다른 분신
                matched = True
                break
        if not matched:
            continue
        w, e = last_real_turn(f)
        if w is not None and (best_work is None or w > best_work):
            best_work = w
        if e is not None and (best_err is None or e > best_err):
            best_err = e
    if best_err and best_work and best_err < best_work:
        best_err = None       # 오류 뒤에 정상 턴이 있으면 해소된 것
    return (best_work, best_err)


# ── 상태 판정 ────────────────────────────────────────────────────────────────

def first_line(path):
    """madang.swift: func firstLine — 앞 4KB의 첫 줄에서 `**`와 머리 `#`을 뗀다."""
    try:
        with open(str(path), "rb") as f:
            text = f.read(4096).decode("utf-8", "replace")
    except OSError:
        return ""
    line = text.split("\n", 1)[0].replace("**", "")
    return line.lstrip("#").strip()


def snapshot(inst, team_dir, sessions_dir, now=None):
    """madang.swift: func snapshot — 상태 결정 규칙·임계값 그대로.

    Swift의 PetState → 이 도구의 state 이름:
      off → asleep · notStarted → not_started · working → working · needsConfirm → waiting_confirm
      blocked → blocked · discuss → discuss · replied → replied · idle(m) → idle (gap_min에 분)
    """
    now = now or datetime.now(timezone.utc)
    team_dir = Path(team_dir)
    brief = team_dir / "briefs" / ("%s.md" % inst.key)
    report = team_dir / "reports" / ("%s.md" % inst.key)
    req = team_dir / "confirm" / ("%s.request.md" % inst.key)
    reply = team_dir / "confirm" / ("%s.reply.md" % inst.key)

    bm, rm, rqm, rpm = mtime(brief), mtime(report), mtime(req), mtime(reply)
    row = {
        "instance": inst.key, "role": inst.role.id, "name": inst.role.name,
        "state": "unknown", "gap_min": None,
        "work": None, "err": None,
        "brief": bm, "report": rm, "request": rqm, "reply": rpm,
        "title": "",
    }

    if bm is None:
        row["state"] = "asleep"        # .off — 브리프 없음
        return row

    row["title"] = first_line(brief)

    if rqm is not None:
        if rpm is not None and rpm >= rqm:
            row["state"] = "replied"
            return row
        head = first_line(req).upper()
        row["state"] = ("blocked" if head.startswith("BLOCKED")
                        else "discuss" if head.startswith("DISCUSS")
                        else "waiting_confirm")
        return row

    # 활동 시각 = 보고 파일과 세션 기록 중 더 최근 — 보고는 안 썼어도 탭이 움직이면 작업중
    work, err = last_session_activity(inst, sessions_dir, now)
    row["work"], row["err"] = work, err

    candidates = [d for d in (rm, work) if d is not None]
    activity = max(candidates) if candidates else None
    if activity is None or activity <= bm:
        row["state"] = "not_started"   # .notStarted — 미기동 = 유휴 아님
        return row

    gap = int((now - activity).total_seconds() / 60)
    row["gap_min"] = gap
    row["state"] = "idle" if gap >= IDLE_MINUTES else "working"
    return row


# ── 출력 ─────────────────────────────────────────────────────────────────────

def format_row(row):
    state = row["state"]
    if state == "idle" and row["gap_min"] is not None:
        state = "idle(%dm)" % row["gap_min"]
    return "%-10s state=%-16s work=%-6s err=%-6s brief=%-6s report=%-6s request=%-6s reply=%s" % (
        row["instance"], state,
        hhmm(row["work"]), hhmm(row["err"]),
        hhmm(row["brief"]), hhmm(row["report"]),
        hhmm(row["request"]), hhmm(row["reply"]),
    )


def json_row(row):
    out = dict(row)
    for k in ("work", "err", "brief", "report", "request", "reply"):
        out[k] = row[k].astimezone().isoformat() if row[k] else None
    return out


def main(argv=None):
    global VERBOSE
    ap = argparse.ArgumentParser(
        description="워커 활동 신호 — 오버레이 madang과 같은 판정 (읽기 전용)")
    ap.add_argument("--team-dir", required=True, help="<프로젝트>/.claude/team")
    ap.add_argument("--projects-dir", default=None,
                    help="세션 기록 폴더 (기본: team-dir에서 유도한 ~/.claude/projects/…)")
    ap.add_argument("--instance", action="append", default=None,
                    help="이 인스턴스만 (반복 가능)")
    ap.add_argument("--roster", default=None, help="roster.json 경로 (기본: claude/roster.json)")
    ap.add_argument("--json", action="store_true", dest="as_json", help="JSON 배열로 출력")
    ap.add_argument("--verbose", action="store_true", help="진단을 stderr로")
    args = ap.parse_args(argv)

    VERBOSE = args.verbose
    team_dir = Path(os.path.expanduser(args.team_dir))
    sessions_dir = (Path(os.path.expanduser(args.projects_dir)) if args.projects_dir
                    else sessions_dir_for(team_dir))
    warn("team-dir=%s" % team_dir)
    warn("sessions-dir=%s" % sessions_dir)

    now = datetime.now(timezone.utc)
    roles = load_roles(args.roster)
    instances = discover_instances(team_dir, roles, now)
    if args.instance:
        wanted = set(args.instance)
        instances = [i for i in instances if i.key in wanted]

    rows = []
    for inst in instances:
        try:
            rows.append(snapshot(inst, team_dir, sessions_dir, now))
        except Exception as e:                                  # 한 인스턴스가 전체를 죽이지 않는다
            warn("%s 판정 실패: %r" % (inst.key, e))
            rows.append({"instance": inst.key, "role": inst.role.id, "name": inst.role.name,
                         "state": "unknown", "gap_min": None, "work": None, "err": None,
                         "brief": None, "report": None, "request": None, "reply": None,
                         "title": ""})

    if args.as_json:
        print(json.dumps([json_row(r) for r in rows], ensure_ascii=False, indent=2))
    else:
        for r in rows:
            print(format_row(r))
    return 0


if __name__ == "__main__":
    sys.exit(main())
