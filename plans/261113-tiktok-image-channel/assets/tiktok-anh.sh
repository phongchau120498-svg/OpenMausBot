#!/usr/bin/env bash
# Làm ảnh TikTok dạng ảnh từ video quay sẵn.
#   tiktok-anh.sh khung <video> [số khung, mặc định 16]
#       -> ra/<tên video>/khung-NN.jpg và ra/<tên video>/bang-khung.jpg (lưới có số để chọn)
#   tiktok-anh.sh chu <khung.jpg> <ảnh ra.jpg> "<chữ>" [tren|giua|duoi]
#       -> ảnh 1080x1920 có chữ, tránh thanh trên, caption dưới và cột nút bên phải của TikTok
#   tiktok-anh.sh bang <thư mục ảnh>
#       -> bang-nguon.jpg: lưới mọi ảnh trong thư mục, có tên, để chọn ảnh
#   tiktok-anh.sh luoi <ảnh ra 1> <ảnh ra 2> ...
#       -> bang-ket-qua.jpg cạnh ảnh đầu, để xem lại cả bộ trong một ảnh
set -euo pipefail

GOC="$(cd "$(dirname "$0")/.." && pwd)"
FONT="${TIKTOK_ANH_FONT:-/usr/share/fonts/truetype/noto/NotoSans-Bold.ttf}"
W=1080 H=1920

khung() {
  local video="$1" n="${2:-16}"
  [[ -f "$video" ]] || { echo "Không thấy video: $video" >&2; exit 1; }
  local ten; ten="$(basename "${video%.*}")"
  local ra="$GOC/ra/$ten"
  mkdir -p "$ra"
  rm -f "$ra"/khung-*.jpg
  local dai; dai="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")"
  # ponytail: chia đều theo thời lượng; bot tự loại khung mờ/chớp mắt khi xem bảng. Cần thì đổi sang lọc theo chuyển cảnh.
  for i in $(seq 1 "$n"); do
    local t; t="$(awk -v d="$dai" -v i="$i" -v n="$n" 'BEGIN{printf "%.3f", d*(i-0.5)/n}')"
    ffmpeg -v error -y -ss "$t" -i "$video" -map_metadata -1 -frames:v 1 -q:v 2 "$ra/$(printf 'khung-%02d.jpg' "$i")"
  done
  magick montage "$ra"/khung-*.jpg -font "$FONT" -pointsize 28 -fill white -background '#111' \
    -set label '%[basename]' -geometry 270x480+6+6 -tile 8x -strip -quality 80 "$ra/bang-khung.jpg"
  echo "$ra"
}

chu() {
  local vao="$1" ra="$2" text="$3" vitri="${4:-tren}"
  [[ -f "$vao" ]] || { echo "Không thấy khung: $vao" >&2; exit 1; }
  # Vùng an toàn: chừa 220px trên, 520px dưới, 170px bên phải cho nút TikTok.
  local y
  case "$vitri" in
    tren) y=260 ;;
    giua) y=760 ;;
    duoi) y=1120 ;;
    *) echo "Vị trí phải là tren, giua hoặc duoi" >&2; exit 1 ;;
  esac
  mkdir -p "$(dirname "$ra")"
  local lop; lop="$(mktemp --suffix=.png)"
  # Chữ trắng viền đen, tự xuống dòng trong khung 880px.
  magick -background none -font "$FONT" -size 880x -pointsize "${TIKTOK_ANH_CO_CHU:-66}" -interline-spacing 6 -gravity center -fill white \
    -stroke black -strokewidth 10 caption:"$text" \
    \( -background none -font "$FONT" -size 880x -pointsize "${TIKTOK_ANH_CO_CHU:-66}" -interline-spacing 6 -gravity center -fill white -stroke none caption:"$text" \) \
    -compose over -composite "$lop"
  magick "$vao" -auto-orient -resize "${W}x${H}^" -gravity center -extent "${W}x${H}" \
    "$lop" -gravity north -geometry "-70+$y" -compose over -composite \
    -colorspace sRGB -strip -sampling-factor 4:2:0 -interlace JPEG -quality 92 "$ra"
  rm -f "$lop"
  kiem "$ra"
  echo "$ra"
}

# Luật đăng social: 1080x1920 (9:16), JPEG sRGB, không còn metadata, dưới 20 MB (giới hạn ảnh của TikTok).
kiem() {
  local f="$1" kt meta byte
  kt="$(magick identify -format '%wx%h %[colorspace]' "$f")"
  meta="$(magick identify -format '%[EXIF:*]%[IPTC:*]%[XMP:*]' "$f" 2>/dev/null || true)"
  byte="$(stat -c %s "$f")"
  [[ "$kt" == "1080x1920 sRGB" && -z "$meta" && "$byte" -lt 20000000 ]] || { echo "Ảnh không đạt chuẩn đăng: $f ($kt, metadata: ${meta:-không}, $byte byte)" >&2; exit 1; }
}

bang() {
  local thu="$1" ra="$1/bang-nguon.jpg" anh=()
  shopt -s nullglob nocaseglob
  for f in "$thu"/*.{jpg,jpeg,png,heic,webp}; do [[ "$(basename "$f")" == bang-* ]] || anh+=("$f"); done
  shopt -u nullglob nocaseglob
  (( ${#anh[@]} )) || { echo "Không có ảnh trong $thu" >&2; exit 1; }
  rm -f "$ra"
  magick montage "${anh[@]}" -auto-orient -font "$FONT" -pointsize 22 -fill white -background '#111' \
    -set label '%[basename]' -geometry 240x427+6+6 -tile 8x -strip -quality 80 "$ra"
  echo "$ra"
}

luoi() {
  local thu; thu="$(dirname "$1")"
  magick montage "$@" -geometry 360x640+8+8 -background '#111' -tile "${#}x1" "$thu/bang-ket-qua.jpg"
  echo "$thu/bang-ket-qua.jpg"
}

case "${1:-}" in
  khung) shift; khung "$@" ;;
  chu) shift; chu "$@" ;;
  luoi) shift; luoi "$@" ;;
  bang) shift; bang "$@" ;;
  kiem) shift; for f in "$@"; do kiem "$f"; done; echo "Đạt" ;;
  *) sed -n '2,9p' "$0"; exit 1 ;;
esac
