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
| **🔴 중단 조건** | ① `git status`에 미커밋 변경이 있으면 중단(누가 손댄 건지 먼저 확인) ② `.claude/TASKS.md` "현재 배분" 표를 열어 다음이 전부 `main`에 머지 완료(✅)인지 확인 — **하나라도 아니면 시작 금지**: `chore/v05-sanitize-2`(sanitize 치환) · `feat/worker-state-v05`(+ 그 후속 피드백 라운드) · 스킬 리네임 2부(디렉토리 5개 이동, 브랜치명은 배분 시점 기준 미정이었음 — TASKS.md에서 확인). (`fix/github-type-hardening`의 `verify-tree.sh` 커밋은 `9a56408`로 이미 재머지됨 — ✅ 해소) ③ `git worktree list`에 미정리 워크트리가 남아 있으면 그 작업이 안 끝났다는 뜻이니 중단 ④ **공개 ref 확인**: `git branch --no-merged main`을 돌려봐서 아직 main에 안 들어간 로컬 브랜치가 남아 있으면 안 된다(비어 있어야 정상 — ②의 항목들이 전부 머지되면 모든 작업 브랜치가 main의 조상이 된다). 아래 "5번 — force-push가 정확히 무엇을 공개하는가" 절을 **아직 안 읽었으면 여기서 먼저 읽는다**(A/B안 결정이 5번 명령을 바꾼다). |
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

## 5. force-push — 정확히 무엇이 공개되는가 (🔴 진짜 되돌릴 수 없음)

### `--mirror`가 실제로 무엇을 미는지 (문서 근거 + 실측, 2026-09-10)

`git push --help`: `--mirror`는 **"refs/ 아래 전부(이는 refs/heads/·refs/remotes/·refs/tags/를 포함하되 그것만은 아니다)"** 를 원격에 강제로 맞춘다 — heads·tags만이 아니라는 게 공식 문서에 명시돼 있다.

레포 밖 `/tmp`에 미러 클론을 떠서 `git for-each-ref`로 직접 세어 확인(origin 미접촉, 확인 후 클론 삭제):

```
$ git clone --mirror ~/Desktop/madang /tmp/madang-refcheck.git
$ git -C /tmp/madang-refcheck.git for-each-ref | wc -l
15
```

**합계 15** — `refs/heads/*` 12개(작업 브랜치 11 + `main`) · `refs/remotes/origin/HEAD`·`refs/remotes/origin/main` 2개 · `refs/tmp-mainref` 1개. 태그는 0개.

**filter-repo(2번)를 거치면 어떻게 바뀌는지도 확인**: 같은 미러를 복사해 filter-repo를 돌려보니 `refs/remotes/origin/*` 2개가 **자동으로 사라졌다**(filter-repo가 기본 동작으로 `origin` 리모트 자체를 제거하면서 그 추적 ref도 함께 없어짐 — 공식 동작, "Removing 'origin' remote" 안내가 뜬다). `refs/tmp-mainref`는 **살아남는다**(다른 ref와 똑같이 새 해시로 재작성됨). `refs/replace/*`는 생기지 않았다. 즉 **2번(filter-repo)을 거치고 나면 원격추적 ref 2개는 이미 사라져 있다** — 남은 문제는 작업 브랜치 11개와 `tmp-mainref` 1개뿐이다.

### `tmp-mainref`의 정체

```
$ git log -1 tmp-mainref
commit d570b8d6e1f3f42ce09a51212c960a9d42853b0e
    Merge fix/github-type-hardening — github 타입 보강 10건 ...
$ git reflog show tmp-mainref   # 비어 있음 — refs/heads·refs/remotes 밖의 커스텀 ref는 git이 기본적으로 reflog를 안 남긴다
$ git merge-base --is-ancestor tmp-mainref main && echo ancestor
ancestor
```

`tmp-mainref`는 **main의 바로 이전 위치(d570b8d, verify-tree.sh 병합 직전의 main)를 정확히 가리킨다** — main의 조상이고, 별도 작업 내용은 없다. `.git/refs/` 아래 loose ref로 존재하고(`refs/heads/`가 아니라 최상위 `refs/`), reflog가 없어 "누가 왜"는 로그로 증명 못 하지만, **시점·내용 정황상 그 병합 직전에 팀장(또는 야간 자동화)이 "되돌릴 지점"으로 남긴 수동 체크포인트 ref로 추정**한다(추측이라고 명시 — 확신 아님). **삭제 판정: main의 순수 조상이라 삭제해도 히스토리 유실은 없다.** 단 브리프 지시대로 **삭제는 하지 않았다** — 팀장·사용자 판단.

### 공개 ref 정책 — 두 가지 안

| | **A. `main`만 공개** | **B. 브랜치도 공개** |
|---|---|---|
| **범위** | `refs/heads/main`만 | `refs/heads/*` 전부(현재 12개 — 실행 시점엔 0번 게이트를 통과했으므로 전부 main의 조상, 즉 **공개해도 새 정보가 없다**, 브랜치 이름표만 추가로 보임) |
| **장점** | 가장 깨끗. 방문자가 보는 첫 화면에 작업용 브랜치명(`chore/v05-blockers` 등 내부 워크플로우 용어)이 노출되지 않는다 | "여러 페르소나가 브랜치로 병렬 작업한다"는 이 프로젝트의 실제 개발 방식이 그대로 드러난다 — README가 설명하는 내용의 증거가 된다 |
| **단점** | 개발 과정(머지 전 브랜치 단위 커밋)이 안 보인다 — 다만 `main`의 머지 커밋 자체에 브랜치명이 메시지로 남아 있어 완전히 안 보이는 건 아니다 | 브랜치명에 내부 용어·오탈자·임시 이름이 그대로 박제된다. 공개 후 브랜치를 늘/줄일 때마다 매번 "정리해서 다시 push"가 필요해진다(관리 부담 지속) |

**추천: A(`main`만 공개).** 0번 게이트가 "모든 작업 브랜치는 main에 머지 완료"를 전제로 하므로, 실행 시점엔 **11개 브랜치 전부가 main의 조상**이다(위 `git branch --no-merged main` 확인 — 비어 있어야 통과). 즉 B를 선택해도 **커밋 내용 기준으로는 새로 드러나는 게 없고**, 순수하게 브랜치 이름표만 더 보인다 — 이름표 노출의 이득(개발 과정 서사)보다 지속적인 관리 부담(매 릴리스마다 브랜치 정리)이 커 보인다. 다만 이건 제품 성격 판단이라 **최종 선택은 사용자 몫**이다.

### 명령 (A/B 둘 다 병기 — 사용자가 고른 쪽만 실행)

**A. `main`만**:
```bash
cd ~/madang-release.git
git push --force https://github.com/janjanjae/madang.git refs/heads/main:refs/heads/main
```

**B. 로컬 브랜치 전부** (와일드카드 refspec — `refs/heads/*`만 매칭, `refs/remotes/*`·`refs/tmp-mainref`는 애초에 이 패턴에 안 걸려 구조적으로 제외된다):
```bash
cd ~/madang-release.git
git push --force https://github.com/janjanjae/madang.git 'refs/heads/*:refs/heads/*'
```

🔴 **어느 안이든 `--mirror`를 쓰지 않는다** — 그게 `refs/remotes/*`·`refs/tmp-mainref`가 공개되는 근본 원인이다. 위 두 명령 다 `refs/heads/*` 안쪽만 건드리는 명시적 refspec이라 구조적으로 안전하다.

⚠️ **알아내지 못한 것**: 지금 `origin`이 이미 어떤 브랜치를 갖고 있는지 이 세션에서 확인 못 했다(gh 계정이 회사 계정으로 원복돼 있어 개인 레포 조회 불가 — 이 태스크 자체가 `gh auth` 금지라 전환도 안 함). **위 명령은 `--mirror`가 아니므로 origin에 이미 있지만 로컬엔 없는 브랜치가 있다면 그건 안 지워진다** — 실행 직전에 `gh api repos/janjanjae/madang/branches --jq '.[].name'`(janjanjae 계정으로)로 한 번 확인해 두는 걸 권한다.

| | 내용 |
|---|---|
| **기대 출력** | (A) `main` 한 줄의 `+ ... forced-update`. (B) `refs/heads/*` 전체에 대한 `+ ... forced-update` 여러 줄 — 어느 쪽이든 `refs/remotes/`나 `tmp-mainref` 언급이 **없어야** 정상. |
| **🔴 중단 조건** | **실행 전, 3번의 "전체 통과"를 다시 확인 — 되돌릴 수 없다.** A/B 중 어느 걸 실행하는지 **실행 직전에 소리 내어 확인**(둘 다 준비돼 있으니 헷갈리기 쉽다). 인증 오류면 gh 계정 재확인(4번). 그 외 실패는 **재시도하지 말고 멈춘다** — 부분 push 상태에서 재시도하면 더 꼬인다. |
| **되돌리기** | **원칙적으로 되돌릴 수 없다.** GitHub 캐시·포크·클론이 이미 잘못된 히스토리를 가져갔을 수 있다. 그나마 되돌리는 방법: `cd ~/madang-backup.git && git push --force --mirror https://github.com/janjanjae/madang.git`(여기서는 원본 복원이 목적이라 `--mirror`가 맞다) — 이건 **원격을 재작성 이전 상태로 강제로 되돌리는 것**이지, "실행 안 한 것"으로 만들지 못한다(그 사이 누가 클론했으면 그 사본엔 여전히 잘못된 히스토리가 남는다). `~/madang-backup.git`은 이 작업이 끝나고 **최소 1주** 지울 것 없이 보관한다. |

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
- 5번에 A/B 두 명령을 나란히 두면 실행 직전에 **어느 쪽을 실행하는지 헷갈릴 수 있어** 중단조건에 "실행 직전 소리 내어 확인" 한 줄을 넣어뒀다 — 되돌릴 수 없는 단계에서 헷갈림은 그 자체로 사고 원인이다.

---

## GitHub 아이디 의존 목록 (`janjanjae` — 결정 나면 일괄 교체용)

⚠️ 사용자가 `janjanjae` → `janjanjae` 변경을 검토 중. **지금은 그대로 둔다** — 결정되면 아래 줄만 찾아 바꾸면 된다(이 커밋 기준 14곳 — 문서가 그 사이 바뀌었으면 줄번호 대신 `grep -n janjanjae plans/release-runbook-v05.md`로 다시 찾을 것):

| 줄 | 내용 |
|---|---|
| 7 | 문서 상단 레포 표기 |
| 73 | 4번 "기대 출력" — gh 계정명 |
| 74 | 4번 중단조건 — `gh auth switch -u janjanjae` |
| 125 | 5번 옵션 A 명령 — push URL |
| 131 | 5번 옵션 B 명령 — push URL |
| 136 | 5번 "알아내지 못한 것" — `gh api repos/janjanjae/madang/branches` |
| 142 | 5번 되돌리기 — 백업 복원 push URL |
| 150–152 | 6번 명령 3줄 — `gh repo edit`·`gh issue list` |
| 157 | 6번 기대출력 — `gh repo view` |
| 159 | 6번 되돌리기 — `gh repo edit --visibility private` |
| 161 | 스모크 이슈 #25 처리 — 이슈 URL·`gh issue delete` |
| 171 | 7번 명령 — 클론 URL |

**이 문서 밖 의존**: `git -C ~/Desktop/madang remote -v`(origin URL 자체) · GitHub 레포 설정(Settings → General → Repository name) · 레포 내 하드코딩(팀장이 별도로 센 19곳, 이 문서 범위 밖) — 아이디가 바뀌면 이 문서보다 먼저 그쪽부터 바뀌어야 5번의 push URL이 유효하다.
