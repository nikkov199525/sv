// main.cpp -- SV.PAS: программа SPEAKING VIEWER.
//
//     sv [/high | /low | /disk] [/r] [файл...]
//
// Файлы открываются в окнах 1..9; файл с расширением архива из SV.DCL
// распаковывается во временный каталог, и из него выбирается файл. /r --
// сразу читать текст.

#include "platform/console.h"
#include "platform/system.h"
#include "speech/speech.h"
#include "sv/app.h"
#include "sv/file_dialog.h"
#include "sv/program.h"
#include "sv/settings.h"
#include "sv/viewer.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <cstdlib>
#include <filesystem>
#include <fstream>

namespace {

namespace fs = std::filesystem;
using namespace sv;

constexpr const char* kArchiveDir = "SV_ARC";

std::string ArchiveDir() {
    return settings.temp_dir + kArchiveDir;
}

void CleanArchive() {
    std::error_code error;
    fs::remove_all(sys::Path(ArchiveDir()), error);
}

// Первое вхождение what в s без учёта регистра -> with.
void ReplaceNoCase(std::string& s, std::string_view what, std::string_view with) {
    const size_t at = text::Upper(s).find(text::Upper(what));
    if (at != std::string::npos)
        s.replace(at, what.size(), with);
}

// Распаковать архив программой из SV.DCL. Строка SV.DCL:
//     расширение: программа параметры
// В программе $SV -- каталог SV, в параметрах <ARCHIVE> -- архив,
// <DIRECTORY> -- куда распаковать.
bool Unpacked(const std::string& archive) {
    std::ifstream list(sys::Path(ProgramFile(kArchiversFile)), std::ios::binary);
    if (!list)
        return false;
    const std::string ext = sys::Utf8(sys::Path(archive).extension());
    for (std::string raw; std::getline(list, raw);) {
        if (!raw.empty() && raw.back() == '\r')
            raw.pop_back();
        const std::string line(text::Trim(text::LegacyToUtf8(raw, text::Encoding::Dos866)));
        const size_t colon = line.find(':');
        if (colon == std::string::npos ||
            !text::EqualNoCase("." + std::string(text::Trim(std::string_view(line).substr(0, colon))), ext))
            continue;
        if (settings.archive_control &&
            !ui::Yes("     Файл имеет расширение архива.  Загружать как архив?     "))
            return false;
        const std::string full = sys::Utf8(fs::absolute(sys::Path(archive)));
        std::error_code error;
        fs::remove_all(sys::Path(ArchiveDir()), error);
        if (!fs::create_directories(sys::Path(ArchiveDir()), error))
            return false;
        static bool clean_on_exit = false;
        if (!clean_on_exit) {
            std::atexit(CleanArchive);
            clean_on_exit = true;
        }
        std::string command(text::Trim(std::string_view(line).substr(colon + 1)));
        // Программа -- до первого пробела вне кавычек.
        size_t end = 0;
        for (bool quoted = false; end < command.size(); end++) {
            if (command[end] == '"')
                quoted = !quoted;
            else if (command[end] == ' ' && !quoted)
                break;
        }
        std::string program = command.substr(0, end);
        std::string arguments = end < command.size() ? command.substr(end + 1) : "";
        std::string dir = program_dir;
        for (size_t at; (at = text::Upper(program).find("$SV")) != std::string::npos;) {
            // program_dir кончается разделителем: «$SV\имя» -- без двойного.
            const bool separator = at + 3 < program.size() && (program[at + 3] == '\\' || program[at + 3] == '/');
            program.replace(at, 3, separator ? dir.substr(0, dir.size() - 1) : dir);
        }
        ReplaceNoCase(arguments, "<ARCHIVE>", full);
        ReplaceNoCase(arguments, "<DIRECTORY>", ArchiveDir());
        fs::current_path(sys::Path(ArchiveDir()), error);
        if (program.size() >= 2 && program.front() == '"' && program.back() == '"')
            program = program.substr(1, program.size() - 2);
        const std::string program_ext = text::Upper(sys::Utf8(sys::Path(program).extension()));
        if ((program_ext == ".CMD" || program_ext == ".BAT") && !sys::CommandShell().empty()) {
            arguments = "/c \"\"" + program + "\" " + arguments + "\"";
            program = sys::CommandShell();
        }
        sys::Run(program, arguments);
        return true;
    }
    return false;
}

// Ключ командной строки? У Windows -- всё, что начинается с «/», как у
// исходника; у Linux с «/» начинается любой полный путь, поэтому ключами
// считаются только известные.
bool IsSwitch(const std::string& arg) {
#ifdef _WIN32
    return !arg.empty() && arg[0] == '/';
#else
    const std::string s = text::Lower(arg);
    return s == "/high" || s == "/low" || s == "/disk" || s == "/r";
#endif
}

// Выход без сообщений и без сохранения настроек (Halt).
[[noreturn]] void Quit() {
    speech::Shutdown();
    console::DoneKeyboard();
    console::DoneVideo();
    std::exit(0);
}

} // namespace

int main(int argc, char** argv) {
    const std::vector<std::string> args = sys::Arguments(argc, argv);
    // Папка программы: настройки, закладки, SV.DCL и помощники. Обычно --
    // там, где лежит программа; установленной в систему (deb-пакет) её
    // задаёт запускающий скрипт: ~/.config/sv.
    program_dir = sys::GetEnv("SV_HOME");
    if (program_dir.empty())
        program_dir = sys::ExeDir();
    else if (program_dir.back() != sys::kSeparator)
        program_dir += sys::kSeparator;
    speech::Init(program_dir);
    console::InitVideo();
    console::InitKeyboard();
    LoadSettings();
    // У исходника справка загружалась перед главным циклом, а F1 в диалоге
    // открытия файла при запуске обращался к ней, ещё не загруженной.
    ui::help.Load(ProgramFile(kHelpFile));
    bool read_mode = false;
    for (const std::string& arg : args) {
        if (!IsSwitch(arg))
            continue;
        const std::string s = text::Lower(arg);
        if (s == "/high")
            settings.memory = Memory::High;
        if (s == "/low")
            settings.memory = Memory::Low;
        if (s == "/disk")
            settings.memory = Memory::Disk;
        if (s == "/r")
            read_mode = true;
    }
    const std::string dialog_path = last_path;
    std::error_code error;
    const fs::path start_dir = fs::current_path(error);
    int window = 1;
    for (const std::string& arg : args) {
        if (IsSwitch(arg) || window > 9)
            continue;
        if (Unpacked(arg)) {
            last_path = ArchiveDir();
            const std::vector<std::string> files = ChooseFiles("*.*", false);
            fs::current_path(start_dir, error);
            if (ui::ReturnCode == key::Esc)
                Quit();
            if (files.empty()) // архиватор ничего не распаковал
                Stop(5);
            viewers[window++] = std::make_unique<Viewer>(files.front());
        } else {
            viewers[window] = std::make_unique<Viewer>(arg);
            settings.last_files[window] = sys::Utf8(fs::absolute(sys::Path(arg)));
            window++;
        }
    }
    // Файлы, открытые в прошлый раз. У исходника пропавший с диска файл
    // останавливал программу; здесь он пропускается.
    if (settings.load_last_files)
        for (int w = 1; w <= 9; w++)
            if (!viewers[w] && !settings.last_files[w].empty() &&
                fs::is_regular_file(sys::Path(settings.last_files[w]))) {
                viewers[w] = std::make_unique<Viewer>(settings.last_files[w]);
                window++;
            }
    last_path = dialog_path;
    if (window == 1) {
        if (!settings.open_dialog)
            Stop(0);
        LoadNewFile();
        if (!CurrentViewer())
            Stop(0);
    }
    speech::Say("загру+жено.");
    if (settings.read_on_start && viewers[1])
        viewers[1]->ReadText();
    MainLoop(read_mode);
    for (auto& v : viewers)
        if (v)
            v->Close();
    Stop(0);
}
