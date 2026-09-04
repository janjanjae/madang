# v0.5 공개 첫인상 리뷰 — 처음 보는 사람의 눈으로 (2026-09-05)

> 번뜩(solver)이 `f9c6de1` 시점의 레포를 **외부 개발자 시점**으로 읽고 정리한 것. 읽기 전용 — 어떤 대상 파일도 고치지 않았다.
> 시점 가정: Claude Code를 써봤고 한국어를 읽는 개발자가 GitHub에서 `janjanjae/madang`을 처음 열었다.
> ⚠️ README는 지금 몽글이 별도 브랜치에서 고치는 중이라, 아래 README 항목 일부는 이미 해결됐을 수 있다.

## 요약

- **첫인상**: 히어로 GIF 한 장과 첫 문장에서 "여러 에이전트가 탭에서 동시에 돌고 상태가 눈에 보인다"가 바로 읽힌다 — 컨셉 전달은 이미 70점을 넘는다.
- **공개 차단급 7건**: 라이선스 파일 부재 · 설치하면 첫 명령이 안 도는 배선 누락 · clone URL 플레이스홀더 · `install.sh`가 기존 심링크를 백업 없이 덮어씀 · 공개 커맨드가 개인 인프라(`work-sync`)를 전제 · **회사 내부 티켓·화면 이름 노출** · 포켓몬 파생 함수명 잔존.
- **가장 큰 마찰 하나**: `./install.sh`를 돌려도 **`go-madang`·`go-solver`가 생기지 않는다.** README는 이 명령들로 시작하라고 하는데(`README.md:30`), 셸 함수를 `.zshrc`에 배선하는 단계가 README·`install.sh` 어디에도 없다(검색 0건). 처음 5분에서 막히는 지점은 여기 하나다.
- **영문 독자에게 남는 정보량**: 4줄 한 문단(`README.md:107-109`)뿐 — 컨셉은 전달되지만 **설치까지 갈 수 없다**(clone/plugin 명령이 그 문단에 없다). 게다가 그 문단만 "desktop pet"으로 남아 09-04에 확정한 "워커 오버레이" 용어와 어긋난다.
- **총평 — 지금 62점 / 70점 컷.** 컨셉·문서 밀도·시각 자산은 이미 컷 위인데, **"clone → install → 첫 명령"이 끊겨 있고 라이선스가 없어** 공개 리포지토리의 최소 요건을 아직 못 채웠다. 아래 차단 7건 중 5건이 한 줄 수정이라 복귀 후 15분이면 컷을 넘긴다.

## 걸리는 지점

| # | 위치 | 무엇이 걸리나 | 심각도 | 수정안 |
|---|---|---|---|---|
| 1 | 레포 루트 (`LICENSE` 없음) | 코드 라이선스가 어디에도 없다. 마스코트만 CC BY 4.0(`BRANDING.md`). 라이선스 없는 공개 레포는 **법적으로 "복제·사용 금지"**가 기본값이라 아무도 쓸 수 없다 | **차단** | `LICENSE`(MIT 등) 추가 + README 하단에 한 줄. **몽글 7번에서 처리 중** — 중복 작업 주의 |
| 2 | `README.md:30`·`63-81` | `go-madang`으로 오버레이를 띄우라고 하는데, 설치 절은 `./install.sh`만 시킨다. `install.sh`는 `~/.claude`·`~/.copilot` 심링크만 만들고 **셸 함수는 배선하지 않는다** → 설치 직후 `go-madang: command not found` | **차단** | 설치 절에 한 줄: <br>`echo 'source ~/madang/claude/shell/go-functions.zsh' >> ~/.zshrc && exec zsh` <br>(또는 `install.sh` 말미에 안내 출력 1줄) |
| 3 | `README.md:68` | `git clone <this-repo> madang` — 플레이스홀더 그대로. 처음 온 사람이 복붙하면 실패 | **차단** | `git clone https://github.com/janjanjae/madang.git && cd madang` |
| 4 | `install.sh:10` | `[ -e "$dst" ] && [ ! -L "$dst" ]` — **목적지가 이미 심링크면 백업 없이** `ln -sfn`으로 덮어쓴다. 자기 스킬 레포를 `~/.claude/skills/*`에 심링크해 둔 사람은 **경고도 없이 링크를 잃는다** (실디렉토리만 `.bak`로 보호된다) | **차단** | `[ ! -L "$dst" ]` 조건을 빼고, 심링크면 기존 대상을 출력한 뒤 확인받거나 `$dst.bak` 심링크로 보존. 최소한 README 설치 절에 경고 한 줄 |
| 5 | `claude/skills/save-progress/SKILL.md:39,43,45,48` | README가 공개 커맨드로 소개한 `/save-progress`가 **`$HOME/Desktop/work-context/bin/work-sync push` 실행을 "반드시"로 규정**하고 ZTNA 안내까지 한다. 외부인에게는 없는 개인 인프라 | **차단** | work-sync·ZTNA 절을 통째로 "선택 사항(개인 환경)"으로 내리거나 삭제. 스킬 본문은 "커밋까지"로 끝내기 |
| 6 | `ways-of-working.md:50` · `model-guide.md:116` · `roster.md:21` · `reference/confirm-protocol.md:10,15` | **회사 내부 정보가 그대로 공개된다** — 「SA 검토결과서 편집 화면」 같은 사내 화면명, `PROJ-1183`·`PROJ-1002` 등 실 티켓 번호, `roster.md:21`은 *현재* 담당 매핑(`현 PROJ-591 매핑: 탭 A(백엔드) = 번뜩`)까지 | **차단** | 사고 사례는 교훈만 남기고 티켓 번호·화면명을 일반화(예: "특정 편집 화면의 버튼"). `roster.md:21`의 현행 매핑 줄은 삭제 — 베이스 레포에 프로젝트 상태가 있을 이유가 없다 |
| 7 | `claude/shell/go-functions.zsh:60,110-117` | 공개 레포의 **실행 코드**에 `go-pairi`·`go-metamong`·`go-kkobugi`·`go-rotomdex`·`go-pokepet`(+`-cop` 4종) 8개 함수와 `pkill -x pokepet`. README:9가 "포켓몬과 무관하다"고 선언한 바로 그 이름들이라 **선언과 코드가 어긋난다** | **차단** | 09-11 제거 예정이지만 **공개는 09-13**이다 — 제거를 공개 전으로 당기면 이 항목이 사라진다. 블록 통째 삭제 (백로그 6번) |
| 8 | `claude/roster.json:36-37,51-52,66-67,81-82` + `:2` | README:21이 "단일 원천"으로 가리키는 파일의 `aliases`에 `파이리/pairi`·`메타몽/metamong`·`꼬부기/kkobugi`·`로토무도감/rotomdex`. `_about`에는 `pokepet` 잔재 | **권장** | aliases는 **옛 세션 제목 매칭용**이라 기능이 있다 → 지우면 구 세션 인식이 깨진다. `_about`에 "aliases의 옛 이름은 과거 세션 제목 호환용"이라고 한 줄 붙이고 `pokepet`→`madang` |
| 9 | `reference/confirm-protocol.md:100` | 구 절대경로 `~/Desktop/pokemon-agent-team/claude/shell/go-functions.zsh` — 리네임 후 갱신 누락 | **권장** | `~/madang/claude/shell/go-functions.zsh` 또는 레포 상대경로로 |
| 10 | `claude/tools/rename-roster.sh` | 리네임이 끝난 뒤 남은 **일회용 스크립트**. 포켓몬 매핑 표(`MAP_ID`·`MAP_KO`·`MAP_CRY`)가 통째로 들어 있어 처음 보는 사람에겐 "왜 이게 있지"이고, 잔재 grep도 계속 걸린다 | **권장** | 삭제(이력은 `plans/rename-night-2026-09-03.md`에 있다). 남긴다면 파일 머리에 "완료된 일회성 도구" 한 줄 |
| 11 | `README.md:109` | 영문 절만 `a small desktop pet` — 09-04에 "펫"을 버리고 "워커 오버레이"로 확정했는데 여기만 남았다. 영문 독자에게는 **이게 유일한 설명**이라 용어가 그대로 굳는다 | **권장** | `a small always-on-top overlay renders each teammate's live state` |
| 12 | `README.md:107-109` | 영문 절에 **설치 명령이 없다** — "Docs are in Korean"으로 끝나 영문 독자의 다음 행동이 없다 | **권장** | 그 문단 끝에 3줄: `git clone …` / `./install.sh` / `source claude/shell/go-functions.zsh`. 명령은 언어 장벽이 없다 |
| 13 | `README.md:83-101` (구조 절) | 실물에 있는 `CONTRIBUTING.md`·`.githooks/`·`.gitmessage`가 구조 절에 없다. 커밋 규칙을 훅으로 강제하는 게 이 레포의 특징인데 **그 존재가 구조에서 안 보인다** | **권장** | 3줄 추가: `CONTRIBUTING.md # 커밋 규칙` / `.githooks/ # commit-msg 강제` / `.gitmessage # 커밋 템플릿` |
| 14 | `claude/skills/teamleader/skill-guide.md:85` | `/jira-story-cache`를 "**신설**"로 안내 — 실제로는 존재하지 않는다(`/issue-cache`로 개명됨). 표대로 따라 하면 없는 커맨드 | **권장** | `/issue-cache`로 갱신 |
| 15 | `claude/skills/kickoff/SKILL.md:4,19` · `claude/agents/sketcher.md:34` | 기본 예시가 회사 프로젝트 키다 — `argument-hint: "[PROJ-이슈번호 \| 작업 설명]"`, 브랜치 규칙 `feat/PROJ-{ticket}-{작업명}`. 외부인은 `BMAD`가 뭔지 모른다 | **권장** | `{KEY}-{n}` / `feat/{ticket}-{작업명}` 처럼 플레이스홀더로 |
| 16 | `install.sh:29-30` | Copilot 스킬을 **무조건** `~/.copilot/`에 심링크한다. Copilot을 안 쓰는 사람에게도 디렉토리가 생긴다 | **권장** | `[ -d "$HOME/.copilot" ] && link …` 로 감싸기 (한 줄) |
| 17 | `README.md` 전체 | "무엇인가"는 30초에 전달되는데 **"왜 이걸 써야 하나"가 없다** — 혼자 Claude Code를 쓰는 것보다 나은 점(병렬성·컨펌 게이트로 얻는 것)이 서술되지 않는다 | **권장** | 로스터 표 앞에 2~3줄: 어떤 문제(긴 작업 중 뭘 하는지 안 보임 / 검증 없이 커밋됨)를 풀었는지 |
| 18 | `install.sh:5` vs `:36` | `REPO`(`BASH_SOURCE`)와 `REPO_DIR`(`$0`)로 같은 값을 두 번 구한다. `$0`은 source되면 깨진다 | **취향** | `REPO_DIR` 삭제하고 `REPO` 재사용 |
| 19 | `claude/assets/hero.gif` | 636×256 · 41KB — GitHub README 폭(~900px)에서 확대돼 살짝 흐리다 | **취향** | 레티나 재캡처 (백로그 4번에 이미 있음) |
| 20 | `README.md:7` | `워커 오버레이(마당)이 보여준다` — 조사 오류(`마당)가`) | **취향** | `(마당)가` |

## `install.sh` 정독 결과 (실행하지 않음)

**실행하면 순서대로 생기는 일** — `set -euo pipefail`, 레포 위치는 `BASH_SOURCE` 기준이라 어디서 호출해도 된다.

1. `claude/agents/{solver,builder,sketcher,narrator}.md` → `~/.claude/agents/` 에 **파일 4개** 심링크 (`:19-21`)
2. `claude/skills/{teamleader,solver,builder,sketcher,narrator,kickoff,save-progress,progress-check,issue-capture,issue-refine,issue-cache,skill-audit}` → `~/.claude/skills/` 에 **디렉토리 12개** 심링크 (`:24-26`) — 12개 전부 실재 확인, 깨진 링크는 생기지 않는다
3. `copilot/skills/sync_claude_team/{SKILL,manifest}.md` → `~/.copilot/skills/…` **파일 2개** 심링크 (`:29-30`)
4. 이 레포에 `core.hooksPath=.githooks`, `commit.template=.gitmessage` 설정 (`:37-38`)

**위험 지점**

- 🔴 **`:10` — 심링크는 백업되지 않는다.** `[ -e "$dst" ] && [ ! -L "$dst" ]`라서 실파일/실디렉토리만 `.bak`으로 옮겨진다. 목적지가 **이미 심링크**면 `ln -sfn`(`:14`)이 조용히 갈아끼운다. 자기 dotfiles 레포를 `~/.claude/skills`에 링크해 쓰는 사람이 정확히 이 경우다 (표 4번).
- ⚠️ **`:25` — 디렉토리 통째 링크.** `~/.claude/skills/teamleader`가 실디렉토리로 존재하면 통째로 `.bak`이 되고, 그 안에 사용자가 섞어 둔 파일이 있어도 분리되지 않는다. 롤백은 `.bak` 되돌리기 하나뿐.
- ⚠️ **`:29-30` — Copilot 무조건 설치** (표 16번).
- ✅ 삭제·덮어쓰기 명령(`rm`, `>`)은 없다. `mv`·`ln -sfn`·`mkdir -p`뿐이라 **되돌릴 수 없는 파괴는 없다**.
- ✅ `git config`(`:37-38`)는 이 레포 로컬 설정만 바꾼다(`--global` 아님).

**문법 검사**

```
$ bash -n install.sh
  문법 오류 없음 (exit 0)
```

## 복귀 후 15분 안에 고칠 수 있는 것

수정안이 한 줄짜리인 것만. 위에서부터 하면 차단 7건 중 5건이 사라진다.

1. **`README.md:68`** — clone URL 실제 주소로 (10초, 표 3)
2. **`README.md` 설치 절** — `source …/go-functions.zsh` 한 줄 추가 (1분, 표 2 — **가장 큰 마찰**)
3. **`install.sh:10`** — `&& [ ! -L "$dst" ]` 제거해 심링크도 백업 (1분, 표 4)
4. **`roster.md:21`** — `현 PROJ-591 매핑…` 줄 삭제 (10초, 표 6의 일부)
5. **`skill-guide.md:85`** — `/jira-story-cache` → `/issue-cache` (10초, 표 14)
6. **`confirm-protocol.md:100`** — 구 경로 `pokemon-agent-team` → `madang` (10초, 표 9)
7. **`README.md:109`** — `desktop pet` → `always-on-top overlay` + 설치 3줄 (2분, 표 11·12)
8. **`README.md:83-101`** — 구조 절에 `CONTRIBUTING.md`·`.githooks/`·`.gitmessage` 3줄 (1분, 표 13)
9. **`claude/tools/rename-roster.sh` 삭제** (10초, 표 10)
10. **`install.sh:29`** — Copilot 링크를 `[ -d ~/.copilot ]`로 감싸기 (30초, 표 16)

**15분으로 안 되는 것 3개** — 별도 태스크로: 라이선스 파일(표 1, 몽글 진행 중) · 회사 정보 sanitize(표 6, 문서 4곳 문장 재작성) · `go-*` 구 alias 제거(표 7, 09-11 예정을 공개 전으로 당기기).
