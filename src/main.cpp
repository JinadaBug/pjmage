#include <string>
#include <iostream>
#include <filesystem>
#include <string_view>

#include <map>
#include <thread>
#include <future>
#include <vector>
#include <atomic>
#include <semaphore>
#include <lua/lua.hpp>

#if defined(_WIN32)
    #include <windows.h>
#endif

#if defined(__linux__)
    #include <unistd.h>
    #include <limits.h>
#endif

#if defined(__APPLE__)
    #include <mach-o/dyld.h>
#endif

// Filesystem Namespace
namespace fs = std::filesystem;

// PJMage Settings
namespace Config
{
    std::map<std::string, std::string> Scripts;
    std::vector<std::string> Keys;
    std::string Help_text;
    std::string Version;
}

// System Paths - Current Working Directory and the Installation Folder
namespace Path
{
    fs::path Install;
    fs::path Current;
};

// Lua Callbacks
namespace Call
{
    // Get File Timestamp (Search By Absolute Path)
    int Get_File_Time(lua_State* L)
    {
        // Get Input from Lua
        fs::path path = luaL_checkstring(L, 1);

        try
        {
            // Get The Last Write Time
            auto time = fs::last_write_time(path);
            auto system_time = std::chrono::clock_cast<std::chrono::system_clock>(time); // Unix Epoch

            // Convert To Seconds
            auto duration = system_time.time_since_epoch();
            auto seconds = std::chrono::duration_cast<std::chrono::seconds>(duration).count();

            // Push Data To Lua
            lua_pushinteger(L, static_cast<lua_Integer>(seconds));
            return 1;
        }

        // Push NIL On Error
        catch (...)
        {
            lua_pushnil(L);
            return 1;
        }
    }

    // Get Source Paths (Absolute)
    int Get_SRC_Files(lua_State* L)
    {
        // Get Input From Lua
        fs::path path = luaL_checkstring(L, 1);
        lua_newtable(L);
        int index = 1;

        try
        {
            // Search Recursively
            for (const auto& file : fs::recursive_directory_iterator(path))
            {
                // Skip if Directory
                if (!file.is_regular_file()) continue;

                // Check for C/C++ source extensions
                std::string ext = file.path().extension().string();
                if (ext == ".c" || ext == ".cpp" || ext == ".cxx" || ext == ".cc")
                {
                    // Get absolute path and push to Lua
                    std::string abs_path = fs::absolute(file.path()).generic_string();
                    lua_pushstring(L, abs_path.c_str());
                    lua_rawseti(L, -2, index++); 
                }
            }
        }

        // Filesystem Error Log
        catch (const std::exception& error)
        {
            std::cerr << "[PJMage][Error] Filesystem Error: " << error.what() << "\n";
        }

        return 1; // Return the table (even if empty)
    }

    // Spawn Compilation Tasks
    int Spawn_Compile(lua_State* L)
    {
        // Check Input
        if (!lua_istable(L, 1)) return 0;

        // Command Queue
        std::vector<std::string> commands;
        lua_pushnil(L);
        while (lua_next(L, 1) != 0)
        {
            if (lua_isstring(L, -1)) commands.push_back(lua_tostring(L, -1));
            lua_pop(L, 1);
        }

        // Check If Empty
        size_t total = commands.size();
        if (total == 0)
        {
            lua_pushboolean(L, true);
            return 1;
        }

        // Check Hardware
        unsigned int available = std::thread::hardware_concurrency();
        if (available == 0) available = 2;

        // Thread Pool
        std::counting_semaphore<256> pool(available); 

        // Progress Trackers
        std::atomic<size_t> finished{0};
        std::atomic<bool> success{true};
        std::vector<std::jthread> workers;
        workers.reserve(total);

        // Iterate through commands
        for (std::string& line : commands)
        {
            // Start Threads Within Semaphore Thread Pool
            workers.emplace_back([&, line]()
            {
                // Wait For Free Place
                pool.acquire();

                // Check Result
                int result = std::system(line.c_str());
                if (result != 0) success = false;

                // Advance
                size_t current = ++finished;

                // Progress Bar
                float percent = (static_cast<float>(current) / total) * 100.0f;
                std::cout << "[PJMage] Progress: [" << current << "/" << total << "][" << (int)percent << "%]\r" << std::flush;
                pool.release(); // Release slot for the next command
            });
        }

        // Clear Threads
        workers.clear(); 

        // Advance Console & Push Result Into Lua
        std::cout << "\n";
        lua_pushboolean(L, success.load());
        return 1;
    }
}

// C++ System Calls
namespace System
{
    // Set the OS name (Windows)
    #if defined(_WIN32)
        inline constexpr const char* OS = "WINDOWS";
    #endif

    // Set the OS name (Linux)
    #if defined(__linux__)
        inline constexpr const char* OS = "LINUX";
    #endif

    // Set the OS name (MacOS)
    #if defined(__APPLE__)
        inline constexpr const char* OS = "MACOS";
    #endif

    // Get Current and Installation Paths
    bool Get_Paths()
    {
        try
        {
            // Get the Current Working Directory (CWD)
            Path::Current = fs::current_path();

            // Buffer
            fs::path exe_path;

            // Windows Logic
            #if defined(_WIN32)
                wchar_t buffer[MAX_PATH];
                if (GetModuleFileNameW(NULL, buffer, MAX_PATH) == 0) return false;
                exe_path = buffer;
            #endif

            // Linux Logic
            #if defined(__linux__)
                char buffer[PATH_MAX];
                ssize_t count = readlink("/proc/self/exe", buffer, PATH_MAX);
                if (count == -1) return false;
                exe_path = std::string(buffer, count);
            #endif

            // MacOS Logic
            #if defined(__APPLE__)
                char buffer[1024];
                uint32_t size = sizeof(buffer);
                if (_NSGetExecutablePath(buffer, &size) != 0) return false;
                exe_path = buffer;
            #endif

            // Resolve Symlinks
            exe_path = fs::canonical(exe_path);

            // Get The Install Path
            Path::Install = exe_path.parent_path().parent_path();
            return true;
        }

        // Filesystem Error
        catch(const fs::filesystem_error& error)
        {
            std::cerr << "[PJMage][Error] Filesystem Failure " << error.code().message() << " | " << error.what() << "\n";
            return false;
        }

        // Unknown Error
        catch(const std::exception& error)
        {
            std::cerr << "[PJMage][Error] Unknown Failure: " << error.what() << '\n';
            return false;
        }
    }

    // Set Lua globals and the environment
    void Setup_Lua_Environment(lua_State* L)
    {
        // Inject OS Name
        lua_pushstring(L, System::OS);
        lua_setglobal(L, "SYS_NAME");

        // Inject Current Path
        lua_pushstring(L, Path::Current.generic_string().c_str());
        lua_setglobal(L, "CWD_PATH");

        // Inject Install Path
        lua_pushstring(L, Path::Install.generic_string().c_str());
        lua_setglobal(L, "EXE_PATH");

        // Inject Calls
        lua_register(L, "GET_FILE_TIME", Call::Get_File_Time);
        lua_register(L, "GET_SRC_FILES", Call::Get_SRC_Files);
        lua_register(L, "SPAWN_COMPILE", Call::Spawn_Compile);

        // Inject System Path
        lua_getglobal(L, "package");
        lua_getfield(L, -1, "path");
        std::string old_path = lua_tostring(L, -1);
        std::string new_path = Path::Install.generic_string() + "/sys/?.lua;" + old_path;
        lua_pop(L, 1);                       // Remove old_path string from stack
        lua_pushstring(L, new_path.c_str()); // Push new path into Lua
        lua_setfield(L, -2, "path");         // Set package.path = new_path
        lua_pop(L, 1);                       // Remove package table from stack
    }

    void Load_Core_Config(lua_State* L,
        std::map<std::string, std::string>& scripts,
        std::vector<std::string>& keys,
        std::string& help_text,
        std::string& version)
    {
        fs::path core_path = Path::Install / "sys" / "core.lua";
        if (luaL_dofile(L, core_path.generic_string().c_str()) != LUA_OK) {
            std::cerr << "[PJMage][Error] Missing Core Config: " << lua_tostring(L, -1) << "\n";
            return;
        }

        // Get Version Text
        lua_getfield(L, -1, "version");
        version = lua_tostring(L, -1);
        lua_pop(L, 1);

        // Get Scripts
        lua_getfield(L, -1, "scripts");
        lua_pushnil(L);
        while (lua_next(L, -2))
        {
            scripts[lua_tostring(L, -2)] = lua_tostring(L, -1);
            lua_pop(L, 1);
        }
        lua_pop(L, 1);

        // Get Keys
        lua_getfield(L, -1, "keys");
        int n = luaL_len(L, -1);
        for (int i = 1; i <= n; i++)
        {
            lua_rawgeti(L, -1, i);
            keys.push_back(lua_tostring(L, -1));
            lua_pop(L, 1);
        }
        lua_pop(L, 1);

        // Get Help Text
        lua_getfield(L, -1, "help");
        help_text = lua_tostring(L, -1);
        lua_pop(L, 2); // Pop help and the main table
    }
}

// Main Function
int main(int argc, char const** argv)
{
    // Get System Paths
    if (!System::Get_Paths()) return 1;

    // Open Core Config (Local Lua State)
    lua_State* L_init = luaL_newstate();
    luaL_openlibs(L_init);
    System::Load_Core_Config(L_init, Config::Scripts, Config::Keys, Config::Help_text, Config::Version);
    lua_close(L_init);

    // Default Command & Data
    std::string command = (argc >= 2) ? argv[1] : "version";;
    std::string data = "";
    std::map<std::string, std::string> metadata;

    // Cache CWD
    fs::path original = Path::Current;
    fs::path external = "";

    // Quote Strip
    auto strip_quotes = [](std::string s)
    {
        if (s.size() >= 2 && s.front() == '"' && s.back() == '"') return s.substr(1, s.size() - 2);
        return s;
    };

    // Loop through arguments
    bool found_command = false;
    for (int i = 1; i < argc; i++)
    {
        // Extract Argument
        std::string arg = argv[i];
        bool is_key = false;

        // Loop through available keys
        for (const auto& key : Config::Keys)
        {
            if (arg.starts_with(key))
            {
                // Strip quotes (if exist)
                std::string value = strip_quotes(arg.substr(key.length()));

                // Detect External Path
                if (key == "pjpath::") external = value;
                else metadata[key.substr(0, key.length() - 2)] = value;
                is_key = true;
                break;
            }
        }

        // Check Keyless Arguments
        if (!is_key)
        {
            // The first is always the command (This is required)
            if (!found_command)
            {
                command = arg;
                found_command = true;
            }

            // Every subsequent non-key argument is data (like package name)
            else data = strip_quotes(arg);
        }
    }

    // Version Command
    if (command == "version")
    {
        std::cout << "PJmage Build System: Version " << Config::Version << " [" << System::OS << "]\n";
        std::cout << "Installation: " << Path::Install.generic_string() << "\n";
        std::cout << "Current Dir:  " << Path::Current.generic_string() << "\n";
        return 0;
    }

    // Help Command
    else if (command == "help")
    {
        std::cout << Config::Help_text << std::endl;
        return 0;
    }

    // Other Commands
    if (Config::Scripts.contains(command))
    {
        // Switch Directory If Path Was Specified
        if (!external.empty())
        {
            // Change Directory
            try
            {
                fs::current_path(external);
                Path::Current = fs::current_path();
                std::cout << "[PJMage] Changed Directory: " << Path::Current.generic_string() << "\n";
            }

            // Filesystem Error Log
            catch (const fs::filesystem_error& error)
            {
                std::cerr << "[PJMage][Error] Invalid Path: " << external.generic_string() << "\n";
                return 1;
            }
        }

        // Open Lua State
        lua_State* L = luaL_newstate();
        luaL_openlibs(L);

        // Setup Lua Paths & Globals
        System::Setup_Lua_Environment(L);

        // Inject ARGV for the script
        lua_newtable(L);
        lua_pushstring(L, data.c_str()); lua_setfield(L, -2, "data");
        for (auto const& [k, v] : metadata) { lua_pushstring(L, v.c_str()); lua_setfield(L, -2, k.c_str()); }
        lua_setglobal(L, "ARGV");

        // Run the script
        fs::path script = Path::Install / "sys" / Config::Scripts[command];
        if (luaL_dofile(L, script.generic_string().c_str()) != LUA_OK)
        {
            std::cerr << "[PJMage][Error] " << lua_tostring(L, -1) << "\n";
        }

        // Close Lua State
        lua_close(L);

        // Return Back
        if (!external.empty())
        {
            // Change Directory
            try
            {
                fs::current_path(original);
                Path::Current = fs::current_path();
                std::cout << "[PJMage] Changed Directory: " << Path::Current.generic_string() << "\n";
            }

            // Filesystem Error Log
            catch (const fs::filesystem_error& error)
            {
                std::cerr << "[PJMage][Error] Invalid Path: " << original.generic_string() << "\n";
                return 1;
            }
        }

        // Success
        return 0;
    }

    // Unknown Command
    else
    {
        std::cerr << "[PJMage][Error] Unknown command: " << command << "\n";
        return -1;
    }
}