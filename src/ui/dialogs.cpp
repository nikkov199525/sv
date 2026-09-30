// dialogs.cpp -- DIALOG.PAS.

#include "ui/dialogs.h"

#include "sound/signals.h"
#include "speech/speech.h"
#include "text/strings.h"
#include "text/utf8.h"
#include "text/words.h"

#include <algorithm>
#include <cmath>

namespace ui {

int ReturnCode = 0;
int Posit = 0;

const char* const kOk = "оке+й.";
const char* const kCancel = "отме+на.";

namespace {

std::vector<int> extra_exit_keys;

int Width(std::string_view s) {
    return static_cast<int>(text::Width(s));
}

int Sum(const std::vector<std::string>& items, int count, int extra = 0) {
    int sum = 0;
    for (int i = 0; i < count && i < static_cast<int>(items.size()); i++)
        sum += Width(items[i]) + extra;
    return sum;
}

void Edge() {
    sound::Play(sound::Signal::Edge);
}

void WaitKey() {
    while (!KeyPressed())
        Idle();
}

} // namespace

ExitKeys::ExitKeys(std::initializer_list<int> keys) : count_(keys.size()) {
    extra_exit_keys.insert(extra_exit_keys.end(), keys);
}

ExitKeys::~ExitKeys() {
    extra_exit_keys.resize(extra_exit_keys.size() - count_);
}

bool IsExitKey(int key) {
    return key == key::Esc || key == key::Enter ||
           std::find(extra_exit_keys.begin(), extra_exit_keys.end(), key) != extra_exit_keys.end();
}

// ------------------------------------------------------------ EditLine

void EditLine(int x, int y, std::string& value, int max, int width) {
    std::u32string line = utf8::Decode(value);
    auto len = [&] { return static_cast<int>(line.size()); };
    auto at = [&](int i) { return i >= 1 && i <= len() ? line[i - 1] : char32_t(0); };
    ReturnCode = 0;
    width = std::min(width, 81 - x);
    Posit = std::min(Posit, len() + 1);
    int offset, cursor_x;
    if (len() < width) {
        offset = 1;
        cursor_x = Posit == 0 ? x + len() : x + Posit - 1;
    } else {
        offset = len() - width + 1;
        cursor_x = x + width;
    }
    int point = Posit == 0 ? len() + 1 : Posit;
    int key;
    for (;;) {
        PutLine(x, y, std::string(width, ' '), color.text);
        PutLine(x, y, std::u32string_view(line).substr(std::clamp(offset - 1, 0, len()), width),
                color.text);
        Show();
        SetCursorXY(cursor_x, y);
        const KeyInput input = ReadKey();
        key = input.code;
        if (IsExitKey(key))
            break;
        if (input.ch >= U' ' && input.ch != 0x7F && len() < max) {
            if (key == key::Space && OnlyAlt()) {
                speech::Say(utf8::Encode(line));
                continue;
            }
            line.insert(point - 1, 1, input.ch);
            speech::SaySymbol(input.ch);
            point++;
            if (cursor_x < width + x)
                cursor_x++;
            else
                offset++;
        }
        switch (key) {
        case key::Back:
            if (point > 1) {
                speech::SaySymbol(at(point - 1));
                line.erase(point - 2, 1);
                point--;
                if (cursor_x > x)
                    cursor_x--;
                else
                    offset--;
            } else
                Edge();
            break;
        case key::Left:
            if (point > 1) {
                speech::SaySymbol(at(point - 1));
                point--;
                if (cursor_x > x)
                    cursor_x--;
                else
                    offset--;
            } else {
                Edge();
                if (len() > 0)
                    speech::SaySymbol(at(1));
            }
            break;
        case key::Right:
            if (point < len() + 1) {
                speech::SaySymbol(len() > point ? at(point + 1) : U' ');
                point++;
                if (cursor_x < x + width - 1)
                    cursor_x++;
                else
                    offset++;
            } else
                Edge();
            break;
        case key::Home:
            if (len() > 0)
                speech::SaySymbol(at(1));
            else
                Edge();
            point = 1;
            offset = 1;
            cursor_x = x;
            break;
        case key::End:
            if (len() > 0)
                speech::SaySymbol(U' ');
            else
                Edge();
            if (len() < width) {
                offset = 1;
                cursor_x = x + len();
            } else {
                offset = len() - width + 1;
                cursor_x = x + width;
            }
            point = len() + 1;
            break;
        case key::Del:
            if (point < len() + 1) {
                line.erase(point - 1, 1);
                if (len() > 0)
                    speech::SaySymbol(at(point));
                else
                    Edge();
            } else
                Edge();
            break;
        case key::CtrlY:
            if (OnlyCtrl()) {
                line.clear();
                point = 1;
                offset = 1;
                cursor_x = x;
                speech::Say("удалено+.");
            }
            break;
        case key::CtrlL:
            if (point > 1)
                speech::Say(utf8::Encode(line.substr(0, point - 1)));
            break;
        case key::CtrlR:
            if (len() > point)
                speech::Say(utf8::Encode(line.substr(point - 1)));
            break;
        case key::CtrlS:
            speech::Say(utf8::Encode(line));
            break;
        }
    }
    value = utf8::Encode(line);
    ReturnCode = key;
    Posit = point;
}

// ------------------------------------------------------------ ViewLine

void ViewLine(int x, int y, std::string value, int width) {
    ReturnCode = 0;
    if (x < 1 || x > kWidth || y < 1 || y > kHeight)
        return;
    std::u32string line = utf8::Decode(value);
    width = std::min(width, kWidth - x + 1);
    if (static_cast<int>(line.size()) < width)
        line.append(width - line.size(), U' ');
    const int len = static_cast<int>(line.size());
    auto at = [&](int i) { return i >= 1 && i <= len ? line[i - 1] : char32_t(0); };
    int offset = 1;
    int point = x;
    Posit = std::min(Posit, len);
    if (Posit > 0 && Posit < width + 1)
        point = x + Posit;
    auto say_word = [&](text::WordStep step) {
        if (!OnlyCtrl())
            return;
        const text::WordBounds word = text::FindWord(line, offset + point - x, step);
        if (!word) {
            Edge();
            return;
        }
        speech::Say(utf8::Encode(line.substr(word.left - 1, word.right - word.left + 1)));
        if (len <= width)
            point = x + word.left - 1;
    };
    int key;
    for (;;) {
        PutLine(x, y, std::u32string_view(line).substr(std::clamp(offset - 1, 0, len), width),
                color.message);
        SetCursorXY(point, y);
        Show();
        key = DefineKey();
        if (IsExitKey(key))
            break;
        switch (key) {
        case key::Right:
            if (point < x + width - 1)
                point++;
            else if (len > offset + width - 1)
                offset++;
            else
                Edge();
            speech::SaySymbol(at(offset + point - x));
            break;
        case key::Left:
            if (point > x)
                point--;
            else if (offset > 1)
                offset--;
            else
                Edge();
            speech::SaySymbol(at(offset + point - x));
            break;
        case key::Home:
            point = x;
            offset = 1;
            Edge();
            if (len > 0)
                speech::SaySymbol(at(1));
            break;
        case key::End:
            point = x + width - 1;
            offset = len - width + 1;
            Edge();
            if (len > 0)
                speech::SaySymbol(at(offset + point - x));
            break;
        case key::CtrlRight: say_word(text::WordStep::Next); break;
        case key::CtrlLeft: say_word(text::WordStep::Previous); break;
        case key::Space:
        case key::F5: speech::Say(utf8::Encode(line)); break;
        }
    }
    Posit = offset + point - x - 1;
    ReturnCode = key;
}

// ----------------------------------------------------------- PopupMenu

void PopupMenu::SetPosition(int l, int t, int r, int b) {
    if (l > 78 || l == 0 || t > 23 || t == 0)
        return;
    left = l;
    top = t;
    right = std::max(r, l + 2);
    bottom = std::max(b, t + 2);
}

void PopupMenu::Center() {
    const int count = static_cast<int>(items.size());
    if (count < 1)
        return;
    int max_len = 0;
    for (const MenuItem& item : items)
        max_len = std::max(max_len, ui::Width(item.text));
    top = (kHeight - (count + 2)) / 2 + 1;
    bottom = top + count + 1;
    left = (kWidth - (max_len + 2)) / 2 + 1;
    right = left + max_len + 1;
    if (count > 22) {
        top = 1;
        bottom = kHeight;
    }
    if (max_len > 77) {
        left = 1;
        right = kWidth;
    }
}

void PopupMenu::Call() {
    const bool talk = speech::Talking();
    const int count = static_cast<int>(items.size());
    ReturnCode = 0;
    if (count < 1)
        return;
    if (current == 0 || current > count)
        current = 1;
    int y = std::min(top + current, bottom - 1);
    first_ = current;
    if (first_ > count - Height() + 3)
        first_ = current - Height() + 3;
    first_ = std::max(first_, 1);
    if (cursor)
        ShowCursor();
    else
        HideCursor();
    int key = 0;
    for (;;) {
        Show();
        SetCursorXY(left, y);
        WaitKey();
        key = DefineKey();
        speech::SetTalk(talk);
        // Enter на недоступном элементе (он начинается с \x01) -- не выход.
        if (key == key::Enter && IsExitKey(key) && items[current - 1].text[0] == '\x01')
            key = 1;
        if (key == key::Down) {
            if (current < count) {
                current++;
                if (y < top + Height() - 2)
                    y++;
                else
                    first_++;
            } else {
                if (cycle) {
                    first_ = 1;
                    current = 1;
                    y = top + 1;
                } else
                    speech::SetTalk(false);
                Edge();
            }
        }
        if (key == key::Up) {
            if (current > 1) {
                current--;
                if (y > top + 1)
                    y--;
                else
                    first_--;
            } else {
                if (cycle) {
                    y = bottom - 1;
                    first_ = count - (bottom - top - 2);
                    current = count;
                } else
                    speech::SetTalk(false);
                Edge();
            }
        }
        if (IsExitKey(key))
            break;
        switch (key) {
        case key::Space:
            if (my > 0) {
                speech::Say(items[current - 1].hint);
                talk_item = false;
            }
            break;
        case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
            if (key - '0' <= count) {
                current = key - '0';
                y = std::min(top + current, bottom - 1);
                first_ = current;
                if (first_ > count - Height() + 3)
                    first_ = current - Height() + 3;
                first_ = std::max(first_, 1);
            }
            break;
        case key::Home:
            first_ = 1;
            current = 1;
            y = top + 1;
            break;
        case key::End:
            y = bottom - 1;
            first_ = count - (bottom - top - 2);
            current = count;
            break;
        }
    }
    ReturnCode = key;
}

void PopupMenu::Show() {
    Frame(left, top, right, bottom, frame, color.menu.frame);
    if (Width() > 4)
        PutLine(left + (Width() - ui::Width(title)) / 2, top, title, color.menu.title);
    for (int n = 0; n <= Height() - 3; n++) {
        const int number = first_ + n;
        const int y = top + n + 1;
        if (number < 1 || number > static_cast<int>(items.size())) {
            PutLine(left + 1, y, std::string(std::max(Width() - 2, 0), ' '), color.menu.inactive);
            continue;
        }
        const MenuItem& item = items[number - 1];
        std::string text = text::Left(item.text, Width() - 2);
        if (!text.empty() && text[0] == '\x01')
            text = text.substr(1) + ' ';
        if (number != current)
            PutLine(left + 1, y, text, color.menu.inactive);
        else {
            PutLine(left + 1, y, text, color.menu.active);
            if (talk_item)
                speech::Say(text);
            else
                talk_item = true;
            if (mx == 0)
                mx = static_cast<int>(std::nearbyint((kWidth - ui::Width(item.hint)) / 2.0));
            PutLine(mx, my, item.hint, color.message);
        }
    }
    ui::Show();
}

// ----------------------------------------------------------- CheckList

void CheckList::SetPosition(int l, int t, int r, int b) {
    left_ = l;
    top_ = t;
    right_ = r;
    bottom_ = b;
}

void CheckList::Call() {
    const bool talk = speech::Talking();
    const int count = static_cast<int>(items.size());
    if (count < 1)
        return;
    current = std::clamp(current, 1, count);
    int y = top_ + margin_top + current;
    int key;
    for (;;) {
        Show();
        const CheckItem& item = items[current - 1];
        speech::Say(std::string(item.on ? "вклю+чено." : "вы+ключено.") + item.text);
        SetCursorXY(left_ + margin_left + 2, y);
        key = DefineKey();
        speech::SetTalk(talk);
        if (IsExitKey(key::Space) && key == key::Space)
            items[current - 1].on = !items[current - 1].on;
        if (IsExitKey(key))
            break;
        if (key == key::Up) {
            if (current == 1) {
                if (!cycle)
                    break;
                current = count;
                y = top_ + margin_top + count;
            } else {
                y--;
                current--;
            }
        } else if (key == key::Down) {
            if (current < count) {
                current++;
                y++;
            } else {
                if (!cycle)
                    break;
                y = top_ + margin_top + 1;
                current = 1;
            }
        } else if (key == key::Space)
            items[current - 1].on = !items[current - 1].on;
    }
    ReturnCode = key;
}

void CheckList::Show() {
    Frame(left_, top_, right_, bottom_, frame, color.frame);
    if (!text::IsBlank(title))
        PutLine(left_ + ((right_ - left_) - Width(title)) / 2, top_, title, color.title);
    for (int n = 1; n <= static_cast<int>(items.size()); n++) {
        const CheckItem& item = items[n - 1];
        const std::string text = std::string(item.on ? "[X]" : "[ ]") + item.text;
        PutLine(left_ + margin_left + 1, top_ + margin_top + n, text::Left(text, right_ - left_ - 1),
                n == current ? color.check.active : color.check.inactive);
    }
    ui::Show();
}

// ---------------------------------------------------------- RadioGroup

void RadioGroup::SetPosition(int l, int t, int r, int b) {
    if (t < 1 || b > kHeight || l < 1 || r > kWidth || b - t < 3 || r - l < 5)
        return;
    left_ = l;
    top_ = t;
    right_ = r;
    bottom_ = b;
}

void RadioGroup::Call() {
    const int count = static_cast<int>(items.size());
    if (count < 2)
        return;
    if (current == 0)
        current = 1;
    selected = std::clamp(selected, 1, count);
    int y = top_ + margin_top + current;
    int key;
    for (;;) {
        Show();
        SetCursorXY(left_ + margin_left + 2, y);
        key = DefineKey();
        if (IsExitKey(key))
            break;
        switch (key) {
        case key::Down:
            current++;
            y++;
            if (current > count) {
                if (cycle) {
                    current = 1;
                    y = top_ + margin_top + current;
                } else {
                    current--;
                    y--;
                }
            }
            break;
        case key::Up:
            current--;
            y--;
            if (current < 1) {
                if (cycle) {
                    current = count;
                    y = top_ + margin_top + current;
                } else {
                    current++;
                    y++;
                }
            }
            break;
        case key::Space:
            selected = current;
            break;
        }
    }
    ReturnCode = key;
}

void RadioGroup::Show() {
    Frame(left_, top_, right_, bottom_, frame);
    if (Width(title) > right_ - left_ - 3)
        title = text::Left(title, right_ - left_ - 3);
    PutLine(left_ + ((right_ - left_ - 1) - Width(title)) / 2 + 1, top_, title, color.title);
    for (int n = 1; n <= static_cast<int>(items.size()); n++) {
        if (n == selected && current == selected)
            sound::Play(sound::Signal::Selected);
        const std::string text = std::string(n == selected ? "(•)" : "( )") + items[n - 1];
        if (n == current) {
            PutLine(left_ + margin_left + 1, top_ + margin_top + n, text, color.radio.active);
            speech::Say(items[n - 1]);
        } else
            PutLine(left_ + margin_left + 1, top_ + margin_top + n, text, color.radio.inactive);
    }
    ui::Show();
}

// ------------------------------------------------------------- MenuBar

void MenuBar::Call() {
    const int count = static_cast<int>(items.size());
    if (count < 2)
        return;
    current = std::clamp(current, 1, count);
    int x = left_ + Sum(items, current - 1);
    if (cursor)
        ShowCursor();
    else
        HideCursor();
    int key;
    for (;;) {
        Show();
        SetCursorXY(x, top_);
        WaitKey();
        key = DefineKey();
        if (IsExitKey(key))
            break;
        switch (key) {
        case key::Right:
            if (current < count) {
                current++;
                x += Width(items[current - 2]);
            } else if (cycle) {
                current = 1;
                x = left_;
            }
            break;
        case key::Left:
            if (current > 1) {
                current--;
                x -= Width(items[current - 1]);
            } else if (cycle) {
                current = count;
                x = left_ + Sum(items, count - 1);
            }
            break;
        case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
            if (key - '0' <= count) {
                current = key - '0';
                x = left_ + Sum(items, current - 1);
            }
            break;
        }
    }
    ShowCursor();
    ReturnCode = key;
}

void MenuBar::Show() {
    int x = left_;
    for (int n = 1; n <= static_cast<int>(items.size()); n++) {
        const std::string& item = items[n - 1];
        if (n == current) {
            speech::Say(item);
            PutLine(x, top_, item, color.menu.active);
        } else
            PutLine(x, top_, item, color.menu.inactive);
        x += Width(item);
    }
    ui::Show();
}

void MenuBar::Center() {
    if (items.size() < 2)
        return;
    top_ = 1;
    const int length = Sum(items, static_cast<int>(items.size()));
    left_ = length < kWidth ? (kWidth - length) / 2 + 1 : 1;
}

// ----------------------------------------------------------- ButtonRow

void ButtonRow::SetPosition(int l, int t, int r, int b) {
    left_ = l;
    top_ = t;
    right_ = r;
    bottom_ = b;
}

void ButtonRow::Call() {
    const int count = static_cast<int>(items.size());
    if (count < 2)
        return;
    current = std::clamp(current, 1, count);
    int x = left_ + 1 + margin_left + Sum(items, current - 1, 6);
    if (cursor)
        ShowCursor();
    else
        HideCursor();
    first_ = true;
    int key;
    for (;;) {
        Show();
        SetCursorXY(x, bottom_ - 2);
        key = DefineKey();
        if (IsExitKey(key))
            break;
        switch (key) {
        case key::Right:
            if (current < count) {
                current++;
                x += Width(items[current - 2]) + 6;
            } else {
                current = 1;
                x = left_ + margin_left + 1;
            }
            break;
        case key::Left:
            if (current > 1) {
                current--;
                x -= Width(items[current - 1]) + 6;
            } else {
                current = count;
                x = left_ + 1 + margin_left + Sum(items, count - 1, 6);
            }
            break;
        case key::CtrlS:
            speech::Say(message);
            break;
        }
    }
    ShowCursor();
    ReturnCode = key;
}

void ButtonRow::Show() {
    if (items.empty())
        return;
    const uint8_t shadow = ((color.frame >> 4) << 4) + 9;
    const uint8_t text_color = color.text;
    Frame(left_, top_, right_, bottom_, frame, color.frame);
    if (!text::IsBlank(message))
        PutLine(left_ + 1, top_ + 1 + margin_top, message, color.button.title);
    int x = left_ + 1 + margin_left;
    for (int n = 1; n <= static_cast<int>(items.size()); n++) {
        const std::string& item = items[n - 1];
        const int w = Width(item);
        if (n == current) {
            if (talk_button) {
                speech::Say(item);
                talk_button = false;
            }
            if (first_) {
                speech::Say(message);
                first_ = false;
            } else
                speech::Say(item);
            PutLine(x + 1, bottom_ - 2, item, color.button.active);
            PutLine(x, bottom_ - 2, "►", color.button.active);
            PutLine(x + w + 1, bottom_ - 2, "◄", color.button.active);
        } else {
            PutLine(x, bottom_ - 2, " ", color.button.inactive);
            PutLine(x + w + 1, bottom_ - 2, " ", color.button.inactive);
            PutLine(x + 1, bottom_ - 2, item, color.button.inactive);
        }
        PutLine(x + 1, bottom_ - 1, std::u32string(w + 2, U'▀'), shadow);
        PutLine(x + w + 2, bottom_ - 2, "▄", shadow);
        x += w + 6;
    }
    if (current == 0) {
        PutLine(left_ + 1 + margin_left, bottom_ - 2, "►", color.button.inactive);
        PutLine(left_ + margin_left + Width(items.back()), bottom_ - 2, "◄", color.button.inactive);
    }
    ui::Show();
    color.text = text_color;
}

// ----------------------------------------------------- Yes, ShowMessage

bool Yes(std::string_view message) {
    const int length = Width(message);
    const int left = (kWidth - length) / 2;
    ButtonRow choice;
    choice.items = {"  Да  ", "  Нет  "};
    choice.message = std::string(message);
    choice.margin_top = 1;
    choice.margin_left = (length - 24) / 2 + 1;
    choice.SetPosition(left, 9, left + length + 1, 16);
    Clear(left, 9, left + length + 1, 16);
    choice.Call();
    if (choice.current == 1 && ReturnCode == key::Enter) {
        speech::Say("да+.");
        return true;
    }
    speech::Say("не+т.");
    return false;
}

void ShowMessage(std::string_view message, std::string_view help) {
    const Screen saved = screen;
    const uint8_t old_text = color.text;
    const uint8_t shadow = ((color.frame >> 4) << 4) + 9;
    color.text = color.message;
    const int length = Width(message);
    const int left = (kWidth - length) / 2;
    const int right = left + length + 1;
    Clear(left, 9, right, 16);
    Frame(left, 9, right, 16, kDoubleFrame, color.frame);
    PutLine(left + 1, 11, message, color.button.title);
    PutLine(left + 1, 14, std::string(length, ' '), color.button.title);
    // кнопка
    PutLine(37, 14, "  Ok   ", color.button.active);
    PutLine(37, 15, std::u32string(8, U'▀'), shadow);
    PutLine(44, 14, "▄", shadow);
    for (int x = 37; x <= 43; x++)
        screen.At(14, x).attr = color.button.active;
    PutLine(36, 14, "►", color.button.active);
    PutLine(43, 14, "◄", color.button.active);
    ui::Show();
    const std::string said(text::Trim(message));
    speech::Say(said);
    int key;
    do {
        key = DefineKey();
        if (key == key::Space) {
            speech::Say(said);
            continue;
        }
        if (key == key::F1) {
            speech::Say(std::string(text::Trim(help)) + '.');
            speech::Say("нажми+те э+нтер и+ли эске+йп для+ продолже+ния.");
            continue;
        }
        if (key != key::Enter && key != key::Esc)
            speech::Say("Нажми+те э+нтер.");
    } while (key != key::Enter && key != key::Esc);
    color.text = old_text;
    screen = saved;
    ui::Show();
    speech::Say(kOk);
}

} // namespace ui
