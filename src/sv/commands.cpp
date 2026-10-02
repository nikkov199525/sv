// commands.cpp -- E_U.PAS: команды окна текста -- чтение, сохранение,
// словарь, печать, будильник, темп речи, блок.

#include "sv/app.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/file_dialog.h"
#include "sv/fragments.h"
#include "sv/history.h"
#include "sv/program.h"
#include "sv/settings.h"
#include "sv/viewer.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "text/utf8.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <thread>

namespace sv {

namespace {

namespace fs = std::filesystem;
using sound::Signal;

bool alarm_off = false;

std::string FileName(const std::string& path) {
    return sys::Utf8(sys::Path(path).filename());
}

std::tm Now() {
    const std::time_t now = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &now);
#else
    localtime_r(&now, &local);
#endif
    return local;
}

void Sleep(int ms) {
    std::this_thread::sleep_for(std::chrono::milliseconds(ms));
}

// Строка ввода имени файла со списком прошлых вводов (у автора -- в каждой
// команде свой экземпляр). false -- Esc.
struct FileInput {
    HistoryKind kind;
    int width;
    int context;         // раздел справки на время ввода; 0 -- не менять
    bool must_exist;     // файл должен существовать (Get_Name)
    std::string current; // первое место списка
};

bool AskFileName(const FileInput& in, std::string& mask, std::string& file) {
    InputHistory history(in.kind);
    int point = 1;
    if (in.must_exist)
        history.items[0] = in.current;
    speech::Say("и+мя фа+йла.");
    if (in.must_exist)
        ui::Clear(21, 11, 60, 13);
    ui::Frame(21, 11, 60, 13);
    ui::PutLine(31, 11, " Введите имя файла ", ui::color.title);
    file.clear();
    {
        const ui::ExitKeys keys{key::F1, key::Down, key::Up};
        do {
            if (in.context)
                ui::Context = in.context;
            if (history.exists) {
                mask = history.items[point - 1];
                speech::Say(mask);
            }
            ui::EditLine(22, 12, mask, 80, in.width);
            if (ui::ReturnCode == key::Down) {
                if (history.exists && point < history.last)
                    point++;
                else
                    sound::Play(Signal::Edge);
            }
            if (ui::ReturnCode == key::Up) {
                if (history.exists && point > 1)
                    point--;
                else
                    sound::Play(Signal::Edge);
            }
            if (ui::ReturnCode == key::F1) {
                ui::help.Show(ui::Context);
                continue;
            }
            if (ui::ReturnCode == key::Enter) {
                if (HasWildcards(mask)) {
                    const std::vector<std::string> chosen = ChooseByMask(mask);
                    file = chosen.empty() ? "" : chosen.front();
                } else
                    file = mask;
                if (in.must_exist) {
                    if (text::IsBlank(file) || ui::ReturnCode == key::Esc)
                        break;
                    if (!fs::is_regular_file(sys::Path(file))) {
                        sound::Play(Signal::Error);
                        speech::Say("Фа+йл не+ на+йден.");
                        ui::ReturnCode = 0;
                    }
                }
            }
        } while (ui::ReturnCode != key::Enter && ui::ReturnCode != key::Esc);
    }
    if (ui::ReturnCode == key::Esc) {
        speech::Say(ui::kCancel);
        if (in.must_exist)
            sound::Play(Signal::Start);
        return false;
    }
    history.Save(!text::EqualNoCase(text::Trim(mask), text::Trim(history.items[point - 1])), mask);
    return true;
}

// Общее у «Сохранить как» и «Записать блок»: имя файла, «уже существует» и
// запись строк first..last в UTF-8.
bool WriteLines(HistoryKind kind, int width, bool clear_choice, long first, long last) {
    static std::string mask;
    std::string file;
    if (!AskFileName({kind, width, kind == kBlockHistory ? 32 : 0, false, ""}, mask, file))
        return false;
    const std::string shown = FileName(file);
    bool append = false;
    const bool existed = fs::exists(sys::Path(file));
    if (existed) {
        ui::ButtonRow choice;
        choice.items = {" Перезаписать ", " Добавить ", " Отмена "};
        const std::string message =
            std::string(std::max<int>(33 - static_cast<int>(text::Width(shown)), 0) / 2, ' ') +
            "Файл  " + shown + "  уже существует";
        choice.message = text::PadRight(message, 54);
        choice.cursor = settings.cursor;
        choice.margin_left = 4;
        choice.margin_top = 1;
        if (clear_choice)
            ui::Clear(13, 9, 68, 16);
        choice.SetPosition(13, 9, 68, 16);
        choice.Call();
        if (choice.current == 3 || ui::ReturnCode == key::Esc) {
            speech::Say(ui::kCancel);
            return false;
        }
        append = choice.current == 2;
    }
    std::ofstream out(sys::Path(file), std::ios::binary | (append ? std::ios::app : std::ios::trunc));
    if (!out) {
        ShowError(7);
        return false;
    }
    if (!existed)
        speech::Say("Со+здан фа+йл " + shown);
    Viewer& v = *CurrentViewer();
    for (long n = first; n <= last; n++)
        out << v.LineUtf8(n) << sys::kEol;
    return true;
}

// Файл, выбранный по F-клавише настроек (Get_Name): false -- отмена.
bool ChooseExistingFile(HistoryKind kind, const std::string& current, std::string& file) {
    static std::array<std::string, 2> masks;
    std::string& mask = masks[kind == kXltHistory ? 0 : 1];
    return AskFileName({kind, 37, 0, true, current}, mask, file);
}

bool IsLatin(char32_t c) {
    return (c >= U'A' && c <= U'Z') || (c >= U'a' && c <= U'z');
}

void PrintLines(long first, long last) {
    Viewer* v = CurrentViewer();
    if (first < 1 || first > v->lines || last > v->lines || last < 1 || last < first)
        return;
    std::vector<std::string> lines;
    for (long n = first; n <= last; n++)
        lines.push_back(v->LineUtf8(n));
    sys::Print(lines);
}

} // namespace

// ----------------------------------------------------------- сообщения

void SayLineNumber() {
    speech::SayOrdinal(CurrentViewer()->first_line, "\\ая\\ строка+.  ");
}

void SayOffset() {
    speech::SayOrdinal(CurrentViewer()->offset, "\\ая\\ пози+ция.  ");
}

void SayPercent() {
    const Viewer& v = *CurrentViewer();
    const long long percent =
        v.lines == 0 ? 0 : static_cast<long long>(std::nearbyint(v.first_line * 100.0 / v.lines));
    speech::SayQuantity(percent, "м \\проце+нт\\\\а\\ов\\.");
}

void SayFreeMemory() {
    speech::Say("свабо+дно ");
    speech::SayByteSize(FreeMemory());
    switch (settings.memory) {
    case Memory::High: speech::Say("ве+рхней"); break;
    case Memory::Low: speech::Say("ни+жней"); break;
    case Memory::Disk: speech::Say("ди+сковой"); break;
    }
    speech::Say("па+мяти.");
}

void SayCode() {
    switch (settings.mode) {
    case kModeWindows: speech::Say("ви+ндовс."); break;
    case kModeKoi8: speech::Say("ко+и8 э+р."); break;
    case kModeUtf8: speech::Say("ютэ эф 8."); break;
    case kModeUser: speech::Say("по+льзовательская."); break;
    default: speech::Say("обы+чная."); break;
    }
}

void ReadWindows() {
    for (int w = current_window; w <= 9; w++) {
        Viewer* v = viewers[w].get();
        if (!v)
            continue;
        if (v->lines > 0)
            v->ReadText();
        if (v->first_line < v->lines || !settings.read_all_windows)
            break;
        if (w < 9 && viewers[w + 1] && viewers[w + 1]->lines > 0)
            current_window = w + 1;
    }
}

// --------------------------------------------------------------- файлы

void SaveAs() {
    const Viewer& v = *CurrentViewer();
    if (!WriteLines(kSaveHistory, 38, false, 1, v.lines))
        return;
    speech::Say("Запи+сано: " + std::to_string(v.lines) + " стро+к.");
}

void ChooseUserDecode() {
    std::string file;
    if (!ChooseExistingFile(kXltHistory, settings.user_decode, file))
        return;
    settings.user_decode = file;
    speech::Say(ui::kOk);
    if (text::IsBlank(settings.user_decode) && settings.mode == kModeUser) {
        settings.mode = kModeDos;
        speech::Say("Сме+на кодиро+вки.");
        SayCode();
    }
    sound::Play(Signal::Start);
}

void ChooseFragments() {
    std::string file;
    if (!ChooseExistingFile(kFragmentsHistory, settings.fragments_file, file))
        return;
    settings.fragments_file = file;
    speech::Say(ui::kOk);
    if (text::IsBlank(settings.fragments_file) && settings.change_fragments) {
        settings.change_fragments = false;
        speech::Say("бе+з заме+ны.");
    }
    if (settings.change_fragments)
        LoadFragments();
    sound::Play(Signal::Start);
}

// ------------------------------------------------------------- словарь

namespace {

// Словарь SV.DIC: записи «английское слово -- перевод» (string[20] и
// string[72] в DOS-866), SV.NDX -- с какой записи начинается каждая буква.
struct DictionaryRecord {
    std::string english;
    std::string russian;
};

constexpr long kRecordSize = 21 + 73;

class Dictionary {
public:
    bool Open() {
        file_.open(sys::Path(ProgramFile(kDictionary)), std::ios::binary);
        if (!file_)
            return false;
        file_.seekg(0, std::ios::end);
        size_ = static_cast<long>(file_.tellg()) / kRecordSize;
        return true;
    }
    long Size() const { return size_; }
    bool Read(long record, DictionaryRecord& out) {
        if (record < 0 || record >= size_)
            return false;
        std::string bytes(kRecordSize, '\0');
        file_.clear();
        file_.seekg(record * kRecordSize);
        file_.read(bytes.data(), kRecordSize);
        auto field = [&](size_t at, size_t capacity) {
            const size_t length = std::min<size_t>(static_cast<unsigned char>(bytes[at]), capacity);
            return text::ToUtf8(bytes.substr(at + 1, length), text::Encoding::Dos866);
        };
        out = {field(0, 20), field(21, 72)};
        return true;
    }

private:
    std::ifstream file_;
    long size_ = 0;
};

} // namespace

void Translate(const std::string& word) {
    std::string english = text::Upper(text::Trim(word));
    auto letter = [&] { return english.empty() ? 0 : english[0] - 'A' + 1; };
    if (letter() < 1 || letter() > 26) {
        ShowError(28);
        return;
    }
    std::array<int32_t, 27> index{}; // [1..26]
    {
        std::ifstream ndx(sys::Path(ProgramFile(kDictionaryIndex)), std::ios::binary);
        if (!ndx) {
            ShowError(25);
            return;
        }
        char bytes[26 * 4];
        if (!ndx.read(bytes, sizeof bytes)) {
            ShowError(26);
            return;
        }
        for (int n = 1; n <= 26; n++) {
            const auto* b = reinterpret_cast<const unsigned char*>(bytes + (n - 1) * 4);
            index[n] = static_cast<int32_t>(b[0] | b[1] << 8 | b[2] << 16 | b[3] << 24);
        }
    }
    Dictionary dictionary;
    if (!dictionary.Open()) {
        ShowError(27);
        return;
    }
    long address = index[letter()];
    const ui::Screen saved = ui::screen;
    DictionaryRecord record;
    while (address / kRecordSize < dictionary.Size() || text::IsBlank(english)) {
        if (!dictionary.Read(address / kRecordSize, record))
            break;
        if (text::StartsWith(record.english, english) || text::IsBlank(english)) {
            const std::string eng(text::Trim(record.english));
            const std::string rus(text::Trim(record.russian));
            const int eng_width = static_cast<int>(text::Width(eng));
            const int rus_width = static_cast<int>(text::Width(rus));
            const int wide = text::Width(record.russian) > text::Width(record.english) ? rus_width : eng_width;
            const int le = (80 - wide) / 2;
            const int re = le + wide + 1;
            ui::Clear(le - 3, 11, re + 3, 15);
            ui::Frame(le - 3, 11, re + 3, 15);
            ui::PutLine((80 - eng_width) / 2 + 1, 12, eng, ui::color.message);
            ui::PutLine(le + 1, 14, rus, ui::color.message);
            ui::Show();
            sound::Play(text::IsBlank(english) ? Signal::DictionaryStep : Signal::Dictionary);
            speech::Say(eng);
            if (!text::IsBlank(english)) {
                Sleep(6);
                speech::Say(rus);
            }
            bool leave = false;
            while (!leave) {
                {
                    const ui::ExitKeys keys{key::F1, key::CtrlEnter, key::Space, key::Up,
                                            key::Down, key::CtrlEnd, key::CtrlHome};
                    ui::ViewLine(le + 1, 14, rus, re - le - 1);
                }
                switch (ui::ReturnCode) {
                case key::Esc:
                    // (у автора здесь стирался словарь: он был распакованной
                    // из архива копией; распаковки больше нет)
                    sound::Play(Signal::Start);
                    ui::screen = saved;
                    ui::Show();
                    return;
                case key::F1: ui::help.Show(ui::Context); break;
                case key::Enter: {
                    // новое слово
                    InputHistory history(kDictionaryHistory);
                    ui::Clear(21, 8, 60, 10);
                    ui::Frame(21, 8, 60, 10);
                    speech::Say("по+иск.");
                    int point = 1;
                    {
                        const ui::ExitKeys help_key{key::F1};
                        do {
                            if (history.exists)
                                english = history.items[point - 1];
                            speech::Say(english);
                            {
                                const ui::ExitKeys arrows{key::Up, key::Down};
                                ui::EditLine(22, 9, english, 255, 38);
                            }
                            if (ui::ReturnCode == key::Down) {
                                if (history.exists && point < history.last)
                                    point++;
                                else
                                    sound::Play(Signal::Edge);
                            }
                            if (ui::ReturnCode == key::Up) {
                                if (history.exists && point > 1)
                                    point--;
                                else
                                    sound::Play(Signal::Edge);
                            }
                            if (ui::ReturnCode == key::F1)
                                ui::help.Show(ui::Context);
                            if (ui::ReturnCode == key::Enter &&
                                !IsLatin(english.empty() ? 0 : static_cast<unsigned char>(english[0]))) {
                                sound::Play(Signal::Error);
                                speech::Say("неве+рный пе+рвый си+мвол.");
                                ui::ReturnCode = 0;
                            }
                        } while (ui::ReturnCode != key::Esc && ui::ReturnCode != key::Enter);
                    }
                    const bool same = text::EqualNoCase(text::Trim(english),
                                                        text::Trim(history.items[point - 1])) &&
                                      ui::ReturnCode == key::Enter;
                    if (ui::ReturnCode == key::Esc) {
                        english.clear();
                        address -= kRecordSize;
                        speech::Say(ui::kCancel);
                    }
                    history.Save(!same, english);
                    english = text::Upper(english);
                    address = (letter() >= 1 && letter() <= 26 ? index[letter()] : address + kRecordSize) -
                              kRecordSize;
                    speech::Say(ui::kOk);
                    leave = true;
                    break;
                }
                case key::Space:
                    if (ui::OnlyAlt())
                        speech::Say(record.english);
                    break;
                case key::CtrlEnter:
                    if (ui::OnlyCtrl())
                        speech::Say(record.russian);
                    break;
                case key::Down:
                    if (address / kRecordSize < dictionary.Size() - 1) {
                        english.clear();
                        leave = true;
                    } else
                        sound::Play(Signal::Edge);
                    break;
                case key::Up:
                    if (address > 0) {
                        address -= 2 * kRecordSize;
                        english.clear();
                        leave = true;
                    } else
                        sound::Play(Signal::Edge);
                    break;
                case key::CtrlHome:
                    english.clear();
                    address = -kRecordSize;
                    leave = true;
                    break;
                case key::CtrlEnd:
                    address = kRecordSize * (dictionary.Size() - 2);
                    english.clear();
                    leave = true;
                    break;
                }
            }
            ui::screen = saved;
            ui::Show();
        }
        address += kRecordSize;
        const int l = letter();
        if (l >= 1 && l < 26 && address > index[l + 1] && index[l + 1] > 0 && !text::IsBlank(english))
            break;
    }
    ShowError(28);
}

// --------------------------------------------------------------- печать

void Print() {
    if (!CurrentViewer())
        return;
    if (ui::Yes("       Печатать весь текст?       "))
        PrintLines(1, CurrentViewer()->lines);
}

void PrintBlock() {
    Viewer* v = CurrentViewer();
    if (!v)
        return;
    if (v->block_begin == 0 || v->block_end == 0) {
        speech::Say("оши+бка.  бло+к не+ отме+чен.");
        return;
    }
    if (ui::Yes("       Печатать блок?       "))
        PrintLines(v->block_begin, v->block_end);
}

// ------------------------------------------------- определение кодировки

int DetectCode(std::string_view line) {
    const std::string_view s = text::Trim(line);
    if (s.empty())
        return 0;
    // Строка с не-ASCII, правильная как UTF-8, -- UTF-8 (у автора русский
    // UTF-8 выходил KOI8 или Windows: байт D1 в KOI8 -- гласная «я»).
    if (s.find_first_of("\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E\x8F"
                        "\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F"
                        "\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF"
                        "\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF"
                        "\xC0\xC1\xC2\xC3\xC4\xC5\xC6\xC7\xC8\xC9\xCA\xCB\xCC\xCD\xCE\xCF"
                        "\xD0\xD1\xD2\xD3\xD4\xD5\xD6\xD7\xD8\xD9\xDA\xDB\xDC\xDD\xDE\xDF"
                        "\xE0\xE1\xE2\xE3\xE4\xE5\xE6\xE7\xE8\xE9\xEA\xEB\xEC\xED\xEE\xEF"
                        "\xF0\xF1\xF2\xF3\xF4\xF5\xF6\xF7\xF8\xF9\xFA\xFB\xFC\xFD\xFE\xFF") !=
            std::string_view::npos &&
        utf8::IsValid(s))
        return 4;
    size_t dos = 0, high = 0, latin = 0;
    for (unsigned char c : s) {
        high += c >= 192;
        dos += (c >= 128 && c <= 175) || (c >= 224 && c <= 241);
        latin += (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
    }
    if (latin > dos && latin > high)
        return 0xFF;
    if (dos > high)
        return 1;
    if (high <= dos)
        return 0;
    // Windows-1251 или KOI8-R -- по гласным.
    static const auto vowels = [] {
        std::array<std::array<bool, 256>, 2> table{};
        for (char32_t c : std::u32string_view(U"аеёиоуыэюяАЕЁИОУЫЭЮЯ")) {
            table[0][text::FromUnicode(text::Encoding::Windows1251, c)] = true;
            table[1][text::FromUnicode(text::Encoding::Koi8R, c)] = true;
        }
        return table;
    }();
    size_t windows = 0, koi = 0;
    for (unsigned char c : s) {
        windows += vowels[0][c];
        koi += vowels[1][c];
    }
    if (windows > koi)
        return 2;
    if (koi > windows)
        return 3;
    return 0;
}

// ---------------------------------------------- точное время, будильник

void TimeControl() {
    if (!settings.exact_time || !settings.sound)
        return;
    std::tm t = Now();
    if ((t.tm_min >= 1 && t.tm_min <= 58) || (t.tm_sec >= 1 && t.tm_sec <= 50))
        return;
    if (t.tm_min == 59 && t.tm_sec == 0)
        return;
    // Последние секунды часа -- короткие сигналы, начало часа -- длинный.
    if (t.tm_min == 59) {
        int old_second = 0;
        bool signal = false;
        do {
            ui::ShowClock();
            t = Now();
            if (old_second != t.tm_sec) {
                signal = true;
                old_second = t.tm_sec;
            }
            if (t.tm_sec >= 55 && t.tm_sec <= 59 && signal) {
                sound::Play(Signal::BeforeHour);
                signal = false;
            }
            ui::Idle();
        } while (t.tm_sec != 0);
    }
    t = Now();
    if (t.tm_min == 0 && t.tm_sec == 0)
        sound::Play(Signal::Hour);
    do {
        t = Now();
        VerifyAlarms();
        ui::ShowClock();
        ui::Idle();
    } while (t.tm_sec == 0);
    ui::ClearBuffer();
}

void VerifyAlarms() {
    const std::tm t = Now();
    char now[8];
    std::snprintf(now, sizeof now, "%02d:%02d", t.tm_hour, t.tm_min);
    for (Alarm& alarm : settings.config.alarms) {
        if (!alarm.on)
            continue;
        if (alarm.time != now) {
            alarm_off = false;
            continue;
        }
        if (alarm_off)
            return;
        sound::Play(Signal::Alarm);
        speech::Say(alarm.message);
        for (;;) {
            Sleep(800);
            if (ui::KeyPressed())
                break;
            sound::Play(Signal::Alarm);
            if (ui::KeyPressed())
                break;
        }
        ui::ClearBuffer();
        alarm_off = true;
        if (!alarm.every_day)
            alarm.on = false;
    }
}

// ----------------------------------------------------------- темп речи
//
// Скорость -- 0..150, быстрее -- больше; ниже 100 шаг -- два (у автора --
// темп выше 50). Ускорение -- -3..+7, 0 -- нормально, плюс -- быстрее.
// Пауза -- авто, 0..255, длиннее -- больше. Шкалы те же, что в
// Настройки -> Речь и в SV.INI; ] -- число больше, [ -- меньше.
//
// Шаг -- на каждое нажатие; повторы удерживаемой клавиши, скопившиеся в
// очереди, забираются и тоже делают шаг, а число говорится одно, в конце.
// (У автора цикл «пока нажата клавиша» её не забирал и при автоповторе
// уводил темп до упора.)

namespace {

// Число для речи; минус синтезатор не произносит.
std::string Signed(int n) {
    return n < 0 ? "ми+нус " + std::to_string(-n) : std::to_string(n);
}

// Шаг скорости, как у автора: от 100 и с нечётного -- на единицу, ниже --
// на два. false -- дальше некуда.
bool TempoStep(bool faster) {
    int& speed = settings.speed;
    const bool single = faster ? (speed >= 100 && speed <= 149) || speed % 2 != 0
                               : speed >= 101 || speed % 2 != 0;
    const int next = faster ? speed + (single ? 1 : 2) : speed - (single ? 1 : 2);
    if (next < 0 || next > 150) {
        sound::Play(Signal::Edge);
        return false;
    }
    speed = next;
    return true;
}

void ChangeTempo(bool faster, int key) {
    if (TempoStep(faster))
        while (ui::TakeRepeat(key) && TempoStep(faster)) {
        }
    speech::SetSpeed(settings.speed);
    speech::Say(text::FormatNumber(settings.speed));
}

bool AccelStep(bool faster) {
    int& accel = settings.acceleration;
    const int next = faster ? accel + 1 : accel - 1;
    if (next < -3 || next > 7) {
        sound::Play(Signal::Edge);
        return false;
    }
    accel = next;
    return true;
}

void ChangeAccel(bool faster, int key) {
    if (AccelStep(faster))
        while (ui::TakeRepeat(key) && AccelStep(faster)) {
        }
    speech::SetAcceleration(settings.acceleration, settings.pause);
    speech::Say(Signed(settings.acceleration));
}

// Ниже нуля -- авто (по ускорению), как в настройках.
bool PauseStep(bool longer) {
    int& pause = settings.pause;
    const int next = longer ? pause + 1 : pause - 1;
    if (next < speech::kPauseAuto || next > 255) {
        sound::Play(Signal::Edge);
        return false;
    }
    pause = next;
    return true;
}

void ChangePause(bool longer, int key) {
    if (PauseStep(longer))
        while (ui::TakeRepeat(key) && PauseStep(longer)) {
        }
    speech::SetAcceleration(settings.acceleration, settings.pause);
    speech::Say(settings.pause == speech::kPauseAuto ? "а+вто" : std::to_string(settings.pause));
}

} // namespace

void TempoFaster() {
    ChangeTempo(true, key::CtrlRightBracket);
}

void TempoSlower() {
    ChangeTempo(false, key::Esc);
}

void AccelFaster() {
    ChangeAccel(true, key::CtrlRightBracket);
}

void AccelSlower() {
    ChangeAccel(false, key::Esc);
}

void PauseLonger() {
    ChangePause(true, key::CtrlRightBracket);
}

void PauseShorter() {
    ChangePause(false, key::Esc);
}

// ---------------------------------------------------------------- блок

void BlockBegin() {
    Viewer& v = *CurrentViewer();
    v.block_begin = v.first_line;
    v.block_end = 0;
}

void BlockEnd() {
    Viewer& v = *CurrentViewer();
    if (v.block_begin == 0) {
        v.block_begin = 1;
        v.block_end = v.first_line;
        speech::Say("бло+к отме+чен с пе+рвой строки+.");
        return;
    }
    if (v.block_begin > v.first_line) {
        speech::Say("оши+бка.  коне+ц вы+ше нача+ла.");
        return;
    }
    v.block_end = v.first_line;
}

void BlockRead() {
    Viewer& v = *CurrentViewer();
    if (v.block_begin == 0 || v.block_end == 0) {
        speech::Say("оши+бка.  бло+к не+ отме+чен.");
        return;
    }
    const long line = v.first_line;
    v.first_line = v.block_begin;
    v.break_read_line = v.block_end;
    v.ReadText();
    v.first_line = line;
}

void BlockHide() {
    Viewer& v = *CurrentViewer();
    v.block_begin = 0;
    v.block_end = 0;
}

void BlockWrite() {
    Viewer& v = *CurrentViewer();
    if (v.block_begin == 0 || v.block_end == 0) {
        speech::Say("оши+бка.  бло+к не+ отме+чен.");
        return;
    }
    ui::Context = 32;
    if (!WriteLines(kBlockHistory, 37, true, v.block_begin, v.block_end))
        return;
    const long count = v.block_end - v.block_begin + 1;
    speech::SayQuantity(count, "ж слово \\запи+сан\\а\\о\\о");
    speech::SayQuantity(count, "ж \\строк\\а+\\и+\\\\.");
}

} // namespace sv
