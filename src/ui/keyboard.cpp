// keyboard.cpp -- KEYB.PAS.

#include "ui/keyboard.h"

#include "platform/console.h"
#include "ui/screen.h"

#include <chrono>
#include <thread>

namespace ui {

namespace {

uint8_t modifiers = 0;
bool alt_alone_is_key = false;
bool mouse_on = false;
bool mouse_move_is_key = false;
uint8_t mouse_buttons = 0;   // кнопки последнего key::Mouse
int mouse_cell = -1;         // клетка указателя при прошлом key::MouseMove

// Указатель на другой клетке, чем в прошлый раз?
bool MouseMoved() {
    if (!mouse_on || !mouse_move_is_key)
        return false;
    const console::MouseState m = console::GetMouse();
    return m.y * kWidth + m.x != mouse_cell;
}

bool Take(uint8_t bit) {
    const bool pressed = modifiers & bit;
    modifiers &= ~bit;
    return pressed;
}

} // namespace

void Idle() {
    std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

bool KeyPressed() {
    return console::PeekKey() || (mouse_on && console::MousePressPending()) || MouseMoved();
}

void ClearBuffer() {
    while (console::PeekKey())
        console::TakeKey();
    console::TakeMousePresses();
}

void EnableMouse(bool on) {
    mouse_on = on;
    console::EnableMouse(on);
}

bool MouseEnabled() {
    return mouse_on;
}

uint8_t TakeMouseButtons() {
    const uint8_t buttons = mouse_buttons;
    mouse_buttons = 0;
    return buttons;
}

uint8_t TakeMousePresses() {
    return mouse_on ? console::TakeMousePresses() : 0;
}

console::MouseState MouseNow() {
    console::MouseState m = console::GetMouse();
    m.x++;
    m.y++;
    return m;
}

void SetMouseMoveIsKey(bool on) {
    mouse_move_is_key = on;
    const console::MouseState m = console::GetMouse();
    mouse_cell = m.y * kWidth + m.x;
}

bool DoubleClick(uint8_t button) {
    using namespace std::chrono;
    bool twice = false;
    // События мыши разбираются пачкой: второе нажатие может прийти раньше,
    // чем программа увидит отпускание первого.
    while (!twice && (console::GetMouse().buttons & button)) {
        twice = (console::TakeMousePresses() & button) != 0;
        if (!twice)
            Idle();
    }
    for (const auto until = steady_clock::now() + milliseconds(300);
         !twice && steady_clock::now() < until && !console::PeekKey();) {
        twice = (console::TakeMousePresses() & button) != 0;
        if (!twice)
            Idle();
    }
    while (console::GetMouse().buttons & button)
        Idle();
    console::TakeMousePresses();
    return twice;
}

int MouseAsKey() {
    const uint8_t buttons = TakeMouseButtons();
    if (buttons & console::kMouseLeft)
        return key::Enter;
    if (buttons & console::kMouseMiddle)
        return key::F1;
    if (buttons & console::kMouseRight)
        return key::Esc;
    return 0;
}

void SetAltAloneIsKey(bool on) {
    alt_alone_is_key = on;
}

KeyInput ReadKey() {
    bool alt_alone = false;
    for (;;) {
        ShowClock();
        while (alt_alone_is_key && (console::ShiftState() & console::kAlt) && !KeyPressed()) {
            alt_alone = true;
            Idle();
        }
        if (alt_alone && !KeyPressed()) {
            modifiers = console::ShiftState() | console::kAlt;
            return {0, 0};
        }
        if (console::PeekKey())
            break;
        if (mouse_on) {
            if (const uint8_t presses = console::TakeMousePresses()) {
                mouse_buttons = presses;
                modifiers = console::ShiftState();
                return {key::Mouse, 0};
            }
            if (MouseMoved()) {
                const console::MouseState m = console::GetMouse();
                mouse_cell = m.y * kWidth + m.x;
                return {key::MouseMove, 0};
            }
        }
        Idle();
    }
    // Модификаторы -- те, что были при нажатии (у Linux их иначе не узнать).
    const console::KeyEvent event = console::TakeKey();
    modifiers = event.mods | console::ShiftState();
    if (event.ch)
        return {static_cast<int>(event.ch), event.ch};
    return {-static_cast<int>(event.scan), 0};
}

bool Ctrl() {
    return Take(console::kCtrl);
}

bool Alt() {
    return Take(console::kAlt);
}

bool Shift() {
    // правый и левый -- по очереди, как «RShift or LShift» с $B-
    return Take(console::kRightShift) || Take(console::kLeftShift);
}

bool OnlyCtrl() {
    return Ctrl() && !Alt() && !Shift();
}

bool OnlyAlt() {
    return !Ctrl() && Alt() && !Shift();
}

bool OnlyShift() {
    return !Ctrl() && !Alt() && Shift();
}

} // namespace ui
