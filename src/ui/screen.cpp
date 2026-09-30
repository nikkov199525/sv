// screen.cpp -- экран программы (DIALOG.PAS, CURSOR.PAS, HRONOS.ShowCurTime).

#include "ui/screen.h"

#include "text/utf8.h"

#include <cstdio>
#include <ctime>

namespace ui {

Screen screen;

const Colors kDefaultColors = {
    0x17,                     // message
    0x1F,                     // text
    0x1F,                     // frame
    {0xB8, 0x70, 0x70, 0x70}, // menu: active, inactive, frame, title
    0x1F,                     // title
    0x4E,                     // error
    0x1E,                     // marked
    0x1D,                     // time
    {0x1F, 0x17, 0x1F, 0x17}, // radio
    {0x1F, 0x17, 0x1F, 0x17}, // check
    {0x1F, 0xB8, 0x07},       // button: title, active, inactive
    0x70,                     // scale
};
Colors color = kDefaultColors;
FrameStyle frame_style = kDoubleFrame;
bool frame_shadow = true;

namespace {

int clock_row = 0;
std::string last_clock;

// Управляющие коды экран DOS показывал значками.
char32_t Glyph(char32_t c) {
    static constexpr char32_t glyphs[32] = {
        U' ', U'☺', U'☻', U'♥', U'♦', U'♣', U'♠', U'•', U'◘', U'○', U'◙', U'♂', U'♀', U'♪', U'♫', U'☼',
        U'►', U'◄', U'↕', U'‼', U'¶', U'§', U'▬', U'↨', U'↑', U'↓', U'→', U'←', U'∟', U'↔', U'▲', U'▼',
    };
    if (c < 32)
        return glyphs[c];
    return c == 0x7F ? U'⌂' : c;
}

} // namespace

console::Cell& Screen::At(int y, int x) {
    const int index = (y - 1) * kWidth + (x - 1);
    if (index < 0 || index >= kWidth * kHeight) {
        static console::Cell dummy;
        return dummy;
    }
    return cells[index];
}

void PutLine(int x, int y, std::u32string_view text, uint8_t attr) {
    if (x == 0 || x + static_cast<int>(text.size()) > kWidth + 1 || y == 0 || y > kHeight)
        return;
    for (size_t i = 0; i < text.size(); i++)
        screen.At(y, x + static_cast<int>(i)) = {Glyph(text[i]), attr};
}

void PutLine(int x, int y, std::string_view text, uint8_t attr) {
    PutLine(x, y, utf8::Decode(text), attr);
}

void Clear(int left, int top, int right, int bottom) {
    for (int y = top; y <= bottom; y++)
        PutLine(left, y, std::u32string(right - left + 1, U' '), color.text);
}

void Frame(int l, int t, int r, int b) {
    const FrameStyle& s = frame_style;
    if (s.find_first_not_of(U' ') == FrameStyle::npos)
        return;
    const int inner = r - l - 1;
    auto line = [&](char32_t left, char32_t fill, char32_t right) {
        return left + std::u32string(inner > 0 ? inner : 0, fill) + right;
    };
    PutLine(l, t, line(s[0], s[1], s[2]), color.frame);
    for (int y = t + 1; y < b; y++)
        if (s[8] == U' ') {
            PutLine(l, y, std::u32string(1, s[7]), color.frame);
            PutLine(r, y, std::u32string(1, s[3]), color.frame);
        } else
            PutLine(l, y, line(s[7], s[8], s[3]), color.frame);
    PutLine(l, b, line(s[6], s[5], s[4]), color.frame);
    if (frame_shadow && r < kWidth && b < kHeight) {
        for (int i = 1; i <= r - l + 1; i++)
            screen.At(b + 1, l + 1 + i).attr = 0;
        for (int y = t + 1; y <= b; y++) {
            screen.At(y, r + 1).attr = 0;
            screen.At(y, r + 2).attr = 0;
        }
    }
}

void Frame(int l, int t, int r, int b, FrameStyle style) {
    const FrameStyle saved = frame_style;
    frame_style = style;
    Frame(l, t, r, b);
    frame_style = saved;
}

void Frame(int l, int t, int r, int b, FrameStyle style, uint8_t attr) {
    const uint8_t saved = color.frame;
    color.frame = attr;
    Frame(l, t, r, b, style);
    color.frame = saved;
}

void Show() {
    console::UpdateScreen(screen.cells.data());
}

void SetCursorXY(int x, int y) {
    console::SetCursorPos(x - 1, y - 1);
}

void HideCursor() {
    console::SetCursor(console::Cursor::Hidden);
}

void ShowCursor() {
    console::SetCursor(console::Cursor::Underline);
}

void SetClockRow(int row) {
    clock_row = row;
}

void ShowClock() {
    if (clock_row == 0)
        return;
    const std::time_t now = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &now);
#else
    localtime_r(&now, &local);
#endif
    char text[16];
    std::snprintf(text, sizeof text, "%02d:%02d:%02d", local.tm_hour, local.tm_min, local.tm_sec);
    if (last_clock != text) {
        PutLine(70, clock_row, std::string(" ") + text + " ", color.time);
        Show();
        last_clock = text;
    }
}

} // namespace ui
