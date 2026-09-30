@echo off
rem ===========================================================================
rem  build_x86.bat -- сборка 32-разрядного пакета Speaking Viewer (SV) 4.0.
rem
rem    build_x86.bat [-b mingw^|msvs] [keep]
rem
rem    -b mingw   llvm-mingw (clang) -- так собирается, если ключа нет;
rem    -b msvs    Visual Studio (MSVC), самая новая из установленных;
rem    keep       не удалять дерево сборки obj\ (следующая сборка быстрее).
rem
rem  Запускать сборку человеку проще всего так, а не вызовом cmake напрямую:
rem  этот файл находит инструменты, зовёт cmake/build.cmake и в любом случае
rem  -- и при ошибке, и при успехе -- заканчивается командой pause. Если сборка
rem  упала, окно не закроется само и видно будет, на каком шаге и с какой
rem  ошибкой. Если прошла -- показывается номер сборки и папка с результатом.
rem ===========================================================================
setlocal EnableExtensions
cd /d "%~dp0"

set "SV_TOOLCHAIN=mingw"
set "SV_ARGS=%*"
:args
if "%~1"=="" goto :args_done
if /i "%~1"=="-b" (
  set "SV_TOOLCHAIN=%~2"
  shift
)
shift
goto :args
:args_done
if /i not "%SV_TOOLCHAIN%"=="mingw" if /i not "%SV_TOOLCHAIN%"=="msvs" (
  echo [ОШИБКА] Ключ -b: ожидается mingw или msvs, а не "%SV_TOOLCHAIN%".
  goto :fail
)

call "%~dp0cmake\findtools.bat" %SV_TOOLCHAIN%
if errorlevel 1 goto :fail

echo.
echo ===========================================================================
echo   SV 4.0 -- сборка x86 (%SV_TOOLCHAIN%)
echo ===========================================================================
echo.

cmake -P cmake\build.cmake x86 %SV_ARGS%
if errorlevel 1 goto :fail

set "BUILDNO="
if exist "build\BUILD_NUMBER.txt" set /p BUILDNO=<build\BUILD_NUMBER.txt

echo.
echo ===========================================================================
echo   Сборка 4.0.0.%BUILDNO% (%SV_TOOLCHAIN%) успешно завершена.
echo   Результат -- в папке build\x86\
echo ===========================================================================
echo.
pause
endlocal
exit /b 0

:fail
echo.
echo ===========================================================================
echo   [ОШИБКА] Сборка не завершена. Прочтите сообщения выше -- в них указано,
echo            на каком шаге и с какой ошибкой она остановилась.
echo ===========================================================================
echo.
pause
endlocal
exit /b 1
