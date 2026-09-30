// keymap.h -- перевод клавиш в коды BIOS, общий для Windows и Linux.
//
// Программа ждёт от клавиатуры ровно то, что отдавал BIOS под DOS: символ
// либо расширенный код. Таблицы ниже -- эти коды.

#ifndef SV_PLATFORM_KEYMAP_H
#define SV_PLATFORM_KEYMAP_H

#include "platform/console.h"

namespace keymap {

using console::KeyEvent;

enum Special {
    kNone,
    kF1, kF2, kF3, kF4, kF5, kF6, kF7, kF8, kF9, kF10, kF11, kF12,
    kHome, kUp, kPgUp, kLeft, kCenter, kRight, kEnd, kDown, kPgDn, kIns, kDel,
    kShiftTab,
};

inline KeyEvent Make(char32_t ch, uint8_t scan, uint8_t mods) {
    return {ch, scan, mods};
}

inline KeyEvent Scan(uint8_t scan, uint8_t mods) {
    return {0, scan, mods};
}

// Функциональные клавиши и клавиши курсора.
inline KeyEvent MakeSpecial(Special k, uint8_t mods) {
    const bool shift = mods & console::kShift, ctrl = mods & console::kCtrl,
               alt = mods & console::kAlt;
    if (k >= kF1 && k <= kF10) {
        const int i = k - kF1;
        return Scan(static_cast<uint8_t>(alt ? 0x68 + i : ctrl ? 0x5E + i : shift ? 0x54 + i : 0x3B + i),
                    mods);
    }
    if (k == kF11)
        return Scan(alt ? 0x8B : ctrl ? 0x89 : shift ? 0x87 : 0x85, mods);
    if (k == kF12)
        return Scan(alt ? 0x8C : ctrl ? 0x8A : shift ? 0x88 : 0x86, mods);
    if (k == kShiftTab)
        return Scan(0x0F, mods | console::kLeftShift);
    //                             Home  Up    PgUp  Left  Cent  Right End   Down  PgDn  Ins   Del
    static const uint8_t plain[] = {0x47, 0x48, 0x49, 0x4B, 0x4C, 0x4D, 0x4F, 0x50, 0x51, 0x52, 0x53};
    static const uint8_t ctrls[] = {0x77, 0x8D, 0x84, 0x73, 0x8F, 0x74, 0x75, 0x91, 0x76, 0x92, 0x93};
    static const uint8_t alts[] = {0x97, 0x98, 0x99, 0x9B, 0x00, 0x9D, 0x9F, 0xA0, 0xA1, 0xA2, 0xA3};
    const int i = k - kHome;
    if (i < 0 || i > 10)
        return {};
    uint8_t scan = alt ? alts[i] : ctrl ? ctrls[i] : plain[i];
    return Scan(scan ? scan : plain[i], mods);
}

// Расширенный код BIOS для Alt с символом (буквы -- по месту на клавиатуре).
inline uint8_t AltScan(char32_t u) {
    // Латиница и кириллица (ЙЦУКЕН) на тех же клавишах.
    static const uint8_t latin[26] = {
        0x1E, 0x30, 0x2E, 0x20, 0x12, 0x21, 0x22, 0x23, 0x17, 0x24, 0x25, 0x26, 0x32, // a..m
        0x31, 0x18, 0x19, 0x10, 0x13, 0x1F, 0x14, 0x16, 0x2F, 0x11, 0x2D, 0x15, 0x2C, // n..z
    };
    if (u >= U'a' && u <= U'z')
        return latin[u - U'a'];
    if (u >= U'A' && u <= U'Z')
        return latin[u - U'A'];
    if (u >= U'1' && u <= U'9')
        return static_cast<uint8_t>(0x78 + (u - U'1'));
    switch (u) {
    case U'0': return 0x81;
    case U'-': return 0x82;
    case U'=': return 0x83;
    }
    // йцукенгшщз фывапролд ячсмить -> qwertyuiop asdfghjkl zxcvbnm
    static const struct {
        char32_t cyr;
        char lat;
    } russian[] = {
        {U'й', 'q'}, {U'ц', 'w'}, {U'у', 'e'}, {U'к', 'r'}, {U'е', 't'}, {U'н', 'y'},
        {U'г', 'u'}, {U'ш', 'i'}, {U'щ', 'o'}, {U'з', 'p'}, {U'ф', 'a'}, {U'ы', 's'},
        {U'в', 'd'}, {U'а', 'f'}, {U'п', 'g'}, {U'р', 'h'}, {U'о', 'j'}, {U'л', 'k'},
        {U'д', 'l'}, {U'я', 'z'}, {U'ч', 'x'}, {U'с', 'c'}, {U'м', 'v'}, {U'и', 'b'},
        {U'т', 'n'}, {U'ь', 'm'}, {U'і', 's'}, // і -- на месте ы
    };
    char32_t lower = u;
    if (lower >= U'А' && lower <= U'Я')
        lower += 0x20;
    if (lower == U'І')
        lower = U'і';
    for (const auto& key : russian)
        if (key.cyr == lower)
            return latin[key.lat - 'a'];
    switch (u) {
    case U'[': case U'х': case U'Х': return 0x1A;
    case U']': case U'ъ': case U'Ъ': return 0x1B;
    case U';': case U'ж': case U'Ж': return 0x27;
    case U'\'': case U'э': case U'Э': return 0x28;
    case U',': case U'б': case U'Б': return 0x33;
    case U'.': case U'ю': case U'Ю': return 0x34;
    case U'/': return 0x35;
    case U'\\': return 0x2B;
    case U'`': case U'ё': case U'Ё': return 0x29;
    }
    return 0;
}

// Символ с Alt. Alt+пробел у BIOS -- сам пробел (им пользуются строка
// ввода и «прочитать строку»), Alt+Enter и Alt+Backspace -- свои коды.
inline KeyEvent MakeAltChar(char32_t u, uint8_t mods) {
    mods |= console::kAlt;
    switch (u) {
    case U' ': return Make(U' ', 0x39, mods);
    case 13: return Scan(0x1C, mods);
    case 8:
    case 127: return Scan(0x0E, mods);
    case 27: return Scan(0x01, mods);
    }
    const uint8_t scan = AltScan(u);
    return scan ? Scan(scan, mods) : KeyEvent{};
}

// Обычный символ без Alt.
inline KeyEvent MakeChar(char32_t u, uint8_t mods) {
    return Make(u, 0, mods);
}

} // namespace keymap

#endif
