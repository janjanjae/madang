#!/usr/bin/env bash
# git filter-repo --replace-text 리허설/실행 후 검증.
# 사용: verify-history.sh <원본 저장소 경로> <재작성된 저장소 경로>
# 검사 3가지: ①패턴 잔존 0건 ②커밋 수 동일 ③브랜치·태그 이름 보존
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
echo "=== ② 커밋 수 비교 ==="
orig_count=$(git -C "$ORIG" rev-list --all --count)
new_count=$(git -C "$NEW" rev-list --all --count)
echo "  원본: ${orig_count} / 재작성: ${new_count}"
if [ "$orig_count" != "$new_count" ]; then
  echo "  FAIL 커밋 수 불일치"
  fail=1
else
  echo "  OK  커밋 수 동일"
fi

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
if [ "$fail" -eq 0 ]; then
  echo "=== 전체 통과 ==="
else
  echo "=== 실패 항목 있음 — 위 FAIL 참조 ==="
fi
exit "$fail"
