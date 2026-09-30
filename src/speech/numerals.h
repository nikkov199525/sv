// numerals.h -- числительные в речи (SAYFORM.PAS, С. А. Картавцев).
//
// Шаблон фразы -- как у автора: части разделяются «\» (или «-»).
//
// SayOrdinal(21, "\ая\ строка+.") -- «двадцать первая строка»:
//     до первого «\» -- слова перед числом, дальше -- окончание
//     порядкового числительного, дальше -- слова после него.
//
// SayQuantity(5, "ж \строк\а+\и+\\.") -- «пять строк»:
//     первое слово -- род (м, ж, с) и ключи («слово» -- только
//     существительное, «число» -- только число, «мо» -- молчать); после
//     «/» -- предлог; дальше -- основа существительного и окончания для
//     1, 2..4, 5 и больше и то, что идёт после.

#ifndef SV_SPEECH_NUMERALS_H
#define SV_SPEECH_NUMERALS_H

#include <string_view>

namespace speech {

void SayOrdinal(long long number, std::string_view pattern);
void SayQuantity(long long number, std::string_view pattern);
// Размер в байтах: «16.58 Мегобайта», «два Килобайта».
void SayByteSize(long long bytes);
// «Сейчас 10 часов 5 минут», «Сегодня пятница, 27 сентября 2026 года».
void SayTime();
void SayDate();

} // namespace speech

#endif
