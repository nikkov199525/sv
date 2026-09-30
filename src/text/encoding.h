// encoding.h -- однобайтовые кодировки на границе программы.
//
// Внутри программы текст -- UTF-8. DOS-866, Windows-1251 и KOI8-R остались
// только там, где их диктует внешний мир: чтение текстов в этих
// кодировках, поля DBF, старые файлы настроек и истории, речевое ядро
// (оно принимает KOI8-R).
//
// В 866 места F6..F9 заняты украинскими буквами І, і, Ґ, ґ -- так было
// принято в самой программе (у стандартной 866 там Ў, ў, °, ∙).

#ifndef SV_TEXT_ENCODING_H
#define SV_TEXT_ENCODING_H

#include <string>
#include <string_view>

namespace text {

enum class Encoding { Dos866, Windows1251, Koi8R, Utf8 };

// Байт однобайтовой кодировки -> символ; пустая позиция -- U+FFFD.
char32_t ToUnicode(Encoding encoding, unsigned char byte);
// Символ -> байт однобайтовой кодировки; -1 -- такого там нет.
int FromUnicode(Encoding encoding, char32_t cp);

// Текст в кодировке encoding -> Unicode. У UTF-8 метка порядка байтов в
// самом начале пропускается.
std::u32string Decode(std::string_view bytes, Encoding encoding);
std::string ToUtf8(std::string_view bytes, Encoding encoding);

// Строка файла, который мог остаться в старой однобайтовой кодировке
// (настройки, история, закладки прежних версий): правильный UTF-8 --
// как есть, иначе -- из legacy.
std::string LegacyToUtf8(std::string_view bytes, Encoding legacy);

} // namespace text

#endif
