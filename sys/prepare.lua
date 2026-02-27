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
    desktop  = ]] .. tostring(sys.desktop) .. [[,
    release  = ]] .. tostring(sys.release) .. [[,
    optimal  = ]] .. tostring(sys.optimal) .. [[,
    warnings = "]] .. sys.warnings .. [[", -- options: "none", "default", "strict"
}
]])
    file:close()
    print("[PJMage] Created .pjmage/config.lua")
end

file = io.open(bricks, "w")
if file then
    file:write([[
return {
    -- Project Dependencies
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
}
]])
    file:close()
    print("[PJMage] Created src/main." .. sys.src_tail)
end

print("[PJMage] Preparation Success")