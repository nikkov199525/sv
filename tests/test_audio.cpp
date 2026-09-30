// test_audio.cpp -- вывод звука (audio.h через miniaudio): устройство
// открывается, «звучит» длится столько, сколько звук, Stop обрывает сразу,
// смена частоты работает. Играется тишина -- проверка ничего не пищит.
// Нет звукового устройства -- проверка пропускается.

#include "platform/audio.h"

#include <chrono>
#include <cstdio>
#include <thread>
#include <vector>

static int failures = 0;

#define CHECK(cond)                                                                            \
    do {                                                                                       \
        if (!(cond)) {                                                                         \
            std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);                        \
            failures++;                                                                        \
        }                                                                                      \
    } while (0)

using Clock = std::chrono::steady_clock;

static long ms_since(Clock::time_point t) {
    return (long)std::chrono::duration_cast<std::chrono::milliseconds>(Clock::now() - t).count();
}

// Сыграть тишину длиной ms и дождаться конца; вернуть, сколько длилось.
static long play_ms(audio::Output* o, int rate, int ms) {
    std::vector<int16_t> s((size_t)rate * ms / 1000, 0);
    auto t = Clock::now();
    if (!audio::Start(o, s.data(), s.size(), rate))
        return -1;
    while (audio::Playing(o)) {
        if (ms_since(t) > ms + 3000)
            return -2; // не кончается
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    return ms_since(t);
}

int main() {
    CHECK(!audio::Start(audio::Tones(), nullptr, 1, 44100));
    CHECK(!audio::Start(audio::Tones(), nullptr, 0, 44100));
    CHECK(!audio::Playing(nullptr));
    audio::Stop(nullptr);

    long d = play_ms(audio::Tones(), 44100, 300);
    if (d == -1) {
        std::printf("no audio device -- skipped\n");
        return 0;
    }
    std::printf("tones 300 ms: %ld ms\n", d);
    CHECK((d >= 280) && (d <= 700));

    // речь -- 10 кГц, отдельный выход
    d = play_ms(audio::Speech(), 10000, 200);
    std::printf("speech 200 ms: %ld ms\n", d);
    CHECK((d >= 180) && (d <= 600));

    // тот же выход с другой частотой
    d = play_ms(audio::Speech(), 22050, 150);
    std::printf("speech 150 ms @22050: %ld ms\n", d);
    CHECK((d >= 130) && (d <= 550));

    // обрыв: Stop -- и сразу не звучит
    std::vector<int16_t> s(44100 * 2, 0);
    CHECK(audio::Start(audio::Tones(), s.data(), s.size(), 44100));
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    CHECK(audio::Playing(audio::Tones()));
    audio::Stop(audio::Tones());
    CHECK(!audio::Playing(audio::Tones()));

    // оба выхода сразу
    std::vector<int16_t> a(44100 / 5, 0), b(10000 / 5, 0);
    CHECK(audio::Start(audio::Tones(), a.data(), a.size(), 44100));
    CHECK(audio::Start(audio::Speech(), b.data(), b.size(), 10000));
    auto t = Clock::now();
    while ((audio::Playing(audio::Tones()) || audio::Playing(audio::Speech())) &&
           (ms_since(t) < 3000))
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    CHECK(ms_since(t) < 1000);

    audio::Shutdown();
    CHECK(!audio::Playing(audio::Speech()));
    std::printf(failures ? "%d failure(s)\n" : "ok\n", failures);
    return failures ? 1 : 0;
}
