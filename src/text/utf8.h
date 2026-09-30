// utf8.h -- UTF-8: разбор, сборка, длина в символах.
//
// Текст внутри программы -- UTF-8 в std::string. Там, где работа идёт по
// символам (экран, строка ввода, подготовка текста к речи), строка
// раскладывается в std::u32string; «символ» везде -- кодовая точка Unicode.
// Ошибочные байты при разборе становятся U+FFFD.

#ifndef SV_TEXT_UTF8_H
#define SV_TEXT_UTF8_H

#include <array>
#include <cstddef>
#include <string>
#include <string_view>

namespace utf8 {

constexpr char32_t kReplacement = U'�';

// Символ, начинающийся в s[pos]; pos сдвигается за него. false -- здесь не
// UTF-8: cp = U+FFFD, pos сдвинут на один байт.
bool Next(std::string_view s, size_t& pos, char32_t& cp);

void Append(std::string& out, char32_t cp);
std::string Encode(char32_t cp);
std::string Encode(std::u32string_view text);
std::u32string Decode(std::string_view text);

bool IsValid(std::string_view text);
// Число символов.
size_t Length(std::string_view text);
// Первые count символов и всё после них.
std::string_view Left(std::string_view text, size_t count);
std::string_view Skip(std::string_view text, size_t count);

// Проверка по частям: символ может пересечь границу блока чтения.
class Validator {
public:
    bool Feed(std::string_view block);
    // Весь текст -- правильный UTF-8 (без оборванного символа в конце).
    bool Valid() const { return !invalid_ && used_ == 0; }
    // Встречался ли хоть один многобайтовый символ.
    bool HasMultibyte() const { return multibyte_; }

private:
    std::array<char, 4> pending_{};
    int used_ = 0;
    int expected_ = 0;
    bool invalid_ = false;
    bool multibyte_ = false;
};

} // namespace utf8

#endif
