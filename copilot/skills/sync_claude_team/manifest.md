# sync_claude_team 매니페스트 — Claude ↔ Copilot 팀 시스템 파일 매핑

> 이 스킬은 **Claude Code 설정을 원본(source of truth)**으로 보고 Copilot CLI 설정에 반영하는 **단방향 동기화**다 (Claude → Copilot).
> 스냅샷(`.snapshots/`)에는 마지막 동기화 시점의 Claude 원본 파일 사본이 있다. 변경 감지는 "현재 Claude 원본" vs "스냅샷"의 diff로 판단한다.

## 파일 쌍 목록

| # | Claude 원본 (source) | Copilot 대상 (target) | 스냅샷 | 변환 규칙 |
|---|---|---|---|---|
| 1 | `~/.claude/agents/pairi.md` | `~/.copilot/agents/pairi.agent.md` | `.snapshots/agents/pairi.md` | frontmatter를 `name`/`description`/`tools: all` 형식으로 유지(모델 필드는 Copilot에서 생략, model-guide.md가 대신함). 본문 내용(역할·작업규율·보고양식)은 의미 동일하게 반영. "탭 모드"/"팀 모드" 표현은 유지 가능(개념은 동일). |
| 2 | `~/.claude/agents/metamong.md` | `~/.copilot/agents/metamong.agent.md` | `.snapshots/agents/metamong.md` | 상동 |
| 3 | `~/.claude/agents/kkobugi.md` | `~/.copilot/agents/kkobugi.agent.md` | `.snapshots/agents/kkobugi.md` | 상동. proto worktree 경로 예시(`{app-repo}-ux` 등 특정 프로젝트명)는 일반화(`{repo-name}-ux`)해서 반영 — Copilot 쪽은 전역 설정이라 특정 프로젝트명을 박아넣지 않는다. |
| 4 | `~/.claude/skills/teamleader/SKILL.md` | `~/.copilot/skills/teamleader/SKILL.md` | `.snapshots/skills/teamleader/SKILL.md` | "`/pairi` `/metamong`" 같은 슬래시커맨드 표현 → "`skill` 도구로 pairi/metamong 호출"로 변환. "네이티브 팀 모드(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)" 언급은 Copilot의 `/fleet`·`task` 서브에이전트 개념으로 각색(기능이 동일하지 않으므로 그대로 베끼지 말 것). 절대원칙·운영루프·성찰루틴 등 정책성 내용은 그대로 반영. |
| 5 | `~/.claude/skills/teamleader/roster.md` | `~/.copilot/skills/teamleader/roster.md` | `.snapshots/skills/teamleader/roster.md` | 팀원 표의 "세션 시작" 컬럼 표현만 변환(`/pairi` → `skill 도구로 pairi 호출`), 나머지(전문 분야·상태)는 그대로 반영. 권장 모델 컬럼은 model-guide.md와 정합되게 Copilot 모델명으로 매핑(예: Sonnet 4.6→Claude Sonnet 5, 최신 대응 모델 확인). |
| 6 | `~/.claude/skills/teamleader/ways-of-working.md` | `~/.copilot/skills/teamleader/ways-of-working.md` | `.snapshots/skills/teamleader/ways-of-working.md` | 정책 내용(문서 규율·브리프 원칙·보고 양식·검증·세션 수명주기)은 그대로 반영. "use-glm/use-claude 셸 함수" 등 Claude 전용 프로바이더 전환 언급은 Copilot의 `/model` 방식으로 각색. **변경 이력 표는 Claude 쪽 이력을 그대로 복사하지 말고, Copilot 쪽에는 "Claude 쪽 변경 반영" 형태로 별도 이력을 남긴다** (두 파일의 변경 이력은 독립적으로 유지). |
| 7 | `~/.claude/skills/teamleader/model-guide.md` | `~/.copilot/skills/teamleader/model-guide.md` | `.snapshots/skills/teamleader/model-guide.md` | **모델 표는 그대로 복사하지 않는다** — Claude 전용 모델/프로바이더 정보이므로. 대신 "역할별 배분 권장" 표의 **구조(팀장/워커/고난도/분석/단순반복 역할 구분)**가 바뀌면 그 구조만 Copilot 모델 목록에 맞게 재적용. 실제 모델명·가격 갱신은 이 스킬이 아니라 `/model` 확인 기반으로 팀장이 별도 수행. |
| 8 | `~/.claude/skills/teamleader/skill-guide.md` | `~/.copilot/skills/teamleader/skill-guide.md` | `.snapshots/skills/teamleader/skill-guide.md` | 스킬 이름·슬래시커맨드(`/kickoff`, `/save-progress` 등)는 Claude 전용 개인 커맨드이므로 그대로 옮기지 말 것. "이 시점에는 이런 종류의 스킬을 쓴다"는 **패턴**만 반영하고, Copilot 표에서는 이미 있는 일반화된 표현(프로젝트 스킬/서브에이전트 종류) 유지. |
| 9 | `~/.claude/skills/pairi/SKILL.md` | `~/.copilot/skills/pairi/SKILL.md` | `.snapshots/skills/pairi/SKILL.md` | 재수화 절차(정체성 로드→보고이력→프로젝트상태→코드상태) 순서·내용이 바뀌면 그대로 반영. 파일 경로 표기만 Copilot 경로(`~/.copilot/agents/pairi.agent.md`)로 유지. |
| 10 | `~/.claude/skills/metamong/SKILL.md` | `~/.copilot/skills/metamong/SKILL.md` | `.snapshots/skills/metamong/SKILL.md` | 상동 |
| 11 | `~/.claude/skills/kkobugi/SKILL.md` | `~/.copilot/skills/kkobugi/SKILL.md` | `.snapshots/skills/kkobugi/SKILL.md` | 상동. worktree 안내의 특정 프로젝트명은 일반화 유지. |
| 12 | `~/.claude/commands/jira-capture.md` | `~/.copilot/skills/jira-capture/SKILL.md` | `.snapshots/commands/jira-capture.md` | 커맨드→스킬 형식 변환(frontmatter name/description 추가). acli/MCP 호출부는 Copilot에서 쓸 수 있는 것만(Atlassian MCP 사이트 분리 미작동 이슈는 copilot-instructions.md 참고 — {atlassian-mcp} 단일 인증 전제로 반영). |
| 13 | `~/.claude/commands/jira-refine.md` | `~/.copilot/skills/jira-refine/SKILL.md` | `.snapshots/commands/jira-refine.md` | 상동. 스토리 분할 판단 기준(400줄/2일/BE·FE)은 정책이므로 그대로 반영. |
| 14 | `~/.claude/commands/jira-story-cache.md` | `~/.copilot/skills/jira-story-cache/SKILL.md` | `.snapshots/commands/jira-story-cache.md` | **2026-07-13 신설 쌍** — Copilot 대상 파일 최초 생성 필요. 캐시 경로(`.claude/stories/`)는 도구 무관 공용이므로 그대로 유지(클로드·코파일럿 팀장이 같은 캐시를 읽는다). |
| 15 | `~/.claude/commands/kickoff.md` | `~/.copilot/skills/kickoff/SKILL.md` | `.snapshots/commands/kickoff.md` | 커맨드→스킬 형식 변환. model-guide 참조는 Copilot 쪽 model-guide로. |
| 16 | `~/.claude/commands/progress-check.md` | `~/.copilot/skills/progress-check/SKILL.md` | `.snapshots/commands/progress-check.md` | 단순 변환 (내용 거의 동일). |
| 17 | `~/.claude/commands/image.md` | `~/.copilot/skills/image/SKILL.md` | `.snapshots/commands/image.md` | 단순 변환. |
| 18 | `~/.claude/agents/rotomdex.md` | `~/.copilot/agents/rotomdex.agent.md` | `.snapshots/agents/rotomdex.md` | **2026-07-22 신설 쌍** — Copilot 대상 파일 최초 생성 필요. 팀원 정의(쌍 1~3)와 동일 변환. 읽기 전용·`edu/` 출력 원칙은 도구 무관이라 그대로. 감시 루프의 `run_in_background` 언급은 Copilot async bash 개념으로 각색 + **폴링 윈도우 25분 제한 특칙**(아래 각색 규칙) 적용. |
| 19 | `~/.claude/skills/rotomdex/SKILL.md` | `~/.copilot/skills/rotomdex/SKILL.md` | `.snapshots/skills/rotomdex/SKILL.md` | **2026-07-22 신설 쌍** — 세션 스킬(쌍 9~11)과 동일 변환. |

## 동기화 상태 메모 (2026-07-22 갱신)

- **쌍 6 (ways-of-working)은 보류 해제 — 동기화 필수 승격 (2026-07-22).** 이 문서에 팀장 전용이 아닌 **워커 행동 규칙**(기술 주체성·DISCUSS request 유형, 코파일럿 폴링 특칙, 팀 파일 수명 정책)이 추가됐고, 팀원 정의(쌍 1~3)가 이 문서를 참조한다. 동기화 시 워커 관련 절(팀원 작업 규율·워커 기술 주체성·컨펌 신호 프로토콜·팀 파일 수명 정책·세션 수명주기)을 우선 반영하고, 팀장 전용 절(운영 루프·성찰·사용량 게이트)은 참고 수준으로.
- **쌍 4·5·7·8 (teamleader SKILL/roster/model-guide/skill-guide) + 12~16 (jira 3종·kickoff·progress-check): 동기화 보류 유지.** 운영 모드 확정(팀장=클로드 전용, 팀원만 코파일럿 혼용)으로 Copilot 팀장 미사용. 단 **roster(쌍 5)의 포켓몬 인사말·로토무도감 행은 팀원 정의(쌍 1~3, 18)에 이미 반영되므로 별도 동기화 불필요**.
- 쌍 1~3 (팀원 정의) + 9~11 (세션 스킬): 2026-07-13 동기화 완료. **2026-07-22 Claude 원본 변경(포켓몬 인사말·기술 주체성·꼬부기 예외 정리·꼬부기 "확정안 메인 반영" 절차) → 재동기화 필요.**
- 쌍 18~19 (rotomdex): Copilot 대상 파일 미생성 — 다음 동기화 때 신규 생성.
- 쌍 17 (image): 개인 유틸, 변경 시에만.
- **⚠️ 스냅샷 무결성**: `.snapshots/commands/` 디렉토리가 실제로 존재하지 않음(쌍 12~17 스냅샷 전무) — 커맨드 쌍은 diff 기준점이 없어 변경 감지가 불가능한 상태다. 보류 해제 시 반드시 "현재 Claude 원본 전체 검토 후 스냅샷 최초 생성"부터 할 것. 활성 쌍(1~3, 6, 9~11, 18~19)은 동기화 완료 시마다 스냅샷을 빠짐없이 갱신.

## 도구 차이 각색 규칙 (2026-07-13 추가, 2026-07-22 개정 — 파일 쌍 공통 적용)

- **컨펌 신호 프로토콜 (2026-07-22 전면 개정 — 구 규칙 폐기)**: ~~"Copilot은 백그라운드 파일 감시 불가"~~는 **실측으로 뒤집혔다**(2026-07-13 PROJ-676 컨펌 사이클, 2026-07-14 브리프 폴링: Copilot 워커가 백그라운드 폴링 루프를 자율 실행해 reply/브리프를 자동 감지함). 따라서 **감시 루프 명령을 Copilot 버전에도 그대로 옮긴다** — 단 아래 Copilot 전용 제약을 반드시 함께 반영:
  - **폴링 윈도우 25분 이하** (`seq 1 100`×15초): Copilot CLI/SDK는 세션 idle ~30분 정리(공식 session-persistence 문서, copilot-sdk#824). 백오프(1~4h) 절대 금지 — 타임아웃마다 즉시 같은 25분 윈도우로 재무장(주기적 깨어남이 idle 타이머를 리셋).
  - **광범위 프로세스 킬 금지**: `pkill node` 류는 Copilot 자기 세션을 죽인다(copilot-cli#3033) — `lsof`로 PID 특정 후 그 PID만 kill.
  - **재개 키워드 "이어서"**: 세션이 그래도 정리됐으면 사용자가 "이어서" 한 마디 → 브리프 파일·reply 파일 순서로 읽고 미처리분부터 재개.
  - 근거 원문: `~/.claude/skills/teamleader/ways-of-working.md` "코파일럿 워커 폴링 특칙".
- **Artifact 도구 없음**: 꼬부기 L1 일회용 목업은 Artifact 대신 **임시 폴더에 HTML 파일 생성 + `open {파일}`로 브라우저 확인** 방식으로 각색. "여러 안 한 페이지 비교" 원칙은 유지.
- **Playwright MCP**: Copilot 쪽에 미설정. 꼬부기 셀프체크 규칙은 "Playwright MCP가 설정돼 있으면 사용, 없으면 dev 서버 스크린샷을 직접 캡처하거나 확인 요청에 수동 확인 항목으로 명시"로 완화 반영.
- **운영 모드 표**(ways-of-working): Copilot 버전에는 "코파일럿 팀원은 모드 1에서만 등장"이라는 관점으로 반영 — 모드 2·3(풀 클로드)은 참고 정보로만.

## 동기화 대상이 아닌 것 (의도적 제외)

- `~/.claude/projects/**/memory/*.md` (프로젝트별 피드백 메모리) — Copilot CLI는 세션 간 메모리 시스템이 없어 직접 대응되는 파일이 없음. 팀장이 필요 시 각 프로젝트의 `.github/copilot-instructions.md`에 프로젝트 한정으로 수동 반영(전역 동기화 대상 아님).
- 프로젝트 로컬 `.claude/agents/*.md`, `.claude/skills/*` (예: backend.md, frontend.md 등 {app-repo} 전용 커스텀 에이전트) — 이건 프로젝트 소유이고 이미 Copilot Task 도구에 `backend`/`frontend`/... 커스텀 에이전트로 노출되어 있음. 이 매니페스트는 **전역 개인 설정**(`~/.claude/` ↔ `~/.copilot/`)만 다룬다.
