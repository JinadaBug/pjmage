-- System Folder
local sys_path = EXE_PATH .. "/sys/"

-- Execution Result
local success, result

-- Clear Phase
success, result = pcall(dofile, sys_path .. "clear.lua")
if not success then
    error("[PJMage][Error] Build Aborted: " .. result)
end

-- Refresh Phase
success, result = pcall(dofile, sys_path .. "refresh.lua")
if not success then
    error("[PJMage][Error] Build Aborted: " .. result)
end

-- Compile Phase
success, result = pcall(dofile, sys_path .. "compile.lua")
if not success then
    error("[PJMage][Error] Build Aborted: " .. result)
end

-- Combine Phase
success, result = pcall(dofile, sys_path .. "combine.lua")
if not success then
    error("[PJMage][Error] Build Aborted: " .. result)
end

-- Execute Phase
success, result = pcall(dofile, sys_path .. "execute.lua")
if not success then
    error("[PJMage][Error] Build Aborted: " .. result)
end