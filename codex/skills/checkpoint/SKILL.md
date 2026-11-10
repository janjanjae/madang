---
name: checkpoint
description: 긴 세션의 현재 상태를 파일로 옮겨 새 세션이 이어갈 수 있게 한다 — plan.md 태스크 체크·.team/TASKS.md 상태 현행화 + .team/PROGRESS.md에 CHECKPOINT 한 줄 → /new 안내. 팀장 탭(또는 단일 모드 탭)에서 사람이 $checkpoint 로 부를 때만.
---

# 체크포인트 (Codex판)

컨텍스트가 차기 전에 지금 상태를 파일에 남긴다. 새 세션은 이 파일들만 읽고 이어간다. 자동 compact가 있어도, compact가 요약을 잘못하면 잃는 것을 파일로 지킨다.

**언제 부르나**: 팀장 탭 컨텍스트가 절반을 넘었을 때(`/status`) · 단계가 바뀔 때(기획서 승인 → 구현, 동결 직전) · 점심처럼 자리를 비우기 전.

## 규칙

- 허브 문서 작성자만 부른다: 탭 모드면 팀장 탭, 단일 모드면 그 탭. 팀원 탭에서는 부르지 않는다.
- 코드를 고치지 않는다. 커밋·push 하지 않는다. 팀원 탭을 건드리지 않는다.
- 짧게 끝낸다(1~2분): 전체 코드 통독·테스트 재실행·서브에이전트 금지. `git`과 허브 문서만 본다.

## 1. 상태 확인

```bash
git log --oneline -10
git status --short
find .team/confirm -maxdepth 1 -name '*.request.md' 2>/dev/null | while read -r x; do r="${x%.request.md}.reply.md"; { [ ! -f "$r" ] || [ "$x" -nt "$r" ]; } && echo "미처리: $x"; done
```

## 2. 현행화 (있는 파일만)

- `plan.md` 태스크: 커밋된 것은 `- [x] T<n> … (<SHA>)`. 맨 위 종료·동결 시각이 맞는지 확인.
- `.team/TASKS.md`: 상태 칸만 지금 상태로 (`진행 중` · `컨펌 대기` · `완료 <SHA>` · `BLOCKED`).
- `.team/PROGRESS.md` 맨 아래에 **추가만** (지우거나 덮어쓰지 않는다):
  ```
  - HH:MM CHECKPOINT
    - 진행 중: <T번호 — 담당 — 어디까지>
    - 미처리: <reply 안 쓴 request, 없으면 없음>
    - 다음: <바로 다음 할 일 1~3개, 파일·함수 수준>
    - 미결: <사람 판단이 필요한 것>
    - 시각: 종료 HH:MM / 동결 HH:MM
  ```
  시각은 사람이 마지막으로 말한 것을 쓴다 (Codex는 시계를 못 본다 — 모르면 묻는다).
- 판단이 들어간 결정 중 결정 로그에 빠진 게 있으면 `plan.md` 결정 로그에 한 줄 추가.

## 3. 사람에게 안내

3줄 이내로 바뀐 것을 요약하고, 그대로 붙여넣을 다음 순서를 준다:

```
/new
$teamleader 이어서. plan.md · .team/TASKS.md · .team/PROGRESS.md 마지막 CHECKPOINT 읽고 이어가.
```

미처리 request가 있으면 "새 세션에서 먼저 '컨펌 확인해'"를 덧붙인다.
