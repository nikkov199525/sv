// html.h -- текст из файла html (HTMTRANS.PAS).
//
// Теги убираются, абзацы, строки, списки, заголовок и линии оформляются
// строками шириной 72 символа, мнемоники (&nbsp; &#233; ...) заменяются.
// keep_links -- ссылки нумеруются в тексте, их адреса -- списком в конце.
//
// Страница в UTF-8 читается по символам и пишется в UTF-8. Прочие кодировки
// переносятся байт в байт: какая у них кодировка, определит окно просмотра.

#ifndef SV_CONVERT_HTML_H
#define SV_CONVERT_HTML_H

#include <string>

namespace convert {

bool HtmlToText(const std::string& from, const std::string& to, bool keep_links);

} // namespace convert

#endif
