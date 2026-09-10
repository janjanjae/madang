#!/bin/bash
# make-hero-gif.sh — README 히어로 GIF 생성 (2026-09-04, 상태 4신호·5라벨 재캡처 2026-09-10)
# 가짜 팀 폴더에서 네 상태(작업중·컨펌 대기·사람 필요·쉼)를 순서대로 연출하고, 워커 창만 캡처해 ffmpeg로 GIF를 만든다.
# 사용: ./make-hero-gif.sh [출력.gif]   (ffmpeg 필요: brew install ffmpeg)
set -e
OUT="${1:-$(dirname "$0")/../../assets/hero.gif}"
DIR="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)/team"; mkdir -p "$T/briefs" "$T/confirm" "$T/reports"
F="$(mktemp -d)"
touch_at() { touch -t "$2" "$1"; }   # -t YYYYMMDDhhmm

# 실제 브리프 H1 형식("브리프 — 이름 · 날짜 · 태스크명") — 말풍선 제목 줄(3번 작업)이 진짜처럼 보이게,
# 인스턴스마다 다른 태스크명으로 (2026-09-05 팀장 리뷰 — "# 브리프" 한 줄뿐이면 말풍선에 "브리프"만 뜬다)
briefTitle() {
  case $1 in
    solver)   echo "# 브리프 — 번뜩 (solver) · 2026-09-05 · 백로그 1번: tracker-config github 타입";;
    builder)  echo "# 브리프 — 몽글 (builder) · 2026-09-05 · 백로그 7번: v0.5 공개 준비";;
    sketcher) echo "# 브리프 — 슥슥 (sketcher) · 2026-09-05 · 백로그 4번: 히어로 GIF 레티나 재캡처";;
  esac
}

# 세션 기록 없이 파일만으로 상태를 만든다 (madang은 세션 기록이 없으면 보고 mtime만 본다)
scene() {  # $1=solver $2=builder $3=sketcher — working|confirm|blocked|idle|off
  rm -f "$T"/confirm/*.md "$T"/reports/*.md "$T"/briefs/*.md
  for pair in "solver:$1" "builder:$2" "sketcher:$3"; do k=${pair%%:*}; s=${pair##*:}
    [ "$s" = off ] && continue
    briefTitle "$k" > "$T/briefs/$k.md"; touch_at "$T/briefs/$k.md" "$(date -v-2H +%Y%m%d%H%M)"
    case $s in
      working) echo "# 보고" > "$T/reports/$k.md";;
      confirm) echo "CONFIRM 요청" > "$T/confirm/$k.request.md";;
      blocked) echo "BLOCKED 막힘" > "$T/confirm/$k.request.md";;
      idle)    echo "# 보고" > "$T/reports/$k.md"; touch_at "$T/reports/$k.md" "$(date -v-90M +%Y%m%d%H%M)";;
    esac
  done
}

# 이름(owner name)만으로 창을 찾으면 다른 madang 프로세스(라이브 오버레이 등)가 같은 이름으로 떠
# 있을 때 엉뚱한 창을 집어 캡처 크기가 실행마다 널뛴다 — 이 스크립트가 띄운 PID로만 정확히 집는다.
winid() { swift - "$1" <<'EOF' 2>/dev/null
import CoreGraphics
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
for w in list where (w[kCGWindowOwnerPID as String] as? Int32) == pid { print(w[kCGWindowNumber as String]!) ; break }
EOF
}

scene working working working
# 메인(레티나) 화면 왼쪽 아래에 띄운다 — 외장 1x 모니터에 뜨면 캡처가 작다
defaults write madang "madang.origin.$T" -array 120 120
MADANG_SILENT=1 "$DIR/madang" "$T" >/dev/null 2>&1 &
PID=$!
sleep 3
ID=$(winid "$PID"); [ -n "$ID" ] || { echo "madang 창을 못 찾음"; kill "$PID" 2>/dev/null || true; exit 1; }

i=0
snap() { for n in $(seq 1 "$1"); do i=$((i+1)); screencapture -x -l "$ID" "$(printf "$F/f%03d.png" $i)"; sleep 0.5; done; }
scene working working working; sleep 3.5; snap 2     # 셋 다 작업중 (바운스)
scene confirm working working; sleep 3.5; snap 2     # 번뜩 컨펌 대기 (호박 발광 + 말풍선)
scene confirm blocked working; sleep 3.5; snap 2     # 몽글 사람 필요 (적 발광, 말풍선 단일화로 이 한 장만 뜬다)
scene working working idle;    sleep 3.5; snap 2     # 슥슥 쉼 (눈 감음)

kill "$PID" 2>/dev/null || true
# 컨펌 대기·막힘 장면은 말풍선·발광이 떠 창 캡처 크기 자체가 커진다 — 프레임마다 크기가 다르면 ffmpeg
# 이미지 시퀀스가 첫 크기 변경에서 멈춰 GIF가 1프레임으로 끊긴다(2026-09-05 발견 — 레티나 여부와 무관한
# 기존 버그). 2026-09-10에 패널 자체를 workerH+bubbleHeadroom 고정 높이로 만들었지만(결함 3) CGWindow의
# 프레임(kCGWindowBounds)은 실측으로 확실히 상수였다 — 그런데도 screencapture -l 캡처 파일 크기는 여전히
# 널뛴다(직접 실험 확인, 588~590 x 206~304). 창이 투명/보더리스일 때 screencapture가 창 프레임이 아니라
# "실제로 그려진(불투명) 픽셀의 바운딩 박스"로 크롭하는 것으로 보인다 — 말풍선이 없으면 마스코트+그림자만
# 작게 잡히고, 말풍선이 뜨면 그 위 여유 공간까지 포함돼 커진다. 패널 높이를 고정해도 이 캡처 단계의
# 특성 자체는 그대로라 고정 캔버스 정렬은 여전히 필요 — 프레임마다 최댓값을 훑는다.
MAXW=0; MAXH=0
for f in "$F"/f*.png; do
  w=$(sips -g pixelWidth "$f" | awk '/pixelWidth/{print $2}')
  h=$(sips -g pixelHeight "$f" | awk '/pixelHeight/{print $2}')
  [ "$w" -gt "$MAXW" ] && MAXW=$w
  [ "$h" -gt "$MAXH" ] && MAXH=$h
done
PADW=$((MAXW + 48)); PADH=$((MAXH + 48))
# 투명 창 캡처를 고정 캔버스 위 종이색 배경에 합성. (시퀀스 오버레이는 타임스탬프가 어긋나 빈 프레임이 나온다)
for f in "$F"/f*.png; do
  ffmpeg -y -loglevel error -i "$f" -f lavfi -i "color=c=#F5F7F8:s=${PADW}x${PADH}" -filter_complex \
    "[0:v]format=rgba,pad=${PADW}:${PADH}:(ow-iw)/2:oh-ih-24:color=#F5F7F8@0[fg];[1:v][fg]overlay=shortest=1:format=auto,format=rgb24" \
    -frames:v 1 "$F/g$(basename "$f" | cut -c2-)"
done
# 원본 워커 창(296x132pt)이 README 표시 폭(~900px)엔 작아 업스케일한다. 진짜 다프레임 GIF가 되며
# (위 고정 캔버스 전엔 1프레임에서 멈췄다) 용량이 커져 300KB를 넘기므로 순서대로: 팔레트는 48색
# 이상 유지(12색은 호박·적 발광이 안 구분돼 2026-09-05 팀장 리뷰에서 기각) → 폭 1050 → 스냅 밀도
# 6→3·3·2·2(총 10프레임, 2026-09-05). 2026-09-10: 안광 상시로 프레임당 디테일(눈동자)이 늘어
# 356KB로 다시 초과 — 스냅 밀도를 2·2·2·2(총 8프레임)로 한 단계 더 줄여 289KB로 복귀. 4장면·순서는 그대로.
ffmpeg -y -loglevel error -framerate 2 -i "$F/g%03d.png" -vf "scale=1050:-2:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=48:stats_mode=diff[pal];[s1][pal]paletteuse=dither=none" -loop 0 "$OUT"
defaults delete madang "madang.origin.$T" 2>/dev/null || true
echo "built: $OUT ($(du -k "$OUT" | cut -f1)KB, $i frames)"
