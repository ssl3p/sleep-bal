SleepChat = SleepChat or {}
SleepChat.ChatBox = nil
SleepChat.EmojiPanel = nil

local COL_NAME = Color(1, 80, 169)
local COL_TIME = color_white

local function EnsureChatBox()
    if not IsValid(SleepChat.ChatBox) then
        SleepChat.ChatBox = vgui.Create("scChatBox")
    end
    return SleepChat.ChatBox
end

function SleepChat.OpenChat()
    local chatBox = EnsureChatBox()
    chatBox:SetVisible(true)
    chatBox.InputBox:RequestFocus()
    chatBox.FadeTime = CurTime() + 999999
    chatBox.IsTyping = true
    
    SleepChat.HideFloatingMessages()
end

function SleepChat.CloseChat()
    if IsValid(SleepChat.EmojiPanel) then
        SleepChat.EmojiPanel:Remove()
        SleepChat.EmojiPanel = nil
    end
    
    if IsValid(SleepChat.ChatBox) then
        SleepChat.ChatBox:Close()
    end
    
    SleepChat.ShowFloatingMessages()
end

hook.Add("OnPlayerChat", "sc_player_message", function(ply, text, teamChat, isDead)
    if not IsValid(ply) then return true end
    
    local chatBox = EnsureChatBox()
    chatBox:AddMessage(ply, text)
    
    SleepChat.AddFloatingMessage({color_white, text}, ply)
    
    return true
end)

hook.Add("ChatText", "sc_system_message", function(index, name, text, type)
    local chatBox = EnsureChatBox()
    
    local color = type == "joinleave" and Color(150, 150, 150) or (type == "namechange" and Color(255, 200, 100) or color_white)
    local coloredText = {color, text}
    
    chatBox:AddSystemMessage(color, text)
    SleepChat.AddFloatingMessage(coloredText)
    
    return true
end)

local oldChatAddText = chat.AddText
function chat.AddText(...)
    local args = {...}
    local chatBox = EnsureChatBox()
    
    if #args > 0 then
        chatBox:AddSystemMessage(...)
        SleepChat.AddFloatingMessage(args)
    end
    
    oldChatAddText(...)
end

hook.Add("StartChat", "sc_open", function(isTeamChat)
    SleepChat.OpenChat()
    return true
end)

hook.Add("FinishChat", "sc_close", function()
    SleepChat.CloseChat()
    return true
end)

hook.Add("HUDShouldDraw", "sc_hide_default", function(name)
    if name == "CHudChat" then
        return false
    end
end)

local lastCheckTime = 0
hook.Add("Think", "sc_escape_close", function()
    if CurTime() - lastCheckTime < 0.1 then return end
    lastCheckTime = CurTime()
    
    if IsValid(SleepChat.ChatBox) and SleepChat.ChatBox:IsVisible() then
        if gui.IsGameUIVisible() or gui.IsConsoleVisible() then
            SleepChat.CloseChat()
        end
    end
end)
