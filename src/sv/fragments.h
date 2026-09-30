// fragments.h -- пользовательские замены в читаемом тексте (S_U.Load_Chf):
// файл замен из настроек, а если он не задан -- SV.CHF рядом с программой.

#ifndef SV_SV_FRAGMENTS_H
#define SV_SV_FRAGMENTS_H

#include "text/fragments.h"

#include <vector>

namespace sv {

void LoadFragments();
void UnloadFragments();
const std::vector<text::FragmentRule>& Fragments();

} // namespace sv

#endif
