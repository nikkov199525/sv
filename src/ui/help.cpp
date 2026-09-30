// help.cpp -- HELP.PAS.

#include "ui/help.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/speech.h"
#include "text/strings.h"
#include "ui/dialogs.h"

#include <algorithm>
#include <chrono>
#include <fstream>
#include <thread>

namespace ui {

int Context = 0;
Help help;

namespace {

constexpr int kLineWidth = 70;

bool IsSeparator(const std::string& s) {
    return s.size() >= 20 && s.find_first_not_of('=') == std::string::npos;
}

bool IsHeader(const std::string& s) {
    const size_t end = s.find_last_not_of(' ');
    return end != std::string::npos && s[end] == ']' && s.rfind('[', end) != std::string::npos;
}

} // namespace

bool Help::Load(const std::string& file) {
    lines_.clear();
    sections_.clear();
    std::ifstream in(sys::Path(file), std::ios::binary);
    std::vector<std::string> all;
    for (std::string line; std::getline(in, line);) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        if (all.empty() && text::StartsWith(line, "\xEF\xBB\xBF"))
            line.erase(0, 3);
        all.push_back(std::move(line));
    }
    // Раздел: разделитель, заголовок, разделитель, пустая строка, текст до
    // следующего разделителя. Пустые строки в конце раздела -- не его.
    for (size_t i = 0; i < all.size();) {
        if (!(IsSeparator(all[i]) && i + 2 < all.size() && IsHeader(all[i + 1]) &&
              IsSeparator(all[i + 2]))) {
            i++;
            continue;
        }
        size_t first = i + 3;
        if (first < all.size() && all[first].empty())
            first++;
        size_t next = first;
        while (next < all.size() && !IsSeparator(all[next]))
            next++;
        size_t end = next;
        while (end > first && text::IsBlank(all[end - 1]))
            end--;
        if (end > first + 1) {
            const int start = static_cast<int>(lines_.size());
            for (size_t n = first; n < end; n++)
                lines_.push_back(text::Left(all[n], kLineWidth));
            sections_.push_back({start, static_cast<int>(lines_.size()) - 1});
        }
        i = next;
    }
    return Loaded();
}

void Help::Show(int number) {
    if (number < 1 || number > static_cast<int>(sections_.size()))
        return;
    const Section section = sections_[number - 1];
    auto line = [&](int n) -> std::string {
        return n >= 0 && n < static_cast<int>(lines_.size()) ? lines_[n] : std::string();
    };
    const Screen saved = screen;
    Clear(5, 3, 76, 22);
    Frame(5, 3, 76, 22);
    const std::string title = line(section.first);
    if (!text::IsBlank(title)) {
        speech::Say(title);
        PutLine((kWidth - (static_cast<int>(text::Width(title)) + 2)) / 2 + 1, 3, " " + title + " ",
                color.title);
    }
    // Чтение раздела вслух с текущей строки; клавиша прерывает.
    auto read_on = [&](int& point) {
        int n = point;
        for (; n <= section.last; n++) {
            const std::string text = line(n);
            if (!text::IsBlank(text))
                speech::Say(std::string(text::Trim(text)));
            else
                std::this_thread::sleep_for(std::chrono::milliseconds(50));
            if (KeyPressed()) {
                DefineKey();
                sound::Play(sound::Signal::Break);
                break;
            }
        }
        point = std::min(n, section.last); // как «for C := Point to ELine»
    };
    int point = section.first + 1;
    for (;;) {
        std::string first_line;
        for (int row = 1; row <= 18; row++) {
            std::string text(kLineWidth, ' ');
            if (point + row - 1 <= section.last) {
                text = text::PadRight(line(point + row - 1), kLineWidth);
                if (row == 1)
                    first_line = text;
            }
            PutLine(6, 3 + row, text, color.text);
        }
        {
            const ExitKeys keys{key::Up,   key::Down,     key::CtrlEnter, key::F6,
                                key::F1,   key::CtrlHome, key::CtrlEnd};
            ViewLine(6, 4, first_line, kLineWidth);
        }
        switch (ReturnCode) {
        case key::Esc:
            screen = saved;
            ui::Show();
            speech::Say("Вы+ход.");
            return;
        case key::Down:
            if (point < section.last)
                point++;
            else
                sound::Play(sound::Signal::Edge);
            break;
        case key::Up:
            if (point > section.first + 1)
                point--;
            else
                sound::Play(sound::Signal::Edge);
            break;
        case key::CtrlEnter:
            if (OnlyCtrl())
                read_on(point);
            break;
        case key::CtrlHome:
            point = section.first + 1;
            Posit = 0;
            sound::Play(sound::Signal::Edge);
            break;
        case key::CtrlEnd:
            point = section.last;
            Posit = 0;
            sound::Play(sound::Signal::Edge);
            break;
        case key::F6:
            read_on(point);
            break;
        case key::F1:
            speech::Say("f6 и ко+нтрл-э+нтер - чте+ние по+мощи, f5 и а+льт-пробе+л - чте+ние строки+.");
            speech::Say("эске+йп - выход.");
            break;
        }
    }
}

} // namespace ui
