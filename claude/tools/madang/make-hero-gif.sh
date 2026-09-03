#!/bin/bash
# make-hero-gif.sh — README 히어로 GIF 생성 (2026-09-04)
# 가짜 팀 폴더에서 네 상태(작업중·컨펌 대기·막힘·유휴)를 순서대로 연출하고, 펫 창만 캡처해 ffmpeg로 GIF를 만든다.
# 사용: ./make-hero-gif.sh [출력.gif]   (ffmpeg 필요: brew install ffmpeg)
set -e
OUT="${1:-$(dirname "$0")/../../assets/hero.gif}"
DIR="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)/team"; mkdir -p "$T/briefs" "$T/confirm" "$T/reports"
F="$(mktemp -d)"
touch_at() { touch -t "$2" "$1"; }   # -t YYYYMMDDhhmm

# 세션 기록 없이 파일만으로 상태를 만든다 (madang은 세션 기록이 없으면 보고 mtime만 본다)
scene() {  # $1=solver $2=builder $3=sketcher — working|confirm|blocked|idle|off
  rm -f "$T"/confirm/*.md "$T"/reports/*.md "$T"/briefs/*.md
  for pair in "solver:$1" "builder:$2" "sketcher:$3"; do k=${pair%%:*}; s=${pair##*:}
    [ "$s" = off ] && continue
    echo "# 브리프" > "$T/briefs/$k.md"; touch_at "$T/briefs/$k.md" "$(date -v-2H +%Y%m%d%H%M)"
    case $s in
      working) echo "# 보고" > "$T/reports/$k.md";;
      confirm) echo "CONFIRM 요청" > "$T/confirm/$k.request.md";;
      blocked) echo "BLOCKED 막힘" > "$T/confirm/$k.request.md";;
      idle)    echo "# 보고" > "$T/reports/$k.md"; touch_at "$T/reports/$k.md" "$(date -v-90M +%Y%m%d%H%M)";;
    esac
  done
}

winid() { "$DIR/../../../plans/.." >/dev/null 2>&1; swift - <<'EOF' 2>/dev/null
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w[kCGWindowOwnerName as String] as? String) == "madang" { print(w[kCGWindowNumber as String]!) ; break }
EOF
}

pkill -x madang 2>/dev/null || true
scene working working working
MADANG_SILENT=1 "$DIR/madang" "$T" >/dev/null 2>&1 &
sleep 3
ID=$(winid); [ -n "$ID" ] || { echo "madang 창을 못 찾음"; exit 1; }

i=0
snap() { for n in $(seq 1 "$1"); do i=$((i+1)); screencapture -x -l "$ID" "$(printf "$F/f%03d.png" $i)"; sleep 0.5; done; }
scene working working working; sleep 3.5; snap 6     # 셋 다 작업중 (바운스)
scene confirm working working; sleep 3.5; snap 6     # 번뜩 컨펌 대기 (호박 발광 + 말풍선)
scene confirm blocked working; sleep 3.5; snap 6     # 몽글 막힘 (적 발광)
scene working working idle;    sleep 3.5; snap 6     # 슥슥 유휴 (눈 감음)

pkill -x madang 2>/dev/null || true
ffmpeg -y -loglevel error -framerate 2 -i "$F/f%03d.png" -vf "scale=iw/2:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=64[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" -loop 0 "$OUT"
echo "built: $OUT ($(du -k "$OUT" | cut -f1)KB, $i frames)"
