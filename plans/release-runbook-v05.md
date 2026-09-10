# v0.5 공개일 런북 (2026-09-11)

> **위에서 아래로, 순서대로.** 각 단계는 명령·기대출력·🔴중단조건·되돌리기 4칸이다.
> 중단조건에 해당하면 다음 단계로 넘어가지 말고 팀장(도담)에게 그 화면을 그대로 보여줄 것.
> 상세 배경·전문(全文) 출력·판정표는 `plans/filter-repo-rehearsal-2026-09-10.md`를 참조 — 이 문서는 **그 요약 + 실행 순서**이며 절차가 겹치는 곳은 그쪽이 원본이다.
>
> 레포: `janjanjae/madang` · 로컬 경로: `~/Desktop/madang` (= `/Users/{user}/Desktop/madang`).

---

## 0. 선행 조건 게이트

| | 내용 |
|---|---|
| **명령** | `cd ~/Desktop/madang && git checkout main && git status --short && git worktree list` (원격 `origin`은 이 시점에 로컬보다 뒤처져 있는 게 정상이다 — 이 런북 자체가 로컬을 origin으로 밀어넣는 절차라 `git pull`은 필요 없다) |
| **기대 출력** | `git status --short`가 **빈 출력**(clean). `git worktree list`에 `main`과 이 런북 브랜치(`docs/release-runbook`) 외에 **진행 중인 워커 워크트리가 없다**(`wt-sanitize`·`wt-state` 등이 남아있으면 안 됨 — 작업 끝났으면 팀장이 정리했어야 한다). |
| **🔴 중단 조건** | ① `git status`에 미커밋 변경이 있으면 중단(누가 손댄 건지 먼저 확인) ② `.claude/TASKS.md` "현재 배분" 표를 열어 다음 4개가 전부 `main`에 머지 완료(✅)인지 확인 — **하나라도 아니면 시작 금지**: `chore/v05-sanitize-2`(sanitize 치환) · `feat/worker-state-v05`(+ 그 후속 피드백 라운드) · 스킬 리네임 2부(디렉토리 5개 이동, 브랜치명은 배분 시점 기준 미정이었음 — TASKS.md에서 확인) · `fix/github-type-hardening`의 `verify-tree.sh` 추가 커밋(`421f168`, 이 문서를 쓰는 시점엔 아직 재머지 전 — 1번 단계가 `claude/tools/sanitize/verify-tree.sh` 파일을 요구하니 이게 없으면 1번에서 바로 막힌다) ③ `git worktree list`에 미정리 워크트리가 남아 있으면 그 작업이 안 끝났다는 뜻이니 중단. |
| **되돌리기** | 이 단계는 관찰만 한다 — 되돌릴 것이 없다. |

---

## 1. `verify-tree.sh` 실행 → 치환표 확정

| | 내용 |
|---|---|
| **명령** | `cd ~/Desktop/madang && ./claude/tools/sanitize/verify-tree.sh` |
| **기대 출력** | exit 0(후보 없음) 또는 exit 1 + 후보 목록. **2026-09-10 기준 11건, 전부 무해로 이미 판정됨**(판정표: `plans/filter-repo-rehearsal-2026-09-10.md` "verify-tree.sh" 절). 0단계 이후 새 커밋이 안 들어왔다면 같은 11건이 나와야 정상이다. |
| **🔴 중단 조건** | 새로운 후보가 나타나고 사람이 "회사 정보다"로 판정하면 → **바로 이 단계에서** `claude/tools/sanitize/replacements.txt`에 치환 규칙을 추가한다. **이 단계 지나면 표를 바꾸지 않는다** — 뒤 단계(2·3)가 이 표를 전제로 검증하므로, 통과 후에 표를 고치면 그 검증들이 전부 무효가 된다. 판정이 애매하면(회사 정보인지 확신 없음) 실행을 멈추고 사용자에게 묻는다 — 임의 판단으로 넘기지 않는다. |
| **되돌리기** | 표를 잘못 고쳤으면 `git diff claude/tools/sanitize/replacements.txt`로 확인 후 `git checkout -- claude/tools/sanitize/replacements.txt`로 되돌릴 수 있다. **아직 아무것도 돌이킬 수 없는 지점이 아니다.** |

---

> ## 🔴🔴🔴 여기부터 되돌릴 수 없다 🔴🔴🔴
> 다음 단계(2번)부터는 실행 전에 한 번 더 멈춰서 위 1번이 정말 끝났는지 확인할 것.

---

## 2. filter-repo 실행 (미러 클론에서)

**명령**:
```bash
git clone --mirror ~/Desktop/madang ~/madang-backup.git && cp -R ~/madang-backup.git ~/madang-release.git
cd ~/madang-release.git && git filter-repo \
  --replace-text ~/Desktop/madang/claude/tools/sanitize/replacements.txt \
  --replace-message ~/Desktop/madang/claude/tools/sanitize/replacements.txt \
  --force
```

| | 내용 |
|---|---|
| **기대 출력** | `New history written in N seconds; now repacking/cleaning...` → `Completely finished after N seconds.` 에러 메시지 없음. |
| **🔴 중단 조건** | ① `git filter-repo: command not found` → `brew install git-filter-repo` 먼저 ② **`--replace-text`와 `--replace-message`를 둘 다 넣었는지 반드시 재확인** — 번뜩이 찾은 함정: `--replace-text`는 파일(blob) 내용만 바꾸고 **커밋 메시지는 `--replace-message`가 따로 필요**하다. 하나만 넣으면 에러 없이 "성공"하지만 절반만 치환된다(조용한 부분 실패) ③ 치환표 파일 경로에 오타가 있으면 filter-repo가 **아무 규칙도 못 찾고도 에러 없이 끝난다** — 아래 3번 검증이 이걸 잡아야 한다. |
| **되돌리기** | 이 단계는 **`~/madang-release.git`(작업용 미러) 안에서만** 재작성이 일어난다 — **실 레포 `~/Desktop/madang`과 `origin`은 아직 전혀 안 건드렸다.** 잘못됐으면 `rm -rf ~/madang-release.git`하고 `cp -R ~/madang-backup.git ~/madang-release.git`으로 다시 시작(1번으로 안 돌아가도 됨, 표는 이미 확정됨). `~/madang-backup.git`은 **절대 filter-repo에 넣지 않는다** — 이게 유일한 순수 원본이다. |

---

## 3. `verify-history.sh` 재검증

| | 내용 |
|---|---|
| **명령** | `~/Desktop/madang/claude/tools/sanitize/verify-history.sh ~/madang-backup.git ~/madang-release.git` |
| **기대 출력** | `① 패턴 잔존 검사`·`①-b 전 커밋 스냅샷 기준` 전부 `OK 0건` · `② 커밋 수 비교`에서 원본=재작성 동일 · `③ 브랜치·태그 보존` 동일 · 마지막 줄 `=== 전체 통과 ===`. |
| **🔴 중단 조건** | **하나라도 `FAIL`이면 다음 단계(push)로 넘어가지 않는다.** 특히 `①-b`(커밋 메시지까지 포함하는 엄격 검사)에서 남은 게 있으면 2번의 `--replace-message` 누락을 의심할 것 — 정확히 오늘 아침 리허설에서 걸렸던 패턴이다. `②` 커밋 수가 다르면 filter-repo가 커밋을 병합/유실한 것이므로 **절대 강행하지 말고** 2번부터 재시작. |
| **되돌리기** | 실패해도 `~/Desktop/madang`·`origin`은 아직 안전하다. `~/madang-release.git`을 지우고 2번부터 다시. |

---

## 4. gh 계정 확인

| | 내용 |
|---|---|
| **명령** | `gh auth status --active` |
| **기대 출력** | `janjanjae` 계정이 active. |
| **🔴 중단 조건** | ① active 계정이 `{company-gh-account}`(회사 계정)면 **`gh auth switch -u janjanjae`** 먼저(사용자가 직접 — 에이전트가 대신 하지 않는다) ② `gh api user`가 403/네트워크 오류를 내면 **사내망(ZTNA)이 켜져 있는 것** — 오늘 오전 정확히 이 이유로 개인 계정 접근이 막혔다(실측). **사내망을 끄고 재확인.** ③ 둘 다 정상인데도 이후 단계에서 API 오류가 나면 네트워크부터 의심. |
| **되돌리기** | 계정 확인만 하는 단계라 되돌릴 것 없음. 공개 작업이 다 끝난 뒤 회사 계정으로 원복하는 것은 8번 뒤 별도(팀장 소관, TASKS.md에 이미 기록됨). |

---

## 5. force-push — 공개 전 마지막 관문 (🔴 진짜 되돌릴 수 없음)

| | 내용 |
|---|---|
| **명령** | `cd ~/madang-release.git && git push --force --mirror https://github.com/janjanjae/madang.git` |
| **기대 출력** | 여러 갈래(`refs/heads/*`, `refs/tags/*`)에 대한 `+ ... forced-update` 줄들, 에러 없이 종료. |
| **🔴 중단 조건** | **이 명령을 실행하기 전, 3번의 "전체 통과"를 이 눈으로 다시 한번 확인할 것 — 되돌릴 수 없다.** 인증 오류가 나면(권한 없음) gh 계정을 다시 확인(4번). 그 외 실패는 **재시도하지 말고 멈춘다** — 부분적으로 push된 상태에서 재시도하면 더 꼬인다. |
| **되돌리기** | **원칙적으로 되돌릴 수 없다.** GitHub 캐시·포크·클론이 이미 잘못된 히스토리를 가져갔을 수 있다. 그나마 되돌리는 방법: `cd ~/madang-backup.git && git push --force --mirror https://github.com/janjanjae/madang.git` — 이건 **원격을 재작성 이전 상태로 강제로 되돌리는 것**이지, "실행 안 한 것"으로 만들지 못한다(그 사이 누가 클론했으면 그 사본엔 여전히 잘못된 히스토리가 남는다). `~/madang-backup.git`은 이 작업이 끝나고 **최소 1주** 지울 것 없이 보관한다. |

---

## 6. Public 전환 + 마무리

**명령**:
```bash
gh repo edit janjanjae/madang --visibility public --accept-visibility-change-consequences
gh repo edit janjanjae/madang --description "여기에 한 줄 소개 입력" --add-topic claude-code --add-topic ai-agents
gh issue list -R janjanjae/madang --state all -L 100 --json number,state --jq 'length'
```

| | 내용 |
|---|---|
| **기대 출력** | `gh repo view janjanjae/madang --json visibility`가 `PUBLIC`. 토픽·설명이 반영됨. 이슈 개수가 25(스모크 #25 포함) 또는 24(#25 삭제 후). |
| **🔴 중단 조건** | `--accept-visibility-change-consequences` 없이 실행하면 gh가 확인 프롬프트에서 멈춘다(터미널 인터랙티브 필요) — 자동화 스크립트로 돌릴 거면 이 플래그 필수. description·topic 값은 **여기 적힌 예시가 아니라 사용자가 그 자리에서 정한다.** |
| **되돌리기** | `gh repo edit janjanjae/madang --visibility private`로 다시 비공개 전환 가능(레포 자체는 되돌아가지만, 5번에서 이미 공개된 히스토리는 여전히 누군가의 클론에 남아 있을 수 있다 — 완전한 원복은 아니다). |

**스모크 이슈 #25 처리**: `janjanjae/madang#25`([스모크] issue-cache/issue-refine github 타입 보강 왕복 검증)는 CLOSED 상태로 남아 있다. 공개 전 삭제할지(`gh issue delete 25 -R janjanjae/madang --yes`) 이력으로 남길지는 **사용자 판단** — 번뜩의 실 검증 이력이라 지우지 않는 것도 합리적이다.

---

## 7. 공개 후 첫인상 확인

`plans/v05-first-impression-review-2026-09-05.md`가 외부 개발자 시점 62/70점, 최대 마찰이 정확히 이 경로("clone → install → 첫 명령")였다고 기록했다. 리네임이 오늘 들어갔으니 **명령 이름이 09-05 리뷰 당시와 다르다** — `/kickoff`→`/start` · `/save-progress`→`/checkpoint` · `/progress-check`→`/progress` · `/issue-capture`→`/issue-add` · `/issue-cache`→`/issue-fetch` (`/issue-refine`은 이름 유지).

**명령**:
```bash
cd /tmp && git clone https://github.com/janjanjae/madang.git madang-fresh-check && cd madang-fresh-check && ./install.sh
```

| | 내용 |
|---|---|
| **기대 출력** | 클론 성공, `install.sh`가 에러 없이 종료하고 셸 함수 배선 안내가 뜬다. 새 셸에서 `/start`(구 `/kickoff`)가 인식된다. |
| **🔴 중단 조건** | ① clone이 실패하면(private 남아있음) 6번으로 돌아가 visibility 재확인 ② `install.sh`가 회사 전용 문구(Copilot 조건부 처리 실패 등)를 무조건 출력하면 몽글의 sanitize가 이 파일을 안 건드린 것 — 중단하고 보고 ③ 새 명령 이름이 인식 안 되면 스킬 리네임 2부가 실제로는 안 끝난 것(0단계 게이트를 잘못 통과시킨 것). |
| **되돌리기** | `rm -rf /tmp/madang-fresh-check` — 이 단계는 사이드이펙트가 없다(로컬 클론 확인용). |

---

## 오늘 잡은 함정 2건 — 이 런북에 반영된 위치

| 함정 | 어디서 걸림 | 중단 조건 반영 |
|---|---|---|
| `regex::`/`literal::`(콜론 두 개)는 오문법 — 콜론 한 개가 맞다. 조용한 전체 치환 실패(카운트가 원본과 완전 동일)로만 드러난다. | `replacements.txt` 작성 시 | **1번**에서 표를 고칠 때, **3번**에서 반드시 잡힌다(패턴 잔존 카운트가 0이 안 되면 전체 실패를 의심). |
| `--replace-text`는 blob만, 커밋 메시지는 `--replace-message` 별도 필요. | filter-repo 실행 시 | **2번**의 명령에 두 플래그 모두 명시 + 중단조건에 명문화. **3번**의 `①-b`(전 커밋 스냅샷 기준)가 이 누락을 실제로 잡는다. |

## 자기 검증 메모 (처음 보는 사람인 척 다시 읽은 결과)

- 0번 게이트의 "스킬 리네임 2부 브랜치명 미정"은 실행 시점에 TASKS.md를 다시 봐야 한다는 뜻을 명확히 했다 — 이 문서만으로 판단하려 하면 막힐 자리라 표시해 둠.
- 6번의 description·topic 값은 의도적으로 플레이스홀더로 남겼다(그 자리는 사용자 취향 판단이라 미리 정하면 오히려 틀린다).
- 5번(force-push)과 2번(filter-repo) 둘 다 "되돌릴 수 없다"고 쓰면 어느 쪽이 진짜 마지노선인지 흐려질 위험이 있어, 2번은 "이 미러 안에서만 되돌릴 수 없다(실 레포는 안전)"로, 5번은 "진짜 되돌릴 수 없음"으로 강도를 구분해 표시했다.
