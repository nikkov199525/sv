// help.h -- контекстная справка (HELP.PAS).
//
// У исходника справка лежала в SV.HLP -- файле записей string[70],
// собранном DOS-утилитой TXT2HLP из разделов SV\HLP\001..045. Теперь это
// обычный текст в UTF-8 (SV_help.txt): разделы разделены строками из
// знаков «=», заголовок раздела кончается его номером «[ 001 ]». Порядок
// разделов, их строки (не длиннее 70 символов) и работа с ними -- прежние.

#ifndef SV_UI_HELP_H
#define SV_UI_HELP_H

#include <string>
#include <vector>

namespace ui {

// Номер раздела справки для F1 -- по месту в программе.
extern int Context;

class Help {
public:
    bool Load(const std::string& file);
    bool Loaded() const { return !sections_.empty(); }
    // Показать раздел number (с единицы).
    void Show(int number);

private:
    struct Section {
        int first; // строка заголовка
        int last;
    };
    std::vector<std::string> lines_;
    std::vector<Section> sections_;
};

// Справка программы.
extern Help help;

} // namespace ui

#endif
