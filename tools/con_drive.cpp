// con_drive.cpp -- проверка SV вручную без рук (только Windows).
//
// Запускает программу в собственной консоли, подаёт ей нажатия клавиш и
// снимает экран. Команды -- со стандартного ввода, по одной в строке:
//     wait <мс>                 подождать
//     key <имя> [ctrl] [alt] [shift]
//                               нажать клавишу: f1..f12, up, down, left,
//                               right, home, end, pgup, pgdn, ins, del,
//                               enter, esc, tab, space, back, [, ], a..z, 0..9
//     text <строка UTF-8>       набрать строку
//     dump                      вывести экран (UTF-8)
//     alive                     жив ли процесс
//     kill                      завершить процесс
// Пример: con_drive build\x64 SV.exe test.txt < script.txt

#ifdef _WIN32

#include <windows.h>

#include <cstdio>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

static HANDLE out_std;

static void out(const std::string& s) {
    DWORD w;
    WriteFile(out_std, s.data(), (DWORD)s.size(), &w, nullptr);
}

static std::wstring widen(const std::string& s) {
    int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
    std::wstring w(n, 0);
    MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
    return w;
}

static std::string narrow(const std::wstring& w) {
    int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), nullptr, 0, nullptr, nullptr);
    std::string s(n, 0);
    WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), &s[0], n, nullptr, nullptr);
    return s;
}

static void send(HANDLE in, WORD vk, wchar_t ch, DWORD mods) {
    INPUT_RECORD r[2] = {};
    for (int i = 0; i < 2; i++) {
        r[i].EventType = KEY_EVENT;
        KEY_EVENT_RECORD& k = r[i].Event.KeyEvent;
        k.bKeyDown = i == 0;
        k.wRepeatCount = 1;
        k.wVirtualKeyCode = vk;
        k.wVirtualScanCode = (WORD)MapVirtualKeyW(vk, MAPVK_VK_TO_VSC);
        k.uChar.UnicodeChar = ch;
        k.dwControlKeyState = mods;
    }
    DWORD w;
    WriteConsoleInputW(in, r, 2, &w);
}

static bool key(HANDLE in, const std::string& name, DWORD mods) {
    struct {
        const char* n;
        WORD vk;
        wchar_t ch;
        bool ext;
    } t[] = {
        {"up", VK_UP, 0, true},       {"down", VK_DOWN, 0, true},   {"left", VK_LEFT, 0, true},
        {"right", VK_RIGHT, 0, true}, {"home", VK_HOME, 0, true},   {"end", VK_END, 0, true},
        {"pgup", VK_PRIOR, 0, true},  {"pgdn", VK_NEXT, 0, true},   {"ins", VK_INSERT, 0, true},
        {"del", VK_DELETE, 0, true},  {"enter", VK_RETURN, 13, false},
        {"esc", VK_ESCAPE, 27, false}, {"tab", VK_TAB, 9, false},    {"space", VK_SPACE, ' ', false},
        {"back", VK_BACK, 8, false},  {"[", VK_OEM_4, '[', false},  {"]", VK_OEM_6, ']', false},
    };
    for (auto& e : t)
        if (name == e.n) {
            wchar_t ch = e.ch;
            if ((mods & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) && (e.vk == VK_OEM_4))
                ch = 27;
            if ((mods & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED)) && (e.vk == VK_OEM_6))
                ch = 29;
            send(in, e.vk, ch, mods | (e.ext ? ENHANCED_KEY : 0));
            return true;
        }
    if ((name.size() >= 2) && (name[0] == 'f') && isdigit((unsigned char)name[1])) {
        int n = atoi(name.c_str() + 1);
        send(in, (WORD)(VK_F1 + n - 1), 0, mods);
        return true;
    }
    if (name.size() == 1 && (isalnum((unsigned char)name[0]))) {
        char c = name[0];
        WORD vk = (WORD)toupper((unsigned char)c);
        wchar_t ch = (wchar_t)c;
        if (mods & (LEFT_CTRL_PRESSED | RIGHT_CTRL_PRESSED))
            ch = isalpha((unsigned char)c) ? (wchar_t)(toupper(c) - 'A' + 1) : ch;
        if (mods & (LEFT_ALT_PRESSED | RIGHT_ALT_PRESSED))
            ch = 0;
        send(in, vk, ch, mods);
        return true;
    }
    return false;
}

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "usage: con_drive <dir> <exe> [args...]\n");
        return 2;
    }
    out_std = GetStdHandle(STD_OUTPUT_HANDLE);
    std::wstring cl = L"\"" + widen(argv[2]) + L"\"";
    for (int i = 3; i < argc; i++)
        cl += L" \"" + widen(argv[i]) + L"\"";
    std::wstring dir = widen(argv[1]);
    std::wstring exe = dir + L"\\" + widen(argv[2]);
    STARTUPINFOW si = {};
    si.cb = sizeof si;
    PROCESS_INFORMATION pi = {};
    std::vector<wchar_t> buf(cl.begin(), cl.end());
    buf.push_back(0);
    if (!CreateProcessW(exe.c_str(), buf.data(), nullptr, nullptr, FALSE,
                        CREATE_NEW_CONSOLE, nullptr, dir.c_str(), &si, &pi)) {
        fprintf(stderr, "CreateProcess failed: %lu\n", GetLastError());
        return 1;
    }
    Sleep(500);
    FreeConsole();
    bool attached = false;
    for (int i = 0; i < 50; i++) {
        if (AttachConsole(pi.dwProcessId)) {
            attached = true;
            break;
        }
        Sleep(100);
    }
    if (!attached) {
        fprintf(stderr, "AttachConsole failed: %lu\n", GetLastError());
        TerminateProcess(pi.hProcess, 1);
        return 1;
    }
    HANDLE in = CreateFileW(L"CONIN$", GENERIC_READ | GENERIC_WRITE,
                            FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    std::string line;
    while (std::getline(std::cin, line)) {
        if (!line.empty() && line.back() == '\r')
            line.pop_back();
        std::istringstream is(line);
        std::string cmd;
        is >> cmd;
        if (cmd == "wait") {
            int ms = 0;
            is >> ms;
            Sleep(ms);
        } else if (cmd == "key") {
            std::string name, m;
            is >> name;
            DWORD mods = 0;
            while (is >> m) {
                if (m == "ctrl")
                    mods |= LEFT_CTRL_PRESSED;
                if (m == "alt")
                    mods |= LEFT_ALT_PRESSED;
                if (m == "shift")
                    mods |= SHIFT_PRESSED;
            }
            if (!key(in, name, mods))
                out("unknown key " + name + "\n");
            Sleep(150);
        } else if (cmd == "text") {
            std::string rest;
            std::getline(is, rest);
            if (!rest.empty() && rest[0] == ' ')
                rest.erase(0, 1);
            for (wchar_t ch : widen(rest)) {
                SHORT vks = VkKeyScanW(ch);
                send(in, vks == -1 ? 0 : (WORD)(vks & 0xFF), ch, (vks >> 8) & 1 ? SHIFT_PRESSED : 0);
                Sleep(30);
            }
            Sleep(150);
        } else if (cmd == "dump") {
            HANDLE o = CreateFileW(L"CONOUT$", GENERIC_READ | GENERIC_WRITE,
                                   FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0,
                                   nullptr);
            CONSOLE_SCREEN_BUFFER_INFO bi{};
            if (o == INVALID_HANDLE_VALUE || !GetConsoleScreenBufferInfo(o, &bi)) {
                out("screen unavailable\n");
                if (o != INVALID_HANDLE_VALUE) CloseHandle(o);
                continue;
            }
            int w = bi.dwSize.X, h = bi.srWindow.Bottom - bi.srWindow.Top + 1;
            if (w <= 0 || h <= 0 || w > 240 || h > 100) {
                out("invalid screen dimensions\n");
                CloseHandle(o);
                continue;
            }
            std::vector<CHAR_INFO> c((size_t)w * h);
            SMALL_RECT r = {0, bi.srWindow.Top, (SHORT)(w - 1), bi.srWindow.Bottom};
            ReadConsoleOutputW(o, c.data(), {(SHORT)w, (SHORT)h}, {0, 0}, &r);
            out("----- screen " + std::to_string(w) + "x" + std::to_string(h) + "\n");
            for (int y = 0; y < h; y++) {
                std::wstring row;
                for (int x = 0; x < w; x++)
                    row += c[(size_t)y * w + x].Char.UnicodeChar;
                while (!row.empty() && row.back() == L' ')
                    row.pop_back();
                out(narrow(row) + "\n");
            }
            CloseHandle(o);
        } else if (cmd == "alive") {
            DWORD code = 0;
            GetExitCodeProcess(pi.hProcess, &code);
            out(code == STILL_ACTIVE ? "alive\n" : "exited " + std::to_string(code) + "\n");
        } else if (cmd == "kill") {
            TerminateProcess(pi.hProcess, 1);
        }
    }
    WaitForSingleObject(pi.hProcess, 3000);
    DWORD code = 0;
    GetExitCodeProcess(pi.hProcess, &code);
    if (code == STILL_ACTIVE)
        TerminateProcess(pi.hProcess, 1);
    return 0;
}

#else
int main() {
    return 0;
}
#endif
