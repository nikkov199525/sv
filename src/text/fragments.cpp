// fragments.cpp -- пользовательские замены в тексте.

#include "text/fragments.h"

#include "text/encoding.h"
#include "text/unicode.h"
#include "text/utf8.h"

#include <optional>
#include <utility>

namespace text {

namespace {

// Текст между открывающим знаком (первый символ) и последним таким же.
std::u32string Between(std::u32string_view line, char32_t mark) {
    const size_t close = line.rfind(mark);
    return close > 1 ? std::u32string(line.substr(1, close - 1)) : std::u32string();
}

} // namespace

std::vector<FragmentRule> ParseFragmentRules(std::string_view file_bytes) {
    const Encoding encoding = utf8::IsValid(file_bytes) ? Encoding::Utf8 : Encoding::Dos866;
    const std::u32string contents = Decode(file_bytes, encoding);
    std::vector<FragmentRule> rules;
    std::optional<std::u32string> find;
    std::optional<std::u32string> replace;
    bool ignore_case = false;
    for (size_t start = 0; start <= contents.size();) {
        size_t end = contents.find(U'\n', start);
        if (end == std::u32string::npos)
            end = contents.size();
        std::u32string_view line(contents.data() + start, end - start);
        start = end + 1;
        if (!line.empty() && line.back() == U'\r')
            line.remove_suffix(1);
        if (line.substr(0, 2) == U"@#") {
            ignore_case = true;
            find = Between(line.substr(1), U'#');
        } else if (line.substr(0, 1) == U"#") {
            ignore_case = false;
            find = Between(line, U'#');
        } else if (line.substr(0, 1) == U"^") {
            replace = Between(line, U'^');
        }
        if (find && replace) {
            if (!find->empty())
                rules.push_back({std::move(*find), std::move(*replace), ignore_case});
            find.reset();
            replace.reset();
        }
    }
    return rules;
}

std::u32string ApplyFragmentRules(std::u32string line, const std::vector<FragmentRule>& rules) {
    for (const auto& rule : rules) {
        const std::u32string haystack = rule.ignore_case ? FoldCase(line) : line;
        const std::u32string needle = rule.ignore_case ? FoldCase(rule.find) : rule.find;
        std::u32string result;
        size_t start = 0;
        for (size_t found; (found = haystack.find(needle, start)) != std::u32string::npos;
             start = found + needle.size())
            result.append(line, start, found - start).append(rule.replace);
        result.append(line, start, std::u32string::npos);
        line = std::move(result);
    }
    return line;
}

} // namespace text
