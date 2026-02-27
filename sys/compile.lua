local sys = require("system")

sys.ensure_dir(sys.obj_path)
sys.ensure_dir(sys.txt_path)

local line = ""
line = line .. sys.comp_flags.exe
line = line .. sys.comp_flags.mod
line = line .. sys.comp_flags.std
line = line .. sys.comp_flags.rel[sys.release]
line = line .. sys.comp_flags.opt[sys.optimal]
line = line .. sys.comp_flags.wrn[sys.warnings]
line = line .. '@"' .. sys.inc_list .. '" '
line = line .. sys.comp_flags.inc .. ' "' .. sys.src_path .. '" '

local commands = {}
local objects = {}
local sources = GET_SRC_FILES(sys.src_path)
for _, src_file in ipairs(sources) do
    local rel_path = src_file:sub(#sys.src_path + 2)
    local obj_name = rel_path:gsub("[/\\]", sys.separator)
    local obj_file = sys.obj_path .. "/" .. obj_name .. sys.obj_tail
    table.insert(objects, '"' .. obj_file .. '"')

    local src_time = GET_FILE_TIME(src_file)
    local obj_time = GET_FILE_TIME(obj_file)
    if not obj_time or src_time > obj_time then
        if SYS_NAME == "WINDOWS" then obj_file = obj_file:gsub("/", "\\") end
        local command = line .. sys.comp_flags.out .. '"' .. obj_file .. '" "' .. src_file .. '"'
        table.insert(commands, command)
    end
end

local headers = {}
for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.inc then
        table.insert(headers, sys.comp_flags.inc .. '"' .. sys.inc_path .. "/" .. name .. sys.separator .. vers .. '"')
    end
end

local file
file = io.open(sys.inc_list, "w")
if not file then error("[PJMage][Error] Include List Opening Failure") end
file:write(table.concat(headers, "\n"))
file:close()

file = io.open(sys.obj_list, "w")
if not file then error("[PJMage][Error] Object List Opening Failure") end
file:write(table.concat(objects, "\n"))
file:close()

if #commands > 0 then
    print("[PJMage] Compiling " .. #commands .. " Files...")
    local success = SPAWN_COMPILE(commands)
    if not success then error("[PJMage][Error] Compilation Failure") end
else
    print("[PJMage] Everything is up to date.")
end