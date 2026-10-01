// viewer.cpp -- V_U.PAS: toViewer (кроме закладок -- bookmarks.cpp).

#include "sv/viewer.h"

#include "convert/html.h"
#include "convert/word97.h"
#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/app.h"
#include "sv/fragments.h"
#include "sv/history.h"
#include "sv/program.h"
#include "sv/records.h"
#include "sv/settings.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "text/utf8.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <chrono>
#include <iterator>
#include <thread>

namespace sv {

std::array<std::unique_ptr<Viewer>, 10> viewers;
int current_window = 1;

namespace {

namespace fs = std::filesystem;
using sound::Signal;

// Строки длиннее -- режутся; после 80 символов строка кончается на первом
// же пробеле или табуляции (перенос длинных абзацев).
constexpr int kMaxLine = 255;
constexpr int kWrapAfter = 80;

// Знаки конца фразы при чтении и заглавные буквы -- для индикации
// заглавных (S_U.Break_Sym и Alf).
constexpr std::u32string_view kBreakSymbols = U".,;?!)]}:=";
constexpr std::u32string_view kCapitals =
    U"АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯABCDEFGHIJKLMNOPQRSTUVWXYZ";

std::string Upper(std::string_view s) {
    return text::Upper(s);
}

// Код символа в DOS-866 (-1 -- там его нет): так у автора проверялись
// заглавные буквы.
int Dos866(char32_t c) {
    return text::FromUnicode(text::Encoding::Dos866, c);
}

bool Contains(std::u32string_view set, char32_t c) {
    return set.find(c) != std::u32string_view::npos;
}

std::u32string Repeat(char32_t c, size_t n) {
    return std::u32string(n, c);
}

// Весь файл -- правильный UTF-8 с многобайтовыми символами? Символ может
// пересечь границу блока чтения.
bool LooksUtf8(const std::string& file) {
    std::ifstream in(sys::Path(file), std::ios::binary);
    if (!in)
        return false;
    utf8::Validator validator;
    std::vector<char> block(0x10000);
    while (in) {
        in.read(block.data(), static_cast<std::streamsize>(block.size()));
        if (!validator.Feed(std::string_view(block.data(), static_cast<size_t>(in.gcount()))))
            return false;
    }
    return validator.Valid() && validator.HasMultibyte();
}

// HToB: две шестнадцатеричные цифры (не цифра -- ноль).
int HexPair(std::string_view s) {
    auto nibble = [](char c) {
        c = static_cast<char>(c >= 'a' && c <= 'z' ? c - 32 : c);
        if (c >= '0' && c <= '9')
            return c - '0';
        if (c >= 'A' && c <= 'F')
            return c - 'A' + 10;
        return 0;
    };
    return nibble(s.size() > 0 ? s[0] : 0) * 16 + nibble(s.size() > 1 ? s[1] : 0);
}

// Quoted printable: «=?кодировка?» убирается, «=XX» -- байт XX.
std::string DecodePrintable(std::string s) {
    const size_t marker = s.find("=?");
    if (marker != std::string::npos) {
        s.erase(marker, 2);
        const size_t question = s.find('?');
        if (question != std::string::npos && question > marker)
            s.erase(marker, question - marker);
    }
    std::string result;
    for (size_t i = 0; i < s.size(); i++) {
        const char next = i + 1 < s.size() ? s[i + 1] : 0;
        if (s[i] == '=' && ((next >= 'A' && next <= 'Z') || (next >= '0' && next <= '9'))) {
            result += static_cast<char>(HexPair(std::string_view(s).substr(i + 1, 2)));
            i += 2;
        } else
            result += s[i];
    }
    return result;
}

// «Латинские в русские»: похожие латинские буквы -- русскими.
char32_t LatinToRussian(char32_t c) {
    switch (c) {
    case U'p': return U'р';
    case U'P': return U'Р';
    case U'H': return U'Н';
    case U'c': return U'с';
    case U'C': return U'С';
    case U'y': return U'у';
    case U'Y': return U'У';
    case U'b': return U'в';
    case U'B': return U'В';
    }
    return c;
}

// Процент -- с округлением к чётному, как Round у Паскаля.
std::string Percent(long long part, long long full) {
    return std::to_string(full == 0 ? 0 : static_cast<long long>(std::nearbyint(part * 100.0 / full)));
}

// Шкала «[████░░░░]» шириной width.
std::u32string Scale(long long part, long long full, int width) {
    width = std::min(width, 80);
    const int dots = full == 0 ? 0 : static_cast<int>(std::nearbyint(part * (width - 2.0) / full));
    return U'[' + Repeat(U'█', dots) + Repeat(U'░', std::max(width - 2 - dots, 0)) + U']';
}

// Файл поделён на строки: где кончается очередная и где начинается
// следующая. utf8 -- символы UTF-8 не рвутся, длина -- в символах.
class LineSplitter {
public:
    LineSplitter(std::istream& in, bool utf8) : in_(in), utf8_(utf8) {}

    struct Line {
        int64_t offset;
        uint32_t length; // байтов
        int width;       // символов
    };

    bool Next(Line& line);
    int64_t Position() const { return base_ + static_cast<int64_t>(pos_); }

private:
    std::istream& in_;
    bool utf8_;
    std::string buf_;
    size_t pos_ = 0;
    int64_t base_ = 0;
    bool eof_ = false;

    // В буфере не меньше need байтов от pos_ (если файл не кончился).
    void Ensure(size_t need) {
        if (buf_.size() - pos_ >= need || eof_)
            return;
        base_ += static_cast<int64_t>(pos_);
        buf_.erase(0, pos_);
        pos_ = 0;
        char block[0x10000];
        while (buf_.size() < need && !eof_) {
            in_.read(block, sizeof block);
            buf_.append(block, static_cast<size_t>(in_.gcount()));
            eof_ = !in_;
        }
    }
    unsigned char At(size_t i) const { return static_cast<unsigned char>(buf_[i]); }
};

bool LineSplitter::Next(Line& line) {
    Ensure(8);
    if (pos_ >= buf_.size())
        return false;
    line.offset = Position();
    line.width = 0;
    bool spaces = false; // строка длиннее 80 и дошла до пробелов
    for (;;) {
        Ensure(8);
        if (pos_ >= buf_.size()) { // конец файла
            line.length = static_cast<uint32_t>(Position() - line.offset);
            return true;
        }
        const unsigned char c = At(pos_);
        if (line.width == kMaxLine || (spaces && c != ' ' && c != '\t' && c != '\r' && c != '\n')) {
            line.length = static_cast<uint32_t>(Position() - line.offset);
            return true;
        }
        if (line.width > kWrapAfter && (c == ' ' || c == '\t'))
            spaces = true;
        if (c == '\n' || (c == '\r' && pos_ + 1 < buf_.size() && At(pos_ + 1) == '\n')) {
            line.length = static_cast<uint32_t>(Position() - line.offset);
            pos_ += c == '\n' ? 1 : 2;
            return true;
        }
        size_t step = 1;
        if (utf8_ && c >= 0x80) {
            char32_t cp;
            size_t end = pos_;
            if (utf8::Next(std::string_view(buf_), end, cp))
                step = end - pos_;
        }
        pos_ += step;
        line.width++;
    }
}

} // namespace

// ------------------------------------------------------------ загрузка

const char* DbfTypeName(char type) {
    switch (type) {
    case 'C': return "символьный";
    case 'D': return "датовый";
    case 'F': return "с плав. точкой";
    case 'G': return "общий";
    case 'L': return "логический";
    case 'M': return "текстовый";
    case 'N': return "числовой";
    }
    return "";
}


Viewer::Viewer(const std::string& file) {
    Load(file);
    left = 1;
    top = 2;
    right = 80;
    bottom = 25;
    find_text.clear();
    block_begin = block_end = 0;
    break_read_line = 0;
    user_table_file_.clear();
    LoadUserTable();
    installed = true;
}

Viewer::~Viewer() = default;

void Viewer::LoadUserTable() {
    const std::string& file = settings.user_decode;
    if (!user_table_file_.empty() && user_table_file_ == file)
        return;
    user_table_loaded_ = false;
    user_table_file_.clear();
    std::ifstream in(sys::Path(file), std::ios::binary);
    if (text::IsBlank(file) || !in)
        return;
    // Пары байтов «откуда, куда» (в DOS-866).
    for (int c = 0; c < 256; c++)
        user_table_[c] = static_cast<unsigned char>(c);
    char pair[2];
    while (in.read(pair, 2))
        user_table_[static_cast<unsigned char>(pair[0])] = static_cast<unsigned char>(pair[1]);
    user_table_loaded_ = true;
    user_table_file_ = file;
}

bool Viewer::LoadDbf(const std::string& file) {
    std::ifstream in(sys::Path(file), std::ios::binary);
    std::string header(32, '\0');
    in.read(header.data(), 32);
    auto byte = [&](size_t i) { return static_cast<unsigned char>(header[i]); };
    dbf = std::make_unique<Dbf>();
    // дата последней правки: ДД/ММ/ГГ. Год в файле -- от 1900; у автора
    // строка из восьми символов обрезала год 2000-х («24/07/10» вместо
    // «24/07/02»).
    auto two = [](int n) { return (n < 10 ? "0" : "") + std::to_string(n); };
    dbf->last_date = two(byte(3)) + '/' + two(byte(2)) + '/' + two(byte(1) % 100);
    dbf->records = static_cast<int32_t>(byte(4) | byte(5) << 8 | byte(6) << 16 | byte(7) << 24);
    dbf->header_size = static_cast<uint16_t>(byte(8) | byte(9) << 8);
    dbf->record_length = static_cast<uint16_t>(byte(10) | byte(11) << 8);
    const int count = (dbf->header_size - 33) / 32;
    for (int n = 1; n <= count && n <= 255; n++) {
        std::string field(32, '\0');
        in.seekg(32 * n);
        in.read(field.data(), 32);
        DbfField f;
        f.name = text::ToUtf8(field.substr(0, std::min(field.find('\0'), size_t{11})),
                              text::Encoding::Dos866);
        f.type = field[11];
        f.offset = static_cast<int32_t>(static_cast<unsigned char>(field[12]) |
                                        static_cast<unsigned char>(field[13]) << 8 |
                                        static_cast<unsigned char>(field[14]) << 16 |
                                        static_cast<unsigned char>(field[15]) << 24);
        f.length = static_cast<uint8_t>(field[16]);
        dbf->fields.push_back(f);
    }
    lines = dbf->records;
    file_.open(sys::Path(file), std::ios::binary);
    return true;
}

void Viewer::Load(const std::string& requested) {
    std::string file = requested;
    if (file.empty())
        return;
    file_.close();
    if (!fs::is_regular_file(sys::Path(file)))
        Stop(5);
    auto split = [&](const std::string& path) {
        const fs::path p = fs::absolute(sys::Path(path));
        dir = sys::Utf8(p.parent_path());
        if (dir.empty() || dir.back() != sys::kSeparator)
            dir += sys::kSeparator;
        const std::string filename = sys::Utf8(p.filename());
        const size_t dot = filename.rfind('.');
        name = dot == std::string::npos ? filename : filename.substr(0, dot);
        ext = dot == std::string::npos ? "" : filename.substr(dot);
    };
    split(file);
    dbf.reset();
    converted_ = false;
    if (Upper(ext) == ".DBF" &&
        (!settings.dbf_control ||
         ui::Yes("     Файл имеет расширение базы данных.  Загружать как Базу Данных?     "))) {
        LoadDbf(file);
        return;
    }
    if (Upper(ext) == ".DOC" &&
        (!settings.doc_control || ui::Yes("     Загружать файл как текст  MS WORD 97?     "))) {
        const std::string text_file = settings.temp_dir + name + ".TXT";
        convert::Word97ToText(file, text_file, settings.word97_width);
        file = text_file;
        split(file);
        converted_ = true;
    }
    if (Upper(ext) == ".HTM" &&
        (!settings.html_control || ui::Yes("     Загружать файл как html?     "))) {
        const std::string text_file = settings.temp_dir + name + ".TXT";
        convert::HtmlToText(file, text_file, settings.html_links);
        file = text_file;
        split(file);
        converted_ = true;
    }
    index_.clear();
    info = TextInfo();

    ui::SetCursorXY(21, 13);
    ui::HideCursor();
    ui::Clear(1, 1, 80, 25);
    ui::Frame(21, 11, 60, 14);
    ui::PutLine(36, 12, "АНАЛИЗ...", 0x14);
    ui::Show();
    std::error_code error;
    const auto size = static_cast<long long>(fs::file_size(sys::Path(file), error));
    if (size > 5000000)
        speech::Say("ана+лиз...");
    const bool detected_utf8 = settings.detect_code && LooksUtf8(file);
    const bool utf8 = settings.mode == kModeUtf8 || detected_utf8;
    std::ifstream in(sys::Path(file), std::ios::binary);
    if (!in)
        return;
    ui::PutLine(34, 12, settings.show_process ? "Загружено " : " Загрузка... ", ui::color.message);
    ui::Show();

    // Оглавление строк; по первым 250 непустым -- голоса за кодировку.
    int votes[5] = {};
    int voted = 0;
    int last_percent = -1;
    LineSplitter splitter(in, utf8);
    auto show_progress = [&](long long done) {
        if (!settings.show_process)
            return;
        const int percent = size == 0 ? 100 : static_cast<int>(std::nearbyint(done * 100.0 / size));
        if (percent == last_percent)
            return;
        ui::PutLine(22, 13, Scale(done, size, 38), ui::color.message);
        ui::PutLine(44, 12, std::to_string(percent) + '%', ui::color.message);
        ui::Show();
        last_percent = percent;
    };
    LineSplitter::Line line;
    int64_t checked = 0;
    std::ifstream probe(sys::Path(file), std::ios::binary);
    while (splitter.Next(line)) {
        index_.push_back({line.offset, line.length});
        const long number = static_cast<long>(index_.size());
        if (line.width > info.max_width) {
            info.max_width = line.width;
            info.max_width_line = number;
        }
        if (number == 1 || line.width < info.min_width) {
            info.min_width = line.width;
            info.min_width_line = number;
        }
        if (settings.detect_code && line.length > 0 && voted < 250) {
            std::string bytes(line.length, '\0');
            probe.clear();
            probe.seekg(line.offset);
            probe.read(bytes.data(), line.length);
            const int code = DetectCode(bytes);
            if (code >= 0 && code <= 4)
                votes[code]++;
            voted++;
        }
        if (splitter.Position() - checked < 0x2000)
            continue;
        checked = splitter.Position();
        show_progress(checked);
        if (!ui::KeyPressed())
            continue;
        const int key = ui::DefineKey();
        if (key == key::Space)
            speech::Say(Percent(checked, size) + '%');
        if (key != key::Esc)
            continue;
        ui::ButtonRow choice;
        choice.items = {" Продолжить ", " Прервать ", " Выход "};
        choice.cursor = settings.cursor;
        choice.message = "                  Прервано...";
        choice.margin_top = 1;
        choice.margin_left = 2;
        choice.SetPosition(16, 9, 65, 16);
        choice.Call();
        if (choice.current == 2)
            break;
        if (choice.current == 3)
            Stop(4);
        ui::Clear(1, 1, 80, 25);
        ui::Frame(21, 11, 60, 14);
        ui::PutLine(34, 12, "Загружено ", ui::color.message);
        ui::Show();
        ui::SetCursorXY(21, 13);
        speech::Say("продо+лжить.");
    }
    show_progress(size);
    info.lines = static_cast<long>(index_.size());
    if (settings.detect_code) {
        int winner = 0;
        for (int code = 1; code <= 4; code++)
            if (votes[code] > votes[winner])
                winner = code;
        // Если первые строки -- одна латиница, голосование кириллицы дальше
        // не видит; проверка всего файла её видела.
        if (detected_utf8)
            winner = 4;
        if (winner == 0)
            speech::Say("Кодиро+вка не+ определена+.");
        else if (winner - 1 != settings.mode) {
            speech::Say("Сме+на кодиро+вки.");
            settings.mode = winner - 1;
            SayCode();
        }
    }
    lines = static_cast<long>(index_.size());
    first_line = 1;
    offset = 1;
    block_begin = block_end = 0;
    file_.open(sys::Path(file), std::ios::binary);
    if (settings.last_position)
        for (const LastPosition& p : ReadLastPositions(ProgramFile(kPositionsFile)))
            if (sys::SameFileName(p.file, Path())) {
                first_line = p.line;
                offset = p.offset;
            }
}

void Viewer::Close() {
    if (!installed)
        return;
    ui::Clear(left, top, right, bottom);
    ui::Show();
    file_.close();
    dbf.reset();
    index_.clear();
    if (converted_) {
        std::error_code error;
        fs::remove(sys::Path(Path()), error);
    }
    lines = 0;
    if (settings.last_position) {
        // Позиция в начале текста не хранится.
        const std::string file = ProgramFile(kPositionsFile);
        std::vector<LastPosition> positions = ReadLastPositions(file);
        const bool at_start = first_line == 1 && offset == 1;
        const auto same = std::find_if(positions.begin(), positions.end(), [&](const LastPosition& p) {
            return sys::SameFileName(p.file, Path());
        });
        if (same != positions.end()) {
            if (at_start) {
                *same = positions.back();
                positions.pop_back();
            } else {
                same->line = static_cast<int32_t>(first_line);
                same->offset = static_cast<uint16_t>(offset);
            }
            WriteLastPositions(file, positions);
        } else if (!at_start) {
            positions.push_back({static_cast<int32_t>(first_line), static_cast<uint16_t>(offset), Path()});
            WriteLastPositions(file, positions);
        }
    }
    offset = 1;
    first_line = 1;
    installed = false;
}

// -------------------------------------------------------------- строки

std::string Viewer::RawLine(long num) {
    if (num < 1 || num > static_cast<long>(index_.size()))
        return {};
    const LineRef& ref = index_[num - 1];
    std::string raw(ref.length, '\0');
    file_.clear();
    file_.seekg(ref.offset);
    file_.read(raw.data(), ref.length);
    raw.resize(static_cast<size_t>(file_.gcount()));
    return raw;
}

std::u32string Viewer::Line(long num) {
    if (dbf) {
        if (num < 1 || num > dbf->records || current_field < 1 ||
            current_field > static_cast<int>(dbf->fields.size()))
            return {};
        const DbfField& f = dbf->fields[current_field - 1];
        std::string raw(f.length, '\0');
        file_.clear();
        file_.seekg(dbf->header_size + static_cast<int64_t>(num - 1) * dbf->record_length + f.offset);
        file_.read(raw.data(), f.length);
        if (f.type == 'D') { // ГГГГММДД -> ДД/ММ/ГГГГ
            raw.resize(std::max<size_t>(raw.size(), 8), ' ');
            raw = raw.substr(raw.size() - 2) + '/' + raw.substr(4, 2) + '/' + raw.substr(0, 4);
        }
        return text::Decode(raw, text::Encoding::Dos866);
    }
    std::string raw = RawLine(num);
    if (settings.printable)
        raw = DecodePrintable(std::move(raw));
    std::u32string decoded;
    switch (settings.mode) {
    case kModeWindows: decoded = text::Decode(raw, text::Encoding::Windows1251); break;
    case kModeKoi8: decoded = text::Decode(raw, text::Encoding::Koi8R); break;
    case kModeUtf8: decoded = text::Decode(raw, text::Encoding::Utf8); break;
    case kModeUser:
        LoadUserTable();
        if (user_table_loaded_)
            for (char& c : raw)
                c = static_cast<char>(user_table_[static_cast<unsigned char>(c)]);
        decoded = text::Decode(raw, text::Encoding::Dos866);
        break;
    default: decoded = text::Decode(raw, text::Encoding::Dos866); break;
    }
    std::u32string result;
    result.reserve(decoded.size());
    for (char32_t c : decoded) {
        if (c == U'\t' && settings.tab)
            result.append(5, U' ');
        else if (c >= 1 && c < 32 && c != U'\t')
            continue;
        else
            result += settings.latin_to_russian ? LatinToRussian(c) : c;
    }
    if (settings.change_fragments)
        result = text::ApplyFragmentRules(std::move(result), Fragments());
    return result;
}

std::string Viewer::LineUtf8(long num) {
    return utf8::Encode(Line(num));
}

// ---------------------------------------------------------------- экран

void Viewer::SetPosition(int l, int t, int r, int b) {
    left = 1;
    top = 2;
    right = 80;
    bottom = 25;
    if (b - t < 3 || r - l < 21 || l == 0 || t == 1 || r > 80 || b > 25)
        return;
    left = l;
    top = t;
    right = r;
    bottom = b;
}

void Viewer::Show() {
    ui::PutLine(1, 1, std::string(80, ' '), ui::color.menu.inactive);
    ui::PutLine(2, 1, "  Файл    Читать    Блок    Закладки    Поиск    Окна    Настройки    Помощь  ",
                ui::color.menu.inactive);
    ui::Clear(left, top, right, bottom);
    ui::Frame(left, top, right, bottom);
    if (!installed) {
        ui::Clear(1, 1, 80, 25);
        ui::Frame(1, 1, 80, 25);
        return;
    }
    const size_t width = static_cast<size_t>(right - left - 1);
    auto visible = [&](const std::u32string& line) {
        const size_t from = offset > 0 ? static_cast<size_t>(offset - 1) : 0;
        return from < line.size() ? line.substr(from, width) : std::u32string();
    };
    if (dbf) {
        const DbfField& f = dbf->fields[current_field - 1];
        ui::PutLine(left + 5, top + 1, "Имя: " + f.name, ui::color.title);
        ui::PutLine(left + 22, top + 1, std::string("Тип: ") + DbfTypeName(f.type), ui::color.title);
        ui::PutLine(left + 42, top + 1, "Длина: " + text::FormatNumber(f.length), ui::color.title);
        for (int y = top + 2; y <= bottom - 1; y++) {
            ui::PutLine(left + 1, y, std::string(width, ' '), ui::color.text);
            ui::PutLine(left + 1, y, visible(Line(first_line + (y - top) - 2)), ui::color.text);
        }
        if (current_field < static_cast<int>(dbf->fields.size()))
            ui::PutLine(right, top + 1, "▲", ui::color.frame);
        if (current_field > 1)
            ui::PutLine(left, top + 1, "▼", ui::color.frame);
        if (f.length > right - left - 1 && right - left - 1 < f.length - offset + 1)
            ui::PutLine(right, top + 2, "↑", ui::color.frame);
    } else
        for (int y = top + 1; y <= bottom - 1; y++) {
            const long number = first_line + (y - top) - 1;
            ui::PutLine(left + 1, y, std::string(width, ' '), ui::color.text);
            const bool marked = number >= block_begin && number <= block_end;
            ui::PutLine(left + 1, y, visible(Line(number)), marked ? ui::color.marked : ui::color.text);
        }
    if (settings.show_coords)
        ui::PutLine(left + 4, bottom,
                    " " + std::to_string(first_line) + ':' + std::to_string(offset) + ' ',
                    ui::color.message);
    if (settings.show_percent && right - left > 23) {
        const std::string percent = Percent(first_line, lines);
        ui::PutLine(left + 17, bottom, std::string(4 - std::min<size_t>(percent.size(), 4), ' ') + percent + '%',
                    ui::color.message);
    }
    if (settings.show_memory && right - left > 47)
        ui::PutLine(left + 25, bottom, " " + text::FormatNumber(FreeMemory()) + " свободно ",
                    ui::color.message);
    if (settings.show_code && right - left > 59)
        switch (settings.mode) {
        case kModeDos: ui::PutLine(left + 50, bottom, " Обычная ", ui::color.message); break;
        case kModeWindows: ui::PutLine(left + 50, bottom, " WINDOWS ", ui::color.message); break;
        case kModeKoi8: ui::PutLine(left + 50, bottom, " KOI 8-R ", ui::color.message); break;
        case kModeUtf8: ui::PutLine(left + 50, bottom, " UTF-8   ", ui::color.message); break;
        case kModeUser: {
            std::string file = sys::Utf8(sys::Path(settings.user_decode).filename());
            if (!file.empty() && file.back() == '.')
                file.pop_back();
            ui::PutLine(left + 50, bottom, " Польз. " + file + " ", ui::color.message);
            break;
        }
        }
}

void Viewer::SetWindow() {
    ui::Context = 22;
    const int l = left, t = top, r = right, b = bottom;
    const uint8_t frame = ui::color.frame;
    ui::color.frame = 0x17;
    ui::frame_style = ui::kSingleFrame;
    ui::HideCursor();
    for (;;) {
        ui::Clear(1, 1, 80, 25);
        Show();
        ui::SetCursorXY(left, top + 1);
        int key = ui::DefineKey();
        if (key == key::Mouse)
            key = ui::MouseAsKey();
        if (key == key::Esc) {
            SetPosition(l, t, r, b);
            break;
        }
        if (key == key::Enter)
            break;
        switch (key) {
        case key::Up:
            if (ui::OnlyShift())
                SetPosition(left, top, right, bottom - 1);
            else
                SetPosition(left, top - 1, right, bottom - 1);
            break;
        case key::Down:
            if (ui::OnlyShift())
                SetPosition(left, top, right, bottom + 1);
            else
                SetPosition(left, top + 1, right, bottom + 1);
            break;
        case key::Right:
            if (ui::OnlyShift())
                SetPosition(left, top, right + 1, bottom);
            else
                SetPosition(left + 1, top, right + 1, bottom);
            break;
        case key::Left:
            if (ui::OnlyShift())
                SetPosition(left, top, right - 1, bottom);
            else
                SetPosition(left - 1, top, right - 1, bottom);
            break;
        case key::F1: ui::help.Show(ui::Context); break;
        }
    }
    ui::ShowCursor();
    ui::color.frame = frame;
    ui::frame_style = ui::kDoubleFrame;
    ui::Clear(1, 1, 80, 25);
}

// ---------------------------------------------------------- перемещение

namespace {

// Что сказать о строке, на которую пришли (Next и Last).
void AnnounceLine(const Viewer& v) {
    if (v.first_line == v.block_begin)
        speech::Say("Нача+ло бло+ка.");
    if (v.first_line == v.block_end)
        speech::Say("коне+ц бло+ка.");
    if (v.first_line > v.block_begin && v.first_line < v.block_end)
        sound::Play(Signal::Marked);
}

} // namespace

bool IsIndent(std::u32string_view line) {
    return !line.empty() && line[0] == U' ' &&
           !(text::Trim(line).substr(0, 1) == U"-" ||
             text::IsBlank(line.substr(0, 10)));
}

void Viewer::Next(long step) {
    if (first_line == lines || lines < 1) {
        sound::Play(Signal::Edge);
        return;
    }
    first_line = std::min(first_line + step, lines);
    AnnounceLine(*this);
    const std::u32string line = Line(first_line);
    if (text::IsBlank(line)) {
        if (settings.read_empty)
            speech::Say("пуста+я.");
        else
            sound::Play(Signal::Empty);
    } else if (line[0] != U' ') {
        // первое слово -- до пробела или знака конца фразы включительно
        if (settings.read_word && !settings.read_line) {
            size_t end;
            if (settings.local == 0) {
                end = line.size() - 1;
                for (size_t i = 0; i < line.size(); i++)
                    if (Contains(kBreakSymbols, line[i]) || line[i] == U' ') {
                        end = i;
                        break;
                    }
            } else {
                const size_t space = line.find(U' ');
                end = space == std::u32string::npos ? line.size() - 1 : space;
            }
            speech::Say(utf8::Encode(line.substr(0, end + 1)));
        }
    } else if (IsIndent(line)) {
        if (settings.read_indent)
            speech::Say("абза+ц.");
        else
            sound::Play(Signal::Indent);
    }
    if (settings.read_line)
        ReadLine();
    if (static_cast<long>(line.size()) < offset)
        offset = static_cast<int>(line.size());
}

void Viewer::Last(long step) {
    if (first_line == 1) {
        sound::Play(Signal::Edge);
        return;
    }
    first_line = std::max(first_line - step, 1L);
    AnnounceLine(*this);
    const std::u32string line = Line(first_line);
    if (text::IsBlank(line)) {
        if (settings.read_empty)
            speech::Say("пуста+я.");
        else
            sound::Play(Signal::Empty);
    } else if (line[0] != U' ') {
        // до первого пробела включительно (у автора -- не как у Next)
        if (settings.read_word && !settings.read_line) {
            const size_t space = line.find(U' ');
            speech::Say(utf8::Encode(line.substr(0, space == std::u32string::npos ? 0 : space + 1)));
        }
    } else if (IsIndent(line)) {
        if (settings.read_indent)
            speech::Say("абза+ц.");
        else
            sound::Play(Signal::Indent);
    }
    if (settings.read_line)
        ReadLine();
    if (static_cast<long>(line.size()) < offset && !text::IsBlank(line))
        offset = static_cast<int>(line.size());
}

void Viewer::GotoLine() {
    ui::Context = 20;
    ui::Frame(27, 11, 54, 13);
    speech::Say("но+мер строки+.");
    ui::PutLine(28, 12, "Номер строки - ", ui::color.message);
    std::string number;
    long line = 0;
    const ui::ExitKeys keys{key::F1};
    do {
        ui::EditLine(43, 12, number, 10, 10);
        if (ui::ReturnCode == key::F1)
            ui::help.Show(ui::Context);
        if (ui::ReturnCode == key::Enter) {
            if (const auto parsed = text::ParseInt(number))
                line = static_cast<long>(*parsed);
            else {
                speech::Say("оши+бка.");
                sound::Play(Signal::Error);
                ui::ReturnCode = 0;
            }
            if (line > lines || line < 1) {
                speech::Say("тако+й строки+ несуществу+ет.");
                sound::Play(Signal::Error);
                ui::ReturnCode = 0;
            }
        }
    } while (ui::ReturnCode != key::Enter && ui::ReturnCode != key::Esc);
    if (ui::ReturnCode == key::Esc) {
        speech::Say(ui::kCancel);
        return;
    }
    first_line = line;
    SayLineNumber();
}

// --------------------------------------------------------------- поиск

void Viewer::Find(bool continue_search) {
    if (!installed)
        return;
    FindOptions& options = settings.config.find;
    if (continue_search && find_text.empty()) {
        speech::Say("Строка+ по+иска не+ за+дана.");
        continue_search = false;
    }
    long from = 0;
    if (continue_search)
        from = options.forward ? first_line + 1 : first_line - 1;
    else {
        InputHistory history(kFindHistory);
        ui::Context = 19;
        speech::Say("По+иск.");
        std::string query = utf8::Encode(find_text);
        ui::CheckList settings_list;
        const uint8_t old_text = ui::color.text;
        ui::color.text = ui::color.frame;
        settings_list.items = {
            {"  Различать регистр  ", options.match_case},
            {"  Искать в прямом направлении  ", options.forward},
            {"  Начать поиск с текущей строки  ", !options.from_begin},
            {"  Искать начало строки  ", !options.substring},
            {"  Сообщать позицию  ", options.say_position},
        };
        settings_list.margin_top = 2;
        settings_list.margin_left = 2;
        settings_list.title = " Поиск ";
        settings_list.cycle = settings.cycle_menu;
        settings_list.SetPosition(21, 8, 60, 16);
        ui::Clear(21, 8, 60, 16);
        ui::color.text = ui::color.frame;
        settings_list.Show();
        ui::PutLine(22, 9, "Строка - ", ui::color.frame);
        ui::color.text = old_text;
        int point = 1;
        {
            const ui::ExitKeys keys{key::Tab, key::F1};
            do {
                if (history.exists)
                    query = history.items[point - 1];
                speech::Say("строка+:");
                speech::Say(query);
                {
                    const ui::ExitKeys arrows{key::Up, key::Down};
                    ui::EditLine(31, 9, query, 255, 28);
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
                if (ui::ReturnCode == key::Tab) {
                    speech::Say("устано+вки.");
                    for (;;) {
                        settings_list.Call();
                        if (ui::ReturnCode != key::F1)
                            break;
                        ui::help.Show(ui::Context);
                    }
                }
                if (ui::ReturnCode == key::F1)
                    ui::help.Show(ui::Context);
            } while (ui::ReturnCode != key::Esc && ui::ReturnCode != key::Enter);
        }
        const bool same = text::EqualNoCase(text::Trim(query), text::Trim(history.items[point - 1]));
        ui::color.text = old_text;
        if (ui::ReturnCode == key::Esc) {
            speech::Say(ui::kCancel);
            return;
        }
        history.Save(!same, query);
        speech::Say(ui::kOk);
        find_text = utf8::Decode(query);
        options.match_case = settings_list.items[0].on;
        options.forward = settings_list.items[1].on;
        options.from_begin = !settings_list.items[2].on;
        options.substring = !settings_list.items[3].on;
        options.say_position = settings_list.items[4].on;
        from = options.from_begin ? (options.forward ? 1 : lines) : first_line;
    }
    const std::u32string needle = options.match_case ? find_text : text::FoldCase(find_text);
    for (long n = from; options.forward ? n <= lines : n >= 1; n += options.forward ? 1 : -1) {
        if (ui::KeyPressed() && ui::DefineKey() == key::Esc &&
            ui::Yes("       Прервать поиск?       "))
            return;
        std::u32string line = Line(n);
        if (!options.match_case)
            line = text::FoldCase(line);
        const size_t position = line.find(needle);
        if (options.substring ? (position != std::u32string::npos && !needle.empty())
                              : line.compare(0, needle.size(), needle) == 0) {
            sound::Play(Signal::Found);
            first_line = n;
            if (options.say_position) {
                speech::SayOrdinal(first_line, "\\ая\\ строка+");
                if (options.substring)
                    speech::SayOrdinal(static_cast<long long>(position) + 1, "\\ая\\ пози+ция.");
            }
            return;
        }
    }
    ui::ShowMessage("           Строка не найдена          ", "");
}

// --------------------------------------------------------------- чтение

namespace {

// Часть строки до знака конца фразы включительно; заглавная буква тоже
// делит строку (при индикации заглавных): перед ней -- сигнал.
// Возвращает длину части, 0 -- знака нет; cap -- найдена заглавная.
struct Phrase {
    size_t length;
    bool interrupted;
};

} // namespace

void Viewer::ReadLine() {
    std::u32string line = Line(first_line);
    if (settings.silence_from > 0 && settings.silence_to > 0 &&
        static_cast<size_t>(settings.silence_from) <= line.size())
        line.erase(settings.silence_from - 1, settings.silence_to - settings.silence_from + 1);
    if (text::IsBlank(line))
        return;
    if (line == Repeat(line[0], line.size())) {
        speech::SayText(utf8::Encode(line));
        return;
    }
    if (settings.read_symbols)
        AllSymbolsOn();
    std::u32string breaks(kBreakSymbols);
    if (settings.capital)
        breaks += kCapitals;
    std::u32string buf = line.substr(std::min(static_cast<size_t>(std::max(offset - 1, 0)), line.size()));
    std::u32string part;
    bool capital = false;
    size_t point = 1;
    while (point <= buf.size()) {
        buf = buf.substr(point - 1);
        size_t counter = 1;
        bool die = false;
        for (; counter <= buf.size(); counter++) {
            if (Contains(breaks, buf[counter - 1])) {
                if (Contains(kCapitals, buf[counter - 1])) {
                    if (!capital) {
                        capital = true;
                        continue;
                    }
                    counter--;
                }
                break;
            }
            if (ui::KeyPressed()) {
                die = true;
                break;
            }
        }
        if (die)
            break;
        if (counter == 0) {
            capital = false;
            point = 1;
            continue;
        }
        if (counter <= buf.size()) {
            if (capital) {
                sound::Play(Signal::Capital);
                capital = false;
            }
            speech::SayText(utf8::Encode(buf.substr(0, counter)));
            part.clear();
            point = counter + 1;
        } else {
            part = buf.substr(0, buf.find_last_not_of(U' ') + 1);
            break;
        }
    }
    if (ui::KeyPressed())
        sound::Play(Signal::EndLine);
    else {
        const int first = part.empty() ? -1 : Dos866(part[0]);
        if (settings.capital && first >= 128 && first <= 160)
            sound::Play(Signal::Capital);
        speech::SayText(utf8::Encode(part));
    }
    AllSymbolsOff();
}

void Viewer::ReadText() {
    long empty_count = 0;
    bool die = false;
    std::u32string breaks(kBreakSymbols);
    if (settings.capital)
        breaks += kCapitals;
    std::u32string part, buf;
    bool break_key = false;
    bool capital = false;
    if (settings.read_symbols)
        AllSymbolsOn();
    long c;
    // Стрелки во время чтения -- к пустой строке или абзацу, чтение
    // продолжается оттуда; прочие клавиши его прерывают.
    auto handle_key = [&](int key) {
        switch (key) {
        case key::Down: FindEmpty(true); break;
        case key::Up: FindEmpty(false); break;
        case key::Left: FindIndent(false); break;
        case key::Right: FindIndent(true); break;
        default:
            break_key = true;
            return false;
        }
        c = first_line - 1;
        part.clear();
        buf.clear();
        return true;
    };
    const long last = lines;
    for (c = first_line; c <= last; c++) {
        buf = std::u32string(text::Trim(std::u32string_view(Line(c))));
        VerifyAlarms();
        if (ui::KeyPressed()) {
            if (!handle_key(ui::DefineKey()))
                break;
            continue;
        }
        if (text::IsBlank(buf)) {
            if (capital) {
                sound::Play(Signal::Capital);
                capital = false;
            }
            speech::SayText(utf8::Encode(part));
            part.clear();
            empty_count++;
            if (empty_count < 5)
                for (int i = 0; i < settings.empty_delay && !ui::KeyPressed(); i++) {
                    VerifyAlarms();
                    std::this_thread::sleep_for(std::chrono::milliseconds(54));
                }
            if (ui::KeyPressed()) {
                if (!handle_key(ui::DefineKey()))
                    break;
                continue;
            }
        } else {
            if (empty_count > 2 && settings.empty_bell)
                for (int k = 0; k < 10; k++)
                    sound::Play(Signal::BreakRead);
            empty_count = 0;
            size_t point = 1;
            if (ui::KeyPressed()) {
                if (!handle_key(ui::DefineKey()))
                    break;
                continue;
            }
            if (part.size() + buf.size() > 160) {
                if (!part.empty() && part.back() == U'-') {
                    // перенос: последнее слово -- к следующей строке
                    const size_t space = part.rfind(U' ');
                    const size_t keep = space == std::u32string::npos ? 0 : space + 1;
                    speech::SayText(utf8::Encode(part.substr(0, keep)));
                    part = part.substr(keep);
                } else {
                    speech::SayText(utf8::Encode(part));
                    part.clear();
                }
            }
            if (!part.empty() && part.back() == U'-')
                buf = std::u32string(text::Trim(part.substr(0, part.size() - 1) + buf));
            else
                buf = std::u32string(text::Trim(part + U' ' + buf));
            if (buf == Repeat(buf[0], buf.size())) {
                speech::SayText(utf8::Encode(buf));
                point = buf.size() + 1;
            }
            while (point <= buf.size()) {
                buf = buf.substr(point - 1);
                if (ui::KeyPressed()) {
                    if (!handle_key(ui::DefineKey()))
                        break;
                    continue;
                }
                size_t counter = 1;
                for (; counter <= buf.size(); counter++) {
                    if (Contains(breaks, buf[counter - 1])) {
                        if (Contains(kCapitals, buf[counter - 1])) {
                            if (!capital) {
                                capital = true;
                                continue;
                            }
                            counter--;
                        }
                        break;
                    }
                    if (ui::KeyPressed()) {
                        if (!handle_key(ui::DefineKey()))
                            die = true;
                        break;
                    }
                }
                TimeControl();
                VerifyAlarms();
                if (die)
                    break;
                if (counter == 0) {
                    point = 1;
                    capital = false;
                    continue;
                }
                if (counter <= buf.size()) {
                    if (capital) {
                        sound::Play(Signal::Capital);
                        capital = false;
                    }
                    speech::SayText(utf8::Encode(buf.substr(0, counter)));
                    part.clear();
                    if (ui::KeyPressed()) {
                        if (!handle_key(ui::DefineKey()))
                            die = true;
                        break;
                    }
                    point = counter + 1;
                } else {
                    part = buf.substr(0, buf.find_last_not_of(U' ') + 1);
                    break;
                }
            }
        }
        first_line = c;
        Show();
        ui::Show();
        if (first_line == break_read_line || die)
            break;
    }
    if (!break_key) {
        const int first = part.empty() ? -1 : Dos866(part[0]);
        if (settings.capital && first >= 128 && first <= 160)
            sound::Play(Signal::Capital);
        speech::SayText(utf8::Encode(part));
    }
    AllSymbolsOff();
    if (first_line == break_read_line) {
        sound::Play(Signal::EndText);
        return;
    }
    if (settings.read_all_windows && settings.window_bell && !break_key) {
        sound::Play(Signal::NextWindow);
        return;
    }
    if (!settings.end_bell && !break_key)
        return;
    for (;;) {
        sound::Play(Signal::EndText);
        if (break_key || ui::KeyPressed())
            break;
        ui::Idle();
    }
    ui::ClearBuffer();
}

} // namespace sv
