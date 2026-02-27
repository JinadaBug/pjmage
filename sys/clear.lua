local sys = require("system")

local targets = {
    sys.obj_path,
    sys.bin_path,
    sys.txt_path,
    sys.env_path,
}

print("[PJMage] Cleaning Project: " .. sys.project)

for _, folder in ipairs(targets) do
    local cmd_line = ""
    if SYS_NAME == "WINDOWS" then
        local win_path = folder:gsub("/", "\\")
        cmd_line = string.format('if exist "%s" rmdir "%s" /Q /S', win_path, win_path)
    else
        cmd_line = string.format('rm -rf "%s"', folder)
    end
    local success = os.execute(cmd_line)
    if not success and folder:find("bin") then
        error("[PJMage][Error] Binary Folder Cleaning Failure: Check For Running Executable")
    end
end

print("[PJMage] Workspace Succesfully Cleared")