# 기여·커밋 규칙

> 2026-09-04 제정. 그 전 커밋 49개는 규칙 없이 쌓였다(타입 접두 없는 것 14개, 첫 줄 72자 초과 42개). 문서 10곳이 옛 SHA를 참조하고 있어 **히스토리는 다시 쓰지 않는다** — 이 규칙은 이 날 이후 커밋부터 적용하고, `.githooks/commit-msg`가 강제한다("훅이 강제, 스킬이 안내").

## 커밋 메시지

```
type(scope): 요약 — 한글, 60자 안, 마침표 없음

왜 바꿨는지 2~5줄. 무엇을 바꿨는지는 diff가 말한다.
사고·실측·근거가 있으면 한 줄로 (예: "09-03 실사고: …", "근거: plans/…").

Co-Authored-By: … (AI 보조 커밋이면 그대로 둔다)
```

**type** (이 여섯만)

| type | 언제 |
|---|---|
| `feat` | 새 기능·새 규칙·새 문서 묶음 |
| `fix` | 잘못된 동작·잘못된 규칙·오타를 고침 |
| `docs` | 문서만 (plans/, README, DIRECTION, changelog) |
| `refactor` | 동작·의미는 그대로, 구조·이름만 (리네임, 파일 이동) |
| `chore` | 빌드·설치·설정·의존성 (install.sh, .gitignore, 훅 배선) |
| `test` | 테스트·스모크만 |

**scope** (이 목록에서, 여러 개면 `·`로: `agents·teamleader`)

`teamleader` `agents` `skills` `hooks` `shell` `madang` `copilot` `brand` `plans` `readme` `direction` `install`

- `madang` = 데스크톱 펫(`claude/tools/madang/`). 프로젝트 전체를 뜻하는 스코프는 없다 — 전체에 걸치면 스코프 생략.
- `brand` = 이름·마스코트·스킨 표·BRANDING.md.

**요약 줄**

- 한글, **60자 안**(훅은 72자에서 막는다). 긴 설명은 본문으로.
- "무엇을"보다 "왜/어떤 결과"가 읽히게: `fix(hooks): 커밋 게이트가 6,900회 전부 실패하던 stdin 결함 수정` ○ / `fix(hooks): gate-commit.sh 수정` ✕
- 티켓 번호는 이 레포엔 없다. 프로젝트 레포(워커)의 규칙은 `claude/skills/teamleader/ways-of-working.md` "커밋 메시지" 항목이 따로 관장한다(Jira 번호 필수, Co-Authored-By 금지 — 회사 레포 정책).

**본문**

- 왜 바꿨는지가 첫 줄. 사고에서 나온 규칙이면 사고 한 줄(날짜·무엇이 어떻게 틀렸나).
- 리네임·이동처럼 큰 변경은 매핑표를 본문에.
- 되돌릴 때 알아야 할 것(다른 레포·심링크·설정과 얽힌 것)이 있으면 마지막 줄에.

**트레일러**

- AI 보조 커밋의 `Co-Authored-By` / `Claude-Session`은 **둔다**. 이 레포는 에이전트 팀으로 만든 물건이라 그게 정직한 표기다.
- `Claude-Session:` 링크는 작업 세션 추적용이라 작성자 본인에게만 열린다. 외부 독자에게는 의미 없는 줄이니 무시해도 된다.

## 커밋 단위

- 한 커밋 = 한 의도. "리네임 + 새 기능"처럼 섞지 않는다(리뷰·되돌리기 단위).
- 문서만 바뀐 것과 코드·규칙이 바뀐 것은 나눈다. 단, 규칙 변경과 그 changelog 항목은 **같은 커밋**(둘이 따로 가면 changelog가 거짓말한다).
- 팀장 세션의 WIP(운영 규칙 보강)는 하루 단위로 모아 `docs(teamleader):` 하나로.

## 브랜치·푸시

- 개인 운영 중이라 `main` 직접 커밋. 공개 후 외부 PR은 `main`으로.
- push는 사람이. 에이전트 세션은 로컬 커밋까지만(밤 작업 포함).

## 설치

`./install.sh`가 `git config core.hooksPath .githooks`와 `commit.template .gitmessage`를 이 레포에 걸어 준다. 클론한 뒤 한 번만.
