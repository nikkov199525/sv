# deb.cmake -- deb-пакет из собранной для Linux программы.
#
#   cmake -DROOT=<корень> -DARCH=x64|x86 -DVERSION=4.0.0.N -P cmake/deb.cmake
#
# Берёт build/linux-<ARCH> (программа) и runtime/ и кладёт пакет в
# build/sv_<VERSION>_<amd64|i386>.deb. Нужны dpkg-deb и dpkg-shlibdeps
# (пакет dpkg-dev): вторая по самой программе вычисляет, какие
# библиотеки ей нужны, и они попадают в Depends -- apt доставит их при
# установке.
#
# Раскладка в системе:
#     /usr/bin/sv            запуск (packaging/deb/sv)
#     /usr/lib/sv/SV         программа
#     /usr/share/sv/         справка, настройки по умолчанию, SV.DCL,
#                            помощники архивов и fb2
#     /usr/share/man/man1/   man sv
#     /usr/share/doc/sv/     copyright
# Папка пользователя -- ~/.config/sv (см. packaging/deb/sv).

find_program(dpkg_deb dpkg-deb)
find_program(shlibdeps dpkg-shlibdeps)
find_program(gzip gzip)
if(NOT dpkg_deb OR NOT shlibdeps OR NOT gzip)
    message(FATAL_ERROR "Для deb-пакета нужны dpkg-deb, dpkg-shlibdeps и gzip: "
                        "apt install dpkg-dev gzip (от root)")
endif()

if(ARCH STREQUAL "x64")
    set(deb_arch amd64)
else()
    set(deb_arch i386)
endif()
set(package "${ROOT}/build/linux-${ARCH}")
set(stage "${ROOT}/obj/deb-${ARCH}")
set(deb "${ROOT}/build/sv_${VERSION}_${deb_arch}.deb")
if(NOT EXISTS "${package}/SV")
    message(FATAL_ERROR "Нет ${package}/SV: сначала сборка.")
endif()

file(REMOVE_RECURSE "${stage}")

set(exec_mode OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
              WORLD_READ WORLD_EXECUTE)
set(data_mode OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)

# put(<откуда> <куда в системе> [exec]) -- файл в пакет.
function(put from to)
    get_filename_component(dir "${stage}${to}" DIRECTORY)
    file(MAKE_DIRECTORY "${dir}")
    file(COPY_FILE "${from}" "${stage}${to}")
    if(ARGN STREQUAL "exec")
        file(CHMOD "${stage}${to}" PERMISSIONS ${exec_mode})
    else()
        file(CHMOD "${stage}${to}" PERMISSIONS ${data_mode})
    endif()
endfunction()

# Текст с подстановкой версии.
function(put_versioned from to)
    file(READ "${from}" text)
    string(REPLACE "@SV_VERSION@" "${VERSION}" text "${text}")
    get_filename_component(name "${from}" NAME)
    file(WRITE "${stage}.tmp/${name}" "${text}")
    put("${stage}.tmp/${name}" "${to}" ${ARGN})
endfunction()

put("${package}/SV" /usr/lib/sv/SV exec)
put_versioned("${ROOT}/packaging/deb/sv" /usr/bin/sv exec)
foreach(name SV_help.txt SV.INI SV.CFG fb2/FB2_to_txt.xsl)
    put("${ROOT}/runtime/${name}" "/usr/share/sv/${name}")
endforeach()
put("${ROOT}/runtime/linux/SV.DCL" /usr/share/sv/SV.DCL)
put("${ROOT}/runtime/linux/sv_arc.sh" /usr/share/sv/sv_arc.sh exec)
put("${ROOT}/runtime/linux/sv_fb2.sh" /usr/share/sv/sv_fb2.sh exec)

# man sv -- сжатый, без даты в заголовке gzip (-n): пакет воспроизводим.
put_versioned("${ROOT}/packaging/deb/sv.1" /usr/share/man/man1/sv.1)
execute_process(COMMAND "${gzip}" -9n "${stage}/usr/share/man/man1/sv.1" RESULT_VARIABLE rc)
if(NOT rc EQUAL 0)
    message(FATAL_ERROR "gzip: ${rc}")
endif()

# copyright и тексты лицензий сторонних частей.
file(READ "${ROOT}/packaging/deb/copyright" copyright)
foreach(pair "MIT|vendor/newfon_core/LICENSE" "public-domain or MIT-0|vendor/miniaudio/LICENSE")
    string(REPLACE "|" ";" pair "${pair}")
    list(GET pair 0 license)
    list(GET pair 1 file)
    file(STRINGS "${ROOT}/${file}" lines)
    string(APPEND copyright "\nLicense: ${license}\n")
    foreach(line IN LISTS lines)
        if(line STREQUAL "")
            string(APPEND copyright " .\n")
        else()
            string(APPEND copyright " ${line}\n")
        endif()
    endforeach()
endforeach()
file(MAKE_DIRECTORY "${stage}/usr/share/doc/sv")
file(WRITE "${stage}/usr/share/doc/sv/copyright" "${copyright}")
file(CHMOD "${stage}/usr/share/doc/sv/copyright" PERMISSIONS ${data_mode})

# Каталоги -- 755 (umask сборщика не должен попасть в пакет).
file(GLOB_RECURSE dirs LIST_DIRECTORIES true "${stage}/*")
foreach(d ${dirs})
    if(IS_DIRECTORY "${d}")
        file(CHMOD "${d}" PERMISSIONS ${exec_mode})
    endif()
endforeach()
file(CHMOD "${stage}" PERMISSIONS ${exec_mode})

# Зависимости программы: dpkg-shlibdeps читает её ELF и находит пакеты
# библиотек. Звук (ALSA, PulseAudio) miniaudio подгружает сама при запуске
# -- этого shlibdeps не видит, поэтому ALSA указана отдельно; procps (ps,
# pgrep) нужен запускающему скрипту.
file(MAKE_DIRECTORY "${stage}.tmp/debian")
file(WRITE "${stage}.tmp/debian/control" "Source: sv\n\nPackage: sv\nArchitecture: any\n")
execute_process(COMMAND "${shlibdeps}" -O "-e${stage}/usr/lib/sv/SV"
                WORKING_DIRECTORY "${stage}.tmp"
                OUTPUT_VARIABLE shlibs RESULT_VARIABLE rc ERROR_VARIABLE err)
if(NOT rc EQUAL 0 OR NOT shlibs MATCHES "shlibs:Depends=([^\n]*)")
    message(FATAL_ERROR "dpkg-shlibdeps: ${err}")
endif()
set(depends "${CMAKE_MATCH_1}, libasound2t64 | libasound2, procps")

# Размер установленного в КиБ.
file(GLOB_RECURSE files "${stage}/*")
set(size 0)
set(md5sums "")
foreach(f ${files})
    file(SIZE "${f}" bytes)
    math(EXPR size "${size} + (${bytes} + 1023) / 1024")
    file(MD5 "${f}" sum)
    file(RELATIVE_PATH rel "${stage}" "${f}")
    string(APPEND md5sums "${sum}  ${rel}\n")
endforeach()

# Сопровождающий пакета.
set(maintainer "Nayk <nikkov199525@gmail.com>")

file(MAKE_DIRECTORY "${stage}/DEBIAN")
file(WRITE "${stage}/DEBIAN/control" "Package: sv
Version: ${VERSION}
Architecture: ${deb_arch}
Maintainer: ${maintainer}
Installed-Size: ${size}
Depends: ${depends}
Recommends: p7zip-full | 7zip, xsltproc, unzip
Suggests: unrar
Section: text
Priority: optional
Description: Speaking Viewer -- talking text viewer for the blind
 SV shows and reads aloud texts in the terminal: DOS-866, Windows-1251,
 KOI8-R and UTF-8 texts, DBF databases, Word 97 documents, HTML pages;
 archives and fb2 books through helper scripts. Russian speech synthesis
 (newfon) is built in.
 .
 Говорящий просмотрщик текстов для незрячих: всё управление с клавиатуры,
 каждое действие озвучивается. Запуск -- sv, справка -- man sv.
")
file(WRITE "${stage}/DEBIAN/md5sums" "${md5sums}")
file(CHMOD "${stage}/DEBIAN" PERMISSIONS ${exec_mode})
file(CHMOD "${stage}/DEBIAN/control" "${stage}/DEBIAN/md5sums" PERMISSIONS ${data_mode})

# Пакет прежней сборки той же разрядности больше не нужен.
file(GLOB old "${ROOT}/build/sv_*_${deb_arch}.deb")
file(REMOVE ${old})
execute_process(COMMAND "${dpkg_deb}" --root-owner-group -Zxz --build "${stage}" "${deb}"
                RESULT_VARIABLE rc)
if(NOT rc EQUAL 0)
    message(FATAL_ERROR "dpkg-deb: ${rc}")
endif()
file(REMOVE_RECURSE "${stage}" "${stage}.tmp")
message("Пакет: ${deb}")
message("Установка (зависимости apt доставит сам): ./build.sh install")
