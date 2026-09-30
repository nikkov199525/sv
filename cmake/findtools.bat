@echo off
rem ===========================================================================
rem  cmake\findtools.bat mingw^|msvs -- поиск инструментов сборки.
rem  Подключается из build_*.bat через call и при необходимости дополняет
rem  %PATH%.
rem
rem  Что требуется (всё бесплатное):
rem    * CMake 3.25 или новее               winget install Kitware.CMake
rem    * для -b mingw: llvm-mingw, вариант ucrt-x86_64
rem                                         winget install MartinStorsjo.LLVM-MinGW.UCRT
rem      (кросс-компиляторы i686-w64-mingw32-clang и x86_64-w64-mingw32-clang
rem      и mingw32-make, которым CMake ведёт сборку). Если llvm-mingw
rem      установлен не через winget, укажите папку bin в переменной LLVMMINGW;
rem    * для -b msvs: Visual Studio 2022 или новее с нагрузкой
rem      "Разработка классических приложений на C++".
rem ===========================================================================

where cmake.exe >nul 2>&1
if errorlevel 1 if exist "%ProgramFiles%\CMake\bin\cmake.exe" set "PATH=%ProgramFiles%\CMake\bin;%PATH%"
where cmake.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Не найден CMake.
  echo         winget install Kitware.CMake
  exit /b 1
)

if /i "%~1"=="msvs" goto :msvs

if not "%LLVMMINGW%"=="" set "PATH=%LLVMMINGW%;%PATH%"
where i686-w64-mingw32-clang.exe >nul 2>&1
if not errorlevel 1 goto :have_clang
for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\MartinStorsjo.LLVM-MinGW*") do (
  for /d %%E in ("%%~fD\llvm-mingw-*") do (
    if exist "%%~fE\bin\i686-w64-mingw32-clang.exe" set "PATH=%%~fE\bin;%PATH%"
  )
)

:have_clang
where i686-w64-mingw32-clang.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Не найден llvm-mingw ^(i686-w64-mingw32-clang^).
  echo         winget install MartinStorsjo.LLVM-MinGW.UCRT
  echo         либо укажите папку bin в переменной LLVMMINGW.
  exit /b 1
)
where x86_64-w64-mingw32-clang.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] llvm-mingw найден, но без 64-разрядного драйвера
  echo         ^(x86_64-w64-mingw32-clang^). Нужен вариант ucrt-x86_64.
  exit /b 1
)
where mingw32-make.exe >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Не найден mingw32-make ^(поставляется вместе с llvm-mingw^).
  exit /b 1
)
exit /b 0

:msvs
rem  Visual Studio ищется её же программой vswhere: нужна установка с
rem  компилятором C++ ^(VC.Tools^). Окружение разработчика ^(vcvars^) не
rem  нужно -- генератор Visual Studio в CMake находит всё сам.
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto :no_vs
set "SV_VS="
for /f "usebackq delims=" %%P in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "SV_VS=%%P"
if "%SV_VS%"=="" goto :no_vs
exit /b 0

:no_vs
echo [ERROR] Не найдена Visual Studio с компилятором C++.
echo         Установите Visual Studio 2022 или новее с нагрузкой
echo         "Разработка классических приложений на C++".
exit /b 1
