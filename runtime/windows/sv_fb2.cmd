@echo off
rem ---------------------------------------------------------------------
rem  sv_fb2.cmd -- kniga fb2 dlya SV. Stroka SV.DCL:
rem      fb2:  "$SV\sv_fb2.cmd" "<Archive>" "<Directory>"
rem  %1 -- kniga .fb2, %2 -- vremennyy katalog.
rem
rem  Konverter pishet .txt ryadom s knigoy, poetomu kniga snachala
rem  kopiruetsya vo vremennyy katalog: original ne trogaem.
rem ---------------------------------------------------------------------
setlocal
set "HERE=%~dp0"
set "SRC=%~1"
set "DST=%~2"
if "%SRC%"=="" exit /b 1
if "%DST%"=="" exit /b 1
if not exist "%SRC%" exit /b 1
if not exist "%DST%" mkdir "%DST%" >nul 2>&1

copy /y "%SRC%" "%DST%\" >nul 2>&1
for %%F in ("%DST%\*.fb2") do (
  "%HERE%fb2\fb2_to_txt.exe" "%%F" >nul 2>&1
  if exist "%%~dpnF.txt" del /q "%%F" >nul 2>&1
)
for %%B in ("%DST%\*.bookmania") do del /q "%%B" >nul 2>&1

endlocal
exit /b 0
