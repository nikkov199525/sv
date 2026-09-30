@echo off
rem ---------------------------------------------------------------------
rem  sv_arc.cmd -- raspakovka arhiva dlya SV. Stroka SV.DCL:
rem      zip:  "$SV\sv_arc.cmd" "<Archive>" "<Directory>"
rem  %1 -- arhiv, %2 -- katalog, kuda raspakovat.
rem
rem  1) arhiv raspakovyvaet 7-Zip (archivers\7z.exe: zip, rar, 7z, arj,
rem     lzh, cab, tar, gz i dr.);
rem  2) vlozhennye arhivy, v kotoryh est fb2 ili txt, raspakovyvayutsya
rem     tozhe (odin uroven);
rem  3) knigi fb2 prevraschayutsya v tekst (fb2\fb2_to_txt.exe);
rem  4) vse, chto SV umeet chitat, sobiraetsya v koren kataloga, ostalnoe
rem     udalyaetsya: SV pokazhet ploskiy spisok, a edinstvennyy fayl
rem     otkroet srazu.
rem ---------------------------------------------------------------------
setlocal
set "HERE=%~dp0"
set "Z=%HERE%archivers\7z.exe"
set "F2T=%HERE%fb2\fb2_to_txt.exe"
set "ARC=%~1"
set "DST=%~2"
if "%ARC%"=="" exit /b 1
if "%DST%"=="" exit /b 1
if not exist "%ARC%" exit /b 1
if not exist "%DST%" mkdir "%DST%" >nul 2>&1

rem --- 1. arhiv ---
"%Z%" x -y "-o%DST%" "%ARC%" >nul 2>&1

rem --- 2. vlozhennye arhivy s fb2 ili txt ---
for /r "%DST%" %%A in (*.zip *.rar *.7z) do (
  "%Z%" l "%%A" > "%DST%\~list.tmp" 2>nul
  findstr /i /r "\.fb2 \.txt" "%DST%\~list.tmp" >nul 2>&1
  if not errorlevel 1 (
    "%Z%" x -y "-o%DST%" "%%A" >nul 2>&1
    del /q "%%A" >nul 2>&1
  )
)
if exist "%DST%\~list.tmp" del /q "%DST%\~list.tmp" >nul 2>&1

rem --- 3. fb2 -> txt ---
for /r "%DST%" %%F in (*.fb2) do (
  "%F2T%" "%%F" >nul 2>&1
  if exist "%%~dpnF.txt" del /q "%%F" >nul 2>&1
)
for /r "%DST%" %%B in (*.bookmania) do del /q "%%B" >nul 2>&1

rem --- 4. chitaemoe -- v koren, ostalnoe -- proch ---
for /r "%DST%" %%T in (*.txt *.fb2 *.doc *.htm *.html *.dbf) do (
  if /i not "%%~dpT"=="%DST%\" move /y "%%T" "%DST%\" >nul 2>&1
)
for /d %%D in ("%DST%\*") do rd /s /q "%%D" >nul 2>&1

endlocal
exit /b 0
