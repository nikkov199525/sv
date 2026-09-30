// keys.h -- коды клавиш (KEYB.PAS).
//
// Код клавиши: символ Unicode -- положительный (управляющие коды 1..31 --
// Ctrl с буквой, Enter, Esc...), расширенный код BIOS -- со знаком минус
// (F1 = -59), 0 -- одиночная клавиша-модификатор (только там, где программа
// об этом просила) или ничего.

#ifndef SV_UI_KEYS_H
#define SV_UI_KEYS_H

namespace key {

// Главный код
constexpr int Back = 8;
constexpr int Tab = 9;
constexpr int CtrlEnter = 10;
constexpr int Enter = 13;
constexpr int Esc = 27;
constexpr int Space = 32;
constexpr int CtrlBack = 127;

constexpr int CtrlA = 1, CtrlB = 2, CtrlC = 3, CtrlD = 4, CtrlE = 5, CtrlF = 6, CtrlG = 7;
constexpr int CtrlH = 8, CtrlI = 9, CtrlJ = 10, CtrlK = 11, CtrlL = 12, CtrlM = 13, CtrlN = 14;
constexpr int CtrlO = 15, CtrlP = 16, CtrlQ = 17, CtrlR = 18, CtrlS = 19, CtrlT = 20, CtrlU = 21;
constexpr int CtrlV = 22, CtrlW = 23, CtrlX = 24, CtrlY = 25, CtrlZ = 26;
constexpr int CtrlBackslash = 28;
constexpr int CtrlLeftBracket = 27;  // Ctrl+[ -- тот же код, что у Esc
constexpr int CtrlRightBracket = 29; // Ctrl+]

// Вспомогательный код: буквенно-цифровые клавиши
constexpr int AltA = -30, AltB = -48, AltC = -46, AltD = -32, AltE = -18, AltF = -33, AltG = -34;
constexpr int AltH = -35, AltI = -23, AltJ = -36, AltK = -37, AltL = -38, AltM = -50, AltN = -49;
constexpr int AltO = -24, AltP = -25, AltQ = -16, AltR = -19, AltS = -31, AltT = -20, AltU = -22;
constexpr int AltV = -47, AltW = -17, AltX = -45, AltY = -21, AltZ = -44;
constexpr int Alt1 = -120, Alt2 = -121, Alt3 = -122, Alt4 = -123, Alt5 = -124;
constexpr int Alt6 = -125, Alt7 = -126, Alt8 = -127, Alt9 = -128, Alt0 = -129;

// Функциональные клавиши
constexpr int F1 = -59, F2 = -60, F3 = -61, F4 = -62, F5 = -63;
constexpr int F6 = -64, F7 = -65, F8 = -66, F9 = -67, F10 = -68;
constexpr int ShiftF9 = -92;
constexpr int CtrlF5 = -98, CtrlF6 = -99, CtrlF8 = -101, CtrlF9 = -102;
constexpr int AltF3 = -106, AltF9 = -112;

// Клавиши курсора. С Shift коды те же: Shift проверяется отдельно.
constexpr int Home = -71, Up = -72, PgUp = -73, Left = -75, Right = -77;
constexpr int End = -79, Down = -80, PgDn = -81, Ins = -82, Del = -83;
constexpr int CtrlHome = -119, CtrlEnd = -117, CtrlPgUp = -132, CtrlPgDn = -118;
constexpr int CtrlLeft = -115, CtrlRight = -116;
constexpr int ShiftTab = -15;

} // namespace key

#endif
