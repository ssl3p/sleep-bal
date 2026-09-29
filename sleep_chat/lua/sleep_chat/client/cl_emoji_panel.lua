SleepChat = SleepChat or {}

local PANEL = {}

function PANEL:Init()
    self:SetSize(150, 200)
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:SetDraggable(false)
    self:MakePopup()
    
    local container = vgui.Create("DPanel", self)
    container:SetPos(5, 35)
    container:SetSize(140, 160)
    container.Paint = function() end
    
    local layout = vgui.Create("DIconLayout", container)
    layout:Dock(FILL)
    layout:SetSpaceX(5)
    layout:SetSpaceY(5)
    layout:SetLayoutDir(LEFT)
    
    local EmojiMaterials = SleepChat.GetEmojiMaterials()
    
    for emojiText, emojiData in pairs(SleepChat.Emojis) do
        local btn = vgui.Create("DButton", layout)
        btn:SetSize(30, 30)
        btn:SetText("")
        btn:SetTooltip(emojiText)
        
        local mat = EmojiMaterials[emojiText]
        local size = emojiData.size
        
        local offset = (30 - size) / 2
        btn.Paint = function(s, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(35, 35, 35))
            
            if mat and not mat:IsError() then
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(offset, offset, size, size)
            end
        end
        
        btn.DoClick = function()
            if IsValid(SleepChat.ChatBox) and IsValid(SleepChat.ChatBox.InputBox) then
                local currentText = SleepChat.ChatBox.InputBox:GetText()
                SleepChat.ChatBox.InputBox:SetText(currentText .. emojiText .. " ")
                SleepChat.ChatBox.InputBox:RequestFocus()
            end
            
            if IsValid(SleepChat.EmojiPanel) then
                SleepChat.EmojiPanel:Remove()
                SleepChat.EmojiPanel = nil
            end
        end
        
        layout:Add(btn)
    end
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, Color(25, 25, 25))
    draw.SimpleText("Emojis", "sc_title", w/2, 15, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.RoundedBox(0, 10, 32, w-20, 1, Color(255, 255, 255, 100))
end

vgui.Register("scEmojiPanel", PANEL, "DFrame")
