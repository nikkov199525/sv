// speech.h -- речь программы (SPEECH.PAS).
//
// Say -- сообщения программы (всегда по правилам русского текста),
// SayText -- строки читаемого текста (язык -- по настройке), SaySymbol --
// один символ при движении по строке. Текст -- UTF-8.

#ifndef SV_SPEECH_SPEECH_H
#define SV_SPEECH_SPEECH_H

#include "speech/normalizer.h"
#include "speech/numerals.h"

#include <string>
#include <string_view>

namespace speech {

// Каталог программы (с разделителем на конце): там newfon.cfg и
// speech.sym -- названия символов, по строке на код символа в DOS-866.
void Init(const std::string& program_dir);
void Shutdown();

// Речь включена (Ctrl+V). Выключенная -- молчит, диктор и темп не меняются.
void SetTalk(bool on);
bool Talking();
void SetDictor(int dictor);
void SetTempo(int tempo);
// Язык кириллических слов читаемого текста (Ctrl+Y).
void SetCyrillic(Cyrillic cyrillic);
// Произносить пробел словом «пб» (иначе -- сигнал).
void SetSpaceSpoken(bool spoken);

void Say(std::string_view text);
void SayText(std::string_view text);
void SaySymbol(char32_t ch);

} // namespace speech

#endif
