---
name: jira-capture
description: 개발 중 발견한 버그(스프린트)나 개선 아이디어(백로그)를 Jira에 빠르게 등록. 팀장 전용.
argument-hint: "[bug|idea] {한 줄 설명}"
---
# jira-capture

개발 중 발견한 버그나 떠오른 개선 아이디어를 Jira에 빠르게 등록한다.

## 언제 사용하나

| 모드 | 상황 | 등록 위치 |
|------|------|-----------|
| **bug** | 개발 중 버그 발견 | 현재 스프린트 |
| **idea** | 개선 아이디어 메모 | 백로그 |

스킬 실행 시 먼저 모드를 확인한다:

> "버그인가요, 개선 아이디어인가요?"

인수로 힌트가 있으면 자동 판단한다. (예: `bug 로그인 시 토큰 만료`, `idea 다크모드 지원`)

---

## 프로젝트 Config

**실행 첫 단계: 현재 프로젝트의 `.claude/team/jira-config.md`를 읽는다** — 도메인·Cloud ID·프로젝트 Key·보드 ID·제품 개요·MCP/acli 전제가 거기 있다.
파일이 없으면 진행을 멈추고 사용자에게 안내한다: "이 프로젝트에는 jira-config.md가 없습니다 — `.claude/team/jira-config.md`를 만들어야 Jira 커맨드를 쓸 수 있어요" (템플릿: 다른 프로젝트 것 참조).

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

### I4. 완료 안내

- 생성된 이슈 Key + URL
- "스프린트 배정은 다음 sprint planning 때 검토"

---

## 가드레일

- Jira 이슈 생성은 반드시 **사용자 확인 후** 실행
- 내용은 간결하게 — description **5줄 이내**
- 스프린트 조회 실패 시 미배정으로 생성, 사용자에게 안내
- description에 체크박스가 필요하면 `contentFormat: "adf"` + ADF `taskList`/`taskItem` 사용 — markdown `- [ ]` 는 체크박스로 렌더링 안 됨
- 체크박스 없는 일반 description은 `contentFormat: "markdown"` 사용 가능

---

## 다른 프로젝트로 전환 시

그 프로젝트에 `.claude/team/jira-config.md`만 새로 작성하면 재사용 가능 (커맨드 수정 불필요).
