---
name: issue-cache
description: 착수할 이슈를 트래커에서 1회 조회해 .claude/stories/ 로컬 캐시 생성 (타입 분기: jira=acli/notion/local. 읽기 전담, 트래커 쓰기 금지). 팀장 전용.
argument-hint: "{KEY}-{n}[, ...] | 스프린트"
---
# issue-cache

착수할 스토리를 Jira에서 1회 조회해 프로젝트 로컬 캐시(`.claude/stories/`)에 저장한다.
이후 팀장·팀원 세션은 Jira를 다시 읽지 않고 이 캐시만 참조한다. **읽기 전담** — Jira 쓰기는 `/issue-refine` 몫.

## 언제 사용하나

- 스토리 착수 시 1회 (팀장 세션에서)
- Jira에서 스토리 내용이 바뀌었다고 **사용자가 알려줬을 때** 재실행 — 에이전트가 변경 감지 폴링하지 않는다
- 팀원 세션은 이 커맨드를 실행하지 않는다 — 캐시 파일만 읽는다 (팀원 쪽 Jira 토큰 비용 = 0)

---

## 프로젝트 Config

**실행 첫 단계: 현재 프로젝트의 `.claude/team/tracker-config.md`를 읽는다** — 도메인·Cloud ID·프로젝트 Key·보드 ID·제품 개요·MCP/acli 전제가 거기 있다.
파일이 없으면 진행을 멈추고 사용자에게 안내한다: "이 프로젝트에는 tracker-config.md가 없습니다 — `.claude/team/tracker-config.md`를 만들어야 Jira 커맨드를 쓸 수 있어요" (템플릿: issue-cache 스킬 디렉토리의 `tracker-config.template.md` 복사).

**타입 분기**: `jira`면 아래 본문(acli 조회→캐시)대로. `notion`이면 `backlog-check` Config의 DB에서 해당 항목(프로젝트 태그값 + 제목)을 fetch해 아래 캐시 템플릿 포맷으로 `.claude/stories/{슬러그}.md`에 저장한다 (항목 상태가 `티켓화`가 아니면 kickoff의 선택 절차를 먼저 안내). `local`이면 백로그 파일의 해당 항목을 같은 포맷으로 복사한다. 읽기 전담·캐시 포맷·재캐시 규칙은 타입 공통.

- **캐시 경로 규칙(프로젝트 불문)**: `{프로젝트 루트}/.claude/stories/`

---

## 실행 절차

### 1. 대상 확인

- 인수로 이슈 키를 받는다 (예: `PROJ-656`, 쉼표 구분 복수 가능). 없으면 사용자에게 확인.
- "스프린트 전체" 요청 시: 활성 스프린트에서 내 담당 To Do/In Progress만 조회.

### 2. acli 조회 — 필요 필드만

특정 이슈:

```bash
acli jira workitem view {Key}-{n} --json --fields 'key,summary,status,priority,description,parent,issuelinks,sprint,assignee'
```

스프린트 전체:

```bash
acli jira workitem search \
  --jql 'project = {Key} AND sprint in openSprints() AND assignee = currentUser() AND status in ("To Do", "In Progress") ORDER BY priority DESC' \
  --json --fields 'key,summary,status,priority,description,parent,sprint'
```

### 3. 캐시 파일 생성

```bash
mkdir -p .claude/stories/
```

파일명: `{Key}-{n}.md` — **재조회 시 같은 파일을 덮어쓴다** (캐시이므로 파일명에 슬러그·스프린트 등 가변 요소를 넣지 않는다).

템플릿:

```markdown
# {Key}-{n}: {summary}

> Jira 캐시 — 직접 수정 금지, 갱신은 `/issue-cache {Key}-{n}` 재실행
> 캐시 생성: {YYYY-MM-DD} · 원본: https://{config의 도메인}/browse/{프로젝트 Key}-{n}

**Status**: {status} · **Priority**: {priority} · **Sprint**: {sprint}
**Epic/상위**: {parent 키+제목, 없으면 "-"} · **링크**: {issuelinks 요약, 없으면 "-"}

## Description (Jira 원문)

{description을 마크다운으로 정리. 없으면 "(비어 있음 — /issue-refine 착수 전 모드 필요)"}

## 수락 조건

{description 내 AC 체크리스트. 없으면 "(없음 — /issue-refine 착수 전 모드 필요)"}
```

### 4. 완료 안내

- 생성/갱신된 파일 경로 목록만 출력하고 **여기서 멈춘다**.
- description·AC가 비어 있으면 `/issue-refine` 착수 전 모드를 안내.
- 검토 질문·구체화·분할 판단은 이 커맨드의 일이 아니다.

---

## 가드레일

- **읽기 전용** — Jira에 어떤 쓰기도 하지 않는다
- 캐시는 Jira 원본의 사본 — 로컬에서 내용을 수정하지 않는다. 고칠 내용이 생기면 `/issue-refine`으로 Jira에 반영한 뒤 재캐시
- 조회는 `--fields`로 필요한 필드만 (전체 JSON 덤프 금지)
- `acli` 인증 오류 시: `acli auth` 실행 안내
- 이슈 없음: 키 확인 요청

---

## 다른 프로젝트로 전환 시

그 프로젝트에 `.claude/team/tracker-config.md`만 새로 작성하면 재사용 가능 (커맨드 수정 불필요).
