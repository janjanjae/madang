# 스킬 시스템 감사 + 구조 성찰 (2026-07-25 야간)

> 작성: 팀장 세션 (사용자 취침 중 위임 작업). 목적: ①개별 스킬·커맨드 비판적 감사 ②현 구조를 효율성·사용자 성향 관점에서 성찰 ③공식/커뮤니티 베스트 프랙티스 대조 후 개선안 제시.
> 적용 원칙: 문서 수준의 안전한 개선만 즉시 적용, 구조 변경은 E절 "검토 후보"로 등재 후 사용자 승인 대기.

## A. 개별 스킬·커맨드 감사 (로컬 정독 결과)

### A-1. 문제 발견 → 야간 수정 적용

**`kickoff.md` — 패치 누적으로 본문·현행 규칙 모순 (가장 낡았던 문서)**

| 위치 | 문제 | 근거 |
|---|---|---|
| Step 1 | `/jira-story-fetch` 참조 | 2026-07-12 개인 워크플로우에서 제외, `/jira-story-cache`로 대체됨 (skill-guide) |
| Step 4 | 모델표 구식: `use-glm glm-5.2`, "Claude Pro 토큰 절감" | 현재 맥스 플랜 + model-guide.md가 SSOT. 상단 주석 패치로 덮었지만 낡은 본문 잔존 — 모순 문서 |
| Step 5 | "새 세션에 붙여넣을 프롬프트" 생성이 본문 주류 | 2026-07-14 파일 기반 브리프 자동 수령으로 대체된 구 패턴 |

→ **리라이트 적용** (C-1). 교훈: 규칙이 바뀔 때 "주석 추가"로 때우면 문서가 자기모순에 빠진다 — skill-audit 판정 기준에 "패치 노트 3개 누적 시 리라이트" 추가함.

**`teamleader/SKILL.md` 팀원 참조 절** — pairi·metamong만 언급, 꼬부기·로토무도감 누락 → 수정 적용 (C-2).

**커맨드 7종 전부 frontmatter 부재** — 공식 스펙상 description(자동발동 매칭·목록 노출)·argument-hint 권장 → 일괄 추가 (C-3). 특히 kickoff/save-progress는 `disable-model-invocation: true`로 워커 세션에서의 오발동을 **산문 금지 규칙이 아니라 구조로** 차단.

### A-2. 경미 — 검토 후보로만 등재 (E절)

- **`jira-refine`/`jira-capture`의 프로젝트 Config 블록**: {app-repo} 제품 개요·Cloud ID가 범용 레포에 하드코딩 — "베이스+오버레이" 원칙 위반이자 README "공개 전 sanitize"와 겹침 → E-6.
- **`save-progress`의 "use-glm / use-claude 상태" 항목**: 모델 전략 변화 후 표현이 낡음 (동작 지장 없음).
- **`rotomdex/SKILL.md`만 `disable-model-invocation` 없음**: 파이리·메타몽·꼬부기는 오발동 방지로 걸어둠. 로토무도감은 "설명 요청 시 자동 발동"이 유용해서 **의도된 비대칭으로 판단, 유지** (공식 문서 확인: 이 플래그는 description을 컨텍스트에서 아예 제거 — 자동발동이 필요한 스킬엔 걸면 안 됨).
- **로토무도감 감시 루프**: 15초 폴링×100회 방식 — 공식 `FileChanged` 훅으로 대체 가능성 확인됨 → E-4.

### A-3. 양호 — 유지 판정

- **`jira-story-cache`**: acli(읽기·토큰 0)/MCP(쓰기) 분리 설계 합리적.
- **`jira-refine`**: 2모드 구조, ADF 체크박스·이미지 깨짐 등 실전 함정 축적 우수. 스토리=PR 1:1 불변식 명문화.
- **포켓몬 페르소나 체계**: "세션은 소모품, 상태는 파일"(정체성/이력/상태/코드 4계층 분리 + 기력회복 절차) — 공식 컨텍스트 관리 철학과 정확히 일치. 유지.
- **프로세스 스킬 5종**: 내용 견실. 단 생태계 대비 평가는 B-2 참조 (3종은 상류 진화, 2종은 고유).
- **ways-of-working 변경 이력 문화**: 날짜+변경+사유 표 = 자기 개선 루프의 모범.

## B. 베스트 프랙티스 대조 (2026-07-25 웹 리서치)

### B-1. 공식 문서에서 확인된 핵심 (code.claude.com/docs)

1. **커맨드는 스킬로 통합됨**: `.claude/commands/foo.md` ≡ `.claude/skills/foo/SKILL.md`. 기존 방식 계속 동작하지만 공식 권장은 스킬 디렉토리 (supporting files·`paths` 글롭 자동활성·`context: fork` 등 신기능은 스킬 전용). → E-1.
2. **심링크 배포는 공식 지원** — skills/rules에 명시적으로 허용. 현 install.sh 방식은 틀리지 않음. **단 클라우드 세션(/schedule 루틴, Cowork)은 `~/.claude/skills`를 읽지 않는다** → 야간 자동화에서 클라우드 루틴을 쓰려면 레포 커밋 스킬 또는 플러그인 필요. → E-2, E-9.
3. **개인 레포 배포의 공식 업그레이드 경로 = 플러그인 마켓플레이스**: 레포 루트에 `.claude-plugin/marketplace.json` → `/plugin marketplace add janjanjae/pokemon-agent-team` → 버전 고정·자동 업데이트·`/plugin list` 관리. 심링크(로컬 반복 수정)와 병행 가능. → E-2.
4. **frontmatter 스펙**: description ≤1,024자·3인칭·what+when, SKILL.md 본문 <500줄, 참조 파일 1단계 깊이만, `disable-model-invocation`(수동 전용·컨텍스트 절약), `argument-hint`, 스킬 본문은 발동 후 **세션 끝까지 컨텍스트에 상주**(모든 줄이 반복 비용). 현 인벤토리는 전부 한도 내 — 통과.
5. **서브에이전트 frontmatter 신기능**: `skills`(스폰 시 스킬 본문 프리로드), `memory`(user/project/local 영속 메모리), `mcpServers`, `isolation: worktree`, 에이전트 스코프 `hooks`. → 파이리/메타몽의 "주특기 & 스킬 사용" 산문을 구조 필드로 격상 가능. 주의: `disable-model-invocation` 스킬은 프리로드 불가, 팀메이트 스폰 경로에선 `skills` 미적용. → E-5.
6. **훅 원칙**: "CLAUDE.md 지침은 조언, 훅은 결정적" — **예외 없이 반드시 일어나야 하는 것은 훅으로**. 이벤트에 `FileChanged`, `PreToolUse`(차단 가능), 팀 이벤트(`TeammateIdle`/`TaskCompleted`) 포함. → E-4.
7. **CLAUDE.md는 200줄 이하 권장** + `.claude/rules/` 디렉토리(paths 글롭으로 파일 터치 시에만 로드) 신설. `/doctor`가 트림 제안.

### B-2. 커뮤니티에서 확인된 핵심

1. **superpowers가 지배적 프레임워크** (공식 마켓플레이스 등재, 활발히 유지). 현 프로세스 스킬 5종은 구세대 superpowers 계열의 동결 포크로 보임:
   - 상류에 진화된 대응물 존재: debugging-and-error-recovery(→systematic-debugging), planning-and-task-breakdown(→writing-plans), incremental-implementation(≈test-driven-development)
   - **상류에 없는 고유 2종: doubt-driven-development, source-driven-development → 유지 가치 높음**
   - **미보유 갭 2종: `verification-before-completion`(스모크 전 검증 문화와 직결), `subagent-driven-development`** → E-3.
2. **트리거 희석은 실재하는 문제**: 스킬 수·설명 중복이 늘면 잘못된 스킬이 발동. 명시적 `/이름` 호출이 훨씬 신뢰성 높음 — 현 팀 체계의 "명시 호출 + disable-model-invocation" 방향이 옳음. {app-repo} 세션은 스킬 ~100개 로드 상태 — 인벤토리 다이어트 여지. → E-8.
3. **3층 아키텍처 합의**: "훅이 강제하고, 스킬이 안내하고, 스크립트가 결정적 상태 변경을 수행" — 컨펌 게이트·허브 문서 보호 같은 필수 규칙을 페르소나 산문에만 두는 현 방식의 업그레이드 방향. → E-4.
4. **멀티에이전트 운영 합의가 현 규칙을 검증**: 팀메이트 3~5명 적정, 태스크 5~6개/인, **파일 소유권 분리** — ways-of-working이 이미 전부 채택하고 있음. 네이티브 Agent Teams는 파일 신호 프로토콜의 근접 대체재지만 experimental + resume 불가 제약 → 탭 모드 병행 판단 유지가 합리적.
5. **BMAD는 2026 SDD 비교글에 기성 스택으로 등재** — Spec Kit/OpenSpec 추가 도입은 중복, 불필요.
6. **MEMORY.md는 ~200줄 초과분 조용히 절단** — 현 인덱스+토픽파일 패턴은 올바름, 인덱스 비대화만 경계.

## C. 야간 적용한 개선 (안전한 문서 수준, 전부 로컬 커밋)

1. **kickoff.md 본문 리라이트** — 구 모델표·jira-story-fetch·붙여넣기 프롬프트 패턴 제거, model-guide SSOT·`/jira-story-cache`·파일 기반 브리프 기준으로 재작성. 배분 계획 표 출력 추가.
2. **teamleader/SKILL.md** 팀원 참조를 4인 전원으로 수정.
3. **커맨드 7종 frontmatter 일괄 추가** — description 전원, argument-hint(kickoff/jira 3종), `disable-model-invocation: true`(kickoff·save-progress — 허브 문서 커맨드의 워커 세션 오발동 구조 차단).
4. **skill-audit 판정 기준에 "패치 노트 3개 누적 시 리라이트" 추가** (kickoff 사례의 재발 방지 규칙화).
5. (선행 커밋) REGISTRY.md 신설, /skill-audit 신설, save-progress 이관, 성찰 루틴 편입, 7/22~23 미커밋분 이력화.

## D. 구조 성찰 — 효율성 × 사용자 성향

**사용자 일하는 방식** (메모리·운영 문서 기반): 비개발자 눈높이 해설 필요(로토무도감 신설 이유), 스모크 테스트는 직접, 팀장에게 리더십·우선순위 프레임 위임, Jira 중심 상태관리, 커밋 전 검증 게이트 문화, 워라밸 지향(야간 자동화 설계), 탭 모드 + 파일 신호 선호.

**구조적 강점 (외부 대조로 재확인됨)**:
- 파일 기반 상태 철학이 공식 "컨텍스트는 소모품" 방향과 정확히 일치 — 프로바이더 불문(코파일럿/OpenCode 혼용) 이식성은 네이티브 팀 모드도 못 주는 고유 장점.
- 변경 이력 문화(ways-of-working 표)가 곧 자기 개선 루프 — 커뮤니티가 권하는 "운영 감사"를 이미 내장.
- Jira 읽기(acli)/쓰기(MCP) 분리, 파일 소유권 분리, 3~5인 규모 — 전부 2026 합의와 일치.

**약점/기회 (우선순위순)**:
1. **"반드시" 규칙이 전부 산문** — 커밋 게이트, 팀원의 TASKS/PROGRESS 수정 금지, 허브 문서 보호가 페르소나 텍스트에만 존재. 공식 원칙상 이런 건 훅(PreToolUse 차단)으로 강제해야 모델 드리프트에 면역. → E-4.
2. **패치 누적형 문서 부채** — kickoff에서 실증. 규칙 변경 시 리라이트 없이 주석만 쌓이면 신뢰도 하락. (C-4로 규칙화함)
3. **회사/개인 컨텍스트 경계 침식** — 범용 레포에 {app-repo} 제품 개요·Cloud ID. 프로바이더 거버넌스(7/23)까지 세운 사용자 성향과 안 맞는 상태. → E-6.
4. **야간 자동화의 클라우드 갭** — /schedule 루틴은 심링크 스킬을 못 읽음. 야간 무인 확장의 숨은 전제 붕괴 지점. → E-9.
5. **프로세스 스킬의 정체** — 상류(superpowers)는 진화 중인데 로컬 5종은 동결 포크 + 레포 밖(이식성 갭). "최근 뜨는 방법론으로 계속 업데이트"라는 사용자 의도와 어긋남. → E-3.

## E. 검토 후보 (사용자 승인 대기 — REGISTRY.md에도 등재)

| # | 제안 | 효과 | 비용/리스크 | 권장 |
|---|---|---|---|---|
| E-1 | 커맨드 7종 → 스킬 디렉토리 마이그레이션 (`commands/foo.md`→`skills/foo/SKILL.md`) | 공식 권장형, supporting files·신기능 사용 가능 | install.sh 수정, 기계적 | 중기 |
| E-2 | 레포에 `.claude-plugin/marketplace.json` 추가 — 플러그인 마켓플레이스화 (심링크와 병행) | 버전 관리·타 머신 설치 1줄·클라우드 호환 | 구조 학습 필요, 병행 시 리스크 낮음 | **높음** |
| E-3 | superpowers 플러그인 도입 검토: debugging/planning/incremental → 상류 대체, doubt/source 유지, `verification-before-completion` 갭 도입 | 자동 업데이트되는 상류 + 스모크 전 검증 스킬 확보 | 5종 diff 검토 필요, 트리거 중복 정리 동반 | **높음** |
| E-4 | 훅 도입 3건: ①커밋 게이트(PreToolUse) ②팀원의 TASKS/PROGRESS 수정 차단 ③로토무도감 감시를 FileChanged 훅으로 | 산문 규칙 → 결정적 강제 ("훅이 강제, 스킬이 안내") | 훅 스크립트 작성·테스트 필요 | **높음** |
| E-5 | 에이전트 frontmatter 구조화: `skills` 프리로드 + `memory` 필드 (파이리/메타몽 주특기 산문 보강) + 꼬부기 "주특기" 섹션 신설 | 스킬 자동발동 불안정성 제거, 팀원별 영속 메모리 | 팀메이트 스폰 경로 미적용 주의 | 중기 |
| E-6 | jira-refine/capture의 프로젝트 Config 블록 외부화 (프로젝트 오버레이로) | 베이스+오버레이 원칙 정합, 공개 sanitize 선행 | 커맨드 참조 방식 설계 필요 | 중기 |
| E-7 | save-progress 문구 현행화 ("use-glm/use-claude 상태" → 모델·프로바이더 일반 표현) | 소소한 정합 | 1줄 | 낮음(묶음 처리) |
| E-8 | {app-repo} 스킬 인벤토리 다이어트: bmad 스위트·디자인 스킬 로드 방식 점검 (`skillOverrides`·`/doctor`) | 트리거 정확도·컨텍스트 예산 개선 | 팀 동료 영향 — 프로젝트 소관 협의 | 중기 |
| E-9 | 야간 /schedule 루틴용 스킬 배포 경로 확보 (E-2와 연계: 클라우드가 읽을 수 있는 형태) | 야간 자동화 확장 전제 확보 | E-2에 종속 | E-2와 함께 |

**권장 우선순위**: E-2+E-9(배포 현대화) → E-3(프로세스 스킬 세대교체) → E-4(훅 강제) 순. E-1·E-5·E-6은 그 다음 정리 사이클에.

---

### 리서치 출처 (핵심만)

- 공식: code.claude.com/docs — best-practices / skills / sub-agents / memory / hooks-guide / plugins / plugin-marketplaces / agent-teams
- 커뮤니티: obra/superpowers · anthropics/skills · Tembo/Shipyard 멀티에이전트 가이드 · 스킬 트리거 안티패턴(Medium) · ro14nd.de 3층 아키텍처 · SDD 도구 비교(timchao.site) · Claude Code 메모리 아키텍처(ianlpaterson.com)
