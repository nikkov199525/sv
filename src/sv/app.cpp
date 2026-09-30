// app.cpp -- S_U.PAS: главный цикл, завершение программы, окна, статистика,
// время звучания.

#include "sv/app.h"

#include "platform/console.h"
#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/file_dialog.h"
#include "sv/fragments.h"
#include "sv/history.h"
#include "sv/menu.h"
#include "sv/program.h"
#include "sv/settings.h"
#include "sv/viewer.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/utf8.h"
#include "text/words.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <thread>

namespace sv {

namespace {

namespace fs = std::filesystem;
using sound::Signal;

const char* OnOff(bool on, const char* yes, const char* no) {
    return on ? yes : no;
}

// Заглавная буква для сигнала: латинская или русская А..Я (коды 866 --
// 65..90 и 128..159).
bool IsCapital(char32_t c) {
    const int code = text::FromUnicode(text::Encoding::Dos866, c);
    return (code >= 65 && code <= 90) || (code >= 128 && code <= 159);
}

bool IsLatin(char32_t c) {
    return (c >= U'A' && c <= U'Z') || (c >= U'a' && c <= U'z');
}

// Английское слово под курсором (E_U.Local_Eng_Word).
text::WordBounds EnglishWord(std::u32string_view line, int position) {
    if (position < 1 || position > static_cast<int>(line.size()) || !IsLatin(line[position - 1]))
        return {};
    int left = position;
    while (left > 1 && IsLatin(line[left - 2]))
        left--;
    int right = position;
    while (right < static_cast<int>(line.size()) && IsLatin(line[right]))
        right++;
    return {left, right};
}

// Ctrl+Right / Ctrl+Left: сказать слово справа или слева и встать на него.
void WordStep(text::WordStep step) {
    Viewer& v = *CurrentViewer();
    const std::u32string line = v.Line(v.first_line);
    const text::WordBounds word = step == text::WordStep::Next && settings.local != 0
                                      ? text::FindInterval(line, v.offset)
                                      : text::FindWord(line, v.offset, step);
    if (!word) {
        sound::Play(Signal::Edge);
        return;
    }
    if (IsCapital(line[word.left - 1]))
        sound::Play(Signal::Capital);
    if (settings.read_symbols)
        AllSymbolsOn();
    speech::Say(utf8::Encode(line.substr(word.left - 1, word.right - word.left + 1)));
    AllSymbolsOff();
    v.offset = word.left;
}

// Стрелки влево-вправо, Home, End: символ под курсором.
void CursorRight() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Edge);
        return;
    }
    std::u32string line = v->Line(v->first_line);
    // Край строки: дальше -- только при непрерывном перемещении, на
    // следующую строку.
    auto next_line = [&] {
        if (!settings.no_stop || v->first_line >= v->lines) {
            sound::Play(Signal::Edge);
            return false;
        }
        v->first_line++;
        v->offset = 0;
        line = v->Line(v->first_line);
        sound::Play(Signal::Edge);
        return true;
    };
    auto empty_line = [&] {
        if (!text::IsBlank(line))
            return false;
        v->offset = 1;
        sound::Play(Signal::Empty);
        return true;
    };
    if (text::IsBlank(line) && !next_line())
        return;
    if (empty_line())
        return;
    if (v->offset >= static_cast<int>(line.size())) {
        if (!settings.no_stop) {
            sound::Play(Signal::Edge);
            speech::SaySymbol(line.back());
            return;
        }
        if (!next_line())
            return;
        if (empty_line())
            return;
    }
    v->offset++;
    speech::SaySymbol(line[v->offset - 1]);
}

void CursorLeft() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Edge);
        return;
    }
    const std::u32string line = v->Line(v->first_line);
    if (text::IsBlank(line)) {
        sound::Play(Signal::Edge);
        return;
    }
    if (v->offset <= 1) {
        sound::Play(Signal::Edge);
        speech::SaySymbol(line.front());
        return;
    }
    v->offset = std::min(v->offset - 1, static_cast<int>(line.size()));
    speech::SaySymbol(line[v->offset - 1]);
}

void CursorHome() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Edge);
        return;
    }
    v->offset = 1;
    const std::u32string line = v->Line(v->first_line);
    sound::Play(Signal::Edge);
    if (!text::IsBlank(line))
        speech::SaySymbol(line.front());
}

void CursorEnd() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Edge);
        return;
    }
    const std::u32string line = v->Line(v->first_line);
    sound::Play(Signal::Edge);
    if (text::IsBlank(line))
        return;
    v->offset = static_cast<int>(line.size());
    speech::SaySymbol(line.back());
}

// Del: код символа под курсором -- в DOS-866, как у автора; символа, которого
// там нет, -- номер Unicode.
void SayCharCode() {
    Viewer* v = CurrentViewer();
    if (!v)
        return;
    const std::u32string line = v->Line(v->first_line);
    if (line.empty())
        return;
    const char32_t c = line[std::clamp(v->offset, 1, static_cast<int>(line.size())) - 1];
    const int code = text::FromUnicode(text::Encoding::Dos866, c);
    speech::Say(text::FormatNumber(code >= 0 ? code : static_cast<long long>(c)));
}

// F8: кодировка по кругу, пока клавиша нажата.
void NextCode() {
    const int last = text::IsBlank(settings.user_decode) ? kModeUtf8 : kModeUser;
    for (;;) {
        sound::Play(Signal::CodeChange);
        const auto start = std::chrono::steady_clock::now();
        while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds(220) && !ui::KeyPressed())
            ui::Idle();
        settings.mode = settings.mode < last ? settings.mode + 1 : kModeDos;
        if (!ui::KeyPressed() || ui::DefineKey() != key::F8)
            break;
    }
    SayCode();
}

// Ctrl+K: команда блока.
void BlockCommand() {
    speech::Say("Бло+к.");
    while (!ui::KeyPressed()) {
        bool pressed = false;
        for (int i = 0; i < 3 && !pressed; i++) {
            pressed = ui::KeyPressed();
            if (!pressed)
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        if (!pressed)
            sound::Play(Signal::Block);
    }
    switch (ui::DefineKey()) {
    case key::CtrlB:
        if (ui::OnlyCtrl()) {
            BlockBegin();
            speech::Say("нача+ло.");
        }
        break;
    case key::CtrlK:
        if (ui::OnlyCtrl()) {
            BlockEnd();
            speech::Say("коне+ц.");
        }
        break;
    case key::CtrlEnter:
        if (ui::OnlyCtrl())
            BlockRead();
        break;
    case key::CtrlH:
        if (ui::OnlyCtrl()) {
            BlockHide();
            speech::Say("разме+чен.");
        }
        break;
    case key::CtrlW:
        if (ui::OnlyCtrl())
            BlockWrite();
        break;
    case key::CtrlT:
        if (ui::OnlyCtrl())
            BlockTime();
        break;
    case key::CtrlF9:
        if (ui::OnlyCtrl())
            PrintBlock();
        break;
    case key::CtrlL: {
        const Viewer& v = *CurrentViewer();
        if (v.block_begin == 0 || v.block_end == 0) {
            speech::Say("Бло+к неотме+чен.");
            break;
        }
        const long count = v.block_end - v.block_begin + 1;
        speech::SayQuantity(count, "ж слово\\отме+чен\\а\\о\\о");
        speech::SayQuantity(count, "ж \\строк\\а+\\и+\\\\.");
        break;
    }
    }
}

void DrawScreen() {
    if (settings.cursor)
        ui::ShowCursor();
    else
        ui::HideCursor();
    ui::Clear(1, 1, 80, 25);
    Viewer* v = CurrentViewer();
    const std::string number = "{" + std::to_string(current_window) + "}";
    if (!v) {
        ui::Clear(1, 2, 80, 25);
        ui::Frame(1, 2, 80, 25);
        ui::PutLine(3, 2, number, ui::color.message);
    } else {
        v->Show();
        ui::PutLine(v->left + 2, v->top, number, ui::color.message);
        ui::PutLine(v->left + 12, v->top, OnOff(settings.latin_to_russian, "|", "-"), ui::color.message);
        ui::PutLine(v->left + 13, v->top, OnOff(settings.read_symbols, "|", "-"), ui::color.message);
        ui::PutLine(v->left + 14, v->top, OnOff(settings.no_stop, "|", "-"), ui::color.message);
    }
    ui::Show();
    if (v)
        ui::SetCursorXY(v->left, v->top + (v->IsDbf() ? 2 : 1));
}

int WaitKey() {
    while (!ui::KeyPressed()) {
        ui::ShowClock();
        TimeControl();
        VerifyAlarms();
        ui::Idle();
    }
    return ui::DefineKey();
}

// Найти строку, подходящую под условие, ниже или выше текущей.
template <typename Match>
bool FindLine(bool forward, Match match) {
    Viewer* v = CurrentViewer();
    if (!v)
        return false;
    if (forward ? v->first_line == v->lines : v->first_line == 1) {
        sound::Play(Signal::NotFound);
        return false;
    }
    const long step = forward ? 1 : -1;
    for (long n = v->first_line + step; forward ? n <= v->lines : n >= 1; n += step)
        if (match(v->Line(n))) {
            v->first_line = n;
            return true;
        }
    sound::Play(Signal::NotFound);
    return false;
}

// Время звучания строк first..last (Count_Read_Time): число вида ЧЧММСС.
long CountReadTime(long first, long last) {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Error);
        return 0;
    }
    if (first == 0 || last == 0 || first > last)
        return 0;
    // Тики таймера DOS (18,2 в секунду): паузы на знаках препинания и на
    // «и», по 1,2 тика на букву.
    long ticks = 0;
    for (long n = first; n <= last; n++) {
        std::u32string line = v->Line(n);
        if (text::IsBlank(line)) {
            ticks += settings.empty_delay;
            continue;
        }
        line = std::u32string(text::Trim(std::u32string_view(line)));
        auto remove_all = [&](std::u32string_view what, long pause) {
            for (size_t at; (at = line.find(what)) != std::u32string::npos;) {
                ticks += pause;
                line.erase(at, what == U".." ? 1 : what.size());
            }
        };
        remove_all(U"..", 0);
        remove_all(U".", 5);
        remove_all(U",", 2);
        remove_all(U":", 4);
        remove_all(U"?", 6);
        remove_all(U"!", 8);
        remove_all(U" и ", 4);
        remove_all(U" ", 0);
        ticks += static_cast<long>(std::nearbyint(line.size() * 1.2));
    }
    long second = static_cast<long>(std::nearbyint(ticks / 18.2));
    long minute = 0, hour = 0;
    if (second > 60) {
        minute = second / 60;
        second -= minute * 60;
    }
    if (minute > 60) {
        hour = minute / 60;
        minute -= hour * 60;
    }
    auto two = [](long n) {
        const std::string s = std::to_string(n);
        return s.size() < 2 ? std::string(2 - s.size(), '0') + s : s;
    };
    const std::string result = (hour > 0 ? std::to_string(hour) : "") + (minute > 0 ? two(minute) : "00") +
                               (second > 0 ? two(second) : "00");
    return static_cast<long>(text::ParseInt(result).value_or(0));
}

// ЧЧММСС -- «ЧЧ:ММ:СС».
std::string TimeString(long number) {
    std::string s = std::to_string(number);
    if (s.size() < 6)
        s.insert(0, 6 - s.size(), '0');
    s.insert(s.size() - 2, 1, ':');
    s.insert(s.size() - 5, 1, ':');
    return s;
}

void ShowTime(long number) {
    const Viewer& v = *CurrentViewer();
    const std::string time = TimeString(number);
    ui::PutLine(v.left + 18, v.top, " " + time + " ", ui::color.frame);
    ui::Show();
    speech::Say(time);
    while (!ui::KeyPressed()) {
        TimeControl();
        VerifyAlarms();
        ui::ShowClock();
        ui::Idle();
    }
}

} // namespace

// ------------------------------------------------------------ завершение

void Stop(int code) {
    // Настройки сохраняются, пока экран программы ещё открыт: ошибка
    // записи показывается сообщением.
    if (code == 0 && settings.auto_save)
        SaveSettings();
    speech::Shutdown();
    console::DoneKeyboard();
    console::DoneVideo();
    // Сообщение -- в терминал, из которого запустили программу (у DOS-
    // программы оно печаталось поверх возвращённого экрана).
    std::string message = "\n";
    auto line = [&](const std::string& text) { message += text + '\n'; };
    switch (code) {
    case 0:
        line("SPEAKING VIEWER");
        line("версия - " + std::string(kVersion));
        break;
    case 4: line("Прервано пользователем!!!"); break;
    case 5: line("Не найден загружаемый файл"); break;
    }
    sys::WriteToTerminal(message + '\n');
    std::exit(0);
}

// ------------------------------------------------------------- память

long long FreeMemory() {
    // У автора «свободная память» кучи была постоянной (16 Мбайт), а
    // дисковая -- место на диске временных файлов.
    constexpr long long kHeap = 0x1000000;
    if (settings.memory != Memory::Disk)
        return kHeap;
    std::error_code error;
    const std::string dir = text::IsBlank(settings.temp_dir) ? sys::TempDir() : settings.temp_dir;
    const fs::space_info space = fs::space(sys::Path(dir), error);
    if (error)
        return 0;
    return static_cast<long long>(std::min<uintmax_t>(space.available, 0x7FFFFFFF));
}

void AllSymbolsOn() {
    speech::SetAllSymbols(true);
}

void AllSymbolsOff() {
    speech::SetAllSymbols(false);
}

// ------------------------------------------------------------ поиск строк

void FindEmpty(bool forward) {
    if (FindLine(forward, [](const std::u32string& line) { return text::IsBlank(line); }))
        sound::Play(Signal::Empty);
}

void FindIndent(bool forward) {
    if (FindLine(forward, [](const std::u32string& line) { return IsIndent(line); })) {
        if (settings.read_indent)
            speech::Say("абза+ц.");
        else
            sound::Play(Signal::Indent);
    }
}

// ------------------------------------------------------------------ окна

void WindowList() {
    ui::Context = 21;
    ui::PopupMenu menu;
    std::vector<int> windows;
    for (int w = 1; w <= 9; w++)
        if (viewers[w] && viewers[w]->lines > 0) {
            menu.items.push_back({std::to_string(w) + std::string(7, ' ') + viewers[w]->name + viewers[w]->ext, ""});
            windows.push_back(w);
        }
    if (windows.empty())
        return;
    menu.cycle = settings.cycle_menu;
    menu.cursor = settings.cursor;
    menu.Center();
    {
        const ui::ExitKeys keys{key::F1};
        for (;;) {
            menu.Call();
            if (ui::ReturnCode != key::F1)
                break;
            ui::help.Show(ui::Context);
        }
    }
    if (ui::ReturnCode != key::Enter) {
        speech::Say(ui::kCancel);
        return;
    }
    current_window = windows[menu.current - 1];
    speech::SayOrdinal(current_window, "\\ое\\ окно+. ");
    speech::Say(CurrentViewer()->name + CurrentViewer()->ext);
}

void CloseWindow() {
    Viewer* v = CurrentViewer();
    if (!v)
        return;
    v->Close();
    viewers[current_window].reset();
    speech::Say("Закры+то.");
}

void LoadNewFile() {
    InputHistory history(kLoadHistory);
    history.items[0] = settings.open_mask;
    // Списка нет, пока в нём нет ни одного прошлого ввода.
    const bool listed = !history.items[1].empty();
    int point = 1;
    bool save = true;
    std::string mask;
    std::vector<std::string> files;
    speech::Say("и+мя фа+йла.");
    ui::Frame(21, 11, 60, 13);
    ui::PutLine(31, 11, " Введите имя файла ", ui::color.title);
    {
        const ui::ExitKeys keys{key::F1, key::Down, key::Up};
        do {
            ui::Context = 13;
            if (listed) {
                mask = history.items[point - 1];
                speech::Say(mask);
            }
            ui::EditLine(22, 12, mask, 255, 37);
            if (ui::ReturnCode == key::Down) {
                if (listed && point < history.last)
                    point++;
                else
                    sound::Play(Signal::Edge);
            }
            if (ui::ReturnCode == key::Up) {
                if (listed && point > 1)
                    point--;
                else
                    sound::Play(Signal::Edge);
            }
            if (ui::ReturnCode == key::F1) {
                ui::help.Show(ui::Context);
                continue;
            }
            if (ui::ReturnCode == key::Enter) {
                if (text::EqualNoCase(text::Trim(mask), text::Trim(history.items[point - 1])))
                    save = false;
                if (HasWildcards(mask))
                    files = ChooseByMask(mask);
                else if (!fs::is_regular_file(sys::Path(mask))) {
                    ShowError(8);
                    ui::ReturnCode = 0;
                } else
                    files = {mask};
            }
        } while (ui::ReturnCode != key::Enter && ui::ReturnCode != key::Esc);
    }
    if (ui::ReturnCode == key::Esc) {
        speech::Say(ui::kCancel);
        return;
    }
    history.Save(save, mask);
    speech::Say(ui::kOk);
    // Отмеченные в диалоге файлы -- в окна начиная с текущего.
    for (size_t n = 0; n < files.size() && current_window + n <= 9; n++) {
        const int w = current_window + static_cast<int>(n);
        if (!viewers[w])
            viewers[w] = std::make_unique<Viewer>(files[n]);
        else
            viewers[w]->Load(files[n]);
        settings.last_files[w] = sys::Utf8(fs::absolute(sys::Path(files[n])));
    }
    speech::Say("загру+жено.");
}

// ------------------------------------------------------------ статистика

void Statistics() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Error);
        return;
    }
    ui::Context = 15;
    ui::Clear(21, 8, 60, 18);
    ui::Frame(21, 8, 60, 18);
    ui::PutLine(35, 8, " Статистика ", ui::color.title);
    const std::string read_time = TimeString(CountReadTime(1, v->lines));
    std::error_code error;
    const auto size = fs::file_size(sys::Path(v->Path()), error);
    if (error)
        return;
    const std::string file = v->name + v->ext;
    const std::string bytes = text::FormatNumber(static_cast<long long>(size));
    // Строки окна (1-я и 9-я пустые) и то же для речи: без разделителей
    // классов в числах.
    std::array<std::string, 10> shown, spoken;
    shown[2] = " Имя файла :  " + file;
    shown[3] = " Размер Файла :  " + bytes;
    shown[8] = " Общее звучание :  " + read_time;
    spoken[2] = "И+мя фа+йла: " + file;
    spoken[3] = "Разме+р Фа+йла: " + std::to_string(size);
    spoken[8] = "О+бщее звуча+ние: " + read_time;
    if (v->IsDbf()) {
        const Dbf& d = *v->dbf;
        shown[4] = " Записей :  " + text::FormatNumber(d.records);
        shown[5] = " Всего полей :  " + text::FormatNumber(static_cast<long long>(d.fields.size()));
        shown[6] = " Дата последней редакции :  " + d.last_date;
        shown[7] = " Размер записи :  " + text::FormatNumber(d.record_length);
        spoken[4] = "За+писей: " + std::to_string(d.records);
        spoken[5] = "Всего+ поле+й: " + std::to_string(d.fields.size());
        spoken[6] = "Да+та после+дней реда+кции: " + d.last_date;
        spoken[7] = "Разме+р за+писи: " + std::to_string(d.record_length);
    } else {
        const TextInfo& t = v->info;
        const std::string longest = std::to_string(t.max_width) + ':' + std::to_string(t.max_width_line);
        const std::string shortest = std::to_string(t.min_width) + ':' + std::to_string(t.min_width_line);
        shown[4] = " Строк :  " + text::FormatNumber(t.lines);
        shown[5] = " Самая длинная строка :  " + longest;
        shown[6] = " Самая короткая строка :  " + shortest;
        shown[7] = " Левый отступ :  " + text::FormatNumber(t.left_margin);
        spoken[4] = "Стро+к: " + std::to_string(t.lines);
        spoken[5] = "Са+мая дли+нная строка+: " + longest;
        spoken[6] = "Са+мая коро+ткая строка+: " + shortest;
        spoken[7] = "Ле+вый о+тступ: " + std::to_string(t.left_margin);
    }
    for (int n = 1; n <= 9; n++)
        ui::PutLine(22, 8 + n, text::Left(shown[n], 38), ui::color.message);
    ui::Show();
    speech::Say("Стати+стика.");
    int key;
    do {
        key = ui::DefineKey();
        if (key == key::CtrlEnter) {
            for (int n = 1; n <= 9; n++) {
                speech::Say(spoken[n] + '.');
                if (ui::KeyPressed()) {
                    sound::Play(Signal::BreakRead);
                    ui::DefineKey();
                    break;
                }
            }
        } else if (key == key::F1)
            ui::help.Show(ui::Context);
        else if (key >= '1' && key <= '7')
            speech::Say(spoken[key - '0' + 1]);
    } while (key != key::Esc);
}

// ---------------------------------------------------------------- справка

void HelpTopics() {
    static const char* const topics[] = {
        "2.  Главное меню программы                   ",
        "3.  Меню  \"Файл\"                             ",
        "4.  Меню  \"Читать\"                           ",
        "5.  Меню  \"Блок\"                             ",
        "6.  Меню  \"Закладки\"                         ",
        "7.  Меню  \"Поиск\"                            ",
        "8.  Меню  \"Окна\"                             ",
        "9.  Меню  \"Настройки\"                        ",
        "10. Меню  \"Помощь\"                           ",
        "11. Меню  \"Настройки\"/\"Общие\"                ",
        "12. Клавиши                                  ",
        "13. Ввод имени нового файла                  ",
        "14. Диалог выбора файлов                     ",
        "15. Окно статистики                          ",
        "16. Список закладок                          ",
        "17. Меню функций списка закладок             ",
        "18. Диалог ввода имени новой закладки        ",
        "19. Диалог поиска строки                     ",
        "20. Диалог ввода номера строки               ",
        "21. Список окон                              ",
        "22. Размер/сдвиг                             ",
        "23. Настройки вида                           ",
        "24. Диалог выбора памяти                     ",
        "25. Диалоговая область  \"Разное\"             ",
        "26. Настройки интерфейса                     ",
        "27. Настройки закладок                       ",
        "28. Настройки речи                           ",
        "29. Настройки чтения                         ",
        "30. Настройки звука                          ",
        "31. Настройки будильника                     ",
        "32. Запись блока в файл                      ",
        "33.                                          ",
        "34. Настройка процесса загрузки              ",
        "35. Установка будильника                     ",
        "36. Словарь                                  ",
        "37. Файл описания замен                      ",
        "38. Файл описания распаковки                 ",
        "39. Пользовательские файлы перекодировки     ",
        "40. Строки редактирования                    ",
        "41. Диалоговые кнопки                        ",
        "42. Меню                                     ",
        "43. Файлы инициализации и конфигурации       ",
        "44. История программы  \"SPEAKING VIEWER\"     ",
        "45. Новое в этой версии                      ",
    };
    ui::PopupMenu menu;
    menu.items.push_back({"1.  Программа  \"SPEAKING VIEWER\"  версии " + std::string(kVersion), ""});
    for (const char* topic : topics)
        menu.items.push_back({topic, ""});
    menu.title = " Разделы ";
    menu.cycle = settings.cycle_menu;
    menu.cursor = settings.cursor;
    menu.SetPosition(17, 5, 63, 21);
    for (;;) {
        menu.Call();
        if (ui::ReturnCode != key::Enter)
            break;
        ui::help.Show(menu.current);
    }
}

// --------------------------------------------------------------- закладки

void CleanBookmarks() {
    if (!ui::Yes("     Отчистить файл закладок?     "))
        return;
    const std::string file = ProgramFile(kBookmarkFile);
    if (!fs::is_regular_file(sys::Path(file))) {
        ShowError(3);
        return;
    }
    // Как у автора: на место закладки на пропавший файл встаёт последняя
    // (с номером удалённой).
    std::vector<Bookmark> bookmarks = ReadBookmarks(file);
    long removed = 0;
    for (size_t n = 0; n < bookmarks.size();) {
        if (fs::exists(sys::Path(bookmarks[n].file))) {
            n++;
            continue;
        }
        const int32_t number = bookmarks[n].number;
        bookmarks[n] = bookmarks.back();
        bookmarks[n].number = number;
        bookmarks.pop_back();
        removed++;
    }
    WriteBookmarks(file, bookmarks);
    ui::ShowMessage("     Удалено " + text::FormatNumber(removed) + " закладок     ", "");
}

// ---------------------------------------------------------- время звучания

void BlockTime() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Error);
        return;
    }
    if (v->block_begin == 0 || v->block_end == 0) {
        speech::Say("оши+бка.  бло+к не+ отме+чен.");
        return;
    }
    speech::Say("вре+мя.");
    ShowTime(CountReadTime(v->block_begin, v->block_end));
}

void RestTime() {
    Viewer* v = CurrentViewer();
    if (!v) {
        sound::Play(Signal::Error);
        return;
    }
    speech::Say("оста+лось ");
    ShowTime(CountReadTime(v->first_line, v->lines));
}

// ------------------------------------------------------------ главный цикл

void MainLoop(bool read_first) {
    if (read_first)
        ReadWindows();
    sound::Play(Signal::Start);
    for (;;) {
        DrawScreen();
        ui::Context = 1;
        const int code = WaitKey();
        Viewer* v = CurrentViewer();
        if (code >= key::Alt9 && code <= key::Alt1) {
            current_window = -code - 119;
            speech::Say("акно+ " + std::to_string(current_window));
            continue;
        }
        switch (code) {
        case key::Esc:
            if (ui::Ctrl()) {
                // Ctrl+[ -- замедление (справка, разделы 1 и 12).
                TempoSlower();
                break;
            }
            if (!settings.exit_confirm || ui::Yes("     Выйти из программы?     "))
                return;
            sound::Play(Signal::Start);
            break;
        case key::Down:
            if (!v)
                sound::Play(Signal::Edge);
            else if (!ui::OnlyShift())
                v->Next(1);
            else
                FindEmpty(true);
            break;
        case key::Up:
            if (!v)
                sound::Play(Signal::Edge);
            else if (!ui::OnlyShift())
                v->Last(1);
            else
                FindEmpty(false);
            break;
        case key::PgDn:
            if (v)
                v->Next(ui::OnlyShift() ? settings.jump2 : 20);
            break;
        case key::PgUp:
            if (v)
                v->Last(ui::OnlyShift() ? settings.jump2 : 20);
            break;
        case key::CtrlPgDn:
            if (v)
                v->Next(settings.jump1);
            break;
        case key::CtrlPgUp:
            if (v)
                v->Last(settings.jump1);
            break;
        case key::CtrlHome:
        case key::CtrlEnd:
            if (ui::OnlyCtrl()) {
                if (v) {
                    v->first_line = code == key::CtrlHome ? 1 : v->lines;
                    v->offset = 1;
                }
                sound::Play(Signal::Edge);
            }
            break;
        case key::Right:
            if (!ui::OnlyShift())
                CursorRight();
            else
                FindIndent(true);
            break;
        case key::Left:
            if (!ui::OnlyShift())
                CursorLeft();
            else
                FindIndent(false);
            break;
        case key::Home: CursorHome(); break;
        case key::End: CursorEnd(); break;
        case key::Del: SayCharCode(); break;
        case key::CtrlRight:
        case key::CtrlLeft:
            if (v && ui::OnlyCtrl()) {
                const bool right = code == key::CtrlRight;
                if (!v->IsDbf())
                    WordStep(right ? text::WordStep::Next : text::WordStep::Previous);
                else if (right ? v->current_field < static_cast<int>(v->dbf->fields.size())
                               : v->current_field > 1) {
                    v->current_field += right ? 1 : -1;
                    speech::Say(v->dbf->fields[v->current_field - 1].name);
                } else
                    sound::Play(Signal::Edge);
            }
            break;
        case key::Space:
            if (ui::OnlyAlt() && v)
                v->ReadLine();
            else
                ReadWindows();
            break;
        case key::CtrlEnter:
            if (ui::OnlyCtrl())
                ReadWindows();
            break;
        case key::F5:
            if (v)
                v->ReadLine();
            break;
        case key::F6: ReadWindows(); break;
        case key::CtrlM:
            if (v && ui::OnlyCtrl()) {
                v->Bookmarks();
                sound::Play(Signal::Start);
            }
            break;
        case key::F10: GlobalMenu(); break;
        case key::F3:
            LoadNewFile();
            sound::Play(Signal::Start);
            break;
        case key::F7:
            if (v) {
                v->Find(false);
                sound::Play(Signal::Start);
            }
            break;
        case key::CtrlL:
            if (v && ui::OnlyCtrl())
                v->Find(true);
            break;
        case key::CtrlI: // Tab
            if (ui::OnlyCtrl()) {
                settings.read_indent = !settings.read_indent;
                speech::Say(std::string(OnOff(settings.read_indent, "", "не, ")) + "Чита+ть абза+ц.");
            } else if (v) {
                const bool forward = settings.config.find.forward;
                settings.config.find.forward = true;
                v->Find(true);
                settings.config.find.forward = forward;
            }
            break;
        case key::ShiftTab:
            if (v) {
                const bool forward = settings.config.find.forward;
                settings.config.find.forward = false;
                v->Find(true);
                settings.config.find.forward = forward;
            }
            break;
        case key::F8:
            if (v)
                NextCode();
            break;
        case key::CtrlF5:
            if (v && ui::OnlyCtrl()) {
                speech::Say("Разме+р/сдви+г окна+.");
                v->SetWindow();
                sound::Play(Signal::Start);
            }
            break;
        case key::ShiftF9:
            if (ui::OnlyShift()) {
                if (ui::Yes("         Сохранить параметры?         "))
                    SaveSettings();
                sound::Play(Signal::Start);
            }
            break;
        case key::CtrlW:
            if (ui::OnlyCtrl()) {
                settings.read_word = !settings.read_word;
                speech::Say(std::string(OnOff(settings.read_word, "", "не, ")) + "Чита+ть сло+во.");
            }
            break;
        case key::CtrlE:
            if (ui::OnlyCtrl()) {
                settings.read_empty = !settings.read_empty;
                speech::Say(std::string(OnOff(settings.read_empty, "", "не, ")) + "чита+ть пусты+е.");
            }
            break;
        case key::CtrlA:
            if (ui::OnlyCtrl()) {
                settings.read_line = !settings.read_line;
                speech::Say(std::string(OnOff(settings.read_line, "", "не")) + "Чита+ть всю+ строку+.");
            }
            break;
        case key::CtrlB:
            if (ui::OnlyCtrl()) {
                settings.read_all_windows = !settings.read_all_windows;
                speech::Say(std::string("чита+ть ") +
                            OnOff(settings.read_all_windows, "все+ о+кна.", "одно+ окно+."));
            }
            break;
        case key::CtrlO:
            if (ui::OnlyCtrl()) {
                settings.read_symbols = !settings.read_symbols;
                speech::Say(std::string("чита+ть ") +
                            OnOff(settings.read_symbols, "все+ си+мволы.", "бе+з си+мволов."));
            }
            break;
        case key::CtrlN:
            if (ui::OnlyCtrl()) {
                settings.no_stop = !settings.no_stop;
                speech::Say(std::string(OnOff(settings.no_stop, "непреры+вное", "ограни+ченое")) +
                            " горизонта+льное перемеще+ние.");
            }
            break;
        case key::CtrlR:
            if (ui::OnlyCtrl()) {
                settings.latin_to_russian = !settings.latin_to_russian;
                speech::Say(std::string(OnOff(settings.latin_to_russian, "", "не. ")) +
                            "Лати+нские в ру+сские.");
            }
            break;
        case key::CtrlC:
            settings.capital = !settings.capital;
            speech::Say(settings.capital ? "индика+ция загла+вных бу+кв."
                                         : "индика+ция загла+вных бу+кв вы+ключена.");
            break;
        case key::CtrlV:
            settings.talk = !settings.talk;
            speech::SetTalk(true);
            if (settings.talk) {
                ApplySettings();
                speech::Say("ре+чь вклю+чена.");
            } else
                speech::Say("ре+чь вы+ключена.");
            speech::SetTalk(settings.talk);
            break;
        case key::CtrlY:
            if (ui::OnlyCtrl()) {
                settings.ukrainian = !settings.ukrainian;
                speech::SetCyrillic(settings.ukrainian ? speech::Cyrillic::Ukrainian : speech::Cyrillic::Russian);
                speech::Say(settings.ukrainian ? "украи+нский." : "ру+сский.");
            }
            break;
        case key::CtrlT:
            if (ui::OnlyCtrl()) {
                settings.german = !settings.german;
                speech::SetLatin(settings.german ? speech::Latin::German : speech::Latin::English);
                speech::Say(settings.german ? "неме+цкий." : "англи+йский.");
            }
            break;
        case key::CtrlRightBracket:
            if (ui::OnlyCtrl())
                TempoFaster();
            break;
        case key::CtrlK:
            if (v && ui::OnlyCtrl())
                BlockCommand();
            break;
        case key::AltT:
            if (ui::OnlyAlt())
                speech::SayTime();
            break;
        case key::AltD:
            if (ui::OnlyAlt())
                speech::SayDate();
            break;
        case key::AltW:
            if (ui::OnlyAlt())
                speech::SayOrdinal(current_window, "\\ое\\ окно+. ");
            break;
        case key::AltP:
            if (ui::OnlyAlt())
                SayPercent();
            break;
        case key::AltL:
            if (ui::OnlyAlt())
                SayLineNumber();
            break;
        case key::AltO:
            if (v && ui::OnlyAlt())
                SayOffset();
            break;
        case key::AltC:
            if (ui::OnlyAlt())
                SayCode();
            break;
        case key::AltM:
            if (ui::OnlyAlt())
                SayFreeMemory();
            break;
        case key::AltV:
            if (ui::OnlyAlt())
                speech::Say("ве+рсия " + std::string(kVersion));
            break;
        case key::AltA:
            if (v && ui::OnlyAlt())
                speech::SayQuantity(v->lines, "ж /Всего+ \\строк\\а+\\и+\\\\.");
            break;
        case key::Alt0:
            if (ui::OnlyAlt()) {
                WindowList();
                sound::Play(Signal::Start);
            }
            break;
        case key::AltF3:
            if (v && ui::OnlyAlt()) {
                CloseWindow();
                sound::Play(Signal::Start);
            }
            break;
        case key::AltR:
            if (v)
                RestTime();
            break;
        case key::AltY:
        case key::AltN:
        case key::AltE:
        case key::AltF:
            if (v && ui::OnlyAlt() && v->IsDbf()) {
                const DbfField& field = v->dbf->fields[v->current_field - 1];
                switch (code) {
                case key::AltY: speech::Say(std::string("ти+п по+ля: ") + DbfTypeName(field.type)); break;
                case key::AltN: speech::Say("назва+ние по+ля: " + field.name); break;
                case key::AltE: speech::Say("разме+р по+ля: " + std::to_string(field.length)); break;
                case key::AltF: speech::Say(std::to_string(v->current_field)); break;
                }
            }
            break;
        case key::CtrlG:
            if (v && ui::OnlyCtrl()) {
                v->GotoLine();
                sound::Play(Signal::Start);
            }
            break;
        case key::CtrlS:
            if (v && ui::OnlyCtrl()) {
                Statistics();
                sound::Play(Signal::Start);
            }
            break;
        case key::F1:
            ui::help.Show(ui::Context);
            sound::Play(Signal::Start);
            break;
        case key::F2:
            if (v) {
                SaveAs();
                sound::Play(Signal::Start);
            }
            break;
        case key::F4:
            settings.printable = !settings.printable;
            speech::Say(std::string("quonted printable ") + OnOff(settings.printable, "вклю+чен.", "вы+ключен."));
            break;
        case key::F9:
            if (text::IsBlank(settings.fragments_file) && !settings.change_fragments) {
                speech::Say("неподклю+чен фа+йл описа+ния заме+н.");
                break;
            }
            settings.change_fragments = !settings.change_fragments;
            if (settings.change_fragments) {
                LoadFragments();
                speech::Say("заме+на.");
            } else {
                UnloadFragments();
                speech::Say("бе+з заме+ны.");
            }
            break;
        case key::AltF9: ChooseFragments(); break;
        case key::CtrlF8: ChooseUserDecode(); break;
        case key::CtrlF6:
            if (v && ui::OnlyCtrl()) {
                const std::u32string line = v->Line(v->first_line);
                const text::WordBounds word = EnglishWord(line, v->offset);
                if (!word) {
                    speech::Say("неудае+тся локализова+ть сло+во.");
                    break;
                }
                Translate(utf8::Encode(line.substr(word.left - 1, word.right - word.left + 1)));
            }
            break;
        case key::CtrlF9:
            if (v)
                Print();
            break;
        }
    }
}

} // namespace sv
