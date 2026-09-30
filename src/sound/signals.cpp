// signals.cpp -- DINAMIC.PAS и V_Signal (S_U.PAS).

#include "sound/signals.h"

#include "sound/music.h"

#include <string>

namespace sound {

namespace {
bool enabled = true;
}

void SetEnabled(bool on) {
    enabled = on;
}

void Play(Signal signal) {
    if (!enabled)
        return;
    const char* music = "";
    switch (signal) {
    case Signal::Edge: music = "@2000:15"; break;
    case Signal::Error: music = "@1000:20"; break;
    case Signal::Capital: music = "@500:25"; break;
    case Signal::Space: music = "@3000:15"; break;
    case Signal::Start: music = "@1000:18 @500:18 @250:18"; break;
    case Signal::Selected: music = "@1000:150"; break;
    case Signal::Break: music = "@800:100"; break;
    case Signal::Empty: music = "@20:20"; break;
    case Signal::Indent: music = "@1000:5"; break;
    case Signal::Found: music = "@100:14"; break;
    case Signal::BreakRead: music = "@750:30 @800:30 @850:30 @900:30 @950:30 @1000:30"; break;
    case Signal::EndText: music = "@1000:40 @950:40 @900:40 @850:40 @800:40 @750:40"; break;
    case Signal::NextWindow: music = "@1000:40 @1100:40 @1000:40 @1100:40"; break;
    case Signal::NotFound: music = "@5000:20"; break;
    case Signal::Marked: music = "@1500:20"; break;
    case Signal::Block: music = "@1000:25"; break;
    case Signal::BeforeHour: music = "@1500:1"; break;
    case Signal::Hour: music = "@1500:7"; break;
    case Signal::Alarm:
        music = "@900:50 @800:50 @900:50 @800:50 @900:50 @800:50 @900:50 @800:50 @900:50 @800:50 "
                "@900:50 @800:50 @900:50 @800:50 @900:50 @800:50 @900:50 @800:50 @900:50 @800:50";
        break;
    case Signal::CodeChange: music = "@800:50"; break;
    case Signal::Dictionary: music = "@800:20 @700:20 @600:20 @500:20 @400:20"; break;
    case Signal::DictionaryStep: music = "@3500:15"; break;
    case Signal::EndLine: music = "@800:20"; break;
    }
    PlayMusic(music);
}

void Beep(int frequency, int ms) {
    if (enabled)
        PlayMusic("@" + std::to_string(frequency) + ":" + std::to_string(ms));
}

} // namespace sound
