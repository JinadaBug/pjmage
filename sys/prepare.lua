local sys = require("system")

print("[PJMage] Preparing Project: " .. sys.project .. " [" .. sys.language .. sys.standard .. "]")

sys.ensure_dir(sys.tgt_path .. "/src")
sys.ensure_dir(sys.tgt_path .. "/.pjmage")

local config = sys.tgt_path .. "/.pjmage/config.lua"
local bricks = sys.tgt_path .. "/.pjmage/bricks.lua"
local source = sys.tgt_path .. "/src/main" .. sys.src_tail

local file
file = io.open(config, "w")
if file then
    file:write([[
return {
    -- Project Metadata
    language = "]] .. sys.language .. [[",
    standard = "]] .. sys.standard .. [[",
    compiler = "]] .. sys.compiler .. [[",

    -- Compilation Settings
    product  = "]] .. sys.product .. [[", -- options: "program", "static", "dynamic"
    desktop  = ]] .. tostring(sys.desktop) .. [[,
    release  = ]] .. tostring(sys.release) .. [[,
    optimal  = ]] .. tostring(sys.optimal) .. [[,
    warnings = "]] .. sys.warnings .. [[", -- options: "none", "default", "strict"

    -- Compiler Definitions
    defines = {
        -- usage: ["MACRO"] = true/false, true to define, false to undefine
    }
}]])
    file:close()
    print("[PJMage] Created .pjmage/config.lua")
end

file = io.open(bricks, "w")
if file then
    file:write([[
return {
    -- Project Dependencies
    -- example:
    -- zlib = {                 (Package name)
    --     version = "1.3.2",   (Specify the package version)
    --     dynamic = true,      (Use static linking or dynamic linking)
    -- },
}
]])
    file:close()
    print("[PJMage] Created .pjmage/bricks.lua")
end

file = io.open(source, "w")
if file then
    file:write([[
#include <iostream>

int main(int argc, char** argv)
{
    (void)argc;
    (void)argv;
    std::cout << "Hello from ]] .. sys.project .. [[!" << std::endl;
    return 0;
}]])
    file:close()
    print("[PJMage] Created src/main" .. sys.src_tail)
end

if sys.editor == "vscode" then
    sys.ensure_dir(sys.tgt_path .. "/.vscode")
    local vscode_props = sys.tgt_path .. "/.vscode/c_cpp_properties.json"

    file = io.open(vscode_props, "w")
    if file then
        file:write([[
{
    "configurations": [
        {
            "name": "]] .. (SYS_NAME == "WINDOWS" and ("Win32" or (SYS_NAME == "LINUX" and ("Linux" or "Mac")))) .. [[",
            "includePath": [
                "${workspaceFolder}/**",
                "${workspaceFolder}/src**",
                "]] .. sys.inc_virt .. [["
            ],
            ]] .. (sys.language == "c++" and '"cppStandard": "' or '"cStandard": "') .. sys.language .. sys.standard .. '"' .. [[
        }
    ]
}]])
        file:close()
        print("[PJMage] Created .vscode/c_cpp_properties.json")
    end

    if SYS_NAME == "WINDOWS" then
        sys.ensure_dir(sys.tgt_path .. "/bat")
        local win_compile = sys.tgt_path .. "/bat/compile.bat"
        local win_combine = sys.tgt_path .. "/bat/combine.bat"

        file = io.open(win_compile, "w")
        if file then
            file:write([[
@echo off
setlocal

:: ======= SETUP ENVIRONMENT =======
echo Initializing MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul

:: ======== COMPILE PROJECT ========
mage compile

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Compilation failed
    exit /b %ERRORLEVEL%
)

:: ======= SUCCESS =======
echo [SUCCESS] Compilation Complete
endlocal]])
            file:close()
            print("[PJMage] Created bat/compile.bat")
        end

        file = io.open(win_combine, "w")
        if file then
            file:write([[
@echo off
setlocal

:: ======= SETUP ENVIRONMENT =======
echo Initializing MSVC environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul

:: ======== COMBINE PROJECT ========
mage combine

:: ==== CHECK ERROR ====
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Combination failed
    exit /b %ERRORLEVEL%
)

:: ======= SUCCESS =======
echo [SUCCESS] Combination Complete
endlocal]])
            file:close()
            print("[PJMage] Created bat/combine.bat")
        end
    end

    local vscode_tasks = sys.tgt_path .. "/.vscode/tasks.json"
    file = io.open(vscode_tasks, "w")
    if file then
        file:write([[{    
    "version": "2.0.0",

    "tasks":
    [
        {
            "label": "Compile Project",
            "type": "shell",
            "windows":
            {
                "command": "${workspaceFolder}/bat/compile.bat",
                "problemMatcher": "$msCompile"
            },

            "linux":
            {
                "command": "mage compile",
                "problemMatcher": "$gcc"
            },

            "osx":
            {
                "command": "mage compile",
                "problemMatcher": "$gcc"
            }
        },

        {
            "label": "Combine Project",
            "type": "shell",
            "windows":
            {
                "command": "${workspaceFolder}/bat/combine.bat",
                "problemMatcher": "$msCompile"
            },

            "linux":
            {
                "command": "mage combine",
                "problemMatcher": "$gcc"
            },

            "osx":
            {
                "command": "mage combine",
                "problemMatcher": "$gcc"
            }
        },

        {
            "label": "Deliver Project",
            "type": "shell",
            "command": "mage deliver"
        },

        {
            "label": "Execute Project",
            "type": "shell",
            "command": "mage execute external::true"
        },

        {
            "label": "Refresh Project",
            "type": "shell",
            "command": "mage refresh"
        },

        {
            "label": "Build Project",
            "dependsOrder": "sequence",
            "dependsOn":
            [
                "Refresh Project",
                "Compile Project",
                "Combine Project",
                "Deliver Project",
                "Execute Project"
            ],

            "group":
            {
                "kind": "build",
                "isDefault": true
            },

            "presentation":
            {
                "clear": true,
                "showReuseMessage": false
            }
        }
    ]
}
]])
        file:close()
        print("[PJMage] Created .vscode/tasks.json")
    end

    local success, result
    success, result = pcall(dofile, EXE_PATH .. "/sys/refresh.lua")
    if not success then
        error("[PJMage][Error] Environment Preparation Failure: " .. result)
    end
end

print("[PJMage] Preparation Success")