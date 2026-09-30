#!/bin/sh
# ---------------------------------------------------------------------
#  sv_arc.sh -- распаковка архива для SV. Строка SV.DCL:
#      zip:  "$SV/sv_arc.sh" "<Archive>" "<Directory>"
#  $1 -- архив, $2 -- каталог, куда распаковать.
#
#  1) архив распаковывает 7z (p7zip), а если его нет -- bsdtar, unzip,
#     unrar или tar;
#  2) вложенные архивы, в которых есть fb2 или txt, распаковываются тоже
#     (один уровень);
#  3) книги fb2 превращаются в текст (xsltproc и fb2/FB2_to_txt.xsl);
#  4) всё, что SV умеет читать, собирается в корень каталога, остальное
#     удаляется: SV покажет плоский список, а единственный файл откроет
#     сразу.
# ---------------------------------------------------------------------
arc=$1
dst=$2
here=$(dirname "$0")
[ -n "$arc" ] && [ -n "$dst" ] && [ -f "$arc" ] || exit 1
mkdir -p "$dst" || exit 1

have() { command -v "$1" >/dev/null 2>&1; }

# fb2 <книга> -- текст книги (метки глав для bookmania не нужны)
fb2() {
    xsltproc --param new-track-at-section 0 --param new-track-at-subsection 0 \
        "$here/fb2/FB2_to_txt.xsl" "$1" 2>/dev/null
}

# extract <архив> <каталог>
extract() {
    if have 7z; then
        7z x -y "-o$2" "$1" >/dev/null 2>&1
    elif have 7za; then
        7za x -y "-o$2" "$1" >/dev/null 2>&1
    elif have bsdtar; then
        bsdtar -xf "$1" -C "$2" >/dev/null 2>&1
    else
        case $(printf '%s' "$1" | tr 'A-Z' 'a-z') in
            *.zip) unzip -o -qq "$1" -d "$2" ;;
            *.rar) unrar x -o+ -inul "$1" "$2/" ;;
            *) tar -xf "$1" -C "$2" ;;
        esac >/dev/null 2>&1
    fi
}

# list <архив> -- имена файлов в архиве
list() {
    if have 7z; then
        7z l "$1" 2>/dev/null
    elif have 7za; then
        7za l "$1" 2>/dev/null
    elif have bsdtar; then
        bsdtar -tf "$1" 2>/dev/null
    else
        case $(printf '%s' "$1" | tr 'A-Z' 'a-z') in
            *.zip) unzip -l "$1" ;;
            *.rar) unrar lb "$1" ;;
            *) tar -tf "$1" ;;
        esac 2>/dev/null
    fi
}

# 1. архив
extract "$arc" "$dst"

# 2. вложенные архивы с fb2 или txt
find "$dst" -type f \( -iname '*.zip' -o -iname '*.rar' -o -iname '*.7z' \) | while IFS= read -r inner; do
    if list "$inner" | grep -qi '\.fb2\|\.txt'; then
        extract "$inner" "$dst"
        rm -f "$inner"
    fi
done

# 3. fb2 -> txt
if have xsltproc; then
    find "$dst" -type f -iname '*.fb2' | while IFS= read -r book; do
        text="${book%.*}.txt"
        if fb2 "$book" > "$text"; then
            rm -f "$book"
        else
            rm -f "$text"
        fi
    done
fi

# 4. читаемое -- в корень, остальное -- прочь
find "$dst" -mindepth 2 -type f \( -iname '*.txt' -o -iname '*.fb2' -o -iname '*.doc' \
    -o -iname '*.htm' -o -iname '*.html' -o -iname '*.dbf' \) -exec mv -f {} "$dst/" \;
find "$dst" -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} +
exit 0
