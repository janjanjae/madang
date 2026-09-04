# teamleader/scripts

팀장이 셸에서 부르는 도구. 전부 **읽기 전용** — 팀 파일에 쓰지 않는다.

## worker-activity.py — 워커 활동 신호

보고 파일 mtime만 보면 긴 슬라이스를 조용히 파는 워커가 유휴로 오판된다. 오버레이 `madang`이
쓰는 것과 같은 근거(파일 신호 + 세션 기록의 **실제 산출 턴**)로 인스턴스별 상태를 한 줄씩 낸다.

```bash
python3 claude/skills/teamleader/scripts/worker-activity.py --team-dir <프로젝트>/.claude/team
#   solver   state=working  work=04:28  err=-  brief=04:21  report=03:58  request=-  reply=-
# --json         같은 정보를 JSON 배열로 (감시 스크립트가 파싱하기 좋게)
# --instance X   그 인스턴스만 (반복 가능)   --verbose  진단을 stderr로
# --projects-dir 세션 기록 폴더 (기본: team-dir에서 유도)   --roster  roster.json 경로
```

`work` = 세션 기록의 마지막 실제 산출 턴, `err` = 그 뒤의 마지막 API 오류(529 등), 나머지는 파일 mtime.
`state` = `working`·`idle`·`waiting_confirm`·`blocked`·`discuss`·`replied`·`not_started`·`asleep`·`unknown`.

테스트: `python3 -m unittest claude/skills/teamleader/scripts/test_worker_activity.py -v`

### 판정의 SSOT는 `claude/tools/madang/madang.swift`

`discoverInstances` / `sessionTitle` / `lastRealTurn` / `lastSessionActivity` / `snapshot`을 1:1로 옮겼고
임계값(유휴 25분, 꼬리 128KB, 세션 12시간, 분신 브리프 24시간)도 Swift 상수 그대로다.
**오버레이 로직이 바뀌면 이 스크립트도 같이 고쳐야 한다** — 갈리는 순간 도구가 두 개가 된다.

브리프 문구와 달라진 3가지(전부 Swift SSOT를 따른 결과):

- **인스턴스 탐색은 `briefs/`만 훑는다** — `discoverInstances`가 그렇다. 기본 인스턴스는 브리프가 없어도 항상 나오고, 분신(`builder2`)만 24시간 내 브리프로 걸러진다. `reports/`·`confirm/`은 보지 않는다.
- **상태 이름이 6개가 아니라 9개다** — Swift `PetState`가 8가지라 6개로 접으면 `not_started`(미기동 = 유휴 아님)·`discuss`·`replied`가 사라진다. 전부 팀장이 행동해야 하는 상태라 접지 않았다.
- **`unknown`은 "세션 없음"이 아니라 "판정 실패"** — 세션이 안 잡히면 `work=-`일 뿐 상태는 파일 신호로 정상 판정된다(컨펌 대기 중인 워커를 `unknown`으로 덮으면 안 된다). `unknown`은 한 인스턴스의 판정이 예외로 실패했을 때만 나오고, 그 경우에도 나머지 인스턴스는 계속 출력된다.

세션 기록은 공백 없는 압축 JSON(`{"type":"assistant",…}`)이고 판정이 그 형태를 그대로 훑는다 —
테스트 픽스처도 반드시 `separators=(",", ":")`로 만들어야 한다.
