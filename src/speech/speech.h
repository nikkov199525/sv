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

// Каталог программы (с разделителем на конце): там speech.sym -- названия
// символов, по строке на код символа в DOS-866.
void Init(const std::string& program_dir);
void Shutdown();

// Речь включена (Ctrl+V). Выключенная -- молчит, диктор и темп не меняются.
void SetTalk(bool on);
bool Talking();
void SetDictor(int dictor);
// Скорость речи: 0..150, больше -- быстрее.
void SetSpeed(int speed);
// Ускорение поверх скорости: -3..+7, 0 -- нормально, плюс -- быстрее.
// Пауза между фразами: 0..255 (100 -- обычная), kPauseAuto -- по
// ускорению, как у прежнего драйвера.
constexpr int kPauseAuto = -1;
void SetAcceleration(int acceleration, int pause);
// Язык кириллических слов читаемого текста (Ctrl+Y).
void SetCyrillic(Cyrillic cyrillic);
// Произносить пробел словом «пб» (иначе -- сигнал).
void SetSpaceSpoken(bool spoken);

void Say(std::string_view text);
void SayText(std::string_view text);
void SaySymbol(char32_t ch);

} // namespace speech

#endif
