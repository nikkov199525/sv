// system_win.cpp -- system.h для Windows.

#ifdef _WIN32

#include "platform/system.h"

#include "text/encoding.h"
#include "text/utf8.h"

#include <windows.h>
#include <shellapi.h>

#include <cstdio>

namespace sys {

namespace {

std::wstring Wide(std::string_view utf8) {
    return Path(utf8).wstring();
}

} // namespace

std::string ExeDir() {
    std::wstring buffer(32768, L'\0');
    buffer.resize(GetModuleFileNameW(nullptr, buffer.data(), static_cast<DWORD>(buffer.size())));
    return Utf8(fs::path(buffer).parent_path()) + kSeparator;
}

std::vector<std::string> Arguments(int, char**) {
    // argv у Windows -- в кодировке ANSI; настоящие имена -- в UTF-16.
    int count = 0;
    LPWSTR* list = CommandLineToArgvW(GetCommandLineW(), &count);
    std::vector<std::string> result;
    for (int i = 1; i < count; i++)
        result.push_back(Utf8(fs::path(list[i])));
    LocalFree(list);
    return result;
}

std::string GetEnv(const char* name) {
    const std::wstring wide = Wide(name);
    const DWORD size = GetEnvironmentVariableW(wide.c_str(), nullptr, 0);
    if (size == 0)
        return {};
    std::wstring value(size, L'\0');
    value.resize(GetEnvironmentVariableW(wide.c_str(), value.data(), size));
    return Utf8(fs::path(value));
}

bool IsHidden(const fs::directory_entry& entry) {
    const DWORD attributes = GetFileAttributesW(entry.path().c_str());
    return attributes != INVALID_FILE_ATTRIBUTES && (attributes & FILE_ATTRIBUTE_HIDDEN);
}

std::string Drives() {
    std::string result;
    const DWORD mask = GetLogicalDrives();
    for (int i = 0; i < 26; i++)
        if (mask & (1u << i))
            result += static_cast<char>('A' + i);
    return result;
}

bool Run(const std::string& program, const std::string& arguments) {
    std::wstring command = L"\"" + Wide(program) + L"\" " + Wide(arguments);
    STARTUPINFOW startup = {};
    startup.cb = sizeof startup;
    PROCESS_INFORMATION process = {};
    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, TRUE, 0, nullptr, nullptr,
                        &startup, &process))
        return false;
    WaitForSingleObject(process.hProcess, INFINITE);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    return true;
}

std::string CommandShell() {
    return GetEnv("COMSPEC");
}

void Print(const std::vector<std::string>& lines) {
    FILE* printer = _wfopen(L"PRN", L"wb");
    if (!printer)
        return;
    for (const std::string& line : lines) {
        for (char32_t cp : utf8::Decode(line)) {
            const int byte = text::FromUnicode(text::Encoding::Dos866, cp);
            std::fputc(byte < 0 ? '?' : byte, printer);
        }
        std::fputs("\r\n", printer);
    }
    std::fclose(printer);
}

void WriteToTerminal(std::string_view utf8) {
    const HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);
    DWORD mode;
    if (GetConsoleMode(out, &mode)) {
        const std::wstring wide = Wide(utf8);
        DWORD written;
        WriteConsoleW(out, wide.data(), static_cast<DWORD>(wide.size()), &written, nullptr);
    } else {
        std::fwrite(utf8.data(), 1, utf8.size(), stdout);
        std::fflush(stdout);
    }
}

} // namespace sys

#endif
