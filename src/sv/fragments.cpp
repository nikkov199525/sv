// fragments.cpp -- S_U.Load_Chf.

#include "sv/fragments.h"

#include "platform/system.h"
#include "sv/program.h"
#include "sv/settings.h"
#include "text/strings.h"

#include <fstream>
#include <iterator>

namespace sv {

namespace {
std::vector<text::FragmentRule> rules;
}

void LoadFragments() {
    const std::string file = text::IsBlank(settings.fragments_file) ? ProgramFile(kFragmentsFile)
                                                                    : settings.fragments_file;
    std::ifstream in(sys::Path(file), std::ios::binary);
    rules = text::ParseFragmentRules(std::string(std::istreambuf_iterator<char>(in), {}));
}

void UnloadFragments() {
    rules.clear();
}

const std::vector<text::FragmentRule>& Fragments() {
    return rules;
}

} // namespace sv
