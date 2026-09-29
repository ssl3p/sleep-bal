if BoiteLettre and BoiteLettre.LoaderLoaded then return end

BoiteLettre = BoiteLettre or {}
BoiteLettre.LoaderLoaded = true

local ROOT = "sleep_bal/"

local function log(msg)
    MsgC(Color(90, 160, 255), "[Sleep - BAL] ", color_white, tostring(msg) .. "\n")
end

local function print_startup_ascii()
    local lines = {
        "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠐⢚⣿⣢⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣷⣻⡑⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠚⣾⣿⣾⣧⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣷⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠘⣹⣷⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣷⣿⡿⣿⡿⡚⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⢳⣿⣿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣶⣶⣶⣶⣦⣶⣶⣶⣶⣦⣿⣿⣻⣿⣿⣿⣷⣇⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠸⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⣟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⡿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢿⠿⠟⠿⢿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣟⡁⠀⡀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⠉⠁⢀⠀⠀⠀⢹⣿⣿⣷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣿⢀⠀⠀⠀⠀⠀⢼⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣮⣀⣤⣠⣀⡤⢾⣿⣿⣿⣿⣿⣿⣿⡿⢀⣔⣀⣀⣠⣴⣾⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠠⣿⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣼⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠠⣿⣿⢿⡯⣜⠻⣿⣿⣿⣿⣿⣿⡟⠙⢿⠿⢿⡟⠋⠙⣹⣿⣿⣿⣿⣿⣿⢣⠕⡾⢿⡧⣗⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⢻⣯⡝⣙⡊⠵⢛⣿⣿⣿⣿⣿⣿⣦⡀⠁⠀⠀⣤⣾⣿⣿⣿⣿⣿⣯⡜⢃⣞⣑⠻⣇⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⠀⠀⠀⣨⣿⣿⡷⣍⣉⢺⣿⣿⣿⣿⣿⣿⣿⠷⡄⢀⠾⢿⢿⢿⢿⢿⡿⠾⡜⣓⣊⢤⡤⢿⣿⡁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⠀⠀⠀⣀⣤⣼⣿⣿⣿⣿⣿⣿⣦⢰⡱⠲⠞⠡⠼⡉⠒⠁⠀⠒⠈⠎⠢⠊⠑⣋⠋⢀⢅⣴⣟⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⢀⣤⣿⣿⣿⣿⣿⣿⣿⣼⡻⢿⣿⢿⡀⠜⠀⠠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠀⠀⡘⢼⠿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣅⢫⢉⡀⠀⠀⠠⠀⠠⠠⡀⢠⡀⠀⠀⠀⠀⠀⢈⡸⣮⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣾⣯⢷⣢⢆⡀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⡠⢐⢮⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡀⠀⠀⠀⠀⠀⠀",
        "⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣾⣤⡰⣀⠀⠀⠀⠀⠀⡀⢀⣄⣡⣿⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡄⠀⠀⠀⠀",
        "",
        "               MERCI D'UTILISER MON ADDONS <3",
        ""
    }

    for _, line in ipairs(lines) do
        MsgC(Color(170, 90, 255), line .. "\n")
    end
end

local function include_shared()
    local path = ROOT .. "sh_config.lua"
    if SERVER then
        AddCSLuaFile(path)
    end
    include(path)
end

local function include_dir(sub, isClient)
    local pattern = ROOT .. sub .. "/*.lua"
    local files = file.Find(pattern, "LUA")

    for _, f in ipairs(files) do
        local path = ROOT .. sub .. "/" .. f
        if SERVER then
            if isClient then
                AddCSLuaFile(path)
            else
                include(path)
            end
        else
            if isClient then
                include(path)
            end
        end
    end
end

include_shared()

if SERVER then
    include_dir("server", false)
    include_dir("client", true)

    AddCSLuaFile("weapons/gmod_tool/stools/mailbox_spawner.lua")

    log("loaded on SERVER")

    hook.Add("InitPostEntity", "startbanner", function()
        timer.Simple(5, function()
            print_startup_ascii()
        end)
    end)
else
    include_dir("client", true)
    log("loaded on CLIENT")
end
