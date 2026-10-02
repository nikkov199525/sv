// menu.cpp -- M_U.PAS: главное меню и диалоги настроек.
//
// Диалоги настроек из нескольких областей (переключатели, радиокнопки,
// строки ввода) -- как у автора: Tab -- следующая область, Shift+Tab --
// предыдущая, Enter -- принять, Esc -- отменить.

#include "sv/menu.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/app.h"
#include "sv/settings.h"
#include "sv/viewer.h"
#include "text/strings.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <array>
#include <filesystem>

namespace sv {

namespace {

namespace fs = std::filesystem;
using sound::Signal;

// Где стоял курсор в подменю главного меню и какое меню было последним.
int file_item, read_item, block_item, bookmark_item, find_item, window_item, setup_item, help_item;
int last_menu = 1;

bool Pressed(std::initializer_list<int> keys) {
    for (int k : keys)
        if (ui::ReturnCode == k)
            return true;
    return false;
}

// «Call; F1 -- справка и снова Call».
template <class Dialog>
void CallWithHelp(Dialog& dialog) {
    for (;;) {
        dialog.Call();
        if (ui::ReturnCode != key::F1)
            break;
        ui::help.Show(ui::Context);
    }
}

// Строка ввода: F1 -- справка и снова ввод.
void EditWithHelp(int x, int y, std::string& value, int max, int width) {
    for (;;) {
        ui::EditLine(x, y, value, max, width);
        if (ui::ReturnCode != key::F1)
            break;
        ui::help.Show(ui::Context);
    }
}

void Done(bool accepted) {
    speech::Say(accepted ? ui::kOk : ui::kCancel);
}

// ------------------------------------------------------ Настройки/Общие

void SetMemory() {
    ui::Context = 24;
    ui::RadioGroup radio;
    radio.items = {"  Верхняя", "  Обычная", "  Диск   "};
    radio.cycle = settings.cycle_menu;
    radio.margin_left = 2;
    radio.margin_top = 1;
    radio.selected = static_cast<int>(settings.memory) + 1;
    radio.SetPosition(54, 6, 71, 12);
    ui::Clear(54, 6, 71, 12);
    {
        const ui::ExitKeys keys{key::F1};
        CallWithHelp(radio);
    }
    if (ui::ReturnCode == key::Enter) {
        settings.memory = static_cast<Memory>(radio.selected - 1);
        ApplySettings();
    }
    Done(ui::ReturnCode == key::Enter);
}

// «Прыжки»: два числа через запятую.
bool ParseJumps(const std::string& s, long& jump1, long& jump2) {
    const size_t comma = s.find(',');
    if (comma == std::string::npos)
        return false;
    const auto a = text::ParseInt(std::string_view(s).substr(0, comma));
    const auto b = text::ParseInt(std::string_view(s).substr(comma + 1));
    if (!a || !b)
        return false;
    jump1 = static_cast<long>(*a);
    jump2 = static_cast<long>(*b);
    return true;
}

void SetVarious() {
    ui::Context = 25;
    std::string path = settings.temp_dir;
    ui::ShowCursor();
    ui::CheckList check;
    check.items = {
        {"  Цикличные меню           ", settings.cycle_menu},
        {"  Авто сохранение          ", settings.auto_save},
        {"  Заменять символ табуляции", settings.tab},
        {"  Подтверждение выхода     ", settings.exit_confirm},
        {"  Латинские в русские      ", settings.latin_to_russian},
        {"  Непрерывное перемещение  ", settings.no_stop},
        {"  Сигнал точного времени   ", settings.exact_time},
    };
    check.margin_left = 2;
    check.margin_top = 1;
    check.cycle = settings.cycle_menu;
    check.SetPosition(22, 7, 77, 21);
    ui::RadioGroup radio;
    radio.items = {"  Слов         ", "  Промежудков  "};
    radio.selected = settings.local + 1;
    radio.margin_left = 35;
    radio.margin_top = 1;
    radio.cycle = settings.cycle_menu;
    radio.SetPosition(22, 7, 77, 21);
    ui::Clear(22, 7, 77, 21);
    ui::PutLine(62, 8, " Локализация ", ui::color.title);
    ui::PutLine(27, 17, "Временный каталог:", ui::color.message);
    ui::PutLine(26, 18, text::Left(path, 24), ui::color.message);
    std::string jumps = std::to_string(settings.jump1) + ',' + std::to_string(settings.jump2);
    ui::PutLine(26, 20, "Прыжки - " + jumps, ui::color.message);
    radio.Show();
    {
        const ui::ExitKeys keys{key::Tab, key::F1, key::ShiftTab};
        int area = 1;
        for (bool done = false; !done;) {
            switch (area) {
            case 1:
                CallWithHelp(check);
                area = ui::ReturnCode == key::ShiftTab ? 4 : 2;
                break;
            case 2:
                speech::Say("локализа+ция.");
                CallWithHelp(radio);
                area = ui::ReturnCode == key::ShiftTab ? 1 : 3;
                break;
            case 3:
                speech::Say("вре+менный катало+г.");
                speech::Say(path);
                ui::Posit = 0;
                EditWithHelp(26, 18, path, 68, 50);
                area = ui::ReturnCode == key::ShiftTab ? 2 : 4;
                break;
            case 4: {
                speech::Say("прыжки+.");
                AllSymbolsOn();
                speech::Say(jumps);
                if (!settings.read_symbols)
                    AllSymbolsOff();
                ui::Posit = 0;
                for (;;) {
                    ui::EditLine(35, 20, jumps, 18, 18);
                    long a, b;
                    if (ui::ReturnCode == key::Enter && !ParseJumps(jumps, a, b)) {
                        sound::Play(Signal::Error);
                        continue;
                    }
                    if (ui::ReturnCode != key::F1)
                        break;
                    ui::help.Show(ui::Context);
                }
                area = ui::ReturnCode == key::ShiftTab ? 3 : 1;
                break;
            }
            }
            done = Pressed({key::Esc, key::Enter});
        }
    }
    if (!settings.cursor)
        ui::HideCursor();
    if (ui::ReturnCode == key::Enter) {
        settings.cycle_menu = check.items[0].on;
        settings.auto_save = check.items[1].on;
        settings.tab = check.items[2].on;
        settings.exit_confirm = check.items[3].on;
        settings.latin_to_russian = check.items[4].on;
        settings.temp_dir = path;
        settings.no_stop = check.items[5].on;
        long a, b;
        if (ParseJumps(jumps, a, b)) {
            settings.jump1 = a;
            settings.jump2 = b;
        }
        settings.exact_time = check.items[6].on;
        settings.local = radio.selected - 1;
        ApplySettings();
    }
    Done(ui::ReturnCode == key::Enter);
}

void SetupGeneral() {
    ui::Context = 11;
    ui::PopupMenu menu;
    menu.items = {{"  Память  ", ""}, {"  Разное  ", ""}};
    menu.cycle = settings.cycle_menu;
    menu.cursor = settings.cursor;
    menu.SetPosition(57, 4, 68, 7);
    ui::PutLine(57, 3, "  Общие      ", ui::color.menu.inactive);
    {
        const ui::ExitKeys keys{key::F1, key::Back};
        CallWithHelp(menu);
    }
    if (ui::ReturnCode != key::Enter)
        return;
    if (menu.current == 1)
        SetMemory();
    else
        SetVarious();
}

// ------------------------------------------------- переключатели настроек

// Диалог из одних переключателей: accept -- записать отмеченное.
template <typename Accept>
void Toggles(int context, std::vector<ui::CheckItem> items, int margin_left, int l, int t, int r, int b,
             Accept accept) {
    ui::Context = context;
    ui::CheckList check;
    check.items = std::move(items);
    check.margin_left = margin_left;
    check.margin_top = 1;
    check.cycle = settings.cycle_menu;
    check.SetPosition(l, t, r, b);
    ui::Clear(l, t, r, b);
    {
        const ui::ExitKeys keys{key::F1};
        CallWithHelp(check);
    }
    if (ui::ReturnCode == key::Enter) {
        accept(check.items);
        ApplySettings();
    }
    Done(ui::ReturnCode == key::Enter);
}

void SetupInterface() {
    Settings& s = settings;
    Toggles(26,
            {{"  Показывать часы", s.clock},
             {"  Показывать проценты", s.show_percent},
             {"  Показывать координаты", s.show_coords},
             {"  Показывать память", s.show_memory},
             {"  Показывать кодировку", s.show_code},
             {"  Использовать \"мышь\"", s.mouse},
             {"  Показывать курсор", s.cursor}},
            3, 43, 5, 76, 15, [&](const std::vector<ui::CheckItem>& on) {
                s.clock = on[0].on;
                s.show_percent = on[1].on;
                s.show_coords = on[2].on;
                s.show_memory = on[3].on;
                s.show_code = on[4].on;
                s.mouse = on[5].on;
                s.cursor = on[6].on;
            });
}

void SetupBookmarks() {
    Settings& s = settings;
    Toggles(27,
            {{"  Глобальные закладки", s.global_bookmarks},
             {"  Показывать строку  ", s.bookmark_line},
             {"  Автодобавление     ", s.auto_bookmarks}},
            3, 43, 6, 74, 12, [&](const std::vector<ui::CheckItem>& on) {
                s.global_bookmarks = on[0].on;
                s.bookmark_line = on[1].on;
                s.auto_bookmarks = on[2].on;
            });
}

void SetupSound() {
    Settings& s = settings;
    Toggles(30,
            {{"  Звуковое сопровождение  ", s.sound},
             {"  Звук заголовка          ", s.empty_bell},
             {"  Звук конца текста       ", s.end_bell},
             {"  Звук:  \"следующее окно\"", s.window_bell}},
            3, 41, 9, 78, 16, [&](const std::vector<ui::CheckItem>& on) {
                s.sound = on[0].on;
                s.empty_bell = on[1].on;
                s.end_bell = on[2].on;
                s.window_bell = on[3].on;
            });
}

// ----------------------------------------------------------------- речь

// У автора последним полем был путь к дикторским файлам (male.dat и
// female.dat драйвера); голоса теперь вшиты в ядро, и поля нет.
void SetupVoice() {
    ui::Context = 28;
    constexpr int kTop = 7, kLeft = 45, kRight = kLeft + 31, kBottom = kTop + 13;
    const int old_speed = settings.speed, old_dictor = settings.dictor;
    const int old_accel = settings.acceleration, old_pause = settings.pause;
    const bool old_talk = settings.talk;
    ui::Clear(kLeft, kTop, kRight, kBottom);
    ui::CheckList check;
    check.items = {{"  Речь", settings.talk}};
    check.margin_left = 5;
    check.margin_top = 1;
    check.cycle = settings.cycle_menu;
    check.SetPosition(kLeft, kTop, kRight, kBottom);
    check.Show();
    ui::RadioGroup radio;
    radio.items = {"  Мужской тенор", "  Женский альт", "  Мужской баритон", "  Женский сопрано"};
    radio.margin_top = 3;
    radio.margin_left = 5;
    radio.SetPosition(kLeft, kTop, kRight, kBottom);
    radio.selected = settings.dictor + 1;
    // Голос выбирается стрелками и сразу звучит: название пункта говорится
    // уже им. Esc возвращает прежний.
    radio.select_follows_cursor = true;
    radio.on_select = [](int n) {
        settings.dictor = n - 1;
        speech::SetDictor(settings.dictor);
    };
    radio.Show();
    radio.current = radio.selected; // курсор -- на текущем голосе

    // Числовые поля: скорость, ускорение, пауза -- шкалы как в SV.INI.
    // Стрелки меняют число, home и end -- края; новое значение действует и
    // слышно сразу. (У автора здесь был темп: 0 -- быстрее всего, 150 --
    // медленнее, влево -- быстрее.)
    struct Number {
        int y;
        const char* label;
        const char* spoken;
        int width;
        int lo, hi;
        int value;
        std::string (*text)(int);
        std::string (*say)(int);
        void (*apply)(int);
    };
    Number numbers[] = {
        {kTop + 9, " Скорость - ", "ско+рость.", 3, 0, 150, settings.speed,
         [](int v) { return std::to_string(v); }, [](int v) { return std::to_string(v); },
         [](int v) { settings.speed = v; }},
        {kTop + 10, " Ускорение - ", "ускоре+ние.", 2, -3, 7, settings.acceleration,
         [](int v) { return v > 0 ? "+" + std::to_string(v) : std::to_string(v); },
         [](int v) { return v < 0 ? "ми+нус " + std::to_string(-v) : std::to_string(v); },
         [](int v) { settings.acceleration = v; }},
        {kTop + 11, " Пауза между фразами - ", "па+уза ме+жду фра+зами.", 4, -1, 255, settings.pause,
         [](int v) { return v < 0 ? std::string("авто") : std::to_string(v); },
         [](int v) { return v < 0 ? std::string("а+вто") : std::to_string(v); },
         [](int v) { settings.pause = v; }},
    };
    auto show_number = [&](const Number& n, uint8_t attr) {
        const int x = kLeft + 3 + static_cast<int>(text::Width(n.label));
        ui::PutLine(x, n.y, std::string(n.width, ' '), attr);
        ui::PutLine(x, n.y, n.text(n.value), attr);
    };
    auto edit_number = [&](Number& n) {
        speech::Say(n.spoken);
        ui::SetCursorXY(kLeft + 2 + static_cast<int>(text::Width(n.label)), n.y);
        ui::HideCursor();
        for (;;) {
            show_number(n, ui::color.menu.active);
            ui::Show();
            n.apply(n.value);
            ApplySettings();
            speech::Say(n.say(n.value));
            while (!ui::KeyPressed())
                ui::Idle();
            while (ui::KeyPressed()) {
                ui::ReturnCode = ui::DefineKey();
                if (Pressed({key::Tab, key::ShiftTab, key::Enter, key::Esc}))
                    break;
                // у автора на краях шкала темпа заворачивалась: «быстрее» с
                // самого быстрого темпа давало самый медленный
                switch (ui::ReturnCode) {
                case key::Left:
                    if (n.value > n.lo)
                        n.value--;
                    else
                        sound::Play(Signal::Edge);
                    break;
                case key::Right:
                    if (n.value < n.hi)
                        n.value++;
                    else
                        sound::Play(Signal::Edge);
                    break;
                case key::Home: n.value = n.lo; break;
                case key::End: n.value = n.hi; break;
                case key::F1: ui::help.Show(ui::Context); break;
                }
                if (&n == &numbers[0]) // тон -- как у автора, по темпу
                    sound::Beep(30 * (150 - n.value + 1), 100);
            }
            if (Pressed({key::Esc, key::Enter, key::Tab, key::ShiftTab}))
                break;
        }
        show_number(n, ui::color.menu.inactive);
        ui::ShowCursor();
    };
    for (const Number& n : numbers) {
        ui::PutLine(kLeft + 3, n.y, n.label, ui::color.message);
        show_number(n, ui::color.menu.inactive);
    }
    {
        // Поля: 1 -- речь, 2 -- голос, 3..5 -- числа.
        const ui::ExitKeys keys{key::Tab, key::F1, key::ShiftTab};
        int area = 1;
        for (;;) {
            if (area == 1)
                CallWithHelp(check);
            else if (area == 2)
                CallWithHelp(radio);
            else
                edit_number(numbers[area - 3]);
            if (!Pressed({key::Tab, key::ShiftTab}))
                break;
            area = ui::ReturnCode == key::ShiftTab ? (area == 1 ? 5 : area - 1) : (area == 5 ? 1 : area + 1);
        }
    }
    if (ui::ReturnCode == key::Enter) {
        settings.talk = check.items[0].on;
        settings.dictor = radio.selected - 1;
        for (const Number& n : numbers)
            n.apply(n.value);
    } else {
        settings.speed = old_speed;
        settings.dictor = old_dictor;
        settings.acceleration = old_accel;
        settings.pause = old_pause;
        settings.talk = old_talk;
    }
    ApplySettings();
    Done(ui::ReturnCode == key::Enter);
}

// --------------------------------------------------------------- чтение

// Число 0..255 (у автора -- Val в байт).
std::optional<int> ParseByte(const std::string& s) {
    const auto n = text::ParseInt(s);
    if (!n || *n < 0 || *n > 255)
        return std::nullopt;
    return static_cast<int>(*n);
}

void SetupReading() {
    ui::Context = 29;
    Settings& s = settings;
    std::string from = std::to_string(s.silence_from);
    std::string to = std::to_string(s.silence_to);
    std::string pause = std::to_string(s.empty_delay);
    ui::CheckList check;
    check.items = {
        {"  Объявлять пустые строки  ", s.read_empty},
        {"  Объявлять абзацы         ", s.read_indent},
        {"  Читать первое слово      ", s.read_word},
        {"  Читать все окна          ", s.read_all_windows},
        {"  Читать все символы       ", s.read_symbols},
        {"  Читать всю строку        ", s.read_line},
        {"  Читать пробел            ", s.read_space},
        {"  Индикация заглавных букв ", s.capital},
    };
    check.margin_top = 1;
    check.margin_left = 3;
    check.cycle = s.cycle_menu;
    check.SetPosition(41, 8, 76, 25);
    ui::Clear(41, 8, 76, 25);
    ui::PutLine(43, 19, "пауза пустых: " + pause, ui::color.message);
    ui::PutLine(43, 21, "Зона молчания:", ui::color.message);
    ui::PutLine(45, 22, "Левая граница  -    ", ui::color.menu.inactive);
    ui::PutLine(45, 23, "Правая граница -    ", ui::color.menu.inactive);
    ui::PutLine(62, 22, from, ui::color.menu.inactive);
    ui::PutLine(62, 23, to, ui::color.menu.inactive);
    {
        const ui::ExitKeys keys{key::Tab, key::ShiftTab, key::F1};
        int area = 1;
        for (bool done = false; !done;) {
            if (area == 1) {
                CallWithHelp(check);
                area = ui::ReturnCode == key::ShiftTab ? 3 : 2;
                done = Pressed({key::Enter, key::Esc});
            } else if (area == 2) {
                speech::Say("Па+уза пусты+х.");
                speech::Say(pause);
                ui::EditLine(57, 19, pause, 3, 3);
                if (ui::ReturnCode == key::F1) {
                    ui::help.Show(ui::Context);
                    continue;
                }
                if (ui::ReturnCode == key::Enter && !ParseByte(pause)) {
                    sound::Play(Signal::Error);
                    continue;
                }
                done = Pressed({key::Enter, key::Esc});
                area = ui::ReturnCode == key::ShiftTab ? 1 : 3;
            } else {
                // Зона молчания: Up/Down -- между границами.
                const ui::ExitKeys arrows{key::Up, key::Down};
                speech::Say("зо+на молча+ния.");
                do {
                    speech::Say("пе+рвый си+мвол.");
                    speech::Say(from);
                    ui::EditLine(62, 22, from, 3, 3);
                    if (ui::ReturnCode == key::F1) {
                        ui::help.Show(ui::Context);
                        continue;
                    }
                    if (Pressed({key::Up, key::Down})) {
                        speech::Say("после+дний си+мвол.");
                        speech::Say(to);
                        EditWithHelp(62, 23, to, 3, 3);
                    }
                } while (!Pressed({key::Tab, key::Enter, key::Esc, key::ShiftTab}));
                ui::PutLine(62, 22, from, ui::color.menu.inactive);
                ui::PutLine(62, 23, to, ui::color.menu.inactive);
                done = Pressed({key::Enter, key::Esc});
                area = ui::ReturnCode == key::ShiftTab ? 2 : 1;
            }
        }
    }
    if (ui::ReturnCode == key::Enter) {
        s.read_empty = check.items[0].on;
        s.read_indent = check.items[1].on;
        s.read_word = check.items[2].on;
        s.read_all_windows = check.items[3].on;
        s.read_symbols = check.items[4].on;
        s.read_line = check.items[5].on;
        s.read_space = check.items[6].on;
        s.capital = check.items[7].on;
        if (const auto n = ParseByte(pause))
            s.empty_delay = *n;
        if (const auto n = ParseByte(from))
            s.silence_from = *n;
        if (const auto n = ParseByte(to))
            s.silence_to = *n;
        ApplySettings();
    }
    Done(ui::ReturnCode == key::Enter);
}

// ------------------------------------------------------------ будильник

void SetupAlarms() {
    static const char* const names[] = {"  Первый     ", "  Второй     ", "  Третий     "};
    ui::PopupMenu menu;
    for (const char* name : names)
        menu.items.push_back({name, ""});
    menu.cycle = settings.cycle_menu;
    menu.cursor = settings.cursor;
    menu.Center();
    ui::CheckList check;
    check.cycle = settings.cycle_menu;
    const ui::ExitKeys help_key{key::F1};
    for (;;) {
        ui::Context = 31;
        {
            const ui::ExitKeys keys{key::ShiftTab, key::Back};
            menu.Call();
        }
        if (Pressed({key::Esc, key::Back}))
            break;
        if (ui::ReturnCode == key::F1) {
            ui::help.Show(ui::Context);
            continue;
        }
        Alarm& alarm = settings.config.alarms[menu.current - 1];
        std::string time = alarm.time;
        std::string message = alarm.message;
        ui::Context = 35;
        check.items = {{"  Будильник активизирован ", alarm.on}, {"  Постоянная работа       ", alarm.every_day}};
        check.title = names[menu.current - 1];
        check.margin_left = 5;
        check.margin_top = 1;
        check.SetPosition(21, 8, 60, 18);
        ui::Clear(21, 8, 60, 18);
        auto show_time = [&](uint8_t attr) { ui::PutLine(22, 13, " Время - " + time, attr); };
        auto show_title = [&](uint8_t attr) {
            ui::PutLine(22, 15, "         Сообщение будильника         " + time, attr);
        };
        show_time(ui::color.message);
        show_title(ui::color.message);
        const ui::Screen saved = ui::screen;
        {
            // Shift+Tab здесь не работает: у автора его место в списке
            // клавиш выхода занимал Tab.
            const ui::ExitKeys keys{key::Tab};
            int area = 1;
            for (bool done = false; !done;) {
                if (area == 1) {
                    check.Call();
                    check.current = 0;
                    check.Show();
                    if (ui::ReturnCode == key::F1) {
                        ui::help.Show(ui::Context);
                        continue;
                    }
                    area = 2;
                } else if (area == 2) {
                    speech::Say("вре+мя.");
                    speech::Say(time);
                    show_time(ui::color.title);
                    ui::EditLine(31, 13, time, 5, 6);
                    show_time(ui::color.message);
                    if (ui::ReturnCode == key::F1) {
                        ui::help.Show(ui::Context);
                        continue;
                    }
                    area = 3;
                } else {
                    speech::Say("Сообще+ние буди+льника.");
                    speech::Say(message);
                    show_title(ui::color.title);
                    ui::Posit = 0;
                    ui::EditLine(22, 16, message, 255, 37);
                    show_title(ui::color.message);
                    if (ui::ReturnCode == key::F1) {
                        ui::help.Show(ui::Context);
                        continue;
                    }
                    area = 1;
                }
                done = Pressed({key::Enter, key::Esc});
            }
        }
        ui::screen = saved;
        ui::Show();
        if (ui::ReturnCode == key::Enter) {
            speech::Say(ui::kOk);
            alarm.time = time;
            alarm.message = message;
            alarm.on = check.items[0].on;
            alarm.every_day = check.items[1].on;
        } else
            speech::Say(ui::kCancel);
    }
}

// -------------------------------------------------------------- загрузка

void SetupStartup() {
    // (у автора раздел справки здесь не назначался -- F1 открывал раздел
    // меню «Настройки»)
    ui::Context = 34;
    Settings& s = settings;
    ui::CheckList check;
    check.items = {
        {"  Контроль отступа         ", s.indent_control},
        {"  Контроль баз данных      ", s.dbf_control},
        {"  Контроль архивов         ", s.archive_control},
        {"  Контроль html-файлов     ", s.html_control},
        {"  Сохранять ссылки в html  ", s.html_links},
        {"  Контроль файлов  Word 97 ", s.doc_control},
        {"  Восстанавливать позицию  ", s.last_position},
        {"  Автоопределение кодировки", s.detect_code},
        {"  Автозапуск чтения", s.read_on_start},
    };
    check.cycle = s.cycle_menu;
    check.margin_left = 3;
    check.margin_top = 1;
    check.SetPosition(41, 10, 78, 23);
    ui::Clear(41, 10, 78, 23);
    int width = s.word97_width;
    std::string width_text = std::to_string(width);
    ui::PutLine(42, 21, " Длина строки  Word 97  - " + width_text, ui::color.message);
    {
        const ui::ExitKeys keys{key::F1, key::Tab, key::ShiftTab};
        do {
            check.Call();
            if (ui::ReturnCode == key::F1) {
                ui::help.Show(ui::Context);
                continue;
            }
            if (!Pressed({key::Tab, key::ShiftTab}))
                continue;
            for (;;) {
                speech::Say("длина+ строки+  word 97  - " + width_text);
                ui::EditLine(68, 21, width_text, 3, 3);
                if (ui::ReturnCode == key::Enter) {
                    const auto n = text::ParseInt(width_text);
                    if (n && *n >= 24 && *n <= 250)
                        width = static_cast<int>(*n);
                    else {
                        sound::Play(Signal::Error);
                        continue;
                    }
                }
                if (ui::ReturnCode != key::F1)
                    break;
                ui::help.Show(ui::Context);
            }
        } while (!Pressed({key::Enter, key::Esc}));
    }
    if (ui::ReturnCode == key::Enter) {
        s.indent_control = check.items[0].on;
        s.dbf_control = check.items[1].on;
        s.archive_control = check.items[2].on;
        s.html_control = check.items[3].on;
        s.html_links = check.items[4].on;
        s.doc_control = check.items[5].on;
        s.last_position = check.items[6].on;
        s.detect_code = check.items[7].on;
        s.read_on_start = check.items[8].on;
        s.word97_width = width;
        ApplySettings();
    }
    Done(ui::ReturnCode == key::Enter);
}

// ------------------------------------------------------------------ вид

void SetupOutlook() {
    Settings& s = settings;
    std::string table = s.user_decode;
    int bottom = 23;
    ui::RadioGroup radio;
    radio.items = {"  Обычный    ", "  WINDOWS 866", "  KOI 8 r    ", "  utf 8      "};
    if (!text::IsBlank(s.user_decode)) {
        for (std::string& item : radio.items)
            item += std::string(9, ' ');
        std::string file = sys::Utf8(sys::Path(s.user_decode).filename());
        if (!file.empty() && file.back() == '.')
            file.pop_back();
        radio.items.push_back("  Польз.  " + file + " ");
        bottom++;
    }
    radio.cycle = s.cycle_menu;
    radio.margin_left = 3;
    radio.margin_top = 1;
    radio.selected = s.mode + 1;
    radio.SetPosition(45, 11, 77, bottom);
    ui::CheckList check;
    check.items = {{"  Quonted printable  ", s.printable}};
    check.cycle = s.cycle_menu;
    check.margin_left = 3;
    check.margin_top = bottom - 14;
    check.SetPosition(45, 11, 77, bottom);
    ui::Clear(45, 11, 77, bottom);
    check.Show();
    ui::PutLine(50, bottom - 5, "  Файл перекодировки  ", ui::color.message);
    ui::PutLine(46, bottom - 4, text::Left(table, 31), ui::color.message);
    ui::Context = 23;
    {
        const ui::ExitKeys keys{key::F1, key::Tab};
        do {
            radio.Call();
            if (ui::ReturnCode == key::F1) {
                ui::help.Show(ui::Context);
                ui::ReturnCode = 0;
                continue;
            }
            if (ui::ReturnCode == key::Tab) {
                speech::Say("фа+йл перекодиро+вки.");
                speech::Say(table);
                ui::Posit = 0;
                for (;;) {
                    ui::EditLine(46, bottom - 4, table, 68, 30);
                    if (ui::ReturnCode == key::Enter) {
                        if (text::IsBlank(table)) {
                            if (s.mode == kModeUser)
                                s.mode = kModeDos;
                            break;
                        }
                        if (!fs::exists(sys::Path(table))) {
                            sound::Play(Signal::Error);
                            speech::Say("фа+йл не+ существу+ет.");
                            continue;
                        }
                    }
                    if (ui::ReturnCode != key::F1)
                        break;
                    ui::help.Show(ui::Context);
                }
            }
            if (ui::ReturnCode == key::Tab)
                CallWithHelp(check);
        } while (!Pressed({key::Enter, key::Esc}));
    }
    if (ui::ReturnCode != key::Enter) {
        speech::Say(ui::kCancel);
        return;
    }
    s.mode = radio.selected - 1;
    s.printable = check.items[0].on;
    s.user_decode = table;
    speech::Say(ui::kOk);
    if (text::IsBlank(s.user_decode) && s.mode == kModeUser) {
        s.mode = kModeDos;
        speech::Say("Сме+на кодиро+вки.");
        SayCode();
    }
}

// ------------------------------------------------------- главное меню

// Подменю главного меню: Left/Right -- соседние меню, Esc/Backspace -- в
// полосу меню. Возвращает, куда идти дальше: номер меню, 0 -- в полосу,
// 10 -- выйти из меню.
constexpr int kLeaveMenu = 10;

bool CallSubmenu(ui::PopupMenu& menu, int& remembered, int context, int l, int t, int r, int b) {
    ui::Context = context;
    menu.cycle = settings.cycle_menu;
    menu.cursor = settings.cursor;
    menu.SetPosition(l, t, r, b);
    menu.current = remembered;
    const ui::ExitKeys keys{key::Left, key::Right, key::F1, key::Back};
    CallWithHelp(menu);
    return ui::ReturnCode == key::Enter;
}

int NextMenu(int left, int right) {
    switch (ui::ReturnCode) {
    case key::Left: return left;
    case key::Right: return right;
    case key::Esc:
    case key::Back: return 0;
    }
    return kLeaveMenu;
}

ui::PopupMenu Items(std::initializer_list<const char*> items) {
    ui::PopupMenu menu;
    for (const char* item : items)
        menu.items.push_back({item, ""});
    return menu;
}

// Без окна -- ошибка.
Viewer* RequireViewer() {
    Viewer* v = CurrentViewer();
    if (!v)
        sound::Play(Signal::Error);
    return v;
}

int FileMenu() {
    ui::PopupMenu menu = Items({"  Открыть     ", "  Закрыть     ", "  Статистика  ", "  Выход       "});
    const bool chosen = CallSubmenu(menu, file_item, 3, 2, 2, 17, 7);
    file_item = menu.current;
    const int next = NextMenu(8, 2);
    if (!chosen)
        return next;
    switch (menu.current) {
    case 1: LoadNewFile(); break;
    case 2: CloseWindow(); break;
    case 3: Statistics(); break;
    case 4:
        if (settings.exit_confirm && !ui::Yes("     Выйти из программы?     "))
            break;
        for (auto& v : viewers)
            if (v)
                v->Close();
        Stop(0);
    }
    return next;
}

int ReadMenu() {
    ui::PopupMenu menu = Items({"  Весь текст  ", "  Строку      ", "  Блок        "});
    const bool chosen = CallSubmenu(menu, read_item, 4, 7, 2, 22, 6);
    read_item = menu.current;
    const int next = NextMenu(1, 3);
    if (!chosen)
        return next;
    Viewer* v = RequireViewer();
    if (!v)
        return next;
    switch (menu.current) {
    case 1: ReadWindows(); break;
    case 2: v->ReadLine(); break;
    case 3: BlockRead(); break;
    }
    return next;
}

int BlockMenu() {
    ui::PopupMenu menu = Items({"  Начало           ", "  Конец            ", "  Записать в файл  ",
                                "  Время            ", "  Печать           ", "  Разметить        "});
    const bool chosen = CallSubmenu(menu, block_item, 5, 14, 2, 34, 9);
    block_item = menu.current;
    const int next = NextMenu(2, 4);
    if (!chosen)
        return next;
    Viewer* v = RequireViewer();
    if (!v)
        return next;
    switch (menu.current) {
    case 1:
        BlockBegin();
        speech::Say("нача+ло бло+ка.");
        break;
    case 2:
        BlockEnd();
        speech::Say("коне+ц бло+ка.");
        break;
    case 3:
        speech::Say("за+пись бло+ка.");
        BlockWrite();
        break;
    case 4: {
        // Время -- в углу экрана, а не на рамке окна.
        const int left = v->left, top = v->top;
        v->left = 5;
        v->top = 6;
        BlockTime();
        v->left = left;
        v->top = top;
        ui::ClearBuffer();
        break;
    }
    case 5:
        speech::Say("печа+ть бло+ка.");
        PrintBlock();
        break;
    case 6:
        BlockHide();
        speech::Say("бло+к разме+чен.");
        break;
    }
    return next;
}

int BookmarkMenu() {
    ui::PopupMenu menu = Items({"  Список     ", "  Отчистить  "});
    const bool chosen = CallSubmenu(menu, bookmark_item, 6, 26, 2, 40, 5);
    const int next = NextMenu(3, 5);
    if (!chosen)
        return next;
    bookmark_item = menu.current;
    if (menu.current == 1) {
        if (Viewer* v = RequireViewer())
            v->Bookmarks();
    } else
        CleanBookmarks();
    return next;
}

int FindMenu() {
    ui::PopupMenu menu = Items({"  Начать поиск         ", "  Продолжить поиск     ", "  Перейти к строке...  "});
    const bool chosen = CallSubmenu(menu, find_item, 7, 32, 2, 56, 6);
    find_item = menu.current;
    const int next = NextMenu(4, 6);
    if (!chosen)
        return next;
    Viewer* v = RequireViewer();
    if (!v)
        return next;
    if (menu.current == 3)
        v->GotoLine();
    else
        v->Find(menu.current == 2);
    return next;
}

int WindowMenu() {
    ui::PopupMenu menu = Items({"  Список окон   ", "  Размер/сдвиг  "});
    const bool chosen = CallSubmenu(menu, window_item, 8, 44, 2, 61, 5);
    window_item = menu.current;
    const int next = NextMenu(5, 7);
    if (!chosen)
        return next;
    if (menu.current == 1)
        WindowList();
    else if (Viewer* v = RequireViewer())
        v->SetWindow();
    return next;
}

int SetupMenu() {
    ui::PopupMenu menu = Items({"  Общие      ", "  Интерфейс  ", "  Закладки   ", "  Речь       ", "  Чтение     ",
                                "  Звук       ", "  Загрузка   ", "  Вид        ", "  Будильник  ", "  Сохранить  "});
    ui::Screen saved = ui::screen;
    for (;;) {
        ui::screen = saved;
        ui::Show();
        const bool chosen = CallSubmenu(menu, setup_item, 9, 56, 2, 70, 12);
        saved = ui::screen;
        setup_item = menu.current;
        const int next = NextMenu(6, 8);
        if (!chosen)
            return next;
        switch (menu.current) {
        case 1: SetupGeneral(); break;
        case 2: SetupInterface(); break;
        case 3: SetupBookmarks(); break;
        case 4: SetupVoice(); break;
        case 5: SetupReading(); break;
        case 6: SetupSound(); break;
        case 7: SetupStartup(); break;
        case 8: SetupOutlook(); break;
        case 9: SetupAlarms(); break;
        case 10: SaveSettings(); break;
        }
        // Backspace в подменю «Общие» и в списке будильников -- обратно
        // в меню настроек.
        if (!((menu.current == 1 || menu.current == 9) && ui::ReturnCode == key::Back))
            return next;
    }
}

int HelpMenu() {
    ui::PopupMenu menu = Items({"  Клавиши  ", "  Разделы  "});
    const bool chosen = CallSubmenu(menu, help_item, 10, 65, 2, 77, 5);
    help_item = menu.current;
    const int next = NextMenu(7, 1);
    if (!chosen)
        return next;
    if (menu.current == 1)
        ui::help.Show(12);
    else
        HelpTopics();
    return next;
}

} // namespace

void GlobalMenu() {
    static const char* const spoken[] = {"фа+йл.",  "чита+ть.", "бло+к.",      "закла+дки.",
                                         "по+иск.", "о+кна.",   "настро+йки.", "по+мощь."};
    const char* const kMenuString =
        "  Файл    Читать    Блок    Закладки    Поиск    Окна    Настройки    Помощь  ";
    ui::Screen saved = ui::screen;
    ui::Context = 2;
    ui::MenuBar bar;
    bar.items = {"  Файл  ", "  Читать  ", "  Блок  ", "  Закладки  ",
                 "  Поиск  ", "  Окна  ", "  Настройки  ", "  Помощь  "};
    bar.cycle = true;
    bar.cursor = settings.cursor;
    bar.Center();
    bar.current = last_menu;
    ui::PutLine(1, 1, std::string(80, ' '), ui::color.menu.inactive);
    int next = 0;
    bool say_menu = false;
    for (;;) {
        if (next >= 1 && next <= 8) {
            if (say_menu)
                speech::Say(spoken[next - 1]);
            say_menu = true;
            last_menu = next;
            if (Viewer* v = CurrentViewer())
                v->Show();
            ui::Show();
        }
        switch (next) {
        case 0: {
            ui::screen = saved;
            ui::Show();
            ui::Context = 2;
            {
                const ui::ExitKeys keys{key::Down, key::F1};
                bar.Call();
            }
            if (ui::ReturnCode == key::F1) {
                ui::help.Show(ui::Context);
                continue;
            }
            ui::PutLine(2, 1, kMenuString, ui::color.menu.inactive);
            if (ui::ReturnCode == key::Esc) {
                sound::Play(Signal::Start);
                return;
            }
            next = bar.current;
            say_menu = false;
            saved = ui::screen;
            break;
        }
        case 1: next = FileMenu(); break;
        case 2: next = ReadMenu(); break;
        case 3: next = BlockMenu(); break;
        case 4: next = BookmarkMenu(); break;
        case 5: next = FindMenu(); break;
        case 6: next = WindowMenu(); break;
        case 7: next = SetupMenu(); break;
        case 8: next = HelpMenu(); break;
        default:
            sound::Play(Signal::Start);
            return;
        }
        if (ui::ReturnCode == key::Esc) {
            sound::Play(Signal::Start);
            return;
        }
    }
}

} // namespace sv
