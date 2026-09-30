// keyboard.h -- чтение клавиатуры (KEYB.PAS).

#ifndef SV_UI_KEYBOARD_H
#define SV_UI_KEYBOARD_H

#include "ui/keys.h"

namespace ui {

struct KeyInput {
    int code;       // код клавиши (keys.h)
    char32_t ch;    // символ; 0 -- служебная клавиша
};

// Ждать клавишу; пока ждёт -- идут часы. Модификаторы нажатия
// запоминаются для Ctrl, Alt, Shift и Only*.
KeyInput ReadKey();
inline int DefineKey() {
    return ReadKey().code;
}
bool KeyPressed();
void ClearBuffer();
// Немного подождать, не занимая процессор.
void Idle();

// Одиночный Alt возвращается кодом 0 (быстрый поиск в диалоге файлов).
void SetAltAloneIsKey(bool on);

// Модификаторы последней клавиши. Проверка «забирает» свой модификатор:
// вторая проверка того же после одного нажатия вернёт false. На этом
// построены Only*: OnlyCtrl -- нажат Ctrl, а Alt и Shift -- нет.
bool Ctrl();
bool Alt();
bool Shift();
bool OnlyCtrl();
bool OnlyAlt();
bool OnlyShift();

} // namespace ui

#endif
