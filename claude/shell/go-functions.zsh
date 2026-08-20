# go-functions.zsh — 팀 워커/팀장 세션 기동 함수 (~/.zshrc에서 source)
# 2026-08-20 ~/.zshrc에서 레포로 이동: 머신 간 공유 (재택 동기화 체계 — work-context/SETUP.md 참조)
# ============================================================================
# 팀 워커 세션 기동 (세션 이름 자동 설정: "<이름>[분신번호] MMDD")
# 새 탭에서 이 함수로 기동하면 `claude -n`으로 이름을 지정하면서 동시에
# 해당 스킬(/pairi 등)을 첫 프롬프트로 보낸다 — 이후 수동 /rename 불필요.
# 분신(파이리2 등)은 숫자 인자로: go-metamong 2 → "메타몽2 MMDD" +
# 스킬에도 "너는 메타몽2다"를 같이 보내 분신 정체성/브리프 파일을 알려준다.
# ============================================================================
# 워커 시작 프롬프트 생성기 (2026-08-18 신설)
# $1=스킬명(pairi) $2=한글이름(파이리) $3=분신번호(빈 값이면 1번=무번호 인스턴스)
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

# 모델은 GO_MODEL 로 덮어쓸 수 있다 (예: GO_MODEL=opus go-pairi)
go-pairi()    { claude --model "${GO_MODEL:-sonnet}" -n "파이리${1} $(date +%m%d)" "$(_go_worker_prompt pairi 파이리 "$1")"; }
go-metamong() { claude --model "${GO_MODEL:-sonnet}" -n "메타몽${1} $(date +%m%d)" "$(_go_worker_prompt metamong 메타몽 "$1")"; }
go-kkobugi()  { claude --model "${GO_MODEL:-sonnet}" -n "꼬부기${1} $(date +%m%d)" "$(_go_worker_prompt kkobugi 꼬부기 "$1")"; }
go-teamleader() {
  # 세션 기동 전 개인 레포 3종(베이스+컨텍스트) 최신화 — 개인 GitHub 접근 불가(ZTNA ON)면 '보류'만 뜨고 기동은 계속된다
  command -v work-sync >/dev/null 2>&1 && work-sync pull
  claude --model "${GO_MODEL:-opus}" -n "팀장 $(date +%m%d)" "/teamleader"
}
go-rotomdex()   { claude --model "${GO_MODEL:-sonnet}" -n "로토무도감 $(date +%m%d)" "/rotomdex"; }

# 코파일럿 워커용 — Copilot CLI는 인터랙티브 모드에 초기 프롬프트 인자가 없다.
# 그래서 같은 시작 프롬프트를 클립보드에 넣고 화면에도 찍어준다 → 뜨면 바로 붙여넣기(Cmd+V).
_go_cop_launch() {
  local skill="$1" kname="$2" n="$3" p
  p="$(_go_worker_prompt "$skill" "$kname" "$n")"
  printf '%s' "$p" | pbcopy
  print -P "%F{green}── 시작 프롬프트를 클립보드에 복사했다. 뜨면 Cmd+V ──%f"
  echo "$p"
  print -P "%F{green}────────────────────────────────────────────%f"
  copilot --model claude-sonnet-5 -n "${kname}${n} $(date +%m%d)"
}
go-pairi-cop()      { _go_cop_launch pairi 파이리 "$1"; }
go-metamong-cop()   { _go_cop_launch metamong 메타몽 "$1"; }
go-kkobugi-cop()    { _go_cop_launch kkobugi 꼬부기 "$1"; }
go-rotomdex-cop()   { copilot --model claude-sonnet-5 -n "로토무도감 $(date +%m%d)"; }
