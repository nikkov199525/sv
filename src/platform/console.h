// console.h -- экран 80x25 и клавиатура.
//
// Экран -- клетки с символом Unicode и атрибутом цвета DOS. Клавиша --
// символ Unicode (или управляющий код 1..31, как у Ctrl+буква) либо, для
// служебных клавиш и Alt с символом, расширенный код BIOS: на эти коды
// рассчитана вся программа (F1 -- $3B, Ctrl+Home -- $77 ...).

#ifndef SV_PLATFORM_CONSOLE_H
#define SV_PLATFORM_CONSOLE_H

#include <cstdint>
#include <string_view>

namespace console {

constexpr int kWidth = 80;
constexpr int kHeight = 25;

// Модификаторы (как у BIOS).
enum : uint8_t {
    kRightShift = 0x01,
    kLeftShift = 0x02,
    kShift = 0x03,
    kCtrl = 0x04,
    kAlt = 0x08,
};

struct KeyEvent {
    char32_t ch = 0;   // символ; 0 -- служебная клавиша
    uint8_t scan = 0;  // расширенный код BIOS (при ch = 0)
    uint8_t mods = 0;  // модификаторы в момент нажатия
    explicit operator bool() const { return ch || scan; }
};

struct Cell {
    char32_t ch = U' ';
    uint8_t attr = 0;
};

enum class Cursor { Hidden, Underline, Block };

void InitVideo();
void DoneVideo();
// Показать экран: kHeight строк по kWidth клеток.
void UpdateScreen(const Cell* cells);
// Координаты с нуля.
void SetCursorPos(int x, int y);
void SetCursor(Cursor type);
Cursor GetCursor();

void InitKeyboard();
void DoneKeyboard();
// Следующее событие, не забирая его; пустое -- нет.
KeyEvent PeekKey();
// Забрать событие (ждёт, если нет).
KeyEvent TakeKey();
// Модификаторы, нажатые сейчас (насколько это известно).
uint8_t ShiftState();

// Мышь. Кнопки -- биты, как у драйвера мыши DOS.
enum : uint8_t {
    kMouseLeft = 0x01,
    kMouseRight = 0x02,
    kMouseMiddle = 0x04,
};

struct MouseState {
    uint8_t buttons = 0; // нажатые сейчас
    int x = 0, y = 0;    // клетка указателя, с нуля
};

// Включить или выключить мышь. У консоли Windows -- события мыши, у
// терминала -- его отчёты о мыши (протокол xterm); пока мышь включена,
// выделять мышью текст в окне терминала нельзя. Текстовая консоль Linux
// мышь программам так не передаёт.
void EnableMouse(bool on);
MouseState GetMouse();
// Кнопки, нажатые после прошлого вызова: нажатие запоминается, даже если
// кнопку уже отпустили.
uint8_t TakeMousePresses();
// Есть незабранные нажатия?
bool MousePressPending();

} // namespace console

#endif
