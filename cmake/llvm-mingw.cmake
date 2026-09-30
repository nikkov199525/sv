# llvm-mingw.cmake -- общая часть toolchain-файлов (toolchain-x86.cmake,
# toolchain-x64.cmake).
#
# Тулчейн -- llvm-mingw (clang + ucrt), кросс-компиляторы вида
# <триплет>-clang. Если их нет в PATH, они ищутся там, куда их ставит
# `winget install MartinStorsjo.LLVM-MinGW.UCRT`, или в папке из переменной
# окружения LLVMMINGW. Там же лежит mingw32-make -- его зовёт генератор
# «MinGW Makefiles».

set(CMAKE_SYSTEM_NAME Windows)

set(_sv_hints "")
if(DEFINED ENV{LLVMMINGW})
    list(APPEND _sv_hints "$ENV{LLVMMINGW}")
endif()
if(DEFINED ENV{LOCALAPPDATA})
    file(TO_CMAKE_PATH "$ENV{LOCALAPPDATA}" _sv_local)
    file(GLOB _sv_winget LIST_DIRECTORIES true
         "${_sv_local}/Microsoft/WinGet/Packages/MartinStorsjo.LLVM-MinGW*/llvm-mingw-*/bin")
    list(APPEND _sv_hints ${_sv_winget})
endif()

find_program(SV_CLANG ${SV_TRIPLE}-clang HINTS ${_sv_hints} REQUIRED)
get_filename_component(SV_LLVM_MINGW_BIN "${SV_CLANG}" DIRECTORY)

set(CMAKE_C_COMPILER   "${SV_LLVM_MINGW_BIN}/${SV_TRIPLE}-clang.exe")
set(CMAKE_CXX_COMPILER "${SV_LLVM_MINGW_BIN}/${SV_TRIPLE}-clang++.exe")
set(CMAKE_RC_COMPILER  "${SV_LLVM_MINGW_BIN}/${SV_TRIPLE}-windres.exe")
set(CMAKE_AR           "${SV_LLVM_MINGW_BIN}/llvm-ar.exe" CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB       "${SV_LLVM_MINGW_BIN}/llvm-ranlib.exe" CACHE FILEPATH "" FORCE)
if(NOT CMAKE_MAKE_PROGRAM AND EXISTS "${SV_LLVM_MINGW_BIN}/mingw32-make.exe")
    set(CMAKE_MAKE_PROGRAM "${SV_LLVM_MINGW_BIN}/mingw32-make.exe" CACHE FILEPATH "" FORCE)
endif()

# Искать библиотеки и заголовки только у тулчейна и в своих зависимостях, а
# не в системе сборки: иначе find_package у libxml2 подцепил бы чужой zlib.
set(CMAKE_FIND_ROOT_PATH "${SV_LLVM_MINGW_BIN}/../${SV_TRIPLE}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
