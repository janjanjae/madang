# v0.5 공개일 런북 (2026-09-11)

> **위에서 아래로, 순서대로.** 각 단계는 명령·기대출력·🔴중단조건·되돌리기 4칸이다.
> 중단조건에 해당하면 다음 단계로 넘어가지 말고 팀장(도담)에게 그 화면을 그대로 보여줄 것.
> 상세 배경·전문(全文) 출력·판정표는 `plans/filter-repo-rehearsal-2026-09-10.md`를 참조 — 이 문서는 **그 요약 + 실행 순서**이며 절차가 겹치는 곳은 그쪽이 원본이다.
>
> 레포: `janjanjae/madang` · 로컬 경로: `~/Desktop/madang` (= `/Users/{user}/Desktop/madang`).
> GitHub 아이디는 `janjanjae` → `janjanjae`로 **확정**됐다(2026-09-10, 팀장이 `git remote`·`gh` 계정 전환 완료) — 이 문서는 전부 새 아이디로 갱신됨. 히스토리(93개 이상 커밋의 author/committer)는 아직 옛 아이디라 2번 단계에서 재작성한다.

---

## 0. 선행 조건 게이트

| | 내용 |
|---|---|
| **명령** | `cd ~/Desktop/madang && git checkout main && git status --short && git worktree list` (원격 `origin`은 이 시점에 로컬보다 뒤처져 있는 게 정상이다 — 이 런북 자체가 로컬을 origin으로 밀어넣는 절차라 `git pull`은 필요 없다) |
| **기대 출력** | `git status --short`가 **빈 출력**(clean). `git worktree list`에 `main`과 이 런북 브랜치(`docs/release-runbook`) 외에 **진행 중인 워커 워크트리가 없다**(`wt-sanitize`·`wt-state` 등이 남아있으면 안 됨 — 작업 끝났으면 팀장이 정리했어야 한다). |
| **🔴 중단 조건** | ① `git status`에 미커밋 변경이 있으면 중단(누가 손댄 건지 먼저 확인) ② `.claude/TASKS.md` "현재 배분" 표를 열어 **표의 모든 항목이 ✅ 완료 + `main` 머지 상태인지 확인** — 하나라도 아니면 시작 금지(브랜치 이름·개수는 이 문서에 박아두지 않는다 — 그날그날 바뀌니 TASKS.md가 SSOT) ③ `git worktree list`에 미정리 워크트리가 남아 있으면 그 작업이 안 끝났다는 뜻이니 중단 ④ **공개 ref 확인**: `git branch --no-merged main`을 돌려봐서 아직 main에 안 들어간 로컬 브랜치가 남아 있으면 안 된다(비어 있어야 정상 — ②가 통과하면 모든 작업 브랜치가 main의 조상이 된다. 공개 범위는 `main`만 확정됐으니 — 아래 5번 — 남은 브랜치는 애초에 안 민다. 단 로컬에 안 merge된 브랜치가 있으면 아직 main이 최신이 아니라는 뜻이라 여전히 막는다). |
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

## 2. filter-repo 실행 — 내용 + 메시지 + 신원, 한 번에 (미러 클론에서)

**신원 재작성 메커니즘**: `git filter-repo --help`(공식 문서) — `--mailmap <파일>`은 "author, committer, and tagger의 이름과 이메일을 재작성한다"고 명시돼 있다(🔑 **author와 committer 둘 다** 이 한 옵션으로 커버된다 — 별도 처리 불필요, `--name-callback`/`--email-callback`은 mailmap으로 안 되는 복잡한 규칙에 쓰는 상위 수단이라 이 단순 1:1 치환엔 과하다). 레포 밖 미러에서 실측 확인(origin 미접촉):
```
$ git filter-repo --mailmap <파일> --force   # 단독 실행
$ git log --all --format='%an <%ae> / %cn <%ce>' | sort -u
janjanjae <155637247+janjanjae@users.noreply.github.com> / janjanjae <155637247+janjanjae@users.noreply.github.com>
```
전 커밋(98개)의 author·committer가 한 번에 바뀜을 확인. `--replace-text`·`--replace-message`·`--mailmap` **세 플래그를 한 실행에 같이 넣어도** 정상 동작(따로 돌리면 중간 상태가 생긴다는 브리프 우려대로 — 한 번에 실행).

**명령**:
```bash
cat > ~/madang-mailmap.txt << 'EOF'
janjanjae <155637247+janjanjae@users.noreply.github.com> <{personal-email}>
janjanjae <155637247+janjanjae@users.noreply.github.com> <{personal-email}>
EOF

git clone --mirror ~/Desktop/madang ~/madang-backup.git && cp -R ~/madang-backup.git ~/madang-release.git
cd ~/madang-release.git && git filter-repo \
  --replace-text ~/Desktop/madang/claude/tools/sanitize/replacements.txt \
  --replace-message ~/Desktop/madang/claude/tools/sanitize/replacements.txt \
  --mailmap ~/madang-mailmap.txt \
  --force
```

| | 내용 |
|---|---|
| **기대 출력** | `New history written in N seconds; now repacking/cleaning...` → `Completely finished after N seconds.` 에러 메시지 없음. |
| **🔴 중단 조건** | ① `git filter-repo: command not found` → `brew install git-filter-repo` 먼저 ② **`--replace-text`·`--replace-message`·`--mailmap` 세 개 다 넣었는지 반드시 재확인** — 번뜩이 찾은 함정: `--replace-text`는 파일(blob) 내용만, 커밋 메시지는 `--replace-message`, **신원(author/committer)은 `--mailmap`** — 셋은 서로 다른 메커니즘이라 하나만 빠져도 에러 없이 "성공"하고 나머지만 조용히 안 바뀐다 ③ 치환표·메일맵 파일 경로에 오타가 있으면 filter-repo가 **아무 규칙도 못 찾고도 에러 없이 끝난다** — 아래 3번 검증(①②③④)이 이걸 잡아야 한다. |
| **되돌리기** | 이 단계는 **`~/madang-release.git`(작업용 미러) 안에서만** 재작성이 일어난다 — **실 레포 `~/Desktop/madang`과 `origin`은 아직 전혀 안 건드렸다.** 잘못됐으면 `rm -rf ~/madang-release.git`하고 `cp -R ~/madang-backup.git ~/madang-release.git`으로 다시 시작(1번으로 안 돌아가도 됨, 표는 이미 확정됨). `~/madang-backup.git`은 **절대 filter-repo에 넣지 않는다** — 이게 유일한 순수 원본이다. |

---

## 3. `verify-history.sh` 재검증 (①②③④)

`verify-history.sh`는 이제 **4가지**를 본다: ①패턴 잔존(diff 기준) ①-b패턴 잔존(전 커밋 스냅샷 기준) ②커밋 보존(제목 집합 비교 — 아래) ③브랜치·태그 보존 **④신원 필드(author/committer) 잔존** — ④는 오늘 새로 추가됐다.

| | 내용 |
|---|---|
| **명령** | `~/Desktop/madang/claude/tools/sanitize/verify-history.sh ~/madang-backup.git ~/madang-release.git` |
| **기대 출력** | **정상 경로에서는 예외 없이 마지막 줄이 `=== 전체 통과 ===`다.** "이건 괜찮은 FAIL"류의 암기가 필요한 출력은 없다. |
| **🔴 중단 조건** | **하나라도 `FAIL`이면 다음 단계(push)로 넘어가지 않는다 — 예외 없음.** `①-b`(커밋 메시지 포함 엄격 검사)에서 남으면 2번의 `--replace-message` 누락 의심. **`④`에서 남으면 `--mailmap` 누락·메일맵 이메일 오타 의심**(author/committer는 blob과 별개 메커니즘). `②`에서 FAIL이 뜨면 — 아래 "왜 커밋 수가 아니라 제목 집합인가" 참조 — **치환표로 설명 안 되는 커밋이 사라졌다는 뜻이라 진짜 유실 의심, 강행 금지.** |
| **되돌리기** | 실패해도 `~/Desktop/madang`·`origin`은 아직 안전하다. `~/madang-release.git`을 지우고 2번부터 다시. |

**왜 커밋 수가 아니라 제목 집합인가 (2026-09-10 발견·수정)**: 팀장이 오늘 오전 `janjanjae`→`janjanjae`를 트리에 수동 전파한 커밋이 2개 있다(`chore: GitHub 아이디 전파`·`docs(plans): 허브 문서 아이디 전파`, 둘 다 오직 그 문자열 치환만 하는 커밋). `replacements.txt`에 같은 규칙이 있어 filter-repo가 그 두 커밋의 부모 블롭에도 이미 같은 치환을 적용해버리면 그 커밋들의 diff가 **빈 diff**가 돼 filter-repo가 자동으로 쳐낸다(히스토리 유실이 아니라 불필요해진 중간 단계 소거) — 원본 98개가 재작성 후 96개가 된다.

1차 구현은 "개수가 같아야 정상"으로 짜서 이 **정상 상황에서도 `FAIL`이 떴다** — 그리고 정상인데 FAIL이 뜨는 검사는 사람이 "저건 괜찮은 FAIL"로 암기하게 만들고, 그러다 **진짜 유실(98→95 같은)이 나도 화면이 똑같아 보여 놓치게 된다.** `verify-tree.sh`에서 자기 문서 오염(24 vs 11)을 걷어낸 것과 같은 종류의 함정이라 같은 원칙으로 고쳤다: **숫자 대신 "사라진 커밋 제목이 무엇인가"를 보고, 그 커밋의 원본 diff가 치환표(치환 전/후 문자열 둘 다)로 전부 설명되는지 확인**한다. 설명되면(=치환 후 빈 diff가 될 수밖에 없었던 게 증명되면) 자동 통과, 설명 안 되는 변경이 하나라도 있으면 FAIL. 재현 검증: 정상 경로(위 2개만 소거)는 `=== 전체 통과 ===`, 무관한 커밋을 미러에서 실제로 하나 드롭시킨 경로는 정확히 그 커밋에 `FAIL`을 띄우는 것 둘 다 확인했다.

---

## 4. gh 계정 확인

| | 내용 |
|---|---|
| **명령** | `gh auth status --active` |
| **기대 출력** | `janjanjae` 계정이 active(GitHub 아이디 자체가 `janjanjae`에서 바뀌었으므로 gh가 기억하는 계정명도 `janjanjae`다). |
| **🔴 중단 조건** | ① active 계정이 `{company-gh-account}`(회사 계정)면 **`gh auth switch -u janjanjae`** 먼저(사용자가 직접 — 에이전트가 대신 하지 않는다) ② `gh api user`가 403/네트워크 오류를 내면 **사내망(ZTNA)이 켜져 있는 것** — 오늘 두 번 정확히 이 이유로 개인 계정 접근이 막혔다(실측, 오전 1회·오후 1회 재발). **사내망을 끄고 재확인.** ③ 둘 다 정상인데도 이후 단계에서 API 오류가 나면 네트워크부터 의심. |
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

**filter-repo(2번)를 거치면 어떻게 바뀌는지도 확인**: 같은 미러를 복사해 filter-repo를 돌려보니 `refs/remotes/origin/*` 2개가 **자동으로 사라졌다**(filter-repo가 기본 동작으로 `origin` 리모트 자체를 제거하면서 그 추적 ref도 함께 없어짐 — 공식 동작, "Removing 'origin' remote" 안내가 뜬다). `refs/tmp-mainref`는 **살아남는다**(다른 ref와 똑같이 새 해시로 재작성됨). `refs/replace/*`는 생기지 않았다. 즉 **2번(filter-repo)을 거치고 나면 원격추적 ref 2개는 이미 사라져 있다.**

### `tmp-mainref` — ✅ 판정 완료, 팀장이 삭제 완료

`tmp-mainref`는 **main의 바로 이전 위치(d570b8d, verify-tree.sh 병합 직전의 main)를 정확히 가리켰다** — `git merge-base --is-ancestor tmp-mainref main`으로 main의 조상임을 확인, 별도 작업 내용 없음. `.git/refs/` 최상위 loose ref라 reflog가 없어 "누가 왜 만들었나"는 증명 못 했지만(정황상 병합 직전 체크포인트로 추정), **삭제해도 히스토리 유실 없음**으로 판정했다. **2026-09-10 팀장이 삭제 완료**(`git rev-parse tmp-mainref` → "unknown revision" 확인) — 아래 명령·0번 게이트에서 이 항목은 뺐다.

### 공개 ref 정책 — `main`만 (A안, 사용자 확정)

**결정**: `main`만 공개한다. 0번 게이트가 "모든 작업 브랜치는 main에 머지 완료"를 전제로 하므로 실행 시점엔 작업 브랜치 전부가 main의 조상이라(즉 공개해도 커밋 내용상 새로 드러나는 게 없고 브랜치 이름표만 더 보임), 이름표 노출의 이득보다 매 릴리스 브랜치 정리 부담이 크다고 판단 — 사용자가 이 추천을 그대로 채택했다. `refs/tmp-mainref`는 이미 삭제됐고, `--mirror`를 쓰지 않으므로 `refs/remotes/*`도 애초에 안 건드린다.

### 명령

```bash
cd ~/madang-release.git
git push --force https://github.com/janjanjae/madang.git refs/heads/main:refs/heads/main
```

| | 내용 |
|---|---|
| **기대 출력** | `main` 한 줄의 `+ ... forced-update`, 에러 없이 종료. `refs/remotes/`나 `tmp-mainref` 언급이 **없어야** 정상(있으면 명령이 잘못 실행된 것 — `--mirror`가 섞였는지 확인). |
| **🔴 중단 조건** | **실행 전, 3번의 "전체 통과"를 다시 확인 — 되돌릴 수 없다.** 인증 오류면 gh 계정 재확인(4번). 그 외 실패는 **재시도하지 말고 멈춘다** — 부분 push 상태에서 재시도하면 더 꼬인다. |
| **되돌리기** | **원칙적으로 되돌릴 수 없다.** GitHub 캐시·포크·클론이 이미 잘못된 히스토리를 가져갔을 수 있다. 그나마 되돌리는 방법: `cd ~/madang-backup.git && git push --force --mirror https://github.com/janjanjae/madang.git`(여기서는 원본 복원이 목적이라 `--mirror`가 맞다) — 이건 **원격을 재작성 이전 상태로 강제로 되돌리는 것**이지, "실행 안 한 것"으로 만들지 못한다(그 사이 누가 클론했으면 그 사본엔 여전히 잘못된 히스토리가 남는다). `~/madang-backup.git`은 이 작업이 끝나고 **최소 1주** 지울 것 없이 보관한다. |

### ⚠️ 잔디(기여 그래프) 확인 — push 직후, public 전환 전에

author 이메일을 `155637247+janjanjae@users.noreply.github.com`(GitHub이 발급한 janjanjae 계정 소유 noreply 주소)로 바꿨다 — GitHub 기여 그래프는 **이메일 기준**으로 커밋을 계정에 연결한다. 계정 소유 주소라 정상 연결되는 게 맞지만, **이 세션에서 실측하지 못했다**(`gh api user/emails`가 토큰 스코프 부족으로 404 — janjanjae 계정으로 직접 GitHub 웹에서 확인 필요, `gh auth` 스코프 문제라 이 브랜치에서 못 고침).

| | 내용 |
|---|---|
| **명령** | `open https://github.com/janjanjae/madang/commit/$(git -C ~/madang-release.git rev-parse main)` (또는 그냥 GitHub에서 최신 커밋 아무거나 하나 클릭) |
| **기대 출력** | 커밋 옆에 **janjanjae 아바타가 뜬다**(회색 기본 아이콘이 아니라 실제 프로필 사진/계정 링크) — 이메일-계정 연결이 살아있다는 뜻. |
| **🔴 중단 조건** | 아바타 없이 이메일 텍스트만 뜨거나 "unknown user"면 **이메일-계정 연결이 안 된 것** — GitHub 계정 설정(Settings → Emails)에서 그 noreply 주소가 실제로 등록·인증됐는지 먼저 확인. 안 살아있는 채로 6번(public 전환)까지 가면 공개 후에야 알게 된다. |
| **되돌리기** | 확인만 하는 단계, 부작용 없음. 문제가 있으면 5번 되돌리기(백업 복원)로 돌아갈지 판단. |

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
| **기대 출력** | `gh repo view janjanjae/madang --json visibility`가 `PUBLIC`. 토픽·설명이 반영됨. 이슈 개수 **24건**(스모크 #25는 삭제 완료 — 아래). |
| **🔴 중단 조건** | `--accept-visibility-change-consequences` 없이 실행하면 gh가 확인 프롬프트에서 멈춘다(터미널 인터랙티브 필요) — 자동화 스크립트로 돌릴 거면 이 플래그 필수. description·topic 값은 **여기 적힌 예시가 아니라 사용자가 그 자리에서 정한다.** |
| **되돌리기** | `gh repo edit janjanjae/madang --visibility private`로 다시 비공개 전환 가능(레포 자체는 되돌아가지만, 5번에서 이미 공개된 히스토리는 여전히 누군가의 클론에 남아 있을 수 있다 — 완전한 원복은 아니다). |

**스모크 이슈 #25**: ✅ **삭제 완료**(2026-09-10, 팀장). 확인할 것 없음 — 이슈 개수는 24건이 맞다.

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

## 오늘 잡은 함정 6건 — 이 런북에 반영된 위치

| 함정 | 어디서 걸림 | 중단 조건 반영 |
|---|---|---|
| `regex::`/`literal::`(콜론 두 개)는 오문법 — 콜론 한 개가 맞다. 조용한 전체 치환 실패(카운트가 원본과 완전 동일)로만 드러난다. | `replacements.txt` 작성 시 | **1번**에서 표를 고칠 때, **3번**에서 반드시 잡힌다(패턴 잔존 카운트가 0이 안 되면 전체 실패를 의심). |
| `--replace-text`는 blob만, 커밋 메시지는 `--replace-message` 별도 필요. | filter-repo 실행 시 | **2번**의 명령에 두 플래그 모두 명시 + 중단조건에 명문화. **3번**의 `①-b`(전 커밋 스냅샷 기준)가 이 누락을 실제로 잡는다. |
| `--mirror`가 `refs/heads`·`refs/remotes`·이름 모를 커스텀 ref까지 전부 민다 — "기본값이라 그냥 그렇게 되는 것"이 사람이 결정한 적 없는 걸 공개할 뻔했다. | force-push 시 | **5번**을 `--mirror` 없는 명시적 `refs/heads/main:refs/heads/main`으로 재작성. `tmp-mainref`는 판정 후 삭제 완료. |
| author/committer 신원은 `--replace-text`·`--replace-message`와 **별개 메커니즘**(`--mailmap`)이라, 다른 둘을 다 맞춰도 신원만 조용히 안 바뀔 수 있다. 사람이 우연히 커밋 목록을 세다 발견했다. | filter-repo 실행 시 | **2번**에 `--mailmap` 추가 + 세 플래그 한 실행으로 통합. **3번**에 ④ 신원 검사 신설(replacements.txt의 literal 패턴을 author/committer 필드에도 적용) — 다음부터는 우연이 아니라 장치가 잡는다. |
| **정상 경로에서도 `FAIL`이 뜨는 검사는 그 자체가 함정이다** — "커밋 수가 같아야 정상"은 치환표에 rename 규칙이 있으면 빈 커밋이 자동 쳐내져 정상인데도 FAIL을 띄운다. 사람이 "이 FAIL은 괜찮다"를 암기하게 되고, 그러다 진짜 유실도 같은 화면으로 지나간다. | `verify-history.sh` ② 설계 시 | 숫자 비교를 **제목 집합 비교 + 사라진 커밋의 원본 diff가 치환표로 설명되는지 검증**으로 교체 — 정상 경로는 예외 없이 `=== 전체 통과 ===`, 무관한 진짜 유실만 FAIL(양쪽 다 재현 확인). |
| **그 거울상** — `git show <sha> -- .`는 머지 커밋에 기본 diff를 안 낸다(combined diff 별도 포맷). "변경 라인 없음"을 "전부 설명됨"으로 읽으면 **머지 커밋(이 레포 11개, 리뷰 요약이 본문에 든 커밋들)이 사라져도 조용히 통과**한다 — 팀장이 발견. | `verify-history.sh` ② 구현 시 | 부모 2개 이상(머지)이거나 diff를 아예 못 읽으면 **fail-closed**(설명 안 됨으로 처리) — "확인 못 함"과 "변경 없음"을 같은 칸에 넣지 않는다. 일반 커밋 유실·머지 커밋 유실 둘 다 실제로 드롭시켜 FAIL 재현 확인. |

## 자기 검증 메모 (처음 보는 사람인 척 다시 읽은 결과)

- 0번 게이트의 "스킬 리네임 2부 브랜치명 미정"은 실행 시점에 TASKS.md를 다시 봐야 한다는 뜻을 명확히 했다 — 이 문서만으로 판단하려 하면 막힐 자리라 표시해 둠.
- 6번의 description·topic 값은 의도적으로 플레이스홀더로 남겼다(그 자리는 사용자 취향 판단이라 미리 정하면 오히려 틀린다).
- 5번(force-push)과 2번(filter-repo) 둘 다 "되돌릴 수 없다"고 쓰면 어느 쪽이 진짜 마지노선인지 흐려질 위험이 있어, 2번은 "이 미러 안에서만 되돌릴 수 없다(실 레포는 안전)"로, 5번은 "진짜 되돌릴 수 없음"으로 강도를 구분해 표시했다.
- 5번에 A/B 두 명령을 나란히 두면 실행 직전에 **어느 쪽을 실행하는지 헷갈릴 수 있어** 중단조건에 "실행 직전 소리 내어 확인" 한 줄을 넣어뒀다 — 되돌릴 수 없는 단계에서 헷갈림은 그 자체로 사고 원인이다. (이번 사이클에서 A안으로 확정되며 B는 삭제 — 이 항목은 이제 과거형이지만 "왜 그렇게 썼는지"는 남겨둔다.)
- **잔디 확인을 별도 6번으로 안 만들고 5번의 하위 절로 넣었다** — 단계를 새로 끼우면 6·7번이 7·8번으로 밀려 문서 전체의 상호 참조("6번 되돌아가라" 류)를 다 다시 세야 한다. "push 직후·public 전환 직전"이라는 인과적 위치는 5번 하위에 둬도 그대로 살고, 되돌릴 수 없는 단계 번호 체계(0~7)도 안 흔들린다 — 실익보다 renumbering 리스크가 커서 이렇게 판단했다.
- `② 커밋 수 비교`를 처음엔 "정확히 2 적어야 정상"으로 문서화했는데, 이것도 결국 사람이 숫자를 암기해야 하는 방식이라 컨펌에서 되돌아왔다 — **"정상 경로는 항상 `=== 전체 통과 ===`"** 원칙으로 검사 자체(제목 집합 비교)를 고치고 나서야 진짜로 해소됐다. 문서만 고치고 검사는 그대로 둔 채 "이 FAIL은 괜찮다"고 적는 건 예외 처리를 기계가 아니라 사람 기억에 얹는 것이었다.

---

## GitHub 아이디 변경 — ✅ 완료 (2026-09-10)

`janjanjae` → `janjanjae` 확정. `git remote`·`gh` 계정 전환은 팀장이 완료, 이 문서의 URL·계정명은 전부 `janjanjae`로 갱신됐다(위 각 단계 참조). 남은 건 **히스토리 재작성**(93개 이상 커밋의 author/committer + `replacements.txt`의 문자열 치환) — 2번 단계가 그 일이고, ④ 신원 검사(3번)가 그 결과를 확인한다. 워킹 트리 쪽(`README.md`·`.claude-plugin/marketplace.json`·`claude/.claude-plugin/plugin.json` 등)에 남은 `janjanjae` 문자열은 이 브랜치 밖(몽글) 소관.
