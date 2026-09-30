// system.h -- то, что зависит от ОС: пути, аргументы, окружение, запуск
// программ, принтер, вывод в терминал.
//
// Пути внутри программы -- UTF-8 с родным разделителем ОС ('\' у Windows,
// '/' у Linux); с файловой системой программа говорит через
// std::filesystem::path, в который строка переводится функцией Path.

#ifndef SV_PLATFORM_SYSTEM_H
#define SV_PLATFORM_SYSTEM_H

#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

namespace sys {

namespace fs = std::filesystem;

#ifdef _WIN32
constexpr char kSeparator = '\\';
constexpr const char* kEol = "\r\n";
#else
constexpr char kSeparator = '/';
constexpr const char* kEol = "\n";
#endif

fs::path Path(std::string_view utf8);
std::string Utf8(const fs::path& path);

// Каталог программы -- с разделителем на конце.
std::string ExeDir();
// Аргументы командной строки (без имени программы), UTF-8.
std::vector<std::string> Arguments(int argc, char** argv);
std::string GetEnv(const char* name);
// Каталог для временных файлов -- с разделителем на конце.
std::string TempDir();

// Имена файлов равны? У Windows -- без учёта регистра.
bool SameFileName(std::string_view a, std::string_view b);
// Скрытый файл: у Windows -- по атрибуту, у Linux -- имя с точки.
bool IsHidden(const fs::directory_entry& entry);
// Буквы дисков (у Linux -- пусто).
std::string Drives();

// Запустить программу и дождаться конца: командная строка -- «"program"
// arguments». false -- не запустилась.
bool Run(const std::string& program, const std::string& arguments);
// Командный интерпретатор для .cmd и .bat (%COMSPEC%); у Linux -- пусто.
std::string CommandShell();

// Отдать строки на печать: у Windows -- устройство PRN (в 866, как у
// исходника), у Linux -- очередь печати lpr. Нет принтера -- ничего.
void Print(const std::vector<std::string>& lines);

// Текст в терминал, из которого запущена программа (после закрытия её
// экрана).
void WriteToTerminal(std::string_view utf8);

} // namespace sys

#endif
