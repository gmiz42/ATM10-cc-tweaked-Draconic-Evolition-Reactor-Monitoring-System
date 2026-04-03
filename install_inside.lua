-- Inside Install Script
local base = "https://raw.githubusercontent.com/gmiz42/ATM10-cc-tweaked-Draconic-Evolition-Reactor-Monitoring-System/main/"

local files = {
    { base .. "inside/startup.lua", "startup.lua" },
    { base .. "inside/config_inside.lua", "config_inside.lua" },
}

for _, f in ipairs(files) do
    local url, name = f[1], f[2]
    print("Downloading " .. name .. " ...")
    shell.run("wget", url, name)
end

print("Installation complete.")
