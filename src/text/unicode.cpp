// unicode.cpp -- регистр букв.

#include "text/unicode.h"

#include "text/utf8.h"

namespace text {

namespace {

// Блоки, где заглавная и строчная идут парой: чётная -- заглавная.
bool InPairedBlock(char32_t cp) {
    return (cp >= 0x0100 && cp <= 0x012F) || (cp >= 0x0132 && cp <= 0x0137) ||
           (cp >= 0x014A && cp <= 0x0177) || (cp >= 0x0460 && cp <= 0x0481) ||
           (cp >= 0x048A && cp <= 0x04BF) || (cp >= 0x04D0 && cp <= 0x052F);
}

// Там же, где пары начинаются с нечётной.
bool InOddPairedBlock(char32_t cp) {
    return (cp >= 0x0139 && cp <= 0x0148) || (cp >= 0x0179 && cp <= 0x017E) ||
           (cp >= 0x04C1 && cp <= 0x04CE);
}

} // namespace

char32_t ToUpper(char32_t cp) {
    if (cp < 0x80)
        return cp >= U'a' && cp <= U'z' ? cp - 0x20 : cp;
    if ((cp >= 0xE0 && cp <= 0xFE && cp != 0xF7) || (cp >= 0x0430 && cp <= 0x044F) ||
        (cp >= 0x03B1 && cp <= 0x03C9 && cp != 0x03C2))
        return cp - 0x20;
    if (cp >= 0x0450 && cp <= 0x045F)
        return cp - 0x50;
    if (cp == 0x03C2)
        return 0x03A3;
    if (cp == 0xFF)
        return 0x0178;
    if (InPairedBlock(cp))
        return cp & ~char32_t(1);
    if (InOddPairedBlock(cp))
        return (cp & 1) ? cp : cp - 1;
    switch (cp) {
    case 0x03AC: return 0x0386;
    case 0x03AD: return 0x0388;
    case 0x03AE: return 0x0389;
    case 0x03AF: return 0x038A;
    case 0x03CC: return 0x038C;
    case 0x03CD: return 0x038E;
    case 0x03CE: return 0x038F;
    case 0x017F: return U'S';
    }
    return cp;
}

char32_t ToLower(char32_t cp) {
    if (cp < 0x80)
        return cp >= U'A' && cp <= U'Z' ? cp + 0x20 : cp;
    if ((cp >= 0xC0 && cp <= 0xDE && cp != 0xD7) || (cp >= 0x0410 && cp <= 0x042F) ||
        (cp >= 0x0391 && cp <= 0x03A9 && cp != 0x03A2))
        return cp + 0x20;
    if (cp >= 0x0400 && cp <= 0x040F)
        return cp + 0x50;
    if (cp == 0x0178)
        return 0xFF;
    if (cp == 0x0130)
        return U'i';
    if (InPairedBlock(cp))
        return cp | 1;
    if (InOddPairedBlock(cp))
        return (cp & 1) ? cp + 1 : cp;
    switch (cp) {
    case 0x0386: return 0x03AC;
    case 0x0388: return 0x03AD;
    case 0x0389: return 0x03AE;
    case 0x038A: return 0x03AF;
    case 0x038C: return 0x03CC;
    case 0x038E: return 0x03CD;
    case 0x038F: return 0x03CE;
    }
    return cp;
}

std::string Upper(std::string_view text) {
    std::string result;
    result.reserve(text.size());
    for (size_t pos = 0; pos < text.size();) {
        char32_t cp;
        utf8::Next(text, pos, cp);
        utf8::Append(result, ToUpper(cp));
    }
    return result;
}

std::string Lower(std::string_view text) {
    std::string result;
    result.reserve(text.size());
    for (size_t pos = 0; pos < text.size();) {
        char32_t cp;
        utf8::Next(text, pos, cp);
        utf8::Append(result, ToLower(cp));
    }
    return result;
}

std::u32string Upper(std::u32string_view text) {
    std::u32string result(text);
    for (char32_t& cp : result)
        cp = ToUpper(cp);
    return result;
}

std::u32string FoldCase(std::u32string_view text) {
    std::u32string result(text);
    for (char32_t& cp : result)
        cp = cp == 0x03C2 ? 0x03C3 : ToLower(cp);
    return result;
}

} // namespace text
