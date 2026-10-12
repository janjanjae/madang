#!/usr/bin/env bash
# madang --probe 회귀 테스트 — 세션 기록 판정(큰 마지막 줄·이름 변경)을 레포 밖 임시 픽스처로 검증한다.
# 사용: test-probe.sh [madang 바이너리]     (기본: 이 디렉토리의 ./madang — build.sh 로 먼저 빌드)
# 종료 코드: 0 전부 통과 / 1 실패 있음 / 2 실행 불가
# 🔴 실행 중인 실제 오버레이는 건드리지 않는다: 세션 기록 루트(MADANG_PROJECTS_DIR)·팀 디렉토리를 모두 임시 디렉토리로 돌리고
#    --probe는 GUI 없이 끝난다(pkill·go-madang 안 씀).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="${1:-$HERE/madang}"
[ -x "$BIN" ] || { echo "🔴 바이너리 없음: $BIN — build.sh 로 먼저 빌드" >&2; exit 2; }
command -v python3 >/dev/null || { echo "🔴 python3 필요(픽스처 생성)" >&2; exit 2; }

FX="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/madang-probe.XXXXXX")" && pwd)"   # TMPDIR 끝 슬래시로 생기는 // 를 없앤다(Swift가 정규화한다)
trap 'rm -rf "$FX"' EXIT
python3 - "$FX" <<'PY'
import json, os, re, sys, time
from datetime import datetime, timezone, timedelta
fx = sys.argv[1]
proj = os.path.join(fx, "proj"); team = os.path.join(proj, ".claude", "team")
for d in ("briefs", "reports", "confirm"): os.makedirs(os.path.join(team, d))
enc = re.sub(r"[^a-zA-Z0-9]", "-", proj)      # Claude Code 의 프로젝트 경로 인코딩과 같은 규칙
sess = os.path.join(fx, "projects", enc); os.makedirs(sess)
now = time.time()
def iso(t): return datetime.fromtimestamp(t, timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.000Z")
# 실제 Claude Code 기록과 같은 compact JSON(공백 없음) — 오버레이의 줄 필터가 이 형태를 전제한다
J = dict(ensure_ascii=False, separators=(",", ":"))
def title(t): return json.dumps({"type": "custom-title", "customTitle": t, "sessionId": "x"}, **J)
def asst(ago): return json.dumps({"type": "assistant", "timestamp": iso(now - ago), "message": {"role": "assistant", "content": [{"type": "text", "text": "작업 중 요약"}]}}, **J)
def big_user(n): return json.dumps({"type": "user", "timestamp": iso(now), "message": {"role": "user", "content": [{"type": "tool_result", "content": "x" * n}]}}, **J)
def write(name, lines): open(os.path.join(sess, name + ".jsonl"), "w").write("\n".join(lines) + "\n")
def stamp(path, ago): os.utime(path, (now - ago, now - ago))
def worker(key, brief_ago=3 * 3600, report_ago=2 * 3600):
    b = os.path.join(team, "briefs", key + ".md"); open(b, "w").write("# 테스트 브리프\n"); stamp(b, brief_ago)
    r = os.path.join(team, "reports", key + ".md"); open(r, "w").write("# 보고\n"); stamp(r, report_ago)

# 브리프 3h 전 · 보고 2h 전 → 세션 신호가 없으면 「쉼」, 1분 전 작업 턴이 보이면 「작업중」
worker("builder");  write("a-big-last-line", [title("☁️몽글 0912 · 큰 줄"), asst(60), big_user(300_000)])             # 128KB 창을 넘는 마지막 줄
worker("builder2"); write("d-huge-last-line", [title("☁️몽글2 0912 · 더 큰 줄"), asst(60), big_user(1_500_000)])      # 1MB 창도 넘는 줄
worker("solver");   write("b-renamed-to", [title("⚪팀장 0905"), asst(600), asst(60), title("🔺번뜩 0912 · 재사용")])     # 처음엔 팀장 → 번뜩으로 이름 변경
worker("sketcher"); write("c-renamed-away", [title("🟦슥슥 0905"), asst(600), asst(60), title("⚪팀장 0912")])          # 처음엔 슥슥 → 팀장으로 이름 변경
open(os.path.join(fx, "team"), "w").write(team)
PY
TEAM="$(cat "$FX/team")"
OUT="$(MADANG_PROJECTS_DIR="$FX/projects" "$BIN" "$TEAM" --probe 2>&1)"; rc=$?
echo "$OUT" | sed 's/^/  | /'
[ $rc -eq 0 ] || { echo "🔴 --probe 실패(exit $rc)" >&2; exit 1; }

pass=0; fail=0
st() { echo "$OUT" | awk -F'\t' -v k="$1" '$1 == k { print $2 }'; }
chk() { # 이름 키 기대(working|resting)
  local got; got="$(st "$2")"
  case "$got" in *"$3"*) echo "  ✅ $1 → $2 $3"; pass=$((pass + 1)) ;; *) echo "  🔴 $1 → $2 기대 $3, 실제 '${got:-없음}'"; fail=$((fail + 1)) ;; esac
}
chk "마지막 줄 300KB(128KB 창 초과)에도 작업 턴을 찾는다" builder working
chk "마지막 줄 1.5MB(1MB 창 초과)에도 작업 턴을 찾는다" builder2 working
chk "이름 변경: 처음 팀장 → 마지막 번뜩이면 번뜩 것으로 집계" solver working
chk "이름 변경: 처음 슥슥 → 마지막 팀장이면 슥슥 것으로 집계하지 않는다" sketcher resting
echo; echo "통과 $pass / 실패 $fail"
[ "$fail" -eq 0 ]
