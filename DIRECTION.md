# 방향성 (DIRECTION) — 포켓몬 에이전트 팀 시스템

> **이 레포(팀 시스템)의** 방향만 담는다. 사용자 개인 AI 환경 전체의 지도·인벤토리는 `~/.claude/DIRECTION.md`·`~/.claude/REGISTRY.md`가 관장 (2026-07-26 스코프 분리 — 이 레포는 "서비스 기획·설계·개발용 에이전트 팀 시스템"이라는 제품이다).
> 갱신 주체: 팀장 성찰 루틴 (+ 큰 방향 변경은 사용자와 합의 후).

## 한 줄 비전

**어떤 프로젝트·어떤 프로바이더에서든 그대로 동작하는 이식 가능한 에이전트 팀** — 페르소나·규칙·상태가 전부 파일 기반이라, 프로젝트를 갈아타면 그 프로젝트의 특화 스킬만 오버레이로 얹으면 된다.

## 설계 원칙 (이 시스템이 지키는 것)

1. **세션은 소모품, 상태는 파일** — 정체성(agents)·이력(reports)·상태(TASKS/PROGRESS)·코드(git) 4계층. 어떤 세션이 죽어도 파일로 복원.
2. **프로젝트 불가지(agnostic)** — 베이스 문서에 특정 회사/프로젝트 컨텍스트를 넣지 않는다 (구 jira-refine/capture Config 블록 위반은 E-6 외부화→2026-07-30 tracker-config 일반화로 해소). 프로젝트 특화는 오버레이의 **애든덤**(`{프로젝트}/.claude/team/agents/{이름}.md`, 기력회복 시 겹쳐 적용·델타만)으로 — 통째 오버라이드 금지 (2026-07-26 채택).
3. **훅이 강제하고, 스킬이 안내한다** — "반드시" 규칙은 산문에서 훅으로 옮겨간다 (로드맵 E-4).
4. **명시 호출 우선** — 페르소나·허브 문서 커맨드는 `/이름` + `disable-model-invocation`.
5. **변경에는 이력** — 날짜+변경+사유 (ways-of-working 표준). 패치 노트 3개 누적 = 리라이트 신호.
6. **상류 추종** — 활발한 상류(superpowers 등)가 있는 스킬은 포크 동결하지 않는다. 고유 자산만 직접 유지.
7. **본문은 규칙, 서사는 reference** (2026-08-31) — 매 세션 읽히는 문서(ways-of-working·SKILL.md·model-guide)는 "언제 확인 → 하지 마라 → 대신"만 적고, 사고 경위·실측·폐기 규칙은 `reference/incidents.md`에 규칙 번호로 색인한다. 컴팩션 생존은 기억이 아니라 `SessionStart(compact)` 훅이 담당. 원칙 5의 후속 — 패치 노트가 쌓이면 서사가 본문을 잠식하므로 리라이트 때 이 형식으로 돌아온다(ways-of-working 349→179줄, `plans/lecture-claude-code-prompt-optimization-2026-08-31-pass2.md`).

## 로드맵 (2026-07-26 사용자 승인 — 레포 소관분)

> 상세 근거: `plans/skill-system-audit-2026-07-25.md` E절. 완료 시 체크 + 커밋 SHA 기록.

- [x] **1차** E-2 플러그인 마켓플레이스화 — `.claude-plugin/marketplace.json` + `claude/.claude-plugin/plugin.json`, 심링크와 병행 (2026-07-26 적용. 클라우드 세션 호환 E-9는 `/schedule` 실사용 시 이걸로 충족)
- [x] **2차** E-3 superpowers 도입 검토 — **판단 변경(2026-07-27)**: 로컬 3종은 한글·팀 커스터마이징 자산이라 대체하지 않고 유지 확정. verification-before-completion만 선별 도입(상류@3dcbd5c, claude-home에 원본 무수정 + provenance). subagent-driven-development는 탭 모드와 상충해 SKIP. 상류 diff는 /skill-audit 트렌드 스캔에 편입
- [x] **3차** E-4 훅 — 커밋 게이트(파이리/메타몽)+허브 문서 보호(전원)를 페르소나 frontmatter 훅으로 구현(2026-07-27). **2026-09-02 실측: 발화는 됐으나 stdin 결함으로 6,900회 전부 실패 → 전면 수정**(꼬부기 적용·인스턴스 구분 포함, 단위 테스트 21건). 실세션 차단 1회 확인은 다음 워커 컨펌 사이클. 로토무도감 FileChanged 대체는 철회(훅은 유휴 세션을 못 깨움 — 공식 문서 확인)
- [x] **4차** E-1 커맨드→스킬 마이그레이션(2026-07-27 완료 — ADF 예시 보조 파일 분리 포함) · ~~E-5~~ 에이전트 frontmatter 구조화+꼬부기 주특기(2026-07-27 완료) · ~~E-6~~ jira Config 외부화(2026-07-27 완료 — `.claude/team/jira-config.md`) · ~~E-7~~ save-progress 문구 현행화(2026-07-27 완료)

## 문서 지도 (레포 내부)

| 문서 | 관장 |
|---|---|
| **DIRECTION.md** (이 문서) | 팀 시스템 비전·설계 원칙·로드맵 |
| README.md | 소개 + 설치 (신규 진입점) |
| claude/skills/teamleader/ways-of-working.md | 팀 운영 규칙(규칙만) · `ways-of-working-changelog.md` 변경 이력 · `reference/incidents.md` 사고 경위·실측 (2026-08-31 3분할) |
| claude/skills/teamleader/roster.md · model-guide.md · skill-guide.md | 팀원 명부 · 모델 배분 · 스킬 매핑 |
| plans/ | 감사 리포트·제안서 (시점 스냅샷 — 결론은 이 문서로 승격) |

인벤토리 원장(REGISTRY)은 사용자 개인 환경 소관이라 이 레포에 없다 — `~/.claude/REGISTRY.md` 참조 (`/skill-audit`이 갱신).
