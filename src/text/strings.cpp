// strings.cpp -- мелочи для строк UTF-8.

#include "text/strings.h"

#include "text/unicode.h"
#include "text/utf8.h"

#include <charconv>

namespace text {

bool IsBlank(std::string_view s) {
    return s.find_first_not_of(' ') == std::string_view::npos;
}

bool IsBlank(std::u32string_view s) {
    return s.find_first_not_of(U' ') == std::u32string_view::npos;
}

std::string_view TrimLeft(std::string_view s) {
    const size_t first = s.find_first_not_of(' ');
    return first == std::string_view::npos ? std::string_view() : s.substr(first);
}

std::string_view TrimRight(std::string_view s) {
    const size_t last = s.find_last_not_of(' ');
    return last == std::string_view::npos ? std::string_view() : s.substr(0, last + 1);
}

std::string_view Trim(std::string_view s) {
    return TrimRight(TrimLeft(s));
}

std::u32string_view Trim(std::u32string_view s) {
    const size_t first = s.find_first_not_of(U' ');
    if (first == std::u32string_view::npos)
        return {};
    return s.substr(first, s.find_last_not_of(U' ') - first + 1);
}

std::string CollapseSpaces(std::string_view s) {
    const size_t lead = s.size() - TrimLeft(s).size();
    const size_t trail = s.size() - TrimRight(s).size();
    if (lead == s.size())
        return {};
    std::string result(lead, ' ');
    for (char c : Trim(s))
        if (c != ' ' || result.back() != ' ')
            result += c;
    return result.append(trail, ' ');
}

size_t Width(std::string_view s) {
    return utf8::Length(s);
}

std::string Left(std::string_view s, size_t count) {
    return std::string(utf8::Left(s, count));
}

std::string Right(std::string_view s, size_t count) {
    const size_t width = Width(s);
    return std::string(count >= width ? s : utf8::Skip(s, width - count));
}

std::string Mid(std::string_view s, size_t start, size_t count) {
    return std::string(utf8::Left(utf8::Skip(s, start), count));
}

std::string PadRight(std::string_view s, size_t width) {
    std::string result(s);
    const size_t current = Width(s);
    if (current < width)
        result.append(width - current, ' ');
    return result;
}

bool StartsWith(std::string_view s, std::string_view prefix) {
    return s.substr(0, prefix.size()) == prefix;
}

bool EqualNoCase(std::string_view a, std::string_view b) {
    return FoldCase(utf8::Decode(a)) == FoldCase(utf8::Decode(b));
}

std::optional<long long> ParseInt(std::string_view s) {
    s = TrimLeft(s);
    if (!s.empty() && s.front() == '+')
        s.remove_prefix(1);
    long long value = 0;
    const auto [end, error] = std::from_chars(s.data(), s.data() + s.size(), value);
    if (s.empty() || error != std::errc() || end != s.data() + s.size())
        return std::nullopt;
    return value;
}

std::string FormatNumber(long long n, char separator) {
    std::string digits = std::to_string(n < 0 ? -n : n);
    if (separator)
        for (size_t i = digits.size(); i > 3; i -= 3)
            digits.insert(i - 3, 1, separator);
    return n < 0 ? "-" + digits : digits;
}

} // namespace text
