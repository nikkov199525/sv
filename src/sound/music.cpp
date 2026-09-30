// music.cpp -- перенос MUSIC.PAS (GenerateMusic, PlayMusic) и wave.pas
// (GenerateSound) один в один.

#include "sound/music.h"

#include "platform/audio.h"

#include <cctype>
#include <chrono>
#include <cmath>
#include <thread>

namespace {

const double kSampleRate = 44100.0;
const double kPi = 3.14159265359;
const double kModulo = 65536.0 / 2 - 1;
const double kAttack = 0.05;
const double kDecay = 0.1;

// wave.pas: GenerateSound
void generate_sound(std::vector<int16_t>& out, double freq, double duration, double volume) {
    if (duration < 0)
        duration = 0;
    long samples = (long)std::trunc(duration * kSampleRate);
    size_t base = out.size();
    out.resize(base + (size_t)samples, 0);
    if (samples == 0 || freq == 0.0)
        return;
    int16_t* r = out.data() + base;
    long high = samples - 1;
    double angle = 0.0;
    double angle_step = 2.0 * kPi * freq / kSampleRate;
    long attack = std::lround(samples * kAttack);
    long decay = std::lround(samples * kDecay);
    auto put = [&](long i, double v) {
        if (i >= 0 && i <= high)
            r[i] = (int16_t)(uint16_t)(long)std::nearbyint(std::sin(angle) * kModulo * v);
        angle += angle_step;
    };
    double vol_var = 0.0;
    double vol_step = attack > 0 ? volume / attack : volume;
    for (long i = 0; i <= attack; i++) {
        vol_var += vol_step;
        put(i, vol_var);
    }
    for (long i = attack + 1; i <= high - decay; i++)
        put(i, volume);
    vol_var = volume;
    vol_step = decay > 0 ? volume / decay : volume;
    for (long i = high - decay; i <= high; i++) {
        put(i, vol_var);
        vol_var -= vol_step;
    }
}

double frequency(int note_num) {
    int octave = note_num / 12;
    note_num -= octave * 12 - 1;
    int oct = octave - 3;
    if (note_num > 0)
        return 440.0 * std::exp((oct + ((note_num - 10.0) / 12.0)) * std::log(2.0));
    return 0.0;
}

struct Parser {
    std::string_view s;
    int len;
    int here; // с единицы, как MusicHere
    double delay1 = 0, delay2 = 0;
    int note_length = 4, tempo = 120, octave = 4, kind = 7;

    char at(int i) const { return (i >= 1 && i <= len) ? s[i - 1] : 0; }

    unsigned get_number(unsigned min, unsigned max, unsigned def) {
        if (here <= len && at(here) == '=') {
            while (here <= len && at(here) != ';')
                here++;
            if (here <= len && at(here) == ';')
                here++;
            return def;
        }
        unsigned n = 0;
        while (here <= len && at(here) >= '0' && at(here) <= '9') {
            n = (uint16_t)(n * 10 + (at(here) - '0'));
            here++;
        }
        if (n < min || n > max)
            return def;
        return n;
    }

    void setup_delays() {
        double r = 1.0 / get_number(1, 512, note_length);
        while (here <= len && at(here) == '.') {
            here++;
            r *= 1.5;
        }
        delay1 = 60.0 * (r * (4.0 / tempo));
        if (kind < 8)
            delay2 = delay1 * (8.0 - kind) / 8.0;
        else
            delay2 = 0.0;
        delay1 -= delay2;
    }
};

} // namespace

namespace sound {

std::vector<int16_t> GenerateMusic(std::string_view music, double avolume) {
    std::vector<int16_t> out;
    Parser p;
    p.s = music;
    p.len = (int)music.size();
    p.here = 1;
    double volume = avolume;
    while (p.here <= p.len) {
        char ch = (char)std::toupper((unsigned char)p.at(p.here));
        p.here++;
        switch (ch) {
        case '@': {
            unsigned f = p.get_number(0, 22050, 440);
            if (p.at(p.here) != ':')
                continue;
            p.here++;
            unsigned l = p.get_number(0, 10000, 1000);
            generate_sound(out, f, l / 1000.0, volume);
            break;
        }
        case 'O':
            p.octave = (int)p.get_number(0, 7, 4);
            break;
        case 'L':
            p.note_length = (int)p.get_number(1, 512, 4);
            break;
        case 'T':
            p.tempo = (int)p.get_number(32, 512, 120);
            break;
        case 'V':
            volume = p.get_number(0, 100, 50) / 100.0 * avolume;
            break;
        case 'M':
            if (p.here <= p.len) {
                char c = (char)std::toupper((unsigned char)p.at(p.here));
                p.here++;
                if (c == 'L')
                    p.kind = 8;
                else if (c == 'N')
                    p.kind = 7;
                else if (c == 'S')
                    p.kind = 6;
            }
            break;
        case 'P':
            p.setup_delays();
            generate_sound(out, 0.0, p.delay1 + p.delay2, volume);
            break;
        case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G':
        case '>': case '<': {
            int note = p.octave * 12;
            if (ch == '>') {
                if (p.here <= p.len)
                    ch = (char)std::toupper((unsigned char)p.at(p.here));
                p.here++;
                if (note <= 71)
                    note += 12;
            }
            if (ch == '<') {
                if (p.here <= p.len)
                    ch = (char)std::toupper((unsigned char)p.at(p.here));
                p.here++;
                if (note >= 12)
                    note -= 12;
            }
            switch (ch) {
            case 'D': note += 2; break;
            case 'E': note += 4; break;
            case 'F': note += 5; break;
            case 'G': note += 7; break;
            case 'A': note += 9; break;
            case 'B': note += 11; break;
            }
            if (p.here <= p.len && (p.at(p.here) == '#' || p.at(p.here) == '+')) {
                p.here++;
                if (note < 10)
                    note++;
            }
            if (p.here <= p.len && p.at(p.here) == '-') {
                p.here++;
                if (note > 0)
                    note--;
            }
            p.setup_delays();
            generate_sound(out, frequency(note), p.delay1, volume);
            generate_sound(out, 0.0, p.delay2, volume);
            break;
        }
        case 'N': {
            int note = (int)p.get_number(1, 84, 0);
            p.setup_delays();
            if (note > 0)
                generate_sound(out, frequency(note - 1), p.delay1, volume);
            else
                generate_sound(out, 0.0, p.delay1, volume);
            generate_sound(out, 0.0, p.delay2, volume);
            break;
        }
        case 'X':
            while (p.here <= p.len && p.at(p.here) != ';')
                p.here++;
            if (p.here <= p.len && p.at(p.here) == ';')
                p.here++;
            break;
        }
    }
    return out;
}

void PlayMusic(std::string_view music) {
    const std::vector<int16_t> wave = GenerateMusic(music);
    if (wave.empty() || !audio::Start(audio::Tones(), wave.data(), wave.size(), (int)kSampleRate))
        return;
    while (audio::Playing(audio::Tones()))
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

} // namespace sound
