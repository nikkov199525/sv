# toolchain-linux-x86.cmake -- 32-разрядная сборка для Linux (build/linux-x86)
# системным компилятором с -m32 (нужны gcc-multilib или его аналог).
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR i686)
set(CMAKE_C_FLAGS_INIT "-m32")
set(CMAKE_CXX_FLAGS_INIT "-m32")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-m32")
set(SV_ARCH linux-x86 CACHE STRING "Разрядность сборки" FORCE)
