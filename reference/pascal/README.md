# SV — Speaking Viewer

Говорящая программа чтения текстов неограниченного размера для незрячих.
Автор — Довыденков Владимир (Новосибирск), при участии Саприна С. Г.,
Сысолятина П. и Картавцева С.

Здесь лежат исходники последней версии — той самой, что собрана автором
**2015-02-03**. Речевое ядро заменено на
[newfon_core](https://github.com/nikkov199525/newfon_core); всё остальное
авторское и не тронуто.

## Сборка

```
winget install FreePascal.FreePascalCompiler
build.bat
```

Результат — `bin\SV.exe` вместе со всем, что нужно для запуска.

| Команда | Что делает |
|---|---|
| `build.bat` | собрать всё: ядро речи, `SV.exe`, разложить `bin\` |
| `build.bat sv` | только `SV.exe` |
| `build.bat newfon` | только `newfon_core.dll` |
| `build.bat clean` | убрать результаты сборки |

Для пересборки речевого ядра нужен [llvm-mingw](https://github.com/mstorsjo/llvm-mingw)
(вариант ucrt-x86_64). Если его нет, скрипт пропустит этот шаг и возьмёт
уже собранную `bin\newfon_core.dll`.

Ключи компиляции взяты из авторского `fp.cfg`: `-TWin32 -Mtp -Sg -Si -Sa`.
Обязательны **`-dFonOn -dSpOn`** — без них не собирается `SDRVPRIM.PAS`,
вся его реализация стоит за `{$IfDef FonOn}`.

## Что где лежит

```
SV\           программа: SV.PAS и модули E_U, M_U, P_U, S_U, V_U
              SV.RC / SV.RES / SV.ICO — ресурс с иконкой
              HLP\ — исходники справки, собираются своим SV_HLP.BAT
TPU\MY\       модули автора: DIALOG, KEYB, LINE, FF, HELP, TABLES,
              TRANSFRM, HARDDISK, HRONOS, HTMTRANS, DINAMIC, MYMATH,
              VARIOUS, ff_win, SPEECH, NEWFON
TPU\EXTERN\   SAYFORM, SPICK (+SNAMKEY1), INTER, MUSEFECT, WORDCONV
TPU\SAPRIN\   DISCS, ZELLER
TPU\SPV\      CURSOR
TPU\ss\       MEM (+mem_Dsk, mem_Hea, MEMDRV), SDRVPRIM (+INC),
              music, sdrvxpapi
newfon_core\  исходники речевого ядра
runtime\      SV.CFG, SV.DCL, SV.INI, SV.HLP, music.dll
```

`SV\STARTER.PAS` — старый DOS-загрузчик. В сборку Win32 не входит,
оставлен как часть авторского комплекта.

## Речь

Единственное изменённое место — `TPU\MY\SPEECH.PAS`. Авторский оригинал
лежит рядом как `SPEECH.PAS.author`. Заменены только обращения к движку;
вся логика — чистка псевдографики, разрезание длинных строк, чтение
названий символов из `speech.sym`, авторские сокращения, `Say_Date`,
`Say_Time` — осталась как была.

`TPU\MY\NEWFON.PAS` — новый драйверный слой, встал на место связки
`SPICK` + `SDRVPRIM`. Ядро грузится динамически: нет `newfon_core.dll` —
программа работает молча, как работала при ненайденном драйвере речи.

Подробности соответствия параметров — в [NEWFON.md](NEWFON.md).

## Что убрано из этой папки

По сравнению с исходным архивом здесь нет: резервных копий `.bak`/`.orig`,
готовых `.ppu`/`.o`, дельфийского демо-проекта `Win2kApp`, каталогов
`test`, `test_fpc`, `distr`, `output`, копии `rtl-console` (в сборке
не участвует — авторский `fp.cfg` на неё не ссылается) и не используемых
модулей `XINTER`, `LINES`, `SPVUNIT`, `most_recent_caller`.

Всё это осталось в архивах `..\sv32.zip` и `..\SV_old_sources.7z`.
