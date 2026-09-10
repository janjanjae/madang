#!/usr/bin/env bash
# 워킹 트리를 적대적으로 훑어 공개 전 회사·개인 식별 정보 "후보"를 찾는다.
# 읽기 전용 — 아무것도 고치지 않고, replacements.txt도 늘리지 않는다. 판정은 사람 몫.
#
# verify-history.sh(히스토리, replacements.txt의 14패턴이 "남았나")와 역할이 다르다.
# 이 스크립트는 "표가 완전한가" — 표에 없는 문자열이 더 있는지를 묻는다.
#
# 설계: 오탐이 나는 게 정상이다(놓치는 것보다 훨씬 싸다). 대신 사람이 읽을 만한 길이로
# 줄이기 위해 ①replacements.txt에 이미 있는 문자열 ②바이너리·락파일(의존성 해시 — 매번
# 수백 건씩 base64 패턴에 걸려 신호를 파묻는다, 내용 자체는 이미 공개 레지스트리 공개
# 정보라 무해) ③README/템플릿의 예시용 placeholder(`user@example.com`류)·이 스크립트
# 자신의 패턴 문자열은 미리 건너뛴다. 나머지는 전부 사람에게 보인다.
#
# 사용: verify-tree.sh              — 실 스캔
#       verify-tree.sh --self-test  — 6개 축이 실제로 발화하는지 레포 밖 임시 디렉토리로 자가진단
# 종료 코드: 0 = 후보/실패 없음, 1 = 후보 있음(사람 판정 필요) 또는 self-test 실패, 2 = 실행 오류
set -uo pipefail  # -e는 안 쓴다 — grep 매치 0건(exit 1)이 정상 흐름이다

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "git 저장소가 아니다" >&2; exit 2; }
cd "$ROOT" || exit 2

# 🔴 git grep -E(POSIX ERE)는 \b(단어 경계)를 지원하지 않는다 — 조용히 0건을 반환한다
# (2026-09-10 실측: PROJ-656이 실재하는데 -E + \b 패턴 전부 0건으로 나와 발견).
# -P(PCRE)가 있어야 아래 패턴들이 의미대로 동작한다. 없으면 "0건"이 거짓일 수 있어 fail-loud.
probe_file="$(mktemp "$ROOT/.verify-tree-probe.XXXXXX")"
printf 'probe123\n' > "$probe_file"
pcre_ok=1
git grep -q -P --no-index '\bprobe[0-9]+\b' -- "$probe_file" 2>/dev/null || pcre_ok=0
rm -f "$probe_file"
if [ "$pcre_ok" -eq 0 ]; then
  echo "🔴 이 git은 grep -P(PCRE)를 지원하지 않는다 — \\b 패턴이 조용히 0건을 반환해 결과를 신뢰할 수 없다. 중단." >&2
  exit 2
fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPL_FILE="$SCRIPT_DIR/replacements.txt"
SELF="$(basename "${BASH_SOURCE[0]}")"

# 🔴 2026-09-10: replacements.txt는 프로젝트 고유 데이터라 gitignore 대상이다(공개
# 저장소엔 없다). 없어도 스캔 자체는 돌아가지만 "이미 아는 패턴" 필터링이 전부 빠져
# 결과가 왜곡된다 — 조용히 degrade시키지 않고 설정이 안 됐다는 걸 바로 알린다.
if [ ! -f "$REPL_FILE" ]; then
  echo "🔴 $REPL_FILE 이 없다 — 이 프로젝트 고유 치환표는 공개 저장소에 없다(정상)." >&2
  echo "   $SCRIPT_DIR/replacements.example.txt 를 복사해 채운 뒤 다시 실행할 것." >&2
  exit 2
fi

# 바이너리·락파일 — 의존성 무결성 해시가 base64/hex 패턴을 대량으로 오탐시켜
# 사람이 읽을 수 없는 출력이 된다. 내용은 이미 공개 레지스트리 정보라 무해.
EXCLUDE_PATHS=(
  ':!*.lock' ':!package-lock.json' ':!pnpm-lock.yaml' ':!yarn.lock'
  ':!*.png' ':!*.jpg' ':!*.jpeg' ':!*.gif' ':!*.ico' ':!*.pdf' ':!*.woff*' ':!*.ttf'
  ':!claude/tools/sanitize/verify-tree.sh'
)

# replacements.txt에 이미 커버된 패턴은 재보고하지 않는다(표 확장은 사람 몫, 이 스크립트는
# "표 밖"만 찾는다). literal 행은 문자열 포함 매치, regex 행은 정규식 매치로 걸러야
# `BMAD-(\d+)`가 커버하는 `PROJ-656` 같은 실사례를 "이미 아는 것"으로 정확히 인식한다.
KNOWN_LITERALS=()
KNOWN_REGEXES=()
if [ -f "$REPL_FILE" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in
      regex:*) KNOWN_REGEXES+=("${line#regex:}") ;;
      literal:*) KNOWN_LITERALS+=("${line#literal:}") ;;
      *) KNOWN_LITERALS+=("$line") ;;
    esac
  done < <(grep -v '^\s*$' "$REPL_FILE" | sed -E 's/==>.*//')
fi
# PROJ-는 replacements.txt가 만들어내는 목표 형식 자체다(치환 결과) — 표 커버 여부와
# 무관하게 "이미 우리 표준"이라 후보에서 뺀다. git grep -E는 lookahead가 없어 이 방식으로 제외.
KNOWN_REGEXES+=('\bPROJ-[0-9]+\b')

found_any=0
total_hits=0

# 이미 알려진 예시 placeholder(문서 템플릿용) — "명백히 무해"라 사람 판정에서 뺀다.
HARMLESS_LITERALS=(
  'user@example.com' 'you@example.com' 'name@example.com'
  '{owner}/{repo}' '{company-gh-account}' '{test-user}' '{app-repo}' '{app-dir}' '{project}'
  'dev.example.com' 'example.com' 'yoursite.atlassian.net'
)

filter_known() {
  # stdin에서 이미 아는 것(replacements.txt 커버 + 명백한 무해 placeholder)을 걸러낸다.
  local out
  out=$(cat)
  for term in "${KNOWN_LITERALS[@]:-}"; do
    [ -z "$term" ] && continue
    out=$(printf '%s\n' "$out" | grep -vF -- "$term" || true)
  done
  for pat in "${KNOWN_REGEXES[@]:-}"; do
    [ -z "$pat" ] && continue
    out=$(printf '%s\n' "$out" | grep -vE -- "$pat" || true)
  done
  for term in "${HARMLESS_LITERALS[@]}"; do
    out=$(printf '%s\n' "$out" | grep -vF -- "$term" || true)
  done
  printf '%s' "$out"
}

# 6개 축 — report()와 --self-test가 **같은 배열을 공유**한다(실스캔·자가진단이 다른
# 패턴을 쓰면 자가진단 통과가 실제 탐지력을 보증하지 못한다).
AXIS_LABELS=(
  "① 사내 도메인·호스트 일반형 (*.co.kr · *.local · 사설 IP · intra/vpn/gitlab/jenkins류)"
  "② 티켓 키 일반형 [A-Z]{2,}-nnnn (PROJ- 제외 — 그건 이미 우리 표준)"
  "③ 이메일 주소 후보"
  "④ 사번·실명 후보 (느슨한 휴리스틱 — 오탐 많다, 사람 판정 필수)"
  "⑤ 회사 GitHub 계정·조직명·사내 패키지 레지스트리 패턴"
  "⑥ 토큰·키처럼 보이는 문자열 (github ghp_/gho_/ghu_/ghs_/ghr_, sk-, 긴 base64)"
)
# "팀장"·"프로"는 축④에서 뺐다 — 이 프로젝트 자체 용어(페르소나명·"프로세스/프로젝트"
# 등 일상어의 부분 문자열)라 110건·96건씩 순수 잡음으로 쏟아진다(2026-09-10 실측).
AXIS_PATTERNS=(
  '\.(co\.kr|local)\b|(^|[^0-9])10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)|(^|[^0-9])172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)|(^|[^0-9])192\.168\.[0-9]{1,3}\.[0-9]{1,3}([^0-9]|$)|\b(intra|vpn|gitlab|jenkins|nexus|artifactory|confluence)\b'
  '\b[A-Z]{2,10}-[0-9]+\b'
  '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'
  '\b[가-힣]{2,4}(\s|\()(강사|대표|이사|부장|매니저|책임|수석|과장|차장)|\bemp(loyee)?[_-]?id\b|\b사번\b'
  '_ktdev\b|-corp\b|\binternal\b.*registry|registry\.[a-zA-Z0-9.-]+\.(co\.kr|local|internal)|npm\.pkg\.github\.com/[a-zA-Z0-9_-]+-corp'
  'gh[pousr]_[A-Za-z0-9]{20,}|\bsk-[A-Za-z0-9]{20,}\b|\b[A-Za-z0-9+/]{60,}={0,2}\b'
)

report() {
  local label="$1" pattern="$2"
  echo "### $label"
  local hits
  hits=$(git grep -InP "$pattern" -- . "${EXCLUDE_PATHS[@]}" 2>/dev/null | filter_known)
  hits=$(printf '%s\n' "$hits" | grep -v '^\s*$' || true)
  if [ -z "$hits" ]; then
    echo "  없음"
  else
    found_any=1
    local n; n=$(printf '%s\n' "$hits" | grep -c . || true)
    total_hits=$((total_hits + n))
    echo "  ${n}건"
    printf '%s\n' "$hits" | head -20 | sed 's/^/  /'
    [ "$n" -gt 20 ] && echo "  … 외 $((n - 20))건 (표시 20건 제한)"
  fi
  echo ""
}

# --self-test: 고정문을 **레포 밖 임시 디렉토리**에서만 만들고 스캔하고 지운다.
# 🔴 이 고정문을 plans/ 등 추적 파일에 적어두면 그 자체가 스캐너의 영구 오탐 소스가
# 된다(2026-09-10 실사고 — 최초 버전은 plans/ 문서에 적어뒀다가 재실행마다 6축 전부에
# 잡혀 진짜 후보 11건이 자기소음 13건에 묻힐 뻔했다). 고정문은 여기, 이 스크립트
# 안에만 존재한다 — 이 파일 자체는 EXCLUDE_PATHS로 스캔에서 빠지므로 안전하다.
self_test() {
  local tmpdir; tmpdir="$(mktemp -d)"
  # 🔴 `git grep --no-index`는 이 환경에서 간헐적으로 "not a git repository"를 반환한다
  # (2026-09-10 실측 — 동일 명령이 재현 없이 성공/실패를 오갔다, 원인 미상). 대신 임시
  # 디렉토리를 **진짜 git repo로 초기화**하고 `--untracked`로 스캔 — 커밋 없이도 워킹
  # 트리 파일을 찾는다(3회 반복 재현으로 안정 확인, 2026-09-10). 시스템 `grep -P`는
  # 쓰지 않는다 — 이 스크립트를 사람이 직접 실행하는 셸엔 `-P`(PCRE) 없는 BSD grep이
  # 잡힐 수 있어(macOS 기본), 실 스캔과 다른 엔진으로 자가진단하면 신뢰할 수 없다.
  git init -q "$tmpdir"
  cat > "$tmpdir/fixture.md" <<'FIXTURE'
사내 vpn.internal-corp.co.kr 접속 후 SEC-4521 티켓 확인.
담당자 jdoe@internal-corp.com, 사번 EMP12345.
토큰 유출 테스트: ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
내부망 10.20.30.40, gitlab.internal-corp.local 참고.
FIXTURE

  echo "=== verify-tree.sh --self-test — 6개 축이 실제로 발화하는지 확인 ==="
  local axis_fail=0 i=1
  for pattern in "${AXIS_PATTERNS[@]}"; do
    if ( cd "$tmpdir" && git grep -q -P --untracked "$pattern" -- . ) 2>/dev/null; then
      echo "  OK   축 $i 발화 — ${AXIS_LABELS[$((i - 1))]}"
    else
      echo "  FAIL 축 $i 미발화 — 그물이 뚫렸다 (${AXIS_LABELS[$((i - 1))]})"
      axis_fail=1
    fi
    i=$((i + 1))
  done
  rm -rf "$tmpdir"

  echo ""
  if [ "$axis_fail" -eq 0 ]; then
    echo "self-test 통과 — 6개 축 전부 고정문을 검출했다."
    exit 0
  else
    echo "self-test 실패 — 위 FAIL 참조, 해당 축 정규식을 점검할 것."
    exit 1
  fi
}

if [ "${1:-}" = "--self-test" ]; then
  self_test
fi

echo "=== verify-tree.sh — 워킹 트리 회사/개인 식별 정보 후보 스캔 ($(date +%Y-%m-%d), $SELF 자체·바이너리·락파일 제외) ==="
echo ""

i=0
for pattern in "${AXIS_PATTERNS[@]}"; do
  report "${AXIS_LABELS[$i]}" "$pattern"
  i=$((i + 1))
done

echo "=== 요약 ==="
if [ "$found_any" -eq 0 ]; then
  echo "후보 없음 — 6개 축 전부 0건."
  exit 0
else
  echo "후보 ${total_hits}건 — 위 항목별로 '회사 정보다 / 무해하다 + 이유'를 사람이 판정할 것."
  echo "🔴 이 스크립트는 replacements.txt를 늘리지 않는다 — 표 확장은 팀장·사용자 결정."
  exit 1
fi
