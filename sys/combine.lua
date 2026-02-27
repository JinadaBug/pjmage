local sys = require("system")

sys.ensure_dir(sys.bin_path)

local line = ""
line = line .. sys.link_flags.exe
line = line .. sys.link_flags.mod
line = line .. sys.link_flags.out .. '"' .. sys.bin_path .. "/" .. sys.exe_name .. '" '
line = line .. '@"' .. sys.obj_list .. '" '
line = line .. '@"' .. sys.lib_list .. '"'

local libraries = {}
for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.lib then
        table.insert(libraries, { name = name .. sys.separator .. vers, file = data.lib })
    end
end

for _, library in ipairs(libraries) do
    line = line .. '"' .. sys.lib_path .. "/" .. library.name .. "/" .. library.file .. '" '
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