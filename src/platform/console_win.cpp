// console_win.cpp -- console.h для консоли Windows.
//
// Экран -- собственный буфер консоли размером 80x25: прежнее содержимое окна
// при выходе возвращается. Вывод -- WriteConsoleOutputW, поэтому кодовая
// страница консоли не важна.

#ifdef _WIN32

#include "platform/console.h"
#include "platform/keymap.h"

#include <windows.h>

#include <array>
#include <deque>

namespace console {

namespace {

HANDLE out_original = INVALID_HANDLE_VALUE;
HANDLE out_screen = INVALID_HANDLE_VALUE;
HANDLE input = INVALID_HANDLE_VALUE;
DWORD input_mode_saved = 0;
bool video_on = false;
bool keyboard_on = false;
Cursor cursor_type = Cursor::Underline;
std::deque<KeyEvent> queue;
uint8_t shift_state = 0;

uint8_t ModifiersOf(DWORD state) {
    uint8_t mods = 0;
    if (state & SHIFT_PRESSED)
        mods |= kLeftShift;
    if (state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED))
        mods |= kCtrl;
    if (state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED))
        mods |= kAlt;
    return mods;
}

KeyEvent Translate(const KEY_EVENT_RECORD& key, char32_t ch) {
    using namespace keymap;
    const WORD vk = key.wVirtualKeyCode;
    const DWORD state = key.dwControlKeyState;
    const uint8_t mods = ModifiersOf(state);
    const bool alt = state & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED);
    const bool ctrl = state & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED);
    // AltGr (правый Alt + левый Ctrl) с символом -- просто символ.
    const bool altgr = (state & RIGHT_ALT_PRESSED) && (state & LEFT_CTRL_PRESSED) && ch >= 32;

    switch (vk) {
    case VK_SHIFT:
    case VK_CONTROL:
    case VK_MENU:
    case VK_CAPITAL:
    case VK_NUMLOCK:
    case VK_SCROLL:
    case VK_LWIN:
    case VK_RWIN:
    case VK_APPS:
        return {};
    }

    Special special = kNone;
    if (vk >= VK_F1 && vk <= VK_F12)
        special = static_cast<Special>(kF1 + (vk - VK_F1));
    else if (ch == 0 || (state & ENHANCED_KEY)) {
        switch (vk) {
        case VK_HOME: special = kHome; break;
        case VK_UP: special = kUp; break;
        case VK_PRIOR: special = kPgUp; break;
        case VK_LEFT: special = kLeft; break;
        case VK_CLEAR: special = kCenter; break;
        case VK_RIGHT: special = kRight; break;
        case VK_END: special = kEnd; break;
        case VK_DOWN: special = kDown; break;
        case VK_NEXT: special = kPgDn; break;
        case VK_INSERT: special = kIns; break;
        case VK_DELETE: special = kDel; break;
        default: break;
        }
    }
    if (special != kNone)
        return MakeSpecial(special, mods);

    if (vk == VK_TAB && (state & SHIFT_PRESSED) && !ctrl && !alt)
        return MakeSpecial(kShiftTab, mods);

    if (alt && !altgr) {
        char32_t base = ch;
        if (vk >= 'A' && vk <= 'Z')
            base = U'a' + (vk - 'A');
        else if (vk >= '0' && vk <= '9')
            base = vk;
        else if (vk == VK_OEM_MINUS)
            base = U'-';
        else if (vk == VK_OEM_PLUS)
            base = U'=';
        else if (vk == VK_RETURN)
            base = 13;
        else if (vk == VK_BACK)
            base = 8;
        else if (vk == VK_ESCAPE)
            base = 27;
        else if (vk == VK_SPACE)
            base = U' ';
        else if (vk == VK_TAB)
            return {};
        else if (!base) // прочие клавиши -- по физическому коду
            return key.wVirtualScanCode ? Scan(static_cast<uint8_t>(key.wVirtualScanCode), mods)
                                        : KeyEvent{};
        return MakeAltChar(base, mods);
    }

    if (ctrl && !altgr) {
        if (!ch || ch >= 32) {
            if (vk >= 'A' && vk <= 'Z')
                ch = vk - 'A' + 1;
            else if (vk == VK_OEM_4)
                ch = 27;
            else if (vk == VK_OEM_6)
                ch = 29;
            else if (vk == VK_OEM_5)
                ch = 28;
            else if (vk == VK_RETURN)
                ch = 10;
            else if (vk == VK_BACK)
                ch = 127;
            else if (vk == VK_TAB)
                return Scan(0x94, mods);
            else if (vk == VK_SPACE)
                ch = U' ';
        }
        return ch ? Make(ch, static_cast<uint8_t>(key.wVirtualScanCode), mods) : KeyEvent{};
    }

    return ch ? Make(ch, static_cast<uint8_t>(key.wVirtualScanCode), mods) : KeyEvent{};
}

void Pump() {
    if (input == INVALID_HANDLE_VALUE)
        return;
    static char16_t high_surrogate = 0;
    for (;;) {
        DWORD count = 0;
        if (!GetNumberOfConsoleInputEvents(input, &count) || count == 0)
            return;
        INPUT_RECORD record;
        DWORD got = 0;
        if (!ReadConsoleInputW(input, &record, 1, &got) || got == 0)
            return;
        if (record.EventType != KEY_EVENT)
            continue;
        const KEY_EVENT_RECORD& key = record.Event.KeyEvent;
        shift_state = ModifiersOf(key.dwControlKeyState);
        if (!key.bKeyDown)
            continue;
        const char16_t unit = static_cast<char16_t>(key.uChar.UnicodeChar);
        if (unit >= 0xD800 && unit <= 0xDBFF) {
            high_surrogate = unit;
            continue;
        }
        char32_t ch = unit;
        if (unit >= 0xDC00 && unit <= 0xDFFF) {
            if (!high_surrogate)
                continue;
            ch = 0x10000 + ((high_surrogate - 0xD800) << 10) + (unit - 0xDC00);
        }
        high_surrogate = 0;
        const KeyEvent event = Translate(key, ch);
        if (!event)
            continue;
        for (WORD i = 0; i < (key.wRepeatCount ? key.wRepeatCount : 1); i++)
            queue.push_back(event);
    }
}

void ApplyCursor() {
    if (out_screen == INVALID_HANDLE_VALUE)
        return;
    CONSOLE_CURSOR_INFO info;
    info.bVisible = cursor_type != Cursor::Hidden;
    info.dwSize = cursor_type == Cursor::Block ? 100 : 15;
    SetConsoleCursorInfo(out_screen, &info);
}

} // namespace

void InitVideo() {
    if (video_on)
        return;
    out_original = GetStdHandle(STD_OUTPUT_HANDLE);
    out_screen = CreateConsoleScreenBuffer(GENERIC_READ | GENERIC_WRITE,
                                           FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr,
                                           CONSOLE_TEXTMODE_BUFFER, nullptr);
    if (out_screen == INVALID_HANDLE_VALUE)
        return;
    // Окно сперва сжать, потом задать буфер 80x25, потом окно по буферу.
    SMALL_RECT tiny = {0, 0, 0, 0};
    SetConsoleWindowInfo(out_screen, TRUE, &tiny);
    SetConsoleScreenBufferSize(out_screen, COORD{kWidth, kHeight});
    SMALL_RECT window = {0, 0, kWidth - 1, kHeight - 1};
    SetConsoleWindowInfo(out_screen, TRUE, &window);
    SetConsoleActiveScreenBuffer(out_screen);
    video_on = true;
    ApplyCursor();
}

void DoneVideo() {
    if (!video_on)
        return;
    video_on = false;
    if (out_original != INVALID_HANDLE_VALUE)
        SetConsoleActiveScreenBuffer(out_original);
    CloseHandle(out_screen);
    out_screen = INVALID_HANDLE_VALUE;
}

void UpdateScreen(const Cell* cells) {
    if (!video_on)
        return;
    // Одна клетка консоли -- одна единица UTF-16: символы за пределами BMP
    // показываются знаком замены.
    static std::array<CHAR_INFO, kWidth * kHeight> buffer;
    for (size_t i = 0; i < buffer.size(); i++) {
        const char32_t ch = cells[i].ch ? cells[i].ch : U' ';
        buffer[i].Char.UnicodeChar = ch <= 0xFFFF ? static_cast<WCHAR>(ch) : L'�';
        buffer[i].Attributes = cells[i].attr;
    }
    SMALL_RECT region = {0, 0, kWidth - 1, kHeight - 1};
    WriteConsoleOutputW(out_screen, buffer.data(), COORD{kWidth, kHeight}, COORD{0, 0}, &region);
}

void SetCursorPos(int x, int y) {
    if (video_on)
        SetConsoleCursorPosition(out_screen, COORD{static_cast<SHORT>(x), static_cast<SHORT>(y)});
}

void SetCursor(Cursor type) {
    cursor_type = type;
    ApplyCursor();
}

Cursor GetCursor() {
    return cursor_type;
}

void InitKeyboard() {
    if (keyboard_on)
        return;
    input = GetStdHandle(STD_INPUT_HANDLE);
    GetConsoleMode(input, &input_mode_saved);
    // Ни строкового ввода, ни эха, ни обработки Ctrl+C системой: Ctrl+C,
    // Ctrl+S и прочие -- клавиши программы. Быстрое выделение мышью
    // выключено, чтобы щелчок не останавливал вывод.
    SetConsoleMode(input, ENABLE_EXTENDED_FLAGS | ENABLE_WINDOW_INPUT);
    SetConsoleCtrlHandler(nullptr, TRUE);
    keyboard_on = true;
}

void DoneKeyboard() {
    if (!keyboard_on)
        return;
    keyboard_on = false;
    SetConsoleMode(input, input_mode_saved);
    SetConsoleCtrlHandler(nullptr, FALSE);
}

KeyEvent PeekKey() {
    Pump();
    return queue.empty() ? KeyEvent{} : queue.front();
}

KeyEvent TakeKey() {
    for (;;) {
        Pump();
        if (!queue.empty()) {
            const KeyEvent event = queue.front();
            queue.pop_front();
            return event;
        }
        WaitForSingleObject(input, 50);
    }
}

uint8_t ShiftState() {
    Pump();
    return shift_state;
}

} // namespace console

#endif
