# build.cmake -- сборка пакетов SV целиком.
#
#   cmake -P cmake/build.cmake <что> [-b mingw|msvs] [keep]
#
#   <что>:  x86     собрать build/x86 (Windows) или build/linux-x86 (Linux)
#           x64     собрать build/x64 (Windows) или build/linux-x64 (Linux)
#                   (на Linux -- ещё и deb-пакет build/sv_<версия>_<арх>.deb)
#           all     обе разрядности с одним номером сборки
#           check [x86|x64|all]
#                   собрать и прогнать проверки (номер сборки не растёт)
#           clean   полная очистка
#
#   -b mingw   llvm-mingw (clang) -- по умолчанию на Windows;
#   -b msvs    Visual Studio (MSVC), самая новая из установленных.
#   На Linux ключ -b не нужен: собирает системный gcc или clang.
#
# Довод keep оставляет дерево сборки obj/<пресет> -- следующая сборка пойдёт
# с того места, а не с нуля. Штатно оно удаляется после успешной сборки: в
# папке результата и рядом с ней не остаётся промежуточных файлов.
#
# Номер сборки увеличивается здесь, ровно один раз за запуск: x86 и x64,
# собранные вместе, получают один и тот же номер.

get_filename_component(root "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
include("${root}/cmake/version.cmake")

set(action "")
set(arches "")
if(CMAKE_HOST_WIN32)
    set(toolchain mingw)
else()
    set(toolchain linux)
endif()
set(keep OFF)
set(expect_toolchain OFF)
math(EXPR last "${CMAKE_ARGC} - 1")
foreach(i RANGE 3 ${last})
    set(arg "${CMAKE_ARGV${i}}")
    if(expect_toolchain)
        set(expect_toolchain OFF)
        if(NOT arg MATCHES "^(mingw|msvs)$")
            message(FATAL_ERROR "Ключ -b: ожидается mingw или msvs, а не «${arg}».")
        endif()
        set(toolchain "${arg}")
    elseif(arg MATCHES "^[-/]b$")
        set(expect_toolchain ON)
    elseif(arg MATCHES "^[-/]b[:=](.*)$")
        set(toolchain "${CMAKE_MATCH_1}")
        if(NOT toolchain MATCHES "^(mingw|msvs)$")
            message(FATAL_ERROR "Ключ -b: ожидается mingw или msvs, а не «${toolchain}».")
        endif()
    elseif(arg MATCHES "^(check|clean)$" AND NOT action)
        set(action "${arg}")
    elseif(arg MATCHES "^(x86|x64)$")
        set(arches "${arg}")
        if(NOT action)
            set(action build)
        endif()
    elseif(arg STREQUAL "all")
        set(arches x86 x64)
        if(NOT action)
            set(action build)
        endif()
    elseif(arg STREQUAL "keep")
        set(keep ON)
    elseif(NOT arg STREQUAL "--")
        message(FATAL_ERROR "Непонятный довод «${arg}».\n"
            "cmake -P cmake/build.cmake x86|x64|all|check|clean [-b mingw|msvs] [keep]")
    endif()
endforeach()
if(expect_toolchain)
    message(FATAL_ERROR "Ключ -b без значения: ожидается mingw или msvs.")
endif()
if(NOT CMAKE_HOST_WIN32 AND NOT toolchain STREQUAL "linux")
    message(FATAL_ERROR "На Linux ключ -b не нужен: сборка -- системным компилятором.")
endif()

if(NOT action)
    message("SV 4.0: cmake -P cmake/build.cmake x86|x64|all|check|clean [-b mingw|msvs] [keep]")
    return()
endif()

if(action STREQUAL "clean")
    file(REMOVE_RECURSE "${root}/obj" "${root}/build/x86" "${root}/build/x64"
         "${root}/build/linux-x86" "${root}/build/linux-x64")
    file(GLOB debs "${root}/build/*.deb")
    file(REMOVE "${root}/build/version.h" "${root}/build/version.rc" ${debs})
    message("Cleaned.")
    return()
endif()

if(action STREQUAL "check")
    if(NOT arches)
        set(arches x64)
    endif()
else()
    sv_generate_version("${root}" ON)
    message("=== build number: ${SV_VERSION_STRING} ===")
endif()

function(run)
    execute_process(COMMAND ${ARGN} WORKING_DIRECTORY "${root}" RESULT_VARIABLE result)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Сборка прервана: ${ARGN}")
    endif()
endfunction()

foreach(arch ${arches})
    set(preset "${toolchain}-${arch}")
    if(toolchain STREQUAL "linux")
        set(out "linux-${arch}")
    else()
        set(out "${arch}")
    endif()
    message("")
    message("############ ${preset} ############")
    run("${CMAKE_COMMAND}" --preset ${preset})
    run("${CMAKE_COMMAND}" --build --preset ${preset})
    if(action STREQUAL "check")
        run("${CMAKE_COMMAND}" --build --preset ${preset} --target check)
    endif()
    # Linux: из собранного -- deb-пакет build/sv_<версия>_<арх>.deb.
    if(toolchain STREQUAL "linux" AND NOT action STREQUAL "check")
        run("${CMAKE_COMMAND}" -DROOT=${root} -DARCH=${arch} -DVERSION=${SV_VERSION_STRING}
            -P "${root}/cmake/deb.cmake")
    endif()

    # Уборка: дерево сборки целиком и всё постороннее в папке результата.
    if(NOT keep)
        message("=== tidy ===")
        file(REMOVE_RECURSE "${root}/obj/${preset}")
    endif()
    file(GLOB_RECURSE junk "${root}/build/${out}/*.o" "${root}/build/${out}/*.obj"
         "${root}/build/${out}/*.a" "${root}/build/${out}/*.lib" "${root}/build/${out}/*.exp"
         "${root}/build/${out}/*.ilk" "${root}/build/${out}/*.pdb" "${root}/build/${out}/*.res")
    if(junk)
        file(REMOVE ${junk})
    endif()
    message("Result: ${root}/build/${out} (${toolchain})")
endforeach()

# Пустая папка obj после уборки ни к чему. Вместе с ней уходят и version.h,
# version.rc: они нужны только деревьям сборки, а те убраны. В build/
# остаются одни готовые пакеты и счётчик номера сборки.
file(GLOB left "${root}/obj/*")
if(NOT left)
    file(REMOVE_RECURSE "${root}/obj")
    file(REMOVE "${root}/build/version.h" "${root}/build/version.rc")
endif()
