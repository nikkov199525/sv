// keyboard.h -- чтение клавиатуры (KEYB.PAS).

#ifndef SV_UI_KEYBOARD_H
#define SV_UI_KEYBOARD_H

#include "platform/console.h"
#include "ui/keys.h"

#include <cstdint>

namespace ui {

struct KeyInput {
    int code;       // код клавиши (keys.h)
    char32_t ch;    // символ; 0 -- служебная клавиша
};

// Ждать клавишу; пока ждёт -- идут часы. Модификаторы нажатия
// запоминаются для Ctrl, Alt, Shift и Only*. Нажатая кнопка мыши -- код
// key::Mouse.
KeyInput ReadKey();
inline int DefineKey() {
    return ReadKey().code;
}
// Нажата клавиша (или кнопка мыши)?
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

// Мышь: «Использовать мышь» в настройках. Кнопки -- биты console::kMouse*.
void EnableMouse(bool on);
bool MouseEnabled();
// Кнопки нажатия, которое ReadKey вернул кодом key::Mouse (забираются).
uint8_t TakeMouseButtons();
// Кнопки, нажатые после того (для двойного щелчка; забираются).
uint8_t TakeMousePresses();
// Нажатые сейчас кнопки и клетка указателя (с единицы).
console::MouseState MouseNow();
// Сдвиг указателя на другую клетку ReadKey возвращает кодом key::MouseMove
// (меню выбирают пункт указателем).
void SetMouseMoveIsKey(bool on);
// После нажатия кнопки: был ли двойной щелчок -- та же кнопка нажата ещё
// раз (до отпускания первой или в течение 0,3 с после). Ждёт, пока кнопку
// отпустят.
bool DoubleClick(uint8_t button);
// Нажатие мыши -- клавишей, как в диалогах автора: левая -- Enter,
// средняя -- F1, правая -- Esc.
int MouseAsKey();

} // namespace ui

#endif
