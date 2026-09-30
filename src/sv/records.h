// records.h -- файлы программы из записей фиксированной длины.
//
// Раскладка записей -- паскалевская, как у исходника: файлы прежних версий
// читаются, а эти -- ими. Строковое поле -- байт длины и место на N байтов.
// Пути и прочий текст пишутся в UTF-8; короткие поля (имя закладки, время
// будильника) -- в DOS-866, если строка в неё укладывается: иначе
// кириллица занимала бы вдвое больше места. Читается и то, и другое.
//
//     SV.CFG   параметры поиска и будильники (одна запись, 2645 байт);
//     SV.LDD   списки прошлых вводов (запись на каждый вид ввода, 2560 байт);
//     SV.VBM   закладки (и внешние файлы закладок; запись 288 байт);
//     SV.LPS   последние позиции в файлах (запись 264 байта).

#ifndef SV_SV_RECORDS_H
#define SV_SV_RECORDS_H

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace sv {

struct FindOptions {
    bool forward = true;     // искать в прямом направлении
    bool match_case = false; // различать регистр
    bool from_begin = true;  // начинать с начала (а не с текущей строки)
    bool substring = true;   // искать подстроку (а не начало строки)
    bool say_position = false;
};

struct Alarm {
    bool on = false;
    std::string time;     // «ЧЧ:ММ»
    bool every_day = true; // «постоянная работа»
    std::string message;
};

// SV.CFG.
struct Config {
    FindOptions find;
    std::array<Alarm, 10> alarms;
};
std::optional<Config> ReadConfig(const std::string& file);
bool WriteConfig(const std::string& file, const Config& config);

// SV.LDD: десять прошлых вводов одного вида.
using History = std::array<std::string, 10>;
std::optional<History> ReadHistory(const std::string& file, int kind);
// Записать список kind; недостающие списки перед ним -- пустые.
bool WriteHistory(const std::string& file, int kind, const History& history);

struct Bookmark {
    std::string file;
    std::string name;
    int32_t line = 0;
    int32_t number = 0; // номер записи в SV.VBM, с единицы
};
std::vector<Bookmark> ReadBookmarks(const std::string& file);
bool WriteBookmarks(const std::string& file, const std::vector<Bookmark>& bookmarks);

struct LastPosition {
    int32_t line = 0;
    uint16_t offset = 0;
    std::string file;
};
std::vector<LastPosition> ReadLastPositions(const std::string& file);
bool WriteLastPositions(const std::string& file, const std::vector<LastPosition>& positions);

} // namespace sv

#endif
