// fragments.h -- пользовательские замены в тексте (файл SV.CHF).
//
// Правило -- пара строк в любом порядке:
//     #что заменить#     или  @#что заменить#  (без учёта регистра)
//     ^на что заменить^
// Закрывающий знак -- последний такой знак в строке. Прочие строки --
// примечания. Правила применяются к строке текста по очереди.

#ifndef SV_TEXT_FRAGMENTS_H
#define SV_TEXT_FRAGMENTS_H

#include <string>
#include <string_view>
#include <vector>

namespace text {

struct FragmentRule {
    std::u32string find;
    std::u32string replace;
    bool ignore_case = false;
};

// Содержимое файла: UTF-8, старый файл -- в 866.
std::vector<FragmentRule> ParseFragmentRules(std::string_view file_bytes);
std::u32string ApplyFragmentRules(std::u32string line, const std::vector<FragmentRule>& rules);

} // namespace text

#endif
