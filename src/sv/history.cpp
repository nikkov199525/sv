// history.cpp -- S_U.Old_Str_Load и Old_Str_Save.

#include "sv/history.h"

#include "text/strings.h"

namespace sv {

InputHistory::InputHistory(HistoryKind kind) : kind_(kind) {
    if (const auto read = ReadHistory(ProgramFile(kHistoryFile), kind)) {
        items = *read;
        exists = true;
        for (last = 10; last > 1; last--)
            if (!text::IsBlank(items[last - 1]))
                break;
    }
}

void InputHistory::Save(bool save, const std::string& value) {
    if (!save)
        return;
    // Места сдвигаются вниз: значение -- на второе, первое -- пустое.
    items[0] = value;
    for (int n = 9; n >= 1; n--)
        items[n] = items[n - 1];
    items[0].clear();
    exists = WriteHistory(ProgramFile(kHistoryFile), kind_, items) || exists;
}

} // namespace sv
