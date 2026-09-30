// word97.h -- текст из файла MS Word 97 (WORDCONV.PAS).
//
// Текст Word 97 лежит с позиции 600h по два байта на символ до нулевого;
// конец абзаца (0Dh) становится концом строки. width > 0 -- длинные абзацы
// режутся на строки около этой длины (по знакам «.,)]};: »). Результат --
// UTF-8.

#ifndef SV_CONVERT_WORD97_H
#define SV_CONVERT_WORD97_H

#include <string>

namespace convert {

bool Word97ToText(const std::string& from, const std::string& to, int width);

} // namespace convert

#endif
