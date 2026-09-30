// strings.h -- мелочи для строк UTF-8, общие для всей программы.
//
// Длины и позиции -- в символах, а не в байтах: так их видит пользователь
// на экране. «Пробел» у Trim и IsBlank -- только ' ', как у исходника.

#ifndef SV_TEXT_STRINGS_H
#define SV_TEXT_STRINGS_H

#include <optional>
#include <string>
#include <string_view>

namespace text {

// Строка пуста или из одних пробелов.
bool IsBlank(std::string_view s);
bool IsBlank(std::u32string_view s);
std::string_view TrimLeft(std::string_view s);
std::string_view TrimRight(std::string_view s);
std::string_view Trim(std::string_view s);
std::u32string_view Trim(std::u32string_view s);
// Внутренние повторы пробелов -- в один, крайние пробелы остаются.
std::string CollapseSpaces(std::string_view s);

// Ширина на экране -- число символов.
size_t Width(std::string_view s);
// Первые count символов, последние count символов.
std::string Left(std::string_view s, size_t count);
std::string Right(std::string_view s, size_t count);
// count символов, начиная с символа start (с нуля).
std::string Mid(std::string_view s, size_t start, size_t count = std::string::npos);
// Дополнить пробелами справа до width символов.
std::string PadRight(std::string_view s, size_t width);

bool StartsWith(std::string_view s, std::string_view prefix);
// Сравнение без учёта регистра.
bool EqualNoCase(std::string_view a, std::string_view b);

// Целое без знаков вокруг (пробелы в начале допускаются, как у Val).
std::optional<long long> ParseInt(std::string_view s);
// Число с разделителем классов, как у автора: 16.777.216 (separator = 0 -- без него).
std::string FormatNumber(long long n, char separator = '.');

} // namespace text

#endif
