// unicode.h -- регистр букв.
//
// Покрыты алфавиты, с которыми программа имеет дело: латиница (с Latin-1 и
// Latin Extended-A), кириллица (включая украинские и белорусские буквы),
// греческий.

#ifndef SV_TEXT_UNICODE_H
#define SV_TEXT_UNICODE_H

#include <string>
#include <string_view>

namespace text {

char32_t ToUpper(char32_t cp);
char32_t ToLower(char32_t cp);
inline bool IsUpper(char32_t cp) {
    return ToLower(cp) != cp;
}

std::string Upper(std::string_view text);
std::string Lower(std::string_view text);
std::u32string Upper(std::u32string_view text);
// Приведение для сравнения без учёта регистра.
std::u32string FoldCase(std::u32string_view text);

} // namespace text

#endif
