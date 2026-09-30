// numerals.cpp -- SAYFORM.PAS: SayOrdNum, SayRight, SayRightByteSize,
// SayTime, SayDate.
//
// Алгоритм -- авторский, с его позициями «с единицы»: окончания здесь
// подбираются правкой отдельных букв готовой строки. Число в программе
// всегда целое, поэтому ветви автора для дробей не перенесены.

#include "speech/numerals.h"

#include "speech/normalizer.h"
#include "text/unicode.h"
#include "text/utf8.h"

#include <chrono>
#include <cstdio>
#include <ctime>
#include <string>

namespace speech {

namespace {

// Строка с доступом «как у Паскаля»: позиции с единицы, за концом -- 0.
struct PStr {
    std::u32string s;

    PStr() = default;
    PStr(std::u32string text) : s(std::move(text)) {}
    PStr(const char32_t* text) : s(text) {}

    int Len() const { return static_cast<int>(s.size()); }
    char32_t operator[](int i) const { return i >= 1 && i <= Len() ? s[i - 1] : 0; }
    void Set(int i, char32_t c) {
        if (i >= 1 && i <= Len())
            s[i - 1] = c;
    }
    int Pos(char32_t c) const {
        const size_t found = s.find(c);
        return found == std::u32string::npos ? 0 : static_cast<int>(found) + 1;
    }
    int Pos(std::u32string_view sub) const {
        if (sub.empty())
            return 0;
        const size_t found = s.find(sub);
        return found == std::u32string::npos ? 0 : static_cast<int>(found) + 1;
    }
    // Copy(S, index, count) у Free Pascal.
    PStr Copy(int index, int count) const {
        index = index > 1 ? index - 1 : 0;
        if (count <= 0 || index >= Len())
            return {};
        return s.substr(index, count);
    }
    void Delete(int index, int count) {
        if (index < 1 || index > Len() || count <= 0)
            return;
        s.erase(index - 1, count);
    }
    void Insert(std::u32string_view what, int index) {
        index = index < 1 ? 1 : index > Len() + 1 ? Len() + 1 : index;
        s.insert(index - 1, what);
    }
};

PStr operator+(const PStr& a, const PStr& b) {
    return a.s + b.s;
}
PStr operator+(const PStr& a, char32_t c) {
    return a.s + c;
}
bool operator==(const PStr& a, std::u32string_view b) {
    return std::u32string_view(a.s) == b;
}

bool IsDigit(char32_t c, char32_t from = U'0', char32_t to = U'9') {
    return c >= from && c <= to;
}

// SayStr: произнести по правилам русского текста.
void SayStr(const PStr& text) {
    Pronounce(text.s, Cyrillic::Russian);
}

// strchar: заглавные -- в строчные.
PStr Lower(PStr text) {
    for (char32_t& c : text.s)
        c = text::ToLower(c);
    return text;
}

// PartL: i-я (с нуля) часть строки s, разделённой символом dv.
PStr PartL(PStr s, char32_t dv, int i) {
    s = PStr(std::u32string(1, dv)) + s;
    int j = 1;
    int k = -1;
    while ((s[j] != dv || k != i - 1) && j <= s.Len()) {
        j++;
        if (s[j] == dv)
            k++;
    }
    int l = j + 1;
    while (s[l] != dv && l <= s.Len())
        l++;
    j++;
    return s.Copy(j, l - j);
}

std::u32string Decode(std::string_view utf8) {
    return utf8::Decode(utf8);
}

} // namespace

void SayOrdinal(long long num, std::string_view pattern) {
    PStr cline = Decode(pattern);
    PStr word_line;
    int i = 0;

    auto partl = [&](int ii) {
        return cline.Copy(cline.Pos(char32_t(ii - 1)) + 1,
                          cline.Pos(char32_t(ii)) - cline.Pos(char32_t(ii - 1)) - 1);
    };
    // названия порядковых числительных
    auto case1 = [](char32_t sym) -> PStr {
        switch (sym) {
        case U'1': return U" пе+рв";
        case U'2': return U" втор";
        case U'3': return U" тре+т";
        case U'4': return U" четвё+рт";
        case U'5': return U" пя+т";
        case U'6': return U" шест";
        case U'7': return U" седьм";
        case U'8': return U" восьм";
        case U'9': return U" девят";
        }
        return {};
    };
    auto case10 = [&](char32_t sym) -> PStr {
        switch (sym) {
        case U'1': return U" деся+т";
        case U'2': return U" двадца+т";
        case U'3': return U" тридца+т";
        case U'4': return i < 3 ? U" сороко+в" : U" сорока+";
        case U'7': return U" семидеся+т";
        case U'9': return U" девяно+ст";
        }
        return case1(sym) + PStr(U"идеся+т");
    };
    auto case11 = [&](char32_t sym) -> PStr {
        switch (sym) {
        case U'1': return U" оди+ннадцат";
        case U'2': return U" двена+дцат";
        case U'3': return U" трина+дцат";
        case U'4': return U" четы+рнадцат";
        case U'7': return U" семна+дцат";
        case U'8': return U" восемна+дцат";
        }
        return case1(sym) + PStr(U"на+дцат");
    };
    auto case100 = [&](char32_t sym) -> PStr {
        switch (sym) {
        case U'1': return {};
        case U'2': return U" двух";
        case U'3': return U" трёх";
        case U'4': return U" четырёх";
        case U'7': return U" семи";
        }
        return case1(sym) + U'и';
    };

    // разделители: \ и -; части помечаются кодами 0..4
    for (char32_t& c : cline.s)
        if (c == U'-')
            c = U'\\';
    cline = PStr(U"\\") + cline + PStr(U"\\\\\\\\\\");
    for (int marker = 0; marker <= 4; marker++)
        cline.Set(cline.Pos(U'\\'), char32_t(marker));
    if (partl(2).Len() == 0)
        cline.Insert(U"ый", cline.Pos(char32_t(1)) + 1);

    const PStr numstr = utf8::Decode(std::to_string(num));
    const int len = numstr.Len();
    if (num == 0)
        word_line = U" нулев";
    else {
        i = len;
        while (numstr[i] == U'0')
            i--; // нули в конце
        i = len - i;
        word_line = numstr;
        switch (i) { // первый разряд
        case 0:
            if (numstr[len - 1] == U'1') {
                word_line.Delete(word_line.Len() - 1, 2);
                word_line = word_line + PStr(U"00") + case11(numstr[len]);
            } else {
                word_line.Set(word_line.Len(), U'0');
                word_line = word_line + case1(numstr[len]);
            }
            break;
        case 1:
            word_line.Set(word_line.Len() - 1, U'0');
            word_line = word_line + case10(numstr[len - 1]);
            break;
        case 2:
            word_line.Set(word_line.Len() - 2, U'0');
            word_line = word_line + case100(numstr[len - 2]) + PStr(U"со+т");
            break;
        default: { // большие числа
            const int j = 3 * (i / 3);
            const PStr padded = PStr(U"   ") + numstr;
            const int n = padded.Len();
            word_line = PStr(U"      ") + word_line;
            word_line.Delete(word_line.Len() - j - 2, 3);
            word_line = word_line + PStr(U"000");
            // разряд сотен
            const char32_t hundreds = padded[n - j - 2];
            if (hundreds == U'1')
                word_line = word_line + PStr(U" сто");
            else if (hundreds != U'0' && hundreds != U' ')
                word_line = word_line + case100(hundreds) + PStr(U" сот");
            const char32_t tens = padded[n - j - 1];
            const char32_t units = padded[n - j];
            if (tens == U'1' && units != U'0') // второй десяток
                word_line = word_line + case11(units) + U'и';
            else {
                if (IsDigit(tens, U'1'))
                    word_line = word_line + case10(tens);
                if (IsDigit(tens, U'1', U'3') || IsDigit(tens, U'5'))
                    word_line = word_line + U'и';
                if (IsDigit(units, U'1'))
                    word_line = word_line + case100(units);
                if (units == U'1')
                    word_line = word_line + PStr(U" одна");
            }
            if (i >= 3 && i <= 5)
                word_line = word_line + PStr(U" ты+сячн");
            else if (i >= 6 && i <= 8)
                word_line = word_line + PStr(U" милио+нн");
            else if (i == 9)
                word_line = word_line + PStr(U" миллиа+рдн");
        }
        }
    }
    while (word_line.Len() >= 1 &&
           (word_line[1] == U'-' || word_line[1] == U'0' || word_line[1] == U' '))
        word_line.Delete(1, 1);
    // окончание: вторую часть -- без пробелов (граница цикла -- как у автора)
    {
        const int from = cline.Pos(char32_t(1)), to = cline.Pos(char32_t(2));
        for (int pos = from; pos <= to; pos++)
            if (cline[pos] == U' ')
                cline.Delete(pos, 1);
    }
    const PStr ending = partl(2);
    if (ending == U"ый" && num == 0)
        word_line = word_line + PStr(U"ой");
    if (ending == U"ЫЙ" && num == 0)
        word_line = word_line + PStr(U"ОЙ");
    if (numstr[len - 1] != U'1') {
        switch (numstr[len]) {
        case U'2':
        case U'6':
        case U'7':
        case U'8':
            if (ending == U"ый")
                word_line = word_line + PStr(U"ой");
            else if (ending == U"ЫЙ")
                word_line = word_line + PStr(U"ОЙ");
            else
                word_line = word_line + ending;
            break;
        default:
            if (!(num == 0 && (ending == U"ый" || ending == U"ЫЙ")))
                word_line = word_line + ending;
        }
        if (numstr[len] == U'3') {
            const int n = word_line.Len();
            switch (word_line[n - ending.Len() + 1]) {
            case U'а':
            case U'у': word_line.Set(n - 1, U'ь'); break;
            case U'А':
            case U'У': word_line.Set(n - 1, U'Ь'); break;
            case U'ы': word_line.Set(n - 1, U'и'); break;
            case U'Ы': word_line.Set(n - 1, U'И'); break;
            case U'о':
                word_line.Set(n - ending.Len() + 1, U'ь');
                if (word_line[n] != U'е')
                    word_line.Insert(U"ь", n - 2);
                break;
            case U'О':
                word_line.Set(n - ending.Len() + 1, U'Ь');
                if (word_line[n] != U'Е')
                    word_line.Insert(U"Ь", n - 2);
                break;
            }
        }
    } else
        word_line = word_line + ending;
    switch (word_line[word_line.Len() - 1]) {
    case U'г': word_line.Set(word_line.Len() - 1, U'в'); break;
    case U'Г': word_line.Set(word_line.Len() - 1, U'В'); break;
    }
    if (num < 0)
        word_line = PStr(U" минус ") + word_line;
    if (num == 2) // соединительная гласная
        switch (cline[cline.Pos(char32_t(1)) - 1]) {
        case U'в':
        case U'к':
        case U'с': word_line = PStr(U"о ") + word_line; break;
        case U'В':
        case U'К':
        case U'С': word_line = PStr(U"О ") + word_line; break;
        }
    SayStr(partl(1) + word_line + partl(3));
}

void SayQuantity(long long num, std::string_view pattern) {
    PStr cline = Lower(Decode(pattern));
    for (char32_t& c : cline.s)
        if (c == U'\\')
            c = U'-';
    auto pl = [&](int n) {
        switch (n) {
        case 0: return PartL(PartL(cline, U'-', 0), U'/', 0);
        case 10: return PartL(PartL(cline, U'-', 0), U'/', 1);
        default: return PartL(cline, U'-', n);
        }
    };

    PStr say = num == 0 ? PStr(U" ноль ") : utf8::Decode(std::to_string(num < 0 ? -num : num));
    const char32_t nul = say.Len() == 1 ? U' ' : U'0';
    const auto last = [&] { return say[say.Len()]; };
    // формы: для 0 и 5..9, для 1, для 2..4
    PStr word_line = pl(1) + pl(4);
    if (say[say.Len() - 1] != U'1') {
        if (last() == U'1')
            word_line = pl(1) + pl(2);
        if (IsDigit(last(), U'2', U'4'))
            word_line = pl(1) + pl(3);
        // числительное по роду
        if (cline[1] == U'ж') {
            if (last() == U'1') {
                say.Delete(say.Len(), 1);
                say = say + nul + PStr(U" odnа+ ");
            }
            if (last() == U'2') {
                say.Delete(say.Len(), 1);
                say = say + nul + PStr(U" две ");
            }
        }
        if (cline[1] == U'с' && last() == U'1') {
            say.Delete(say.Len(), 1);
            word_line = pl(1) + pl(2);
            say = say + nul + PStr(U"одно+ ");
        }
    }
    if (num < 0)
        say = PStr(U"minus") + say;
    say = pl(10) + U' ' + say; // предлог
    word_line = word_line + pl(5);
    // ключи: «слово» -- только существительное, «число» -- только число,
    // «мо» -- ничего
    const PStr keys = pl(0);
    if (keys.Pos(U"слово") > 0)
        say = {};
    if (keys.Pos(U"число") == 0)
        say = say + U' ' + word_line + U' ';
    if (keys.Pos(U"мо") == 0)
        SayStr(say);
}

void SayByteSize(long long bytes) {
    constexpr long long kKilo = 0x400;
    constexpr long long kMega = 1012000; // так у автора
    constexpr long long kGiga = kMega * 1000;
    const char* name;
    long long unit;
    if (bytes < kKilo) {
        name = "Байт";
        unit = 1;
    } else if (bytes < kMega) {
        name = "Килобайт";
        unit = kKilo;
    } else if (bytes < kGiga) {
        name = "Мегобайт";
        unit = kMega;
    } else {
        name = "Гигабайт";
        unit = kGiga;
    }
    if (bytes % unit == 0) // ровное число -- как количество целых
        SayQuantity(bytes / unit, std::string("м \\") + name + "\\\\а\\ов\\.");
    else {
        char number[32];
        std::snprintf(number, sizeof number, "%.2f", static_cast<double>(bytes) / unit);
        SayStr(Decode(std::string(number) + " " + name + "а."));
    }
}

namespace {

std::tm Now() {
    const std::time_t now = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &now);
#else
    localtime_r(&now, &local);
#endif
    return local;
}

const char* MonthName(int month) {
    static const char* const names[12] = {"Января+",  "Февраля+", "Ма+рта",    "Апре+ля",
                                          "Ма+я",     "Ию+ня",    "Ию+ля",     "А+вгуста",
                                          "Сентября+", "Октября+", "Ноября+", "Декабря+"};
    return month >= 1 && month <= 12 ? names[month - 1] : "";
}

} // namespace

void SayTime() {
    const std::tm now = Now();
    SayStr(U" Сейча+с ");
    SayQuantity(now.tm_hour, "м \\час\\\\а+\\о+в");
    if (now.tm_min == 0)
        SayStr(U"Ро+вно");
    else
        SayQuantity(now.tm_min, "ж \\мину+т\\а\\ы\\\\.");
}

void SayDate() {
    static const char32_t* const weekdays[7] = {U"Воскресе+нье", U"Понеде+льник", U"Вто+рник",
                                                U"среда+",       U"Четве+рг",     U"Пя+тница",
                                                U"Суббо+та"};
    const std::tm now = Now();
    SayStr(U"Сево+дня");
    SayStr(weekdays[now.tm_wday]);
    SayOrdinal(now.tm_mday, std::string("\\ое\\") + MonthName(now.tm_mon + 1));
    int year = now.tm_year + 1900;
    if (year < 2000)
        year -= 1900;
    SayOrdinal(year, "\\ого\\ го+да.");
}

} // namespace speech
