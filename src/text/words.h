// words.h -- поиск слова в строке для перемещения по словам (LINE.WordLoc,
// E_U.Interval_Loc). Позиции -- с единицы; 0 -- слова нет.

#ifndef SV_TEXT_WORDS_H
#define SV_TEXT_WORDS_H

#include <string_view>

namespace text {

// Направление поиска слова.
enum class WordStep {
    Previous, // Ctrl+Left
    Next,     // Ctrl+Right
};

struct WordBounds {
    int left = 0;
    int right = 0;
    explicit operator bool() const { return left != 0 && right != 0; }
};

// Слово слева или справа от позиции position. Слова разделяются пробелами
// и знаками препинания.
WordBounds FindWord(std::u32string_view line, int position, WordStep step);
// То же, но слова разделяются только пробелами («промежутками»); только
// вправо.
WordBounds FindInterval(std::u32string_view line, int position);

} // namespace text

#endif
