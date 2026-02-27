local sys = require("system")

print("[PJMage] Delivering '" .. sys.project .. "' into: " .. sys.exp_path)

sys.ensure_dir(sys.exp_path)
sys.copy_file(sys.bin_path .. "/" .. sys.exe_name, sys.exp_path .. "/" .. sys.exe_name)
for name, vers in pairs(sys.bricks) do
    local data = sys.stored[name] and sys.stored[name][vers]
    if data and data.dll then
        sys.copy_file(sys.dll_path .. "/" .. name .. sys.separator .. vers .. "/" .. data.dll, sys.exp_path .. "/" .. data.dll)
    end
end

print("[PJMage] Program Successfully Delivered Into: " .. sys.exp_path)