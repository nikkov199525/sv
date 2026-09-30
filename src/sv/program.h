// program.h -- общее для всей программы: каталог, файлы, сообщения об
// ошибках (S_U.PAS, E_U.V_Err).

#ifndef SV_SV_PROGRAM_H
#define SV_SV_PROGRAM_H

#include <string>

namespace sv {

constexpr const char* kVersion = "4.0";

// Каталог программы (с разделителем на конце).
extern std::string program_dir;

// Файлы программы -- в её каталоге.
constexpr const char* kBookmarkFile = "SV.VBM";
constexpr const char* kConfigFile = "SV.CFG";
constexpr const char* kIniFile = "SV.INI";
constexpr const char* kHistoryFile = "SV.LDD";
constexpr const char* kHelpFile = "SV_help.txt";
constexpr const char* kPositionsFile = "SV.LPS";
constexpr const char* kDictionaryIndex = "SV.NDX";
constexpr const char* kDictionary = "SV.DIC";
constexpr const char* kFragmentsFile = "SV.CHF";
constexpr const char* kArchiversFile = "SV.DCL";

inline std::string ProgramFile(const char* name) {
    return program_dir + name;
}

// Списки прошлых вводов в SV.LDD -- по видам ввода.
enum HistoryKind {
    kLoadHistory = 0,
    kFindHistory,
    kBlockHistory,
    kBookmarkHistory,
    kSaveHistory,
    kXltHistory,
    kDictionaryHistory,
    kBookmarkSaveHistory,
    kBookmarkLoadHistory,
    kFragmentsHistory,
};

// Сообщение об ошибке номер code (V_Err).
void ShowError(int code);

} // namespace sv

#endif
