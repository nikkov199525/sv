// music.h -- звуковые сигналы: перенос music.dll (MUSIC.PAS и wave.pas
// Сергея Шишминцева, reference/music).
//
// Строка -- команды BASIC PLAY (ноты A..G, O, L, T, P, MN/ML/MS) и
// «@частота:миллисекунды»; звук -- синусоида 44,1 кГц, 16 бит, с атакой 5%
// и затуханием 10% длительности, громкость по умолчанию 0,7.

#ifndef SV_SOUND_MUSIC_H
#define SV_SOUND_MUSIC_H

#include <cstdint>
#include <string_view>
#include <vector>

namespace sound {

std::vector<int16_t> GenerateMusic(std::string_view music, double volume = 0.7);
// Сыграть и дождаться конца.
void PlayMusic(std::string_view music);

} // namespace sound

#endif
