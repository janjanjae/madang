#!/usr/bin/env bash
# git filter-repo --replace-text/--mailmap 리허설/실행 후 검증.
# 사용: verify-history.sh <원본 저장소 경로> <재작성된 저장소 경로>
# 검사 4가지: ①패턴 잔존 0건(blob) ②커밋 수 동일 ③브랜치·태그 이름 보존 ④신원 필드(author/committer) 잔존 0건
# 🔴 2026-09-10: ①~③은 blob·메시지·ref만 본다 — author/committer 신원 필드(이름·이메일)는
# 구조적으로 아무도 안 봤다(--replace-text는 blob만 바꾸고, 신원은 --mailmap이라는 별도
# 메커니즘). replacements.txt의 literal 패턴(예: 실명 GitHub 계정명)을 신원 필드에도
# 그대로 적용해 이 구멍을 막는다 — 새 설정 파일을 만들지 않고 기존 표를 재사용한다.
set -euo pipefail

ORIG="${1:?사용법: verify-history.sh <원본 저장소> <재작성된 저장소>}"
NEW="${2:?사용법: verify-history.sh <원본 저장소> <재작성된 저장소>}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPL_FILE="${3:-$SCRIPT_DIR/replacements.txt}"

fail=0

echo "=== ① 패턴 잔존 검사 — diff 기준 (git log -p --all, AC 명시 방식) ==="
# replacements.txt의 치환 대상(==> 왼쪽)을 뽑아 grep -cE로 검사한다.
patterns=$(grep -v '^#' "$REPL_FILE" | grep -v '^\s*$' | sed -E 's/^(literal|regex):(.*)==>.*/\2/')
while IFS= read -r pat; do
  [ -z "$pat" ] && continue
  count=$(git -C "$NEW" log -p --all -- . 2>/dev/null | grep -cE -- "$pat" || true)
  if [ "$count" -eq 0 ]; then
    echo "  OK  0건 — $pat"
  else
    echo "  FAIL ${count}건 잔존 — $pat"
    fail=1
  fi
done <<< "$patterns"

echo ""
echo "=== ①-b 패턴 잔존 검사 — 전 커밋 스냅샷 기준 (더 엄격, diff에 안 잡히는 무변경 라인도 검사) ==="
commits=$(git -C "$NEW" rev-list --all)
while IFS= read -r pat; do
  [ -z "$pat" ] && continue
  hits=$( (git -C "$NEW" grep -IlE -- "$pat" $commits -- . 2>/dev/null || true) | wc -l | tr -d ' ')
  if [ "$hits" -eq 0 ]; then
    echo "  OK  0개 커밋 스냅샷에 잔존 — $pat"
  else
    echo "  FAIL ${hits}개 커밋 스냅샷에 잔존 — $pat"
    fail=1
  fi
done <<< "$patterns"

echo ""
echo "=== ② 커밋 보존 검사 — 제목 집합 비교 (단순 개수 비교 아님) ==="
# 🔴 2026-09-10: 단순 "개수가 같아야 한다"는 정상 경로에서도 FAIL을 띄운다 — filter-repo는
# 치환 후 빈 diff가 된 커밋을 기본적으로 쳐내므로(치환표에 "전파 커밋"이 있으면 그 커밋
# 자체가 빈 diff가 돼 사라진다), 개수 차이가 "정상 소거"와 "진짜 유실"을 구분 못 한다.
# 대신 제목 집합을 비교해 사라진 커밋을 찾고, 그 커밋의 **원본 diff가 치환표 패턴만
# 건드렸는지**(= 치환 후 빈 diff가 될 수밖에 없었는지)를 확인한다. 그런 커밋만 정상
# 소거로 인정 — 그 외 사라짐이나 새로 생긴 제목은 전부 FAIL. 정상 경로에서는 예외 없이
# "=== 전체 통과 ==="가 뜨는 것이 원칙(사람이 FAIL을 "괜찮은 FAIL"로 암기하게 만들지 않는다).
orig_titles=$(git -C "$ORIG" log --all --format='%s' | sort)
new_titles=$(git -C "$NEW" log --all --format='%s' | sort)
missing=$(comm -23 <(printf '%s\n' "$orig_titles") <(printf '%s\n' "$new_titles"))
gained=$(comm -13 <(printf '%s\n' "$orig_titles") <(printf '%s\n' "$new_titles"))

# 변경 라인 하나가 치환표(literal 또는 regex, 치환 전 문자열이든 치환 후 문자열이든)
# 아무 패턴에라도 걸리면 "설명됨"으로 친다. 🔴 "-"(제거) 라인은 치환 전 문자열(패턴
# 원문)과 매치되고 "+"(추가) 라인은 치환 후 문자열(==> 오른쪽)과 매치된다 — 둘 다 봐야
# "이 diff가 치환표만으로 설명되는가"를 제대로 검증한다(한쪽만 보면 +라인이 전부
# 미설명으로 뜬다 — 2026-09-10 1차 구현에서 실제로 이 버그가 났다).
line_explained_by_table() {
  local line="$1"
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    printf '%s' "$line" | grep -qF -- "$term" && return 0
  done <<< "$literal_from_for_c2"
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    printf '%s' "$line" | grep -qF -- "$term" && return 0
  done <<< "$literal_to_for_c2"
  while IFS= read -r pat; do
    [ -z "$pat" ] && continue
    printf '%s' "$line" | grep -qE -- "$pat" && return 0
  done <<< "$regex_from_for_c2"
  return 1
}
literal_from_for_c2=$(grep -v '^#' "$REPL_FILE" | grep -v '^\s*$' | grep '^literal:' | sed -E 's/^literal:(.*)==>.*/\1/')
literal_to_for_c2=$(grep -v '^#' "$REPL_FILE" | grep -v '^\s*$' | grep '^literal:' | sed -E 's/^literal:.*==>(.*)/\1/')
regex_from_for_c2=$(grep -v '^#' "$REPL_FILE" | grep -v '^\s*$' | grep '^regex:' | sed -E 's/^regex:(.*)==>.*/\1/')

c2_fail=0
if [ -n "$(printf '%s' "$gained" | tr -d '[:space:]')" ]; then
  echo "  FAIL 재작성본에만 있는 커밋 제목(있으면 안 됨):"
  printf '%s\n' "$gained" | grep -v '^\s*$' | sed 's/^/    + /'
  c2_fail=1
fi

if [ -z "$(printf '%s' "$missing" | tr -d '[:space:]')" ]; then
  echo "  OK  커밋 제목 차집합 없음 — 원본과 완전히 동일 ($(printf '%s\n' "$orig_titles" | grep -c .)개)"
else
  n_missing=$(printf '%s\n' "$missing" | grep -v '^\s*$' | grep -c .)
  echo "  사라진 커밋 제목 ${n_missing}건 — 각각 원본 diff가 치환표로 설명되는지 확인:"
  while IFS= read -r title; do
    [ -z "$title" ] && continue
    sha=$(git -C "$ORIG" log --all --format='%H %s' | grep -F -- " ${title}" | head -1 | cut -d' ' -f1)
    # 🔴 2026-09-10 실사고: 머지 커밋은 `git show <sha> -- .`가 기본 diff를 안 낸다
    # (combined diff 별도 포맷이라 이 grep 패턴에 아무것도 안 걸림) — changed가 비고,
    # 그걸 "변경 라인이 없다=전부 설명됨"으로 잘못 읽으면 머지 커밋 유실이 조용히 통과된다.
    # "diff를 못 읽음"과 "diff가 비어 있음"은 다르다 — 머지 커밋과, 못 읽은 나머지 전부는
    # fail-closed(설명 안 됨)로 보낸다. 부모가 여럿인지로 머지 여부를 먼저 가른다.
    parent_count=$(git -C "$ORIG" show -s --format='%P' "$sha" | wc -w | tr -d ' ')
    if [ "$parent_count" -gt 1 ]; then
      echo "    FAIL \"${title}\" (${sha:0:9}) — 머지 커밋이라 diff 판정 불가(fail-closed) → 사람 확인 필요"
      c2_fail=1
      continue
    fi
    changed=$(git -C "$ORIG" show "$sha" -- . 2>/dev/null | grep -E '^[+-][^+-]' || true)
    if [ -z "$(printf '%s' "$changed" | tr -d '[:space:]')" ]; then
      echo "    FAIL \"${title}\" (${sha:0:9}) — 원본 diff를 못 읽음(fail-closed) → 사람 확인 필요"
      c2_fail=1
      continue
    fi
    unexplained=0
    while IFS= read -r cline; do
      [ -z "$cline" ] && continue
      line_explained_by_table "$cline" || unexplained=1
    done <<< "$changed"
    if [ "$unexplained" -eq 0 ]; then
      echo "    OK   \"${title}\" (${sha:0:9}) — 변경 라인 전부 치환표로 설명됨 → 정상 소거"
    else
      echo "    FAIL \"${title}\" (${sha:0:9}) — 치환표로 설명 안 되는 변경 포함 → 진짜 유실 의심"
      c2_fail=1
    fi
  done <<< "$missing"
fi
[ "$c2_fail" -eq 1 ] && fail=1

echo ""
echo "=== ③ 브랜치·태그 보존 ==="
orig_branches=$(git -C "$ORIG" for-each-ref --format='%(refname:short)' refs/heads | sort)
new_branches=$(git -C "$NEW" for-each-ref --format='%(refname:short)' refs/heads | sort)
if [ "$orig_branches" = "$new_branches" ]; then
  echo "  OK  브랜치 이름 동일 ($(echo "$orig_branches" | wc -l | tr -d ' ')개)"
else
  echo "  FAIL 브랜치 목록 불일치"
  diff <(echo "$orig_branches") <(echo "$new_branches") || true
  fail=1
fi

orig_tags=$(git -C "$ORIG" tag | sort)
new_tags=$(git -C "$NEW" tag | sort)
if [ "$orig_tags" = "$new_tags" ]; then
  tag_n=$(echo "$orig_tags" | grep -c . || true)
  echo "  OK  태그 이름 동일 (${tag_n}개)"
else
  echo "  FAIL 태그 목록 불일치"
  diff <(echo "$orig_tags") <(echo "$new_tags") || true
  fail=1
fi

echo ""
echo "=== ④ 신원 필드(author/committer) 잔존 검사 ==="
# replacements.txt의 literal 패턴(실명 GitHub 계정명 등)을 author/committer 이름·이메일에도
# 적용한다. regex 패턴은 대상이 아니다(BMAD-(\d+) 류는 신원 필드에 나타날 일이 없다 —
# literal만으로 충분하고, regex를 신원 문자열에 잘못 매치시키는 오탐을 피한다).
identities=$(git -C "$NEW" log --all --format='%an <%ae>%n%cn <%ce>' | sort -u)
id_fail=0
literal_patterns=$(grep -v '^#' "$REPL_FILE" | grep -v '^\s*$' | grep '^literal:' | sed -E 's/^literal:(.*)==>.*/\1/')
while IFS= read -r term; do
  [ -z "$term" ] && continue
  hit=$(printf '%s\n' "$identities" | grep -F -- "$term" || true)
  if [ -n "$hit" ]; then
    echo "  FAIL 신원 필드에 잔존 — \"$term\""
    printf '%s\n' "$hit" | sed 's/^/    /'
    id_fail=1
    fail=1
  fi
done <<< "$literal_patterns"
if [ "$id_fail" -eq 0 ]; then
  echo "  OK  0건 — replacements.txt의 literal 패턴 전부 신원 필드에 없음"
  echo "  (현재 재작성 저장소의 고유 신원: $(printf '%s\n' "$identities" | wc -l | tr -d ' ')종)"
fi

echo ""
if [ "$fail" -eq 0 ]; then
  echo "=== 전체 통과 ==="
else
  echo "=== 실패 항목 있음 — 위 FAIL 참조 ==="
fi
exit "$fail"
