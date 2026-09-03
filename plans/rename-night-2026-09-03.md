# 밤 작업 계획 — 포켓몬 → 마당(madang) 리네임 (2026-09-04 00:11 자동 시작)

> 사용자 지시(09-03 23:40): "토큰 리셋된 00:11에 시작해서 밤새 해 둬라." 이 파일이 밤 작업의 유일한 지시서다. 진행하면서 **각 단계 끝에 이 파일의 진행 로그에 결과를 적는다**(중단돼도 아침에 이어갈 수 있게). 근거 문서: `plans/brand-strategy-2026-09-03.md`, DIRECTION.md "브랜드 결정" 절.

## 확정된 결정 (다시 묻지 않는다)

- 프로젝트명 **madang / 마당**. 플러그인 ID `madang`. 저자 크레딧 "made by 잔잔재 (janjanjae)".
- 식별자: `pairi→solver`, `metamong→builder`, `kkobugi→sketcher`, `rotomdex→narrator`. **`teamleader`는 그대로**(이미 역할명, 훅 경로 종속). roster.json의 lead key도 `teamleader` 유지.
- 캐릭터명·울음소리(스킨 표 `claude/roster.json`): 도담(팀장, 부속 없음) · 번뜩! · 몽글~ · 슥슥~ · 조잘조잘!. 이모지 ⚪🔺☁️🟦💬.
- 포켓몬은 **스킨으로도 남기지 않는다**. 기원은 changelog·README "기원" 한 문단으로만.
- 역할 재정의(§5-2): solver = 하나의 어려운 문제를 끝까지(핵심 슬라이스·2회 실패 버그·통합/재현불가/아키텍처급), builder = 같은 모양의 독립 태스크 N개 병렬(분신), sketcher = 화면이 필요할 때(worktree 격리·스크린샷 후보), narrator = 사용자가 이해하고 싶을 때(읽기 전용). "에이스/메인" 시니어리티 표현은 지운다.
- 도구 `pokepet` → **`madang`** (디렉토리 `claude/tools/madang/`, 바이너리 `madang`, 셸 함수 `go-madang`).
- 커밋은 **로컬만**, push 금지. 팀장 WIP 3파일(model-guide·worktree-setup·ways-of-working)은 건드리지도 커밋하지도 않는다.

## 0. 안전 게이트 (통과 못 하면 30분 뒤 재확인, 4회 실패 시 중단하고 로그만 남김)

```bash
K=~/Desktop/{project}/{app-repo}/.claude/team
ls $K/confirm/*.request.md 2>/dev/null            # 있으면 워커가 컨펌 대기 중 → 대기
find $K/briefs $K/reports -mmin -30 -name "*.md"  # 30분 내 갱신 있으면 → 대기
# 워커 세션 실제 턴: ~/.claude/projects/-Users-{user}-Desktop-{project}-{app-repo}/*.jsonl 중 제목이 파이리/메타몽/꼬부기로 시작하는 파일의 mtime이 30분 내면 → 대기
```
워커 탭(iTerm)은 **절대 죽이지 않는다**. 리네임 뒤 그 탭들은 다음 기동(`go-solver` 등)부터 새 이름을 쓴다.

## 1. 오늘 작업 먼저 커밋 (리네임과 분리)

- 커밋 A `feat(shell): 세션명 이모지 접두 (L0)` — `.gitignore`, `claude/shell/go-functions.zsh`(현재 상태)
- 커밋 B `docs(brand): 마당 브랜드 전략·DIRECTION 브랜드 결정 절` — `DIRECTION.md`, `plans/brand-strategy-2026-09-03.md`, `plans/rename-night-2026-09-03.md`
- 커밋 C `feat(madang): 스킨 표·마스코트 SVG 30종·데스크톱 펫 표시층(말 없는 펫)` — `claude/roster.json`, `claude/assets/`, `claude/tools/pokepet/`, `claude/tools/rename-roster.sh`
- `git status`에 팀장 WIP 3파일만 남아야 한다.

## 2. 기계 치환

- `claude/tools/rename-roster.sh --apply` (드라이런 09-03: 식별자 249회·한글 234회·파일/디렉토리 8개). (스크립트의 `teamleader→lead` 치환 줄과 인사말 공백 버그는 09-03 23:40에 이미 수정·검증됨.)
- 치환 후 `git diff --stat`으로 plans/·changelog·incidents가 안 바뀌었는지 확인(기원 서사 보존).

## 3. 손으로 다듬기 (기계 치환이 못 하는 것)

- `claude/agents/{solver,builder,sketcher,narrator}.md`: 첫 문단 정체성·역할을 §5-2대로 재서술("가장 성실하고 실력 있는" 같은 시니어리티 문구 제거, 호출 조건 명시). 말버릇 줄: 첫 줄 "번뜩!" / "몽글~" / "슥슥~" / "조잘조잘!" (번호 규칙 동일: "몽글2~"). `description:` frontmatter도 동기화. 모델명 서술은 넣지 않는다(arXiv 2604.00026).
- `claude/skills/{solver,builder,sketcher,narrator}/SKILL.md` description·본문 이름.
- `claude/skills/teamleader/roster.md` 표(이름·agent name·세션 시작·역할 재정의·배분 기준), `skill-guide.md`, `ways-of-working.md`의 이름 언급(규칙 본문만, changelog는 놔둠), `reference/confirm-protocol.md`.
- `claude/shell/go-functions.zsh`: `go-solver/go-builder/go-sketcher/go-narrator`, `_go_emoji` 새 이모지(🔺☁️🟦💬, 팀장 ⚪), 세션명 "🔺번뜩 0904", 프롬프트 인자 이름. **옛 함수명은 alias로 1주 유지**(`alias go-pairi=go-solver` 등 + 경고 echo) — 손이 기억하는 이름.
- `claude/tools/pokepet/` → `claude/tools/madang/`: `git mv`, 소스 파일명 `madang.swift`, build.sh 출력 `madang`, 헤더 주석, README 제목, UserDefaults 키(`pokepet.*` → `madang.*`), 환경변수 `POKEPET_SILENT` → `MADANG_SILENT`, 셸 함수 `go-madang`(+ `alias go-pokepet=go-madang`). 실행 전 `pkill -x pokepet`, 빌드 후 `~/Desktop/{project}/{app-repo}/.claude/team`으로 기동해 3마리 뜨는지 확인.
- `.claude-plugin/marketplace.json`, `claude/.claude-plugin/plugin.json`: name `madang`, description에서 포켓몬 제거.
- `README.md`: 제목 "마당 (madang)", 훅 한 줄(§1 포지셔닝: 역할이 다른 여러 에이전트가 동시에, 파일 신호로 조율되고, 상태가 눈에 보이는 팀), 로스터 표(이름·역할·인사), "기원" 한 문단(포켓몬 이름으로 시작 → 공개하며 자작으로. 공식 그림·상표 언급 없음, 비제휴 고지), 설치 명령의 플러그인 이름, 하단 "made by 잔잔재 (janjanjae)". 영문 요약 1절(3~5문장). GIF는 아침 이후(사람 작업).
- `BRANDING.md` 신설: 마스코트 CC BY 4.0, 색 변경 금지·보증 암시 금지(CNCF식), 이름·울음소리 목록, 포켓몬 비제휴 고지.
- `DIRECTION.md` 제목·본문의 "포켓몬 에이전트 팀" → "마당(madang) 에이전트 팀". 브랜드 결정 절에 "09-04 새벽 리네임 완료" 한 줄.
- `claude/skills/teamleader/ways-of-working-changelog.md`에 09-04 항목: 리네임 사유·매핑표·기원 서사.
- `install.sh`: 이름 목록 갱신 후 **실행** → `~/.claude/agents/`·`~/.claude/skills/`에 새 심링크. 옛 심링크(pairi 등 8개) 제거. `ls -la ~/.claude/skills ~/.claude/agents | grep -E "solver|builder|sketcher|narrator"`로 확인.
- 훅 확인: `claude/skills/teamleader/hooks/`의 gate-commit·protect-hub가 인스턴스 이름을 쓰면 새 이름으로. 테스트가 있으면 실행(09-02 "단위 테스트 21건" — 위치를 찾아 돌린다), 없으면 `echo '{"tool_input":{"command":"git commit -m x"}}' | ./gate-commit.sh` 식으로 한 번 흉내.
- `copilot/skills/sync_claude_team/manifest.md`·`SKILL.md` 이름 갱신.

## 4. {app-repo} 오버레이 (회사 레포 — `.claude/team`은 git 비추적이라 `mv`, 커밋 없음)

- `~/Desktop/{project}/{app-repo}/.claude/team/agents/{pairi,metamong,kkobugi}.md` → 새 이름, 파일 안의 이름·인사말 치환.
- `briefs/`·`reports/`·`confirm/`의 현재 파일(`pairi*.md`, `metamong*.md`, `kkobugi*.md`, 번호 포함) → 새 이름(`solver2.md` 등). `reports/archive/`는 놔둔다(히스토리).
- `.claude/PROGRESS.md`·`TASKS.md`에 이름이 있으면 "(구 파이리)" 병기로 1회만 치환 — 허브 문서라 최소 변경.
- 여기서 실패하면 이 단계는 건너뛰고 로그에 "아침에 사람이" 표기.

## 5. 리네임 커밋 (로컬)

- `git add` 는 경로 지정으로(팀장 WIP 3파일 제외). 메시지: `refactor(brand): 포켓몬 → 마당(madang) — 식별자·캐릭터·도구 리네임`. 본문에 매핑표와 "기원: 파이리·메타몽·꼬부기·로토무도감으로 시작(2026-07), 공개(09-13) 앞 자작 마스코트로 교체".

## 6. GitHub·폴더 (조건부)

- `gh auth status`에서 `janjanjae`가 **로그인 상태(토큰 유효)일 때만**: `gh auth switch -u janjanjae` → `gh repo rename madang -R janjanjae/pokemon-agent-team --yes` → 끝나면 **`gh auth switch -u {company-gh-account}`로 회사 계정 복귀**(이 맥의 기본은 회사 계정) → 원격 URL 갱신 확인 → 로컬 폴더 `mv ~/Desktop/pokemon-agent-team ~/Desktop/madang` → 참조 갱신: `~/.zshrc`(51·53행), `~/Desktop/work-context/bin/work-sync`(REPOS), `~/Desktop/claude-home/{DIRECTION,README,MIGRATION-macbook-air,REGISTRY}.md`의 경로 문자열, 메모리 파일 경로 → `install.sh` 재실행(심링크가 새 경로를 가리켜야 함) → `source ~/.zshrc; type go-madang`.
- 로그인 아니면 **6 전체 건너뜀**(폴더명도 유지 — 레포명과 폴더명은 같이 바꾼다). push는 어느 경우에도 하지 않는다.

## 7. 상표 조회 (조건부)

- TMview API(`POST https://www.tmdn.org/tmview/api/search/results`, offices KR, basicSearch "madang" / "마당")를 집 네트워크에서 시도. 응답 오면 9류·42류 결과를 이 파일에 표로. 실패하면 "KIPRIS 수동 조회" 표기.

## 8. 마무리

- `~/.claude/REGISTRY.md` E-17에 "09-04 리네임 완료, 도구명 madang" 한 줄. `~/.claude/projects/-Users-{user}/memory/pokepet-mascot-redesign.md` 갱신(파일명은 그대로, 내용에 완료 표기·남은 사람 작업: README GIF·push·KIPRIS·워커 탭 재기동을 `go-solver` 등으로).
- 이 파일 맨 아래 진행 로그에 최종 요약: 한 것 / 건너뛴 것 / 아침에 사람이 할 것 / 되돌리는 법(`git log`의 커밋 3~4개 revert, 심링크는 install.sh).

## 알려진 잔여

- 기계 치환 후 분신 인사말 "몽글2..."(점 세 개)가 남을 수 있음 → 3단계에서 "몽글2~"로 손질.
- 이 예약은 CronCreate(세션 내 일회성, 00:11)로 걸었다. 세션이 죽어 안 돌았으면 아침에 같은 프롬프트를 손으로 넣는다.

## 진행 로그

(밤 작업이 단계마다 여기에 추가)

- **00:12 · 0단계 통과** — confirm/*.request.md 없음, 30분 내 briefs/reports 갱신 없음, 워커 세션(파이리·메타몽·꼬부기) 30분 내 실제 턴 없음. pokepet은 돌고 있음(뒤에 madang으로 교체 기동).
- **00:14 · 1단계 완료** — 커밋 A 27cc2de(세션 이모지), B 8368ef5(브랜드 문서), C e4a5730(스킨 표·SVG·펫). 남은 미커밋 = 팀장 WIP **4파일**(model-guide·confirm-protocol·worktree-setup·ways-of-working — confirm-protocol이 09-03 중 추가로 수정돼 있어 WIP로 취급). 이 4파일은 기계 치환에서도 제외한다(아침에 사람이 커밋 후 재실행).
- **00:15 · 2단계 완료** — `rename-roster.sh --apply`: 파일/디렉토리 8개 이동(agents·skills), 본문 치환(WIP 4파일 제외 — EXCLUDE에 추가). plans/·changelog·incidents 무변경 확인. 훅(gate-commit.py/.sh) 정규식이 새 식별자로 바뀜.
- **00:18 · 3단계 완료** — agents 4개 정체성 재서술(깊이/넓이/시안/해설, 시니어리티 문구 제거, 인사말 "번뜩!/몽글~/슥슥~/조잘조잘!", 분신 표기 몽글2·3) · roster.md 표·운영 메모 · teamleader/skill-audit/save-progress SKILL 문구 · go-functions(이모지 🔺☁️🟦💬⚪, go-madang, 구 이름 alias 8개 → 09-11 제거 예정) · tools/pokepet→tools/madang(소스 madang.swift, MADANG_SILENT, UserDefaults madang.*) · .gitignore · 플러그인 매니페스트 name `madang` · DIRECTION 제목+완료 줄 · README 전면 재작성(훅·로스터 "언제 부르나"·기원·설치·영문 요약·크레딧) · BRANDING.md 신설 · changelog 09-04 항목. install.sh 실행 → 새 심링크 8개, 옛 심링크 8개 제거, 깨진 링크 0. 훅 스모크 3건 통과(APPROVE 없음→exit 2 차단 / APPROVE→통과 / sketcher [proto]→통과). 옛 이름 `pairi`는 미인식 → 구 동작 폴백(통과) — 워커가 새 이름으로 뜨는 한 무관.
- **00:20 · 4단계 완료** — {app-repo} `.claude/team/`: agents 3개·briefs 7개·reports 7개 파일명 교체(confirm 비어 있었음), agents 오버레이·_local-runtime 인사말·이름 치환, PROGRESS.md·TASKS.md 상단에 안내 1줄(과거 기록 옛 이름 유지). `reports/archive/`는 그대로. `reports/builder1.md`는 옛 `metamong1.md`(무번호 규칙 위반 잔존물) — 아침에 삭제 여부 판단.
- **00:21 · 5단계 완료** — 커밋 b35bf94 `refactor(brand): 포켓몬 → 마당(madang)` (34파일, 이동 10). 미커밋 = 팀장 WIP 4파일만.
- **00:22 · 6단계 완료(조건 충족)** — 사용자가 자기 전 janjanjae 재인증 → `gh repo rename madang` 성공(원격 `janjanjae/madang.git`), 회사 계정으로 복귀. 로컬 폴더 `~/Desktop/madang`. 참조 갱신: `~/.zshrc` 51·53행, `work-context/bin/work-sync` REPOS, claude-home DIRECTION·README·MIGRATION의 레포 이름 언급 9곳 → madang(구 이름 병기, MIGRATION clone URL 포함) + REGISTRY E-17 줄(claude-home 미커밋 — 다른 세션의 money-brief 변경과 섞여 있어 사람이 분리 커밋), 메모리 경로. `install.sh` 재실행 → 심링크 새 경로, 깨진 링크 0. `zsh -ic 'type go-madang'` 정상. madang 펫을 새 경로에서 재기동({app-repo}, 3마리 눈 감음 = 밤이라 정상).
- **7단계 (00:30 사용자 기상 후 완료)** — 사내망(ZTNA)이 켜져 있어 http 000이었음. 끄고 User-Agent 헤더로 TMview 성공: "마당" 9·42류 9건 중 살아 있는 건 "CONTENTS MADANG"(콘텐츠마당, 9류 결합상표, 2034 만료) 1건뿐, 단독 "마당"은 전부 소멸. 리스크 낮음 → 이름 유지. 결과 표는 brand-strategy §4.
- **8단계 완료** — REGISTRY E-17 완료 줄, 메모리·MEMORY.md 갱신.

### 최종 요약 (2026-09-04 새벽)

**한 것**
- 리포 안: 식별자·캐릭터·인사말·이모지·도구·플러그인 ID 전부 마당으로. 역할 재정의(깊이/넓이/시안/해설). README 재작성, BRANDING.md, changelog 09-04. 커밋 4개(로컬): 27cc2de 세션 이모지 · 8368ef5 브랜드 문서 · e4a5730 스킨 표·SVG·펫 · b35bf94 리네임.
- 리포 밖: GitHub `janjanjae/madang`, 폴더 `~/Desktop/madang`, ~/.claude 심링크 8+, .zshrc·work-sync·claude-home 경로, {app-repo} 오버레이 파일명·인사말, REGISTRY·메모리.
- 검증: 훅 스모크 3건(차단/통과/proto 예외), 심링크 깨짐 0, 셸 함수 로드, 펫 빌드·기동·창 캡처.

**건너뛴 것**
- 팀장 WIP 4파일(model-guide·ways-of-working·confirm-protocol·worktree-setup) 치환 — 미커밋 변경과 섞이지 않게 제외.
- 상표 조회(TMview 차단).
- push (지시).

**아침에 사람이 할 것**
1. WIP 4파일 커밋 → `claude/tools/rename-roster.sh`의 `WIP=` 줄을 지우고 `--apply` 재실행 → 그 4파일만 치환됨 → 커밋.
2. `git push`(madang), claude-home 4문서 변경도 커밋·push.
3. KIPRIS에서 "madang"·"마당" 9·42류 조회 → brand-strategy §4에 결과 기록.
4. 워커 탭 재기동은 `go-solver` / `go-builder` / `go-sketcher` (옛 이름도 경고 후 동작, 09-11 제거). 첫 발화가 "번뜩!"으로 열리는지 확인 — 훅 실세션 차단 1회 확인도 이때.
5. README 히어로 GIF(넷이 서로 다른 상태로 동시에), `{app-repo}/.claude/team/reports/builder1.md` 삭제 여부.
6. 새 터미널을 열어야 .zshrc 변경(경로)이 적용된다. 열려 있던 워커 탭은 옛 함수 정의를 갖고 있으나 파일 신호 경로는 이미 새 이름이라, **탭을 새로 여는 게 맞다**.

**되돌리는 법**
- 리포: `git revert b35bf94` (리네임만) 또는 `git reset --hard 7ff2def` (오늘·어제 것 전부, 4커밋). 이후 `./install.sh`.
- GitHub: `gh repo rename pokemon-agent-team -R janjanjae/madang`(리다이렉트는 양방향 아님 — 되돌리면 새 URL 링크가 죽음). 폴더는 `mv ~/Desktop/madang ~/Desktop/pokemon-agent-team` + .zshrc/work-sync 경로 복원 + install.sh.
- {app-repo} 오버레이: 파일명 역방향 mv(solver→pairi …), 인사말은 agents 오버레이 3파일만.

### 아침 이어서 (2026-09-04 08:30~09:00, 사용자 기상 후 "다 이어서 진행")

- 상표 조회 완료(7단계 갱신 참조) → brand-strategy §4 표.
- 팀장 WIP 4파일 커밋(4a3f529) → 재치환. **사고 2건**: ① rename-roster.sh가 자기 매핑표까지 치환해 첫 재실행이 무효(ab81bba 메시지 오류 → 1125aed 정정) ② 재실행이 go-functions alias 블록의 옛 이름까지 바꿔 `go-solver`가 자기 재귀 → 2731de0 복구. 스크립트 EXCLUDE에 자기 자신·go-functions.zsh 추가.
- push: madang(main = origin/main), claude-home 4문서 분리 커밋(abbb2f0) 후 push. money-brief 변경은 남겨 둠(다른 세션 것).
- `{app-repo}/.claude/team/reports/builder1.md` → `reports/archive/metamong1-2026-08.md`(삭제 대신 보관).
- README 히어로 GIF: `claude/tools/madang/make-hero-gif.sh`(가짜 팀 폴더로 4장면 연출 → 창 캡처 → ffmpeg). 1x 캡처라 318px — 나중에 레티나 화면에서 다시 뽑으면 2배 선명. 스크립트 사고: ffmpeg 무한 color 소스로 3분 행(→ shortest=1·프레임별 합성), `${f/\/f/\/g}` 치환이 /folders를 잡음(→ basename).
- 남은 사람 작업: 워커 탭 재기동(`go-solver` 등)과 첫 발화·커밋 게이트 실세션 확인.
