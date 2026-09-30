// viewer.h -- окно просмотра текста (V_U.PAS): загрузка, показ, чтение,
// поиск, закладки.
//
// Файл не читается в память целиком: при загрузке строится оглавление
// строк (где начинается и сколько байтов), строка читается и раскодируется
// при обращении. Номера строк и позиции в строке -- с единицы, позиция --
// в символах.

#ifndef SV_SV_VIEWER_H
#define SV_SV_VIEWER_H

#include <array>
#include <cstdint>
#include <fstream>
#include <memory>
#include <string>
#include <string_view>
#include <vector>

namespace sv {

struct TextInfo {
    int max_width = 0;
    long max_width_line = 0;
    int min_width = 0;
    long min_width_line = 0;
    long lines = 0;
    int left_margin = 0;
};

struct DbfField {
    std::string name;
    char type = 0;
    int32_t offset = 0;
    uint8_t length = 0;
};

struct Dbf {
    std::vector<DbfField> fields;
    int32_t records = 0;
    uint16_t header_size = 0;
    uint16_t record_length = 0;
    std::string last_date;
};

class Viewer {
public:
    // Открыть файл (Install). Нет файла -- программа завершается.
    explicit Viewer(const std::string& file);
    ~Viewer();

    bool installed = false;
    std::string dir, name, ext; // путь файла: каталог (с разделителем), имя, расширение
    TextInfo info;
    long first_line = 1;
    int offset = 1;
    std::u32string find_text;
    long block_begin = 0, block_end = 0;
    long break_read_line = 0; // строка, на которой чтение останавливается
    std::unique_ptr<Dbf> dbf;
    int current_field = 1;
    long lines = 0; // строк в тексте (у базы -- записей)
    int left = 1, top = 2, right = 80, bottom = 25;

    std::string Path() const { return dir + name + ext; }
    bool IsDbf() const { return dbf != nullptr; }

    void Load(const std::string& file);
    // Строка num текста -- как её видит пользователь: раскодированная,
    // без управляющих символов, с заменами.
    std::u32string Line(long num);
    std::string LineUtf8(long num);

    void SetPosition(int l, int t, int r, int b);
    void Show();
    void Next(long step);
    void Last(long step);
    void ReadLine();
    void ReadText();
    void GotoLine();
    void Find(bool continue_search);
    void SetWindow();
    void Bookmarks();
    // Закрыть окно: запомнить позицию, удалить временный файл.
    void Close();

private:
    struct LineRef {
        int64_t offset;
        uint32_t length;
    };
    std::vector<LineRef> index_;
    std::ifstream file_;
    bool converted_ = false; // текст -- временный файл из .DOC или .HTM
    std::array<unsigned char, 256> user_table_{};
    bool user_table_loaded_ = false;
    std::string user_table_file_;

    bool LoadDbf(const std::string& file);
    void LoadUserTable();
    std::string RawLine(long num);
    bool AddBookmark();
    void ChangeBookmark(int32_t number);
    bool DeleteBookmark(int32_t number);
};

// Окна 1..9 (у пустого -- nullptr) и текущее.
extern std::array<std::unique_ptr<Viewer>, 10> viewers;
extern int current_window;
inline Viewer* CurrentViewer() {
    return viewers[current_window].get();
}

// Название типа поля DBF: «символьный», «числовой»...
const char* DbfTypeName(char type);
// Строка -- начало абзаца: отступ пробелами, но не больше девяти и не
// перед тире.
bool IsIndent(std::u32string_view line);

} // namespace sv

#endif
