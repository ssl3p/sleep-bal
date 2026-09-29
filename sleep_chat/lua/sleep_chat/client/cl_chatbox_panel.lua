SleepChat = SleepChat or {}

local PANEL = {}

local MAT_SEND = Material("sleep_chat/send.png", "smooth")
local MAT_EMOJI = Material("sleep_chat/emoji.png", "smooth")
local SV_LOGO = Material(SleepChat.Config.ServerLogo, "smooth")

local FADE_DURATION = 10
local CHAT_WIDTH = 586
local MESSAGE_WIDTH = 570
local CHAT_PADDING_LEFT = 45
local AVATAR_SIZE = 33
local AVATAR_PADDING = 6
local AVATAR_Y_OFFSET = 8
local INPUT_HEIGHT = 40
local BUTTON_SIZE = 40
local LINE_HEIGHT = 18
local MESSAGE_MIN_HEIGHT = 50
local MESSAGE_PADDING_TOP = 15
local MESSAGE_PADDING_BOTTOM = 10
local CHAT_TOP = 400
local INPUT_BOTTOM_OFFSET = 200

SleepChat.DrawCircularImage = SleepChat.DrawCircularImage or function(x, y, size, drawFunc)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)
    render.SetStencilFailOperation(STENCILOPERATION_REPLACE)
    render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
    render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NEVER)
    render.SetStencilReferenceValue(1)
    
    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    
    local centerX, centerY = x + size / 2, y + size / 2
    local radius = size / 2
    
    for i = 0, 32 do
        local angle = math.rad((i / 32) * 360)
        local nextAngle = math.rad(((i + 1) / 32) * 360)
        surface.DrawPoly({
            {x = centerX, y = centerY},
            {x = centerX + math.cos(angle) * radius, y = centerY + math.sin(angle) * radius},
            {x = centerX + math.cos(nextAngle) * radius, y = centerY + math.sin(nextAngle) * radius}
        })
    end
    
    render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
    render.SetStencilPassOperation(STENCILOPERATION_KEEP)
    render.SetStencilFailOperation(STENCILOPERATION_KEEP)
    
    drawFunc()
    
    render.SetStencilEnable(false)
end

function PANEL:Init()
    self:SetSize(600, ScrH() - 100)
    self:SetPos(25, 50)
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    
    self.Messages = {}
    self.MaxMessages = SleepChat.Config.MaxMessages
    self.FadeTime = CurTime() + FADE_DURATION
    self.IsTyping = false
    
    self:CreateChatLog()
    self:CreateInputArea()
end

function PANEL:CreateChatLog()
    local panelW, panelH = self:GetSize()
    local chatHeight = panelH - CHAT_TOP - INPUT_HEIGHT - INPUT_BOTTOM_OFFSET - 10
    
    self.ChatLog = vgui.Create("DScrollPanel", self)
    self.ChatLog:SetPos(0, CHAT_TOP)
    self.ChatLog:SetSize(CHAT_WIDTH, chatHeight)
    
    local vbar = self.ChatLog:GetVBar()
    vbar:SetWide(8)
    vbar:SetHideButtons(true)
    vbar.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(40, 40, 40, 255))
    end
    vbar.btnGrip.Paint = function(s, w, h)
        draw.RoundedBox(4, 0, 0, w, h, Color(80, 80, 80, 255))
    end
    
    self.ChatCanvas = vgui.Create("DIconLayout", self.ChatLog)
    self.ChatCanvas:Dock(BOTTOM)
    self.ChatCanvas:DockMargin(0, 0, 5, 0)
    self.ChatCanvas:SetSpaceY(2)
    self.ChatCanvas:SetSpaceX(0)
end

function PANEL:CreateInputArea()
    local inputY = select(2, self:GetSize()) - INPUT_BOTTOM_OFFSET - INPUT_HEIGHT
    
    self:CreateInputBox(inputY)
    self:CreateSendButton(inputY)
    self:CreateEmojiButton(inputY)
end

function PANEL:CreateInputBox(inputY)
    local maxLen = SleepChat.Config.MaxCar
    
    self.InputBox = vgui.Create("DTextEntry", self)
    self.InputBox:SetPos(0, inputY)
    self.InputBox:SetSize(490, INPUT_HEIGHT)
    self.InputBox:SetFont("sc_placeholder")
    self.InputBox:SetTextColor(Color(255, 255, 255))
    self.InputBox:SetDrawLanguageID(false)
    self.InputBox:SetPaintBackground(false)
    self.InputBox:SetCursor("beam")
    
    self.InputBox.OnTextChanged = function(s)
        local text = s:GetText()
        if #text > maxLen then
            s:SetText(string.sub(text, 1, maxLen))
            s:SetCaretPos(maxLen)
        end
    end
    
    self.InputBox.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
        
        if s:GetText() == "" and not s:HasFocus() then
            draw.SimpleText(SleepChat.Config.Placeholder, "sc_placeholder", 15, h/2, Color(146, 146, 142), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        
        local textLen = #s:GetText()
        local color = textLen >= maxLen and Color(255, 100, 100) or color_white
        
        s:DrawTextEntryText(color, Color(100, 150, 255), color)
    end
    
    self.InputBox.OnEnter = function(s)
        self:SendMessage(s:GetText())
    end
    
    self.InputBox.OnGetFocus = function()
        self.IsTyping = true
        self.FadeTime = CurTime() + 999999
    end
    
    self.InputBox.OnLoseFocus = function(s)
        self.IsTyping = false
        if s:GetText() == "" then
            self.FadeTime = CurTime() + FADE_DURATION
        end
    end
end

function PANEL:CreateEmojiButton(inputY)
    self.EmojiButton = vgui.Create("DButton", self)
    self.EmojiButton:SetPos(546, inputY)
    self.EmojiButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    self.EmojiButton:SetText("")
    
    self.EmojiButton.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
        surface.SetDrawColor(255, 255, 255, 200)
        surface.SetMaterial(MAT_EMOJI)
        surface.DrawTexturedRect(10, 10, 20, 20)
    end
    
    self.EmojiButton.DoClick = function()
        if IsValid(SleepChat.EmojiPanel) then
            SleepChat.EmojiPanel:Remove()
            SleepChat.EmojiPanel = nil
        else
            local chatX, chatY = self:GetPos()
            SleepChat.EmojiPanel = vgui.Create("scEmojiPanel")
            SleepChat.EmojiPanel:SetPos(chatX + 610, chatY + select(2, self:GetSize()) - 400)
        end
    end
end

function PANEL:CreateSendButton(inputY)
    self.SendButton = vgui.Create("DButton", self)
    self.SendButton:SetPos(495, inputY)
    self.SendButton:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    self.SendButton:SetText("")
    
    self.SendButton.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
        surface.SetDrawColor(255, 255, 255, 200)
        surface.SetMaterial(MAT_SEND)
        surface.DrawTexturedRect(10, 10, 20, 20)
    end
    
    self.SendButton.DoClick = function()
        self:SendMessage(self.InputBox:GetText())
    end
end

function PANEL:Paint(w, h)
    draw.SimpleText(SleepChat.Config.ServerName, "sc_server_name", 0, 375, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function PANEL:SendMessage(text)
    if text == "" or text == " " then return end
    
    self.InputBox:SetText("")
    self.InputBox:RequestFocus()
    
    RunConsoleCommand("say", text)
    
    self:Close()
end

function PANEL:AddMessage(ply, message)
    if not IsValid(ply) or not message or message == "" then return end
    
    local playerName = ply:Nick()
    local currentTime = os.date("%H:%M")
    
    local coloredText = {Color(255, 255, 255), message}
    local elements = SleepChat.ParseTextWithEmojis(coloredText)
    local lines = SleepChat.WrapTextElements(elements, MESSAGE_WIDTH - CHAT_PADDING_LEFT, "sc_message_text")
    
    local msgHeight = math.max(MESSAGE_MIN_HEIGHT, MESSAGE_PADDING_TOP + (#lines * LINE_HEIGHT) + MESSAGE_PADDING_BOTTOM)
    
    local msgPanel = vgui.Create("DPanel", self.ChatCanvas)
    msgPanel:SetSize(MESSAGE_WIDTH, msgHeight)
    
    local avatar = vgui.Create("AvatarImage", msgPanel)
    avatar:SetPos(AVATAR_PADDING, AVATAR_Y_OFFSET)
    avatar:SetSize(AVATAR_SIZE, AVATAR_SIZE)
    avatar:SetPlayer(ply, 64)
    avatar:SetPaintedManually(true)
    
    msgPanel.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
        
        SleepChat.DrawCircularImage(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, function()
            avatar:PaintManual()
        end)
        
        draw.SimpleText(currentTime, "sc_time", w - 10, AVATAR_Y_OFFSET, Color(146, 146, 142), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(playerName, "sc_player_name", CHAT_PADDING_LEFT, AVATAR_Y_OFFSET, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        local yOffset = 28
        for _, line in ipairs(lines) do
            SleepChat.DrawTextElements(line, CHAT_PADDING_LEFT, yOffset, "sc_message_text", 255)
            yOffset = yOffset + LINE_HEIGHT
        end
    end
    
    self:AddMessageToCanvas(msgPanel)
end

function PANEL:AddMessageToCanvas(msgPanel)
    table.insert(self.Messages, msgPanel)
    
    if #self.Messages > self.MaxMessages then
        if IsValid(self.Messages[1]) then
            self.Messages[1]:Remove()
        end
        table.remove(self.Messages, 1)
    end
    
    self.ChatCanvas:InvalidateLayout(true)
    self.ChatLog:GetVBar():AnimateTo(9999999, 0.1, 0, 0.5)
end

function PANEL:AddSystemMessage(...)
    local coloredText = {}
    
    for i, v in ipairs({...}) do
        if type(v) == "table" and v.r then
            table.insert(coloredText, v)
        elseif type(v) == "string" then
            table.insert(coloredText, v)
        end
    end
    
    if #coloredText == 0 then return end
    
    local currentTime = os.date("%H:%M")
    
    local elements = SleepChat.ParseTextWithEmojis(coloredText)
    local lines = SleepChat.WrapTextElements(elements, MESSAGE_WIDTH - CHAT_PADDING_LEFT, "sc_message_text")
    
    local msgHeight = math.max(MESSAGE_MIN_HEIGHT, MESSAGE_PADDING_TOP + (#lines * LINE_HEIGHT) + MESSAGE_PADDING_BOTTOM)
    
    local msgPanel = vgui.Create("DPanel", self.ChatCanvas)
    msgPanel:SetSize(MESSAGE_WIDTH, msgHeight)
    
    msgPanel.Paint = function(s, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(25, 25, 25))
        
        if SV_LOGO and not SV_LOGO:IsError() then
            SleepChat.DrawCircularImage(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, function()
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(SV_LOGO)
                surface.DrawTexturedRect(AVATAR_PADDING, AVATAR_Y_OFFSET, AVATAR_SIZE, AVATAR_SIZE)
            end)
        end
        
        draw.SimpleText(currentTime, "sc_time", w - 10, AVATAR_Y_OFFSET, Color(146, 146, 142), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        draw.SimpleText(SleepChat.Config.ServerName, "sc_player_name", CHAT_PADDING_LEFT, AVATAR_Y_OFFSET, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        
        local yOffset = 28
        for _, line in ipairs(lines) do
            SleepChat.DrawTextElements(line, CHAT_PADDING_LEFT, yOffset, "sc_message_text", 255)
            yOffset = yOffset + LINE_HEIGHT
        end
    end
    
    self:AddMessageToCanvas(msgPanel)
end

function PANEL:Think()
    if not self.IsTyping and CurTime() > self.FadeTime then
        self:SetVisible(false)
    end
end

function PANEL:Close()
    self:SetVisible(false)
    self.InputBox:SetText("")
    gui.EnableScreenClicker(false)
    self.IsTyping = false
    self.FadeTime = CurTime() + FADE_DURATION
end

vgui.Register("scChatBox", PANEL, "DFrame")
