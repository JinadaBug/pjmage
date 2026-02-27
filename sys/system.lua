local tgt_path = CWD_PATH
if type(ARGV.data) == "string" and ARGV.data ~= "" then
    tgt_path = CWD_PATH .. "/" .. ARGV.data
end

local exp_path = tgt_path .. "/out"
if type(ARGV.expath) == "string" and ARGV.expath ~= "" then
    if ARGV.expath:match("^/") or ARGV.expath:match("^%a:") then
        exp_path = ARGV.expath:gsub("[/\\]", "/")
    else
        exp_path = tgt_path .. "/" .. ARGV.expath:gsub("[/\\]", "/")
    end
end

local function load(path)
    local f = loadfile(path)
    return f and f() or {}
end

local function make_bool(val)
    if val == "true"  or val == "1" or val == true  then return true end
    if val == "false" or val == "0" or val == false then return false end
    return nil
end

local function pick(arg, cfg, default)
    if arg ~= nil then return arg end
    if cfg ~= nil then return cfg end
    return default
end

local valid_c   = { ["23"] = true, ["18"] = true, ["11"] = true, ["99"] = true } -- 18 preferred
local valid_cpp = { ["23"] = true, ["20"] = true, ["17"] = true, ["11"] = true } -- 20 preferred
local valid_exe = { ["msvc"] = true, ["gnu"] = true, ["clang"] = true }
local valid_wrn = { ["none"] = true, ["default"] = true, ["strict"] = true }
local basic_exe = (SYS_NAME == "WINDOWS" and "msvc") or (SYS_NAME == "LINUX" and "gnu") or (SYS_NAME == "MACOS" and "clang")

local config = load(tgt_path .. "/.pjmage/config.lua")
local bricks = load(tgt_path .. "/.pjmage/bricks.lua")
local stored = load(tgt_path .. "/.pjmage/stored.lua")

local cfg_gui = make_bool(config.desktop)
local cfg_rel = make_bool(config.release)
local cfg_opt = make_bool(config.optimal)
local cfg_lan = type(config.language) == "string"  and config.language:lower() or "c++"
local cfg_std = type(config.standard) == "string"  and config.standard:lower() or "20"
local cfg_wrn = type(config.warnings) == "string"  and config.warnings:lower() or "strict"
local cfg_exe = type(config.compiler) == "string"  and config.compiler:lower() or basic_exe

local arg_gui = make_bool(ARGV.desktop)
local arg_rel = make_bool(ARGV.release)
local arg_opt = make_bool(ARGV.optimal)
local arg_lan = type(ARGV.language) == "string" and string.lower(ARGV.language) or nil
local arg_std = type(ARGV.standard) == "string" and string.lower(ARGV.standard) or nil
local arg_wrn = type(ARGV.warnings) == "string" and string.lower(ARGV.warnings) or nil
local arg_exe = type(ARGV.compiler) == "string" and string.lower(ARGV.compiler) or nil

local compiler =
    (valid_exe[arg_exe] and arg_exe) or
    (valid_exe[cfg_exe] and cfg_exe) or
    basic_exe

local language =
    (arg_lan == "c++" or arg_lan == "c") and arg_lan or
    (cfg_lan == "c++" or cfg_lan == "c") and cfg_lan or
    "c++"

local valid = (language == "c++") and valid_cpp or valid_c
local standard =
    (valid[arg_std] and arg_std) or
    (valid[cfg_std] and cfg_std) or
    (language == "c++" and "20" or "18")

local std_lang = language .. standard

local desktop = pick(arg_gui, cfg_gui, false)
local release = pick(arg_rel, cfg_rel, false)
local optimal = pick(arg_opt, cfg_opt, false)

local warnings =
    (valid_wrn[arg_wrn] and arg_wrn) or
    (valid_wrn[cfg_wrn] and cfg_wrn) or
    "strict"

local project   = tgt_path:match("[^/\\]+$")
local separator = "@"

local src_path = tgt_path .. "/src"
local inc_path = EXE_PATH .. "/add/inc"
local lib_path = EXE_PATH .. "/add/lib"
local dll_path = EXE_PATH .. "/add/dll"

local env_path = EXE_PATH .. "/env/" .. project
local inc_virt = env_path .. "/inc"
local lib_virt = env_path .. "/lib"
local dll_virt = env_path .. "/dll"

local bin_path = EXE_PATH .. "/out/bin/" .. project
local obj_path = EXE_PATH .. "/out/obj/" .. project
local txt_path = EXE_PATH .. "/out/txt/" .. project

local inc_list = txt_path .. "/inc.txt"
local obj_list = txt_path .. "/obj.txt"
local lib_list = txt_path .. "/lib.txt"
local dll_list = txt_path .. "/dll.txt"

local src_tail = language == "c++" and ".cpp" or ".c"
local obj_tail = SYS_NAME == "WINDOWS" and ".obj" or ".o"
local exe_tail = SYS_NAME == "WINDOWS" and ".exe" or ""
local exe_name = project .. exe_tail

local splitter = SYS_NAME == "WINDOWS" and ";" or ":"
local path_var = "PATH"
if SYS_NAME == "LINUX" then
    path_var = "LD_LIBRARY_PATH"
elseif SYS_NAME == "MACOS" then
    path_var = "DYLD_LIBRARY_PATH"
end

local function ensure_dir(path)
    if SYS_NAME == "WINDOWS" then
        local winpath = path:gsub("/", "\\")
        os.execute('if not exist "' .. winpath .. '" mkdir "' .. winpath .. '" 2>nul')
    else
        os.execute('mkdir -p "' .. path .. '"')
    end
end

local function copy_file(src_file, dst_file)
    local cmd_line = ""
    if SYS_NAME == "WINDOWS" then
        local win_src = src_file:gsub("/", "\\")
        local win_dst = dst_file:gsub("/", "\\")
        cmd_line = 'copy /Y "' .. win_src .. '" "' .. win_dst .. '" >nul'
    else
        cmd_line = 'cp -f "' .. src_file .. '" "' .. dst_file .. '"'
    end
    os.execute(cmd_line)
end

local comp_flags = nil
local link_flags = nil
if compiler == "msvc" then
    comp_flags = {
        exe = "cl /nologo ",
        mod = '/c /EHsc /D"_WIN32_WINNT=0x0A00" ',
        std = "/std:" .. std_lang .. " ",
        inc = "/I ",
        out = "/Fo",

        wrn = {
            ["none"]    = "/W0 ",
            ["default"] = "/W3 ",
            ["strict"]  = "/W4 /WX "
        },

        opt = {
            [true]  = "/O2 ",
            [false] = "/Od "
        },

        rel = {
            [true]  = "",
            [false] = "/Z7 "
        },
    }

    link_flags = {
        exe = "link /nologo ",
        mod = "/SUBSYSTEM:" .. (desktop and "WINDOWS " or "CONSOLE "),
        out = "/OUT:",
    }

elseif compiler == "gnu" then
    comp_flags = {
        exe = "g" .. (language == "c++" and "++ " or "cc "),
        mod = '-c  ',
        std = "-std=" .. std_lang .. " ",
        inc = "-I ",
        out = "-o ",

        wrn = {
            ["none"]    = "-w ",
            ["default"] = "-Wall ",
            ["strict"]  = "-Wall -Wextra -Werror"
        },

        opt = {
            [true]  = "-O2 ",
            [false] = "-O0 "
        },

        rel = {
            [true]  = "",
            [false] = "-g "
        },
    }

    link_flags = {
        exe = "g" .. (language == "c++" and "++ " or "cc "),
        mod = "",
        out = "-o ",
    }

elseif compiler == "clang" then
    comp_flags = {
        exe = "clang" .. (language == "c++" and "++ " or " "),
        mod = '-c  ',
        std = "-std=" .. std_lang .. " ",
        inc = "-I ",
        out = "-o ",

        wrn = {
            ["none"]    = "-w ",
            ["default"] = "-Wall ",
            ["strict"]  = "-Wall -Wextra -Werror"
        },

        opt = {
            [true]  = "-O2 ",
            [false] = "-O0 "
        },

        rel = {
            [true]  = "",
            [false] = "-g "
        },
    }

    link_flags = {
        exe = "clang" .. (language == "c++" and "++ " or " "),
        mod = "",
        out = "-o ",
    }

end

return {
    config  = config,
    bricks  = bricks,
    stored  = stored,
    project = project,

    release = release,
    optimal = optimal,
    desktop = desktop,
    warnings = warnings,
    compiler = compiler,
    language = language,
    standard = standard,

    tgt_path = tgt_path,
    exp_path = exp_path,

    comp_flags = comp_flags,
    link_flags = link_flags,

    separator = separator,

    src_path = src_path,
    src_tail = src_tail,
    env_path = env_path,

    inc_path = inc_path,
    inc_list = inc_list,
    inc_virt = inc_virt,

    lib_path = lib_path,
    lib_list = lib_list,
    lib_virt = lib_virt,

    dll_path = dll_path,
    dll_list = dll_list,
    dll_virt = dll_virt,

    obj_path = obj_path,
    obj_list = obj_list,

    bin_path = bin_path,
    txt_path = txt_path,

    obj_tail = obj_tail,
    exe_tail = exe_tail,
    exe_name = exe_name,

    splitter = splitter,
    path_var = path_var,

    copy_file = copy_file,
    ensure_dir = ensure_dir,
}