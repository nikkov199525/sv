// audio.h -- вывод звука: 16-битный моно PCM, асинхронно.
//
// Два независимых выхода: речь (newfon, 10 кГц) и сигналы (music, 44,1 кГц),
// как у исходной программы, где речь шла через waveOut, а сигналы --
// через PlaySound. Вывод -- через miniaudio (audio_miniaudio.cpp) и на
// Windows, и на Linux; нет звука в системе -- программа работает молча.

#ifndef SV_AUDIO_H
#define SV_AUDIO_H

#include <cstddef>
#include <cstdint>

namespace audio {

class Output;

// Начать играть (данные копируются); false -- не вышло.
bool Start(Output* o, const int16_t* samples, size_t count, int rate);
// Ещё звучит?
bool Playing(Output* o);
// Оборвать немедленно.
void Stop(Output* o);

Output* Speech();
Output* Tones();

// Закрыть устройства (при выходе).
void Shutdown();

} // namespace audio

#endif
