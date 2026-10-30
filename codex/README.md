# codex/ — 마당 Codex판

```bash
git clone https://github.com/janjanjae/madang /tmp/madang
bash /tmp/madang/codex/install.sh --restricted   # 감독·폐쇄 환경용. 기본판은 옵션 없이
```

작업 공간 **루트**에서 실행한다. `/tmp`는 작업 공간 밖이라 IDE 파일 트리에 안 보일 수 있다 — 이 문서는 `cat /tmp/madang/codex/README.md`로 보거나, Codex에게 "/tmp/madang/codex/README.md 읽고 설치해줘"라고 시킨다.
설치 후 **codex를 다시 켠다**(`exit` → `codex`). 스킬·에이전트·AGENTS.md는 세션 시작 때 읽힌다.

Claude Code판 마당과 **같은 팀(도담·번뜩·몽글·슥슥·조잘), 같은 파일 신호, 같은 작업 규율**을 Codex CLI 기능으로 옮긴 판이다.

## 설치되는 것

| 작업 공간 경로 | 원본 | 내용 |
|---|---|---|
| `.agents/skills/teamleader/` | `skills/teamleader` | 팀장 도담 — 배분·컨펌 루프·허브 문서 (`$teamleader`) |
| `.agents/skills/planning-and-task-breakdown/` | `skills/…` | 문제 정의 → plan.md → 수직 슬라이스 |
| `.agents/skills/incremental-implementation/` | `skills/…` | 슬라이스 단위 구현 + 최소코드 사다리 |
| `.agents/skills/debugging-and-error-recovery/` | `skills/…` | 재현 → 원인 → 수정 → 회귀 테스트 |
| `.agents/skills/verification-before-completion/` | `skills/…` | 증거 없는 완료 주장 금지 (superpowers 원본) |
| `.codex/agents/solver.toml` | `agents/` | 번뜩 — 깊이 (어려운 문제 하나, 2회 실패 버그) |
| `.codex/agents/builder.toml` | `agents/` | 몽글 — 넓이 (같은 모양의 독립 태스크 여러 개) |
| `.codex/agents/sketcher.toml` | `agents/` | 슥슥 — 시안 (UI를 코드로 만들고 미리보기로 확인) |
| `.codex/agents/narrator.toml` | `agents/` | 조잘 — 해설 (읽기 전용, 구조·결정 설명) |
| `.codex/hooks.json` + `.codex/hooks/madang_hook.py` | `hooks/` | 커밋 게이트 · 허브 문서 보호 · (`--restricted`) push 차단 |
| `AGENTS.md` | `AGENTS.md` (+ `AGENTS.restricted.md`) | 작업 규칙 템플릿 — 과제별 칸만 채운다 |
| `.team/{briefs,confirm,reports,plans}/`, `.team/TASKS.md`, `.team/PROGRESS.md` | `templates/team/` | 파일 신호 폴더 + 허브 문서 |

- 이미 있는 파일은 **덮어쓰지 않고 건너뛴다**. 두 번 돌려도 안전하다.
- `~/.codex` 같은 전역 설정은 건드리지 않는다. Codex를 업데이트하지 않는다. 네트워크에 접속하지 않는다.

## `--restricted` — 감독·폐쇄 환경용

옵션 하나로 아래가 추가된다.
- `.codex/madang-restricted` 표식 → 훅이 `git push`를 막는다 ("제한 환경: push 금지 — 로컬 커밋까지만")
- `AGENTS.md`에 「제한 환경 규칙」 절: 외부 전송 금지 · 개인 키·다른 모델 연결 금지 · 플랫폼 관리 설정 수정 금지 · 도구 업데이트 금지 · 토큰 절약(반복 요청·폴링 루프 금지) · 서버는 별도 터미널 `0.0.0.0`

## 쓰는 법

**혼자 (기본)** — 탭 하나. AGENTS.md 규칙과 스킬만으로 진행한다.
- `/skills` — 인식된 스킬 목록, `$이름` — 직접 호출 (설명이 맞는 상황이면 Codex가 스스로 부르기도 한다)

**팀으로** — 계획을 세운 **뒤**, 서로 다른 파일 영역의 독립 태스크가 2개 이상일 때. 빠른 시작은 [`team-lite.md`](team-lite.md).
- 팀장 탭: `$teamleader` → 브리프를 `.team/briefs/<인스턴스>.md`에 쓴다
- 팀원 탭: `MADANG_INSTANCE=builder codex` → 첫 입력 `너는 몽글이다. .codex/agents/builder.toml 의 developer_instructions 를 따르고 .team/briefs/builder.md 브리프를 읽어라.`
- 대기는 **사람이 깨운다**: 팀원 탭에 "브리프 확인해" / 팀장 탭에 "컨펌 왔나 봐" / 팀원 탭에 "reply 확인해"

**서브에이전트로** — 탭을 열 만큼은 아닌 일회성 일. "solver 에이전트로 이 버그 근본 원인 찾아줘", "narrator 에이전트로 지금까지 만든 구조 설명해줘". `/subagents`로 스레드를 오간다. 서브에이전트마다 토큰이 따로 든다.

## Claude판 → Codex판 대응

| Claude Code판 | Codex판 | 비고 |
|---|---|---|
| `~/.claude/skills/*/SKILL.md` | `.agents/skills/*/SKILL.md` | 같은 형식(`name`·`description` frontmatter). Codex는 `$CWD`·상위 폴더·`$REPO_ROOT`·`$HOME`의 `.agents/skills`를 찾는다 |
| `~/.claude/agents/*.md` | `.codex/agents/*.toml` | 필수 `name`·`description`·`developer_instructions`. `model`은 적지 않는다(세션 모델 상속) |
| `/teamleader`, `/solver` … | `$teamleader` / 팀원 탭 첫 입력 / 서브에이전트 호출 | |
| frontmatter 훅 (gate-commit·protect-hub) | `.codex/hooks.json` PreToolUse (`Bash`·`apply_patch`) | `/hooks`에서 신뢰 승인 후 동작. 인스턴스 식별은 `MADANG_INSTANCE` 환경변수 |
| 백그라운드 감시 (Monitor·폴 루프) | **없음 — 사람이 깨운다** | Codex는 30초가 넘는 명령을 백그라운드로 넘기고, 그 확인 반복이 토큰을 태운다 |
| push·PR·머지·이슈 트래커 스킬 | **없음** | APPROVE = 로컬 커밋까지 |
| 워커 오버레이 `go-madang` | **없음** | macOS 앱이라 웹 IDE·원격 환경에서 못 띄운다. 상태는 `.team/`과 `git log`로 |
| `.claude/team/`, `.claude/TASKS.md` | `.team/`, `.team/TASKS.md` | |

## 확인된 것 / 시험해 볼 것

- 공식 문서로 확인: 스킬 위치·형식, 커스텀 에이전트 TOML 형식·위치, 훅 위치·PreToolUse 차단 방식(exit 2 + stderr), 프로젝트 훅은 신뢰 승인 후 동작
  - [Agent Skills](https://developers.openai.com/codex/skills) · [Subagents](https://developers.openai.com/codex/subagents) · [Hooks](https://developers.openai.com/codex/hooks)
- 실제 Codex 세션에서 아직 안 돌려 본 것: 훅이 `MADANG_INSTANCE`를 실제로 물려받는지, `apply_patch` 패치 머리 파싱, 서브에이전트가 이 TOML을 이름으로 부르는지

출처·라이선스는 각 스킬의 `provenance.md`.
