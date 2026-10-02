// app.h -- главный цикл программы и её команды (S_U.PAS, E_U.PAS).

#ifndef SV_SV_APP_H
#define SV_SV_APP_H

#include <string>
#include <string_view>

namespace sv {

// Завершить программу: 0 -- обычный выход, остальное -- причина.
[[noreturn]] void Stop(int code);
// Главный цикл: клавиши окна текста. read_first -- сначала прочитать
// текст (ключ /r).
void MainLoop(bool read_first);

// «Свободная память» -- для строки состояния и Alt+M.
long long FreeMemory();

// Чтение (E_U.ReadTxt): с текущего окна, при «читать все окна» -- дальше.
void ReadWindows();
// Произносить все символы на время чтения (Ctrl+O) -- Symb_On/Symb_Off.
void AllSymbolsOn();
void AllSymbolsOff();

// Пустая строка или абзац ниже (forward) или выше.
void FindEmpty(bool forward);
void FindIndent(bool forward);

void SayLineNumber();
void SayOffset();
void SayPercent();
void SayFreeMemory();
void SayCode();

// Сигнал точного времени и будильники -- вызываются при ожидании клавиши
// и во время чтения.
void TimeControl();
void VerifyAlarms();

void LoadNewFile();
void CloseWindow();
void WindowList();
void Statistics();
void HelpTopics();
void CleanBookmarks();
void SaveAs();
void ChooseUserDecode();
void ChooseFragments();
void Translate(const std::string& word);
void Print();
void PrintBlock();
void TempoFaster();
void TempoSlower();
// Ускорение речи (Ctrl+Alt+] и Ctrl+Alt+[).
void AccelFaster();
void AccelSlower();
// Паузы между фразами (Ctrl+Shift+] и Ctrl+Shift+[).
void PauseLonger();
void PauseShorter();
void BlockBegin();
void BlockEnd();
void BlockRead();
void BlockHide();
void BlockWrite();
void BlockTime();
void RestTime();

// Определение кодировки строки (E_U.Detect_Code): 0 -- не определена,
// 1 -- DOS, 2 -- Windows, 3 -- KOI8, 4 -- UTF-8, 0xFF -- латиница.
int DetectCode(std::string_view line);

} // namespace sv

#endif
