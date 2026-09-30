// signals.h -- звуковые сигналы программы (DINAMIC.PAS и V_Signal из
// S_U.PAS). Все сигналы звучат, только если звук включён в настройках.

#ifndef SV_SOUND_SIGNALS_H
#define SV_SOUND_SIGNALS_H

namespace sound {

void SetEnabled(bool on);

enum class Signal {
    Edge,       // край: дальше некуда
    Error,
    Capital,    // заглавная буква
    Space,      // пробел, если он не произносится
    Start,      // возврат в текст
    Selected,   // выбранный элемент
    Break,      // чтение прервано
    // Сигналы окна текста.
    Empty,      // пустая строка
    Indent,     // абзац
    Found,      // строка найдена
    BreakRead,  // после нескольких пустых строк
    EndText,    // конец текста
    NextWindow, // чтение переходит в следующее окно
    NotFound,   // пустой строки (абзаца) дальше нет
    Marked,     // строка в блоке
    Block,      // ожидание команды блока
    BeforeHour, // секунды перед часом
    Hour,       // начало часа
    Alarm,      // будильник
    CodeChange, // смена кодировки
    Dictionary,
    DictionaryStep,
    EndLine,    // конец строки
};

void Play(Signal signal);
// Тон частотой frequency Гц длиной ms миллисекунд.
void Beep(int frequency, int ms);

} // namespace sound

#endif
