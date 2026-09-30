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
    return static_cast<bool>(console::PeekKey());
}

void ClearBuffer() {
    while (console::PeekKey())
        console::TakeKey();
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
        if (KeyPressed())
            break;
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
