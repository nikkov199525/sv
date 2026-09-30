// normalizer.cpp -- SPICK.PAS (U_R_SText) и SNAMKEY1.PAS.
//
// Логика -- авторская, строка за строкой; позиции в предложении, как у
// автора, считаются с единицы. Отличия от исходника -- только там, где он
// зависел от однобайтовой кодировки: украинские буквы узнаются по
// Unicode, латинские буквы с диакритикой читаются как основные.

#include "speech/normalizer.h"

#include "platform/console.h"
#include "speech/newfon.h"
#include "text/unicode.h"

#include <algorithm>
#include <iterator>

namespace speech {

namespace {

Latin latin_language = Latin::English;
bool all_symbols = false;

// Украинские заглавные в роли, которую им отводит транскрипция.
constexpr char32_t kUkrGe = U'Ґ';
constexpr char32_t kUkrYe = U'Є';
constexpr char32_t kUkrI = U'І';
constexpr char32_t kUkrYi = U'Ї';

constexpr char32_t kBlank = U' ';

// Заглавная; табуляция и перевод строки -- пробел (таблица UpCode).
char32_t UC(char32_t c) {
    if (c == U'\t' || c == U'\n' || c == U'\r')
        return kBlank;
    return text::ToUpper(c);
}

bool IsDigit(char32_t c) {
    return c >= U'0' && c <= U'9';
}

bool In(char32_t c, std::u32string_view set) {
    return c != 0 && set.find(c) != std::u32string_view::npos;
}

// Классы букв INTER.PAS -- только заглавные.
bool IsEngLetter(char32_t c) {
    return c >= U'A' && c <= U'Z';
}
bool IsEngVowel(char32_t c) {
    return In(c, U"AEIOUY");
}
bool IsEngConsonant(char32_t c) {
    return IsEngLetter(c) && !IsEngVowel(c);
}
bool IsRusLetter(char32_t c) {
    return (c >= U'А' && c <= U'Я') || In(c, U"ЁҐЄІЇ");
}
bool IsRusVowel(char32_t c) {
    return In(c, U"АЕИОУЫЭЮЯЁЄІЇ");
}
bool IsRusConsonant(char32_t c) {
    return IsRusLetter(c) && !IsRusVowel(c);
}
bool IsLetter(char32_t c) {
    return IsEngLetter(c) || IsRusLetter(c);
}
bool IsVowel(char32_t c) {
    return IsEngVowel(c) || IsRusVowel(c);
}
bool IsConsonant(char32_t c) {
    return IsEngConsonant(c) || IsRusConsonant(c);
}

// Символ, который сейчас не произносится (NoSTextSym).
bool Silenced(char32_t c) {
    if (all_symbols)
        return c == kBlank;
    return c >= 2 && !(IsLetter(UC(c)) || IsDigit(c) || In(c, U"+=#%$"));
}

// Латинская буква с диакритикой -> основная.
char32_t BaseLatin(char32_t c) {
    // 0 -- не буква с диакритикой (×, ÷, Þ, þ).
    static constexpr char32_t latin1[] = U"AAAAAAACEEEEIIII"  // U+00C0
                                         U"DNOOOOO\0OUUUUY\0s" // U+00D0
                                         U"aaaaaaaceeeeiiii"  // U+00E0
                                         U"dnooooo\0ouuuuy\0y"; // U+00F0
    static constexpr char32_t extended[] = U"AaAaAaCcCcCcCcDd"  // U+0100
                                           U"DdEeEeEeEeEeGgGg"  // U+0110
                                           U"GgGgHhHhIiIiIiIi"  // U+0120
                                           U"IiIiJjKkkLlLlLlL"  // U+0130
                                           U"lLlNnNnNnnNnOoOo"  // U+0140
                                           U"OoOoRrRrRrSsSsSs"  // U+0150
                                           U"SsTtTtTtUuUuUuUu"  // U+0160
                                           U"UuUuWwYyYZzZzZzs"; // U+0170
    static_assert(std::size(latin1) == 0x40 + 1 && std::size(extended) == 0x80 + 1);
    char32_t base = 0;
    if (c >= 0xC0 && c <= 0xFF)
        base = latin1[c - 0xC0];
    else if (c >= 0x0100 && c <= 0x017F)
        base = extended[c - 0x0100];
    return base ? base : c;
}

class Sentence {
public:
    explicit Sentence(Cyrillic cyrillic) : ukrainian_(cyrillic == Cyrillic::Ukrainian) {}

    void Run(std::u32string_view source) {
        s0_ = DelSpaces(source);
        nules_ = false;
        // Два пробела в начале и проверка строки с третьей позиции
        // избавляют от множества проверок индексов.
        s0_ = U"  " + s0_ + U"  ";
        if (latin_language == Latin::German)
            InsUmlauts();
        for (char32_t& c : s0_)
            c = BaseLatin(c);
        l_ = static_cast<int>(s0_.size());
        s0_ += kBlank;
        sent_ = kBlank;
        i_ = 3;
        k_ = 1;
        WordFinder();
        while (i_ < l_) {
            // каждый символ -- на фонетический анализ, в sent_ --
            // произносимая строка
            if (IsLetter(UC(At(i_))) && WordTester())
                Abbreviation();
            else
                SentMaker();
            if (sent_.size() > 200) { // чтобы не переполнить строку
                newfon::Speak(sent_);
                sent_ = kBlank;
                if (console::PeekKey())
                    i_ = l_; // не продолжать чтения
            }
        }
        newfon::Speak(sent_);
    }

private:
    const bool ukrainian_;
    std::u32string s0_;
    std::u32string sent_;
    int i_ = 0, k_ = 0, l_ = 0;
    int same_count_ = 0;     // подряд идущих одинаковых символов
    char32_t same_sym_ = 0;
    bool nules_ = false;     // произносить незначащие нули
    bool silence_ = true;    // был непроизносимый символ

    char32_t At(int pos) const {
        return pos >= 1 && pos <= static_cast<int>(s0_.size()) ? s0_[pos - 1] : 0;
    }

    std::u32string CharName(char32_t c) const {
        return SymbolName(c, ukrainian_ ? Cyrillic::Ukrainian : Cyrillic::Russian);
    }

    // Удаление повторов пробелов; украинский апостроф между согласной и
    // йотированной гласной -- твёрдый знак.
    std::u32string DelSpaces(std::u32string_view mm) const {
        std::u32string result;
        bool b = false;
        for (size_t pos = 0; pos < mm.size(); pos++) {
            const char32_t c = mm[pos];
            if (c != kBlank)
                b = true;
            if (b) {
                const char32_t next = pos + 1 < mm.size() ? UC(mm[pos + 1]) : 0;
                if ((c == U'\'' || c == U'`') && ukrainian_ && pos > 0 && pos + 1 < mm.size() &&
                    IsRusConsonant(UC(mm[pos - 1])) && In(next, U"ЯЮЄЇ"))
                    result += U'ъ';
                else
                    result += c;
            }
            if (c == kBlank)
                b = false;
        }
        return result;
    }

    // Умлауты немецкого текста: настоящие и те, что в тексте DOS (кодовая
    // страница 437) читаются как Д, Ф, Б, О, Щ, Ъ, -- рядом с латиницей.
    void InsUmlauts() {
        const std::u32string upper = text::Upper(s0_);
        const size_t aus = upper.find(U" AUS");
        if (aus != std::u32string::npos)
            s0_.insert(aus + 4, 1, kBlank);
        for (int pos = 1; pos <= static_cast<int>(s0_.size()); pos++) {
            char32_t& c = s0_[pos - 1];
            if (!IsEngLetter(UC(At(pos - 1))) && !IsEngLetter(UC(At(pos + 1))))
                continue;
            if (In(c, U"ДОäÄ"))
                c = U'e';
            else if (In(c, U"ФЩöÖ"))
                c = U'ё';
            else if (In(c, U"БЪüÜ"))
                c = U'ю';
        }
    }

    // Длинные последовательности одинаковых символов -- словами.
    void ManySameSymbols() {
        const char32_t c = At(k_ - 1);
        if (same_sym_ != c && !(Silenced(c) || c <= kBlank)) {
            if (sent_.size() < 100) {
                if (same_count_ <= 20)
                    sent_ += U", Не+сколько ";
                else if (same_count_ <= 80)
                    sent_ += U", Многа ";
                else
                    sent_ += U"Очень многа ";
            }
            if (sent_.size() < 175)
                sent_ += U" символов " + CharName(c) + U", ";
            same_sym_ = c;
        }
        i_ = k_;
        same_count_ = 0;
    }

    // Ставит k_ на начало следующей последовательности букв.
    void WordFinder() {
        while (!IsLetter(UC(At(k_))) && k_ <= l_) {
            k_++;
            if (At(k_) == At(k_ - 1) && !IsDigit(At(k_)))
                same_count_++;
            else if (same_count_ > 3) {
                if (i_ < k_ - same_count_)
                    k_ -= same_count_; // сначала обработать участок слева
                else
                    ManySameSymbols();
            } else
                same_count_ = 0;
        }
    }

    // Даёт добро на произнесение слова как аббревиатуры.
    bool WordTester() {
        bool word_begin = true;
        bool no_abbreviation = false; // есть буквы, недопустимые в аббревиатуре
        bool all_capital = true;      // false -- в слове есть строчная буква
        int vowels = 0;
        while (IsLetter(UC(At(k_))) &&
               (!IsLetter(At(k_)) || !IsLetter(UC(At(k_ + 1))) || IsLetter(At(k_ + 1)) ||
                word_begin) &&
               (!IsLetter(At(k_)) || all_capital) && k_ <= l_) {
            if (IsVowel(UC(At(k_))))
                vowels++;
            if (!IsLetter(At(k_)))
                all_capital = false;
            if (In(UC(At(k_)), U"ЫЯЁЬЪЙ"))
                no_abbreviation = true;
            word_begin = false;
            k_++;
        }
        // ударение после русской гласной -- слово слитное
        if ((At(i_ - 1) == U'+' || At(i_ - 1) == U'=') && IsRusLetter(UC(At(i_))) &&
            IsRusVowel(UC(At(i_ - 2))))
            return false;
        if (k_ == i_ + 1) {
            // однобуквенные согласные предлоги и украинское слово с апострофом
            const char32_t u = UC(At(i_));
            const char32_t n = UC(At(k_ + 1));
            if (((At(k_) == kBlank || At(k_) == U'_') && In(u, U"БВКС")) ||
                ((At(k_) == U'\'' || At(k_) == U'`') && In(u, U"БВДКЛМП") && In(n, U"ЇЄЮЯ")))
                return false;
            return true; // прочие одинокие буквы, включая гласные
        }
        if (vowels == 0)
            return true;
        const std::u32string word = s0_.substr(i_ - 1, std::min(k_ - i_, 5));
        if (word == U"USA" || word == U"ОБСЕ")
            return true;
        static constexpr std::u32string_view exceptions[] = {
            U"ГДЕ", U"ДА", U"ДО", U"ЗА", U"ИЗ", U"КТО", U"МНЕ", U"НА", U"НЕ", U"ОН", U"ПО", U"США",
            U"ЧТО"};
        for (std::u32string_view exception : exceptions)
            if (word == exception)
                return false;
        return all_capital && !no_abbreviation &&
               ((vowels == 1 && (IsVowel(At(i_)) || IsVowel(At(k_ - 1)))) || vowels == k_ - i_);
    }

    // Произнесение по буквам.
    void Abbreviation() {
        // украинские однобуквенные слова й, з
        if (ukrainian_ && k_ == i_ + 1 && At(k_) == kBlank && In(UC(At(i_)), U"ЙЗ")) {
            sent_ += At(i_);
            sent_ += At(i_);
            i_++;
        } else {
            sent_ += U'-';
            for (; i_ < k_; i_++)
                sent_ += CharName(At(i_)) + kBlank;
        }
        WordFinder(); // к следующему слову
    }

    void Apostrophe() {
        if (i_ == 1) {
            sent_ += CharName(At(i_)) + U',';
            return;
        }
        const char32_t previous = UC(At(i_ - 1));
        const char32_t next = UC(At(i_ + 1));
        if (IsEngLetter(previous)) {
            if (next != U'S')
                sent_ += U',' + CharName(At(i_)) + U',';
        } else if (In(previous, U"БВДКЛМП") && In(next, U"ЇЄЮЯ"))
            sent_ += U'Ь';
        else
            sent_ += U',' + CharName(At(i_)) + U',';
    }

    // Общее у немецкой и английской транскрипции. true -- обработано.
    bool CommonSymbols(int& number_length) {
        const char32_t c = At(i_);
        const char32_t previous = At(i_ - 1);
        switch (UC(c)) {
        case U'Ж':
            sent_ += IsRusLetter(UC(previous)) ? U"Ж" : U"ЖЖ";
            return true;
        case kUkrGe: sent_ += U'г'; return true;
        case kUkrYe: sent_ += U'е'; return true;
        case kUkrI: sent_ += U'и'; return true;
        case kUkrYi: sent_ += U"йи"; return true;
        case U'Ц':
            sent_ += ukrainian_ ? U"ТС" : U"Ц";
            return true;
        case U'Ё':
        case U'Ы':
        case U'Ъ':
        case U'Э':
            sent_ += c; // включение русского
            return true;
        case U'Ь':
            // У автора «О» бралась и за концом фрагмента: «иьО» зацикливало
            // чтение.
            if (i_ + 1 < k_ && UC(At(i_ + 1)) == U'О') {
                sent_ += U'ё';
                i_++;
            } else
                sent_ += U'Ь';
            return true;
        case U'Е':
            sent_ += ukrainian_ ? U'Э' : U'Е';
            return true;
        case U'И':
            sent_ += ukrainian_ ? U'Ы' : U'И';
            return true;
        case U'\'':
        case U'`': // прямой и обратный апострофы
            Apostrophe();
            return true;
        case U'$':
            sent_ += U" ДОЛЛАР";
            if (previous == U'1')
                sent_ += U", ";
            else if (previous >= U'2' && previous <= U'4')
                sent_ += U"А, ";
            else
                sent_ += ukrainian_ ? U"ИВ," : U"ОВ, ";
            return true;
        case U'%':
            sent_ += ukrainian_ ? U"Видсот" : U" ПРОЦЕНТ";
            if (previous == U'1')
                sent_ += ukrainian_ ? U"ОК," : U", ";
            else if (previous >= U'2' && previous <= U'4')
                sent_ += ukrainian_ ? U"КА," : U"А, ";
            else
                sent_ += ukrainian_ ? U"КИВ," : U"ОВ, ";
            return true;
        case U'^': sent_ += U" ,Крыш, "; return true;
        case U'|': sent_ += U" ,Верт, "; return true;
        case U'+':
            sent_ += IsRusVowel(UC(previous)) ? U"+" : U" Плюс ";
            return true;
        case U'=':
            if (!IsRusVowel(UC(previous)))
                sent_ += U" ,Равно, ";
            return true;
        case U'0': case U'1': case U'2': case U'3': case U'4':
        case U'5': case U'6': case U'7': case U'8': case U'9': {
            const char32_t next = At(i_ + 1);
            if (c == U'0' && next == U'.' && (nules_ || !IsDigit(previous)) && Silenced(U'.'))
                sent_ += U"ноль 0";
            else if (c == U'0' &&
                     (!(IsDigit(previous) || (Silenced(U'.') && (previous == U'.' || next == U'.'))) ||
                      nules_)) {
                sent_ += U" Ноль ";
                nules_ = true;
            } else {
                sent_ += c;
                nules_ = false;
                number_length++;
            }
            if (!(IsDigit(next) || next == U'.'))
                sent_ += U',';
            return true;
        }
        }
        if (In(c, U".!?;,~@#&*_()[]{}<>/\\\"")) {
            sent_ += U" ," + CharName(c) + U", ";
            return true;
        }
        return false;
    }

    // Следующая буква в пределах слова -- заглавная?
    char32_t Next(int offset = 1) const {
        return UC(At(i_ + offset));
    }

    void GermanTranscription(int& number_length) {
        const char32_t previous = UC(At(i_ - 1));
        switch (UC(At(i_))) {
        case U'C':
            if (i_ < k_ - 1 && Next() == U'H') {
                if (previous != U'S')
                    sent_ += U'х';
                i_++;
            } else if (i_ < k_ - 1 &&
                       (Next() == U'E' || Next() == U'I' || (Next() == U'Y' && !IsEngVowel(Next(2)))))
                sent_ += U'Ц';
            else
                sent_ += U'К';
            return;
        case U'E':
            if (i_ < k_ - 1 && Next() == U'I') {
                sent_ += previous == U'L' ? U"яй" : U"ай";
                i_++;
            } else if (i_ < k_ - 1 && Next() == U'U') {
                sent_ += previous == U'L' ? U"ёй" : U"ой";
                i_++;
            } else
                sent_ += previous == U'L' ? U'Е' : U'Э';
            return;
        case U'H':
            if (!IsVowel(previous))
                sent_ += U'Х';
            return;
        case U'I':
            if (i_ < k_ - 1 && Next() == U'E') {
                sent_ += U"ИИ";
                i_++;
            } else
                sent_ += U'И';
            return;
        case U'J': sent_ += U'й'; return;
        case U'L':
            sent_ += (i_ < k_ - 1 && IsEngConsonant(Next())) || i_ == k_ - 1 ? U"ль" : U"л";
            return;
        case U'O': sent_ += U'О'; return;
        case U'P':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U'Ф';
                i_++;
            } else
                sent_ += U'П';
            return;
        case U'Q': sent_ += U'К'; return;
        case U'S':
            if (i_ < k_ - 2 && IsEngConsonant(Next()) && Next() != U'S' && Next() != U'Z')
                sent_ += U'Ш';
            else if (i_ < k_ - 1 && IsVowel(Next()) && previous != U'S')
                sent_ += U'З';
            else
                sent_ += U'С';
            return;
        case U'T':
            if (i_ < k_ - 2 && Next() == U'C' && Next(2) == U'H') {
                sent_ += U'Ч';
                i_ += 2;
            } else
                sent_ += U'Т';
            return;
        case U'U': sent_ += U'У'; return;
        case U'V': sent_ += U'Ф'; return;
        case U'W': sent_ += U'В'; return;
        case U'X':
            sent_ += i_ < k_ - 1 && IsVowel(previous) && IsVowel(Next()) ? U"ГЗ" : U"КС";
            return;
        case U'Y':
            sent_ += IsConsonant(previous) &&
                             (IsConsonant(Next()) || i_ == k_ - 1 || !IsLetter(Next()))
                         ? U'И'
                         : U'Й';
            return;
        case U'Z':
            sent_ += previous != U'S' ? U'Ц' : U'С';
            return;
        }
        if (!CommonSymbols(number_length))
            sent_ += UC(At(i_));
    }

    void EnglishTranscription(int& number_length) {
        const char32_t previous = UC(At(i_ - 1));
        switch (UC(At(i_))) {
        case U'C':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U'Ч';
                i_++;
            } else if (i_ < k_ - 1 &&
                       (Next() == U'E' || Next() == U'I' || (Next() == U'Y' && !IsEngVowel(Next(2)))))
                sent_ += U'Ц';
            else
                sent_ += U'К';
            return;
        case U'E':
            if (i_ < k_ - 1 && Next() == U'W') {
                sent_ += U"ЬЮ";
                i_++;
            } else if (i_ < k_ - 1 && Next() == U'A') {
                sent_ += U'И';
                i_++;
            } else if (i_ < k_ - 1 && Next() == U'E') {
                sent_ += U"ИИ";
                i_++;
            } else
                sent_ += U'Э';
            return;
        case U'H': sent_ += U'Х'; return;
        case U'J': sent_ += U"ДЖ"; return;
        case U'O':
            if (i_ < k_ - 1 && Next() == U'O') {
                sent_ += U"УУ";
                i_++;
            } else
                sent_ += U'О';
            return;
        case U'P':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U'Ф';
                i_++;
            } else
                sent_ += U'П';
            return;
        case U'Q': sent_ += U'К'; return;
        case U'S':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U'Ш';
                i_++;
            } else
                sent_ += U'С';
            return;
        case U'T':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U'З';
                i_++;
            } else
                sent_ += U'T';
            return;
        case U'X':
            sent_ += i_ < k_ - 1 && IsVowel(previous) && IsVowel(Next()) ? U"ГЗ" : U"КС";
            return;
        case U'W': sent_ += U'В'; return;
        case U'Y':
            sent_ += IsConsonant(previous) &&
                             (IsConsonant(Next()) || i_ == k_ - 1 || !IsLetter(Next()))
                         ? U'Ы'
                         : U'Й';
            return;
        case U'Z':
            if (i_ < k_ - 1 && Next() == U'H') {
                sent_ += U"ЖЖ";
                i_++;
            } else
                sent_ += U'З';
            return;
        }
        if (!CommonSymbols(number_length))
            sent_ += UC(At(i_));
    }

    void SentMaker() {
        constexpr int kMaxFragment = 15; // длина числа, которую синтезатор читает верно
        int number_length = 0;
        while (i_ < k_) {
            const char32_t c = At(i_);
            if (!IsDigit(c)) {
                if (number_length > kMaxFragment) {
                    // длинное число -- по частям с псевдоименами классов
                    int name_pos = static_cast<int>(sent_.size()) - kMaxFragment;
                    const int number_begin = static_cast<int>(sent_.size()) - number_length;
                    char32_t class_name = U'A';
                    while (name_pos > number_begin) {
                        sent_.insert(std::min<size_t>(name_pos - 1, sent_.size()),
                                     U',' + CharName(class_name) + U';');
                        name_pos -= 3;
                        class_name = class_name == U'Z' ? U'А' : class_name + 1;
                    }
                }
                number_length = 0;
            }
            // знаки, влияющие на интонацию и при их запрете
            if (In(c, U".?!;,") && !silence_)
                sent_ += c;
            silence_ = Silenced(c);
            if (c == U'.')
                nules_ = false;
            if (c == U'-') {
                if (!Silenced(U'-'))
                    sent_ += CharName(U'-');
            } else if (c == U':') {
                if (At(i_ + 1) == U'=') {
                    sent_ += U" ,Присво+ить, ";
                    i_++;
                } else if (!Silenced(U':'))
                    sent_ += ukrainian_ ? U"Двукр" : U" ,Дво, ";
                else
                    sent_ += U':';
            } else if (Silenced(c))
                sent_ += kBlank; // вместо запрещённого символа
            else if (latin_language == Latin::German)
                GermanTranscription(number_length);
            else
                EnglishTranscription(number_length);
            i_++;
        }
        WordFinder();
    }
};

} // namespace

void SetLatin(Latin latin) {
    latin_language = latin;
}

void SetAllSymbols(bool all) {
    all_symbols = all;
}

void Pronounce(std::u32string_view sentence, Cyrillic cyrillic) {
    Sentence(cyrillic).Run(sentence);
}

std::u32string SymbolName(char32_t m, Cyrillic cyrillic) {
    const bool ukr = cyrillic == Cyrillic::Ukrainian;
    if (latin_language == Latin::German) { // немецкие названия букв
        switch (m) {
        case U'"': return ukr ? U"Лапкы+" : U"Кавы";
        case U'-': return ukr ? U"дэфис" : U"дефис";
        case U'I': case U'i': return U"и";
        case U'J': case U'j': return U"йот";
        case U'Q': case U'q': return U"Ку";
        case U'V': case U'v': return U"фау";
        case U'X': case U'x': return U"икс";
        case U'Y': case U'y': return U"игрек";
        case U'A': case U'a': case U'А': case U'а': return U"А";
        case U'B': case U'b': case U'Б': case U'б': return U"Бэ";
        case U'W': case U'w': case U'В': case U'в': return U"Вэ";
        case U'G': case U'g': case U'Г': case U'г': return U"Гэ";
        case U'D': case U'd': case U'Д': case U'д': return U"Дэ";
        case U'K': case U'k': case U'К': case U'к': return U"Ка";
        case U'L': case U'l': case U'Л': case U'л': return U"Эль";
        case U'O': case U'o': case U'О': case U'о': return U"О";
        case U'P': case U'p': case U'П': case U'п': return U"Пэ";
        case U'R': case U'r': case U'Р': case U'р': return U"Эр";
        case U'T': case U't': case U'Т': case U'т': return U"Тэ";
        case U'U': case U'u': case U'У': case U'у': return U"У";
        case U'H': case U'h': case U'Х': case U'х': return U"Ха";
        case U'C': case U'c': case U'Ц': case U'ц': return U"Цэ";
        case U'E': case U'e': case U'Э': case U'э': return U"э";
        }
    } else { // английские названия букв
        switch (m) {
        case U'"': return ukr ? U"Ла+пкы+" : U"Кавы";
        case U'-': return ukr ? U"Мынус" : U"Ми+нус";
        case U'A': case U'a': return U"Эй";
        case U'B': case U'b': return U"Би";
        case U'C': case U'c': return U"Си";
        case U'D': case U'd': return U"Ди";
        case U'E': case U'e': return U"И";
        case U'G': case U'g': return U"Джи";
        case U'H': case U'h': return U"Эйч";
        case U'I': case U'i': return ukr ? U"и+" : U"ай";
        case U'J': case U'j': return U"Джэй";
        case U'K': case U'k': return U"Кэй";
        case U'L': case U'l': return U"Эл";
        case U'O': case U'o': return U"Оу";
        case U'P': case U'p': return U"Пи";
        case U'Q': case U'q': return U"Къю";
        case U'R': case U'r': return U"Ар";
        case U'T': case U't': return U"Ти";
        case U'U': case U'u': return U"Ю";
        case U'V': case U'v': return U"Ви";
        case U'W': case U'w': return U"Дабъйу";
        case U'X': case U'x': return U"Экс";
        case U'Y': case U'y': return U"Вай";
        case U'А': case U'а': return U"А";
        case U'Б': case U'б': return U"Бэ";
        case U'В': case U'в': return U"Вэ";
        case U'Г': case U'г': return U"Гэ";
        case U'Д': case U'д': return U"Дэ";
        case U'К': case U'к': return U"Ка";
        case U'Л': case U'л': return U"Эль";
        case U'О': case U'о': return U"О";
        case U'П': case U'п': return U"Пэ";
        case U'Р': case U'р': return U"Эр";
        case U'Т': case U'т': return U"Тэ";
        case U'У': case U'у': return U"У";
        case U'Х': case U'х': return U"Ха";
        case U'Ц': case U'ц': return U"Цэ";
        case U'Э': case U'э': return U"э";
        }
    }
    // Общее для обеих таблиц: служебные символы, цифры, прочие буквы.
    switch (m) {
    case 27: return U"Эск";
    case 8: return U"Заб";
    case 13: return ukr ? U"Ввид" : U"Вво+д";
    case U' ': return U"ПР";
    case U'!': return ukr ? U"Оклык" : U"Воскл";
    case U'#': return ukr ? U"номэр" : U"Номер";
    case U'$': return U"Доллар";
    case U'%': return ukr ? U"Видсоток" : U"Процент";
    case U'&': return U"Ампэрсэнд";
    case U'\'': return U" ,Апо, ";
    case U'(': return ukr ? U"ЛиДуж" : U"Леско";
    case U')': return ukr ? U"ПраДуж" : U"Праско";
    case U'*': return ukr ? U"Зирка" : U"Звё";
    case U'+': return U"Плю+с";
    case U',': return ukr ? U"Кома" : U"Зап";
    case U'.': return ukr ? U"крапка" : U"Тэчк";
    case U'/': return ukr ? U"дриб" : U"дробь";
    case U'0': return ukr ? U"Нуль" : U"0";
    case U'1': return ukr ? U"одын" : U"1";
    case U'2': return U"2";
    case U'3': return ukr ? U"тры" : U"3";
    case U'4': return ukr ? U"чотыры" : U"4";
    case U'5': return ukr ? U"Пъять" : U"5";
    case U'6': return ukr ? U"шисть" : U"6";
    case U'7': return ukr ? U"Симь" : U"7";
    case U'8': return ukr ? U"Висимь" : U"8";
    case U'9': return ukr ? U"дэвъять" : U"9";
    case U':': return ukr ? U"двукрапка" : U"Двоеточ";
    case U';': return ukr ? U"КрапКома" : U"Тэч зап";
    case U'<': return ukr ? U"Мэншэ" : U"Ме+ньше";
    case U'=': return ukr ? U"Доривнюе" : U"Равно";
    case U'>': return ukr ? U"Бильшэ" : U"Бо+льше";
    case U'?': return ukr ? U"запыт" : U"Вопр";
    case U'@': return U"Эт";
    case U'[': return ukr ? U"ЛиКваД" : U"Леквас";
    case U']': return ukr ? U"ПраКваД" : U"Праквас";
    case U'\\': return U"БэкСлэ+ш";
    case U'^': return U"Кры+шка";
    case U'_': return U"По+д";
    case U'`': return ukr ? U"Звор Апо" : U"Обр апо";
    case U'{': return ukr ? U"ЛиФиД" : U"Лефис";
    case U'}': return ukr ? U"ПраФиД" : U"Прафис";
    case U'|': return ukr ? U"Вэртыкаль" : U"Вертикаль";
    case U'~': return U"Ти+льда";
    case U'F': case U'f': return U"Эф";
    case U'M': case U'm': return U"эм";
    case U'N': case U'n': return U"Эн";
    case U'S': case U's': return U"Эс";
    case U'Z': case U'z': return U"Зэт";
    case U'Е': case U'е': return U"Е";
    case U'Ж': case U'ж': return U"Жжэ";
    case U'З': case U'з': return U"Зэ";
    case U'И': case U'и': return U"И";
    case U'Й': case U'й': return U"И+ЙЙ";
    case U'М': case U'м': return U"Эмм";
    case U'Н': case U'н': return U"Эн";
    case U'С': case U'с': return U"Эс";
    case U'Ф': case U'ф': return U"Эф";
    case U'Ч': case U'ч': return U"Чэ";
    case U'Ш': case U'ш': return U"Ша";
    case U'Щ': case U'щ': return U"Ща";
    case U'Ъ': case U'ъ': return U"твЁ";
    case U'Ы': case U'ы': return U"ы";
    case U'Ь': case U'ь': return U"мя";
    case U'Ю': case U'ю': return U"йю";
    case U'Я': case U'я': return U"йя";
    case U'Ё': case U'ё': return U"Ё";
    case kUkrGe: case U'ґ': return U"ТВЭРДЭ+ гэ+";
    case kUkrYe: case U'є': return U"йэ";
    case kUkrI: case U'і': return U"и";
    case kUkrYi: case U'ї': return U"ЙЙИИ";
    }
    return U"                              .";
}

} // namespace speech
