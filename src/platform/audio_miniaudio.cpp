// audio_miniaudio.cpp -- audio.h через miniaudio (vendor/miniaudio).
//
// Один и тот же код для Windows (WASAPI, DirectSound, WinMM) и Linux
// (PulseAudio/PipeWire, ALSA, JACK): miniaudio сама выбирает, что есть в
// системе, и подгружает это при запуске, так что для сборки ничего из них
// не нужно. Нет звука совсем -- программа работает молча.
//
// У каждого выхода своё устройство: моно, 16 бит, с частотой звука (её
// пересчёт в частоту устройства -- дело miniaudio). Устройство открывается
// при первом звуке и дальше работает всё время, в паузах выдавая тишину:
// так следующая фраза начинается без задержки на запуск. Обрыв (Stop) --
// мгновенный: звук просто перестаёт подаваться.

#include "platform/audio.h"

#include "miniaudio.h"

#include <cstring>
#include <mutex>
#include <vector>

namespace audio {

namespace {

// Буфер устройства: 3 периода по 10 мс.
const ma_uint32 kPeriodMs = 10;
const ma_uint32 kPeriods = 3;

} // namespace

class Output {
public:
    ma_device dev;
    bool dev_ok = false;
    bool dev_failed = false; // не открылось -- не пытаться на каждом звуке
    int rate = 0;

    std::mutex mu;
    std::vector<int16_t> data;
    size_t pos = 0;
    // Сколько кадров ещё идёт тишина после конца звука, пока его хвост
    // доигрывается из буфера устройства; пока > 0 -- «звучит».
    ma_uint32 drain = 0;

    ~Output() { close(); }

    static void callback(ma_device* d, void* out, const void*, ma_uint32 frames) {
        Output* o = (Output*)d->pUserData;
        int16_t* dst = (int16_t*)out;
        std::lock_guard<std::mutex> lk(o->mu);
        size_t left = o->data.size() - o->pos;
        size_t n = left < frames ? left : frames;
        if (n) {
            std::memcpy(dst, o->data.data() + o->pos, n * sizeof(int16_t));
            o->pos += n;
        }
        if (n < frames) {
            std::memset(dst + n, 0, (frames - n) * sizeof(int16_t));
            ma_uint32 silent = (ma_uint32)(frames - n);
            o->drain = o->drain > silent ? o->drain - silent : 0;
        }
    }

    bool open(int r) {
        if (dev_ok && rate == r)
            return true;
        close();
        if (dev_failed && rate == r)
            return false;
        rate = r;
        ma_device_config c = ma_device_config_init(ma_device_type_playback);
        c.playback.format = ma_format_s16;
        c.playback.channels = 1;
        c.sampleRate = (ma_uint32)r;
        c.dataCallback = callback;
        c.pUserData = this;
        c.periodSizeInMilliseconds = kPeriodMs;
        c.periods = kPeriods;
        c.performanceProfile = ma_performance_profile_low_latency;
        c.noPreSilencedOutputBuffer = MA_TRUE; // тишину пишет callback сам
        if (ma_device_init(nullptr, &c, &dev) != MA_SUCCESS) {
            dev_failed = true;
            return false;
        }
        dev_failed = false;
        dev_ok = true;
        if (ma_device_start(&dev) != MA_SUCCESS) {
            close();
            dev_failed = true;
            return false;
        }
        return true;
    }

    void close() {
        if (!dev_ok)
            return;
        ma_device_uninit(&dev); // ждёт конца callback'а
        dev_ok = false;
        std::lock_guard<std::mutex> lk(mu);
        data.clear();
        pos = 0;
        drain = 0;
    }

    // Хвост в кадрах звука: весь буфер устройства плюс запас на период.
    ma_uint32 tail() const { return (ma_uint32)rate * kPeriodMs * (kPeriods + 1) / 1000; }
};

bool Start(Output* o, const int16_t* samples, size_t count, int rate) {
    if (!o || !samples || !count || rate <= 0)
        return false;
    if (!o->open(rate))
        return false;
    std::lock_guard<std::mutex> lk(o->mu);
    o->data.assign(samples, samples + count);
    o->pos = 0;
    o->drain = o->tail();
    return true;
}

bool Playing(Output* o) {
    if (!o || !o->dev_ok)
        return false;
    std::lock_guard<std::mutex> lk(o->mu);
    return (o->pos < o->data.size()) || (o->drain > 0);
}

void Stop(Output* o) {
    if (!o || !o->dev_ok)
        return;
    std::lock_guard<std::mutex> lk(o->mu);
    o->pos = o->data.size();
    o->drain = 0;
}

namespace {
Output speech_out, tones_out;
}

Output* Speech() {
    return &speech_out;
}

Output* Tones() {
    return &tones_out;
}

void Shutdown() {
    speech_out.close();
    tones_out.close();
}

} // namespace audio
