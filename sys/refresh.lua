local sys = require("system")

local function create_link(link_path, target_path)
    if SYS_NAME == "WINDOWS" then
        local win_link = link_path:gsub("/", "\\")
        local win_target = target_path:gsub("/", "\\")
        local cmd = string.format('mklink /J "%s" "%s"', win_link, win_target)
        local result = os.execute(cmd)
        if not result then error("[PJMage][Error] Junction Creation Failure") end
    else
        local cmd = string.format('ln -s "%s" "%s"', target_path, link_path)
        local result = os.execute(cmd)
        if not result then error("[PJMage][Error] Junction Creation Failure") end
    end
end

local function remove_link(path)
    if SYS_NAME == "WINDOWS" then
        local win_path = path:gsub("/", "\\")
        local cmd = string.format('if exist "%s" rmdir "%s" /Q /S', win_path, win_path)
        local result = os.execute(cmd)
        if not result then error("[PJMage][Error] Junction Deletion Failure") end
    else
        local cmd = string.format('rm -rf "%s"', path)
        local result = os.execute(cmd)
        if not result then error("[PJMage][Error] Junction Deletion Failure") end
    end
end

print("[PJMage] Refreshing Environment For Project: " .. sys.project)
remove_link(sys.env_path)
sys.ensure_dir(sys.inc_virt)
sys.ensure_dir(sys.lib_virt)
sys.ensure_dir(sys.dll_virt)

for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.inc then create_link(sys.inc_virt .. "/" .. name, sys.inc_path .. "/" .. package) end
    if data and data.lib then create_link(sys.lib_virt .. "/" .. name, sys.lib_path .. "/" .. package) end
    if data and data.dll then create_link(sys.dll_virt .. "/" .. name, sys.dll_path .. "/" .. package) end
end

print("[PJMage] Environment Was Succesfully Refreshed")