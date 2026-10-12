# sanitize — 공개 전 회사·개인 식별 정보 점검 도구

공개 전환 절차 전체는 `docs/going-public.md`. 여기는 도구별 한 줄 요약이다.

| 도구 | 입력 | 하는 일 | 종료 코드 |
|---|---|---|---|
| `verify-tree.sh [--self-test]` | 현재 레포의 워킹 트리 | 치환표에 **없는** 회사·개인 식별 후보를 6축으로 찾는다. 읽기 전용 | 0 후보 없음 · 1 후보 있음(사람 판정) · 2 실행 불가(치환표 없음 등) |
| `verify-history.sh <원본> <재작성본>` | filter-repo 전후 저장소 | 재작성본에 **치환표 패턴·구 신원이 남았나**, 커밋·브랜치가 유실되지 않았나 | 0 전체 통과 · 그 외 FAIL |
| `check-draft.sh [--repo o/r] [--file f] [--self-test]` | 텍스트(stdin 또는 파일) | 이슈·PR 초안 등 텍스트의 일반형 축 + 로컬 경로·계정명 + 개인 치환표를 검사. PRIVATE 레포면 건너뜀 | 0 통과 · 1 걸림(줄·치환안 출력) · 2 검사 불가 |

**기억할 것**

- `verify-history.sh`는 "치환표가 설명하는가"만 본다. 표에 없는 문자열은 못 잡는다 — 공개 직전 독립 스캔이 따로 필요하다(`docs/going-public.md` 3절).
- 종료 코드 2는 "검사 못 함"이다. 통과로 읽지 않는다.
- 개인 파일(gitignore, 공개 레포에 없음): `replacements.txt` · `mailmap.txt`. 형식은 `replacements.example.txt` · `mailmap.example.txt`를 복사해 채운다. `check-draft.sh`와 `verify-tree.sh`는 `verify-tree.sh`의 축 정의를 공유한다(`check-draft.sh`가 런타임에 읽는다).
- 이 디렉토리의 스크립트는 고정문을 리터럴로 두지 않는다 — 자기 자신을 스캔에 걸리게 하기 때문이다. `--self-test`는 고정문을 조각으로 조립해 레포 밖 임시 디렉토리에서만 쓴다.
