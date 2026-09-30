// system_posix.cpp -- system.h для Linux (и других POSIX-систем).

#ifndef _WIN32

#include "platform/system.h"

#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <sys/wait.h>
#include <unistd.h>

namespace sys {

std::string ExeDir() {
    std::error_code error;
    const fs::path exe = fs::read_symlink("/proc/self/exe", error);
    if (error)
        return Utf8(fs::current_path(error)) + kSeparator;
    return Utf8(exe.parent_path()) + kSeparator;
}

std::vector<std::string> Arguments(int argc, char** argv) {
    return std::vector<std::string>(argv + (argc > 0 ? 1 : 0), argv + argc);
}

std::string GetEnv(const char* name) {
    const char* value = std::getenv(name);
    return value ? value : "";
}

bool IsHidden(const fs::directory_entry& entry) {
    const std::string name = Utf8(entry.path().filename());
    return !name.empty() && name[0] == '.' && name != "..";
}

std::string Drives() {
    return {};
}

bool Run(const std::string& program, const std::string& arguments) {
    // Командная строка -- в шелл: её так и собирают из SV.DCL.
    const std::string command = "'" + program + "' " + arguments;
    std::fflush(nullptr);
    const pid_t pid = fork();
    if (pid < 0)
        return false;
    if (pid == 0) {
        execl("/bin/sh", "sh", "-c", command.c_str(), static_cast<char*>(nullptr));
        _exit(127);
    }
    int status = 0;
    while (waitpid(pid, &status, 0) < 0 && errno == EINTR) {
    }
    return !(WIFEXITED(status) && WEXITSTATUS(status) == 127);
}

std::string CommandShell() {
    return {};
}

void Print(const std::vector<std::string>& lines) {
    FILE* printer = popen("lpr", "w");
    if (!printer)
        return;
    for (const std::string& line : lines) {
        std::fwrite(line.data(), 1, line.size(), printer);
        std::fputc('\n', printer);
    }
    pclose(printer);
}

void WriteToTerminal(std::string_view utf8) {
    std::fwrite(utf8.data(), 1, utf8.size(), stdout);
    std::fflush(stdout);
}

} // namespace sys

#endif
