local sys = require("system")

local runtimes = { sys.bin_path }
for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.dll then
        table.insert(runtimes, sys.dll_path .. "/" .. name .. sys.separator .. vers)
    end
end

local env_path = os.getenv(sys.path_var) or ""
local env_line = table.concat(runtimes, sys.splitter)
if env_path ~= "" then
    env_line = env_line .. sys.splitter .. env_path
end

local cmd_line = ""
if SYS_NAME == "WINDOWS" then
    local win_bin = string.gsub(sys.bin_path, "/", "\\")
    local win_env = string.gsub(env_line, "/", "\\")
    cmd_line = string.format('set "%s=%s" && cd /d "%s" && "%s"', sys.path_var, win_env, win_bin, sys.exe_name)
else
    cmd_line = string.format('export %s="%s" && cd "%s" && ./%s', sys.path_var, env_line, sys.bin_path, sys.exe_name)
end

print("[PJMage] Launching: " .. sys.exe_name)
local success = os.execute(cmd_line)
if not success then error("[PJMage][Error] Execution Failure")
else
    print("[PJMage] Execution Success")
end