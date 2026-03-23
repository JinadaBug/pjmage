local sys = require("system")

sys.ensure_dir(sys.bin_path)
sys.ensure_dir(sys.txt_path)

local line = ""
if sys.product == "program" then
    line = line .. sys.link_flags.exe
    line = line .. sys.link_flags.mod
    line = line .. sys.link_flags.out .. '"' .. sys.bin_path .. "/" .. sys.exe_name .. '" '
    line = line .. '@"' .. sys.obj_list .. '" '
    line = line .. '@"' .. sys.lib_list .. '"'
elseif sys.product == "dynamic" then
    line = line .. sys.link_flags.exe
    line = line .. sys.link_flags.mod
    line = line .. sys.link_flags.out .. '"' .. sys.bin_path .. "/" .. sys.dll_name .. '" '
    line = line .. '@"' .. sys.obj_list .. '" '
    line = line .. '@"' .. sys.lib_list .. '"'
elseif sys.product == "static" then
    line = line .. sys.arch_flags.exe
    line = line .. sys.arch_flags.out .. '"' .. sys.bin_path .. "/" .. sys.lib_name .. '" '
    line = line .. '@"' .. sys.obj_list .. '" '
    line = line .. '@"' .. sys.lib_list .. '"'
end

local libraries = {}
for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.lib then
        table.insert(libraries, '"' .. sys.lib_path .. "/" .. name .. sys.separator .. vers .. "/" .. data.lib .. '"')
    end
end

local file
file = io.open(sys.lib_list, "w")
if not file then error("[PJMage][Error] Library List Opening Failure") end
file:write(table.concat(libraries, "\n"))
file:close()

print("[PJMage] Linking Files For Project: " .. sys.project)
local success = os.execute(line)
if not success then error("[PJMage][Error] Combination Failure")
else
    print("[PJMage] Combination Success")
end