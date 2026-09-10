---
name: issue-add
description: 개발 중 발견한 버그·개선 아이디어를 빠르게 등록 — 팀 티켓(Jira) vs 개인 백로그 분기, tracker-config 타입 분기(jira/notion/local/github). 팀장 전용.
argument-hint: "[bug|idea] {한 줄 설명}"
---
# issue-add

개발 중 발견한 버그나 떠오른 개선 아이디어를 Jira에 빠르게 등록한다.

## 언제 사용하나

| 모드 | 상황 | 등록 위치 |
|------|------|-----------|
| **bug** | 개발 중 버그 발견 | 현재 스프린트 |
| **idea** | 개선 아이디어 메모 | 백로그 |

스킬 실행 시 먼저 모드를 확인한다:

> "버그인가요, 개선 아이디어인가요?"

인수로 힌트가 있으면 자동 판단한다. (예: `bug 로그인 시 토큰 만료`, `idea 다크모드 지원`)

## 팀 티켓 vs 개인 백로그 분기 (모드 확인 직후)

팀 Jira 등록은 **팀 합의가 필요한 일감일 때만** — 스프린트·백로그 임의 추가는 지양한다. 등록 전에 판단한다:

- **팀 티켓**: 팀원이 고쳐야 할 버그, 팀 로드맵에 올릴 개선 → 아래 Bug/Idea 모드로 진행
- **개인 메모**: 개인적 관찰·아이디어·기술부채, 아직 팀에 올릴 확신이 없는 것 → **개인 백로그로 등록** (사용자 스킬 `backlog-check`의 Config 절이 가리키는 노션 DB에 `notion-create-pages` — 상태 `inbox`, 출처 `AI세션`). 그 스킬이 없는 환경이면: "개인 백로그가 설정되지 않았습니다 — 팀 Jira에 등록할까요, 보류할까요?"로 안내

애매하면 개인 백로그가 기본값이다 (개인 → 팀 승격은 `/backlog-check` 트리아지에서 가능하지만, 팀 Jira에 잘못 올라간 건 되돌리기 번거롭다).

---

## 프로젝트 Config

**실행 첫 단계: 현재 프로젝트의 `.claude/team/tracker-config.md`를 읽는다** — 도메인·Cloud ID·프로젝트 Key·보드 ID·제품 개요·MCP/acli 전제가 거기 있다.
파일이 없으면 진행을 멈추고 사용자에게 안내한다: "이 프로젝트에는 tracker-config.md가 없습니다 — `.claude/team/tracker-config.md`를 만들어야 Jira 커맨드를 쓸 수 있어요" (템플릿: issue-fetch 스킬 디렉토리의 `tracker-config.template.md` 복사).

**타입 분기**: config의 `타입`이 `jira`면 아래 본문대로 진행한다. `notion`/`local`이면 팀 Jira 경로 자체가 없으므로 **모든 캡처가 개인 백로그로** 간다 — notion: `backlog-check` Config의 DB에 등록(프로젝트 태그값 사용), local: 백로그 파일에 `## {제목}` 항목 추가. 이 경우 아래 "팀 티켓 vs 개인 백로그 분기"와 Bug/Idea 모드의 Jira 절차는 건너뛴다 (초안 작성 원칙은 동일 적용).

`github`이면 **이 레포의 GitHub Issues가 팀 트래커 자리**다 — `local`처럼 개인 백로그로 흘려보내지 않는다. 위 "팀 티켓 vs 개인 백로그 분기"는 그대로 적용하되 팀 티켓 쪽 목적지가 `gh issue create`이고, B1/I1 내용 파악과 B2/I2 초안 형식(5줄 이내)·사용자 승인 가드레일도 그대로다. 달라지는 것만:

- **생성**: `gh issue create -R {owner}/{repo} --title "{제목}" --body-file - --label {bug|enhancement}` (본문은 초안을 stdin으로)
- **라벨**: bug 모드 → `--label bug` / idea 모드 → `--label enhancement` + 제목 앞에 `[개선] ` — 라벨이 레포에 없으면 tracker-config 템플릿 `[타입: github]` 절의 "라벨 없음 시" 참조
- **milestone은 붙이지 않는다** — 아래 "기한은 배분 시점에"의 github 판이다
- **건너뛰는 것**: 스프린트 조회(B3)·issuetype·priority·ADF 절차 (GitHub에 대응물이 없다)
- **생성 전 인증 확인**: 가드레일은 tracker-config 템플릿 `[타입: github]` 절(SSOT) 참조
- **완료 안내**: 이슈 번호(`#{번호}`) + URL

---

## [Bug 모드] 버그 등록

### B1. 내용 파악

대화 컨텍스트에서 파악하거나 사용자에게 확인:

- **현상**: 어떤 문제가 발생하는가 (1문장)
- **재현 조건**: 언제/어떤 상황에서 발생하는가
- **영향 범위**: 어떤 기능/사용자에게 영향을 주는가

### B2. 이슈 초안 작성

아래 형식으로 초안을 작성해 사용자에게 제시:

```
{현상 한 줄}

**재현 조건**: {조건}
**영향 범위**: {범위}
**제안**: {수정 방향 — 있는 경우만}
```

### B3. 현재 스프린트 조회

`searchJiraIssuesUsingJql`로 활성 스프린트 ID 조회:

```
project = {Key} AND sprint in openSprints() ORDER BY created DESC
```

결과에서 `sprint` 필드의 ID 추출. 조회 실패 시 스프린트 미배정으로 생성하고 사용자에게 안내.

### B4. Jira 생성

사용자 승인 후 `createJiraIssue`로 생성:

- **issuetype**: `버그` (오류 시 `getJiraProjectIssueTypesMetadata`로 확인)
- **summary**: `{현상 한 줄}`
- **description**: `contentFormat: "markdown"`으로 B2 초안 내용
- **priority**: `Medium`
- **sprint**: 조회한 활성 스프린트 ID
- **duedate**: 🔴 **비워 둔다** (아래 "기한은 배분 시점에" 참조)

### B5. 완료 안내

- 생성된 이슈 Key + URL

---

## [Idea 모드] 개선 아이디어 등록

### I1. 내용 파악

대화 컨텍스트에서 파악하거나 사용자에게 확인:

- **아이디어**: 무엇을 개선하고 싶은가 (1문장)
- **배경**: 왜 필요한가, 어떤 문제를 해결하는가 (1~2문장)

### I2. 이슈 초안 작성

아래 형식으로 초안을 작성해 사용자에게 제시:

```
{아이디어 한 줄}

**배경**: {왜 필요한가 — 현재 문제점}
**제안**: {어떻게 개선하면 좋겠는지}
```

### I3. Jira 생성

사용자 승인 후 `createJiraIssue`로 생성:

- **issuetype**: `스토리` (오류 시 `getJiraProjectIssueTypesMetadata`로 확인)
- **summary**: `[개선] {아이디어 한 줄}`
- **description**: `contentFormat: "markdown"`으로 I2 초안 내용
- **priority**: `Medium`
- **labels**: `improvement`
- 스프린트 미배정 (백로그)
- **duedate**: 🔴 **비워 둔다** (아래 "기한은 배분 시점에" 참조)

### I4. 완료 안내

- 생성된 이슈 Key + URL
- "스프린트 배정은 다음 sprint planning 때 검토"

---

## 기한은 배분 시점에 — 캡처 때는 비운다 (2026-08-20 확정)

**`duedate` = 그 티켓이 나갈 PR 묶음**이다. 하루에 PR 1~2개가 나가므로 날짜가 사실상 묶음 식별자다.

| 시점 | `duedate` / 시작일 | 누가 |
|---|---|---|
| **캡처(이 스킬)** | **비움** | — |
| **배분(브리프 작성)** | **필수 입력 = 그 PR 예정일** | 팀장 |
| PR 발행 | (기한 대신) 티켓에 PR 링크 코멘트 | 팀장 |

- 캡처 시점에 비우는 이유: 스모크 중 개선 건이 여러 개 쏟아지는데 그때마다 기한을 고민하면 **흐름이 끊기고**, 그 순간엔 크기·우선순위·담당 정보가 아직 없다. 캡처는 빠른 게 미덕이다.
- 이 규칙 하에서 **"기한 없음 = 아직 배분 안 된 것"**이 된다 → `assignee = currentUser() AND duedate IS EMPTY AND status != 완료`가 곧 미배분 백로그.
- ⚠️ **사용자가 캡처 시점에 기한을 명시하면 그대로 넣는다** — 위는 기본값이지 금지가 아니다.
- **타입 `github`**: `duedate` 자리를 **milestone**이 대신한다 (GitHub 이슈엔 마감일 필드가 없다). 캡처 때는 비우고, 배분 시점에 `gh issue edit -R {owner}/{repo} {번호} --milestone "{PR 묶음}"`. 따라서 "milestone 없음 = 미배분 백로그"가 된다 — 조회 쿼리는 tracker-config 템플릿 `[타입: github]` 절(SSOT) 참조.
- 계기: 2026-08-20 — PROJ-1085가 코드는 이미 커밋돼 PR에 실려 있었는데 **배분 시점에 Jira를 안 갱신**해서 사용자 현황판에서 사라져 있었다. 문제는 캡처가 아니라 배분 시점 누락이었다.

---

## 가드레일

- Jira 이슈 생성은 반드시 **사용자 확인 후** 실행
- 내용은 간결하게 — description **5줄 이내**
- 스프린트 조회 실패 시 미배정으로 생성, 사용자에게 안내
- description에 체크박스가 필요하면 `contentFormat: "adf"` + ADF `taskList`/`taskItem` 사용 — markdown `- [ ]` 는 체크박스로 렌더링 안 됨
- 체크박스 없는 일반 description은 `contentFormat: "markdown"` 사용 가능

---

## 다른 프로젝트로 전환 시

그 프로젝트에 `.claude/team/tracker-config.md`만 새로 작성하면 재사용 가능 (커맨드 수정 불필요).
