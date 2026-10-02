// console_posix.cpp -- console.h для терминала Linux.
//
// Экран рисуется в альтернативном буфере терминала последовательностями
// ANSI, символы -- UTF-8, цвета -- 16 цветов DOS. Перерисовываются только
// изменившиеся клетки.
//
// Клавиатура -- терминал в «сыром» режиме: разбор последовательностей
// xterm, консоли Linux, режима modifyOtherKeys и протокола клавиатуры kitty.
// Модификаторы, нажатые «сейчас», терминалы не сообщают; на текстовой
// консоли Linux их отдаёт ioctl TIOCLINUX, и тогда различаются, например,
// Esc и Ctrl+[ -- как у Windows. В эмуляторах терминала различение Ctrl+[
// даёт modifyOtherKeys (xterm) или протокол kitty (kitty, foot, WezTerm,
// ghostty, Alacritty).

#ifndef _WIN32

#include "platform/console.h"
#include "platform/keymap.h"
#include "text/utf8.h"

#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdio>
#include <cstring>
#include <deque>
#include <poll.h>
#include <string>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

#ifdef __linux__
#include <linux/kd.h>
#include <linux/tiocl.h>
#endif

namespace console {

namespace {

bool video_on = false;
bool keyboard_on = false;
bool tty_raw = false;
struct termios saved_tio;
Cursor cursor_type = Cursor::Underline;
int cursor_x = 0, cursor_y = 0;
Cell last[kWidth * kHeight];
bool last_valid = false;
volatile sig_atomic_t resized = 0;

std::deque<KeyEvent> queue;
std::string pending;          // непрочитанные байты
uint32_t pending_since = 0;   // когда пришёл первый из них (мс)
uint8_t last_mods = 0;
bool vt_console = false;      // текстовая консоль Linux: TIOCLINUX работает
bool mouse_on = false;
MouseState mouse;
uint8_t mouse_presses = 0;

// Отчёты о мыши xterm: нажатия (1000), движение (1003), запись SGR (1006).
const char* const kMouseOn = "\x1b[?1000h\x1b[?1003h\x1b[?1006h";
const char* const kMouseOff = "\x1b[?1006l\x1b[?1003l\x1b[?1000l";

// Отчёт SGR «ESC [ < b;x;y M» (нажатие, движение) или «... m» (отпускание).
void mouse_report(const int* p, int np, bool press) {
    if (np < 3)
        return;
    const int b = p[0];
    if (b & 64) // колесо
        return;
    static const uint8_t kButton[3] = {kMouseLeft, kMouseMiddle, kMouseRight};
    uint8_t buttons = mouse.buttons;
    if (!(b & 32) && (b & 3) < 3) { // нажатие или отпускание кнопки
        const uint8_t bit = kButton[b & 3];
        if (press) {
            mouse_presses |= bit & ~buttons;
            buttons |= bit;
        } else
            buttons &= ~bit;
    }
    mouse = {buttons, p[1] - 1, p[2] - 1};
}

uint32_t now_ms() {
    using namespace std::chrono;
    return static_cast<uint32_t>(duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count());
}

void out(const std::string& s) {
    size_t off = 0;
    while (off < s.size()) {
        ssize_t n = write(STDOUT_FILENO, s.data() + off, s.size() - off);
        if (n < 0) {
            if (errno == EINTR)
                continue;
            return;
        }
        off += (size_t)n;
    }
}

void on_winch(int) {
    resized = 1;
}

void raw_mode(bool on) {
    if (on && !tty_raw) {
        if (tcgetattr(STDIN_FILENO, &saved_tio) != 0)
            return;
        struct termios t = saved_tio;
        // Никаких сигналов, эха, строкового ввода и XON/XOFF: Ctrl+C, Ctrl+S,
        // Ctrl+Q, Ctrl+Z, Ctrl+V -- клавиши программы.
        t.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL | IXON | IXOFF);
        t.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN);
        t.c_cflag |= CS8;
        t.c_cc[VMIN] = 0;
        t.c_cc[VTIME] = 0;
        tcsetattr(STDIN_FILENO, TCSANOW, &t);
        tty_raw = true;
    } else if (!on && tty_raw) {
        tcsetattr(STDIN_FILENO, TCSANOW, &saved_tio);
        tty_raw = false;
    }
}

// Модификаторы с текстовой консоли Linux: 1 -- Shift, 4 -- Ctrl, 8 -- Alt.
bool vt_shift_state(uint8_t& m) {
#if defined(__linux__) && defined(TIOCLINUX)
    char arg = TIOCL_GETSHIFTSTATE;
    if (ioctl(STDIN_FILENO, TIOCLINUX, &arg) != 0)
        return false;
    uint8_t s = (uint8_t)arg;
    m = 0;
    if (s & 0x01)
        m |= kLeftShift;
    if (s & 0x04)
        m |= kCtrl;
    if (s & 0x0A) // Alt и AltGr
        m |= kAlt;
    return true;
#else
    (void)m;
    return false;
#endif
}

void read_available() {
    char buf[256];
    for (;;) {
        struct pollfd p = {STDIN_FILENO, POLLIN, 0};
        if (poll(&p, 1, 0) <= 0 || !(p.revents & POLLIN))
            return;
        ssize_t n = read(STDIN_FILENO, buf, sizeof buf);
        if (n <= 0)
            return;
        if (pending.empty())
            pending_since = now_ms();
        pending.append(buf, (size_t)n);
    }
}

void push(KeyEvent e) {
    if (e) {
        queue.push_back(e);
        last_mods = e.mods;
    }
}

// Параметры CSI: «1;5» -> {1, 5}; подпараметры после «:» отбрасываются.
void csi_params(const std::string& s, int* p, int& n) {
    n = 0;
    int v = 0;
    bool have = false, sub = false;
    for (char c : s) {
        if (c >= '0' && c <= '9') {
            if (!sub) {
                v = v * 10 + (c - '0');
                have = true;
            }
        } else if (c == ':') {
            sub = true;
        } else if (c == ';') {
            if (n < 8)
                p[n++] = have ? v : 0;
            v = 0;
            have = false;
            sub = false;
        }
    }
    if ((have || !s.empty()) && n < 8)
        p[n++] = have ? v : 0;
}

uint8_t mods_from_param(int m) {
    if (m < 2)
        return 0;
    m -= 1;
    uint8_t r = 0;
    if (m & 1)
        r |= kLeftShift;
    if (m & 2)
        r |= kAlt;
    if (m & 4)
        r |= kCtrl;
    return r;
}

// Символ с модификаторами (из CSI u и modifyOtherKeys).
KeyEvent char_with_mods(char32_t u, uint8_t mods) {
    using namespace keymap;
    // Ctrl+Alt+[ и ], Ctrl+Shift+[ и ] (с Shift терминал шлёт и «{», «}») --
    // Ctrl+[ и Ctrl+] с Alt или Shift (ускорение и паузы речи).
    if ((mods & kCtrl) && (mods & (kAlt | kShift)) &&
        (u == '[' || u == '{' || u == 27 || u == ']' || u == '}' || u == 29))
        return Make(u == '[' || u == '{' || u == 27 ? 27 : 29, 0, mods);
    if (mods & kAlt)
        return MakeAltChar(u, mods);
    if (mods & kCtrl) {
        if (u >= 'a' && u <= 'z')
            return Make((uint8_t)(u - 'a' + 1), 0, mods);
        if (u >= 'A' && u <= 'Z')
            return Make((uint8_t)(u - 'A' + 1), 0, mods);
        switch (u) {
        case '[': case 27: return Make(27, 0, mods);
        case ']': return Make(29, 0, mods);
        case '\\': return Make(28, 0, mods);
        case 13: return Make(10, 0, mods);
        case 8: case 127: return Make(127, 0, mods);
        case 9: return Scan(0x94, mods);
        case ' ': return Make(' ', 0, mods);
        }
        // Ctrl с кириллицей: код по латинской букве на той же клавише.
        uint8_t scan = AltScan(u);
        static const char qwerty_by_scan[0x40] = {
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 0, 0, 0, 0,
            'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 0, 0, 0, 0, 0,
            'z', 'x', 'c', 'v', 'b', 'n', 'm', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        };
        if (scan && scan < 0x40 && qwerty_by_scan[scan])
            return Make((uint8_t)(qwerty_by_scan[scan] - 'a' + 1), 0, mods);
        return {};
    }
    if (u == 27)
        return Make(27, 0x01, mods);
    if (u == 13)
        return Make(13, 0x1C, mods);
    if (u == 9)
        return (mods & kShift) ? MakeSpecial(kShiftTab, mods) : Make(9, 0x0F, mods);
    if (u == 127 || u == 8)
        return Make(8, 0x0E, mods);
    return MakeChar(u, mods);
}

// Символ UTF-8 в pending с позиции pos; false -- неполный или ошибочный.
bool DecodeAt(size_t pos, char32_t& cp, size_t& length) {
    size_t end = pos;
    const bool valid = utf8::Next(pending, end, cp);
    length = end - pos;
    return valid;
}

// Разобрать одну клавишу из начала pending. false -- данных мало, ждать.
bool parse_one(bool timed_out) {
    using namespace keymap;
    const unsigned char* s = (const unsigned char*)pending.data();
    size_t n = pending.size();
    if (!n)
        return false;
    uint8_t vt_mods = 0;
    bool have_vt = vt_console && vt_shift_state(vt_mods);

    unsigned char c = s[0];
    if (c == 0x1B) {
        if (n == 1) {
            if (!timed_out)
                return false;
            pending.erase(0, 1);
            // Esc или Ctrl+[ -- на текстовой консоли их различает Ctrl.
            push((have_vt && (vt_mods & kCtrl)) ? Make(27, 0, vt_mods) : Make(27, 0x01, 0));
            return true;
        }
        if (s[1] == '[') {
            // Консоль Linux: F1..F5 -- ESC [ [ A..E.
            if (n >= 3 && s[2] == '[') {
                if (n < 4)
                    return timed_out ? (pending.erase(0, n), true) : false;
                int k = s[3] - 'A';
                pending.erase(0, 4);
                if (k >= 0 && k < 5)
                    push(MakeSpecial((Special)(kF1 + k), have_vt ? vt_mods : 0));
                return true;
            }
            size_t i = 2;
            while (i < n && s[i] >= 0x20 && s[i] <= 0x3F)
                i++;
            if (i >= n) {
                if (!timed_out)
                    return false;
                pending.erase(0, n);
                return true;
            }
            char fin = (char)s[i];
            std::string par((const char*)s + 2, i - 2);
            pending.erase(0, i + 1);
            int p[8] = {0};
            int np = 0;
            if (!par.empty() && par[0] == '<' && (fin == 'M' || fin == 'm')) {
                csi_params(par.substr(1), p, np);
                mouse_report(p, np, fin == 'M');
                return true;
            }
            csi_params(par, p, np);
            uint8_t mods = np >= 2 ? mods_from_param(p[1]) : 0;
            if (!mods && have_vt)
                mods = vt_mods;
            switch (fin) {
            case 'A': push(MakeSpecial(kUp, mods)); break;
            case 'B': push(MakeSpecial(kDown, mods)); break;
            case 'C': push(MakeSpecial(kRight, mods)); break;
            case 'D': push(MakeSpecial(kLeft, mods)); break;
            case 'E': push(MakeSpecial(kCenter, mods)); break;
            case 'H': push(MakeSpecial(kHome, mods)); break;
            case 'F': push(MakeSpecial(kEnd, mods)); break;
            case 'Z': push(MakeSpecial(kShiftTab, mods)); break;
            case 'P': push(MakeSpecial(kF1, mods)); break;
            case 'Q': push(MakeSpecial(kF2, mods)); break;
            case 'R': push(MakeSpecial(kF3, mods)); break;
            case 'S': push(MakeSpecial(kF4, mods)); break;
            case 'u':
                // Протокол kitty: код;модификаторы u
                if (np >= 1)
                    push(char_with_mods((char32_t)p[0], np >= 2 ? mods_from_param(p[1]) : 0));
                break;
            case '~': {
                int code = np >= 1 ? p[0] : 0;
                if (code == 27 && np >= 3) { // modifyOtherKeys: 27;мод;код~
                    push(char_with_mods((char32_t)p[2], mods_from_param(p[1])));
                    break;
                }
                Special k = kNone;
                switch (code) {
                case 1: case 7: k = kHome; break;
                case 2: k = kIns; break;
                case 3: k = kDel; break;
                case 4: case 8: k = kEnd; break;
                case 5: k = kPgUp; break;
                case 6: k = kPgDn; break;
                case 11: k = kF1; break;
                case 12: k = kF2; break;
                case 13: k = kF3; break;
                case 14: k = kF4; break;
                case 15: k = kF5; break;
                case 17: k = kF6; break;
                case 18: k = kF7; break;
                case 19: k = kF8; break;
                case 20: k = kF9; break;
                case 21: k = kF10; break;
                case 23: k = kF11; break;
                case 24: k = kF12; break;
                // Консоль Linux: Shift+F1..F8 приходят как F11..F20.
                case 25: k = kF3; mods |= kLeftShift; break;
                case 26: k = kF4; mods |= kLeftShift; break;
                case 28: k = kF5; mods |= kLeftShift; break;
                case 29: k = kF6; mods |= kLeftShift; break;
                case 31: k = kF7; mods |= kLeftShift; break;
                case 32: k = kF8; mods |= kLeftShift; break;
                case 33: k = kF9; mods |= kLeftShift; break;
                case 34: k = kF10; mods |= kLeftShift; break;
                }
                if (k != kNone)
                    push(MakeSpecial(k, mods));
                break;
            }
            default:
                break; // вставка, фокус и прочее -- не клавиши
            }
            return true;
        }
        if (s[1] == 'O') {
            if (n < 3)
                return timed_out ? (pending.erase(0, n), true) : false;
            char fin = (char)s[2];
            pending.erase(0, 3);
            uint8_t mods = have_vt ? vt_mods : 0;
            switch (fin) {
            case 'A': push(MakeSpecial(kUp, mods)); break;
            case 'B': push(MakeSpecial(kDown, mods)); break;
            case 'C': push(MakeSpecial(kRight, mods)); break;
            case 'D': push(MakeSpecial(kLeft, mods)); break;
            case 'E': push(MakeSpecial(kCenter, mods)); break;
            case 'H': push(MakeSpecial(kHome, mods)); break;
            case 'F': push(MakeSpecial(kEnd, mods)); break;
            case 'P': push(MakeSpecial(kF1, mods)); break;
            case 'Q': push(MakeSpecial(kF2, mods)); break;
            case 'R': push(MakeSpecial(kF3, mods)); break;
            case 'S': push(MakeSpecial(kF4, mods)); break;
            case 'M': push(Make(13, 0x1C, mods)); break;
            }
            return true;
        }
        if (s[1] == 0x1B) {
            // ESC ESC: первый -- Esc, второй разберётся отдельно.
            pending.erase(0, 1);
            push(Make(27, 0x01, 0));
            return true;
        }
        // ESC + символ -- Alt+символ.
        char32_t cp;
        size_t k;
        if (s[1] >= 0x80) {
            if (!DecodeAt(1, cp, k)) {
                if (!timed_out && n < 5)
                    return false;
                cp = '?';
                k = 1;
            }
        } else {
            cp = s[1];
            k = 1;
        }
        pending.erase(0, 1 + k);
        if (cp < 32 && cp != 13 && cp != 8 && cp != 9)
            cp = cp + 'a' - 1;
        push(MakeAltChar(cp, kAlt));
        return true;
    }

    if (c >= 0x80) {
        char32_t cp;
        size_t k;
        if (!DecodeAt(0, cp, k)) {
            if (!timed_out && n < 4)
                return false;
            cp = '?';
            k = 1;
        }
        pending.erase(0, k);
        uint8_t mods = have_vt ? vt_mods : 0;
        if (mods & kAlt)
            push(MakeAltChar(cp, mods));
        else
            push(MakeChar(cp, mods & kShift));
        return true;
    }

    pending.erase(0, 1);
    uint8_t mods = have_vt ? vt_mods : 0;
    switch (c) {
    case 0x7F:
        push(Make(8, 0x0E, mods & ~kCtrl));
        break;
    case 0x08:
        push(Make(127, 0x0E, kCtrl)); // Ctrl+Backspace у xterm
        break;
    case 0x0D:
        push(mods & kCtrl ? Make(10, 0x1C, mods) : Make(13, 0x1C, mods));
        break;
    case 0x0A:
        push(Make(10, 0x24, kCtrl));
        break;
    case 0x09:
        push(mods & kShift ? MakeSpecial(kShiftTab, mods) : Make(9, 0x0F, mods));
        break;
    case 0x00:
        break;
    default:
        if (c < 0x20)
            push(Make(c, 0, (uint8_t)(mods | kCtrl)));
        else if (mods & kAlt)
            push(MakeAltChar(c, mods));
        else
            push(Make(c, 0, mods & kShift));
        break;
    }
    return true;
}

void pump() {
    if (!keyboard_on)
        return;
    read_available();
    bool timed_out = !pending.empty() && now_ms() - pending_since > 30;
    while (!pending.empty()) {
        if (!parse_one(timed_out))
            break;
        pending_since = now_ms();
    }
}

const int kAnsiColor[8] = {0, 4, 2, 6, 1, 5, 3, 7};

void sgr(std::string& s, uint8_t attr) {
    int fg = attr & 0x0F, bg = (attr >> 4) & 0x0F;
    char buf[32];
    std::snprintf(buf, sizeof buf, "\x1b[0;%d;%dm",
                  fg < 8 ? 30 + kAnsiColor[fg] : 90 + kAnsiColor[fg - 8],
                  bg < 8 ? 40 + kAnsiColor[bg] : 100 + kAnsiColor[bg - 8]);
    s += buf;
}

void place_cursor(std::string& s) {
    char buf[32];
    std::snprintf(buf, sizeof buf, "\x1b[%d;%dH", cursor_y + 1, cursor_x + 1);
    s += buf;
    if (cursor_type == Cursor::Hidden)
        s += "\x1b[?25l";
    else {
        s += cursor_type == Cursor::Block ? "\x1b[2 q" : "\x1b[4 q";
        s += "\x1b[?25h";
    }
}

void restore_terminal() {
    if (video_on) {
        // kitty -- снять флаги, xterm -- modifyOtherKeys; курсор, буфер.
        if (mouse_on)
            out(kMouseOff);
        out("\x1b[<u\x1b[>4;0m\x1b[0m\x1b[0 q\x1b[?25h\x1b[?1049l");
        video_on = false;
    }
    raw_mode(false);
}

void on_fatal(int sig) {
    restore_terminal();
    signal(sig, SIG_DFL);
    raise(sig);
}

} // namespace

void InitVideo() {
    if (video_on)
        return;
    video_on = true;
    last_valid = false;
    out("\x1b[?1049h\x1b[H\x1b[2J");
    // Различать Ctrl+[ и Esc, Ctrl+M и Enter: xterm (modifyOtherKeys) и
    // kitty (протокол клавиатуры). Кто не умеет -- промолчит.
    out("\x1b[>4;2m\x1b[>1u");
    if (mouse_on)
        out(kMouseOn);
    struct sigaction sa = {};
    sa.sa_handler = on_winch;
    sigaction(SIGWINCH, &sa, nullptr);
    signal(SIGTERM, on_fatal);
    signal(SIGHUP, on_fatal);
    signal(SIGSEGV, on_fatal);
    signal(SIGABRT, on_fatal);
}

void DoneVideo() {
    restore_terminal();
}

void UpdateScreen(const Cell* cells) {
    if (!video_on)
        return;
    if (resized) {
        resized = 0;
        last_valid = false;
        out("\x1b[0m\x1b[2J");
    }
    std::string s;
    int cur_attr = -1;
    int pos = -1;
    for (int y = 0; y < kHeight; y++)
        for (int x = 0; x < kWidth; x++) {
            int i = y * kWidth + x;
            if (last_valid && last[i].ch == cells[i].ch && last[i].attr == cells[i].attr)
                continue;
            if (pos != i) {
                char buf[24];
                std::snprintf(buf, sizeof buf, "\x1b[%d;%dH", y + 1, x + 1);
                s += buf;
            }
            if (cur_attr != cells[i].attr) {
                sgr(s, cells[i].attr);
                cur_attr = cells[i].attr;
            }
            utf8::Append(s, cells[i].ch ? cells[i].ch : U' ');
            last[i] = cells[i];
            pos = i + 1;
            if (x == kWidth - 1)
                pos = -1; // после последней колонки курсор терминала не надёжен
        }
    last_valid = true;
    place_cursor(s);
    out(s);
}

void SetCursorPos(int x, int y) {
    cursor_x = x;
    cursor_y = y;
    if (!video_on)
        return;
    std::string s;
    place_cursor(s);
    out(s);
}

void SetCursor(Cursor type) {
    cursor_type = type;
    if (!video_on)
        return;
    std::string s;
    place_cursor(s);
    out(s);
}

Cursor GetCursor() {
    return cursor_type;
}

void InitKeyboard() {
    if (keyboard_on)
        return;
    raw_mode(true);
    uint8_t m;
    vt_console = vt_shift_state(m);
    keyboard_on = true;
}

void DoneKeyboard() {
    if (!keyboard_on)
        return;
    keyboard_on = false;
    raw_mode(false);
}

KeyEvent PeekKey() {
    pump();
    return queue.empty() ? KeyEvent{} : queue.front();
}

KeyEvent TakeKey() {
    for (;;) {
        pump();
        if (!queue.empty()) {
            KeyEvent e = queue.front();
            queue.pop_front();
            return e;
        }
        struct pollfd p = {STDIN_FILENO, POLLIN, 0};
        poll(&p, 1, pending.empty() ? 50 : 10);
    }
}

uint8_t ShiftState() {
    pump();
    uint8_t m;
    if (vt_console && vt_shift_state(m))
        return m;
    // Эмулятор терминала о нажатых модификаторах не сообщает.
    return 0;
}

void EnableMouse(bool on) {
    if (video_on && on != mouse_on)
        out(on ? kMouseOn : kMouseOff);
    mouse_on = on;
    mouse = {};
    mouse_presses = 0;
}

MouseState GetMouse() {
    pump();
    return mouse;
}

uint8_t TakeMousePresses() {
    pump();
    const uint8_t presses = mouse_presses;
    mouse_presses = 0;
    return presses;
}

bool MousePressPending() {
    pump();
    return mouse_presses != 0;
}

} // namespace console

#endif
