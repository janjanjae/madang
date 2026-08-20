---
name: save-progress
description: 현재 세션 작업 내용으로 .claude/PROGRESS.md 현행화 (+ TASKS.md 체크박스). 팀장 전용 (허브 문서 작성).
---
현재 세션에서 작업한 내용을 바탕으로 `.claude/PROGRESS.md`를 업데이트하라.

다음 항목을 현재 상태로 갱신:
- **현재 Phase**: 지금 어느 단계인지
- **모델 설정**: 현재 프로바이더·모델 상태 (model-guide.md 기준 표기)
- **마지막 작업**: 이번 세션에서 완료한 것들 (구체적으로)
- **다음 세션 시작점**: 다음에 어디서 이어야 하는지 (파일명, 함수명 수준으로 구체적으로)
- **미결 질문 / 결정 필요**: 판단을 못 내린 것, 사람 입력이 필요한 것
- **Jira 현황**: 완료된 서브태스크 반영

TASKS.md가 존재하면 완료된 태스크 체크박스도 함께 업데이트하라.

## 롤링 (새 체크포인트 추가 직후 매번)

PROGRESS.md는 **최신 체크포인트 + 직전 1개만** 유지한다. 밀려난 옛 블록은 `.claude/archive/PROGRESS-archive.md`로 원문 그대로 이동 (없으면 생성. 이동분 앞에 `## [YYYY-MM-DD 이동분]` 헤더). 원본 상단에 포인터 한 줄 유지: `> 과거 이력은 .claude/archive/ 참조`.

TASKS.md의 "대체됨"·지난 스프린트 블록 이동은 여기서 하지 않는다 — 스프린트 경계 작업이라 kickoff 소관 (이 스킬은 컨텍스트가 찬 시점에 돌므로 가볍게 유지).

업데이트 후 변경된 내용을 짧게 요약해서 알려줄 것 (아카이브로 이동한 블록이 있으면 함께).

## 이동 전 워커 WIP 코드 체크 (2026-08-20 신설 — 동기화 스텝보다 먼저)

다른 기기에서 이어갈 수 있게, PROGRESS 갱신 후 워크트리의 미이동 코드를 점검한다:

```bash
for wt in .claude/worktrees/*/; do
  dirty=$(git -C "$wt" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
  ahead=$(git -C "$wt" rev-list --count '@{u}..HEAD' 2>/dev/null || echo "업스트림없음")
  [ "$dirty" != "0" ] || [ "$ahead" != "0" ] && echo "$wt — 미커밋 ${dirty}건, 미push ${ahead}"
done
```

- 걸리는 워크트리가 없으면 조용히 통과.
- 걸리면 사용자에게 목록 보여주고 **"다른 기기에서 이어갈 것인지"** 확인 → 이어갈 것만 wip 커밋(`wip: 이어하기 스냅샷 YYYY-MM-DD`) + **회사 origin push** (커밋 전 게이트 준수: 커밋 내용 제시 → 확인 → 커밋). push된 브랜치명을 PROGRESS의 "다음 세션 시작점"에 기록.
- **주의: 회사 GitHub push는 ZTNA를 켜야 된다** (아래 work-sync와 반대). push 실패 시 "ZTNA 켜진 상태인지 확인" 안내.

## 컨텍스트 동기화 (2026-08-20 신설 — 마지막 스텝, 항상 실행)

PROGRESS/TASKS 갱신을 마치면 **반드시** `work-sync push`를 실행한다 (`$HOME/Desktop/work-context/bin/work-sync push`, PATH에 있으면 `work-sync push`). 이 스크립트는:

- work-context 레포(오버레이 작업 상태 원본)를 자동 커밋하고 push
- pokemon-agent-team·claude-home의 **이미 커밋된** ahead 커밋도 함께 push (미커밋 변경은 건드리지 않고 경고만)

**ZTNA 주의**: 개인 GitHub은 ZTNA를 꺼야 접근된다. 출력에 "push 보류"가 뜨면 커밋은 로컬에 안전하게 쌓인 상태다 — 사용자에게 **"퇴근/이동 전 ZTNA 끄고 터미널에서 `work-sync push` 한 번 실행"**을 리마인드하고 끝낸다 (재시도 루프 금지, 세션에서 ZTNA를 제어할 수 없다).
