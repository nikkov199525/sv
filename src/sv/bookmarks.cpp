// bookmarks.cpp -- V_U.PAS: toViewer.BookMark, AddBookMark, ChBookMark,
// DelBookMark.
//
// Закладки -- в SV.VBM рядом с программой; к ним добавляются закладки из
// внешнего файла: «имя текста.VBM» в текущем каталоге (если включено
// автодобавление) или выбранного клавишей F3.

#include "sv/viewer.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "sv/app.h"
#include "sv/file_dialog.h"
#include "sv/history.h"
#include "sv/program.h"
#include "sv/records.h"
#include "sv/settings.h"
#include "text/strings.h"
#include "ui/dialogs.h"
#include "ui/help.h"

#include <algorithm>
#include <filesystem>

namespace sv {

namespace {

namespace fs = std::filesystem;

constexpr const char* kBookmarkExt = ".VBM";

bool NonEmptyFile(const std::string& file) {
    std::error_code error;
    return fs::is_regular_file(sys::Path(file), error) && fs::file_size(sys::Path(file), error) > 0;
}

std::string FileName(const std::string& path) {
    return sys::Utf8(sys::Path(path).filename());
}

// Строка ввода имени файла закладок со списком прошлых вводов.
// false -- Esc.
bool AskBookmarkFile(HistoryKind kind, const std::string& suggested, std::string& mask,
                     std::string& file) {
    InputHistory history(kind);
    speech::Say("и+мя фа+йла.");
    ui::Frame(21, 11, 60, 13);
    ui::PutLine(31, 11, " Введите имя файла ", ui::color.title);
    history.items[0] = suggested;
    if (!history.exists) {
        mask = suggested;
        speech::Say(mask);
    }
    ui::Posit = 0;
    int point = 1;
    {
        const ui::ExitKeys keys{key::F1, key::Down, key::Up};
        do {
            if (history.exists) {
                mask = history.items[point - 1];
                speech::Say(mask);
            }
            ui::EditLine(22, 12, mask, 80, 37);
            if (ui::ReturnCode == key::Down) {
                if (history.exists && point < history.last)
                    point++;
                else
                    sound::Play(sound::Signal::Edge);
            }
            if (ui::ReturnCode == key::Up) {
                if (history.exists && point > 1)
                    point--;
                else
                    sound::Play(sound::Signal::Edge);
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
            }
        } while (ui::ReturnCode != key::Enter && ui::ReturnCode != key::Esc);
    }
    if (ui::ReturnCode == key::Esc) {
        speech::Say(ui::kCancel);
        return false;
    }
    history.Save(!text::EqualNoCase(text::Trim(mask), text::Trim(history.items[point - 1])), mask);
    return true;
}

} // namespace

void Viewer::Bookmarks() {
    static std::string mask;
    if (!installed || !fs::exists(sys::Path(Path())))
        return;
    const std::string main_file = ProgramFile(kBookmarkFile);
    ui::Screen saved = ui::screen;
    bool can_say = true;
    int current = 1;
    std::string extra_file;
    if (settings.auto_bookmarks && NonEmptyFile(name + kBookmarkExt))
        extra_file = name + kBookmarkExt;
    // Закладка этого текста? Глобальные -- по имени файла без каталога.
    auto matches = [&](const Bookmark& b) {
        return settings.global_bookmarks ? sys::SameFileName(FileName(b.file), name + ext)
                                         : sys::SameFileName(b.file, Path());
    };
    for (;;) {
        if (!fs::exists(sys::Path(main_file)) || (!NonEmptyFile(main_file) && extra_file.empty())) {
            if (!ui::Yes("   Закладок нет.  Вложить закладку?   ") || !AddBookmark())
                break;
        }
        ui::PopupMenu menu;
        std::vector<int32_t> numbers;
        for (const std::string& file : {main_file, extra_file}) {
            if (file.empty())
                continue;
            for (const Bookmark& b : ReadBookmarks(file)) {
                if (!matches(b))
                    continue;
                std::string item = text::PadRight(b.name, 24);
                if (settings.global_bookmarks)
                    item += ": ";
                if (settings.bookmark_line) {
                    const std::string number = text::FormatNumber(b.line);
                    item += ": " + std::string(12 - std::min<size_t>(number.size(), 12), ' ') + number;
                }
                menu.items.push_back({item, std::to_string(b.line)});
                numbers.push_back(b.number);
            }
        }
        if (menu.items.empty()) {
            if (!ui::Yes("   Закладок нет.  Вложить закладку?   ") || !AddBookmark())
                break;
            continue;
        }
        if (can_say) {
            can_say = false;
            speech::Say("Спи+сак закла+дак.");
        }
        ui::screen = saved;
        ui::Show();
        const int count = static_cast<int>(menu.items.size());
        if (count < 6)
            menu.Center();
        else
            menu.SetPosition(21, 10, 60, 16);
        ui::Clear(menu.left, menu.top, menu.right, menu.bottom);
        menu.cycle = settings.cycle_menu;
        menu.cursor = settings.cursor;
        menu.title = " Список закладок ";
        if (current == 0)
            current = count;
        menu.current = current;
        ui::Context = 16;
        {
            const ui::ExitKeys keys{key::Ins, key::Space, key::Del, key::F10,
                                    key::F1,  key::F2,    key::F3};
            if (!ui::KeyPressed())
                menu.Call();
            else
                ui::ReturnCode = ui::DefineKey();
        }
        current = menu.current;
        const int selected = std::clamp(menu.current, 1, count);
        const int32_t number = numbers[selected - 1];
        switch (ui::ReturnCode) {
        case key::Enter: {
            if (ui::OnlyCtrl())
                continue;
            const auto line = text::ParseInt(menu.items[selected - 1].hint);
            if (line && *line <= lines) {
                first_line = static_cast<long>(*line);
                SayLineNumber();
            } else
                ShowError(1);
            break;
        }
        case key::Ins:
            if (!AddBookmark() && ui::ReturnCode != key::Esc)
                ShowError(2);
            else
                current = count + 1;
            continue;
        case key::Space:
            ChangeBookmark(number);
            continue;
        case key::Del:
            if (DeleteBookmark(number) && menu.current == count)
                current = menu.current - 1;
            continue;
        case key::F10: {
            saved = ui::screen;
            ui::PopupMenu actions;
            actions.items = {{"  Добавить закладку      ", ""},
                             {"  Перезаложить закладку  ", ""},
                             {"  Удалить закладку       ", ""},
                             {"  Выход                   ", ""}};
            actions.cycle = settings.cycle_menu;
            actions.cursor = settings.cursor;
            actions.Center();
            actions.my = 0;
            ui::Context = 17;
            speech::Say("меню+.");
            {
                const ui::ExitKeys keys{key::F1};
                for (;;) {
                    actions.Call();
                    if (ui::ReturnCode != key::F1)
                        break;
                    ui::help.Show(ui::Context);
                }
            }
            if (ui::ReturnCode == key::Enter)
                switch (actions.current) {
                case 1:
                    if (!AddBookmark())
                        ShowError(2);
                    break;
                case 2: ChangeBookmark(number); break;
                case 3: DeleteBookmark(number); break;
                case 4: speech::Say("текст."); return;
                }
            ui::screen = saved;
            continue;
        }
        case key::F1:
            ui::help.Show(ui::Context);
            continue;
        case key::F2: {
            // Закладки этого текста -- во внешний файл.
            if (!NonEmptyFile(main_file)) {
                ui::ShowMessage("     Не найден файл закладок     ", "");
                continue;
            }
            std::string file;
            if (!AskBookmarkFile(kBookmarkSaveHistory, name + kBookmarkExt, mask, file))
                continue;
            const std::string shown = FileName(file);
            std::vector<Bookmark> saved_marks;
            if (fs::exists(sys::Path(file))) {
                ui::ButtonRow choice;
                choice.items = {" Перезаписать ", " Добавить ", " Отмена "};
                std::string message =
                    std::string(std::max<int>(33 - static_cast<int>(text::Width(shown)), 0) / 2, ' ') +
                    "Файл  " + shown + "  уже существует";
                choice.message = text::PadRight(message, 54);
                choice.cursor = settings.cursor;
                choice.margin_left = 4;
                choice.margin_top = 1;
                choice.SetPosition(13, 9, 68, 16);
                choice.Call();
                if (choice.current == 3 || ui::ReturnCode == key::Esc) {
                    speech::Say(ui::kCancel);
                    continue;
                }
                if (choice.current == 2)
                    saved_marks = ReadBookmarks(file);
            }
            for (const Bookmark& b : ReadBookmarks(main_file))
                if (matches(b))
                    saved_marks.push_back(b);
            if (!WriteBookmarks(file, saved_marks)) {
                ShowError(7);
                continue;
            }
            speech::Say("сохранено+ в фа+йл " + shown);
            break;
        }
        case key::F3: {
            // Добавить закладки из внешнего файла.
            std::string file;
            if (!AskBookmarkFile(kBookmarkLoadHistory, name + kBookmarkExt, mask, file))
                continue;
            if (!NonEmptyFile(file)) {
                ShowError(8);
                continue;
            }
            extra_file = file;
            continue;
        }
        }
        break;
    }
    speech::Say("текст.");
}

bool Viewer::AddBookmark() {
    ui::Context = 18;
    InputHistory history(kBookmarkHistory);
    std::string bookmark_name;
    Show();
    ui::Frame(28, 12, 53, 14);
    ui::PutLine(34, 12, " Имя закладки ", ui::color.title);
    ui::PutLine(29, 13, std::string(24, ' '), ui::color.text);
    speech::Say("И+мя закла+дки.");
    ui::ShowCursor();
    int point = 1;
    {
        const ui::ExitKeys keys{key::F1, key::Up, key::Down};
        do {
            if (history.exists)
                bookmark_name = history.items[point - 1];
            speech::Say(bookmark_name);
            ui::EditLine(29, 13, bookmark_name, 23, 23);
            if (ui::ReturnCode == key::F1)
                ui::help.Show(ui::Context);
            if (ui::ReturnCode == key::Down) {
                if (history.exists && point < history.last)
                    point++;
                else
                    sound::Play(sound::Signal::Edge);
            }
            if (ui::ReturnCode == key::Up) {
                if (history.exists && point > 1)
                    point--;
                else
                    sound::Play(sound::Signal::Edge);
            }
        } while (ui::ReturnCode != key::Esc && ui::ReturnCode != key::Enter);
    }
    if (ui::ReturnCode == key::Esc) {
        speech::Say(ui::kCancel);
        return false;
    }
    history.Save(
        !text::EqualNoCase(text::Trim(bookmark_name), text::Trim(history.items[point - 1])),
        bookmark_name);
    if (!settings.cursor)
        ui::HideCursor();
    const std::string file = ProgramFile(kBookmarkFile);
    std::vector<Bookmark> marks = ReadBookmarks(file);
    marks.push_back({Path(), bookmark_name, static_cast<int32_t>(first_line),
                     static_cast<int32_t>(marks.size()) + 1});
    if (!WriteBookmarks(file, marks)) {
        ShowError(3);
        return false;
    }
    speech::Say(ui::kOk);
    return true;
}

void Viewer::ChangeBookmark(int32_t number) {
    if (!ui::Yes("        Перезаложить закладку?        "))
        return;
    const std::string file = ProgramFile(kBookmarkFile);
    std::vector<Bookmark> marks = ReadBookmarks(file);
    if (number < 1 || number > static_cast<int32_t>(marks.size())) {
        ShowError(3);
        return;
    }
    marks[number - 1].line = static_cast<int32_t>(first_line);
    WriteBookmarks(file, marks);
}

bool Viewer::DeleteBookmark(int32_t number) {
    if (number < 1 || !ui::Yes("          Удалить закладку ?          "))
        return false;
    const std::string file = ProgramFile(kBookmarkFile);
    std::vector<Bookmark> marks = ReadBookmarks(file);
    if (number > static_cast<int32_t>(marks.size())) {
        ShowError(3);
        return false;
    }
    if (marks.size() == 1) {
        std::error_code error;
        fs::remove(sys::Path(file), error);
        return true;
    }
    // записи после удалённой -- на место выше, их номера -- на единицу меньше
    marks.erase(marks.begin() + (number - 1));
    for (size_t i = number - 1; i < marks.size(); i++)
        marks[i].number--;
    WriteBookmarks(file, marks);
    return true;
}

} // namespace sv
