# 브랜드 전략 → 디자인 컨셉 (2026-09-03)

> **2026-09-03 사용자 확정**: 이름 madang · 캐릭터 이름 의태어 A안 · 1차 독자 한국 개발자 · 포켓몬은 스킨으로도 남기지 않고 기원 서사만 기록(전면 교체). 결론은 DIRECTION.md에 승격됨.
> 목적: 9/13 저장소 공개(v0.5)·10/25 소개 글(v1) 앞에 **이름·정체성·시각 언어**를 확정한다. 리서치 3건(오픈소스 브랜딩 사례 / 포켓몬 IP 리스크 / 마스코트 디자인 원칙, 웹서치 50회+)을 근거로 썼고, 출처는 말미에. 결론은 DIRECTION.md로 승격, 이 파일은 시점 스냅샷.
> 읽기 버전(시안 SVG·상태 배지 포함): https://claude.ai/code/artifact/f4bf5dc2-0582-49ef-8df4-b919b20b8c9a

## 0. 한 줄 결론

**자작 마스코트로 전면 교체하고, 포켓몬은 기원 서사(히스토리)로만 기록한다.** 식별자는 역할(영문)로 바꾸고 캐릭터 이름·그림은 표 하나(스킨 표)에서 읽게 분리한다 — 교체 비용을 낮추기 위한 구조이지 포켓몬 스킨을 보관하려는 것이 아니다. 시각 언어는 잉크 한 색의 실루엣(원·세모·구름·네모·말풍선) + 역할 색은 시그니처 슬롯 하나에만, 얼굴은 다섯 모두 점 2개 + 선 1개(2026-09-03 사용자 피드백 2회 반영: 넓은 색은 형태를 가리고, 작은 색 슬롯은 좋다, 얼굴은 통일).

---

## 1. 목표와 방향 (브랜딩의 근본)

맞다 — 목표 설정이 먼저다. 이름·마스코트·색은 전부 "누구에게 무엇으로 기억될 것인가"에서 파생된다. Eghbal(*Working in Public*)의 핵심 경고는 오픈소스에서 **유지보수자의 주의력이 유일하게 희소한 자원**이라는 것이고, 목표가 수익이 아니라면 기여 범위를 처음부터 좁게 선언하는 게 정합적이다.

| 항목 | 결정 |
|---|---|
| **목적** | 포트폴리오 + 생태계 기여. 수익화 대상 아님(2027 수익 실험의 "만들고 알리는 사람" 발판). |
| **한 줄 포지셔닝** | "역할이 다른 여러 에이전트가 **동시에**, 파일 신호로 조율되고, 그 상태가 **눈에 보이는** 팀." |
| **차별점 (Codex Pets 대비)** | Codex Pets(2026-05)는 단일 스레드 상태를 펫 1마리로 보여준다. 우리는 **역할이 다른 N명이 병렬로** 뛰고, 조율 구조(브리프·컨펌 파일 프로토콜·커밋 게이트 훅)가 **오픈소스**다. "펫 오버레이"로 포지셔닝하면 아류로 읽힌다 — 펫은 증거, 팀 구조가 제품. |
| **계보** | Stanford Smallville(2023, 픽셀 에이전트 마을) → Codex Pets(2026) → 이 프로젝트. 런치 글에 이 계보를 쓰면 서사가 생긴다. |
| **기여 범위** | 이슈·PR은 받되 "페르소나 추가 PR"은 받지 않는다(마스코트 일관성 붕괴 방지). 스킨(이름·이모지·그림 교체)은 오버레이 폴더로 열어 둔다. |

**1차 독자 확정(2026-09-03): 한국 개발자 커뮤니티 우선, 영문은 "통과 가능" 수준.**
- 근거: 에이전트 발화·문서·잔잔재 콘텐츠가 전부 한국어이고, 10/25 소개 글도 한국어로 나간다. 영문 README를 1차로 잡으면 번역·유지 비용이 두 배가 되고 70점 컷을 못 지킨다.
- 다만 **식별자·프로젝트 이름은 ASCII로 발음 가능하게** 잡아 영문 README 요약 한 절만 두면 글로벌은 자동으로 "통과"한다(awesome 목록 등재 조건은 영문 설명 한 문단이면 충분).
- 결정은 사용자 몫. 글로벌 우선으로 바꾸면 §4 이름 후보 중 영단어 계열(tabmates)로 기운다.

---

## 2. 브랜드 전략: 포켓몬 유지 vs 자작

### 2-1. 장점 대 리스크

| | 포켓몬 이름·모티프 유지 | 자작 마스코트 |
|---|---|---|
| 즉시 이해 | ◎ 파이리=불꽃 에이스, 메타몽=변신이 설명 없이 읽힘 | △ 첫 노출에 한 줄 설명 필요 |
| 재미·화제성 | ◎ | ○ 캐릭터가 좋으면 동등 |
| SMILE 검사 | Memorable·Imagery ◎ / **Legs ✕**(확장 불가) / **Restrictive ✕** | Legs ◎(굿즈·스티커·변종 가능) |
| 브랜드 자산 귀속 | **✕ 포켓몬컴퍼니에 귀속** — 잘될수록 남의 브랜드가 큼 | ◎ 잔잔재 자산 |
| 라이선스 확산 | ✕ CC BY로 풀 수 없음 | ◎ Gopher(CC BY)·Ferris(CC0)처럼 커뮤니티 변종 유도 가능 |
| 글로벌 | △ 파이리·꼬부기는 한국 현지화명 — 해외엔 안 통함 | ○ |
| 포트폴리오 인상 | △ "팬 프로젝트" 프레임 위험 | ○ "브랜드까지 만든 사람" |
| 법적 리스크 | §2-2 참조 | 없음 |

### 2-2. IP 리스크 매트릭스 (4층)

리서치 근거: github/dmca 21,833건 전수 grep, TMview(KIPO 미러) 상표 직접 조회, 포켓몬컴퍼니·닌텐도·GitHub·Apple 공식 정책 원문, 한국 대법원 판례. **법률 자문 아님** — 제품화 시점엔 변리사 1회 확인.

| 층 | 무엇 | C&D | GitHub 조치 | 앱스토어 | 한 줄 근거 |
|---|---|---|---|---|---|
| **A. 레포·플러그인·문서 제목**의 "pokemon/포켓몬" | `pokemon-agent-team`, `pokemon-team`, 「포켓몬 에이전트 팀」 | **중간** | 낮음(상표 신고만 가능, 구제 = 개명 후 복구) | 중간~높음(가이드라인 5.2) | 한국에서 「포켓몬」·「Pokemon」이 **닌텐도 명의로 9류(소프트웨어)·42류(SW 개발) 등록** 확인. 포켓몬컴퍼니 미디어 가이드라인이 "제품·서비스·앱·도메인 **이름**에 사용 금지"를 문언으로 명시. 2016 속초시에 "'포켓몬'이란 용어 자체도 저작권료 없이 사용 불가" 통보 전례 |
| **B. 에이전트 식별자** | 파이리·메타몽·꼬부기·로토무도감 | **매우 낮음** | 매우 낮음 | 중간(메타데이터 노출 시) | 대법원 96도1424 "출처 표시가 아닌 사용은 침해 아님". 실증: npm `pokemon`(월 4만 DL, 11년), pokemon-showdown, pret/pokered(디스어셈블리인데 13년 생존), Pokemon-Terminal 등 전부 생존. **이름만으로 내려간 GitHub 사례 0건**. 단 상표 등록 차이로 꼬부기(9류 등록) > 파이리(9·42류 없음) > 메타몽·로토무(미등록) |
| **C. 울음소리** | "파이리~!" | 매우 낮음 | 없음 | 낮음 | 짧은 의성어, 전례 0 |
| **D. 블로그 서술** | "에이전트를 포켓몬 이름으로 지었다" | 거의 없음 | 해당 없음 | 해당 없음 | 지명적 사용. 오히려 "IP 판단력"을 보여주는 콘텐츠 |

집행 패턴(사례 12건): 조치는 전부 **공식 파일(스프라이트·ROM·음악) 또는 수익화**가 있을 때였다. 닌텐도/포켓몬사 발신 GitHub DMCA 8건 전부 파일 지목. 전 포켓몬컴퍼니 최고법무 McGowan: *"the worst thing on earth is when your 'fan' project gets press, because now I know about you."* / 펀딩이 붙으면 그때 개입. → **10/25 소개 글은 작은 '언론 노출'이고, 수익화 금지가 방아쇠를 안 당기는 조건.**

### 2-2b. 전략 3안

| | ① 전면 유지 | ② A층만 교체 (제품명만 바꾸고 캐릭터 유지) | ③ 자작 마스코트 + 포켓몬은 사적 스킨 |
|---|---|---|---|
| 법적 리스크 | 중간(A층) | 낮음 | 없음 |
| 즉시 이해·재미 | ◎ | ◎ (B·C층 그대로) | ○ + 기원 서사로 회수 |
| 브랜드 자산·Legs·CC BY 확산 | ✕ | ✕ (캐릭터 자산은 여전히 남의 것) | ◎ |
| 포트폴리오 인상 | "팬 프로젝트" | 절충 | "브랜드까지 만든 사람" |
| 수정 비용 | 0 | 최소(「포켓몬」18회+「pokemon」16회, 17개 파일) | 이름·그림·스킨 표 분리 |


### 2-3. 확정: 전면 교체 + 기원 서사

1. **전부 자작** — 레포·README·소개 글·펫·로컬 세션까지 이름·그림·울음소리 전부 자작. 포켓몬 스킨은 로컬에도 두지 않는다(2026-09-03 사용자 결정: "바꾸는 김에 다 바꾼다", 유지할 이유 없음. 원 권고였던 사적 오버레이 유지는 철회).
2. **기원 서사는 공개** — "처음엔 파이리·메타몽·꼬부기로 시작했다"는 설명적 언급(nominative use)이라 안전하고, 오히려 글의 훅이 된다. 단 공식 그림·스프라이트는 소개 글에도 쓰지 않는다. changelog·DIRECTION에 히스토리로 남긴다.

이 구조가 "재미·이해"와 "자산·안전"을 동시에 가져간다. 포켓몬의 이해 보조 효과는 **기원 서사 한 문단**으로 대부분 회수된다. **②는 9/13 조정 밸브** — 마스코트가 늦으면 제품명만 바꾸고 캐릭터 이름을 그대로 두고 나가도 실재 리스크 경로(A층)는 끊긴다. 어느 안이든 공통 필수: 공식 아트 배제, README 비제휴 고지, 수익화 금지, 로고에 포켓몬 노란색·폰트 금지.

---

## 3. 브랜드 위계: 잔잔재 산하 vs 독립 제품

| | A. 잔잔재 산하 ("잔잔재의 X") | B. 독립 제품 + 저자 크레딧 |
|---|---|---|
| 이름 구조 | `janjanjae/{제품명}` 접두, 팔레트·톤을 잔잔재 시스템에서 상속 | 제품 고유 이름, README 하단 "made by 잔잔재(janjanjae)" |
| 장점 | 허브(janjanjae.dev)에 자연스럽게 묶임, 콘텐츠 축("과잉사고→구조화")과 직결 | 제품이 스스로 검색·기억됨. 나중에 협업자·기여자가 붙어도 어색하지 않음. Kiro가 AWS를 떼고 나온 이유와 같음(제품은 제품 이름으로 산다) |
| 단점 | 잔잔재 = 실명 인접 정체성이라 네이버 블로그(시·플레이리스트)와 섞이면 개발 툴 신뢰도가 흐려짐. 계정 rename이 선행돼야 함 | 브랜드가 하나 더 늘어 관리 표면 증가(로고·이름·소셜) |
| 잔잔 톤 상속 | 자동 | **디자인 언어로 상속**(§6 잔잔 규칙) — 이름은 독립이어도 시각은 같은 DNA |

**권고: B(독립 제품 + 저자 크레딧), 단 시각 언어는 잔잔재 DNA를 공유.** 오픈소스 관례(Rust/Ferris, Go/Gopher, Deno)가 전부 이 구조이고, 잔잔재 GitHub rename·프로필 정리가 아직 안 끝난 상태에서 A를 택하면 9/13에 선행작업이 두 배가 된다. 허브 편입은 janjanjae.dev가 생길 때 "만든 것" 목록으로 걸면 된다.

---

## 4. 프로젝트 이름

opensource.guide 3종 검사(생태계 충돌·핸들/도메인·상표)와 SMILE/SCRATCH로 걸렀다. 선점 조회는 2026-09-03 실측(npm·PyPI·GitHub 이름 검색·.dev 도메인 NS).

| 후보 | 뜻·근거 | npm | PyPI | GitHub | 비고 |
|---|---|---|---|---|---|
| **madang** (마당) | 팀원이 모여 일하는 앞마당. 파일 신호 = 마당에 놓인 쪽지. 발음 쉬움(ma-dang), 한국어 고유 | 선점 | 비어 있음 | 이름 포함 337개(정확 일치 유명 프로젝트 없음) | .dev NS 응답 없음(미등록 추정, 확인 필요) |
| **tabmates** | 탭 모드 + 팀메이트. 영어권 즉시 이해 | 비어 있음 | 비어 있음 | 3개 — **TabMates(더치페이 앱, org 선점)** | 조직명 충돌. 글로벌 우선이면 후보 |
| **dokkaebi** (도깨비) | 밤에 대신 일해 주는 한국 요괴. 뿔이 패밀리 시그니처 슬롯이 될 수 있음 | 선점 | 비어 있음 | 167개 | dokkaebi.dev **이미 사용 중**. 드라마 연상 강함 |
| pocketmates | "포켓 속 동료" | 비어 있음 | 비어 있음 | 0 | "Pocket Monsters" 오마주로 읽혀 §2 취지와 충돌 — 비추천 |
| moim (모임) | 모임·집합 | 비어 있음 | 비어 있음 | 727개 | 너무 일반명사, Imagery 약함 |

**확정(2026-09-03): `madang`.** Suggestive(마당=함께 일하는 열린 공간)·Imagery(마당·쪽지)·Legs(마당에 캐릭터를 늘어놓는 그림이 곧 README 히어로)·발음 용이. SCRATCH 걸림 없음. 레포명은 `madang`(플러그인 ID `madang`), 한글 표기 "마당". npm 선점은 npm 배포 계획이 없으므로 무관. **9/13 전 할 일**: WIPO Global Brand Database + KIPRIS에서 "madang/마당" 9·42류 조회, GitHub `madang` 리네임(리다이렉트 자동), `install.sh`·plugin.json ID 변경.

(이름은 사용자 결정. tabmates로 가면 글로벌 우선 결정과 세트.)

---

## 5. 로스터 정체성 재정의

### 5-1. 진단

파이리(에이스 구현)와 메타몽(구현 메인)의 겹침은 이름 문제가 아니라 **호출 조건** 문제다. ASAF(Frontiers in CS, 2026)의 명제: 두 에이전트가 사용자에게서 같은 상호작용 패턴을 이끌어내면 기술적으로 달라도 **기능적으로 동일**하다. "에이스/메인"은 시니어리티 라벨이라 사용자가 매번 "누가 더 잘하지?"를 판단해야 하고, 그게 곧 어포던스 중복이다. 커뮤니티 컨벤션(VoltAgent 100+ 서브에이전트)도 `senior-` 접두를 쓰지 않고 **범위·초점**으로 가른다.

같은 논문의 두 가지 부수 근거:
- 정체성 차별화형(이름·역할·톤) > 기능 라벨형 > 무라벨형 — **캐릭터 부여 자체는 지지**된다. 문제는 변별.
- 인간 운영자는 4~7명 관리가 최적. Anthropic 공식 문서도 3~5명 권장. **현 5명(팀장+4)이 스위트 스팟 — 늘리지 않는다.**
- 별도 실증(arXiv 2604.00026): 에이전트를 **모델명**으로 부르면 행동 유사도가 0.56→0.77로 올라간다. 페르소나 정의에 "너는 Sonnet"을 넣지 말 것(현재 frontmatter `model:`은 실행 설정이라 무관, 본문 서술만 피하면 됨).

### 5-2. 재정의 (호출 조건 기준)

| 역할 식별자(엔지니어링 층) | 호출 조건 = "언제 부르나" | 하지 않는 것 | 지배 도형 | 시그니처 슬롯 |
|---|---|---|---|---|
| `lead` 팀장 | 사람이 직접 대화. 브리프 배분·컨펌·허브 문서 | 코드 작성 | **원**(부모 도형, 부속 없음) | 없음 |
| `solver` (구 파이리) | **하나의 어려운 문제를 끝까지** — 핵심 슬라이스, 2회 실패 버그, 통합·재현불가·아키텍처급 | 병렬 물량 | **세모**(돌파·속도) | 뾰족한 꼭짓점 |
| `builder` (구 메타몽) | **같은 모양의 독립 태스크 N개** — 병렬 물량, 분신 | 난제 디버깅(2회 실패 시 solver로) | **구름**(봉우리 3, 바닥은 타원) | 떨어져 나간 조각(분신) |
| `sketcher` (구 꼬부기) | **화면이 필요할 때** — worktree 격리, 스크린샷 후보 → 확정안만 메인 | 백엔드·데이터 로직 | **네모**(화면) | 창 탭 |
| `narrator` (구 로토무도감) | **사용자가 이해하고 싶을 때** — 읽기 전용 감시·해설 | 모든 쓰기 | **말풍선** | 꼬리 |

식별자 후보는 `solver/builder/sketcher/narrator` 외에 `deep/wide/proto/dex`(짧고 대비가 명확)도 가능. 핵심은 **"깊이 vs 넓이"** 대비가 이름에 들어가는 것.

### 5-3. 두 층 분리 (ASAF "사회층과 엔지니어링층 분리")

- **엔지니어링 층**: `agents/solver.md`, `/solver`, `reports/solver.md` — 영문 역할명. 코드·경로·훅이 이걸 본다.
- **사회 층(스킨 표)**: 표시 이름·울음소리·이모지·그림을 **표 하나**(`roster.yaml` 같은 것)에서 읽는다. 스킨은 자작 하나뿐이다 — 표를 분리하는 이유는 pokepet·인사말·README가 같은 원천을 보게 하기 위해서다.
- 이렇게 하면 pokepet도, 인사말 규칙도, README 로스터 표도 스킨 표 하나에서 렌더된다. 현재 pokepet은 이미 "이름·이모지 표 하나"라 전환 비용이 낮다.

### 5-4. 캐릭터 이름 체계 후보 (사회 층)

| 체계 | 팀장 | solver | builder | sketcher | narrator | 평가 |
|---|---|---|---|---|---|---|
| **A. 의태어**(잔잔 톤, 인사말 전통 계승) | 도담 (dodam) | 번뜩 (beontteok) | 몽글 (monggeul) | 슥슥 (seukseuk) | 조잘 (jojal) | 한국어권 최강. 이름이 곧 울음소리("몽글~", "조잘조잘!"). 로마자 발음은 중간 |
| B. 도형 이름 | 동글 | 세모 | 몽글 | 네모 | 렌즈 | 구조화 축과 직결, 그러나 "네모(Nemo)"가 디즈니 연상, 밋밋 |
| C. 영단어 | Lead | Spark | Blob | Frame | Lens | 글로벌 즉시 이해. 단 `blob`은 코드 예약어급 일반명사라 검색·구분 약함 |

**확정(2026-09-03): A(의태어).** 잔잔재 브랜드 축("과잉사고→구조화"의 잔잔한 톤)과 로딩이 브랜드의 언어 감각에 맞고, 기존 "말버릇 첫 줄" 규칙을 그대로 계승한다(파이리~! → 번뜩!). 영문 README에는 로마자 + 역할 식별자를 병기하면 된다. 이름은 후보일 뿐 — 사용자가 어감으로 고를 것.

---

## 6. 디자인 컨셉

### 6-1. 잔잔 규칙 6 (브랜드 톤을 형태로)

Notion(Buck 스튜디오)의 "featureless·모노크롬·비켜서는 일러스트" 원칙 + 16px 가독성 원칙에서 도출.

1. **잉크 본체 + 역할 색은 슬롯 하나에만.** 본체 덩어리는 잉크 한 색. 역할 색은 시그니처 슬롯(꼭짓점·조각·탭·꼬리) 한 군데, 면적은 본체의 1할 아래 — 넓게 칠하면 실루엣을 가린다(사용자 피드백). 색을 빼도 실루엣만으로 5명이 구분돼야 통과.
2. **얼굴은 점 2개 + 선 1개, 5명 모두 같은 얼굴, 눈은 몸통 중심선·입은 눈 아래 14(2026-09-03 최종 — 위쪽은 이마가 없고 아래쪽은 처져 보여 중심선으로 절충).** 눈 크기·간격·입 길이를 바꾸지 않는다. 차이는 실루엣이 내고, 감정은 **자세·기울기**로. **미소는 작업 완료·APPROVE 순간 1회 전이로만** — 항상 웃으면 신호가 아니다.
3. **색은 상태에만.** waiting(컨펌 대기)=호박색 점, blocked(막힘)=적색 점. 그 외 상태는 배지 없음 → 색이 뜨면 그게 신호.
4. **모션 예산.** idle 바운스 진폭 ≤ 키의 6%, 주기 ≥ 2초, 이징 필수. 전이 시에만 강도↑, 3초 내 복귀. blocked/waiting은 1회 알림 후 정적 배지(반복 애니메이션 금지 — Clippy 역산).
5. **배치 4곳만.** README 히어로·소셜 카드·데스크톱 펫·터미널 탭. 문서 본문·CLI 출력에는 뿌리지 않는다(GitHub 브랜드 가이드 "less is more").
6. **기하 조립을 드러낸다.** 원·세모·구름·네모·말풍선이 보이게 남긴다 — "과잉사고를 구조로" 축이 형태 자체로 설명되고, 그림 실력 없이 Figma 불리언으로 만들 수 있다.

### 6-2. 캐릭터 패밀리 규칙

- **공통 골격 + 슬롯 1개** (포켓몬 스타터 트리오 로직): 같은 키·같은 눈 간격·같은 선 굵기, 다른 건 지배 도형과 시그니처 슬롯뿐.
- **팀장 = 부속 없는 원** — 나머지 4명의 "부모 도형". 패밀리 유사성의 기준점.
- **16px 실루엣 테스트가 1차 관문** — 검은 실루엣만으로 5명이 구분되면 통과. 색·디테일은 실루엣을 못 고친다.
- **분신 표현** — 구름 옆에 떨어져 나간 작은 조각 하나. 그 조각이 곧 몽글의 색 슬롯.

### 6-3. 팔레트 (초안)

| 토큰 | Light | Dark | 용도 |
|---|---|---|---|
| ink | #1E2430 | #E6E9EE | 캐릭터 본체·본문 |
| paper | #F5F7F8 | #15181D | 바탕(약한 청회색 편향 — "잔잔한 물") |
| solver | #B8563F | #D8836C | 세모 꼭짓점 + 이름표 |
| builder | #7A6FA8 | #A79DD1 | 떨어진 조각 + 이름표 |
| sketcher | #3E8E8A | #6DBDB8 | 창 탭 + 이름표 |
| narrator | #C09A2B | #E0BE5A | 말풍선 꼬리 + 이름표 |
| waiting | #D9A21B | 동일 | 컨펌 대기 배지 |
| blocked | #C0392B | 동일 | 막힘 배지 |

### 6-4. 상태 → 표현 매핑 — "말 없는 펫" (2026-09-03 확정, 사용자 피드백: 작은 글자는 어떤 배경에서도 가독성이 안 나온다 → 글자를 없애는 쪽으로)

| 팀 상태 | 마스코트 | 테두리 | 말풍선(글자) |
|---|---|---|---|
| 작업중 / 답장 처리중 | 눈 뜸, 미세 바운스 | 없음 | 없음 |
| 유휴 / 브리프 대기 / 휴식 | **눈 감음**(sleep 변형), 휴식은 반투명 | 없음 | 없음 (시간은 툴팁) |
| 컨펌 대기 / 논의 요청 | 정지 | 테두리 호박 발광 | 종이색 말풍선 "컨펌 대기" |
| 막힘 | 정지, 큰 바운스 | 테두리 적 발광 | 말풍선 "막힘" |
| 작업 완료 / APPROVE 수신 | 미소 1회, 3초 뒤 복귀 | 없음 | 없음 |

글자는 **사람이 행동해야 할 때만** 뜬다(Calm Tech: 주변부에 머물다 필요할 때만 중심으로). 그 외엔 한 번 클릭(엿보기 3초)·툴팁·메뉴 "말풍선 항상 표시"로 본다. 말풍선은 단색 종이 배경 + 12px 잉크 글자 + 꼬리(조잘 모티프)라 어떤 바탕에서도 읽힌다. 이름표는 없앰(실루엣이 이름) — 분신만 숫자 배지.

### 6-5. 제작 파이프라인

**v1(9/13) = A. Figma 기하 조립 → SVG → CSS 상태 변형.** 몸통 고정, 눈·부속 레이어만 교체하는 4 Variant. 바운스는 이미지가 아니라 `transform`으로. 저작권 이슈 없음, 다크 모드는 `currentColor`.
**v2 = C. 같은 SVG를 Rive 상태 머신으로** — idle CPU ≈ 0%(상시 오버레이의 배터리·팬 소음 = 잔잔함의 물리 조건).
**옵션 = B. AI 캐릭터 시트(Nano Banana 등) → 픽셀 스킨.** 쓰려면 반드시 사람이 Figma/Aseprite에서 재구성·보정하고 **프롬프트·수정 과정을 커밋 로그로 남긴다** — 한국 저작권위원회 2025-06 안내서·미 저작권청 2025 보고서 모두 "AI를 도구로 쓴 인간 기여분"만 보호. 오픈소스 레포의 커밋 이력이 그대로 증빙이 된다.

**마스코트 라이선스: CC BY 4.0**을 `BRANDING.md`에 명시(색상 변경 금지·보증 암시 금지 같은 CNCF식 조항 포함). Gopher가 확산된 결정적 이유이고 Octocat이 확산되지 않은 이유다.

### 6-6. 데스크톱 펫 체크리스트 (Calm Technology 8원칙 적용)

- [ ] 클릭 스루 기본, 드래그 이동
- [ ] 원클릭 숨김 + 영구 비활성화 1뎁스
- [ ] 유휴 상태에서 먼저 말 걸지 않음
- [ ] 화면 공유·전체화면 감지 시 자동 숨김
- [ ] 크기 프리셋(vscode-pets: nano/small/medium/large)
- [ ] "조용한 모드"(모션 없이 색 점만) — 회사 노트북용
- [ ] `prefers-reduced-motion` 존중, idle CPU 측정치를 릴리스 기준에 포함

---

## 7. 실행 로드맵

**9/13 v0.5 (저장소 공개 + README + 짧은 글) — 70점 컷**
1. 이름 확정 → WIPO/KIPRIS 조회 → 레포 리네임·plugin ID·install.sh
2. 식별자 리네임(`pairi→solver` 등) + 스킨 표 분리 + 포켓몬 이름·인사말 전부 교체(로컬 포함), 기원은 changelog에 기록
3. 마스코트 v1(SVG 5종 × idle/waiting/blocked) — Figma 불리언, 16px 실루엣 테스트 통과
4. pokepet 이모지 라벨 → SVG 뷰 교체(표 하나)
5. README: 훅 한 줄 → **오버레이 GIF(4명이 서로 다른 상태로 동시에)** → 30초 설치. 배지 3~5개. 영문 요약 1절
6. `BRANDING.md`(CC BY, 사용 규칙) + 기여 범위 선언
7. 짧은 글: 기원 서사(포켓몬으로 시작 → 자작으로) + GIF

**10/25 v1 (소개 글 + 알리기)**
- 계보(Smallville → Codex Pets → 마당) + "펫이 아니라 팀 구조" 포지셔닝 글
- 마스코트 v2(Rive) 여유 있으면
- awesome-claude-code 등 목록 PR, 한국 커뮤니티(GeekNews 등) 공유

**조정 밸브**: 9월이 버거우면 3·4(마스코트·펫 그림)를 10/25로 밀고 9/13은 이모지 스킨(자작 이름 + 도형 이모지 ●▲■)으로 나간다 — 이름·식별자 분리만 되어 있으면 리스크 0.

---

## 8. 출처

**오픈소스 브랜딩·네이밍·README**
- opensource.guide, Starting a project — https://opensource.guide/starting-a-project/
- Changelog, Naming an open source project — https://changelog.com/posts/naming-open-source-project-start
- Watkins, *Hello, My Name Is Awesome* (SMILE/SCRATCH) — https://books.google.com/books/about/Hello_My_Name_Is_Awesome.html?id=d2SEAwAAQBAJ
- 8 README mistakes (2차) — https://dev.to/ofershap/8-readme-mistakes-killing-your-github-stars-and-how-to-fix-them-ong
- Eghbal, *Working in Public* — https://press.stripe.com/working-in-public
- DuVander, *Developer Marketing Does Not Exist* — https://everydeveloper.com/developer-marketing/book/
- CNCF Brand Guidelines — https://www.cncf.io/brand-guidelines/ · Linux Foundation trademark — https://www.linuxfoundation.org/legal/trademark-usage

**마스코트 사례·라이선스**
- Go Gopher(CC BY) — https://go.dev/blog/gopher · Ferris(CC0) — https://ferris.rs/blogs/guides/can-you-use-ferris
- GitHub Mascots 가이드("less is more", 금지 목록) — https://brand.github.com/graphic-elements/mascots · Octodex FAQ — https://octodex.github.com/faq/
- Tux — https://en.wikipedia.org/wiki/Tux_(mascot) · Deno artwork — https://deno.com/artwork · Kiro/GeekWire — https://www.geekwire.com/2025/amazons-surprise-indie-hit-kiro-launches-broadly-in-bid-to-reshape-ai-powered-software-development/

**AI 코딩 툴 페르소나·계보**
- Codex Pets — https://www.engadget.com/2162796/openai-introduces-ai-generated-pets-for-its-codex-app/ · https://www.pcworld.com/article/3131011/i-love-my-new-codex-ai-pet-and-now-i-want-one-in-every-app.html
- Claude Code Agent Teams 공식 — https://code.claude.com/docs/en/agent-teams
- Generative Agents(Smallville) — https://dl.acm.org/doi/fullHtml/10.1145/3586183.3606763
- OpenDevin→OpenHands — https://www.openhands.dev/blog/one-year-of-openhands-a-journey-of-open-source-ai-development · Claude Dev→Cline — https://en.wikipedia.org/wiki/Cline_(AI_agent)

**역할 명명·페르소나 변별**
- ASAF, Frontiers in CS 2026 — https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2026.1860996/full
- Behavioral Differentiation Without Role Assignment, arXiv 2604.00026 — https://arxiv.org/abs/2604.00026
- VoltAgent awesome-claude-code-subagents — https://github.com/VoltAgent/awesome-claude-code-subagents · CrewAI agent guide — https://docs.crewai.com/en/guides/agents/crafting-effective-agents · MetaGPT — https://arxiv.org/html/2308.00352v6

**포켓몬 IP**
- 포켓몬컴퍼니 Media Usage Guidelines — https://pokemon.gamespress.com/Media-Usage-Guidelines · 스트리밍 가이드라인 — https://support.pokemon.com/hc/en-us/articles/17715339053972 · Nintendo 가이드라인 — https://www.nintendo.co.jp/networkservice_guideline/en/index.html
- GitHub 상표 정책 — https://docs.github.com/en/site-policy/content-removal-policies/github-trademark-policy · Apple 심사 5.2 — https://developer.apple.com/app-store/review/guidelines/
- github/dmca 원문: pokereact 2016 — https://github.com/github/dmca/blob/master/2016/2016-03-07-Pokemon.md · Essentials 2018 — https://github.com/github/dmca/blob/master/2018/2018-08-30-Nintendo.md
- McGowan 인터뷰 — https://aftermath.site/pokemon-lawyer-cease-desist-fan-project-pikachu-movie/ · https://www.videogameschronicle.com/news/former-pokemon-lawyer-says-fundraising-and-press-coverage-lead-to-fan-project-takedowns/
- 사례: Uranium — https://en.wikipedia.org/wiki/Pok%C3%A9mon_Uranium · Prism — https://www.vice.com/en/article/nintendo-shuts-down-pokemon-prism-rom-hack-after-eight-years-of-development/ · Pixelmon — https://kotaku.com/popular-pokemon-minecraft-mod-gets-shut-down-1796918730 · Relic Castle 2024 — https://www.nintendolife.com/news/2024/03/pokemon-fan-game-site-relic-castle-shut-down-following-dmca-takedown-notice · Game Jolt 2021 — https://www.nintendolife.com/news/2021/01/nintendo_issues_mass_dmca_takedown_379_fan-made_games_forcibly_removed · Pokénet — https://www.engadget.com/2010-04-02-nintendo-shuts-down-fan-made-pokemon-mmo.html · Pokédroid — https://nolanlawson.com/2011/05/26/on-pokedroids-removal/
- 생존 사례: npm pokemon — https://github.com/sindresorhus/pokemon · pokemon-showdown — https://github.com/smogon/pokemon-showdown · pret/pokered — https://github.com/pret/pokered · PokéAPI LICENSE — https://github.com/PokeAPI/pokeapi/blob/master/LICENSE.md
- 한국: 속초시 2016(SBS) — https://news.sbs.co.kr/news/endPage.do?news_id=N1003699155 · TMview(KIPO) — https://www.tmdn.org/tmview/ · 대법원 96도1424 — https://www.nepla.ai/case/%EB%8C%80%EB%B2%95%EC%9B%90/96%EB%8F%841424 · 2005도70 — https://casenote.kr/%EB%8C%80%EB%B2%95%EC%9B%90/2005%EB%8F%8470 · 96도139 — https://casenote.kr/%EB%8C%80%EB%B2%95%EC%9B%90/96%EB%8F%84139 · 부정경쟁방지법 2조 — https://casenote.kr/%EB%B2%95%EB%A0%B9/%EB%B6%80%EC%A0%95%EA%B2%BD%EC%9F%81%EB%B0%A9%EC%A7%80_%EB%B0%8F_%EC%98%81%EC%97%85%EB%B9%84%EB%B0%80%EB%B3%B4%ED%98%B8%EC%97%90_%EA%B4%80%ED%95%9C_%EB%B2%95%EB%A5%A0/%EC%A0%9C2%EC%A1%B0
- 미확인(지어내지 않음): 한국 법원의 포켓몬 상표 판결, 캐릭터 이름 단독 저작물성 판례, 한국 개인 OSS 대상 집행 사례

**캐릭터 디자인·제작·데스크톱 펫**
- 셰이프 랭귀지 — https://blog.cg-wire.com/character-shape-language/ · 16px 파비콘 — https://faviconstudio.com/blog/favicon-best-practices-2026
- 스기모리 켄 인터뷰 — https://www.nintendolife.com/news/2018/07/ken_sugimori_wants_pokemon_designs_to_be_as_memorable_as_possible · https://www.resetera.com/threads/translated-interviews-with-ken-sugimori-about-the-design-process-of-5th-gen-pok%C3%A9mon.124133/
- Notion 일러스트(Buck) — https://www.itsnicethat.com/articles/buck-notion-graphic-design-illustration-project-170724 · https://www.jannivalkealahti.com/fieldnotes/illustrated-mascot-humanizing-the-brand
- 2026 마스코트 트렌드 — https://svgapp.ai/blog/mascot-design-trends-2026/
- Figma 불리언 — https://justfigma.com/figma-boolean-operations-for-icons-and-ui-shapes/ · Rive vs Lottie — https://unicornicons.com/learn/rive-vs-lottie · PixelLab — https://www.pixellab.ai/ · Retro Diffusion — https://retrodiffusion.ai/
- AI 저작권: 한국저작권위원회 2025-06 안내서 — https://www.copyright.or.kr/information-materials/publication/research-report/view.do?brdctsno=54253 · 미 저작권청 2025 Part 2 — https://www.jonesday.com/en/insights/2025/02/copyrightability-of-ai-outputs-us-copyright-office-analyzes-human-authorship-requirement
- vscode-pets — https://tonybaloney.github.io/vscode-pets/getting-started/ · Calm Technology — https://www.calmtech.institute/calm-tech-principles · Clippy 교훈 — https://thenewstack.io/humanity-vs-clippy-lessons-from-microsofts-failed-virtual-assistant/
