@echo off
rem ---------------------------------------------------------------------
rem  Sborka SV  (Speaking Viewer, versiya ot 2015-02-03)
rem
rem  build.bat          - sobrat vse: yadro rechi + SV, sobrat bin\
rem  build.bat sv       - tolko SV
rem  build.bat newfon   - tolko newfon_core.dll
rem  build.bat clean    - ubrat rezultaty sborki
rem
rem  Trebuetsya:
rem    Free Pascal 3.2.2   winget install FreePascal.FreePascalCompiler
rem    llvm-mingw          tolko dlya peresborki yadra rechi
rem                        https://github.com/mstorsjo/llvm-mingw
rem ---------------------------------------------------------------------
setlocal enabledelayedexpansion
cd /d "%~dp0"

if /i "%~1"=="clean" (
  if exist units rmdir /s /q units
  rem  bin\ celikom NE udalyaem: tam fayly polzovatelya
  if exist bin\SV.exe del /q bin\SV.exe
  if exist newfon_core\build rmdir /s /q newfon_core\build
  echo Ochischeno. Katalog bin ne tronut.
  goto :eof
)

if /i "%~1"=="newfon" goto :newfon
if /i "%~1"=="sv"     goto :sv

:newfon
rem --------------------------- yadro rechi -----------------------------
set TRIPLE=i686-w64-mingw32
set CC=
where %TRIPLE%-clang.exe >nul 2>&1 && set CC=%TRIPLE%-clang.exe
if "%CC%"=="" (
  for /d %%D in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\MartinStorsjo.LLVM-MinGW*\llvm-mingw-*") do (
    if exist "%%D\bin\%TRIPLE%-clang.exe" set "CC=%%D\bin\%TRIPLE%-clang.exe"
  )
)
if "%CC%"=="" (
  echo llvm-mingw ne nayden - propuskayu peresborku yadra.
  if exist "%~dp0bin\newfon_core.dll" echo Ispolzuyu uzhe sobrannuyu bin\newfon_core.dll
  if /i "%~1"=="newfon" exit /b 1
  goto :sv
)

set NSRC=%~dp0newfon_core\src
set NINC=%~dp0newfon_core\include
set NOUT=%~dp0newfon_core\build
if not exist "%NOUT%" mkdir "%NOUT%"
set CFLAGS=-Wall -Wextra -Werror -Wno-unused-parameter -Wno-sign-compare -O3 -I"%NINC%" -I"%NSRC%"
set NUNITS=female intonator male numerics sink soundproducer speechrate_control synth text2speech time_planner transcription utterance voices
set NOBJS=
echo --- newfon_core.dll
for %%U in (%NUNITS%) do (
  "%CC%" %CFLAGS% -o "%NOUT%\%%U.o" -c "%NSRC%\%%U.c" || exit /b 1
  set NOBJS=!NOBJS! "%NOUT%\%%U.o"
)
"%CC%" -shared -o "%NOUT%\newfon_core.dll" !NOBJS! || exit /b 1
if /i "%~1"=="newfon" (
  echo Gotovo: %NOUT%\newfon_core.dll
  goto :eof
)

:sv
rem ------------------------------- SV ----------------------------------
set FPC=C:\FPC\3.2.2\bin\i386-win32\fpc.exe
if not exist "%FPC%" (
  for /d %%D in ("C:\FPC\*") do if exist "%%D\bin\i386-win32\fpc.exe" set "FPC=%%D\bin\i386-win32\fpc.exe"
)
if not exist "%FPC%" (
  echo NE NAYDEN Free Pascal.
  echo Ustanovite: winget install FreePascal.FreePascalCompiler
  exit /b 1
)

if not exist units mkdir units
if not exist bin   mkdir bin

rem  -Mtp             rezhim Turbo Pascal, kak u avtora
rem  -dFonOn -dSpOn   bez nih ne sobiraetsya SDRVPRIM
echo --- SV.exe
"%FPC%" -TWin32 -Mtp -Sg -Si -Sa -dFonOn -dSpOn ^
        -FuSV -FuTPU/EXTERN -FuTPU/MY -FuTPU/SAPRIN -FuTPU/SPV -FuTPU/ss ^
        -FUunits -FEbin SV/SV.PAS
if errorlevel 1 exit /b 1

rem --- sobrat rabochiy katalog ---
rem  Kopiruem tolko to, chego v bin escho net:  SV.DCL i SV.INI
rem  polzovatel nastraivaet pod sebya, zatirat ih nelzya.
for %%F in (runtime\*.*) do if not exist "bin\%%~nxF" copy /y "%%F" bin\ >nul
if exist newfon_core\build\newfon_core.dll copy /y newfon_core\build\newfon_core.dll bin\ >nul

echo.
echo Gotovo. Zapusk:  bin\SV.exe [fayl]
endlocal
