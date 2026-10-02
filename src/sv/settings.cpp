// settings.cpp -- P_U.PAS: RParam, SParam, Set_Viewer_Param,
// Set_Default_Param.

#include "sv/settings.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/file_dialog.h"
#include "sv/fragments.h"
#include "sv/program.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "ui/dialogs.h"

#include <algorithm>
#include <fstream>
#include <functional>
#include <vector>

namespace sv {

Settings settings;

namespace {

namespace fs = std::filesystem;

const char* const kColorNames[16] = {
    "black",     "blue",        "green",      "cyan",      "red",           "magenta",
    "brown",     "light_gray",  "dark_gray",  "light_blue", "light_green",  "light_cyan",
    "light_red", "light_magenta", "yellow",   "white",
};

const char* OnOff(bool on) {
    return on ? "on" : "off";
}

std::string ColorValue(uint8_t attr) {
    return std::string(kColorNames[attr & 0x0F]) + '-' + kColorNames[attr >> 4];
}

// Строка «ИМЯ= значение»: имя (заглавными) и значение как есть.
struct IniLine {
    std::string key;
    std::string value;
};

IniLine Split(const std::string& line) {
    const size_t equal = line.find('=');
    if (equal == std::string::npos)
        return {text::Upper(text::Trim(line)), {}};
    return {text::Upper(text::Trim(std::string_view(line).substr(0, equal))),
            std::string(text::Trim(std::string_view(line).substr(equal + 1)))};
}

bool ParseOnOff(const std::string& value, bool& out) {
    const std::string v = text::Upper(value);
    if (v == "ON")
        out = true;
    else if (v == "OFF")
        out = false;
    else
        return false;
    return true;
}

bool ParseRange(const std::string& value, long lo, long hi, long& out) {
    const auto number = text::ParseInt(value);
    if (!number || *number < lo || *number > hi)
        return false;
    out = static_cast<long>(*number);
    return true;
}

// Раздел SV.INI: разбор строки; false -- строка неверна.
using SectionParser = std::function<bool(const IniLine&)>;

bool ParseGeneral(const IniLine& l, Settings& s) {
    const std::string value = text::Upper(l.value);
    if (l.key == "OPEN_MASK") {
        s.open_mask = l.value;
        return true;
    }
    if (l.key == "LAST_PATH") {
        last_path = l.value;
        return true;
    }
    if (text::StartsWith(l.key, "PROTECTED_MODE"))
        return true;
    if (text::StartsWith(l.key, "INVOKEDMEMORY")) {
        if (value == "LOW")
            s.memory = Memory::Low;
        else if (value == "HIGH")
            s.memory = Memory::High;
        else if (value == "DISK")
            s.memory = Memory::Disk;
        else
            return false;
        return true;
    }
    if (text::StartsWith(l.key, "CYCLEOBJ"))
        return ParseOnOff(l.value, s.cycle_menu);
    if (text::StartsWith(l.key, "AUTOSAVE"))
        return ParseOnOff(l.value, s.auto_save);
    if (text::StartsWith(l.key, "TAB"))
        return ParseOnOff(l.value, s.tab);
    if (text::StartsWith(l.key, "EXITCONFIRM"))
        return ParseOnOff(l.value, s.exit_confirm);
    if (text::StartsWith(l.key, "LATIN2RUSS"))
        return ParseOnOff(l.value, s.latin_to_russian);
    if (text::StartsWith(l.key, "NOSTOP"))
        return ParseOnOff(l.value, s.no_stop);
    if (text::StartsWith(l.key, "JUMP")) {
        const size_t comma = l.value.find(',');
        const auto first = text::ParseInt(l.value.substr(0, comma == std::string::npos ? 0 : comma));
        if (!first || comma == std::string::npos)
            return false;
        s.jump1 = static_cast<long>(std::max<long long>(*first, 0));
        const auto second = text::ParseInt(l.value.substr(comma + 1));
        if (!second)
            return false;
        s.jump2 = static_cast<long>(std::max<long long>(*second, 0));
        return true;
    }
    if (text::StartsWith(l.key, "EXACT_TIME"))
        return ParseOnOff(l.value, s.exact_time);
    if (text::StartsWith(l.key, "CHANGE_FRAG"))
        return ParseOnOff(l.value, s.change_fragments);
    if (text::StartsWith(l.key, "CHFRAG_FILE")) {
        if (!text::IsBlank(l.value) && !fs::is_regular_file(sys::Path(l.value)))
            return false;
        s.fragments_file = text::IsBlank(l.value) ? "" : l.value;
        return true;
    }
    if (text::StartsWith(l.key, "LOCAL")) {
        if (value == "WORD")
            s.local = 0;
        else if (value == "INTERVAL")
            s.local = 1;
        else
            return false;
        return true;
    }
    return false;
}

bool ParseInterface(const IniLine& l, Settings& s) {
    const std::pair<const char*, bool*> keys[] = {
        {"CLOCK", &s.clock},        {"MOUSE", &s.mouse},        {"CURSOR", &s.cursor},
        {"PERCENT", &s.show_percent}, {"COORDS", &s.show_coords}, {"FREEMEMORY", &s.show_memory},
        {"CODE", &s.show_code},
    };
    for (const auto& [name, flag] : keys)
        if (text::StartsWith(l.key, name) && ParseOnOff(l.value, *flag))
            return true;
    return false;
}

bool ParseBookmark(const IniLine& l, Settings& s) {
    const std::pair<const char*, bool*> keys[] = {
        {"GLOBAL", &s.global_bookmarks}, {"SHOWLINE", &s.bookmark_line}, {"AUTO_ADD", &s.auto_bookmarks}};
    for (const auto& [name, flag] : keys)
        if (text::StartsWith(l.key, name) && ParseOnOff(l.value, *flag))
            return true;
    return false;
}

// Ключи уже прочитаны? Тогда ключи прежних версий (Temp, Accel) их не
// перекрывают.
bool ini_has_speed = false;
bool ini_has_accel = false;

bool ParseSynthesizer(const IniLine& l, Settings& s) {
    long number;
    if (text::StartsWith(l.key, "TALK") && ParseOnOff(l.value, s.talk))
        return true;
    if (text::StartsWith(l.key, "DICTOR") && ParseRange(l.value, 0, 3, number)) {
        s.dictor = static_cast<int>(number);
        return true;
    }
    // Голоса в ядре, папка не нужна: не существующая -- не ошибка (у
    // автора без папки дикторских файлов речи не было).
    if (text::StartsWith(l.key, "VOICEDIRECTORY")) {
        std::string dir = l.value;
        if (!dir.empty() && dir.back() == sys::kSeparator)
            dir.pop_back();
        s.voice_dir = dir;
        return true;
    }
    // Новые и прежние ключи -- только целиком: Acceleration начинается с
    // Accel, а шкалы у них разные.
    if (l.key == "SPEED" && ParseRange(l.value, 0, 150, number)) {
        s.speed = static_cast<int>(number);
        ini_has_speed = true;
        return true;
    }
    if (l.key == "ACCELERATION" && ParseRange(l.value, -3, 7, number)) {
        s.acceleration = static_cast<int>(number);
        ini_has_accel = true;
        return true;
    }
    if (text::StartsWith(l.key, "PAUSE")) {
        if (text::EqualNoCase(l.value, "AUTO"))
            number = speech::kPauseAuto;
        else if (!ParseRange(l.value, -1, 255, number))
            return false;
        s.pause = static_cast<int>(number);
        return true;
    }
    // Ключи прежних версий, шкалы наоборот: Temp 0..150 (0 -- быстрее
    // всего), Accel 3..13 (10 -- нормально, меньше -- быстрее).
    if (l.key == "TEMP" && ParseRange(l.value, 0, 150, number)) {
        if (!ini_has_speed)
            s.speed = 150 - static_cast<int>(number);
        return true;
    }
    if (l.key == "ACCEL" && ParseRange(l.value, 3, 13, number)) {
        if (!ini_has_accel)
            s.acceleration = 10 - static_cast<int>(number);
        return true;
    }
    return false;
}

bool ParseReading(const IniLine& l, Settings& s) {
    const std::pair<const char*, bool*> keys[] = {
        {"EMPTYLINE", &s.read_empty},    {"INDENT", &s.read_indent},
        {"FIRSTWORD", &s.read_word},     {"LINE", &s.read_line},
        {"READSPACEBAR", &s.read_space}, {"SYMBOLS", &s.read_symbols},
        {"WINBYWIN", &s.read_all_windows}, {"CAPITAL", &s.capital},
    };
    for (const auto& [name, flag] : keys)
        if (text::StartsWith(l.key, name) && ParseOnOff(l.value, *flag))
            return true;
    if (text::StartsWith(l.key, "AOS")) {
        const size_t dash = l.value.find('-');
        long from, to;
        if (dash != std::string::npos && ParseRange(l.value.substr(0, dash), 0, 255, from) &&
            ParseRange(l.value.substr(dash + 1), 0, 255, to) && to >= from) {
            s.silence_from = static_cast<int>(from);
            s.silence_to = static_cast<int>(to);
            return true;
        }
    }
    if (text::StartsWith(l.key, "EMPTY_DELAY")) {
        if (const auto number = text::ParseInt(l.value)) {
            s.empty_delay = static_cast<uint8_t>(*number); // byte у автора
            return true;
        }
    }
    return false;
}

bool ParseSound(const IniLine& l, Settings& s) {
    const std::pair<const char*, bool*> keys[] = {
        {"STATUS", &s.sound},           {"EMPTYBELL", &s.empty_bell}, {"BELLOFEND", &s.end_bell},
        {"SEPARATE_WIN", &s.window_bell}, {"LOADSOUND", &s.load_sound},
    };
    for (const auto& [name, flag] : keys)
        if (text::StartsWith(l.key, name) && ParseOnOff(l.value, *flag))
            return true;
    return false;
}

bool ParseStartup(const IniLine& l, Settings& s) {
    // Эти три при неверном значении выключаются, но ошибкой не считаются.
    const std::pair<const char*, bool*> lenient[] = {
        {"LOAD_LAST_FILES", &s.load_last_files}, {"OPEN_DIALOG", &s.open_dialog},
        {"READ_ONSTART", &s.read_on_start}};
    for (const auto& [name, flag] : lenient)
        if (text::StartsWith(l.key, name)) {
            if (!ParseOnOff(l.value, *flag))
                *flag = false;
            return true;
        }
    const std::pair<const char*, bool*> keys[] = {
        {"INDENT_CONTROL", &s.indent_control}, {"DBF_CONTROL", &s.dbf_control},
        {"ARC_CONTROL", &s.archive_control},   {"HTML_CONTROL", &s.html_control},
        {"SHOWLINK", &s.html_links},           {"DOC_CONTROL", &s.doc_control},
        {"SHOWPROCESS", &s.show_process},      {"OLD_POSIT", &s.last_position},
        {"AUTODETECT_CODE", &s.detect_code},
    };
    for (const auto& [name, flag] : keys)
        if (text::StartsWith(l.key, name) && ParseOnOff(l.value, *flag))
            return true;
    long number;
    if (text::StartsWith(l.key, "WORD97_STLEN") && ParseRange(l.value, 24, 250, number)) {
        s.word97_width = static_cast<int>(number);
        return true;
    }
    return false;
}

bool ParseLanguage(const IniLine& l, Settings& s) {
    const std::string value = text::Upper(l.value);
    if (text::StartsWith(l.key, "LAT_LANGUAGE") && (value == "ENGLISH" || value == "GERMAN")) {
        s.german = value == "GERMAN";
        return true;
    }
    if (text::StartsWith(l.key, "CYR_LANGUAGE") && (value == "RUSSIAN" || value == "UKRAINIAN")) {
        s.ukrainian = value == "UKRAINIAN";
        return true;
    }
    return false;
}

bool ParseOutlook(const IniLine& l, Settings& s) {
    if (text::StartsWith(l.key, "CODE")) {
        static const char* const modes[] = {"NORMAL", "WINDOWS", "KOI8", "UTF-8", "USER_RECODING"};
        for (int m = 0; m < 5; m++)
            if (text::Upper(l.value) == modes[m]) {
                s.mode = m;
                return true;
            }
    }
    if (text::StartsWith(l.key, "USER_DECODE")) {
        if (text::IsBlank(l.value)) {
            s.user_decode.clear();
            return true;
        }
        if (fs::is_regular_file(sys::Path(l.value))) {
            s.user_decode = l.value;
            return true;
        }
    }
    return text::StartsWith(l.key, "Q_PRINTABLE") && ParseOnOff(l.value, s.printable);
}

// Цвет «текст-фон». Не найденное имя -- прежнее значение: у автора номера
// цветов переходили от строки к строке.
bool ParseColors(const IniLine& l, Settings& s, int& foreground, int& background) {
    ui::Colors& c = s.colors;
    const std::pair<const char*, uint8_t*> keys[] = {
        {"TEXT", &c.text},    {"TITLE", &c.title},          {"MESSAGE", &c.message},
        {"FRAME", &c.frame},  {"TIME", &c.time},            {"MARK", &c.marked},
        {"MENU.ACTITEM", &c.menu.active},  {"MENU.NOACTITEM", &c.menu.inactive},
        {"MENU.FRAME", &c.menu.frame},     {"MENU.TITLE", &c.menu.title},
    };
    const std::string value = text::Upper(l.value);
    const size_t dash = value.find('-');
    const std::string back(text::Trim(value.substr(dash == std::string::npos ? 0 : dash + 1)));
    const std::string fore(text::Trim(value.substr(0, dash == std::string::npos ? 0 : dash)));
    for (const auto& [name, attr] : keys) {
        if (!text::StartsWith(l.key, name))
            continue;
        int found = 16;
        for (int n = 0; n < 16; n++)
            if (text::Upper(kColorNames[n]) == back) {
                background = n;
                break;
            }
        for (int n = 0; n < 16; n++)
            if (text::Upper(kColorNames[n]) == fore) {
                foreground = found = n;
                break;
            }
        if (found < 16) {
            *attr = static_cast<uint8_t>(foreground | (background << 4));
            return true;
        }
        return false;
    }
    return false;
}

bool ParseLastFiles(const IniLine& l, Settings& s) {
    for (int n = 1; n <= 9; n++)
        if (l.key == "FILE" + std::to_string(n)) {
            s.last_files[n] = l.value;
            return true;
        }
    return false;
}

void LoadIni() {
    ini_has_speed = ini_has_accel = false;
    std::ifstream in(sys::Path(ProgramFile(kIniFile)), std::ios::binary);
    if (!in) {
        ShowError(14);
        return;
    }
    std::vector<std::string> lines;
    for (std::string raw; std::getline(in, raw);) {
        if (!raw.empty() && raw.back() == '\r')
            raw.pop_back();
        // SV.INI прежних версий -- в кодировке ANSI Windows.
        lines.emplace_back(text::Trim(text::LegacyToUtf8(raw, text::Encoding::Windows1251)));
    }
    int foreground = 0, background = 0;
    struct Section {
        const char* name;
        int error;
        SectionParser parse;
    };
    Settings& s = settings;
    const Section sections[] = {
        {"[GENERAL]", 15, [&](const IniLine& l) { return ParseGeneral(l, s); }},
        {"[INTERFACE]", 16, [&](const IniLine& l) { return ParseInterface(l, s); }},
        {"[BOOK-MARK]", 17, [&](const IniLine& l) { return ParseBookmark(l, s); }},
        {"[SINTEZIZER]", 18, [&](const IniLine& l) { return ParseSynthesizer(l, s); }},
        {"[READING]", 19, [&](const IniLine& l) { return ParseReading(l, s); }},
        {"[SOUND]", 20, [&](const IniLine& l) { return ParseSound(l, s); }},
        {"[STARTUP]", 23, [&](const IniLine& l) { return ParseStartup(l, s); }},
        {"[LANGUAGE]", 32, [&](const IniLine& l) { return ParseLanguage(l, s); }},
        {"[OUTLOOK]", 24, [&](const IniLine& l) { return ParseOutlook(l, s); }},
        {"[COLORS]", 21,
         [&](const IniLine& l) { return ParseColors(l, s, foreground, background); }},
        {"[LAST-FILES]", 21, [&](const IniLine& l) { return ParseLastFiles(l, s); }},
    };
    const Section* current = nullptr;
    for (size_t n = 0; n < lines.size(); n++) {
        const std::string& line = lines[n];
        if (text::IsBlank(line) || line[0] == ';')
            continue;
        if (line[0] == '[') {
            current = nullptr;
            for (const Section& section : sections)
                if (text::Upper(line) == section.name)
                    current = &section;
            continue;
        }
        if (current) {
            if (!current->parse(Split(line)))
                ShowError(current->error);
        } else if (n + 1 < lines.size()) // строка вне разделов, кроме последней
            ShowError(22);
    }
}

} // namespace

void SetDefaults() {
    Settings& s = settings;
    s = Settings();
    s.temp_dir = sys::TempDir();
    std::string voice_dir = program_dir;
    if (!voice_dir.empty())
        voice_dir.pop_back();
    s.voice_dir = voice_dir;
    s.colors = ui::kDefaultColors;
}

void LoadSettings() {
    ui::Clear(1, 1, ui::kWidth, ui::kHeight);
    ui::Show();
    SetDefaults();
    ApplySettings();
    ui::SetClockRow(0);
    const std::string config_file = ProgramFile(kConfigFile);
    if (!fs::exists(sys::Path(config_file))) {
        settings.config = Config{{false, false, false, false, false}, {}};
        for (Alarm& alarm : settings.config.alarms)
            alarm.every_day = false;
        ShowError(12);
    } else if (const auto config = ReadConfig(config_file))
        settings.config = *config;
    else
        ShowError(13);
    LoadIni();
    ApplySettings();
}

void SaveSettings() {
    Settings& s = settings;
    if (!WriteConfig(ProgramFile(kConfigFile), s.config))
        ShowError(9);
    std::ofstream ini(sys::Path(ProgramFile(kIniFile)), std::ios::binary | std::ios::trunc);
    if (!ini) {
        ShowError(11);
        return;
    }
    auto line = [&](const std::string& text) { ini << text << "\r\n"; };
    auto flag = [&](const char* name, bool on) { line(std::string(name) + "= " + OnOff(on)); };
    static const char* const memory_names[] = {"High", "Low", "Disk"};
    line("[GENERAL]");
    line(std::string("InvokedMemory= ") + memory_names[static_cast<int>(s.memory)]);
    line("Protected_Mode= off");
    flag("CycleObj", s.cycle_menu);
    flag("AutoSave", s.auto_save);
    flag("Tab", s.tab);
    flag("ExitConfirm", s.exit_confirm);
    flag("Latin2Russ", s.latin_to_russian);
    flag("NoStop", s.no_stop);
    line("Jump= " + std::to_string(s.jump1) + ',' + std::to_string(s.jump2));
    flag("Exact_Time", s.exact_time);
    flag("Change_Frag", s.change_fragments);
    line("ChFrag_File= " + s.fragments_file);
    line(std::string("Local= ") + (s.local == 0 ? "Word" : "Interval"));
    line("Open_Mask= " + s.open_mask);
    line("Last_Path= " + last_path);
    line("");
    line("[INTERFACE]");
    flag("Clock", s.clock);
    flag("Mouse", s.mouse);
    flag("Cursor", s.cursor);
    flag("PerCent", s.show_percent);
    flag("Coords", s.show_coords);
    flag("FreeMemory", s.show_memory);
    flag("Code", s.show_code);
    line("");
    line("[BOOK-MARK]");
    flag("Global", s.global_bookmarks);
    flag("ShowLine", s.bookmark_line);
    flag("Auto_Add", s.auto_bookmarks);
    line("");
    line("[SINTEZIZER]");
    flag("Talk", s.talk);
    line("Dictor= " + std::to_string(s.dictor));
    line("VoiceDirectory= " + s.voice_dir);
    line("Speed= " + std::to_string(s.speed));
    line("Acceleration= " + std::to_string(s.acceleration));
    line("Pause= " + (s.pause == speech::kPauseAuto ? std::string("Auto") : std::to_string(s.pause)));
    line("");
    line("[READING]");
    flag("EmptyLine", s.read_empty);
    flag("Indent", s.read_indent);
    flag("FirstWord", s.read_word);
    flag("Line", s.read_line);
    flag("ReadSpaceBar", s.read_space);
    flag("Symbols", s.read_symbols);
    flag("WinByWin", s.read_all_windows);
    flag("Capital", s.capital);
    line("AOS= " + std::to_string(s.silence_from) + '-' + std::to_string(s.silence_to));
    line("Empty_Delay= " + std::to_string(s.empty_delay));
    line("");
    line("[SOUND]");
    flag("Status", s.sound);
    flag("EmptyBell", s.empty_bell);
    flag("BellOfEnd", s.end_bell);
    flag("Separate_Win", s.window_bell);
    flag("LoadSound", s.load_sound);
    line("");
    line("[STARTUP]");
    flag("Indent_Control", s.indent_control);
    flag("DBF_Control", s.dbf_control);
    flag("Arc_Control", s.archive_control);
    flag("Html_Control", s.html_control);
    flag("ShowLink", s.html_links);
    flag("Doc_Control", s.doc_control);
    line("Word97_StLen= " + std::to_string(s.word97_width));
    flag("ShowProcess", s.show_process);
    flag("Old_Posit", s.last_position);
    flag("AutoDetect_Code", s.detect_code);
    flag("Load_Last_Files", s.load_last_files);
    flag("Open_Dialog", s.open_dialog);
    flag("Read_OnStart", s.read_on_start);
    line("");
    line("[LANGUAGE]");
    line(std::string("Lat_Language= ") + (s.german ? "German" : "English"));
    line(std::string("Cyr_Language= ") + (s.ukrainian ? "Ukrainian" : "Russian"));
    line("");
    line("[OUTLOOK]");
    static const char* const mode_names[] = {"Normal", "Windows", "KOI8", "utf-8", "User_Recoding"};
    line(std::string("Code= ") + mode_names[s.mode]);
    line("User_Decode= " + s.user_decode);
    flag("Q_Printable", s.printable);
    line("");
    line("[COLORS]");
    const ui::Colors& c = s.colors;
    line("Text= " + ColorValue(c.text));
    line("Title= " + ColorValue(c.title));
    line("Message= " + ColorValue(c.message));
    line("Frame= " + ColorValue(c.frame));
    line("Time= " + ColorValue(c.time));
    line("Mark= " + ColorValue(c.marked));
    line("Menu.ActItem= " + ColorValue(c.menu.active));
    line("Menu.NoactItem= " + ColorValue(c.menu.inactive));
    line("Menu.Frame= " + ColorValue(c.menu.frame));
    line("Menu.Title= " + ColorValue(c.menu.title));
    line("");
    line("[LAST-FILES]");
    for (int n = 1; n <= 9; n++)
        line("File" + std::to_string(n) + "=" + s.last_files[n]);
}

void ApplySettings() {
    Settings& s = settings;
    ui::color = s.colors;
    ui::SetClockRow(s.clock ? 2 : 0);
    ui::EnableMouse(s.mouse);
    speech::SetTalk(s.talk);
    speech::SetDictor(s.dictor);
    sound::SetEnabled(s.sound);
    speech::SetSpeed(s.speed);
    speech::SetAcceleration(s.acceleration, s.pause);
    // Пользовательская перекодировка без файла -- обычная. (У автора здесь
    // стояло «Mode = 3», оставшееся с тех пор, когда пользовательской была
    // кодировка 3: после появления UTF-8 это сбрасывало её в обычную.)
    if (s.mode == kModeUser && text::IsBlank(s.user_decode))
        s.mode = kModeDos;
    speech::SetSpaceSpoken(s.read_space);
    speech::SetLatin(s.german ? speech::Latin::German : speech::Latin::English);
    speech::SetCyrillic(s.ukrainian ? speech::Cyrillic::Ukrainian : speech::Cyrillic::Russian);
    // Файл замен читается один раз; без файла в настройках -- SV.CHF.
    if (s.change_fragments)
        LoadFragments();
}

} // namespace sv
