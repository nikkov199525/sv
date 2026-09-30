// normalizer.h -- подготовка текста к синтезатору (SPICK.PAS, SNAMKEY1.PAS).
//
// Авторский нормализатор: схлопывание длинных повторов символов в слова,
// аббревиатуры по буквам, транскрипция английских и немецких слов,
// украинский текст русскими буквами, незначащие нули, деление длинных
// чисел на классы. На выходе -- текст, который синтезатор читает как есть.

#ifndef SV_SPEECH_NORMALIZER_H
#define SV_SPEECH_NORMALIZER_H

#include <string>
#include <string_view>

namespace speech {

enum class Cyrillic { Russian, Ukrainian };
enum class Latin { English, German };

// Язык латинских слов -- общий для всей речи (Ctrl+T).
void SetLatin(Latin latin);
// Читать все символы (Ctrl+O): знаки препинания называются словами.
// Иначе молчат все знаки, кроме «+=#%$», а препинание даёт интонацию.
void SetAllSymbols(bool all);

// Произнести предложение. Текст уходит синтезатору частями; нажатая
// клавиша прекращает чтение.
void Pronounce(std::u32string_view sentence, Cyrillic cyrillic);

// Название символа для произнесения по буквам: «Тэчк», «Эм», «Би»...
std::u32string SymbolName(char32_t ch, Cyrillic cyrillic);

} // namespace speech

#endif
