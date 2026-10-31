# 마당 Codex판 — 처음부터 끝까지

설치 직후 이 파일 하나만 보고 따라간다. 명령은 전부 **작업 공간 루트**에서 친다.
설치 후 작업 공간의 `.codex/START.md`에 복사된다 — 에디터로 열거나 `cat .codex/START.md` · 앞부분만: `head -60 .codex/START.md`

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
$              스킬 목록: teamleader · solver · builder · sketcher · narrator · 습관 4개
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

## 3. 계획 (10~15분)

Codex에:
```
$teamleader 로 진행. README·과제 파일 읽고 AGENTS.md의 '과제별' 칸(실행·테스트 명령, 포트)을 채워줘.
그리고 plan.md 에서 빠진 요구사항·위험·애매한 점을 지적해줘. 코드는 아직 짜지 마.
```
- 제출 문서(plan.md 등)에는 **판단 · 근거 · 검증 결과 · 남은 한계**가 들어가야 한다. Codex와 같이 써도 된다.
- 문제 정의·반드시 될 것 3개·안 할 것은 내가 먼저 몇 줄 쓰고 Codex가 보강하게 하면 의도가 기록에 남는다.

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
- 매 시 정각쯤 `/status`로 토큰 확인 + plan.md 결정 로그 한 줄.
- 서버가 안 뜰 때 순서: 터미널 에러 → 실제 포트 → `0.0.0.0` 바인딩 → 경로.

## 6. 기능 동결 → 검증 (마감 55분 전)

```
$verification-before-completion 로 지금까지 만든 것 검증해줘. 테스트·엣지 케이스·입력 검증·키 노출 확인하고 실제 출력 보여줘.
```
- 새 기능은 그만. README에 실행 방법(설치·실행·테스트 명령, 포트) 정리.

## 7. 제출 문서 (마감 30분 전)

```
plan.md 에 판단·근거·검증 결과·남은 한계를 정리해줘. 결정 로그는 시간순으로.
narrator(조잘)로 지금까지 만든 구조와 내가 내린 결정을 설명해줘.
```
- 조잘의 설명은 후속 질문 대비로 읽는다 (그 단계는 AI 없이 직접 답한다).

## 8. 제출 (마감 15분 전 시작)

```bash
git status --short          # 커밋 안 된 변경 확인
git log --oneline -10
ls -la                      # 필수 파일 경로·이름 확인
```
- 에디터 저장 상태가 "저장됨"인지 확인 → 제출.
- 질문의 전제가 실제 구현과 다르면 그 차이부터 밝히고 내 작업을 설명한다.

---

## 설치가 만드는 것

| 경로 | 이미 있으면 |
|---|---|
| `.agents/skills/` 스킬 9개 (teamleader · solver · builder · sketcher · narrator · planning · incremental · debugging · verification) | 파일 단위로 건너뜀 |
| `.codex/agents/` solver · builder · sketcher · narrator `.toml` | 건너뜀 |
| `.codex/hooks.json` · `.codex/hooks/madang_hook.py` | 건너뜀 |
| `.codex/START.md` (이 문서) | 건너뜀 |
| `.codex/madang-restricted` (`--restricted` 때만, push 차단 표식) | 건너뜀 |
| `.team/TASKS.md` · `.team/PROGRESS.md` | 건너뜀 |
| `.team/briefs/` `confirm/` `reports/` `plans/` 빈 폴더 | 그대로 둠 (`mkdir -p`) |
| `AGENTS.md` | 없으면 새로 만듦. 있으면 **원본 유지 + 맨 아래 `<!-- madang:start -->` 블록만 추가**, 원본은 `.codex/AGENTS.md.orig`로 백업. 이미 madang 규칙이 있으면 건너뜀 |

덮어쓰는 파일은 없다. 되돌리기: 설치 출력에서 "추가"로 찍힌 파일만 지우고, `AGENTS.md`는 `<!-- madang:start -->`~`<!-- madang:end -->` 블록만 삭제하거나 `.codex/AGENTS.md.orig`로 복원. 과제가 원래 갖고 있던 `.codex`·`.agents`는 지우지 않는다.
