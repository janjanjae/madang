# 포켓몬 에이전트 팀 (pokemon-agent-team)

Claude Code(+ GitHub Copilot CLI)로 **"팀장 1 + 구현 팀원 N"** 멀티 세션 개발 팀을 운영하기 위한 설정 모음.
터미널 탭마다 페르소나를 가진 에이전트 세션을 띄우고, 파일 신호로 브리프·컨펌을 주고받는 **탭 모드** 협업 시스템이다.

## 로스터

| 이름 | 역할 | 인사 |
|---|---|---|
| 팀장 (`/teamleader`) | 오케스트레이터 — 브리프 배분, 보고 git 교차검증, 허브 문서(TASKS/PROGRESS) 단일 작성자 | — |
| 파이리 (`/pairi`) | 에이스 구현 + 에스컬레이션 디버깅 | 파이리~! |
| 메타몽 (`/metamong`) | 구현 메인 축 — 어떤 도메인이든 변신, 분신(메타몽1·2)으로 병렬 처리 | 메타몽... |
| 꼬부기 (`/kkobugi`) | UX/UI 프로토타이핑 — worktree 격리, 스크린샷 후보 제시 → 확정안만 메인 반영 | 꼬부기~ 꼬북꼬북! |
| 로토무도감 (`/rotomdex`) | 기술 해설 전담(읽기 전용) — 팀 문서를 감시하며 비개발자에게 쉽게 설명 + 학습 링크 | 로토무! 지지직— |

## 핵심 개념

- **탭 모드**: 사람이 터미널 탭을 열어 팀원 세션을 기동(사람 개입은 탭당 시작 프롬프트 1회). 브리프는 `.claude/team/briefs/{인스턴스}.md` 파일 폴링으로 자동 수령.
- **컨펌 신호 프로토콜**: 커밋 전 팀원이 `.claude/team/confirm/{인스턴스}.request.md`(CONFIRM/BLOCKED/DISCUSS) 작성 → 팀장이 백그라운드 감시로 감지·검증 → `reply.md`(APPROVE/FIX)로 응답.
- **기술 주체성**: 팀원은 공식문서로 브리프를 선검증하고, 세부 판단은 자율, 브리프와 충돌하면 `DISCUSS`로 논의.
- **커밋 게이트 훅**: 파이리·메타몽 세션은 페르소나 frontmatter 훅으로 `git commit`을 차단 — APPROVE reply 또는 팀장이 만든 `commit-waiver` 파일이 있을 때만 통과. 허브 문서(TASKS/PROGRESS) 수정 차단 훅은 전 팀원 적용. ("훅이 강제, 스킬이 안내" — 산문 규칙의 기계적 강제)
- **프로젝트 애든덤**: 프로젝트별 상시 특화는 `{프로젝트}/.claude/team/agents/{이름}.md`에 두면 기력회복 시 베이스 정의 위에 겹쳐 적용(델타만, 통째 오버라이드 금지). 베이스 업데이트는 자동 반영.
- 상세 규칙: `claude/skills/teamleader/ways-of-working.md` · 방향·로드맵: `DIRECTION.md`

## 스킬 한눈에

세션 진입은 전부 `/이름` 명시 호출. 팀장 커맨드는 팀장 전용(`disable-model-invocation`).

**페르소나 세션 (`claude/skills/{이름}/` + `claude/agents/{이름}.md`)**

| 스킬 | 한 줄 |
|---|---|
| `/teamleader` | 팀장 모드 — 배분·보고 git 교차검증·허브 문서 단일 작성. 빈 프로젝트면 `/kickoff` 안내 |
| `/pairi` | 파이리 세션 시작 — 에이스 구현 + 에스컬레이션 디버깅 |
| `/metamong` | 메타몽 세션 시작 — 만능 구현, 분신(메타몽1·2) 병렬 |
| `/kkobugi` | 꼬부기 세션 시작 — UX/UI 프로토타이핑(worktree 격리) |
| `/rotomdex` | 로토무도감 세션 시작 — 기술 해설 전담(읽기 전용, 비개발자 눈높이) |

**팀장 커맨드 (`claude/skills/{이름}/`)**

| 스킬 | 한 줄 |
|---|---|
| `/kickoff` | 새 스토리/에픽 착수 — 팀 폴더 스캐폴딩 + Phase 설계 + 브리프 초안 + PROGRESS 초기화 |
| `/save-progress` | PROGRESS.md 현행화 (체크포인트·세션 종료) |
| `/progress-check` | PROGRESS/TASKS 기반 상태 브리핑 (읽기 전용) |
| `/jira-story-cache` | Jira 스토리 1회 조회 → `.claude/stories/` 로컬 캐시 (acli, 읽기 전담) |
| `/jira-refine` | 스토리 구체화·분할(착수 전) / 구현 기록·상태 전환(PR 머지 후) |
| `/jira-capture` | 버그(스프린트)·아이디어(백로그) 빠른 등록 |
| `/skill-audit` | 스킬 인벤토리 전수 스캔 → `~/.claude/REGISTRY.md` 현행화 (월 1회/스프린트 종료) |

> Jira 커맨드 3종은 프로젝트의 `.claude/team/jira-config.md`(도메인·Key·제품 개요)를 읽어 동작 — 베이스엔 회사 정보 없음. 다른 프로젝트는 그 파일만 새로 쓰면 재사용.

**팀장 구동 문서 (`claude/skills/teamleader/`)**: `roster`(명부) · `ways-of-working`(운영 규칙+변경 이력) · `model-guide`(모델 배분) · `skill-guide`(역할×시점 스킬 매핑).

## 설치

**방법 1 — 심링크 (주 사용 기기, 수정하며 쓸 때)**

```bash
git clone <this-repo> && cd pokemon-agent-team
./install.sh   # ~/.claude, ~/.copilot 에 심링크 생성 (기존 파일은 .bak 백업)
```

**방법 2 — 플러그인 (다른 기기·클라우드 세션, 읽기 전용 사용)**

```
/plugin marketplace add janjanjae/pokemon-agent-team
/plugin install pokemon-team
```

플러그인 설치 시 커맨드는 `/pokemon-team:kickoff`처럼 네임스페이스가 붙는다. 두 방법 병행 가능 — 같은 기기에선 심링크(로컬 파일)가 우선한다.

이후 `~/.claude/...`를 편집하면 그대로 이 레포의 워킹트리 변경이 된다 — 커밋만 하면 팀 시스템이 버전 관리된다.

## 구조

```
DIRECTION.md            # 팀 시스템의 방향 (비전·설계 원칙·로드맵) — 여기부터 읽기
.claude-plugin/         # 마켓플레이스 매니페스트 (플러그인 설치용)
claude/
  agents/               # 팀원 페르소나 (pairi, metamong, kkobugi, rotomdex)
  skills/               # 페르소나 세션 스킬 + teamleader(구동 문서 4종) + 팀장 커맨드 스킬
  skills/teamleader/hooks/   # 커밋 게이트·허브 문서 보호 훅 스크립트
plans/                  # 감사 리포트·설계 스냅샷 (결론은 DIRECTION으로 승격)
copilot/
  skills/sync_claude_team/   # Claude → Copilot 단방향 설정 동기화 (manifest 기반 의미 번역)
install.sh              # ~/.claude, ~/.copilot 심링크
```

## 위치 (4계층 중 "베이스")

이 레포는 개인 AI 환경 4계층(내장 → 개인 → **베이스** → 오버레이) 중 **베이스**다 — 프로젝트 불문 팀 시스템. 개인 계층(프로세스·비개발 스킬)은 별도 비공개 레포 `claude-home`, 프로젝트 특화는 각 프로젝트 `.claude/`(오버레이). 전체 지도는 `~/.claude/DIRECTION.md`.

## 상태

개인 운영 중(private). 회사 정보는 프로젝트 오버레이(`.claude/team/jira-config.md`)로 외부화 완료(E-6) — 베이스엔 하드코딩 없음. 공개 공유 시 `plans/`의 운영 메모 sanitize만 남음.
