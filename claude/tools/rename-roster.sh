#!/bin/sh
# rename-roster.sh — 포켓몬 식별자 → 마당 역할 식별자 일괄 교체 (2026-09-03 준비, 실행은 스프린트14 종료 후)
#
# 기본은 드라이런(변경 없음, 대상 파일·건수만 출력). 실제 실행: ./rename-roster.sh --apply
# ⚠️ 워커 세션이 하나라도 돌고 있으면 실행 금지 — briefs/confirm/reports 경로가 바뀌어 파일 신호가 끊긴다.
#    확인: 프로젝트 .claude/team/confirm/ 에 *.request.md 가 없고, 최근 1시간 내 briefs/ 갱신이 없을 것.
#
# 하는 일 (레포 안):
#   1. 파일·디렉토리 이름: claude/agents/{구}.md, claude/skills/{구}/, copilot 동기화 매니페스트
#   2. 본문 치환: 식별자(solver→solver …) + 표시 이름(번뜩→번뜩 …) + 인사말
#   3. plans/·changelog 는 히스토리라 건드리지 않는다 (기원 서사 보존)
# 하지 않는 일 (사람이 이어서):
#   - ~/.claude 심링크 재생성: ./install.sh 재실행
#   - 프로젝트 오버레이({app-repo} 등 {프로젝트}/.claude/team/{agents,briefs,reports}/{구}*.md) 리네임 — 워커 재기동 전에 각 프로젝트에서
#   - GitHub 레포 리네임(pokemon-agent-team → madang, 개인 계정 재인증 필요) · 로컬 폴더명 · plugin.json 이름
#   - README·DIRECTION 문장 다듬기 (기계 치환 후 눈으로)

set -e
cd "$(dirname "$0")/../.."
APPLY=0; [ "$1" = "--apply" ] && APPLY=1

# 구 식별자 → 신 식별자 / 구 표시 이름 → 신 표시 이름 / 인사말
MAP_ID="solver:solver builder:builder sketcher:sketcher narrator:narrator"
MAP_KO="번뜩:번뜩 몽글:몽글 슥슥:슥슥 조잘:조잘 조잘:조잘"
# 인사말은 공백을 포함하므로 줄 단위로 (탭 구분)
MAP_CRY="$(printf '번뜩!\t번뜩!\n몽글~\t몽글~\n슥슥~\t슥슥~\n조잘조잘!\t조잘조잘!')"

# 팀장 WIP(미커밋) 파일은 제외 — 커밋 뒤 이 스크립트를 다시 돌리면 잡힌다
WIP='teamleader/(model-guide\.md|ways-of-working\.md|reference/(confirm-protocol|worktree-setup)\.md)'
EXCLUDE="(^\./\.git/|^\./plans/|changelog|reference/incidents|^\./claude/roster\.json|^\./claude/assets/|$WIP)"
files() { grep -rIl -E "$1" . 2>/dev/null | grep -Ev "$EXCLUDE" || true; }

echo "== 드라이런: 본문 치환 대상 (plans/·changelog·incidents 제외)"
for pair in $MAP_ID; do
  old=${pair%%:*}; new=${pair##*:}
  n=$(grep -rIo -E "\b$old[0-9]*\b" . 2>/dev/null | grep -Ev "$EXCLUDE" | wc -l | tr -d ' ')
  echo "  $old → $new : $n 회 / $(files "\b$old" | wc -l | tr -d ' ') 파일"
done
for pair in $MAP_KO; do
  old=${pair%%:*}; new=${pair##*:}
  n=$(grep -rIo "$old" . 2>/dev/null | grep -Ev "$EXCLUDE" | wc -l | tr -d ' ')
  echo "  $old → $new : $n 회"
done
echo "== 이름 바뀔 파일/디렉토리"
for pair in $MAP_ID; do
  old=${pair%%:*}; new=${pair##*:}
  [ -e "claude/agents/$old.md" ] && echo "  claude/agents/$old.md → claude/agents/$new.md"
  [ -d "claude/skills/$old" ]   && echo "  claude/skills/$old/ → claude/skills/$new/"
done
echo "== 남는 'pokemon/포켓몬' (레포명·플러그인·README 훅 — 손으로): $(grep -rIo -i "pokemon\|포켓몬" . 2>/dev/null | grep -Ev "$EXCLUDE" | wc -l | tr -d ' ') 회"

[ $APPLY -eq 1 ] || { echo; echo "(드라이런 끝 — 실제 적용은 --apply)"; exit 0; }

echo "== 적용"
for pair in $MAP_ID; do
  old=${pair%%:*}; new=${pair##*:}
  [ -e "claude/agents/$old.md" ] && git mv "claude/agents/$old.md" "claude/agents/$new.md"
  [ -d "claude/skills/$old" ]   && git mv "claude/skills/$old" "claude/skills/$new"
done
for f in $(files "solver|builder|sketcher|narrator|번뜩|몽글|슥슥|조잘"); do
  printf '%s\n' "$MAP_CRY" | while IFS="$(printf '\t')" read -r old new; do [ -n "$old" ] && perl -pi -e "s/\Q$old\E/$new/g" "$f"; done
  for pair in $MAP_ID;  do old=${pair%%:*}; new=${pair##*:}; perl -pi -e "s/\b$old(?=[0-9]*\b)/$new/g" "$f"; done
  for pair in $MAP_KO;  do old=${pair%%:*}; new=${pair##*:}; perl -pi -e "s/\Q$old\E/$new/g" "$f"; done
done
# 스킨 표: key 를 id 와 일치시킨다
perl -pi -e 's/"key": ?"solver"/"key": "solver"/; s/"key": ?"builder"/"key": "builder"/; s/"key": ?"sketcher"/"key": "sketcher"/; s/"key": ?"narrator"/"key": "narrator"/' claude/roster.json   # teamleader 는 그대로
echo "완료. 다음: ./install.sh 재실행 → git diff 눈으로 확인 → 프로젝트 오버레이 리네임 → 커밋"
