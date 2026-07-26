# 스킬 사용 가이드 (역할 × 시점)

> 팀장이 관리. 글로벌 스킬(`~/.claude/skills/`) + 개인 커맨드(`~/.claude/commands/`) + 기본 제공 스킬의 팀 내 사용 기준.
> 프로젝트 스킬(backend-dev, frontend-dev 등 저장소 공유분)은 각 프로젝트 CLAUDE.md/브리프가 지정 — 이 문서 범위 아님.

## 팀장

| 시점 | 스킬 | 용도 |
|---|---|---|
| 세션 시작 | `/teamleader` | 팀장 모드 활성화 (roster·규칙·모델가이드 로드) |
| 새 스토리/에픽 착수 | `/kickoff` | Phase 설계 + PROGRESS.md 초기화 (**팀장 전용** — 허브 문서 작성) |
| 태스크 분해 | `planning-and-task-breakdown` | TASKS.md 태스크 목록 설계 (의존성·병렬성·검증 기준) |
| 상태 확인 | `/progress-check` | PROGRESS/TASKS 기반 전체 상태 브리핑 |
| 체크포인트·세션 종료 | `/save-progress` | PROGRESS.md 현행화 (**팀장 전용**) |
| 설계 결정·보고 검증 | `doubt-driven-development` | 무거운 설계 판단, 팀원 보고가 의심스러울 때 적대적 검증 |
| 체크포인트 품질 검토 | `/code-review` (low~medium) | 브랜치 diff 검토. **`--fix` 금지** (팀장은 소스 수정 불가 — 발견 사항은 정리 태스크로 발행) |
| 버그·아이디어 발견 시 | `/jira-capture` | 티켓 수시 등록 (버그=스프린트 / 아이디어=백로그) |
| 스토리 착수 시 | `/jira-story-cache` → `/jira-refine` (착수 전) | ①Jira 1회 조회→`.claude/stories/` 캐시 생성 ②description 구체화 + 크기 판단(400줄/2일/BE·FE) → 크면 **스토리 분할**. 분할 후 재캐시 |
| PR 머지 시 | `/jira-refine` (완료 후, `done PROJ-…`) | 구현 내용·판단 근거 기록 + 상태 전환. 같은 날 다건은 세션 말미 배치 처리 |
| DB 마이그레이션 관련 브리핑·머지 직전 | `db-migration-order-check` | 새 마이그레이션 배정/충돌 진단 시, 특히 여러 팀원 동시 작업일 때 |
| model-guide 현행화 | `claude-api` + 웹서치 | 성찰 루틴에서 모델 표 갱신 |
| 스킬 인벤토리 점검 (월 1회/스프린트 종료) | `/skill-audit` | 파일 전수 스캔 → `~/.claude/REGISTRY.md` 현행화 → 유지/폐기 판정 + 트렌드 후보 등재 (2026-07-25 신설) |

## 파이리 / 메타몽 (구현 워커)

> 2026-07-13부터 각 팀원 정의(agents/{name}.md)의 "주특기 & 스킬 사용" 섹션에 아래 규칙이 명시돼 있어, 팀원이 슬래시 호출 없이도 스스로 발동한다. 이 표는 팀장의 배분 판단용.

| 시점 | 스킬 | 용도 |
|---|---|---|
| 세션 시작 | `/pairi` / `/metamong` | 정체성 로드 + 기력회복 (reports·TASKS·git log) 후 브리프 대기 |
| M 이상 구현 | `incremental-implementation` | 슬라이스 단위 점진 구현 — **메타몽 주특기** (구현 메인 축) |
| 테스트 실패·버그 1차 | `debugging-and-error-recovery` | 발견한 팀원이 직접 근본 원인 디버깅 (추측 수정 금지) |
| 버그 2회 실패·통합·재현 불가·아키텍처급 | `debugging-and-error-recovery` | **파이리 주특기** — 팀장이 파이리에게 재배정 (관련 보고·커밋 이력 선독 후 진행) |
| 낯선 프레임워크 API | `source-driven-development` | 공식 문서 근거 구현 (기억 의존 금지) |
| 민감 로직·어려운 설계 판단 | `doubt-driven-development` | 인증·마이그레이션·상태전이 등 실수 비용 큰 코드 — 파이리 성향의 태스크에서 특히 |
| 런타임 확인 지시 시 | `/verify` `/run` | 브리프에 명시된 경우만 (기본 검증은 test/lint/build) |
| 새 DB 마이그레이션 파일 작성 시 | `db-migration-order-check` | pull 직후/PR 전/merge 직전 3단계 체크 — 타임스탬프 충돌 반복 방지 (2026-07-09 추가, 이미 적용된 마이그레이션 리네임 금지 규칙 포함) |

## 팀 공통 금지·주의

- **팀원의 `/kickoff` `/save-progress` 사용 금지** — 허브 문서는 팀장 단일 작성자.
- **팀원의 Jira 접근 금지** (`/jira-*` 커맨드·MCP·acli 전부) — 스토리 내용은 `.claude/stories/` 캐시와 브리프로만 받는다. Jira 토큰 비용은 팀장 세션에만 존재하게 설계 (2026-07-12).
- **팀원의 `/simplify`, `/code-review --fix` 금지** — 워킹트리 공유 중이라 타 팀원 파일 침범 위험. 정리는 팀장이 정리 태스크로 발행.
- `/loop` `/schedule`: 팀 워크플로우에서 미사용 (배분·보고 루프는 사람이 중계하는 탭 모드 전제).

## 스킬 상태 평가

> 2026-07-25부터 전체 인벤토리·판정은 `~/.claude/REGISTRY.md`가 원장(개인 환경 소관 — 레포에 두지 않음)(`/skill-audit`이 갱신). 아래 표는 팀 워크플로우 관점 판정 이력만 유지.

### 2026-07-25 점검

| 스킬 | 판정 | 비고 |
|---|---|---|
| `/save-progress` | **이관** | {app-repo} 레포 공유분 → 이 레포 `claude/commands/`로 (팀장 전용 커맨드 정위치. {app-repo} 쪽은 gitignore라 로컬 파일 삭제만) |
| `/skill-audit` | **신설** | 레지스트리 현행화 루틴 — 성찰 루틴 편입 (ways-of-working 참조) |

### 2026-07-03 점검

| 스킬 | 판정 | 비고 |
|---|---|---|
| 글로벌 5종 (debugging/doubt/incremental/planning/source) | 유지 | 범용 프로세스 스킬 — 팀 패턴과 충돌 없음 |
| `/kickoff` | **갱신됨** | 팀장 패턴 연동 노트 추가 (Phase 3 구현 = 팀원 배분, 모델 전략 = model-guide.md 참조) |
| `/progress-check` | 유지 | 읽기 전용이라 누구나 사용 가능하나 실질 사용자는 팀장 |
| `/image` `/jira-capture` | 유지 | 팀 패턴과 독립적인 개인 유틸 |
| `/jira-refine` | **개정됨** | 착수 전: 서브태스크 분해 → 스토리 분할 판단(스토리=PR 1:1) / 완료 후: PR 머지 트리거 + 상태 전환 (2026-07-12) |
| `/jira-story-cache` | **신설** | Jira 읽기 전담(acli) → `.claude/stories/` 캐시. 레포 공유 `jira-story-fetch`는 개인 워크플로우에서 제외 — 팀 동료용으로 존치 (2026-07-12, 근거: `~/Desktop/agent-system-upgrade/reports/03-jira-rules.md`) |
| `/pairi` `/metamong` | **신설** | 워커 세션 시작 커맨드 (2026-07-03) |
| `db-migration-order-check` | **신설** | 프로젝트 스킬(저장소 공유분, repo-root `.claude/skills/`) — 마이그레이션 타임스탬프 충돌 예방/복구 (2026-07-09) |
