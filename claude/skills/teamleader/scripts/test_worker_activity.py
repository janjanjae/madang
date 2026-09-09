#!/usr/bin/env python3
"""worker-activity.py 단위/스모크 테스트 — stdlib unittest만.

픽스처(팀 디렉토리·세션 jsonl·roster.json)를 임시 디렉토리에 직접 만든다.
실제 세션 파일·실제 .claude/team에 의존하지 않는다.

실행: python3 -m unittest claude/skills/teamleader/scripts/test_worker_activity.py -v
"""

import importlib.util
import json
import os
import shutil
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path

_SPEC = importlib.util.spec_from_file_location(
    "worker_activity", str(Path(__file__).resolve().parent / "worker-activity.py"))
wa = importlib.util.module_from_spec(_SPEC)
_SPEC.loader.exec_module(wa)

NOW = datetime(2026, 9, 5, 4, 30, tzinfo=timezone.utc)


def ts(minutes_ago):
    return (NOW - timedelta(minutes=minutes_ago)).isoformat().replace("+00:00", "Z")


# 실제 세션 기록은 공백 없는 압축 JSON이다 ({"type":"assistant",…}). 판정이 그 형태를
# 그대로 훑으므로(오버레이와 동일) 픽스처도 반드시 압축으로 만든다.
COMPACT = (",", ":")


def dumps(obj):
    return json.dumps(obj, ensure_ascii=False, separators=COMPACT)


def assistant(minutes_ago, parts):
    return dumps({"type": "assistant", "timestamp": ts(minutes_ago),
                  "message": {"role": "assistant", "content": parts}})


def user(minutes_ago, text):
    return dumps({"type": "user", "timestamp": ts(minutes_ago),
                  "message": {"role": "user", "content": text}})


def touch(path, body="x", minutes_ago=0):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(body, encoding="utf-8")
    when = (NOW - timedelta(minutes=minutes_ago)).timestamp()
    os.utime(str(path), (when, when))
    return path


class Base(unittest.TestCase):
    def setUp(self):
        wa._title_cache.clear()
        self.tmp = Path(tempfile.mkdtemp())
        self.team = self.tmp / "proj" / ".claude" / "team"
        for d in ("briefs", "reports", "confirm"):
            (self.team / d).mkdir(parents=True, exist_ok=True)
        self.sessions = self.tmp / "sessions"
        self.sessions.mkdir()
        self.roster = self.tmp / "roster.json"
        self.roster.write_text(json.dumps({"roster": [
            {"id": "solver", "key": "solver", "name": "번뜩", "pet": True, "aliases": ["파이리"]},
            {"id": "builder", "key": "builder", "name": "몽글", "pet": True, "aliases": ["메타몽"]},
            {"id": "lead", "key": "teamleader", "name": "도담", "pet": False, "aliases": ["팀장"]},
        ]}, ensure_ascii=False), encoding="utf-8")
        self.roles = wa.load_roles(self.roster)

    def tearDown(self):
        shutil.rmtree(str(self.tmp), ignore_errors=True)

    def session(self, name, title, lines, minutes_ago=1):
        p = self.sessions / (name + ".jsonl")
        body = dumps({"type": "custom-title", "customTitle": title})
        touch(p, "\n".join([body] + lines) + "\n", minutes_ago)
        return p

    def inst(self, key):
        for i in wa.discover_instances(self.team, self.roles, NOW):
            if i.key == key:
                return i
        raise AssertionError("인스턴스 %s 없음" % key)

    def snap(self, key):
        return wa.snapshot(self.inst(key), self.team, self.sessions, NOW)


class TestRoster(Base):
    def test_pet_false는_제외된다(self):
        keys = [r.key for r in self.roles]
        self.assertEqual(keys, ["solver", "builder"])   # 도담(pet:false) 제외

    def test_roster가_없으면_대체목록(self):
        roles = wa.load_roles(self.tmp / "없는파일.json")
        self.assertEqual([r.key for r in roles], ["solver", "builder", "sketcher"])


class TestLastRealTurn(Base):
    def test_케이스1_정상_산출_턴(self):
        p = self.session("s1", "🔺번뜩 0905", [
            assistant(30, [{"type": "text", "text": "생각 중"}]),
            assistant(10, [{"type": "tool_use", "name": "Bash"}]),
        ])
        work, err = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=10))   # 마지막 도구 호출
        self.assertIsNone(err)

    def test_케이스2_마지막이_API오류면_그_전_산출턴(self):
        """529 Overloaded 턴은 활동이 아니다 — work는 그 전 산출 턴이어야 한다."""
        p = self.session("s2", "🔺번뜩 0905", [
            assistant(40, [{"type": "text", "text": "실제 작업"}]),
            assistant(5, [{"type": "text", "text": "API Error: 529 Overloaded"}]),
        ])
        work, err = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=40), "오류 턴을 산출로 세면 안 된다")
        self.assertEqual(err, NOW - timedelta(minutes=5), "마지막 API 오류 시각이 잡혀야 한다")

    def test_케이스3_사용자_이어서_입력만_있는_꼬리(self):
        """사용자가 '이어서'를 친 것은 활동이 아니다 — user 턴은 무시한다."""
        p = self.session("s3", "🔺번뜩 0905", [
            assistant(50, [{"type": "text", "text": "작업"}]),
            user(2, "이어서"),
        ])
        work, err = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=50))
        self.assertIsNone(err)

    def test_빈_텍스트_턴은_산출이_아니다(self):
        p = self.session("s4", "🔺번뜩 0905", [
            assistant(60, [{"type": "text", "text": "진짜 작업"}]),
            assistant(3, [{"type": "text", "text": ""}]),
        ])
        work, _ = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=60))

    def test_잘린_첫줄은_조용히_건너뛴다(self):
        p = self.sessions / "s5.jsonl"
        touch(p, '{"type":"assistant","timest\n' + assistant(7, [{"type": "text", "text": "ok"}]) + "\n", 1)
        work, _ = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=7))

    def test_꼬리_128KB만_읽는다(self):
        """앞쪽 산출 턴이 128KB 밖이면 안 보여야 한다 (전체 로드 금지의 증거)."""
        old = assistant(300, [{"type": "text", "text": "아주 옛날 턴"}])
        filler = "\n".join('{"type":"noise","pad":"%s"}' % ("x" * 200) for _ in range(900))
        recent = assistant(9, [{"type": "text", "text": "최근"}])
        p = self.sessions / "s6.jsonl"
        touch(p, old + "\n" + filler + "\n" + recent + "\n", 1)
        self.assertGreater(p.stat().st_size, wa.TAIL_SPAN)
        work, _ = wa.last_real_turn(p)
        self.assertEqual(work, NOW - timedelta(minutes=9))


class TestSessionMatching(Base):
    def test_케이스4_매칭_세션이_없으면_work가_없다(self):
        self.session("other", "⚪팀장 0905", [assistant(5, [{"type": "text", "text": "x"}])])
        work, err = wa.last_session_activity(self.inst("solver"), self.sessions, NOW)
        self.assertIsNone(work)
        self.assertIsNone(err)

    def test_세션_폴더가_없어도_예외로_죽지_않는다(self):
        work, err = wa.last_session_activity(self.inst("solver"), self.tmp / "없는폴더", NOW)
        self.assertEqual((work, err), (None, None))

    def test_별칭과_key로도_매칭된다(self):
        self.session("a", "🔺파이리 0905", [assistant(12, [{"type": "text", "text": "x"}])])
        work, _ = wa.last_session_activity(self.inst("solver"), self.sessions, NOW)
        self.assertEqual(work, NOW - timedelta(minutes=12))

    def test_케이스5_분신은_이름_뒤_숫자로_구분된다(self):
        touch(self.team / "briefs" / "builder2.md", "# 브리프", 120)
        self.session("b1", "☁️몽글 0905", [assistant(40, [{"type": "text", "text": "x"}])])
        self.session("b2", "☁️몽글2 0905", [assistant(8, [{"type": "text", "text": "x"}])])
        base = wa.last_session_activity(self.inst("builder"), self.sessions, NOW)[0]
        two = wa.last_session_activity(self.inst("builder2"), self.sessions, NOW)[0]
        self.assertEqual(base, NOW - timedelta(minutes=40), "몽글은 몽글2를 먹으면 안 된다")
        self.assertEqual(two, NOW - timedelta(minutes=8))

    def test_12시간_지난_세션은_안_훑는다(self):
        self.session("stale", "🔺번뜩 0904", [assistant(5, [{"type": "text", "text": "x"}])],
                     minutes_ago=13 * 60)
        work, _ = wa.last_session_activity(self.inst("solver"), self.sessions, NOW)
        self.assertIsNone(work)

    def test_오류_뒤에_정상_턴이_있으면_해소된다(self):
        self.session("e1", "🔺번뜩 0905", [assistant(30, [{"type": "text", "text": "API Error: 529"}])])
        self.session("e2", "🔺번뜩 0905 b", [assistant(10, [{"type": "text", "text": "복구"}])])
        work, err = wa.last_session_activity(self.inst("solver"), self.sessions, NOW)
        self.assertEqual(work, NOW - timedelta(minutes=10))
        self.assertIsNone(err, "오류(30분 전)보다 새 산출(10분 전)이 있으면 오류는 해소")


class TestDiscoverInstances(Base):
    def test_기본_인스턴스는_브리프_없어도_나온다(self):
        keys = [i.key for i in wa.discover_instances(self.team, self.roles, NOW)]
        self.assertEqual(keys, ["solver", "builder"])

    def test_분신은_24시간_내_브리프만(self):
        touch(self.team / "briefs" / "builder2.md", "# 최근", 60)
        touch(self.team / "briefs" / "builder3.md", "# 오래됨", 25 * 60)
        keys = [i.key for i in wa.discover_instances(self.team, self.roles, NOW)]
        self.assertIn("builder2", keys)
        self.assertNotIn("builder3", keys, "24시간 지난 브리프의 분신은 안 띄운다")


class TestSnapshot(Base):
    def test_브리프_없으면_asleep(self):
        self.assertEqual(self.snap("solver")["state"], "asleep")

    def test_브리프만_있고_활동_없으면_not_started(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 10)
        self.assertEqual(self.snap("solver")["state"], "not_started")

    def test_세션_활동이_브리프보다_새로우면_working(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 30)
        self.session("s", "🔺번뜩 0905", [assistant(3, [{"type": "tool_use", "name": "Bash"}])])
        r = self.snap("solver")
        self.assertEqual(r["state"], "working")
        self.assertEqual(r["work"], NOW - timedelta(minutes=3))

    def test_25분_이상_정지면_idle(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 200)
        touch(self.team / "reports" / "solver.md", "보고", 26)
        r = self.snap("solver")
        self.assertEqual(r["state"], "idle")
        self.assertEqual(r["gap_min"], 26)

    def test_24분이면_아직_working(self):
        """임계값 25분 — Swift 상수 그대로."""
        touch(self.team / "briefs" / "solver.md", "# 브리프", 200)
        touch(self.team / "reports" / "solver.md", "보고", 24)
        self.assertEqual(self.snap("solver")["state"], "working")

    def test_request가_있으면_waiting_confirm(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 60)
        touch(self.team / "confirm" / "solver.request.md", "# 번뜩! — 컨펌 요청", 5)
        self.assertEqual(self.snap("solver")["state"], "waiting_confirm")

    def test_request_첫줄_BLOCKED면_blocked(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 60)
        touch(self.team / "confirm" / "solver.request.md", "BLOCKED — 못 함", 5)
        self.assertEqual(self.snap("solver")["state"], "blocked")

    def test_request_첫줄_DISCUSS면_discuss(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 60)
        touch(self.team / "confirm" / "solver.request.md", "**DISCUSS** — 논의", 5)
        self.assertEqual(self.snap("solver")["state"], "discuss")

    def test_reply가_request보다_새로우면_replied(self):
        touch(self.team / "briefs" / "solver.md", "# 브리프", 60)
        touch(self.team / "confirm" / "solver.request.md", "# 요청", 10)
        touch(self.team / "confirm" / "solver.reply.md", "APPROVE", 2)
        self.assertEqual(self.snap("solver")["state"], "replied")

    def test_컨펌_대기는_세션_기록을_보지_않는다(self):
        """Swift snapshot과 동일 — request 분기는 세션을 읽기 전에 return."""
        touch(self.team / "briefs" / "solver.md", "# 브리프", 60)
        touch(self.team / "confirm" / "solver.request.md", "# 요청", 5)
        r = self.snap("solver")
        self.assertEqual(r["state"], "waiting_confirm")
        self.assertIsNone(r["work"])


class TestCLI(Base):
    def test_실행되고_종료코드_0(self):
        import contextlib, io
        touch(self.team / "briefs" / "solver.md", "# 브리프", 10)
        with contextlib.redirect_stdout(io.StringIO()):
            rc = wa.main(["--team-dir", str(self.team),
                          "--projects-dir", str(self.sessions),
                          "--roster", str(self.roster)])
        self.assertEqual(rc, 0)

    def test_json_출력이_파싱된다(self):
        import contextlib, io
        touch(self.team / "briefs" / "solver.md", "# 브리프", 10)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            wa.main(["--team-dir", str(self.team), "--projects-dir", str(self.sessions),
                     "--roster", str(self.roster), "--json"])
        rows = json.loads(buf.getvalue())
        self.assertEqual([r["instance"] for r in rows], ["solver", "builder"])

    def test_instance_필터(self):
        import contextlib, io
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            wa.main(["--team-dir", str(self.team), "--projects-dir", str(self.sessions),
                     "--roster", str(self.roster), "--instance", "builder"])
        self.assertEqual(len(buf.getvalue().strip().splitlines()), 1)


if __name__ == "__main__":
    unittest.main()
