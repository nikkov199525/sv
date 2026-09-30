// history.h -- списки прошлых вводов (SV.LDD) для строк ввода с Up/Down.
//
// Как у автора: первое место списка всегда пустое (его на время ввода
// занимает текущее значение), новые значения записываются вторыми.

#ifndef SV_SV_HISTORY_H
#define SV_SV_HISTORY_H

#include "sv/program.h"
#include "sv/records.h"

#include <string>

namespace sv {

class InputHistory {
public:
    explicit InputHistory(HistoryKind kind);

    // Список прочитан (Exist_File).
    bool exists = false;
    History items{};
    // Номер последнего непустого места (1, если пусто).
    int last = 1;

    // Сохранить значение; save = false -- ничего не делать.
    void Save(bool save, const std::string& value);

private:
    HistoryKind kind_;
};

} // namespace sv

#endif
