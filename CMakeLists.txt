# ===========================================================================
#  Speaking Viewer (SV) -- сборка.
#
#  Одно дерево сборки -- один тулчейн и одна разрядность:
#
#      mingw-x86, mingw-x64   llvm-mingw (clang), Windows;
#      msvs-x86,  msvs-x64    Visual Studio (MSVC), Windows;
#      linux-x64, linux-x86   системный gcc или clang, Linux.
#
#      cmake --preset mingw-x64 && cmake --build --preset mingw-x64
#
#  Готовый пакет ложится в build/<арх> (x86, x64, linux-x64, linux-x86).
#  Руками это звать не нужно: build_x86.bat, build_x64.bat, build_all.bat
#  (Windows) и build.sh (Linux) зовут cmake/build.cmake, который увеличивает
#  номер сборки, собирает и вычищает промежуточные файлы.
#
#  Исходники -- в UTF-8, текст внутри программы -- тоже UTF-8.
# ===========================================================================

cmake_minimum_required(VERSION 3.25)

# Статическая библиотека времени выполнения MSVC -- как -static у MinGW.
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded")

project(SV VERSION 4.0.0 LANGUAGES C CXX)
if(WIN32)
    enable_language(RC)
endif()

if(NOT SV_ARCH)
    if(WIN32)
        message(FATAL_ERROR
            "Разрядность не задана. Настраивайте пресетом: cmake --preset mingw-x64 "
            "(mingw-x86, msvs-x86, msvs-x64).")
    elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
        set(SV_ARCH linux-x64)
    else()
        set(SV_ARCH linux-x86)
    endif()
endif()

set(SV_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(SV_OUT "${SV_ROOT}/build/${SV_ARCH}")

option(SV_SANITIZE "AddressSanitizer + UBSan (clang/gcc)" OFF)
if(SV_SANITIZE)
    set(SV_OUT "${CMAKE_BINARY_DIR}/out")
    add_compile_options(-fsanitize=address,undefined -fno-omit-frame-pointer -g -O1)
    add_link_options(-fsanitize=address,undefined)
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin/$<0:>")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib/$<0:>")

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(MSVC)
    set(CMAKE_C_FLAGS_RELEASE "/O2 /Ob2")
    set(CMAKE_CXX_FLAGS_RELEASE "/O2 /Ob2")
else()
    set(CMAKE_C_FLAGS_RELEASE "-O2")
    set(CMAKE_CXX_FLAGS_RELEASE "-O2")
endif()
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()
set(CMAKE_CONFIGURATION_TYPES Release)

include("${SV_ROOT}/cmake/version.cmake")
sv_generate_version("${SV_ROOT}" OFF)

# ------------------------------------------------------------ newfon_core
# Речевое ядро (vendor/newfon_core) -- код на C, не переписывается;
# собирается статически и входит в SV целиком: отдельной DLL в пакете нет.
set(newfon_dir "${SV_ROOT}/vendor/newfon_core")
set(newfon_sources)
foreach(name female intonator male numerics sink soundproducer speechrate_control
             synth text2speech time_planner transcription utterance voices)
    list(APPEND newfon_sources "${newfon_dir}/src/${name}.c")
endforeach()
add_library(newfon_core STATIC ${newfon_sources})
if(MSVC)
    target_compile_options(newfon_core PRIVATE /O2 /W3 /utf-8 /wd4244 /wd4267 /wd4018)
    target_compile_definitions(newfon_core PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
    # Сторонний код (подмодуль): его предупреждения -- не наша забота, а
    # -Werror ломал сборку на каждом новом компиляторе (gcc 14: fallthrough).
    target_compile_options(newfon_core PRIVATE -O3 -w)
endif()
target_include_directories(newfon_core
    PUBLIC "${newfon_dir}/include"
    PRIVATE "${newfon_dir}/src")

# -------------------------------------------------------------- miniaudio
# Вывод звука (vendor/miniaudio, один заголовок): Windows -- WASAPI,
# DirectSound или WinMM, Linux -- PulseAudio/PipeWire, ALSA или JACK;
# системные библиотеки подгружаются при запуске.
add_library(miniaudio STATIC "${SV_ROOT}/src/platform/miniaudio_impl.c")
target_include_directories(miniaudio PUBLIC "${SV_ROOT}/vendor/miniaudio")
if(MSVC)
    target_compile_options(miniaudio PRIVATE /O2 /W1)
    target_compile_definitions(miniaudio PRIVATE _CRT_SECURE_NO_WARNINGS)
else()
    target_compile_options(miniaudio PRIVATE -O2 -w)
endif()
if(NOT WIN32)
    find_package(Threads REQUIRED)
    target_link_libraries(miniaudio PUBLIC Threads::Threads ${CMAKE_DL_LIBS} m)
endif()

# -------------------------------------------------------------- исходники
file(GLOB_RECURSE sv_compile CONFIGURE_DEPENDS "${SV_ROOT}/src/*.cpp")

# ----------------------------------------------------------------- SV
# Всё, кроме главной программы, -- библиотека sv_core: с ней собираются и
# SV, и тесты.
set(sv_main "${SV_ROOT}/src/sv/main.cpp")
set(sv_core_compile ${sv_compile})
list(REMOVE_ITEM sv_core_compile "${sv_main}")
add_library(sv_core STATIC ${sv_core_compile})
target_include_directories(sv_core PUBLIC "${SV_ROOT}/src" "${SV_ROOT}/build")
target_link_libraries(sv_core PUBLIC newfon_core miniaudio)

# Отладка речи: всё, что уходит синтезатору, пишется (UTF-8) в файл из
# переменной окружения SV_SPEECH_LOG. Для сравнения речи двух сборок.
option(SV_SPEECH_TRACE "log speech to $SV_SPEECH_LOG" OFF)
if(SV_SPEECH_TRACE)
    target_compile_definitions(sv_core PUBLIC SV_SPEECH_TRACE)
endif()

if(MSVC)
    # /utf-8 -- кодировка исходников и строковых литералов.
    target_compile_options(sv_core PUBLIC
        $<$<COMPILE_LANGUAGE:CXX>:/W3>
        $<$<COMPILE_LANGUAGE:CXX>:/utf-8>
        $<$<COMPILE_LANGUAGE:CXX>:/permissive->
        $<$<COMPILE_LANGUAGE:CXX>:/Zc:__cplusplus>
        $<$<COMPILE_LANGUAGE:CXX>:/wd4996>)
    target_compile_definitions(sv_core PUBLIC _CRT_SECURE_NO_WARNINGS NOMINMAX UNICODE _UNICODE)
else()
    target_compile_options(sv_core PUBLIC
        $<$<COMPILE_LANGUAGE:CXX>:-Wall>
        $<$<COMPILE_LANGUAGE:CXX>:-Wextra>
        $<$<COMPILE_LANGUAGE:CXX>:-Wno-unused-parameter>)
endif()

if(WIN32)
    target_compile_definitions(sv_core PUBLIC UNICODE _UNICODE NOMINMAX)
    target_link_libraries(sv_core PUBLIC shell32)
else()
    find_package(Threads REQUIRED)
    target_link_libraries(sv_core PUBLIC Threads::Threads ${CMAKE_DL_LIBS})
endif()

# Как собирать исполняемые файлы (SV и тесты).
function(sv_executable target)
    target_link_libraries(${target} PRIVATE sv_core)
    if(WIN32 AND NOT MSVC AND NOT SV_SANITIZE)
        target_link_options(${target} PRIVATE -static -s)
    elseif(NOT WIN32 AND NOT SV_SANITIZE)
        target_link_options(${target} PRIVATE -s)
    endif()
endfunction()

if(WIN32)
    set(sv_rc "${SV_ROOT}/res/sv.rc")
    set_source_files_properties("${sv_rc}" PROPERTIES INCLUDE_DIRECTORIES "${SV_ROOT}/build")
else()
    set(sv_rc)
endif()
add_executable(SV "${sv_main}" ${sv_rc})
sv_executable(SV)
set_target_properties(SV PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${SV_OUT}/$<0:>")

# ------------------------------------------------------------- развёртка
# Рядом с программой -- то, без чего она не работает, и помощники
# распаковки архивов и fb2 для своей ОС (runtime/windows, runtime/linux).
# SV.CFG, SV.INI и SV.DCL -- настройки пользователя: уже лежащие не
# затираются.
if(WIN32)
    set(sv_platform windows)
else()
    set(sv_platform linux)
endif()
add_custom_target(deploy ALL
    COMMAND ${CMAKE_COMMAND} -DSRC=${SV_ROOT}/runtime -DPLATFORM=${sv_platform} -DDST=${SV_OUT}
            -P "${SV_ROOT}/cmake/deploy.cmake"
    COMMENT "deploy runtime data"
    VERBATIM)

# ------------------------------------------------------------------ тесты
enable_testing()
file(GLOB test_sources CONFIGURE_DEPENDS "${SV_ROOT}/tests/*.cpp")
set(test_targets)
foreach(source ${test_sources})
    get_filename_component(name "${source}" NAME_WE)
    add_executable(${name} EXCLUDE_FROM_ALL "${source}")
    sv_executable(${name})
    set_target_properties(${name} PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests/$<0:>")
    add_test(NAME ${name} COMMAND ${name} "${SV_OUT}")
    list(APPEND test_targets ${name})
endforeach()
add_custom_target(check
    COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure -C $<CONFIG> --test-dir "${CMAKE_BINARY_DIR}"
    DEPENDS ${test_targets} SV deploy
    COMMENT "tests (${SV_ARCH})"
    USES_TERMINAL)
