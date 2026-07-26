---
description: 착수할 스토리를 Jira에서 acli로 1회 조회해 .claude/stories/ 로컬 캐시 생성 (읽기 전담, Jira 쓰기 금지). 팀장 전용.
argument-hint: "PROJ-{n}[, PROJ-{m}...] | 스프린트"
---
# jira-story-cache

착수할 스토리를 Jira에서 1회 조회해 프로젝트 로컬 캐시(`.claude/stories/`)에 저장한다.
이후 팀장·팀원 세션은 Jira를 다시 읽지 않고 이 캐시만 참조한다. **읽기 전담** — Jira 쓰기는 `/jira-refine` 몫.

## 언제 사용하나

- 스토리 착수 시 1회 (팀장 세션에서)
- Jira에서 스토리 내용이 바뀌었다고 **사용자가 알려줬을 때** 재실행 — 에이전트가 변경 감지 폴링하지 않는다
- 팀원 세션은 이 커맨드를 실행하지 않는다 — 캐시 파일만 읽는다 (팀원 쪽 Jira 토큰 비용 = 0)

---

## 프로젝트 Config (현재: {app-repo} / BMAD)

- **Atlassian 도메인**: `{yoursite}.atlassian.net`
- **프로젝트 Key**: `BMAD`
- **보드 ID**: `4120`
- **CLI**: `acli` (`/opt/homebrew/bin/acli`) — MCP 대신 CLI 사용 (토큰 절약)
- **캐시 경로**: `{프로젝트 루트}/.claude/stories/`

> 레포 공유 스킬 `jira-story-fetch`({app-repo}/.claude/skills)와 별개의 개인 커맨드.
> 그쪽은 팀 동료용(`{app-dir}/docs/stories/`에 생성 + 검토 질문 포함)이고,
> 이 커맨드는 조회→캐시만 한다. 검토·구체화는 `/jira-refine`에서.

---

## 실행 절차

### 1. 대상 확인

- 인수로 이슈 키를 받는다 (예: `PROJ-656`, 쉼표 구분 복수 가능). 없으면 사용자에게 확인.
- "스프린트 전체" 요청 시: 활성 스프린트에서 내 담당 To Do/In Progress만 조회.

### 2. acli 조회 — 필요 필드만

특정 이슈:

```bash
acli jira workitem view PROJ-{n} --json --fields 'key,summary,status,priority,description,parent,issuelinks,sprint,assignee'
```

스프린트 전체:

```bash
acli jira workitem search \
  --jql 'project = BMAD AND sprint in openSprints() AND assignee = currentUser() AND status in ("To Do", "In Progress") ORDER BY priority DESC' \
  --json --fields 'key,summary,status,priority,description,parent,sprint'
```

### 3. 캐시 파일 생성

```bash
mkdir -p .claude/stories/
```

파일명: `PROJ-{n}.md` — **재조회 시 같은 파일을 덮어쓴다** (캐시이므로 파일명에 슬러그·스프린트 등 가변 요소를 넣지 않는다).

템플릿:

```markdown
# PROJ-{n}: {summary}

> Jira 캐시 — 직접 수정 금지, 갱신은 `/jira-story-cache PROJ-{n}` 재실행
> 캐시 생성: {YYYY-MM-DD} · 원본: https://{yoursite}.atlassian.net/browse/PROJ-{n}

**Status**: {status} · **Priority**: {priority} · **Sprint**: {sprint}
**Epic/상위**: {parent 키+제목, 없으면 "-"} · **링크**: {issuelinks 요약, 없으면 "-"}

## Description (Jira 원문)

{description을 마크다운으로 정리. 없으면 "(비어 있음 — /jira-refine 착수 전 모드 필요)"}

## 수락 조건

{description 내 AC 체크리스트. 없으면 "(없음 — /jira-refine 착수 전 모드 필요)"}
```

### 4. 완료 안내

- 생성/갱신된 파일 경로 목록만 출력하고 **여기서 멈춘다**.
- description·AC가 비어 있으면 `/jira-refine` 착수 전 모드를 안내.
- 검토 질문·구체화·분할 판단은 이 커맨드의 일이 아니다.

---

## 가드레일

- **읽기 전용** — Jira에 어떤 쓰기도 하지 않는다
- 캐시는 Jira 원본의 사본 — 로컬에서 내용을 수정하지 않는다. 고칠 내용이 생기면 `/jira-refine`으로 Jira에 반영한 뒤 재캐시
- 조회는 `--fields`로 필요한 필드만 (전체 JSON 덤프 금지)
- `acli` 인증 오류 시: `acli auth` 실행 안내
- 이슈 없음: 키 확인 요청

---

## 다른 프로젝트로 전환 시

상단 **프로젝트 Config** 블록(도메인·프로젝트 Key·보드 ID·캐시 경로)만 수정하면 재사용 가능.
