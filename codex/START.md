# 마당 Codex판 — 처음부터 끝까지

설치 직후 이 파일 하나만 보고 따라간다. 명령은 전부 **작업 공간 루트**에서 친다.
설치 후 작업 공간 루트의 `MADANG-START.md`(파일 트리에서 바로 열기)와 `.codex/START.md`에 복사된다 — `cat MADANG-START.md` · 앞부분만: `head -60 MADANG-START.md`

---

## 0. 설치 (2분)

```bash
pwd                                                   # 작업 공간 루트인지 확인
git clone https://github.com/janjanjae/madang /tmp/madang
bash /tmp/madang/codex/install.sh --restricted        # 감독·폐쇄 환경. 일반 환경은 옵션 없이
```

- `/tmp` 앞 슬래시 필수. 빼먹어서 작업 공간 안에 `tmp/`가 생겼다면 설치 후 **첫 커밋 전에** `rm -rf tmp`.
- 설치는 기존 파일을 덮어쓰지 않는다 (아래 "설치가 만드는 것" 참고).

## 1. Codex 준비 (3분)

```bash
codex                                  # 이미 켜져 있었다면 exit 후 다시 codex
```
Codex 안에서:
```
/status        모델·권한 확인
/model         플래그십 모델 + 추론 강도 medium (계획·어려운 버그 때만 high)
/hooks         madang 훅 검토 → 신뢰
$              스킬 목록: teamleader · solver · builder · sketcher · narrator · defense-drill · 습관 4개
```

(선택) 낯선 라이브러리를 쓰는 과제면 IDE의 MCP 설정에 문서 검색 MCP 하나 — 기존 예시 형식에 맞춰 넣고 Codex 재시작:
```json
{ "mcpServers": { "context7": { "url": "https://mcp.context7.com/mcp" } } }
```
MCP는 하나만. 도구 설명이 매 요청 토큰을 먹는다.

## 2. 과제 읽기 (10분) — 코드보다 먼저

```bash
ls -la                     # 숨김 파일 포함 전체 구조
cat README.md              # 과제 안내 (이름이 다르면 ls 결과에서 찾는다)
git log --oneline -5       # 시작 커밋 확인
```
- 필수 제출물·**파일명**·제출 문서 틀(예: plan.md)을 목록으로 적는다. **파일명과 틀은 과제 안내가 1순위.**
- 애매한 요구사항은 모아 둔다 → 업무 담당자(실무자) 에이전트에게 **한 번에** 묻는다.
- 과제에 원래 있던 `AGENTS.md`는 설치 때 그대로 두고 맨 아래에 madang 블록만 붙었다. 충돌하면 과제 규칙이 우선.

## 3. 질문 → 기획서 → 코드 (20분)

① 문제 정의·반드시 될 것 3개·안 할 것을 **내가 먼저** plan.md에 몇 줄 쓴다. 의도가 기록에 남는다.

② 질문 (최대 2라운드·10분) — Codex에:
```
$teamleader 로 진행. README·과제 파일 읽고 AGENTS.md의 '과제별' 칸(실행·테스트 명령, 포트)을 채워줘.
그리고 내가 쓴 plan.md 기준으로 질문 라운드를 돌려줘. 종료 시각은 HH:MM, 동결은 HH:MM.
기능 코드는 아직 짜지 마. 답과 무관한 준비 작업이 있으면 네 판단으로 팀원 브리프로 바로 나눠줘.
```
- 내 판단이 필요한 질문은 권장안과 함께 나온다. 동의하면 "응", 아니면 내 말로 답한다.
- 업무 담당자용 질문 표(필수/선택)가 나오면 내가 고른 것만 메신저에 **한 번에** 붙여넣고, 답을 Codex에 전달한다. 답을 주면 "바뀐 가정"만 표로 나온다.
- 준비 브리프가 나오면 팀원 탭을 띄워 바로 돌린다 (4번 표의 탭 방식).

③ 기획서 (5~10분) — Codex가 답을 plan.md로 합성한다. 제출 문서(plan.md 등)에는 **판단 · 근거 · 검증 결과 · 남은 한계**가 들어가야 한다.

④ 태스크의 크기와 순서를 내가 확인하고 **승인한 뒤에** 코드로 넘어간다.

## 4. 나눌지 정하기

| 상황 | 방식 | 어떻게 |
|---|---|---|
| **기본** | **탭** | `$teamleader`가 `.team/TASKS.md`·`.team/briefs/<이름>.md` 작성 → `+` 새 터미널 → `codex` → `$builder` / `$sketcher` |
| 아주 작거나 전부 같은 파일에 몰림 | 단일 | 팀장 탭에서 그대로 (`.team/` 안 씀) |
| 한 번에 끝나는 일 | 서브에이전트 | "solver(번뜩)로 이 버그 근본 원인 찾아줘" · "narrator(조잘)로 구조와 결정 설명해줘" |

문서 역할 — 같은 내용을 두 곳에 쓰지 않는다:
- `plan.md` = 큰 계획(요구사항 R·태스크 T 상세) + 결정 로그(왜) + 검증 결과 + 남은 한계. 완료 시 `[x] T1 (<SHA>)`.
- `.team/TASKS.md` = 배정판. T번호·담당·파일 영역·상태만.
- `.team/PROGRESS.md` = 진행 로그. `- HH:MM T1 APPROVE (<SHA>)`처럼 아래로 추가만.
- 제출 문서 이름·틀은 과제 안내가 1순위. 작업 공간 파일은 전부 수집되니 모든 문서를 읽히게 쓴다.

- 팀원은 최대 2명. 파일 영역을 겹치지 않게 (예: 몽글 `api/`, 슥슥 `web/`).
- 탭은 자동 감시가 없다. 팀원 탭에 **"브리프 확인해"**, 팀장 탭에 **"컨펌 확인해"**를 직접 친다.
- 서브에이전트 진행 보기: `/subagents`

## 5. 구현 루프

작게 맡기고 → 직접 실행해서 보고 → 커밋.

**서버는 새 터미널(`+`)에서 내가 직접 띄운다.** Codex에게는 "실행 명령만 알려줘, 실행은 내가 할게". 서버 탭은 닫지 않는다.
```bash
# 과제가 정한 명령이 1순위. 없을 때 흔한 것:
uvicorn main:app --host 0.0.0.0 --port 8000 --reload       # FastAPI
flask --app app run --host 0.0.0.0 --port 5000              # Flask
npm install && npm run dev -- --host 0.0.0.0 --port 3000     # Vite·React
npm start                                                    # 과제가 PORT를 정해 둔 Node
python3 -m http.server 8000 --bind 0.0.0.0                   # 정적 파일
```
미리보기: Browser 도구 → PORT에 터미널에 찍힌 포트, URL에 `/` (또는 `/dashboard` 같은 경로) → 원형 화살표.

자주 쓰는 명령:
```bash
pip install -r requirements.txt        # 파이썬 의존성
npm install                            # 노드 의존성
pytest -q                              # 파이썬 테스트
npm test                               # 노드 테스트
lsof -i :8000                          # 포트 점유 확인 → kill <PID>
git status --short                     # 변경 파일
git diff --stat                        # 변경량
git add -A && git commit -m "feat: <무엇을> — <왜>"   # 작은 단위 커밋 (push 금지)
git log --oneline -10                  # 커밋 기록
```
- 같은 에러에 두 번 실패 → `$debugging-and-error-recovery` → 그래도 안 되면 solver(번뜩).
- 태스크를 승인할 때 Codex가 묻는 "왜 이렇게 했어요?"에 **내 말로 한 줄** 답한다. 결정 로그에 남고 8번 서술형의 재료가 된다.
- 매 시 정각쯤 `/status`로 토큰 확인 + plan.md 결정 로그 한 줄 + 팀장 탭에 "지금 HH:MM"이라고 말해 다음 체크포인트까지 남은 시간 받기.
- 팀장 탭 컨텍스트가 절반을 넘었거나 단계가 바뀌면 → 팀장 탭에 "체크포인트" → 안내대로 `/new` → `$teamleader 이어서. plan.md·.team/TASKS.md·.team/PROGRESS.md 읽고 이어가`.
- 서버가 안 뜰 때 순서: 터미널 에러 → 실제 포트 → `0.0.0.0` 바인딩 → 경로.

## 6. 기능 동결 → 검증 · 제출 문서 (작업 타이머 잔여 45분~30분)

시간은 전부 **작업 타이머의 잔여 시간** 기준이다(팀장이 plan.md 맨 위에 적은 종료·동결 시각). Codex는 타이머를 못 보니 내가 챙긴다.

```
$verification-before-completion 로 지금까지 만든 것 검증해줘. 테스트·엣지 케이스·입력 검증·키 노출 확인하고 실제 출력 보여줘.
```
- 새 기능은 그만. README에 실행 방법(설치·실행·테스트 명령, 포트) 정리.
- plan.md `가정`을 한 번 훑는다. 틀린 가정은 작으면 팀장 탭에서 지금 고치고, 크면 `남은 한계`에 적는다.
```
plan.md 에 판단·근거·검증 결과·남은 한계를 정리해줘. 결정 로그는 시간순으로.
```
- 문서를 먼저 끝낸다. 서술형 문항은 제출물과 작업 기록으로 만들어지고, 다음 단계의 재료도 이 문서다.

## 7. 이해 세션 (잔여 30분~5분, 25분)

`+` 새 터미널 → `codex` → 첫 입력:
```
$defense-drill
```
- 우선순위 높은 질문부터 **질문 → 모범 답안 → 왜 그 답인지**를 하나씩 받는다. "다음"으로 넘기고, 먼저 내 말로 답해 보고 싶으면 "내가 먼저".
- 이 세션에서는 코드를 고치지 않는다. 드러난 문제는 plan.md `남은 한계`에 적힌다.
- 치명적인 문제(실행이 안 됨, 필수 요구사항 누락)만 팀장 탭에서 고치고 다시 확인한다. 나머지는 `남은 한계`에 둔다.
- 시간이 밀렸으면 잔여 5분에 끊고 제출로 넘어간다. 세션을 위해 제출을 미루지 않는다.

## 8. 제출 → 서술형 (잔여 5분에 점검, 1분 전까지 확정)

```bash
git status --short          # 커밋 안 된 변경 확인
git log --oneline -10
ls -la                      # 필수 파일 경로·이름 확인
```
- 에디터 저장 상태가 "저장됨"인지 확인 → "제출하고 문제풀기" → 미리보기 → "제출물 확정하고 문제풀기". 🔴 확정하면 파일을 고칠 수 없고 **이후 AI 사용 금지**.
- 문제 준비 대기 후 **문항당 5분씩**, 직접 입력(복사·붙여넣기 불가). 확정한 답은 고칠 수 없다.
- 답안 틀: **결론 1줄 → 근거 → 한계나 대안**. 시간이 끝나면 입력한 만큼 자동 확정되니 결론부터 친다.
- 질문의 전제가 실제 구현과 다르면 그 차이부터 밝히고 내 작업을 설명한다.

---

## 설치가 만드는 것

| 경로 | 이미 있으면 |
|---|---|
| `.agents/skills/` 스킬 10개 (teamleader · solver · builder · sketcher · narrator · defense-drill · planning · incremental · debugging · verification) | 파일 단위로 건너뜀 |
| `.codex/agents/` solver · builder · sketcher · narrator `.toml` | 건너뜀 |
| `.codex/hooks.json` · `.codex/hooks/madang_hook.py` | 건너뜀 |
| `MADANG-START.md` · `.codex/START.md` (이 문서) | 건너뜀 |
| `.codex/madang-restricted` (`--restricted` 때만, push 차단 표식) | 건너뜀 |
| `.team/TASKS.md` · `.team/PROGRESS.md` | 건너뜀 |
| `.team/briefs/` `confirm/` `reports/` `plans/` 빈 폴더 | 그대로 둠 (`mkdir -p`) |
| `AGENTS.md` | 없으면 새로 만듦. 있으면 **원본 유지 + 맨 아래 `<!-- madang:start -->` 블록만 추가**, 원본은 `.codex/AGENTS.md.orig`로 백업. 이미 madang 규칙이 있으면 건너뜀 |

덮어쓰는 파일은 없다. 되돌리기: 설치 출력에서 "추가"로 찍힌 파일만 지우고, `AGENTS.md`는 `<!-- madang:start -->`~`<!-- madang:end -->` 블록만 삭제하거나 `.codex/AGENTS.md.orig`로 복원. 과제가 원래 갖고 있던 `.codex`·`.agents`는 지우지 않는다.
