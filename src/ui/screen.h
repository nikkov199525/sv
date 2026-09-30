// screen.h -- экран программы (DIALOG.PAS): буфер 80x25, строки, рамки,
// цвета, курсор, часы.
//
// Координаты -- с единицы, как у автора. Всё рисуется в буфер; на экран его
// выводит Show.

#ifndef SV_UI_SCREEN_H
#define SV_UI_SCREEN_H

#include "platform/console.h"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>

namespace ui {

constexpr int kWidth = console::kWidth;
constexpr int kHeight = console::kHeight;

struct Screen {
    std::array<console::Cell, kWidth * kHeight> cells{};

    // Клетка (y, x). Проверка -- по всему массиву, а не по измерениям:
    // автор иногда пишет в 81-ю колонку, то есть в начало следующей строки.
    console::Cell& At(int y, int x);
};

// Буфер экрана (BufScreen).
extern Screen screen;

struct MenuColors {
    uint8_t active;
    uint8_t inactive;
    uint8_t frame;
    uint8_t title;
};
struct ToggleColors {
    uint8_t active_title;
    uint8_t inactive_title;
    uint8_t active;
    uint8_t inactive;
};
struct ButtonColors {
    uint8_t title;
    uint8_t active;
    uint8_t inactive;
};
struct Colors {
    uint8_t message;
    uint8_t text;
    uint8_t frame;
    MenuColors menu;
    uint8_t title;
    uint8_t error;
    uint8_t marked;
    uint8_t time;
    ToggleColors radio;
    ToggleColors check;
    ButtonColors button;
    uint8_t scale;
};

// Цвета по умолчанию и текущие.
extern const Colors kDefaultColors;
extern Colors color;

// Рамка: 1..8 -- углы и стороны, 9 -- заполнение, 10..11 -- стрелки,
// 12..16 -- стыки.
using FrameStyle = std::u32string_view;
constexpr FrameStyle kDoubleFrame = U"╔═╗║╝═╚║ ▲▼╩╠╦╣╬";
constexpr FrameStyle kSingleFrame = U"┌─┐│┘─└│ ↑↓┴├┬┤┼";
// Рамка текущих окон (меняется на время «Размер/сдвиг»).
extern FrameStyle frame_style;
// Тень под рамкой.
extern bool frame_shadow;

// Строка с позиции (x, y). Не помещается в строку экрана -- не выводится.
void PutLine(int x, int y, std::string_view text, uint8_t attr);
void PutLine(int x, int y, std::u32string_view text, uint8_t attr);
void Clear(int left, int top, int right, int bottom);
void Frame(int left, int top, int right, int bottom);
void Frame(int left, int top, int right, int bottom, FrameStyle style);
void Frame(int left, int top, int right, int bottom, FrameStyle style, uint8_t attr);
void Show();

void SetCursorXY(int x, int y);
void HideCursor();
void ShowCursor(); // курсор-подчёркивание

// Часы в правом верхнем углу: row -- строка экрана, 0 -- не показывать.
void SetClockRow(int row);
void ShowClock();

} // namespace ui

#endif
