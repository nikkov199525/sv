# toolchain-x64.cmake -- 64-разрядная сборка для Windows (build/x64).
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(SV_TRIPLE x86_64-w64-mingw32)
set(SV_ARCH x64 CACHE STRING "Разрядность сборки" FORCE)
include("${CMAKE_CURRENT_LIST_DIR}/llvm-mingw.cmake")
