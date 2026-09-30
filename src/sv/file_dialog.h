// file_dialog.h -- диалог выбора файла (FF.PAS, FF_WIN.PAS).

#ifndef SV_SV_FILE_DIALOG_H
#define SV_SV_FILE_DIALOG_H

#include <string>
#include <vector>

namespace sv {

// Каталог диалога: где он откроется и где закрылся (Last_Path в SV.INI).
extern std::string last_path;

// Выбрать файл по маске в каталоге last_path. change_dir -- можно ли
// уходить из каталога; нельзя -- и файл в нём один: он выбирается сразу
// (так открывается распакованный архив). Результат -- полные пути: один
// или отмеченные клавишей Ins; пусто -- ничего не выбрано. Клавиша выхода
// -- в ui::ReturnCode.
std::vector<std::string> ChooseFiles(const std::string& mask, bool change_dir = true);

// Имя с «*» или «?» -- маска: «каталог\*.txt». Выбрать по ней файл
// (каталог маски становится last_path).
bool HasWildcards(const std::string& name);
std::vector<std::string> ChooseByMask(const std::string& mask);

} // namespace sv

#endif
