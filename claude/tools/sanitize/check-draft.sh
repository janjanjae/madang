#!/usr/bin/env bash
# 공개 레포에 올릴 이슈 초안(텍스트)에 개인·회사 맥락이 섞였는지 생성 전에 검사한다.
# /issue-add 의 github 경로가 호출한다 — 다른 프로젝트에서 돌므로 madang 레포 위치는
# `~/.claude/madang-repo` 힌트(install.sh가 씀)로 찾는다. 읽기 전용: 초안을 고치지 않는다.
#
# 사용: check-draft.sh [--repo owner/repo] [--file 초안.md]     (--file 없으면 stdin)
#       check-draft.sh --self-test
# 종료 코드: 0 = 걸린 것 없음(또는 PRIVATE이라 건너뜀) / 1 = 걸린 줄 있음 / 2 = 검사 불가
#   🔴 검사 불가(2)를 "통과"로 읽지 마라 — 호출 쪽은 반드시 사용자 확인으로 넘긴다.
#
# 재사용: 일반형 6축·무해 placeholder 목록은 같은 디렉토리의 verify-tree.sh 배열을 읽어 쓴다
#   (패턴을 복제하면 어긋난다). 이 스크립트가 더하는 것: ⑦로컬 절대경로 ⑧로컬 신원 문자열
#   ⓪개인 치환표(replacements.txt — gitignore된 개인 파일, 없으면 일반형 축만으로 동작).
# 환경: GH_BIN(gh 대체) CHECK_DRAFT_REPL(치환표 경로) CHECK_DRAFT_IDENTITIES(공백 구분 신원 문자열)
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VT="$HERE/verify-tree.sh"
REPL="${CHECK_DRAFT_REPL:-$HERE/replacements.txt}"
GH_BIN="${GH_BIN:-gh}"

cant() { echo "🔴 검사 불가: $*" >&2; echo "   → 이 초안은 검사되지 않았다. 사용자에게 '검사 못 함'을 알리고 직접 확인을 받아라(조용히 통과 금지)." >&2; exit 2; }

# ── 규칙표 만들기: id \t 라벨 \t 치환 placeholder \t 정규식 ───────────────────────
build_rules() { # → $1 파일에 기록
  local out="$1"; : > "$out"
  [ -f "$VT" ] || cant "verify-tree.sh 를 못 찾았다($VT) — 일반형 축 정의가 없다"
  local pats labels
  pats="$(awk '/^AXIS_PATTERNS=\(/{f=1;next} /^\)/{f=0} f' "$VT" | sed -E "s/^[[:space:]]+'//; s/'[[:space:]]*\$//")"
  labels="$(awk '/^AXIS_LABELS=\(/{f=1;next} /^\)/{f=0} f' "$VT" | sed -E 's/^[[:space:]]+"//; s/"[[:space:]]*$//')"
  local np nl; np="$(printf '%s\n' "$pats" | grep -c .)"; nl="$(printf '%s\n' "$labels" | grep -c .)"
  { [ "$np" -eq 6 ] && [ "$nl" -eq 6 ]; } || cant "verify-tree.sh 의 축 배열 형식이 바뀌었다(패턴 $np·라벨 $nl, 기대 6) — 파서 점검 필요"
  local ph=('<내부-호스트>' '<티켓키>' '<이메일>' '<실명·ID>' '<조직-계정>' '<토큰>') i=0
  while IFS= read -r p; do
    local l; l="$(printf '%s\n' "$labels" | sed -n "$((i + 1))p")"
    printf '%s\t%s\t%s\t%s\n' "$((i + 1))" "$l" "${ph[$i]}" "$p" >> "$out"
    i=$((i + 1))
  done <<<"$pats"
  # ⑦ 로컬 절대경로 — 흔한 placeholder 사용자명은 perl 쪽 allow 로 거른다
  printf '7\t⑦ 로컬 절대경로 (/Users/… · /home/… · C:\\Users\\…)\t<로컬경로>\t%s\n' \
    '(?:/(?:Users|home)/[A-Za-z0-9._-]+|[A-Za-z]:\\Users\\[A-Za-z0-9._-]+)' >> "$out"
  # ⑧ 로컬 신원 문자열 — OS 사용자명·git 사용자명/이메일 로컬파트·호스트명(4자 미만은 오탐이 커서 제외)
  local ids="${CHECK_DRAFT_IDENTITIES-}"
  if [ -z "${CHECK_DRAFT_IDENTITIES+x}" ]; then
    ids="${USER:-} $(git config user.name 2>/dev/null | tr ' ' '_') $(git config user.email 2>/dev/null | sed 's/@.*//') $(hostname -s 2>/dev/null)"
  fi
  local id
  for id in $ids; do
    [ "${#id}" -ge 4 ] || continue
    printf '8\t⑧ 로컬 신원 문자열 (OS 사용자명·git 이름·호스트명)\t<로컬계정>\tWLIT::%s\n' "$id" >> "$out"
  done
  # ⓪ 개인 치환표 — verify-tree 와 반대로 여기서는 "있으면 곧 유출"이다
  if [ -f "$REPL" ]; then
    local line
    while IFS= read -r line; do
      line="${line%%==>*}"; [ -z "${line// }" ] && continue
      case "$line" in
        regex:*) printf '0\t⓪ 개인 치환표 일치(regex)\t<치환표-항목>\t%s\n' "${line#regex:}" >> "$out" ;;
        literal:*) printf '0\t⓪ 개인 치환표 일치\t<치환표-항목>\tLIT::%s\n' "${line#literal:}" >> "$out" ;;
        *) printf '0\t⓪ 개인 치환표 일치\t<치환표-항목>\tLIT::%s\n' "$line" >> "$out" ;;
      esac
    done < <(grep -v '^[[:space:]]*#' "$REPL")
    echo "ℹ️  개인 치환표 사용: $REPL" >&2
  else
    echo "ℹ️  개인 치환표 없음 — 일반형 축(①~⑧)만으로 검사한다" >&2
  fi
}

harmless_list() { # verify-tree 의 무해 placeholder — 못 읽어도 에러가 아니다(걸리는 쪽이 늘 뿐, 안전한 방향)
  awk '/^HARMLESS_LITERALS=\(/{f=1;next} /^\)/{f=0} f' "$VT" 2>/dev/null | grep -oE "'[^']+'" | tr -d "'"
}

# ── 본 검사 (perl: verify-tree 패턴이 PCRE 라 BSD grep 은 못 읽는다) ─────────────
scan() { # $1=규칙파일 $2=초안파일 $3=무해목록파일 → 걸린 줄 출력, 있으면 exit 1
  perl -CSD -Mutf8 -e '
    use strict; use warnings; use Encode qw(decode);
    my ($rf, $df, $hf) = @ARGV;
    open(my $h, "<:utf8", $hf) or exit 2; my @harm = grep { length } map { chomp; $_ } <$h>; close $h;
    my @rules;
    open(my $r, "<:utf8", $rf) or exit 2;
    while (<$r>) {
      chomp; my ($id, $label, $ph, $re) = split /\t/, $_, 4; next unless defined $re;
      # LIT:: = 리터럴(quotemeta), WLIT:: = 단어 경계 리터럴 — bash 에서 이스케이프하면 다국어 바이트가 깨진다
      if    ($re =~ s/^WLIT:://) { $re = "(?<![A-Za-z0-9])" . quotemeta($re) . "(?![A-Za-z0-9])" }
      elsif ($re =~ s/^LIT:://)  { $re = quotemeta($re) }
      my $qr = eval { qr/$re/ };
      if ($@) { print STDERR "규칙 $id 정규식 오류: $@"; exit 2 }
      push @rules, { id => $id, label => $label, ph => $ph, qr => $qr };
    }
    close $r;
    my %allow = (
      2 => qr/^(?:PROJ|UTF|SHA|ISO|MD|AES|RSA|HTTP|TLS|SSL|TCP|UDP|IPV|RFC|CVE|CWE|PEP|ES|GPT|X|COVID)-/,
      7 => qr{^(?:/(?:Users|home)/(?:you|user|username|name|me|foo|example|your-?name)|[A-Za-z]:\\Users\\(?:you|user|username|name))$}i,
    );
    my $hits = 0;
    open(my $d, "<:utf8", $df) or exit 2;
    my $n = 0;
    while (my $line = <$d>) {
      $n++; chomp $line; my $sug = $line; my %seen;
      for my $ru (@rules) {
        my $hit = 0;
        $sug =~ s{$ru->{qr}}{
          my $m = $&; my $keep = 0;
          for my $hl (@harm) { if (index($m, $hl) >= 0) { $keep = 1; last } }
          $keep = 1 if !$keep && $allow{$ru->{id}} && $m =~ $allow{$ru->{id}};
          if ($keep) { $m } else { $hit = 1; $ru->{ph} }
        }ge;
        $seen{$ru->{label}} = 1 if $hit;
      }
      next unless %seen;
      $hits++;
      my $show = length($line) > 160 ? substr($line, 0, 160) . "…" : $line;
      my $ssug = length($sug) > 160 ? substr($sug, 0, 160) . "…" : $sug;
      my @short = map { (my $x = $_) =~ s/ \(.*//; $x } sort keys %seen;
      print "  L$n [" . join(" / ", @short) . "]\n     원문: $show\n     치환안: $ssug\n";
    }
    exit($hits ? 1 : 0);
  ' "$1" "$2" "$3"
}

run_check() { # $1=초안파일 $2=repo(선택)
  local draft="$1" repo="${2:-}" vis="PUBLIC"
  if [ -n "$repo" ]; then
    local v
    if v="$("$GH_BIN" repo view "$repo" --json visibility -q .visibility 2>/dev/null)" && [ -n "$v" ]; then vis="$v"
    else echo "⚠️  공개 여부를 못 읽었다($repo) — PUBLIC으로 간주하고 검사한다(안전 쪽)" >&2; fi
    if [ "$vis" = PRIVATE ]; then echo "PRIVATE 레포($repo) — 검사를 건너뛴다."; return 0; fi
  else
    echo "⚠️  --repo 없음 — PUBLIC으로 간주하고 검사한다(안전 쪽)" >&2
  fi
  command -v perl >/dev/null 2>&1 || cant "perl 이 없다 — PCRE 패턴을 평가할 수 없다"
  local tmp; tmp="$(mktemp -d "${TMPDIR:-/tmp}/check-draft.XXXXXX")" || cant "임시 디렉토리 생성 실패"
  build_rules "$tmp/rules.tsv" || { local rc=$?; rm -rf "$tmp"; exit "$rc"; }
  harmless_list > "$tmp/harm.txt"
  local out rc
  out="$(scan "$tmp/rules.tsv" "$draft" "$tmp/harm.txt")"; rc=$?
  rm -rf "$tmp"
  case "$rc" in
    0) echo "✅ 걸린 것 없음 (공개 여부: $vis)"; return 0 ;;
    1) echo "🔴 공개 레포($vis)에 올리기 전에 걸린 줄 — 치환하거나 사용자 확인을 받아라:"; echo "$out"; return 1 ;;
    *) cant "검사 엔진 오류(exit $rc)" ;;
  esac
}

# ── self-test: 고정문은 조각으로 조립한다(이 파일이 verify-tree 스캔에 걸리지 않도록) ──
self_test() {
  local t; t="$(mktemp -d "${TMPDIR:-/tmp}/check-draft-test.XXXXXX")"
  local fails=0
  ok() { echo "  OK   $1"; }
  ng() { echo "  FAIL $1"; fails=$((fails + 1)); }
  local dom="v""pn.internal" corp="-co" rp="rp" tld=".co"
  local f_domain="접속은 ${dom}${corp}${rp}${tld}.kr 로"
  local f_ticket="티켓 SEC-$((4000 + 521)) 참고"
  local f_mail="담당 jdoe@internal${corp}${rp}.com"
  local f_emp="담당 김철수 ""부장님, 사""번 확인"
  local f_org="레포 acme${corp}${rp} 조직"
  local f_tok="토큰 gh""p_$(printf 'A%.0s' $(seq 1 30))"
  local f_path="로그 /Users/""realname/work/app.log"
  local f_id="사용자 zzidentity""x 가 실행"
  local f_repl="내부 코드명 ZZcode""nameQQ 사용"
  local f_clean="로그인 버튼이 눌리지 않는다. U""TF-8 인코딩, 예시 user@example.com, 경로 /Users/you/app"
  printf '%s\n' "$f_domain" > "$t/a1"; printf '%s\n' "$f_ticket" > "$t/a2"; printf '%s\n' "$f_mail" > "$t/a3"
  printf '%s\n' "$f_emp" > "$t/a4"; printf '%s\n' "$f_org" > "$t/a5"; printf '%s\n' "$f_tok" > "$t/a6"
  printf '%s\n' "$f_path" > "$t/a7"; printf '%s\n' "$f_id" > "$t/a8"; printf '%s\n' "$f_repl" > "$t/a0"
  printf '%s\n' "$f_clean" > "$t/clean"
  printf '%s\n' "$f_domain" "$f_ticket" > "$t/multi"
  printf 'literal:ZZcode%sQQ==>x\n' 'name' > "$t/repl.txt"

  export CHECK_DRAFT_IDENTITIES="zzidentityx"
  local ax
  echo "=== check-draft.sh --self-test (고정문은 레포 밖 임시 디렉토리 $t 에만 존재) ==="
  # 종료 코드만 보면 다른 축이 대신 걸려도 통과한다 — 그 축의 글리프가 출력에 있어야 발화로 친다
  local glyphs=(⓪ ① ② ③ ④ ⑤ ⑥ ⑦ ⑧) o
  for ax in 1 2 3 4 5 6 7 8; do
    o="$(CHECK_DRAFT_REPL="$t/none.txt" "$0" --file "$t/a$ax" 2>/dev/null)"
    if printf '%s' "$o" | grep -q "\[[^]]*${glyphs[$ax]}"; then ok "축 $ax 발화(${glyphs[$ax]})"; else ng "축 $ax 미발화 — 그물이 뚫렸다"; fi
  done
  o="$(CHECK_DRAFT_REPL="$t/repl.txt" "$0" --file "$t/a0" 2>/dev/null)"
  printf '%s' "$o" | grep -q '⓪' && ok "축 0(치환표) 발화(⓪)" || ng "축 0(치환표) 미발화"
  CHECK_DRAFT_REPL="$t/none.txt" "$0" --file "$t/a0" >/dev/null 2>&1 && ok "치환표 없으면 그 항목은 안 잡힌다(일반형 축만 — 의도된 동작)" || ng "치환표 없는데 축 0이 발화"
  CHECK_DRAFT_REPL="$t/none.txt" "$0" --file "$t/clean" >/dev/null 2>&1 && ok "깨끗한 초안(placeholder·약어 포함) exit 0" || ng "깨끗한 초안이 걸렸다(오탐)"
  local out; out="$(CHECK_DRAFT_REPL="$t/none.txt" "$0" --file "$t/multi" 2>/dev/null)"
  printf '%s' "$out" | grep -q 'L1' && printf '%s' "$out" | grep -q 'L2' && printf '%s' "$out" | grep -q '치환안' && ok "걸린 줄 번호·치환안 출력" || ng "줄 번호/치환안 출력 누락"
  # 공개 여부: 가짜 gh
  # 🔴 가짜 gh 는 실제 gh 의 인자 형식(`repo view <owner/repo> --json … -q …`, -R 없음)만 받는다 — 잘못된 호출이 조용히 통과하지 않게
  printf '#!/bin/sh\n[ "$*" = "repo view o/r --json visibility -q .visibility" ] && echo PRIVATE || exit 1\n' > "$t/gh_priv"; printf '#!/bin/sh\nexit 1\n' > "$t/gh_fail"; chmod +x "$t/gh_priv" "$t/gh_fail"
  GH_BIN="$t/gh_priv" CHECK_DRAFT_REPL="$t/none.txt" "$0" --repo o/r --file "$t/a1" >/dev/null 2>&1 && ok "PRIVATE이면 걸리는 초안도 건너뜀(exit 0)" || ng "PRIVATE인데 검사됨"
  GH_BIN="$t/gh_fail" CHECK_DRAFT_REPL="$t/none.txt" "$0" --repo o/r --file "$t/a1" >/dev/null 2>&1 && ng "판정 실패인데 통과 — PUBLIC 간주 실패" || ok "공개 여부 판정 실패 → PUBLIC 간주(검사함)"
  rm -rf "$t"
  echo ""
  if [ "$fails" -eq 0 ]; then echo "self-test 통과"; exit 0; else echo "self-test 실패 ${fails}건"; exit 1; fi
}

# ── 진입 ───────────────────────────────────────────────────────────────────────
repo=""; file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --self-test) self_test ;;
    --repo) repo="${2:-}"; shift ;;
    --file) file="${2:-}"; shift ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "알 수 없는 인자: $1" >&2; exit 2 ;;
  esac
  shift
done
cleanup_tmp=""
if [ -z "$file" ]; then
  cleanup_tmp="$(mktemp "${TMPDIR:-/tmp}/check-draft-in.XXXXXX")" || cant "임시 파일 생성 실패"
  cat > "$cleanup_tmp"; file="$cleanup_tmp"
fi
[ -f "$file" ] || cant "초안 파일을 읽을 수 없다: $file"
[ -s "$file" ] || cant "초안이 비어 있다"
run_check "$file" "$repo"; rc=$?
[ -n "$cleanup_tmp" ] && rm -f "$cleanup_tmp"
exit "$rc"
