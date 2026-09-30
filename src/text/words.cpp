// words.cpp -- LINE.WordLoc и E_U.Interval_Loc.

#include "text/words.h"

#include <string>

namespace text {

namespace {

// Разделители слов (RazdLim у INTER.PAS и LINE.PAS).
bool IsSeparator(char32_t c) {
    return std::u32string_view(U"\" .,;!?/\\|{}[]():@=*").find(c) != std::u32string_view::npos ||
           c == 0;
}

} // namespace

WordBounds FindWord(std::u32string_view line, int position, WordStep step) {
    const std::u32string text = std::u32string(line) + U' ';
    const int length = static_cast<int>(text.size());
    auto at = [&](int i) { return i >= 1 && i <= length ? text[i - 1] : char32_t(0); };
    const bool left = step == WordStep::Previous;
    if ((position > length && !left) || position < 1)
        return {};
    // начало последнего слова не правее позиции
    int start = 0;
    bool separator = true;
    for (int i = 1; i <= position && i <= length + 1; i++) {
        const bool now = IsSeparator(at(i));
        if (separator && !now)
            start = i;
        separator = now;
    }
    if (left && !separator) { // внутри слова -- к предыдущему
        int i = start - 1;
        while (i > 0 && IsSeparator(at(i)))
            i--;
        while (i > 0 && !IsSeparator(at(i)))
            i--;
        if (!IsSeparator(at(i + 1)) && i < start - 1)
            start = i + 1;
    } else if (!left) { // к следующему
        int i = start;
        while (i < length && !IsSeparator(at(i)))
            i++;
        while (i < length && IsSeparator(at(i)))
            i++;
        if (!IsSeparator(at(i)) && i > start)
            start = i;
    }
    if (start == 0)
        return {};
    int end = start;
    while (end <= length && !IsSeparator(at(end)))
        end++;
    return {start, end};
}

WordBounds FindInterval(std::u32string_view line, int position) {
    const int length = static_cast<int>(line.size());
    auto at = [&](int i) { return i >= 1 && i <= length ? line[i - 1] : char32_t(0); };
    if (line.find_first_not_of(U' ') == std::u32string_view::npos)
        return {};
    int c = position == 0 || position > length ? 1 : position;
    if (at(c) != U' ') { // к пробелу за словом
        while (c < length && at(c) != U' ')
            c++;
        if (at(c) != U' ')
            return {};
    }
    // к началу следующего слова
    while (c < length && at(c) == U' ')
        c++;
    if (at(c) == U' ')
        return {};
    int left = c;
    while (left > 1 && at(left) != U' ')
        left--;
    if (at(left) == U' ')
        left++;
    int right = c;
    while (right < length && at(right) != U' ')
        right++;
    if (at(right) == U' ')
        right--;
    return {left, right};
}

} // namespace text
