// utf8.cpp -- кодек UTF-8.

#include "text/utf8.h"

namespace utf8 {

bool Next(std::string_view s, size_t& pos, char32_t& cp) {
    const auto byte = [&](size_t i) { return static_cast<unsigned char>(s[i]); };
    const unsigned char lead = byte(pos);
    if (lead < 0x80) {
        cp = lead;
        pos++;
        return true;
    }
    size_t length;
    char32_t value;
    if ((lead & 0xE0) == 0xC0) {
        length = 2;
        value = lead & 0x1F;
    } else if ((lead & 0xF0) == 0xE0) {
        length = 3;
        value = lead & 0x0F;
    } else if ((lead & 0xF8) == 0xF0) {
        length = 4;
        value = lead & 0x07;
    } else {
        cp = kReplacement;
        pos++;
        return false;
    }
    if (s.size() - pos < length) {
        cp = kReplacement;
        pos++;
        return false;
    }
    for (size_t i = 1; i < length; i++) {
        if ((byte(pos + i) & 0xC0) != 0x80) {
            cp = kReplacement;
            pos++;
            return false;
        }
        value = (value << 6) | (byte(pos + i) & 0x3F);
    }
    static constexpr char32_t minimum[5] = {0, 0, 0x80, 0x800, 0x10000};
    if (value < minimum[length] || value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF)) {
        cp = kReplacement;
        pos++;
        return false;
    }
    cp = value;
    pos += length;
    return true;
}

void Append(std::string& out, char32_t cp) {
    if (cp > 0x10FFFF || (cp >= 0xD800 && cp <= 0xDFFF))
        cp = kReplacement;
    if (cp < 0x80) {
        out += static_cast<char>(cp);
    } else if (cp < 0x800) {
        out += static_cast<char>(0xC0 | (cp >> 6));
        out += static_cast<char>(0x80 | (cp & 0x3F));
    } else if (cp < 0x10000) {
        out += static_cast<char>(0xE0 | (cp >> 12));
        out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
        out += static_cast<char>(0x80 | (cp & 0x3F));
    } else {
        out += static_cast<char>(0xF0 | (cp >> 18));
        out += static_cast<char>(0x80 | ((cp >> 12) & 0x3F));
        out += static_cast<char>(0x80 | ((cp >> 6) & 0x3F));
        out += static_cast<char>(0x80 | (cp & 0x3F));
    }
}

std::string Encode(char32_t cp) {
    std::string out;
    Append(out, cp);
    return out;
}

std::string Encode(std::u32string_view text) {
    std::string out;
    out.reserve(text.size());
    for (char32_t cp : text)
        Append(out, cp);
    return out;
}

std::u32string Decode(std::string_view text) {
    std::u32string out;
    out.reserve(text.size());
    for (size_t pos = 0; pos < text.size();) {
        char32_t cp;
        Next(text, pos, cp);
        out += cp;
    }
    return out;
}

bool IsValid(std::string_view text) {
    for (size_t pos = 0; pos < text.size();) {
        char32_t cp;
        if (!Next(text, pos, cp))
            return false;
    }
    return true;
}

size_t Length(std::string_view text) {
    size_t count = 0;
    for (size_t pos = 0; pos < text.size(); count++) {
        char32_t cp;
        Next(text, pos, cp);
    }
    return count;
}

std::string_view Left(std::string_view text, size_t count) {
    size_t pos = 0;
    for (; count > 0 && pos < text.size(); count--) {
        char32_t cp;
        Next(text, pos, cp);
    }
    return text.substr(0, pos);
}

std::string_view Skip(std::string_view text, size_t count) {
    return text.substr(Left(text, count).size());
}

bool Validator::Feed(std::string_view block) {
    if (invalid_)
        return false;
    for (char c : block) {
        const auto b = static_cast<unsigned char>(c);
        if (used_ == 0) {
            if (b < 0x80)
                continue;
            if (b >= 0xC2 && b <= 0xDF)
                expected_ = 2;
            else if (b >= 0xE0 && b <= 0xEF)
                expected_ = 3;
            else if (b >= 0xF0 && b <= 0xF4)
                expected_ = 4;
            else
                return !(invalid_ = true);
            pending_[used_++] = c;
            continue;
        }
        if ((b & 0xC0) != 0x80)
            return !(invalid_ = true);
        pending_[used_++] = c;
        if (used_ == expected_) {
            size_t pos = 0;
            char32_t cp;
            if (!Next(std::string_view(pending_.data(), used_), pos, cp))
                return !(invalid_ = true);
            multibyte_ = true;
            used_ = 0;
        }
    }
    return true;
}

} // namespace utf8
