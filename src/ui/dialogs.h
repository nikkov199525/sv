// dialogs.h -- элементы диалога (DIALOG.PAS): строка ввода, меню,
// переключатели, радиокнопки, полоса главного меню, кнопки, «Да/Нет»,
// сообщение, просмотр строки.
//
// Протокол -- авторский. Диалог работает, пока не нажата клавиша выхода:
// Esc, Enter и те, что на время добавил вызывающий (ExitKeys); нажатая
// клавиша выхода остаётся в ReturnCode. Номера элементов -- с единицы.

#ifndef SV_UI_DIALOGS_H
#define SV_UI_DIALOGS_H

#include "ui/keyboard.h"
#include "ui/screen.h"

#include <functional>
#include <initializer_list>
#include <string>
#include <string_view>
#include <vector>

namespace ui {

// Клавиша, которой кончился последний диалог.
extern int ReturnCode;
// Позиция курсора в строке ввода: на входе (0 -- в конце) и на выходе.
extern int Posit;

// Дополнительные клавиши выхода на время жизни объекта (ECode[3..]).
class ExitKeys {
public:
    ExitKeys(std::initializer_list<int> keys);
    ~ExitKeys();
    ExitKeys(const ExitKeys&) = delete;
    ExitKeys& operator=(const ExitKeys&) = delete;

private:
    size_t count_;
};
bool IsExitKey(int key);

// «оке+й.» и «отме+на.» -- сказать по завершении диалога.
extern const char* const kOk;
extern const char* const kCancel;

// Строка ввода: не длиннее max символов, видно width символов.
void EditLine(int x, int y, std::string& text, int max, int width);
// Просмотр строки по символам и словам (справка, словарь).
void ViewLine(int x, int y, std::string text, int width);
bool Yes(std::string_view message);
void ShowMessage(std::string_view message, std::string_view help);

struct MenuItem {
    std::string text;
    std::string hint; // подсказка внизу экрана (строка MY)
};

// Вертикальное меню.
class PopupMenu {
public:
    std::vector<MenuItem> items;
    int current = 0;
    bool cycle = true;
    bool cursor = false;
    bool talk_item = true; // говорить выбранный элемент
    FrameStyle frame = kDoubleFrame;
    std::string title;
    int mx = 0, my = 0;  // где подсказка; my = 0 -- её нет
    int left = 1, top = 1, right = kWidth, bottom = kHeight;

    void SetPosition(int l, int t, int r, int b);
    void Center();
    void Call();
    void Show();

private:
    int first_ = 0;
    int Height() const { return bottom - top + 1; }
    int Width() const { return right - left + 1; }
};

struct CheckItem {
    std::string text;
    bool on;
};

// Список переключателей «[X]».
class CheckList {
public:
    std::vector<CheckItem> items;
    int current = 0;
    bool cycle = false;
    int margin_left = 0, margin_top = 0;
    FrameStyle frame = kDoubleFrame;
    std::string title;

    void SetPosition(int l, int t, int r, int b);
    void Call();
    void Show();

private:
    int left_ = 1, top_ = 1, right_ = kWidth, bottom_ = kHeight;
};

// Радиокнопки «(•)»: selected -- выбранная, current -- под курсором.
class RadioGroup {
public:
    std::vector<std::string> items;
    int current = 0;
    int selected = 1;
    bool cycle = false;
    int margin_left = 0, margin_top = 0;
    FrameStyle frame = kDoubleFrame;
    std::string title;
    // Выбор идёт за курсором (не только по пробелу), и о каждом новом
    // выборе сразу сообщается -- до того, как пункт будет сказан.
    bool select_follows_cursor = false;
    std::function<void(int)> on_select;

    void SetPosition(int l, int t, int r, int b);
    void Call();
    void Show();

private:
    int left_ = 1, top_ = 1, right_ = kWidth, bottom_ = kHeight;
};

// Полоса главного меню.
class MenuBar {
public:
    std::vector<std::string> items;
    int current = 0;
    bool cycle = false;
    bool cursor = false;

    void Center();
    void Call();

private:
    int left_ = 1, top_ = 1;
    void Show();
};

// Кнопки под сообщением.
class ButtonRow {
public:
    std::vector<std::string> items;
    std::string message;
    int current = 0;
    bool cursor = false;
    bool talk_button = false;
    int margin_left = 0, margin_top = 0;
    FrameStyle frame = kDoubleFrame;

    void SetPosition(int l, int t, int r, int b);
    void Call();
    void Show();

private:
    int left_ = 1, top_ = 1, right_ = kWidth, bottom_ = kHeight;
    bool first_ = false;
};

} // namespace ui

#endif
