-- Outside Install Script
local base = "https://raw.githubusercontent.com/gmiz42/ATM10-cc-tweaked-Draconic-Evolition-Reactor-Monitoring-System/main/"

local files = {
    { base .. "monitor/monitor.lua", "monitor.lua" },
    { base .. "monitor/config_monitor.lua", "config_monitor.lua" },
}

for _, f in ipairs(files) do
    local url, name = f[1], f[2]
    print("Downloading " .. name .. " ...")
    shell.run("wget", url, name)
end

print("Installation complete.")
print("Rename monitor.lua to startup.lua if you want auto‑start.")
