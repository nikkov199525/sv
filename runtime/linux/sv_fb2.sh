#!/bin/sh
# ---------------------------------------------------------------------
#  sv_fb2.sh -- книга fb2 для SV. Строка SV.DCL:
#      fb2:  "$SV/sv_fb2.sh" "<Archive>" "<Directory>"
#  $1 -- книга .fb2, $2 -- временный каталог.
#
#  Текст получается xsltproc по fb2/FB2_to_txt.xsl и пишется во
#  временный каталог: оригинал не трогаем. Без xsltproc книга
#  копируется как есть.
# ---------------------------------------------------------------------
book=$1
dst=$2
here=$(dirname "$0")
[ -n "$book" ] && [ -n "$dst" ] && [ -f "$book" ] || exit 1
mkdir -p "$dst" || exit 1

name=$(basename "$book")
# метки глав для bookmania не нужны
if command -v xsltproc >/dev/null 2>&1 &&
    xsltproc --param new-track-at-section 0 --param new-track-at-subsection 0 \
        "$here/fb2/FB2_to_txt.xsl" "$book" > "$dst/${name%.*}.txt" 2>/dev/null; then
    exit 0
fi
rm -f "$dst/${name%.*}.txt"
cp -f "$book" "$dst/"
exit 0
