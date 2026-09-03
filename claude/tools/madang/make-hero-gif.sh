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

winid() { swift - <<'EOF' 2>/dev/null
import CoreGraphics
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w[kCGWindowOwnerName as String] as? String) == "madang" { print(w[kCGWindowNumber as String]!) ; break }
EOF
}

pkill -x madang 2>/dev/null || true
scene working working working
# 메인(레티나) 화면 왼쪽 아래에 띄운다 — 외장 1x 모니터에 뜨면 캡처가 작다
defaults write madang "madang.origin.$T" -array 120 120
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
# 투명 창 캡처를 프레임별로 종이색 위에 합성(여백 24px) → GIF 2fps. (시퀀스 오버레이는 타임스탬프가 어긋나 빈 프레임이 나온다)
for f in "$F"/f*.png; do
  ffmpeg -y -loglevel error -i "$f" -f lavfi -i "color=c=#F5F7F8:s=16x16" -filter_complex \
    "[0:v]format=rgba,pad=iw+48:ih+48:24:24:color=#F5F7F8@0[fg];[1:v][fg]scale2ref[bg][fg2];[bg][fg2]overlay=shortest=1:format=auto,format=rgb24" \
    -frames:v 1 "$F/g$(basename "$f" | cut -c2-)"
done
ffmpeg -y -loglevel error -framerate 2 -i "$F/g%03d.png" -vf "split[s0][s1];[s0]palettegen=max_colors=96[pal];[s1][pal]paletteuse=dither=bayer:bayer_scale=4" -loop 0 "$OUT"
defaults delete madang "madang.origin.$T" 2>/dev/null || true
echo "built: $OUT ($(du -k "$OUT" | cut -f1)KB, $i frames)"
