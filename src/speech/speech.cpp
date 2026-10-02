// speech.cpp -- SPEECH.PAS.

#include "speech/speech.h"

#include "platform/system.h"
#include "sound/signals.h"
#include "speech/newfon.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "text/utf8.h"

#include <fstream>
#include <vector>

namespace speech {

namespace {

bool talk = true;
bool space_spoken = true;
Cyrillic cyrillic_language = Cyrillic::Russian;
std::string symbols_file;

// Кусками по столько символов текст уходит нормализатору.
constexpr size_t kChunk = 200;

// Псевдографика (у DOS -- символы B0..DF) не произносится.
bool IsPseudoGraphic(char32_t c) {
    return c >= 0x2500 && c <= 0x259F;
}

// Типографские знаки -- к тому, к чему их сводила таблица Win2Dos, чтобы
// текст в любой кодировке звучал одинаково.
char32_t Typography(char32_t c) {
    switch (c) {
    case 0x00A0: return U' ';        // неразрывный пробел
    case U'«': case U'»': case U'“': case U'”': case U'„': return U'"';
    case U'‘': case U'’': case U'‚': case U'‹': case U'›': return U'`';
    case U'–': case U'—': return U'-';
    case U'…': return U'.';
    }
    return c;
}

std::u32string Prepare(std::string_view utf8) {
    std::u32string text;
    text.reserve(utf8.size());
    for (char32_t c : utf8::Decode(utf8))
        if (c != 0xFEFF) // метка порядка байтов
            text += Typography(c);
    return text;
}

// Del_Mid_Space(Trim(s)): крайние пробелы прочь, внутренние повторы -- в один.
std::u32string Squeeze(std::u32string_view s) {
    std::u32string result;
    for (char32_t c : text::Trim(s))
        if (c != U' ' || result.back() != U' ')
            result += c;
    return result;
}

void Speak(std::u32string_view text, Cyrillic cyrillic) {
    // Короче 200 символов -- целиком, иначе по 200 (у автора строка
    // вмещала 255 символов, и частей было две).
    Pronounce(text.substr(0, kChunk), cyrillic);
    if (text.size() >= kChunk)
        for (size_t pos = kChunk; pos <= text.size(); pos += kChunk)
            Pronounce(text.substr(pos, kChunk), cyrillic);
}

// Название символа из speech.sym: строка номер «код в DOS-866».
bool SayFromSymbolsFile(char32_t ch) {
    const int code = text::FromUnicode(text::Encoding::Dos866, ch);
    std::ifstream file(sys::Path(symbols_file), std::ios::binary);
    if (code <= 0 || !file)
        return false;
    std::string line;
    for (int n = 1; n <= code; n++)
        if (!std::getline(file, line))
            return false;
    if (!line.empty() && line.back() == '\r')
        line.pop_back();
    Say(text::LegacyToUtf8(line, text::Encoding::Dos866));
    return true;
}

} // namespace

void Init(const std::string& program_dir) {
    symbols_file = program_dir + "speech.sym";
}

void Shutdown() {
    newfon::Shutdown();
}

void SetTalk(bool on) {
    talk = on;
}

bool Talking() {
    return talk;
}

void SetDictor(int dictor) {
    if (talk)
        newfon::SetVoice(dictor);
}

// У ядра шкалы наоборот: темп 0..150 -- растяжка звука (0 -- быстрее
// всего), accel 3..13 (10 -- нормально, меньше -- быстрее).
void SetSpeed(int speed) {
    if (talk && speed >= 0 && speed <= newfon::kTempoMax)
        newfon::SetTempo(newfon::kTempoMax - speed);
}

void SetAcceleration(int acceleration, int pause) {
    newfon::SetAcceleration(10 - acceleration, pause);
}

void SetCyrillic(Cyrillic cyrillic) {
    cyrillic_language = cyrillic;
}

void SetSpaceSpoken(bool spoken) {
    space_spoken = spoken;
}

void Say(std::string_view message) {
    if (!talk)
        return;
    std::u32string text;
    for (char32_t c : Squeeze(Prepare(message)))
        if (!IsPseudoGraphic(c))
            text += c;
    Speak(text::Trim(std::u32string_view(text)), Cyrillic::Russian);
}

void SayText(std::string_view line) {
    if (!talk)
        return;
    std::u32string text = Prepare(line);
    for (char32_t& c : text)
        if (IsPseudoGraphic(c))
            c = U' ';
    Speak(Squeeze(text), cyrillic_language);
}

void SaySymbol(char32_t ch) {
    if (!talk)
        return;
    ch = Typography(ch);
    if (SayFromSymbolsFile(ch))
        return;
    // Чего синтезатор не скажет -- кодом: у символов DOS -- кодом в 866.
    const int code = text::FromUnicode(text::Encoding::Dos866, ch);
    const bool letter = text::IsUpper(ch) || text::ToUpper(ch) != ch;
    if (IsPseudoGraphic(ch) || (ch >= 1 && ch <= 31) || (code >= 0xF2 && !letter) ||
        (code < 0 && !letter && ch > U'~')) {
        Say("си+мвол " + std::to_string(code > 0 ? code : static_cast<long>(ch)));
        return;
    }
    if (text::IsUpper(ch))
        sound::Play(sound::Signal::Capital);
    const char* name = nullptr;
    switch (ch) {
    case U' ':
        if (space_spoken)
            name = "пб";
        else
            sound::Play(sound::Signal::Space);
        break;
    case U'\\': name = "слэ+ш"; break;
    case U'.': name = "тэ+чк"; break;
    case U',': name = "за+п"; break;
    case U':': name = "дво+"; break;
    case U'"': name = "Кавы+"; break;
    case U'-': name = "тирэ+."; break;
    case U'!': name = "во+скл."; break;
    case U'@': name = "эт."; break;
    case U'#': name = "Но+мер."; break;
    case U'_': name = "по+д."; break;
    case U'+': name = "плю+с."; break;
    case U'=': name = "равно+."; break;
    case U'*': name = "звё+."; break;
    case U'$': name = "до+ллар."; break;
    case U'~': name = "ти+льда."; break;
    case U'?': name = "во+пр."; break;
    case U'/': name = "дро+бь."; break;
    case U'%': name = "проце+нт."; break;
    case U'^': name = "кры+шка."; break;
    case U'&': name = "а+мпер."; break;
    case U'(': name = "ле+ско."; break;
    case U')': name = "пра+ско."; break;
    case U'|': name = "ве+рт."; break;
    case U'\'': name = "а+по."; break;
    case U';': name = "тэчзап."; break;
    case U'`': name = "обрапо."; break;
    case U'>': name = "бо+льше."; break;
    case U'<': name = "ме+ньше."; break;
    case U'б':
    case U'Б': name = "бэ"; break;
    case U'в':
    case U'В': name = "вэ"; break;
    case U'к':
    case U'К': name = "кэ"; break;
    case U'с':
    case U'С': name = "эс"; break;
    case U'[': name = "ле+квас."; break;
    case U']': name = "пра+квас."; break;
    case U'{': name = "ле+фис."; break;
    case U'}': name = "пра+фис."; break;
    default: Say(utf8::Encode(ch)); break;
    }
    if (name)
        Say(name);
}

} // namespace speech
