// records.cpp -- записи файлов SV.CFG, SV.LDD, SV.VBM, SV.LPS.

#include "sv/records.h"

#include "platform/system.h"
#include "text/encoding.h"
#include "text/utf8.h"

#include <algorithm>
#include <cstring>
#include <fstream>
#include <iterator>

namespace sv {

namespace {

using Bytes = std::string;

// Поле string[capacity]: байт длины и capacity байтов.
std::string GetString(const Bytes& record, size_t offset, size_t capacity) {
    const size_t length = std::min<size_t>(static_cast<unsigned char>(record[offset]), capacity);
    return text::LegacyToUtf8(record.substr(offset + 1, length), text::Encoding::Dos866);
}

// Байты строки не длиннее limit, без обрывка символа UTF-8 в конце.
std::string FitUtf8(std::string_view text, size_t limit) {
    size_t end = 0;
    for (size_t pos = 0; pos < text.size();) {
        char32_t cp;
        utf8::Next(text, pos, cp);
        if (pos > limit)
            break;
        end = pos;
    }
    return std::string(text.substr(0, end));
}

// Короткое поле: в 866, если строка в ней записывается целиком.
std::string ShortField(std::string_view text) {
    std::string legacy;
    for (char32_t cp : utf8::Decode(text)) {
        const int byte = text::FromUnicode(text::Encoding::Dos866, cp);
        if (byte < 0)
            return std::string(text);
        legacy += static_cast<char>(byte);
    }
    return legacy;
}

void PutString(Bytes& record, size_t offset, size_t capacity, const std::string& text) {
    const std::string bytes = FitUtf8(text, capacity);
    record[offset] = static_cast<char>(bytes.size());
    std::memcpy(&record[offset + 1], bytes.data(), bytes.size());
}

void PutShortString(Bytes& record, size_t offset, size_t capacity, const std::string& text) {
    std::string bytes = ShortField(text);
    if (bytes.size() > capacity)
        bytes = utf8::IsValid(bytes) ? FitUtf8(bytes, capacity) : bytes.substr(0, capacity);
    record[offset] = static_cast<char>(bytes.size());
    std::memcpy(&record[offset + 1], bytes.data(), bytes.size());
}

template<class T>
T GetInt(const Bytes& record, size_t offset) {
    T value = 0;
    for (size_t i = 0; i < sizeof(T); i++)
        value |= static_cast<T>(static_cast<unsigned char>(record[offset + i])) << (8 * i);
    return value;
}

template<class T>
void PutInt(Bytes& record, size_t offset, T value) {
    for (size_t i = 0; i < sizeof(T); i++)
        record[offset + i] = static_cast<char>((static_cast<uint32_t>(value) >> (8 * i)) & 0xFF);
}

Bytes ReadAll(const std::string& file) {
    std::ifstream in(sys::Path(file), std::ios::binary);
    return Bytes(std::istreambuf_iterator<char>(in), {});
}

bool WriteAll(const std::string& file, const Bytes& data) {
    std::ofstream out(sys::Path(file), std::ios::binary | std::ios::trunc);
    out.write(data.data(), static_cast<std::streamsize>(data.size()));
    return static_cast<bool>(out);
}

// Записи файла по size байтов (неполная последняя отбрасывается).
std::vector<Bytes> Records(const std::string& file, size_t size) {
    const Bytes data = ReadAll(file);
    std::vector<Bytes> records;
    for (size_t offset = 0; offset + size <= data.size(); offset += size)
        records.push_back(data.substr(offset, size));
    return records;
}

// ---------------------------------------------------------------- SV.CFG
// Forward, Regs, FromBegin, SubString, Say_Posit: boolean;
// Alarm: array[1..10] of record Status: boolean; Tme: string[5];
//                                EveryOnce: boolean; Message: string end.
constexpr size_t kAlarmSize = 1 + 6 + 1 + 256;
constexpr size_t kConfigSize = 5 + 10 * kAlarmSize;

// -------------------------------------------------------------- SV.LDD
constexpr size_t kHistorySize = 10 * 256;

// -------------------------------------------------------------- SV.VBM
// FileName: string; BMName: string[23]; Line, Num: longint.
constexpr size_t kBookmarkSize = 256 + 24 + 4 + 4;

// -------------------------------------------------------------- SV.LPS
// L: longint; OfS: word; FN: string (и 2 байта выравнивания).
constexpr size_t kPositionSize = 4 + 2 + 256 + 2;

} // namespace

std::optional<Config> ReadConfig(const std::string& file) {
    const Bytes data = ReadAll(file);
    if (data.size() < kConfigSize)
        return std::nullopt;
    Config config;
    config.find = {data[0] != 0, data[1] != 0, data[2] != 0, data[3] != 0, data[4] != 0};
    for (size_t i = 0; i < config.alarms.size(); i++) {
        const size_t at = 5 + i * kAlarmSize;
        Alarm& alarm = config.alarms[i];
        alarm.on = data[at] != 0;
        alarm.time = GetString(data, at + 1, 5);
        alarm.every_day = data[at + 7] != 0;
        alarm.message = GetString(data, at + 8, 255);
    }
    return config;
}

bool WriteConfig(const std::string& file, const Config& config) {
    Bytes data(kConfigSize, '\0');
    const FindOptions& f = config.find;
    data[0] = f.forward;
    data[1] = f.match_case;
    data[2] = f.from_begin;
    data[3] = f.substring;
    data[4] = f.say_position;
    for (size_t i = 0; i < config.alarms.size(); i++) {
        const size_t at = 5 + i * kAlarmSize;
        const Alarm& alarm = config.alarms[i];
        data[at] = alarm.on;
        PutShortString(data, at + 1, 5, alarm.time);
        data[at + 7] = alarm.every_day;
        PutString(data, at + 8, 255, alarm.message);
    }
    return WriteAll(file, data);
}

std::optional<History> ReadHistory(const std::string& file, int kind) {
    const std::vector<Bytes> records = Records(file, kHistorySize);
    if (kind < 0 || kind >= static_cast<int>(records.size()))
        return std::nullopt;
    History history;
    for (size_t i = 0; i < history.size(); i++)
        history[i] = GetString(records[kind], i * 256, 255);
    return history;
}

bool WriteHistory(const std::string& file, int kind, const History& history) {
    std::vector<Bytes> records = Records(file, kHistorySize);
    if (static_cast<int>(records.size()) <= kind)
        records.resize(kind + 1, Bytes(kHistorySize, '\0'));
    Bytes& record = records[kind];
    record.assign(kHistorySize, '\0');
    for (size_t i = 0; i < history.size(); i++)
        PutString(record, i * 256, 255, history[i]);
    Bytes data;
    for (const Bytes& r : records)
        data += r;
    return WriteAll(file, data);
}

std::vector<Bookmark> ReadBookmarks(const std::string& file) {
    std::vector<Bookmark> bookmarks;
    for (const Bytes& r : Records(file, kBookmarkSize))
        bookmarks.push_back({GetString(r, 0, 255), GetString(r, 256, 23), GetInt<int32_t>(r, 280),
                             GetInt<int32_t>(r, 284)});
    return bookmarks;
}

bool WriteBookmarks(const std::string& file, const std::vector<Bookmark>& bookmarks) {
    Bytes data;
    for (const Bookmark& b : bookmarks) {
        Bytes r(kBookmarkSize, '\0');
        PutString(r, 0, 255, b.file);
        PutShortString(r, 256, 23, b.name);
        PutInt(r, 280, b.line);
        PutInt(r, 284, b.number);
        data += r;
    }
    return WriteAll(file, data);
}

std::vector<LastPosition> ReadLastPositions(const std::string& file) {
    std::vector<LastPosition> positions;
    for (const Bytes& r : Records(file, kPositionSize))
        positions.push_back({GetInt<int32_t>(r, 0), GetInt<uint16_t>(r, 4), GetString(r, 6, 255)});
    return positions;
}

bool WriteLastPositions(const std::string& file, const std::vector<LastPosition>& positions) {
    Bytes data;
    for (const LastPosition& p : positions) {
        Bytes r(kPositionSize, '\0');
        PutInt(r, 0, p.line);
        PutInt(r, 4, p.offset);
        PutString(r, 6, 255, p.file);
        data += r;
    }
    return WriteAll(file, data);
}

} // namespace sv
