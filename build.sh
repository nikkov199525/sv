#!/bin/sh
# ===========================================================================
#  build.sh -- сборка Speaking Viewer (SV) 4.0 на Linux: deb-пакет.
#
#    ./build.sh [x64|x86|all|check|install|clean] [keep]
#
#    x64      64-разрядный deb-пакет (так -- если довода нет);
#    x86      32-разрядный (нужны gcc-multilib/g++-multilib);
#    all      оба с одним номером сборки;
#    check    собрать и прогнать проверки (без пакета);
#    install  собрать x64 и установить (спросит пароль root или sudo);
#    clean    удалить всё собранное;
#    keep     не удалять дерево сборки obj/ (следующая сборка быстрее).
#
#  Результат -- build/sv_<версия>_amd64.deb (i386 для x86) и та же
#  программа без установки в build/linux-x64. После установки программа
#  запускается командой sv; папка настроек -- ~/.config/sv (man sv).
#
#  Нужны: CMake 3.25 или новее, gcc/g++ или clang, make, dpkg-dev.
#  Звук -- через miniaudio: она выбирает доступный системный аудиосервер
#  или ALSA, дополнительные заголовки для сборки не нужны.
# ===========================================================================

# Всё -- в подоболочке: и запуск через «. build.sh» не закроет терминал.
main() (
    set -e
    line="==========================================================================="

    missing=""
    command -v cmake >/dev/null 2>&1 || missing="$missing cmake"
    command -v make >/dev/null 2>&1 || missing="$missing make"
    command -v c++ >/dev/null 2>&1 || missing="$missing g++"
    if [ "$1" != "check" ] && [ "$1" != "clean" ]; then
        command -v dpkg-shlibdeps >/dev/null 2>&1 || missing="$missing dpkg-dev"
    fi
    # 32-разрядная сборка: компилятор с -m32 и библиотеки i386 для
    # зависимостей пакета.
    case " $* " in
    *" x86 "*|*" all "*)
        if ! echo 'int main() { return 0; }' |
                c++ -m32 -x c++ - -o /dev/null >/dev/null 2>&1; then
            missing="$missing gcc-multilib g++-multilib"
        fi
        if [ "$1" != "check" ] && ! dpkg -s libstdc++6:i386 >/dev/null 2>&1; then
            echo "[ОШИБКА] Для пакета i386 нужны библиотеки i386. Установить (от root):" >&2
            echo "         dpkg --add-architecture i386 && apt update &&" >&2
            echo "         apt install libc6:i386 libstdc++6:i386 libgcc-s1:i386" >&2
            [ -n "$missing" ] && echo "         apt install$missing" >&2
            return 1
        fi ;;
    esac
    if [ -n "$missing" ]; then
        echo "[ОШИБКА] Не хватает инструментов сборки:$missing" >&2
        echo "         Установить (от root): apt install$missing" >&2
        return 1
    fi

    install=""
    if [ $# -eq 0 ]; then
        set -- x64
    elif [ "$1" = "install" ]; then
        shift
        set -- x64 "$@"
        install=yes
    fi

    if ! cmake -P cmake/build.cmake "$@"; then
        echo
        echo "$line"
        echo "  [ОШИБКА] Сборка не завершена. Прочтите сообщения выше."
        echo "$line"
        return 1
    fi
    case $1 in
    check|clean) return 0 ;;
    esac

    n=$(cat build/BUILD_NUMBER.txt 2>/dev/null || true)
    echo
    echo "$line"
    echo "  Сборка 4.0.0.$n успешно завершена."
    for deb in build/sv_*.deb; do
        [ -f "$deb" ] && echo "  Пакет: $deb"
    done
    if [ -z "$install" ]; then
        echo "  Установка: ./build.sh install"
        echo "    или вручную: su -   и затем   apt install $(pwd)/build/sv_*_amd64.deb"
        echo "  Запуск: sv [файл...]      Справка: sv --help, man sv"
        echo "$line"
        return 0
    fi
    echo "$line"
    install_deb "build/sv_4.0.0.${n}_amd64.deb"
)

# Установить пакет через apt: он доставит зависимости. Права root -- как
# есть: сам root, sudo (если пользователю можно) или su (пароль root).
# Пакет ставится из временной папки: домашняя обычно закрыта (700), и
# apt, читая файл оттуда, пугал бы «unsandboxed as root».
install_deb() {
    deb=$1
    tmp=$(mktemp -d /tmp/sv-deb.XXXXXX) || return 1
    chmod 755 "$tmp"
    cp "$deb" "$tmp/" && chmod 644 "$tmp/$(basename "$deb")"
    # PATH root задан явно: у «su» без «-» остаётся PATH пользователя без
    # /usr/sbin, и dpkg обрывает установку («start-stop-daemon not found»).
    cmd="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin apt install -y $tmp/$(basename "$deb")"
    echo
    rc=0
    if [ "$(id -u)" -eq 0 ]; then
        sh -c "$cmd" || rc=$?
    elif id -nG | tr ' ' '\n' | grep -qx sudo; then
        echo "  Установка через sudo (пароль пользователя):"
        sudo sh -c "$cmd" || rc=$?
    else
        echo "  Установка от root (пароль root):"
        su -c "$cmd" || rc=$?
    fi
    rm -rf "$tmp"
    echo
    if [ $rc -eq 0 ]; then
        echo "  Установлено. Запуск: sv [файл...]      Справка: sv --help, man sv"
    else
        echo "  [ОШИБКА] Пакет не установлен (код $rc)."
    fi
    return $rc
}

# Папка проекта: откуда бы ни звали (у «. build.sh» $0 -- это оболочка).
dir=$(dirname "${BASH_SOURCE:-$0}")
[ -f "$dir/cmake/build.cmake" ] || dir=.
(cd "$dir" && main "$@")
rc=$?
return $rc 2>/dev/null || exit $rc
