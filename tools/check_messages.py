#!/usr/bin/env python3
"""check_messages.py -- все ли сообщения исходника Паскаля перенесены как есть.

Из исходников Паскаля (reference/pascal, кодировка 866) берутся строковые
литералы с русскими буквами -- вне комментариев; из исходников C++ (src,
UTF-8) -- все строковые литералы, соседние склеиваются, как у компилятора.
Каждый литерал Паскаля должен найтись среди литералов C++ байт в байт
(после перевода в одну кодировку). Недостающие печатаются; код выхода 1.
Исключения -- NOT_COMPILED (не было в собранной программе) и REMOVED
(удалено вместе с недостижимым кодом автора).

    python tools/check_messages.py
"""

import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PAS_DIRS = ["reference/pascal/SV", "reference/pascal/TPU"]
PAS_SKIP = {"STARTER.PAS"}  # отдельная программа, в SV не входит

CYR = re.compile("[А-Яа-яЁё]")

# Литералы, которых в C++ нет, потому что их не было и в собранной программе.
NOT_COMPILED = {
    "рабо+чая ": "S_U.PAS: {$ifdef debug}",
    "бэта.": "S_U.PAS: {$ifdef beta}",
    "Защищённый режим": "S_U.PAS: {$ifdef DPMI}",
    "С половиной ": "SAYFORM.PAS: константа Halves нигде не используется",
}


# Литералы, удалённые вместе с недостижимым кодом автора: причина -> литералы.
REMOVED = {
    'E_U.Translate: распаковка словаря из SV.ERD закомментирована у автора': [
        '       Не удается открыть архив словаря       ',
        '       Не удается разархивировать словарь       ',
        'неудае+тся откры+ть архи+вный фа+йл словаря+ - ',
        'неудае+тся созда+ть фа+йл словаря+ - ',
        'оши+бка при+ распако+вки словаря+.',
    ],
    'E_U.ReadOfS: процедура нигде не вызывается (Alt+O говорит текст из S_U)': [
        '\\ая\\ Пози+ция.  ',
    ],
    'S_U.Stop(1..3): остановки из-за нехватки памяти недостижимы': [
        '    Программа попыталась установить модуль управления тем типом памяти,',
        '    Программе необходим определенный минимум оперативной памяти.',
        '    Произошла ошибка при добавлении новой строки из файла в память.',
        '  Значения:',
        ' Low -  нижняя (досовская) память',
        '"  в строке',
        'Disk -  дисковая (винчестер) память',
        'High -  верхняя (EMS) память',
        'Для выполнения вызванной вами операции необходимо ',
        'Не достаточно памяти',
        'Не удается установить модуль памяти',
        'Оши+бка.  не доста+точно па+мяти.',
        'Ошибка при добавлении новой строки в память',
        'Это могло произойти из-за недостаточного количества памяти того типа, который',
        'который определен в файле инициализации  "',
        'оши+бка при+ добавле+нии строки+.',
        'оши+бка.  не удае+тся установи+ть мо+дуль па+мяти.',
        'указан в файле инициализации.',
    ],
    'V_U.Install: левый отступ GetnTextInfo всегда 0 -- вопрос не задаётся': [
        '   Левый отступ ',
        ' символов.  Удалять?   ',
    ],
    'V_U.Install: предела длины текста больше нет (строки читаются из файла)': [
        '% текста.  Продолжать?',
        'Можно загрузить только ',
    ],
    'INTER.preskey: только в речевом вводе SAYFORM, который не вызывается': [
        'Без скроллинга.',
        'Больши+е.',
        'Курсо+р.',
        'Ма+лые.',
        'Со скро+ллингом.',
        'Ци+фры.',
    ],
    'SAYFORM: дробные числа, падежи (SayRight2..6), речевой ввод (Read*), сведения о диске и ключи «пиши»/«ок» -- не вызываются': [
        ' дде+сятимилиа+рдн',
        ' дде+сятимилио+нн',
        ' де+сятиты+сячн',
        ' ми+ли+о+нн',
        ' ми+нус ',
        ' милиа+рдн',
        ' ссто+милио+нн',
        ' сстоты+сячн',
        '-це+л-ую-ых-ых- -',
        '-ых',
        '0 две+ ',
        '0 одна+ ',
        'ВО',
        'ГО',
        'Разме+р ди+ска',
        'Разме+р кла+стера ',
        'Станда+ртной па+мяти свобо+дно',
        'Стёр',
        'Теку+щий катало+г: ',
        'ая ',
        'во',
        'восемна+дцат',
        'восм',
        'восми+десят',
        'го',
        'д ам ам и ю+ ому+ у +м и+ ё+м ста+м м ста+м ё+м ',
        'двадцат',
        'двена+дцат',
        'дву',
        'девяно+ста',
        'девят',
        'девятна+дцат',
        'десят',
        'длина+ строки+',
        'ж \\минут\\а\\ы\\\\.',
        'ж молчи-деся+т-ой-ы',
        'ж молчи-со+т-ой-ы',
        'ж молчи-ты+сячн-ой-ы',
        'ж молчи-цел-ой-ы',
        'ж-деся+т-ую-ых-ых',
        'ж-со+т-ую-ых-ых',
        'ж-ты+сячн-ую-ых-ых',
        'ж-цел-ая-ых-ых',
        'ж/',
        'коне+ц подска+зки.',
        'м \\час\\\\а\\ов',
        'ми+нус',
        'миллиа+рд',
        'миллио+н',
        'на',
        'на дде+сять в сте+пени',
        'на де+сять в сте+пени',
        'на ди+ске свобо+дно',
        'назва+ния кла+виш.',
        'нет',
        'ноль',
        'нул',
        'об ',
        'оди+ннацат',
        'одн',
        'одно+й ',
        'ок',
        'п ах ах и е+ о+м е +х и+ ё+х ста+х х ста+х ё+х ',
        'пи',
        'пят',
        'пяти+десят',
        'пятна+дцат',
        'р  ов и я+ ово+ а +х и+ ё+х со+т х ста+ ё+х ',
        'сем',
        'семи+десят',
        'семна+дцат',
        'си+мвол',
        'сорока+ ',
        'ста+ ',
        'строка+ очи+щена.',
        'т ами ами ью ё+м и+м ом мя+ ью+ ьмя+ ста+ми ми ста+ми емя+ ',
        'те',
        'тр',
        'тридцат',
        'триллио+н',
        'трина+дцат',
        'ты+сяч',
        'четы+рнадцат',
        'четыр',
        'шест',
        'шести+десят',
        'шестна+дцат',
        'ых ',
    ],
    'SNAMKEY1: названия служебных клавиш и ветви Speak_On -- не вызываются': [
        'В коне+ц',
        'В нача+ло',
        'Вве+рх',
        'Вле+во',
        'Вни+з',
        'Впра+во',
        'Вста+вка',
        'Зныщэння',
        'Ливо+руч',
        'Наступна Сторинка',
        'Попэрэдня Сторинка',
        'Право+руч',
        'Страни+ца вверх',
        'Страни+ца вниз',
        'Удале+ние',
        'Укр-И',
        'Укр-ЙЭ',
        'Унызу',
        'ЭФ Чотыры',
        'ЭФ висимь',
        'ЭФ дэвъять',
        'ЭФ дэсять',
        'ЭФ одын',
        'ЭФ пъять',
        'ЭФ симь',
        'ЭФ тры',
        'ЭФ шисть',
        'Эф 1',
        'Эф 10',
        'Эф 2',
        'Эф 3',
        'Эф 4',
        'Эф 5',
        'Эф 6',
        'Эф 7',
        'Эф 8',
        'Эф 9',
        'Ээм',
        'на початок',
        'угору',
        'укинэтсь',
    ],
    'SPICK: алфавит в DOS-866 заменён свойствами символов Unicode': [
        'абвгдеїжзиў∙йклмнопрстуфхцчшщюяьАБВГДЕЇЖЗИЎ°ЙКЛМНОПРСТУФХЦЧШЩЮЯЬ',
    ],
}


def pascal_literals(text):
    """Литералы '...' вне комментариев { }, (* *), //."""
    out = []
    joined = False
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "{":
            j = text.find("}", i + 1)
            i = n if j < 0 else j + 1
        elif text.startswith("(*", i):
            j = text.find("*)", i + 2)
            i = n if j < 0 else j + 2
        elif text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif c == "'":
            s = []
            i += 1
            while i < n:
                if text[i] == "'":
                    if i + 1 < n and text[i + 1] == "'":
                        s.append("'")
                        i += 2
                        continue
                    i += 1
                    break
                s.append(text[i])
                i += 1
            lit = "".join(s)
            # 'abc'+'def' -- одна строка, как «"abc" "def"» у C++
            m = re.match(r"\s*\+\s*'", text[i:])
            if out and joined:
                out[-1] += lit
            else:
                out.append(lit)
            joined = bool(m)
            if m:
                i += m.end() - 1
        else:
            if not c.isspace():
                joined = False
            i += 1
    return out


ESC = {"n": "\n", "t": "\t", "r": "\r", "\\": "\\", '"': '"', "'": "'", "0": "\0", "?": "?"}


def cpp_literals(text):
    """Литералы "..." вне комментариев; соседние (через пробелы) склеены."""
    out = []
    i, n = 0, len(text)
    pending = None
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            i = n if j < 0 else j
            continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        if c == "'":
            # символьный литерал
            j = i + 1
            while j < n and text[j] != "'":
                j += 2 if text[j] == "\\" else 1
            body = text[i + 1:j]
            if len(body) == 1:
                out.append(body)
            if pending is not None:
                out.append(pending)
                pending = None
            i = j + 1
            continue
        if c == '"':
            s = []
            i += 1
            while i < n and text[i] != '"':
                if text[i] == "\\":
                    e = text[i + 1]
                    if e == "x":
                        m = re.match(r"[0-9A-Fa-f]{1,2}", text[i + 2:])
                        s.append(bytes([int(m.group(0), 16)]).decode("cp866"))
                        i += 2 + len(m.group(0))
                        continue
                    s.append(ESC.get(e, e))
                    i += 2
                    continue
                s.append(text[i])
                i += 1
            i += 1
            lit = "".join(s)
            pending = lit if pending is None else pending + lit
            continue
        if not c.isspace() and pending is not None:
            out.append(pending)
            pending = None
        i += 1
    if pending is not None:
        out.append(pending)
    return out


def main():
    # консоль Windows может быть не в UTF-8
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    pas = {}
    for d in PAS_DIRS:
        for dirpath, _, files in os.walk(os.path.join(ROOT, d)):
            for f in files:
                if not f.upper().endswith((".PAS", ".INC")) or f.upper() in PAS_SKIP:
                    continue
                path = os.path.join(dirpath, f)
                with open(path, "rb") as fh:
                    text = fh.read().decode("cp866")
                for lit in pascal_literals(text):
                    if CYR.search(lit):
                        pas.setdefault(lit, os.path.relpath(path, ROOT))
    cpp = set()
    for dirpath, _, files in os.walk(os.path.join(ROOT, "src")):
        for f in files:
            if f.endswith((".cpp", ".h")):
                with open(os.path.join(dirpath, f), encoding="utf-8") as fh:
                    text = fh.read()
                cpp.update(cpp_literals(text))
    removed = {lit for lits in REMOVED.values() for lit in lits}
    missing = [(src, lit) for lit, src in pas.items() if lit not in cpp and
               lit not in NOT_COMPILED and lit not in removed]
    # Удалённое не должно вернуться незамеченным: такой литерал -- снова в C++.
    for lit in sorted(removed & cpp):
        print("removed, but present in C++: %r" % lit)
    for src, lit in sorted(missing):
        print("%s: %r" % (src, lit))
    print("Pascal literals: %d, removed with unreachable code: %d, missing in C++: %d" %
          (len(pas), len(removed & set(pas)), len(missing)))
    return 1 if missing else 0


if __name__ == "__main__":
    sys.exit(main())
