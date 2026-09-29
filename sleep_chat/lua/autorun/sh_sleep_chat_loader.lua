local ROOT = "sleep_chat/"

local COL_TAG = Color(150, 150, 150)
local COL_CYAN = Color(0, 255, 255)
local COL_WHITE = Color(255, 255, 255)
local COL_GREEN = Color(0, 255, 0)
local COL_YELLOW = Color(255, 255, 0)
local COL_BLUE = Color(100, 150, 255)

local function PrintHeader()
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "  _________.__                     /\\          _________                  .__              \n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, " /   _____/|  |   ____   ____ _____)/ ______  /   _____/ ______________  _|__| ____  ____  \n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, " \\_____  \\ |  | _/ __ \\_/ __ \\\\____ \\/  ___/  \\_____  \\_/ __ \\_  __ \\  \\/ /  |/ ___\\/ __ \\ \n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, " /        \\|  |_\\  ___/\\  ___/|  |_> >___ \\   /        \\  ___/|  | \\/\\   /|  \\  \\__\\  ___/ \n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "/_______  /|____/\\___  >\\___  >   __/____  > /_______  /\\___  >__|    \\_/ |__|\\___  >___  >\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "        \\/           \\/     \\/|__|       \\/          \\/     \\/                    \\/    \\/ \n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_WHITE, "\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_GREEN, "[AUTHOR] ", COL_WHITE, "Sleep (Sleep's Service)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_BLUE, "[DISCORD] ", COL_WHITE, "https://discord.gg/f6c5jc6N7D\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_YELLOW, "[BUYER] ", COL_WHITE, "Xaprix\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_WHITE, "\n")
end

local clientFiles = {}
local sharedFiles = {}
local serverFiles = {}

local function include_shared()
    if SERVER then AddCSLuaFile(ROOT .. "sh_config.lua") end
    include(ROOT .. "sh_config.lua")
    table.insert(sharedFiles, "sh_config.lua")
end

local function include_dir(sub, isClient)
    local pattern = ROOT .. sub .. "/*.lua"
    local files = file.Find(pattern, "LUA")

    for _, f in ipairs(files) do
        local path = ROOT .. sub .. "/" .. f
        if SERVER then
            if isClient then
                AddCSLuaFile(path)
                table.insert(clientFiles, f)
            else
                include(path)
                table.insert(serverFiles, f)
            end
        else
            if isClient then
                include(path)
                table.insert(clientFiles, f)
            end
        end
    end
end

PrintHeader()

include_shared()

if SERVER then
    include_dir("server", false)
    include_dir("client", true)
    
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_GREEN, "[SERVER] ", COL_WHITE, "Fichiers chargés:\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "         → Shared: ", COL_WHITE, #sharedFiles .. " fichier(s)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "         → Server: ", COL_WHITE, #serverFiles .. " fichier(s)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "         → Client: ", COL_WHITE, #clientFiles .. " fichier(s)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_GREEN, "[SERVER] ", COL_WHITE, "Sleep Chat chargé avec succès!\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_WHITE, "\n")
else
    include_dir("client", true)
    
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_BLUE, "[CLIENT] ", COL_WHITE, "Fichiers chargés:\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "         → Shared: ", COL_WHITE, #sharedFiles .. " fichier(s)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_CYAN, "         → Client: ", COL_WHITE, #clientFiles .. " fichier(s)\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_BLUE, "[CLIENT] ", COL_WHITE, "Sleep Chat chargé avec succès!\n")
    MsgC(COL_TAG, "[SLEEP - CHAT] ", COL_WHITE, "\n")
end
