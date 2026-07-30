# 스킬 사용 가이드 (역할 × 시점)

> 팀장이 관리. 글로벌 스킬(`~/.claude/skills/`) + 개인 커맨드(`~/.claude/commands/`) + 기본 제공 스킬의 팀 내 사용 기준.
> 프로젝트 스킬(backend-dev, frontend-dev 등 저장소 공유분)은 각 프로젝트 CLAUDE.md/브리프가 지정 — 이 문서 범위 아님.

## 트리거 사전 (2026-07-29 신설)

> "스프린트"처럼 경계가 모호한 추상 단위가 아니라 **관찰 가능한 사건**에 실행 시점을 앵커한다. 각 사건이 어떤 스킬과 부수 작업을 발동시키는지의 원장. 아래 팀장/워커 표는 이 사전의 스킬별 상세.

| 사건 (트리거) | 판별 기준 | 실행 | 이때 함께 하는 것 |
|---|---|---|---|
| **프로젝트 첫 투입** | `.claude/team/` 구조 없음 | `/kickoff`의 Step 6 부트스트랩 (멱등 — 재실행 무해) | 폴더 스캐폴딩. tracker-config는 필요 시점에 |
| **스토리/에픽 착수** | 새 스토리 작업을 시작하는 순간 | `/kickoff` **한 번** — Step 1이 소스 선택(팀=Jira 스토리 캐시 / 개인=노션 백로그 후보)과 story-cache 실행·refine 선행 안내를 내부에서 수행 | **허브 문서 아카이빙** (구 스토리·"대체됨" 블록 → `.claude/archive/`, Step 6) + TASKS 재설계 |
| **컨텍스트 만석·세션 종료** | 팀장 컨텍스트 압박 | `/save-progress` | PROGRESS 롤링 (최신+직전 1개만, 밀려난 블록 → archive). TASKS 아카이빙은 여기서 안 함 |
| **작업 중 발견** | 버그·아이디어를 인지한 순간 (수시) | `/issue-capture` | 팀 티켓 vs 개인 백로그 분기 — 애매하면 개인 |
| **PR 머지** | 머지 이벤트 | `/issue-refine` (완료 후 모드) | 같은 날 다건은 세션 말미 배치 |
| **월 1회 / "이 스킬 뭐더라" 신호** | 달력 또는 반복 질문 | `/skill-audit` | REGISTRY 현행화 + 방치 백로그 정리 |

> **kickoff는 프로젝트 시작 1회용이 아니다** — 착수(스토리/에픽) 단위로 매번 실행한다. 1회성인 것은 Step 6의 부트스트랩 부분뿐이고 멱등이라 구분할 필요 없이 그냥 실행하면 된다. "스프린트 종료 작업"이라는 별도 트리거는 두지 않는다 — 종료는 모호하지만 다음 착수는 명확하므로, 종료 시점 일은 전부 다음 착수(아카이빙·백로그 정리)나 PR 머지(issue-refine done)에 붙어 있다.

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
| 버그·아이디어 발견 시 | `/issue-capture` | 티켓 수시 등록 (버그=스프린트 / 아이디어=백로그) |
| 스토리 착수 시 | `/issue-cache` → `/issue-refine` (착수 전) | ①Jira 1회 조회→`.claude/stories/` 캐시 생성 ②description 구체화 + 크기 판단(400줄/2일/BE·FE) → 크면 **스토리 분할**. 분할 후 재캐시. **보통 `/kickoff` Step 1이 내부 실행** — 단독 호출은 캐시 갱신·분할만 따로 필요할 때 |
| PR 머지 시 | `/issue-refine` (완료 후, `done PROJ-…`) | 구현 내용·판단 근거 기록 + 상태 전환. 같은 날 다건은 세션 말미 배치 처리 |
| DB 마이그레이션 관련 브리핑·머지 직전 | `db-migration-order-check` | 새 마이그레이션 배정/충돌 진단 시, 특히 여러 팀원 동시 작업일 때 |
| model-guide 현행화 | `claude-api` + 웹서치 | 성찰 루틴에서 모델 표 갱신 |
| 스킬 인벤토리 점검 (월 1회/스프린트 종료) | `/skill-audit` | 파일 전수 스캔 → `~/.claude/REGISTRY.md` 현행화 → 유지/폐기 판정 + 트렌드 후보 등재 (2026-07-25 신설) |

## 파이리 / 메타몽 / 꼬부기 (구현 워커)

> 2026-07-13부터 각 팀원 정의(agents/{name}.md)의 "주특기 & 스킬 사용" 섹션에 아래 규칙이 명시돼 있어, 팀원이 슬래시 호출 없이도 스스로 발동한다. 이 표는 팀장의 배분 판단용.
> 2026-07-27(E-5): 에이전트 frontmatter에 `skills`(서브에이전트 스폰 시 프리로드)·`memory: project`(팀원별 영속 메모리) 추가 — 탭 모드에선 부분 적용이라 산문 규칙 병행 유지. 꼬부기 주특기 섹션 신설(공식문서 선검증·디자인 판단 반박검증·셀프체크 증거).

| 시점 | 스킬 | 용도 |
|---|---|---|
| 세션 시작 | `/pairi` / `/metamong` | 정체성 로드 + 기력회복 (reports·TASKS·git log) 후 브리프 대기 |
| M 이상 구현 | `incremental-implementation` | 슬라이스 단위 점진 구현 — **메타몽 주특기** (구현 메인 축) |
| 테스트 실패·버그 1차 | `debugging-and-error-recovery` | 발견한 팀원이 직접 근본 원인 디버깅 (추측 수정 금지) |
| 버그 2회 실패·통합·재현 불가·아키텍처급 | `debugging-and-error-recovery` | **파이리 주특기** — 팀장이 파이리에게 재배정 (관련 보고·커밋 이력 선독 후 진행) |
| 낯선 프레임워크 API | `source-driven-development` | 공식 문서 근거 구현 (기억 의존 금지) |
| 민감 로직·어려운 설계 판단 | `doubt-driven-development` | 인증·마이그레이션·상태전이 등 실수 비용 큰 코드 — 파이리 성향의 태스크에서 특히 |
| 런타임 확인 지시 시 | `/verify` `/run` | 브리프에 명시된 경우만 (기본 검증은 test/lint/build) |
| 완료 주장·컨펌 요청 직전 | `verification-before-completion` | 검증 명령을 실제 실행한 증거 없이 "됐다" 금지 — 컨펌 게이트의 스킬 계층 (2026-07-27 상류 도입) |
| 새 DB 마이그레이션 파일 작성 시 | `db-migration-order-check` | pull 직후/PR 전/merge 직전 3단계 체크 — 타임스탬프 충돌 반복 방지 (2026-07-09 추가, 이미 적용된 마이그레이션 리네임 금지 규칙 포함) |

## 팀 공통 금지·주의

- **팀원의 `/kickoff` `/save-progress` 사용 금지** — 허브 문서는 팀장 단일 작성자.
- **팀원의 Jira 접근 금지** (`/issue-*` 커맨드·MCP·acli 전부) — 스토리 내용은 `.claude/stories/` 캐시와 브리프로만 받는다. Jira 토큰 비용은 팀장 세션에만 존재하게 설계 (2026-07-12).
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
