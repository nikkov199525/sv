# toolchain-x86.cmake -- 32-разрядная сборка для Windows (build/x86).
set(CMAKE_SYSTEM_PROCESSOR i686)
set(SV_TRIPLE i686-w64-mingw32)
set(SV_ARCH x86 CACHE STRING "Разрядность сборки" FORCE)
include("${CMAKE_CURRENT_LIST_DIR}/llvm-mingw.cmake")
