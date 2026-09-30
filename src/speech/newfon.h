// newfon.h -- синтезатор речи: ядро newfon_core и вывод звука.
//
// Ядро (vendor/newfon_core) собрано в программу статически. Текст ему
// отдаётся в KOI8-R: это единственное место, где речь покидает Unicode.
//
// Соответствие параметров:
//     диктор SV 0..3 -- голос ядра male 1, female 1, male 2, female 2;
//     темп SV 0..150 -- темп ядра 0..150 (0 -- самый быстрый), без пересчёта.
//
// Файл newfon.cfg рядом с программой -- замена ключам setup.bat прежнего
// драйвера SDRV:
//     accel  1..15   ускорение темпа; 10 -- нейтраль;
//     pause  0..255  относительная длина пауз, 100 -- обычная;
//            -1 -- паузы пропорциональны accel (так по умолчанию).

#ifndef SV_SPEECH_NEWFON_H
#define SV_SPEECH_NEWFON_H

#include <string>
#include <string_view>

namespace newfon {

constexpr int kTempoMax = 150;

// Прочитать newfon.cfg из каталога dir (с разделителем на конце).
void Init(const std::string& dir);
void SetVoice(int dictor);
void SetTempo(int tempo);

// Произнести подготовленный текст и дождаться конца. Как у драйвера
// автора, речь обрывается нажатой клавишей или заново нажатым Ctrl.
void Speak(std::u32string_view text);
void Shutdown();

} // namespace newfon

#endif
