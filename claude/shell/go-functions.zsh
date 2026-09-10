# go-functions.zsh — 팀 워커/팀장 세션 기동 함수 (~/.zshrc에서 source)
# 2026-08-20 ~/.zshrc에서 레포로 이동: 머신 간 공유 (개인 환경 애든덤(claude-home) 참조)
# 2026-09-05 구 이름 alias 제거 — 공개(09-13) 준비로 09-11 예정을 앞당겼다.
#            옛 이름 목록·경위는 plans/rename-night-2026-09-03.md
# ============================================================================
# 팀 워커 세션 기동 (세션 이름 자동 설정: "<이모지><이름>[분신번호] MMDD")
# 2026-09-02 이모지 접두(REGISTRY E-17 L0), 2026-09-04 마당 리네임: 🔺번뜩 ☁️몽글 🟦슥슥 ⚪팀장 💬조잘 — 탭 목록에서 발화자 식별용 (원천: claude/roster.json)
# 새 탭에서 이 함수로 기동하면 `claude -n`으로 이름을 지정하면서 동시에
# 해당 스킬(/solver 등)을 첫 프롬프트로 보낸다 — 이후 수동 /rename 불필요.
# 분신(번뜩2 등)은 숫자 인자로: go-builder 2 → "몽글2 MMDD" +
# 스킬에도 "너는 몽글2다"를 같이 보내 분신 정체성/브리프 파일을 알려준다.
# ============================================================================
# 워커 시작 프롬프트 생성기 (2026-08-18 신설)
# $1=스킬명(solver) $2=한글이름(번뜩) $3=분신번호(빈 값이면 1번=무번호 인스턴스)
# 워커 스킬의 "기력회복 후 행동"은 기본이 '브리프 주세요' 하고 대기라, 브리프 파일이
# 이미 있어도 안 문다. 그래서 여기서 "있으면 즉시 읽어라"를 명시적으로 실어 보낸다.
_go_worker_prompt() {
  local skill="$1" kname="$2" n="$3" inst="$1$3"
  local p="/$skill"
  [ -n "$n" ] && p="$p 너는 이 세션에서 ${kname}${n}(분신)이다."
  p="$p 네 인스턴스명은 '${inst}'다."
  p="$p 기력회복을 마치면 곧바로 .claude/team/briefs/${inst}.md 를 확인해라 — 파일이 있으면 즉시 읽고 그 브리프만 수행한다(팀장에게 '브리프 주세요'라고 묻지 말 것). 파일이 없을 때만 대기한다."
  p="$p 브리프 수행을 마친 뒤에는 그 파일의 md5가 바뀌면 exit하는 폴 루프를 반드시 run_in_background(백그라운드)로 실행해 다음 브리프를 자동 수령해라 — 절대 포그라운드로 read하며 기다리지 마라."
  printf '%s' "$p"
}

# 브리프 첫 줄에서 작업 요약을 뽑아 세션 이름 꼬리표로 만든다 (2026-08-24)
# 규격: "# {이름} 브리프 ({차수}) — {요약}" → " · {요약}"(38자)
# 브리프가 없거나 규격이 다르면 조용히 생략 — 기존 동작과 동일하다.
# ⚠️ 상대경로라 프로젝트 루트에서 기동해야 한다.
_go_brief_tag() {
  local f=".claude/team/briefs/${1}.md"
  [ -f "$f" ] || return 0
  head -1 "$f" | grep -q '—' || return 0
  printf ' · %s' "$(head -1 "$f" | sed -E 's/^#+ *//; s/\*\*//g; s/^[^—]*— *//' | cut -c1-38)"
}

# 역할 이모지 (세션명 접두) — 클로드·코파일럿 공통
_go_emoji() {
  case "$1" in
    solver) printf "🔺";; builder) printf "☁️";; sketcher) printf "🟦";;
    narrator) printf "💬";; teamleader) printf "⚪";;
  esac
}

# 모델은 GO_MODEL 로 덮어쓸 수 있다 (예: GO_MODEL=opus go-solver)
go-solver()    { claude --model "${GO_MODEL:-sonnet}" -n "$(_go_emoji solver)번뜩${1} $(date +%m%d)$(_go_brief_tag solver${1})" "$(_go_worker_prompt solver 번뜩 "$1")"; }
go-builder() { claude --model "${GO_MODEL:-sonnet}" -n "$(_go_emoji builder)몽글${1} $(date +%m%d)$(_go_brief_tag builder${1})" "$(_go_worker_prompt builder 몽글 "$1")"; }
go-sketcher()  { claude --model "${GO_MODEL:-sonnet}" -n "$(_go_emoji sketcher)슥슥${1} $(date +%m%d)$(_go_brief_tag sketcher${1})" "$(_go_worker_prompt sketcher 슥슥 "$1")"; }
go-teamleader() {
  # 개인 동기화 스크립트가 PATH에 있으면 기동 전 pull — 없으면 건너뜀
  command -v work-sync >/dev/null 2>&1 && work-sync pull
  claude --model "${GO_MODEL:-opus}" -n "$(_go_emoji teamleader)팀장 $(date +%m%d)" "/teamleader"
}
go-narrator()   { claude --model "${GO_MODEL:-sonnet}" -n "$(_go_emoji narrator)조잘 $(date +%m%d)" "/narrator"; }

# 마당 워커 오버레이 (2026-09-02, REGISTRY E-17 · 09-04 madang으로 개명): 워커 상태를 화면 위 캐릭터로. 프로젝트 루트에서 실행.
# 읽기 전용 — .claude/team/ 파일 신호 + 세션 기록만 읽는다. 종료는 워커 우클릭 또는 메뉴바 아이콘(도담) → 종료.
go-madang() {
  local dir="${${(%):-%x}:A:h}/../tools/madang"   # 이 파일 기준 상대 경로 (레포 위치 무관)
  [ -x "$dir/madang" ] || "$dir/build.sh" || return 1
  pkill -x madang 2>/dev/null
  "$dir/madang" "${1:-$PWD/.claude/team}" >/dev/null 2>&1 &!
}

# 코파일럿 워커용 (2026-08-31 전면 수정 — CLI 1.0.82 기준으로 두 전제가 낡아 있었다)
#
#   ① 프롬프트: 예전 주석은 "인터랙티브 모드에 초기 프롬프트 인자가 없다"였으나 지금은 `-i <prompt>`가
#      있다(`copilot --help` 참조). pbcopy로 클립보드에 넣고 사람이 Cmd+V 하던 걸 자동 전달로 바꿨다.
#      pbcopy는 -i가 실패할 때를 위한 보험으로 남겨둔다.
#
#   ② 페르소나: 🔴 코파일럿에는 `/solver` 같은 슬래시 명령이 없다(`copilot help commands`로 확인 —
#      `/agent [name]`뿐). 그동안 `-cop`으로 띄운 워커는 프롬프트 첫 토큰 "/solver"가 그냥 텍스트로
#      들어가 **페르소나가 안 붙은 채** 돌고 있었다. 이제 `--agent`로 붙이고 프롬프트에서 슬래시를 뗀다.
#      에이전트 정의는 ~/.copilot/agents/{skill}.agent.md (Claude 쪽 ~/.claude/agents 와 별도 파일).
#
#   ③ 모델: GO_MODEL로 덮어쓴다 (Claude 변형과 대칭).
#      ⚠️ 코파일럿은 모델 ID 전체를 써야 한다: GO_MODEL=claude-opus-5 go-solver-cop
#      (claude 쪽 별칭 opus/sonnet은 안 먹는다). 가용 ID: claude-opus-5 · claude-sonnet-5 ·
#      gpt-5.6-sol · gpt-5.4 · gpt-5.4-mini · claude-opus-4.8
#
#   ④ 오토파일럿 (2026-08-31 신설): 워커는 오토파일럿으로 뜬다. 승인창마다 멈추면 무인 진행이
#      불가능하므로 --allow-all-tools(도구만)를 함께 준다. 경로·URL은 열지 않는다 —
#      브리프의 작업트리 제약이 살아 있어야 한다.
#      🔴 오토파일럿은 컨펌 게이트와 부딪힌다. 코파일럿에는 Claude Code의 hooks/gate-commit.sh 같은
#         강제 장치가 없어 게이트가 브리프의 약속뿐이다. 그래서 연속 진행을 3회로 묶는다(기본 5).
#      끄려면: GO_AUTOPILOT=0 go-solver-cop
#
#   기동 후 확인: 워커가 인사말("번뜩!" 등)로 열면 페르소나가 붙은 것이다.
_go_cop_launch() {
  local skill="$1" kname="$2" n="$3" p
  local -a autoflags
  if [ "${GO_AUTOPILOT:-1}" != "0" ]; then
    autoflags=(--autopilot --allow-all-tools --max-autopilot-continues "${GO_AUTOPILOT_CONTINUES:-3}")
  fi
  p="$(_go_worker_prompt "$skill" "$kname" "$n")"
  p="${p#/$skill }"                      # 코파일럿은 --agent로 붙이므로 앞의 "/solver " 제거
  printf '%s' "$p" | pbcopy              # -i가 안 먹을 때를 위한 보험
  copilot --agent "$skill" --model "${GO_MODEL:-claude-sonnet-5}" \
          "${autoflags[@]}" -n "$(_go_emoji "$skill")${kname}${n} $(date +%m%d)" -i "$p"
}
go-solver-cop()      { _go_cop_launch solver 번뜩 "$1"; }
go-builder-cop()   { _go_cop_launch builder 몽글 "$1"; }
go-sketcher-cop()    { _go_cop_launch sketcher 슥슥 "$1"; }
go-narrator-cop()   { copilot --agent narrator --model "${GO_MODEL:-claude-sonnet-5}" -n "$(_go_emoji narrator)조잘 $(date +%m%d)"; }
