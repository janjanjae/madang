# 트래커 Config ({프로젝트 이름})

> issue-cache · issue-refine · issue-capture 스킬이 읽는 프로젝트별 트래커 설정.
> **이 파일을 프로젝트의 `.claude/team/tracker-config.md`로 복사한 뒤, 타입을 정하고 해당 절만 채워라** (다른 타입 절은 삭제).
> 위치가 `.claude/team/`인 이유: gitignore 영역(레포 동료 비노출) + 팀장 수정 가능 영역.
> 다른 프로젝트로 전환 시 이 파일만 그 프로젝트에 새로 작성하면 스킬은 그대로 재사용된다.

## 타입

- **타입**: `jira` | `notion` | `local` | `github` 중 하나

| 타입 | 언제 | 이슈의 SSOT |
|---|---|---|
| `jira` | 팀 프로젝트 (스프린트·보드 협업) | 팀 Jira |
| `notion` | 개인 프로젝트 (개인 dev 백로그 DB 사용) | 노션 백로그 DB의 해당 프로젝트 항목 |
| `local` | 오프라인/최소 구성 | `.claude/team/backlog.md` |
| `github` | 공개 개인 레포 (GitHub Issues) | GitHub Issues |

## [타입: jira] 연결 정보

- **Atlassian 도메인**: `{yoursite}.atlassian.net`
- **Cloud ID**: `{getAccessibleAtlassianResources로 조회한 UUID}`
- **프로젝트 Key**: `{KEY}`
- **보드 ID**: `{보드 URL의 boards/ 뒤 숫자}`
- **읽기 CLI**: `acli` (설치돼 있으면) — 조회는 MCP 대신 CLI (토큰 절약). 쓰기(ADF 필요)는 MCP.
  acli가 없으면 읽기도 MCP(`searchJiraIssuesUsingJql` + `fields` 파라미터 최소화)로 대체.

> ⚠️ **MCP 연결 전제조건**: Atlassian MCP 인증 + 해당 사이트 접근 권한 필요.
> 연결 안 된 경우: Claude Code에서 Atlassian MCP 재인증 → 해당 사이트 선택.
> acli 인증 오류 시: `acli auth` 실행.

## [타입: notion] 연결 정보

- **DB 좌표**: 사용자 스킬 `backlog-check`의 Config 절 참조 — **여기에 중복 기재 금지** (좌표 SSOT는 그 한 곳).
- **프로젝트 태그값**: `{노션 DB '프로젝트' select의 이 프로젝트 값}`
- backlog-check 스킬이 없는 환경이면 notion 타입은 사용 불가 — local로 전환.

## [타입: local] 연결 정보

- **백로그 파일**: `.claude/team/backlog.md` (항목 = `## {제목}` 헤더 단위, 본문에 배경·상태 표기)

## [타입: github] 연결 정보

- **레포**: `{owner}/{repo}`
- **gh 계정**: `{이 레포에 이슈를 쓸 GitHub 계정 로그인}`
  - 🔴 스킬은 `gh auth status --active`가 위 계정과 다르면 **스스로 전환하지 말고 멈추고**
    사용자에게 `gh auth switch -u {계정}`을 요청한다 (전역 인증을 에이전트가 말없이 바꾸면 이후 다른 레포 작업이 잘못된 계정으로 나간다).
- **개념 매핑** (Jira 기준 규약을 GitHub으로 옮긴 것 — 세 스킬이 공통으로 따른다):
  | Jira | GitHub | 비고 |
  |---|---|---|
  | 이슈 키 `{KEY}-{n}` | `#{번호}` | 인수는 `#591`·`591` 둘 다 받는다. 캐시 파일명 `.claude/stories/{번호}.md` |
  | issuetype 버그 / 스토리 | label `bug` / `enhancement` | |
  | sprint | (없음) | milestone이 그 역할까지 겸한다 |
  | `duedate` = PR 묶음 식별자 | **milestone** | GitHub 이슈엔 마감일 필드가 없다. 미배분 백로그 = milestone 없음 |
  | 미배분 백로그 JQL | `--assignee @me --search "no:milestone state:open"` | |
  | status 전환 | open / closed | 🔴 닫는 것은 사용자 소관 (Jira 상태 전환 규칙과 동일) |
  | `assignee = currentUser()` | `--assignee @me` | |

> ⚠️ **전제**: `gh` CLI 설치 + `gh auth status`에 위 계정이 로그인돼 있을 것.
> 미설치/미인증이면: `brew install gh` → `gh auth login`.
> 사내망·프록시 때문에 GitHub API가 403이면 우회하지 말고 네트워크 사유로 보고하고 멈춘다.

## 제품 개요 (타입 공통 — 이슈 구체화 시 컨텍스트)

{이 프로젝트가 무엇인지 2~3문장. issue-refine이 이슈를 구체화할 때 도메인 컨텍스트로 쓴다.}

**핵심 기능:**
- {핵심 기능 1}
- {핵심 기능 2}

**주요 통합**: {외부 시스템·인증·인프라 등 — 없으면 삭제}

## 프로젝트별 참고

- {이 프로젝트에서만 유효한 트래커 관련 규칙·주의사항 — 없으면 절 삭제}
