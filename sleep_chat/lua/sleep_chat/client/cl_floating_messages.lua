SleepChat = SleepChat or {}

local FloatingMessages = {}
local FloatingContainer = nil
local FLOATING_MESSAGE_DURATION = 10
local SLIDE_ANIMATION_DURATION = 0.5
local LINE_HEIGHT = 18
local MESSAGE_WIDTH = 570
local MESSAGE_HEIGHT = 50
local MESSAGE_PADDING_TOP = 15
local MESSAGE_PADDING_BOTTOM = 10
local CHAT_PADDING_LEFT = 45
local AVATAR_SIZE = 33
local AVATAR_PADDING = 6
local AVATAR_Y_OFFSET = 8
local bShowFloatingMessages = true

local SV_LOGO = Material(SleepChat.Config.ServerLogo, "smooth")

local function CreateFloatingContainer()
    if IsValid(FloatingContainer) then return FloatingContainer end
    
    FloatingContainer = vgui.Create("DPanel")
    FloatingContainer:SetPos(25, 0)
    FloatingContainer:SetSize(MESSAGE_WIDTH, ScrH())
    FloatingContainer:SetMouseInputEnabled(false)
    FloatingContainer:SetKeyboardInputEnabled(false)
    FloatingContainer:ParentToHUD()
    FloatingContainer.Paint = function() end
    
    return FloatingContainer
end

function SleepChat.AddFloatingMessage(coloredText, ply)
    local container = CreateFloatingContainer()
    
    local elements = SleepChat.ParseTextWithEmojis(coloredText)
    local lines = SleepChat.WrapTextElements(elements, MESSAGE_WIDTH - CHAT_PADDING_LEFT, "sc_message_text")
    local msgHeight = math.max(MESSAGE_HEIGHT, MESSAGE_PADDING_TOP + (#lines * LINE_HEIGHT) + MESSAGE_PADDING_BOTTOM)
    
    local msgPanel = vgui.Create("DPanel", container)
    msgPanel:SetSize(MESSAGE_WIDTH, msgHeight)
    msgPanel.expireTime = CurTime() + FLOATING_MESSAGE_DURATION
    msgPanel.alpha = 255
    msgPanel.slideStartTime = CurTime()
    msgPanel.slideEndTime = CurTime() + SLIDE_ANIMATION_DURATION
    
    if IsValid(ply) then
        local playerName = ply:Nick()
        local currentTime = os.date("%H:%M")
        
        local avatar = vgui.Create("AvatarImage", msgPanel)
        avatar:SetPos(AVATAR_PADDING, AVATAR_Y_OFFSET)
        avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
        avatar:SetPlayer(ply, 64)
        avatar:SetPaintedManually(true)
        
        msgPanel.Paint = function(s, w, h)
            local alpha = s.alpha
            draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25, alpha))
            
            SleepChat.DrawCircularImage(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, function()
                avatar:PaintManual()
            end)
            
            draw.SimpleText(currentTime, "sc_time", w - 10, AVATAR_Y_OFFSET, Color(146, 146, 142, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.SimpleText(playerName, "sc_player_name", CHAT_PADDING_LEFT, AVATAR_Y_OFFSET, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            local yOffset = 28
            for _, line in ipairs(lines) do
                SleepChat.DrawTextElements(line, CHAT_PADDING_LEFT, yOffset, "sc_message_text", alpha)
                yOffset = yOffset + LINE_HEIGHT
            end
        end
    else
        local currentTime = os.date("%H:%M")
        
        msgPanel.Paint = function(s, w, h)
            local alpha = s.alpha
            draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25, alpha))
            
            if SV_LOGO and not SV_LOGO:IsError() then
                SleepChat.DrawCircularImage(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, function()
                    surface.SetDrawColor(255, 255, 255, alpha)
                    surface.SetMaterial(SV_LOGO)
                    surface.DrawTexturedRect(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, AVATAR_SIZE)
                end)
            end
            
            draw.SimpleText(currentTime, "sc_time", w - 10, AVATAR_Y_OFFSET, Color(146, 146, 142, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
            draw.SimpleText(SleepChat.Config.ServerName, "sc_player_name", CHAT_PADDING_LEFT, AVATAR_Y_OFFSET, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            
            local yOffset = 28
            for _, line in ipairs(lines) do
                SleepChat.DrawTextElements(line, CHAT_PADDING_LEFT, yOffset, "sc_message_text", alpha)
                yOffset = yOffset + LINE_HEIGHT
            end
        end
    end
    
    table.insert(FloatingMessages, msgPanel)
    
    if #FloatingMessages > 10 then
        if IsValid(FloatingMessages[1]) then
            FloatingMessages[1]:Remove()
        end
        table.remove(FloatingMessages, 1)
    end
    
    bShowFloatingMessages = true
end

function SleepChat.HideFloatingMessages()
    bShowFloatingMessages = false
    if IsValid(FloatingContainer) then
        FloatingContainer:SetVisible(false)
    end
end

function SleepChat.ShowFloatingMessages()
    bShowFloatingMessages = true
    if IsValid(FloatingContainer) then
        FloatingContainer:SetVisible(true)
    end
end

local function UpdateFloatingMessages()
    if not IsValid(FloatingContainer) then return end
    
    FloatingContainer:SetVisible(bShowFloatingMessages)
    if not bShowFloatingMessages then return end
    
    local curTime = CurTime()
    local currentY = ScrH() - 250
    
    for i = #FloatingMessages, 1, -1 do
        local msg = FloatingMessages[i]
        
        if not IsValid(msg) or curTime > msg.expireTime then
            if IsValid(msg) then
                msg:Remove()
            end
            table.remove(FloatingMessages, i)
        else
            local timeLeft = msg.expireTime - curTime
            msg.alpha = timeLeft < 1 and math.floor(255 * timeLeft) or 255
            
            local msgHeight = msg:GetTall()
            currentY = currentY - msgHeight - 5
            
            local slideProgress = 1
            if curTime < msg.slideEndTime then
                slideProgress = (curTime - msg.slideStartTime) / SLIDE_ANIMATION_DURATION
                slideProgress = math.ease.OutCubic(slideProgress)
            end
            
            local slideOffset = (1 - slideProgress) * (ScrW() - 25)
            msg:SetPos(slideOffset, currentY)
        end
    end
end

hook.Add("Think", "sc_update_floating", UpdateFloatingMessages)

hook.Add("InitPostEntity", "sc_init_floating", function()
    CreateFloatingContainer()
end)
