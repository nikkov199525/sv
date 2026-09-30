// system.cpp -- общая для всех ОС часть system.h.

#include "platform/system.h"

#include "text/unicode.h"
#include "text/utf8.h"

namespace sys {

fs::path Path(std::string_view utf8) {
    return fs::u8path(utf8.begin(), utf8.end());
}

std::string Utf8(const fs::path& path) {
    return path.u8string();
}

std::string TempDir() {
    std::string dir = GetEnv("TEMP");
    if (dir.empty())
        dir = GetEnv("TMP");
#ifndef _WIN32
    if (dir.empty())
        dir = GetEnv("TMPDIR");
    if (dir.empty() && fs::is_directory("/tmp"))
        dir = "/tmp";
#endif
    if (dir.empty())
        return ExeDir();
    if (dir.back() != kSeparator)
        dir += kSeparator;
    return dir;
}

bool SameFileName(std::string_view a, std::string_view b) {
#ifdef _WIN32
    return text::FoldCase(utf8::Decode(a)) == text::FoldCase(utf8::Decode(b));
#else
    return a == b;
#endif
}

} // namespace sys
