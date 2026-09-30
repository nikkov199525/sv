// file_dialog.cpp -- FF.PAS: ChFile, FastFind, Fill_FList, Sort_FList.

#include "sv/file_dialog.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "text/utf8.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <algorithm>
#include <filesystem>

namespace sv {

std::string last_path;

namespace {

namespace fs = std::filesystem;

// Окно списка.
constexpr int kLeft = 15, kTop = 8, kRight = 66, kBottom = 18;
constexpr int kRows = kBottom - kTop - 3;

struct Entry {
    std::string name;
    bool directory = false;
    uintmax_t size = 0;
    bool marked = false;
};

enum class Sort { ByExtension, ByName };
Sort sort_order = Sort::ByExtension;
bool show_hidden = false;

// Расширение -- с последней точки, как у FSplit.
std::pair<std::string, std::string> SplitName(const std::string& name) {
    const size_t dot = name.rfind('.');
    if (dot == std::string::npos)
        return {name, ""};
    return {name.substr(0, dot), name.substr(dot)};
}

// Маска DOS: «*» и «?», без учёта регистра; «*.*» -- всё, «имя.*» -- и без
// расширения.
bool MatchMask(std::u32string_view mask, std::u32string_view name) {
    if (mask.empty())
        return name.empty();
    if (mask[0] == U'*') {
        for (size_t skip = 0; skip <= name.size(); skip++)
            if (MatchMask(mask.substr(1), name.substr(skip)))
                return true;
        return false;
    }
    return !name.empty() && (mask[0] == U'?' || mask[0] == name[0]) &&
           MatchMask(mask.substr(1), name.substr(1));
}

bool MatchesMask(const std::string& mask, const std::string& name) {
    if (mask == "*.*" || mask == "*")
        return true;
    const std::u32string m = text::FoldCase(utf8::Decode(mask));
    const std::u32string n = text::FoldCase(utf8::Decode(name));
    if (MatchMask(m, n))
        return true;
    return m.size() >= 2 && m.substr(m.size() - 2) == U".*" && n.find(U'.') == std::u32string::npos &&
           MatchMask(m.substr(0, m.size() - 2), n);
}

std::string Normalize(const fs::path& path) {
    std::string s = sys::Utf8(path.lexically_normal());
    while (s.size() > 1 && s.back() == sys::kSeparator &&
           sys::Utf8(sys::Path(s).root_path()) != s)
        s.pop_back();
    return s;
}

std::vector<Entry> ReadDirectory(const std::string& dir, const std::string& mask,
                                 bool change_dir, const std::string& start_dir) {
    std::vector<Entry> directories, files;
    const fs::path path = sys::Path(dir);
    std::error_code error;
    const bool is_root = path.has_parent_path() ? path == path.root_path() : true;
    if (!is_root && !(sys::SameFileName(start_dir, dir) && !change_dir))
        directories.push_back({"..", true, 0, false});
    for (fs::directory_iterator it(path, fs::directory_options::skip_permission_denied, error), end;
         !error && it != end; it.increment(error)) {
        if (!show_hidden && sys::IsHidden(*it))
            continue;
        std::error_code status_error;
        const bool directory = it->is_directory(status_error);
        const std::string name = sys::Utf8(it->path().filename());
        if (directory)
            directories.push_back({name, true, 0, false});
        else if (MatchesMask(mask, name))
            files.push_back({name, false, it->file_size(status_error), false});
    }
    if (error)
        return {};
    directories.insert(directories.end(), files.begin(), files.end());
    return directories;
}

void SortEntries(std::vector<Entry>& entries) {
    auto key = [](const Entry& e) {
        const auto [name, ext] = SplitName(e.name);
        std::string k = text::Lower(sort_order == Sort::ByExtension ? ext + name : name + ext);
        return e.directory ? '\x01' + k : k;
    };
    std::stable_sort(entries.begin(), entries.end(),
                     [&](const Entry& a, const Entry& b) { return key(a) < key(b); });
}

// Путь в заголовке: у длинного -- «C:\...» и хвост с целого каталога.
std::string ShortPath(const std::string& path) {
    constexpr size_t kMax = kRight - kLeft - 5;
    const std::string root = sys::Utf8(sys::Path(path).root_path());
    std::string shown = path;
    while (text::Width(shown) > kMax) {
        const std::string rest = shown.substr(root.size());
        const size_t separator = rest.find(sys::kSeparator);
        if (separator == std::string::npos) {
            shown = "..." + text::Right(shown, kMax - 3);
            break;
        }
        shown = root + "..." + rest.substr(separator + 1);
    }
    return shown;
}

class Dialog {
public:
    Dialog(std::string mask, bool change_dir) : mask_(std::move(mask)), change_dir_(change_dir) {}

    std::vector<std::string> Run();

private:
    std::string mask_;
    bool change_dir_;
    std::string start_dir_;
    std::vector<Entry> list_;
    int current_ = 1;
    int first_ = 0; // строк списка выше окна

    int Count() const { return static_cast<int>(list_.size()); }
    Entry& Current() { return list_[current_ - 1]; }
    void Show();
    int FastFind();
    void Select(const std::string& name);
};

void Dialog::Show() {
    ui::Clear(kLeft, kTop, kRight, kBottom);
    ui::Frame(kLeft, kTop, kRight, kBottom);
    for (int row = 1; row <= kRows; row++) {
        uint8_t attr = 0x1F;
        const int n = first_ + row;
        if (n < 1 || n > Count()) {
            ui::PutLine(kLeft + 4, kTop + 1 + row, std::string(22, ' '), attr);
            continue;
        }
        const Entry& e = list_[n - 1];
        if (n == current_)
            attr = 0x1E;
        std::string size;
        if (e.directory)
            size = e.name == ".." ? "<КАТАЛОГ>" : ">КАТАЛОГ<";
        else {
            size = e.size < 10000000 ? text::FormatNumber(static_cast<long long>(e.size))
                                     : text::FormatNumber(static_cast<long long>(e.size / 1024)) + 'k';
            size = std::string(9 - std::min<size_t>(text::Width(size), 9), ' ') + size;
        }
        ui::PutLine(kLeft + 4, kTop + 1 + row,
                    text::Left(e.name, kRight - kLeft - text::Width(size) - 3), attr);
        ui::PutLine(kLeft + 17 + 22, kTop + 1 + row, size, attr);
        if (e.marked)
            ui::PutLine(kLeft + 3, kTop + 1 + row, "*", attr);
    }
    const std::string title = " " + ShortPath(last_path) + " ";
    ui::PutLine(kLeft + ((kRight - kLeft - 1) - static_cast<int>(text::Width(title))) / 2 + 1, kTop,
                title, ui::color.frame);
    ui::PutLine(kLeft + 2, kBottom, show_hidden ? "HIDN" : "", ui::color.frame);
    ui::PutLine(kLeft + 9, kBottom, sort_order == Sort::ByExtension ? "ext" : "name",
                ui::color.frame);
}

// Быстрый поиск по первым буквам (Alt).
int Dialog::FastFind() {
    std::u32string prefix;
    bool can_speak = true;
    int old = current_;
    speech::Say("По+иск.");
    for (;;) {
        Show();
        ui::Frame(29, kBottom + 1, 52, kBottom + 3);
        ui::PutLine(30, kBottom + 2, " Поиск - ", ui::color.frame);
        ui::PutLine(31 + 8, kBottom + 2, prefix + std::u32string(13 - prefix.size(), U' '),
                    ui::color.message);
        ui::SetCursorXY(31 + 8 + static_cast<int>(prefix.size()), kBottom + 2);
        ui::Show();
        const ui::KeyInput input = ui::ReadKey();
        if (input.ch >= U' ' && prefix.size() < 13) {
            prefix += input.ch;
            const std::u32string folded = text::FoldCase(prefix);
            // с текущего до конца, затем с начала
            int found = 0;
            for (int pass = 0; pass < 2 && !found; pass++)
                for (int n = pass == 0 ? current_ : 1; n <= Count() && !found; n++) {
                    if (pass == 1 && current_ <= 1)
                        break;
                    const std::u32string name = text::FoldCase(utf8::Decode(list_[n - 1].name));
                    if (name.compare(0, folded.size(), folded) == 0)
                        found = n;
                }
            if (!found) {
                prefix.pop_back();
                can_speak = true;
                sound::Play(sound::Signal::Edge);
            } else {
                current_ = found;
                first_ = current_ > kRows ? current_ - kRows : 0;
                if (can_speak || old != current_) {
                    speech::Say(Current().name);
                    can_speak = false;
                    old = current_;
                }
            }
        } else if (input.code == key::Back) {
            if (!prefix.empty()) {
                speech::SaySymbol(prefix.back());
                prefix.pop_back();
                can_speak = true;
            }
        } else
            return input.code;
    }
}

void Dialog::Select(const std::string& name) {
    for (int n = 1; n <= Count(); n++)
        if (sys::SameFileName(list_[n - 1].name, name)) {
            current_ = n;
            if (current_ > kRows)
                first_ = current_ - kRows;
            return;
        }
    current_ = 1;
}

std::vector<std::string> Dialog::Run() {
    ui::ReturnCode = 0;
    if (text::IsBlank(last_path))
        last_path = sys::Utf8(fs::current_path());
    start_dir_ = last_path;
    std::string find_name;
    int char_pos = 0;
    bool dont_say = false;
    std::vector<std::string> result;
    auto path_of = [&](const std::string& name) { return sys::Utf8(sys::Path(last_path) / sys::Path(name)); };
    auto go_to = [&](const std::string& dir, const std::string& select) {
        last_path = Normalize(sys::Path(dir));
        find_name = select;
        current_ = 1;
        first_ = 0;
        char_pos = 0;
    };
    ui::SetAltAloneIsKey(true);
    bool reload = true;
    int key = 0;
    while (true) {
        if (reload) {
            reload = false;
            list_ = ReadDirectory(last_path, mask_, change_dir_, start_dir_);
            if (Count() == 1 && !change_dir_ && sys::SameFileName(start_dir_, last_path) &&
                !list_[0].directory) {
                result.push_back(path_of(list_[0].name));
                break;
            }
            if (Count() < 1) {
                key = 0;
                break;
            }
            SortEntries(list_);
            if (!text::IsBlank(find_name))
                Select(find_name);
        }
        Show();
        ui::SetCursorXY(kLeft + 2, kTop + 1 + current_ - first_);
        ui::Show();
        if (!dont_say)
            speech::Say(Current().name == ".." ? "две+ то+чки." : Current().name);
        dont_say = false;
        if (Current().marked)
            sound::Play(sound::Signal::Selected);
        key = ui::DefineKey();
        if (key == 0 && ui::OnlyAlt())
            key = FastFind();
        if (key == key::Esc)
            break;
        switch (key) {
        case key::Down:
            if (current_ < Count()) {
                current_++;
                if (current_ > kRows + first_)
                    first_++;
                char_pos = 0;
            } else
                sound::Play(sound::Signal::Edge);
            break;
        case key::Up:
            if (current_ > 1) {
                current_--;
                if (current_ < first_ + 1)
                    first_--;
                char_pos = 0;
            } else
                sound::Play(sound::Signal::Edge);
            break;
        case key::PgUp:
            current_ -= kRows - 1;
            first_ = std::max(first_ - (kRows - 1), 0);
            if (current_ <= 0) {
                current_ = 1;
                first_ = 0;
                sound::Play(sound::Signal::Edge);
            }
            char_pos = 0;
            break;
        case key::PgDn:
            current_ += kRows - 1;
            first_ = std::min(first_ + kRows - 1, Count() - kRows);
            if (current_ >= Count()) {
                current_ = Count();
                first_ = current_ - kRows;
                sound::Play(sound::Signal::Edge);
            }
            char_pos = 0;
            break;
        case key::Home:
            current_ = 1;
            first_ = 0;
            char_pos = 0;
            break;
        case key::End:
            current_ = Count();
            first_ = current_ - kRows;
            char_pos = 0;
            break;
        case key::Right:
        case key::Left: {
            const std::u32string name = utf8::Decode(Current().name);
            char_pos += key == key::Right ? 1 : -1;
            if (char_pos >= 1 && char_pos <= static_cast<int>(name.size()))
                speech::SaySymbol(name[char_pos - 1]);
            else {
                char_pos = std::clamp(char_pos, 0, static_cast<int>(name.size()) + 1);
                sound::Play(sound::Signal::Edge);
            }
            dont_say = true;
            break;
        }
        case key::Enter:
            if (!Current().directory) {
                for (const Entry& e : list_)
                    if (e.marked)
                        result.push_back(path_of(e.name));
                if (result.empty())
                    result.push_back(path_of(Current().name));
                goto done;
            }
            if (Current().name == "..") {
                const fs::path dir = sys::Path(last_path);
                go_to(sys::Utf8(dir.parent_path()), sys::Utf8(dir.filename()));
            } else
                go_to(path_of(Current().name), "");
            reload = true;
            break;
        case key::CtrlS:
            if (ui::OnlyCtrl()) {
                if (sort_order == Sort::ByName) {
                    sort_order = Sort::ByExtension;
                    speech::Say("Сортирова+ть по+ расшире+нию.");
                } else {
                    sort_order = Sort::ByName;
                    speech::Say("Сортирова+ть по+ и+мени фа+йла..");
                }
                go_to(last_path, Current().name);
                reload = true;
            }
            break;
        case key::CtrlH:
            if (ui::OnlyCtrl()) {
                show_hidden = !show_hidden;
                speech::Say(std::string(show_hidden ? "" : "не") + "пока+зывать скры+тые фа+йлы.");
                go_to(last_path, Current().name);
                reload = true;
            }
            break;
        case key::F1:
            ui::help.Show(ui::Context);
            break;
        case key::Alt9: case key::Alt8: case key::Alt7: case key::Alt6: case key::Alt5:
        case key::Alt4: case key::Alt3: case key::Alt2: case key::Alt1:
            if (ui::OnlyAlt() && change_dir_) {
                const char drive = static_cast<char>('A' + (-key - 120));
                if (sys::Drives().find(drive) != std::string::npos) {
                    std::error_code error;
                    const fs::path dir = fs::absolute(sys::Path(std::string(1, drive) + ":"), error);
                    if (!error && fs::is_directory(dir, error)) {
                        go_to(sys::Utf8(dir), "");
                        reload = true;
                    }
                }
            }
            break;
        case key::CtrlPgUp:
            if (ui::OnlyCtrl() && change_dir_) {
                const fs::path dir = sys::Path(last_path);
                go_to(sys::Utf8(dir.parent_path()), sys::Utf8(dir.filename()));
                reload = true;
            }
            break;
        case key::CtrlBackslash:
            if (ui::OnlyCtrl() && change_dir_) {
                go_to(sys::Utf8(sys::Path(last_path).root_path()), "");
                reload = true;
            }
            break;
        case key::Ins:
            if (!Current().directory) {
                Current().marked = !Current().marked;
                speech::Say(std::to_string(std::count_if(list_.begin(), list_.end(),
                                                         [](const Entry& e) { return e.marked; })));
            }
            break;
        case key::CtrlEnd: {
            // к последнему каталогу списка
            if (!ui::OnlyCtrl())
                break;
            const auto file = std::find_if(list_.begin(), list_.end(),
                                           [](const Entry& e) { return !e.directory; });
            if (file == list_.begin()) {
                sound::Play(sound::Signal::Edge);
                break;
            }
            current_ = static_cast<int>(file - list_.begin());
            if (current_ > kRows)
                first_ = current_ - kRows;
            char_pos = 0;
            break;
        }
        case key::CtrlHome: {
            // к первому файлу списка
            if (!ui::OnlyCtrl())
                break;
            const auto file = std::find_if(list_.begin(), list_.end(),
                                           [](const Entry& e) { return !e.directory; });
            if (file == list_.end())
                sound::Play(sound::Signal::Edge);
            else {
                current_ = static_cast<int>(file - list_.begin()) + 1;
                if (current_ > kRows)
                    first_ = current_ - kRows;
                char_pos = 0;
            }
            break;
        }
        }
    }
done:
    ui::SetAltAloneIsKey(false);
    ui::ReturnCode = key;
    return result;
}

} // namespace

bool HasWildcards(const std::string& name) {
    return name.find_first_of("*?") != std::string::npos;
}

std::vector<std::string> ChooseFiles(const std::string& mask, bool change_dir) {
    return Dialog(mask, change_dir).Run();
}

std::vector<std::string> ChooseByMask(const std::string& mask) {
    ui::Context = 14;
    const fs::path path = sys::Path(mask);
    if (path.has_parent_path())
        last_path = Normalize(path.parent_path());
    return ChooseFiles(sys::Utf8(path.filename()));
}

} // namespace sv
