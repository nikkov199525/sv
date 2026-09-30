// settings.h -- параметры программы (P_U.PAS): SV.INI и SV.CFG.

#ifndef SV_SV_SETTINGS_H
#define SV_SV_SETTINGS_H

#include "sv/records.h"
#include "ui/screen.h"

#include <array>
#include <string>

namespace sv {

// Память для текста. У DOS-программы -- настоящий выбор; теперь текст всегда
// в оперативной памяти, а настройка осталась для совместимости: от неё
// зависят лишь число «свободной памяти» и предел длины текста.
enum class Memory { High, Low, Disk };

// Кодировка текста (режим «Вид»).
enum Mode { kModeDos = 0, kModeWindows, kModeKoi8, kModeUtf8, kModeUser };

struct Settings {
    Config config; // SV.CFG: параметры поиска и будильники

    // [GENERAL]
    Memory memory = Memory::Low;
    std::string temp_dir; // с разделителем на конце
    bool cycle_menu = true;
    bool auto_save = true;
    bool tab = true;          // заменять табуляцию пятью пробелами
    bool exit_confirm = true;
    bool latin_to_russian = false;
    bool no_stop = false;     // непрерывное перемещение по строкам
    long jump1 = 100;
    long jump2 = 500;
    bool exact_time = true;
    bool change_fragments = false;
    std::string fragments_file;
    int local = 0;            // перемещение: 0 -- по словам, 1 -- по промежуткам
    std::string open_mask;
    // [INTERFACE]
    bool clock = true;
    bool mouse = true;
    bool cursor = false;
    bool show_percent = true;
    bool show_coords = true;
    bool show_memory = true;
    bool show_code = true;
    // [BOOK-MARK]
    bool global_bookmarks = false;
    bool bookmark_line = false;
    bool auto_bookmarks = true;
    // [SINTEZIZER]
    bool talk = true;
    int dictor = 0;
    std::string voice_dir;
    int tempo = 0; // 0..150
    // [READING]
    bool read_empty = false;
    bool read_indent = false;
    bool read_word = false;
    bool read_line = false;
    bool read_space = true;
    bool read_symbols = false;
    bool read_all_windows = false;
    bool capital = false;
    int silence_from = 0; // зона молчания: символы с silence_from по silence_to
    int silence_to = 0;
    int empty_delay = 5;
    // [SOUND]
    bool sound = true;
    bool empty_bell = false;
    bool end_bell = true;
    bool window_bell = true;
    bool load_sound = true;
    // [STARTUP]
    bool indent_control = true;
    bool dbf_control = true;
    bool archive_control = true;
    bool html_control = true;
    bool html_links = false;
    bool doc_control = true;
    int word97_width = 72;
    bool show_process = false;
    bool last_position = true;
    bool detect_code = true;
    bool load_last_files = true;
    bool open_dialog = false;
    bool read_on_start = false;
    // [LANGUAGE]
    bool german = false;
    bool ukrainian = false;
    // [OUTLOOK]
    int mode = kModeDos;
    std::string user_decode;
    bool printable = false; // quoted-printable
    // [COLORS]
    ui::Colors colors = ui::kDefaultColors;
    // [LAST-FILES]: окна 1..9
    std::array<std::string, 10> last_files;
};

extern Settings settings;

void SetDefaults();
// Прочитать SV.CFG и SV.INI (ошибки -- сообщениями) и применить.
void LoadSettings();
void SaveSettings();
// Разнести параметры по модулям: цвета, речь, звук, часы...
void ApplySettings();

} // namespace sv

#endif
