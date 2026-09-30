// word97.cpp -- WORDCONV.PAS (Trans_w97_txt, Word97_UnicharDecode).

#include "convert/word97.h"

#include "platform/system.h"
#include "text/encoding.h"
#include "text/utf8.h"

#include <cstdint>
#include <fstream>
#include <string_view>

namespace convert {

namespace {

// Как у автора: 07h -- табуляция, коды до FFh -- байты Windows-1251
// («ёлочки» -- прямые кавычки), прочее -- сам символ.
char32_t Decode(char16_t unit) {
    if (unit == 7)
        return U'\t';
    if (unit < 0x20)
        return static_cast<char32_t>(unit);
    if (unit <= 0xFF) {
        if (unit == 0xAB || unit == 0xBB)
            return U'"';
        return text::ToUnicode(text::Encoding::Windows1251, static_cast<unsigned char>(unit));
    }
    return static_cast<char32_t>(unit);
}

} // namespace

bool Word97ToText(const std::string& from, const std::string& to, int width) {
    // Перенос: знак конца фразы в пределах width-16..width+8 или длина width+8.
    constexpr int kMargin = 8;
    constexpr int kBack = 16;
    constexpr std::u32string_view kBreaks = U".,)]};: ";
    std::ifstream in(sys::Path(from), std::ios::binary);
    std::ofstream out(sys::Path(to), std::ios::binary | std::ios::trunc);
    if (!in || !out)
        return false;
    in.seekg(0x600);
    uint8_t count = 0; // byte у автора
    std::string line;
    char pair[2];
    while (in.read(pair, 2)) {
        const char16_t unit = static_cast<unsigned char>(pair[0]) |
                              (static_cast<unsigned char>(pair[1]) << 8);
        if (unit == 0)
            break;
        const char32_t ch = Decode(unit);
        utf8::Append(line, ch);
        if (ch == U'\r') {
            line += '\n';
            count = 0;
        }
        if (width > 0) {
            count++;
            if (kBreaks.find(ch) != std::u32string_view::npos && count > width - kBack &&
                count < width + kMargin) {
                line += "\r\n";
                count = 0;
            }
            if (count == width + kMargin) {
                line += "\r\n";
                count = 0;
            }
        }
        if (line.size() > 0x10000) {
            out << line;
            line.clear();
        }
    }
    out << line;
    return static_cast<bool>(out);
}

} // namespace convert
