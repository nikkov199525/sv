// newfon.cpp -- NEWFON.PAS и Win32-бэкенд SDRVPRIM (SDRVXPApi.INC).

#include "speech/newfon.h"

#include "newfon_core.h"
#include "platform/audio.h"
#include "platform/console.h"
#include "platform/system.h"
#include "text/encoding.h"
#include "text/strings.h"
#include "text/unicode.h"

#include <chrono>
#include <fstream>
#include <thread>
#include <vector>

#ifdef SV_SPEECH_TRACE
#include "text/utf8.h"
#include <cstdlib>
#endif

namespace newfon {

namespace {

constexpr int kSampleRate = 10000;

// Диктор SV -> голос ядра (порядок из меню «Настройки»/«Речь»).
constexpr int kVoices[4] = {NEWFON_MALE_1, NEWFON_FEMALE_1, NEWFON_MALE_2, NEWFON_FEMALE_2};

newfon_conf_t config = [] {
    // Ровно те значения, что ставит newfon_config_init: настройки программы
    // (диктор, темп) задаются раньше, чем читается newfon.cfg.
    newfon_conf_t c{};
    c.voice = NEWFON_MALE_1;
    c.speech_rate = NEWFON_RATE_DEFAULT;
    c.acceleration = 10; // нейтраль, как accel 10 у прежнего драйвера
    c.pitch = NEWFON_PITCH_DEFAULT;
    c.inflection = NEWFON_INFLECTION_DEFAULT;
    c.pause = 100;
    c.flags = DEC_SEP_POINT | DEC_SEP_COMMA | USE_LEGACY_RATE_ALGO;
    return c;
}();

// Паузы пропорциональны accel -- умолчание прежнего драйвера (pause = -1).
void PauseFromAcceleration() {
    const int a = config.acceleration >= 1 && config.acceleration <= 15 ? config.acceleration : 10;
    config.pause = 100 * a / 10;
}

// Символ -> байт KOI8-R. Чего в KOI8-R нет, то заменяется: украинские буквы
// -- ближайшими русскими (ядро русское), прочее -- пробелом.
char ToKoi8(char32_t cp) {
    if (cp == 0x00A0)
        return ' ';
    const int byte = text::FromUnicode(text::Encoding::Koi8R, cp);
    if (byte >= 0)
        return static_cast<char>(byte);
    const char32_t lower = text::ToLower(cp);
    char32_t russian = 0;
    switch (lower) {
    case U'є': russian = U'е'; break;
    case U'і':
    case U'ї': russian = U'и'; break;
    case U'ґ': russian = U'г'; break;
    case U'ў': russian = U'у'; break;
    case U'№': return 'N';
    default: return ' ';
    }
    if (lower != cp)
        russian = text::ToUpper(russian);
    return static_cast<char>(text::FromUnicode(text::Encoding::Koi8R, russian));
}

// Ядро отдаёт знаковые восьмибитные отсчёты; играем шестнадцатибитными.
int Collect(void* buffer, size_t size, void* user) {
    auto& samples = *static_cast<std::vector<int16_t>*>(user);
    const auto* source = static_cast<const signed char*>(buffer);
    for (size_t i = 0; i < size; i++)
        samples.push_back(static_cast<int16_t>(source[i] * 256));
    return 0;
}

} // namespace

void Init(const std::string& dir) {
    std::ifstream file(sys::Path(dir + "newfon.cfg"));
    bool pause_auto = true;
    for (std::string line; std::getline(file, line);) {
        line = line.substr(0, line.find(';')); // точка с запятой -- примечание
        const size_t equal = line.find('=');
        if (equal == std::string::npos)
            continue;
        std::string name, value;
        for (char c : line.substr(0, equal))
            if (static_cast<unsigned char>(c) > ' ')
                name += c;
        for (char c : line.substr(equal + 1))
            if (static_cast<unsigned char>(c) > ' ')
                value += c;
        const auto number = text::ParseInt(value);
        if (!number)
            continue;
        name = text::Upper(name);
        if (name == "ACCEL")
            config.acceleration = static_cast<int>(*number);
        if (name == "PAUSE") {
            if (*number < 0)
                pause_auto = true;
            else if (*number <= NEWFON_PAUSE_MAX) {
                pause_auto = false;
                config.pause = static_cast<int>(*number);
            }
        }
    }
    if (pause_auto)
        PauseFromAcceleration();
}

void SetVoice(int dictor) {
    config.voice = kVoices[dictor >= 0 && dictor <= 3 ? dictor : 0];
}

void SetTempo(int tempo) {
    // шкала у SV и у ядра одна и та же
    config.speech_rate = tempo > kTempoMax ? kTempoMax : tempo;
}

void Speak(std::u32string_view text) {
    if (text.empty())
        return;
    std::string koi8;
    koi8.reserve(text.size());
    for (char32_t cp : text)
        koi8 += ToKoi8(cp);

#ifdef SV_SPEECH_TRACE
    // Проверочная сборка: речь не звучит, а пишется в файл SV_SPEECH_LOG.
    if (const char* log = std::getenv("SV_SPEECH_LOG")) {
        static std::ofstream trace(sys::Path(log), std::ios::app | std::ios::binary);
        trace << text::ToUtf8(koi8, text::Encoding::Koi8R) << '\n' << std::flush;
        return;
    }
#endif

    std::vector<int16_t> samples;
    unsigned char chunk[4096];
    newfon_transfer(&config, koi8.c_str(), chunk, sizeof chunk, Collect, &samples);
    if (samples.empty() ||
        !audio::Start(audio::Speech(), samples.data(), samples.size(), kSampleRate))
        return;

    // Как у автора: пока звучит -- опрос клавиатуры; нажатая клавиша или
    // нажатый заново Ctrl обрывают речь.
    bool ctrl_held = console::ShiftState() & console::kCtrl;
    while (audio::Playing(audio::Speech())) {
        if (console::PeekKey())
            break;
        const bool ctrl = console::ShiftState() & console::kCtrl;
        if (ctrl && !ctrl_held)
            break;
        ctrl_held = ctrl;
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    audio::Stop(audio::Speech());
}

void Shutdown() {
    audio::Stop(audio::Speech());
    audio::Shutdown();
}

} // namespace newfon
