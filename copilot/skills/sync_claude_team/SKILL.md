---
name: sync_claude_team
description: Claude Code의 팀장/팀원(teamleader, solver, builder, sketcher) 전역 설정 변경사항을 Copilot CLI의 대응 파일에 반영하는 단방향 동기화. 사용자가 "sync_claude_team", "클로드 팀 설정 동기화", "팀 시스템 동기화"를 요청할 때 사용.
---

# sync_claude_team — Claude → Copilot 팀 시스템 동기화

이 스킬은 `~/.claude/`(Claude Code 전역 설정, **원본**)에 있는 팀장/팀원 시스템 파일이 바뀌었는지 확인하고, 바뀐 내용을 `~/.copilot/`(Copilot CLI 전역 설정)의 대응 파일에 **의미를 보존하며 번역/반영**한다. 단순 파일 복사가 아니다 — 두 도구의 호출 방식·모델 목록·기능이 다르므로 `manifest.md`의 변환 규칙을 따른다.

## 전제

- 대상 파일 목록·변환 규칙: `~/.copilot/skills/sync_claude_team/manifest.md` (항상 먼저 읽을 것)
- 변경 감지용 스냅샷: `~/.copilot/skills/sync_claude_team/.snapshots/` — 마지막 동기화 시점 Claude 원본 사본. 폴더 구조는 `~/.claude/` 하위 경로를 그대로 미러링.

## 절차

1. **manifest.md 읽기** — 전체 파일 쌍과 변환 규칙 숙지.
2. **신규 파일 스캔 (manifest 누락 감지)** — `ls ~/.claude/agents/ ~/.claude/skills/ ~/.claude/commands/` 결과를 manifest 파일 쌍 목록과 대조한다. 팀 시스템 관련 파일(팀원 페르소나, 세션 스킬, 팀장 supporting, 팀 커맨드)인데 manifest에 없는 것이 있으면 **새 행 추가 + `.snapshots/` 대응 디렉토리 생성 + Copilot 대상 파일 신설**부터 한다(개인 유틸·프로젝트 전용은 제외하되, 판단이 애매하면 사용자에게 확인).
3. **변경 감지** — 각 쌍에 대해 `diff -u ~/.copilot/skills/sync_claude_team/.snapshots/{미러경로} ~/.claude/{원본경로}` 실행.
   - **스냅샷 파일이 없으면** diff가 아니라 "최초 동기화"로 취급 — Claude 원본 전체를 읽고 대상 파일과 의미 대조한다(파일 없음을 "변경 없음"으로 오판하지 말 것).
   - diff 없음 → 해당 쌍은 스킵.
   - diff 있음 → 변경분 사람이 읽을 수 있게 정리(무엇이 추가/삭제/수정됐는지 요약).
4. **번역·반영** — 변경이 있는 쌍마다:
   - manifest.md의 해당 변환 규칙 적용 (예: `/solver` 슬래시커맨드 언급 → `skill 도구로 solver 호출`, Claude 전용 모델명 → Copilot 모델명은 model-guide.md 규칙 참고, 특정 프로젝트명 언급은 일반화).
   - Copilot 대상 파일(`~/.copilot/...`)을 **edit 도구로 해당 diff에 대응하는 부분만 수정** (전체 재작성 금지 — Copilot 쪽에서 이미 커스터마이징된 표현은 보존).
   - 정책성 내용(작업 규율, 보고 양식, 체크리스트 등)은 그대로 반영. Claude 전용 기능/용어는 절대 직역하지 말고 Copilot 대응 개념으로 각색.
5. **잔재 검증** — 반영한 Copilot 대상 파일에 Claude 전용 용어가 새어들지 않았는지 grep으로 확인: `grep -nE 'run_in_background|use-claude|use-glm|CLAUDE_CODE_|/model |Artifact 도구|claude-fable|claude-opus' {대상파일}`. 검출되면 각색 누락 — 해당 부분 재작성. (Copilot 폴링 특칙 관련: 백오프 확장(`seq 1 240` 이상)이 Copilot 팀원 파일에 들어가 있으면 안 된다 — 25분 윈도우 제약 위반.)
6. **스냅샷 갱신** — 반영을 마친 쌍은 `~/.claude/{원본경로}` 최신 내용을 `.snapshots/{미러경로}`에 덮어써서 다음 동기화의 기준점으로 삼는다. **신규 쌍도 스냅샷 생성을 빠뜨리지 말 것** (스냅샷 없는 쌍 = 다음 동기화에서 변경 감지 불능).
7. **`.snapshots/last-sync-at.txt` 갱신** — 현재 UTC 타임스탬프 기록 (`date -u +"%Y-%m-%dT%H:%M:%SZ"`).
8. **요약 보고** — 어떤 파일이 바뀌었고 어떻게 반영했는지, 스킵한 항목은 무엇인지, **동기화가 필요했는데 보류 중인 쌍**은 무엇인지 사용자에게 짧게 보고.

## 주의사항

- **단방향**: Copilot 쪽에서만 존재하는 커스터마이징(예: 이 매니페스트 자체, `.snapshots/`, Copilot 전용 모델 표 내용)은 Claude 쪽으로 역반영하지 않는다. 사용자가 명시적으로 반대 방향 동기화를 요청하면 별도로 처리(이 스킬 범위 아님).
- **새 파일 쌍 추가**: Claude 쪽에 `~/.claude/agents/` 또는 `~/.claude/skills/`에 새 팀원/스킬이 추가되면(예: 새 팀원 신설), manifest.md에 새 행을 추가하고 `.snapshots/`에 대응 디렉토리를 만든 뒤 Copilot에도 대응 파일을 신설한다.
- **충돌 시 사람에게 확인**: Claude 원본의 변경이 Copilot 쪽 기존 커스터마이징과 상충하면(예: 서로 다른 방향으로 규칙이 바뀜) 임의로 덮어쓰지 말고 사용자에게 어떻게 반영할지 물어본다.
- 이 스킬은 파일시스템에 직접 접근 가능한 환경(같은 컴퓨터, `~/.claude/`와 `~/.copilot/` 모두 접근 가능)에서만 동작한다.
