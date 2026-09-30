// html.cpp -- HTMTRANS.PAS (Htm2Txt).
//
// Разбор -- авторский, со всеми его особенностями: теги узнаются только в
// том написании, что ниже («<BR>», но не «<BR/>»), параметры тегов -- в
// верхнем регистре (так и попадают в текст имена картинок и адреса ссылок),
// длинные мнемоники вроде &brvbar; узнаются по первым семи знакам.

#include "convert/html.h"

#include "platform/system.h"
#include "text/encoding.h"
#include "text/utf8.h"

#include <algorithm>
#include <fstream>
#include <iterator>
#include <string_view>
#include <vector>

namespace convert {

namespace {

constexpr size_t kWidth = 72;
constexpr size_t kTab = 5;

using Text = std::u32string; // символы, а у страниц не в UTF-8 -- байты

class Converter {
public:
    Converter(bool utf8, bool keep_links, std::ofstream& out)
        : utf8_(utf8), keep_links_(keep_links), out_(out) {}

    void Run(const Text& page);

private:
    bool utf8_;
    bool keep_links_;
    std::ofstream& out_;
    std::vector<Text> links_;

    // Литерал программы -- символами или, у страниц не в UTF-8, байтами
    // DOS-866, как у автора.
    Text Literal(std::u32string_view s) const {
        if (utf8_)
            return Text(s);
        Text bytes;
        for (char32_t c : s)
            bytes += static_cast<char32_t>(text::FromUnicode(text::Encoding::Dos866, c));
        return bytes;
    }

    void Write(const Text& line) {
        out_ << (utf8_ ? utf8::Encode(line) : Bytes(line)) << sys::kEol;
    }

    static std::string Bytes(const Text& line) {
        std::string bytes;
        for (char32_t c : line)
            bytes += static_cast<char>(c);
        return bytes;
    }

    void Save(Text s);
};

bool IsBlank(const Text& s) {
    return s.find_first_not_of(U' ') == Text::npos;
}

char32_t Last(const Text& s) {
    return s.empty() ? 0 : s.back();
}

Text Trim(const Text& s) {
    const size_t first = s.find_first_not_of(U' ');
    if (first == Text::npos)
        return {};
    return s.substr(first, s.find_last_not_of(U' ') - first + 1);
}

Text Spaces(long n) {
    return Text(n > 0 ? static_cast<size_t>(n) : 0, U' ');
}

char32_t Upper(char32_t c) {
    return c >= U'a' && c <= U'z' ? c - 0x20 : c;
}

// Мнемоники и числовые ссылки -- в символы, строка -- в файл.
void Converter::Save(Text s) {
    struct Entity {
        std::u32string_view name;
        std::u32string_view text;
    };
    static const Entity entities[] = {
        {U"&nbsp;", U" "},   {U"&lt;", U"<"},      {U"&gt;", U">"},      {U"&laquo;", U"\""},
        {U"&raquo;", U"\""}, {U"&amp;", U"&"},     {U"&brvbar;", U"|"},  {U"&cdots;", U"..."},
        {U"&copy;", U"(c)"}, {U"&deg;", U"град."}, {U"&emsp;", U" "},    {U"&endash;", U"-"},
        {U"&ensp;", U" "},   {U"&frac12;", U"1/2"}, {U"&frac14;", U"1/4"}, {U"&frac34;", U"3/4"},
        {U"&iexcl;", U"!"},  {U"&iquest;", U"?"},  {U"&ldots;", U"..."}, {U"&mdash;", U"-"},
        {U"&middot;", U"."}, {U"&ndash;", U"-"},   {U"&para;", U"\x15"}, {U"&plusmn;", U"+/-"},
        {U"&quot;", U"\""},  {U"&quadsp;", U"    "}, {U"&reg;", U"(R)"},  {U"&sect;", U"(s)"},
        {U"&shy;", U"-"},    {U"&sp;", U" "},      {U"&sup1;", U"^1"},   {U"&sup2;", U"^2"},
        {U"&sup3;", U"^3"},  {U"&thinsp;", U" "},  {U"&times;", U" x "}, {U"&trade;", U"TM"},
        {U"&vdots;", U"|"},  {U"&hellip;", U"..."},
    };
    for (const Entity& e : entities) {
        const std::u32string_view name = e.name.substr(0, 7); // string[7] у автора
        const Text replacement = Literal(e.text);
        for (size_t at; (at = s.find(name)) != Text::npos;)
            s.replace(at, name.size(), replacement);
    }
    // &#число; -- символ с этим кодом (у страниц не в UTF-8 -- байт).
    const char32_t max_code = utf8_ ? 0x10FFFF : 0xFF;
    for (size_t at; (at = s.find(U"&#")) != Text::npos && s.find(U';') != Text::npos;) {
        const size_t end = s.find(U';', at + 1);
        if (end == Text::npos)
            break;
        char32_t code = 0;
        bool valid = end > at + 2;
        for (size_t i = at + 2; i < end && valid; i++) {
            valid = s[i] >= U'0' && s[i] <= U'9' && code <= max_code;
            code = code * 10 + (s[i] - U'0');
        }
        if (!valid || code > max_code)
            break;
        s.replace(at, end - at + 1, 1, code);
    }
    Write(s);
}

void Converter::Run(const Text& page) {
    Text s, tag, param, link;
    long ol = -1;
    bool pre = false, select = false, tag_opened = false;
    for (size_t i = 0; i < page.size(); i++) {
        const char32_t c = page[i];
        const bool newline = (c == U'\r' && i + 1 < page.size() && page[i + 1] == U'\n') || c == U'\n';
        if (newline && Last(s) != U' ' && !IsBlank(s) && !select && !pre)
            s += U' ';
        if (newline) {
            if (pre) {
                Save(s);
                s.clear();
            }
            continue;
        }
        if (c == U'<') {
            tag_opened = true;
            tag.clear();
            param.clear();
            continue;
        }
        if (c == U'>' && tag_opened) {
            tag_opened = false;
            // Текст в кавычках параметра: адрес картинки или ссылки.
            auto quoted = [&](Text& out) {
                size_t open = param.find(U'\'');
                if (open == Text::npos || param.find(U'\'', open + 1) == Text::npos)
                    open = param.find(U'"');
                if (open == Text::npos)
                    return false;
                const size_t close = param.find(param[open], open + 1);
                out = param.substr(open + 1, close == Text::npos ? Text::npos : close - open - 1);
                return true;
            };
            if (tag == U"PRE") {
                Save(s);
                pre = true;
            }
            if (tag == U"/PRE") {
                Save(s);
                pre = false;
            }
            if (tag == U"IMG " && Trim(param).substr(0, 3) == U"SRC") {
                if (!quoted(link))
                    link.clear();
                const size_t slash = link.rfind(U'/');
                s += slash == Text::npos ? link : link.substr(slash + 1);
            }
            if (tag == U"A " && keep_links_ && Trim(param).substr(0, 4) == U"HREF") {
                if (!quoted(link))
                    continue;
                links_.push_back(link);
                s += U'[' + utf8::Decode(std::to_string(links_.size())) + U' ';
            }
            if (tag == U"/A" && !IsBlank(link) && keep_links_) {
                s += U']';
                link.clear();
            }
            if (tag.substr(0, 7) == U"SELECT ") {
                select = true;
                s += U" [";
            }
            if (tag == U"/SELECT") {
                select = false;
                s += U']';
                Write(s);
                s.clear();
            }
            if (tag.substr(0, 7) == U"OPTION ") {
                const Text trimmed = s.substr(0, s.find_last_not_of(U' ') + 1);
                if (Last(trimmed) != U'[')
                    s += U", ";
            }
            if (tag.substr(0, 3) == U"HR ") {
                if (!IsBlank(s))
                    Save(s);
                Save(Spaces(3) + Text(kWidth - 6, U'_'));
                s.clear();
            }
            if (tag == U"OL")
                ol = 0;
            if (tag == U"/OL")
                ol = -1;
            if (tag == U"LI" && ol > -1) {
                ol++;
                Save(s);
                s = utf8::Decode(std::to_string(ol)) + U".  ";
            }
            if (tag == U"/P" && !IsBlank(s)) {
                Save(s);
                s.clear();
            }
            if (tag == U"P") {
                if (!IsBlank(s))
                    Save(s);
                s = Spaces(kTab);
            }
            if (tag == U"TITLE")
                Write({});
            if (tag == U"/TITLE") {
                const Text title = Trim(s);
                Save(Spaces((static_cast<long>(kWidth) - static_cast<long>(title.size())) / 2) + title);
                Write({});
                Write({});
                s.clear();
            }
            if (tag == U"BR") {
                Save(s);
                s.clear();
            }
            if (tag == U"DD") {
                if (!IsBlank(s))
                    Save(s);
                s = Spaces(kTab);
            }
            continue;
        }
        if (tag_opened && Last(tag) != U' ')
            tag += Upper(c);
        if (tag_opened && Last(tag) == U' ')
            param += Upper(c);
        if (!tag_opened && (c != U' ' || (Last(s) != U' ' && !s.empty())) && !pre)
            s += c;
        if (pre && !tag_opened)
            s += c;
        if (s.size() > kWidth && !pre) {
            // перенос по последнему пробелу
            const size_t space = s.rfind(U' ');
            Text rest = space == Text::npos ? Text() : s.substr(space);
            if (space != Text::npos)
                s.erase(space);
            if (tag == U"TITLE")
                s = Spaces((static_cast<long>(kWidth) - static_cast<long>(s.size())) / 2) + s;
            Save(s);
            s = rest.substr(std::min(rest.find_first_not_of(U' '), rest.size()));
        }
    }
    if (!IsBlank(s))
        Save(s);
    if (keep_links_ && !links_.empty()) {
        Save({});
        for (size_t n = 1; n <= links_.size(); n++) {
            const Text number = utf8::Decode(std::to_string(n));
            Save(number + U'.' + Spaces(4 - static_cast<long>(number.size())) + links_[n - 1]);
        }
    }
}

} // namespace

bool HtmlToText(const std::string& from, const std::string& to, bool keep_links) {
    std::ifstream in(sys::Path(from), std::ios::binary);
    if (!in)
        return false;
    const std::string bytes((std::istreambuf_iterator<char>(in)), {});
    std::ofstream out(sys::Path(to), std::ios::binary | std::ios::trunc);
    if (!out)
        return false;
    const bool utf8 = utf8::IsValid(bytes);
    Text page;
    if (utf8)
        page = utf8::Decode(bytes);
    else
        for (char b : bytes)
            page += static_cast<unsigned char>(b);
    Converter(utf8, keep_links, out).Run(page);
    return static_cast<bool>(out);
}

} // namespace convert
