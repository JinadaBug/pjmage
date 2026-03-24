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
for name, meta in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][meta.version]
    if data and data.lib and meta.dynamic then
        table.insert(libraries, '"' .. sys.lib_path .. "/" .. name .. sys.separator .. meta.version .. "/" .. data.lib.dynamic .. '"')
    elseif data and data.lib then
        table.insert(libraries, '"' .. sys.lib_path .. "/" .. name .. sys.separator .. meta.version .. "/" .. data.lib.static .. '"')
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