// test_units.cpp -- проверки текстовых модулей, кодировок, путей и файлов
// записей.

#include "platform/system.h"
#include "sv/app.h"
#include "sv/records.h"
#include "text/encoding.h"
#include "text/fragments.h"
#include "text/strings.h"
#include "text/unicode.h"
#include "text/utf8.h"
#include "text/words.h"

#include <cstdio>
#include <filesystem>
#include <fstream>
#include <string>

namespace fs = std::filesystem;

static int failures = 0;

#define CHECK(cond)                                                                            \
    do {                                                                                       \
        if (!(cond)) {                                                                         \
            std::printf("FAIL %s:%d: %s\n", __FILE__, __LINE__, #cond);                        \
            failures++;                                                                        \
        }                                                                                      \
    } while (0)

static std::string Encode(std::string_view utf8, text::Encoding encoding) {
    std::string bytes;
    for (char32_t c : utf8::Decode(utf8)) {
        const int b = text::FromUnicode(encoding, c);
        bytes += static_cast<char>(b < 0 ? '?' : b);
    }
    return bytes;
}

static void TestStrings() {
    CHECK(text::Width("Привет, мир") == 11);
    CHECK(text::Left("абвгдеж", 5) == "абвгд");
    CHECK(text::Right("абвгдеж", 2) == "еж");
    CHECK(text::Mid("Привет, мир", 8) == "мир");
    CHECK(text::PadRight("ёж", 4) == "ёж  ");
    CHECK(text::Trim("  а б  ") == "а б");
    CHECK(text::IsBlank("   ") && !text::IsBlank(" а "));
    CHECK(text::CollapseSpaces(" а  б   в ") == " а б в ");
    CHECK(text::EqualNoCase("ПРИВІТ, ÉTÉ", "привіт, été"));
    CHECK(text::ParseInt("123") == 123);
    CHECK(text::ParseInt("  42") == 42);
    CHECK(!text::ParseInt("12x"));
    CHECK(!text::ParseInt(""));
    CHECK(text::FormatNumber(16777216) == "16.777.216");
    CHECK(text::FormatNumber(999) == "999");
    CHECK(text::FormatNumber(-1234, 0) == "-1234");
}

static void TestEncodings() {
    // Украинские буквы 866 программы -- на местах F6..F9, Є и Ї -- F2, F4.
    const std::string ukrainian = "Ґанок, їжак, Єва, Іван";
    const std::string dos = Encode(ukrainian, text::Encoding::Dos866);
    CHECK(dos.find('?') == std::string::npos);
    CHECK(static_cast<unsigned char>(dos[0]) == 0xF8);
    CHECK(text::ToUtf8(dos, text::Encoding::Dos866) == ukrainian);
    CHECK(text::FromUnicode(text::Encoding::Dos866, U'Ё') == 0xF0);
    CHECK(text::FromUnicode(text::Encoding::Dos866, U'█') == 0xDB);
    CHECK(text::FromUnicode(text::Encoding::Dos866, U'界') == -1);

    const std::string sample = "Съешь же ещё этих мягких булок.";
    for (text::Encoding e : {text::Encoding::Dos866, text::Encoding::Windows1251, text::Encoding::Koi8R})
        CHECK(text::ToUtf8(Encode(sample, e), e) == sample);
    CHECK(text::Decode(std::string("\x97", 1), text::Encoding::Koi8R) == U"≈");
    // Метка порядка байтов пропускается только одна, в самом начале.
    CHECK(text::Decode("\xEF\xBB\xBF\xEF\xBB\xBF" "A", text::Encoding::Utf8) == U"\uFEFFA");
    // Строки старых файлов: UTF-8 -- как есть, иначе -- из старой кодировки.
    CHECK(text::LegacyToUtf8("C:\\中文\\Каталог", text::Encoding::Windows1251) == "C:\\中文\\Каталог");
    CHECK(text::LegacyToUtf8("C:\\\xCA\xE0\xF2\xE0\xEB\xEE\xE3", text::Encoding::Windows1251) == "C:\\Каталог");
}

static void TestUtf8() {
    const std::u32string text = U"Українська, 中文, 🙂";
    CHECK(utf8::Decode(utf8::Encode(text)) == text);
    CHECK(utf8::Length("中文🙂") == 3);
    CHECK(utf8::Left("中文🙂", 2) == "中文");
    CHECK(utf8::Decode("\xD0") == U"\uFFFD");

    utf8::Validator validator;
    std::string prefix(65535, 'a');
    prefix += '\xD0'; // первый байт «П» -- в конце первого блока
    CHECK(validator.Feed(prefix));
    CHECK(!validator.Valid());
    CHECK(validator.Feed("\x9F\xD1"));
    CHECK(validator.Feed("\x80"));
    CHECK(validator.Valid() && validator.HasMultibyte());

    utf8::Validator broken;
    CHECK(broken.Feed("\xD0"));
    CHECK(!broken.Feed("X"));
    CHECK(!broken.Valid());

    utf8::Validator legacy;
    CHECK(!legacy.Feed("\xA0")); // одиночный байт 866
}

static void TestUnicode() {
    CHECK(text::Upper("ёжик abc їжак") == "ЁЖИК ABC ЇЖАК");
    CHECK(text::Lower("ҐАНОК") == "ґанок");
    CHECK(text::FoldCase(U"ПРИВІТ, ΕΛΛΗΝΙΚΆ, CAFÉ") == text::FoldCase(U"привіт, ελληνικά, café"));
    CHECK(text::IsUpper(U'Є') && !text::IsUpper(U'є') && !text::IsUpper(U'1'));
}

static void TestFragments() {
    const auto rules = text::ParseFragmentRules("@#ПРИВІТ#\n^您好^\n#中文#\n^世界^\n");
    CHECK(rules.size() == 2);
    CHECK(text::ApplyFragmentRules(U"Привіт, 中文!", rules) == U"您好, 世界!");
    // Замена может стоять и перед образцом.
    const auto reversed = text::ParseFragmentRules("^б^\r\n#а#\r\n");
    CHECK(text::ApplyFragmentRules(U"мама", reversed) == U"мбмб");
}

static void TestWords() {
    const std::u32string line = U"Раз, два  три.";
    const text::WordBounds next = text::FindWord(line, 1, text::WordStep::Next);
    CHECK(next.left == 6 && next.right == 9);
    const text::WordBounds previous = text::FindWord(line, 11, text::WordStep::Previous);
    CHECK(previous.left == 6 && previous.right == 9);
    CHECK(!text::FindWord(line, 11, text::WordStep::Next) == false);
    const text::WordBounds interval = text::FindInterval(line, 1);
    CHECK(interval.left == 6);
}

static void TestDetectCode() {
    const std::string sample = "Съешь же ещё этих мягких французских булок, да выпей чаю.";
    CHECK(sv::DetectCode("Первая строка текста.") == 4);
    CHECK(sv::DetectCode(Encode("Первая строка текста.", text::Encoding::Dos866)) == 1);
    CHECK(sv::DetectCode(Encode(sample, text::Encoding::Windows1251)) == 2);
    CHECK(sv::DetectCode(Encode(sample, text::Encoding::Koi8R)) == 3);
    CHECK(sv::DetectCode("Plain latin text here.") == 0xFF);
    CHECK(sv::DetectCode("   ") == 0);
}

static void TestUnicodePath() {
    const std::string name = "sv_path_中文🙂.txt";
    {
        std::ofstream out(sys::Path(name), std::ios::binary);
        CHECK(out.is_open());
        out << "UTF-8 path";
    }
    bool seen = false;
    for (const auto& entry : fs::directory_iterator("."))
        if (sys::Utf8(entry.path().filename()) == name)
            seen = true;
    CHECK(seen);
    std::ifstream in(sys::Path(name), std::ios::binary);
    std::string line;
    std::getline(in, line);
    CHECK(line == "UTF-8 path");
    in.close();
    CHECK(sys::SameFileName(name, name));
#ifdef _WIN32
    CHECK(sys::SameFileName("SV_PATH_中文🙂.TXT", name));
#endif
    CHECK(fs::remove(sys::Path(name)));
}

static void TestRecords() {
    const std::string dir = sys::Utf8(fs::temp_directory_path() / "sv_records_test");
    fs::create_directories(sys::Path(dir));
    const std::string file = dir + sys::kSeparator;

    sv::Config config;
    config.find.match_case = true;
    config.alarms[2] = {true, "07:30", false, "Подъём! 中文"};
    CHECK(sv::WriteConfig(file + "SV.CFG", config));
    CHECK(fs::file_size(sys::Path(file + "SV.CFG")) == 2645);
    const auto read_config = sv::ReadConfig(file + "SV.CFG");
    CHECK(read_config && read_config->find.match_case && read_config->alarms[2].on);
    CHECK(read_config && read_config->alarms[2].message == "Подъём! 中文");
    CHECK(read_config && read_config->alarms[2].time == "07:30");

    sv::History history{};
    history[1] = "C:\\Тексты\\*.txt";
    CHECK(sv::WriteHistory(file + "SV.LDD", 3, history));
    CHECK(fs::file_size(sys::Path(file + "SV.LDD")) == 4 * 2560);
    const auto read_history = sv::ReadHistory(file + "SV.LDD", 3);
    CHECK(read_history && (*read_history)[1] == history[1]);
    CHECK(sv::ReadHistory(file + "SV.LDD", 0) && sv::ReadHistory(file + "SV.LDD", 0)->at(1).empty());

    const std::vector<sv::Bookmark> bookmarks = {{"C:\\中文\\книга.txt", "Глава 1", 120, 1},
                                                 {"C:\\a.txt", "中文 name", 5, 2}};
    CHECK(sv::WriteBookmarks(file + "SV.VBM", bookmarks));
    CHECK(fs::file_size(sys::Path(file + "SV.VBM")) == 2 * 288);
    const auto read_bookmarks = sv::ReadBookmarks(file + "SV.VBM");
    CHECK(read_bookmarks.size() == 2);
    CHECK(read_bookmarks.size() == 2 && read_bookmarks[0].name == "Глава 1" && read_bookmarks[0].line == 120 &&
          read_bookmarks[1].name == "中文 name" && read_bookmarks[1].file == "C:\\a.txt");

    const std::vector<sv::LastPosition> positions = {{77, 12, "C:\\中文.txt"}};
    CHECK(sv::WriteLastPositions(file + "SV.LPS", positions));
    CHECK(fs::file_size(sys::Path(file + "SV.LPS")) == 264);
    const auto read_positions = sv::ReadLastPositions(file + "SV.LPS");
    CHECK(read_positions.size() == 1 && read_positions[0].line == 77 && read_positions[0].offset == 12 &&
          read_positions[0].file == "C:\\中文.txt");

    fs::remove_all(sys::Path(dir));
}

int main() {
    TestStrings();
    TestEncodings();
    TestUtf8();
    TestUnicode();
    TestFragments();
    TestWords();
    TestDetectCode();
    TestUnicodePath();
    TestRecords();
    if (failures)
        std::printf("%d failure(s)\n", failures);
    else
        std::printf("ok\n");
    return failures ? 1 : 0;
}
