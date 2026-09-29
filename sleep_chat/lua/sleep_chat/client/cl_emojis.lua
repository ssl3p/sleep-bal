SleepChat = SleepChat or {}
SleepChat.Emojis = {
    [":sleep:"] = {material = "sleep_chat/sleep.png", size = 18},
    [":declay:"] = {material = "sleep_chat/server_logo.png", size = 18},
    [":alloselem:"] = {material = "sleep_chat/alloselem.jpg", size = 18},
    [":annonce:"] = {material = "sleep_chat/annonce.png", size = 18},

    [":unhappy:"] = {material = "icon16/emoticon_unhappy.png", size = 16},
    [":surprised:"] = {material = "icon16/emoticon_surprised.png", size = 16},
    [":exclamation:"] = {material = "icon16/exclamation.png", size = 16},
    [":information:"] = {material = "icon16/information.png", size = 16},
    [":)"] = {material = "icon16/emoticon_smile.png", size = 16},
    [":D"] = {material = "icon16/emoticon_happy.png", size = 16},
    [":O"] = {material = "icon16/emoticon_surprised.png", size = 16},
    [":p"] = {material = "icon16/emoticon_tongue.png", size = 16},
    [":P"] = {material = "icon16/emoticon_tongue.png", size = 16},
    [":("] = {material = "icon16/emoticon_unhappy.png", size = 16},
}

local EmojiMaterials = {}
local EmojiOrder = {}

for emoji, data in pairs(SleepChat.Emojis) do
    EmojiMaterials[emoji] = Material(data.material, "smooth")
    table.insert(EmojiOrder, emoji)
end

table.sort(EmojiOrder, function(a, b) return #a > #b end)

function SleepChat.ParseTextWithEmojis(coloredText)
    local elements = {}
    local currentColor = Color(255, 255, 255)
    
    for i, v in ipairs(coloredText) do
        if type(v) == "table" and v.r then
            currentColor = v
        elseif type(v) == "string" then
            local pos = 1
            local len = #v
            
            while pos <= len do
                local nearestStart, nearestEmoji, nearestEnd
                
                for _, emoji in ipairs(EmojiOrder) do
                    local s, e = string.find(v, emoji, pos, true)
                    if s and (not nearestStart or s < nearestStart) then
                        nearestStart = s
                        nearestEnd = e
                        nearestEmoji = emoji
                    end
                end
                
                if nearestStart then
                    if nearestStart > pos then
                        table.insert(elements, {
                            type = "text",
                            text = string.sub(v, pos, nearestStart - 1),
                            color = currentColor
                        })
                    end
                    
                    table.insert(elements, {type = "emoji", emoji = nearestEmoji})
                    pos = nearestEnd + 1
                else
                    local remaining = string.sub(v, pos)
                    if #remaining > 0 then
                        table.insert(elements, {
                            type = "text",
                            text = remaining,
                            color = currentColor
                        })
                    end
                    break
                end
            end
        end
    end
    
    return elements
end

function SleepChat.WrapTextElements(elements, maxWidth, font)
    local lines = {}
    local currentLine = {}
    local currentWidth = 0
    
    surface.SetFont(font)
    
    for _, elem in ipairs(elements) do
        if elem.type == "text" then
            local text = elem.text
            local words = string.Explode(" ", text)
            
            for wordIdx, word in ipairs(words) do
                if wordIdx > 1 then
                    local spaceWidth = surface.GetTextSize(" ")
                    if currentWidth + spaceWidth > maxWidth and #currentLine > 0 then
                        table.insert(lines, currentLine)
                        currentLine = {}
                        currentWidth = 0
                    else
                        table.insert(currentLine, {type = "text", text = " ", color = elem.color})
                        currentWidth = currentWidth + spaceWidth
                    end
                end
                
                local wordWidth = surface.GetTextSize(word)
                
                if currentWidth + wordWidth > maxWidth and #currentLine > 0 then
                    table.insert(lines, currentLine)
                    currentLine = {}
                    currentWidth = 0
                end
                
                table.insert(currentLine, {type = "text", text = word, color = elem.color})
                currentWidth = currentWidth + wordWidth
            end
        elseif elem.type == "emoji" then
            local emojiData = SleepChat.Emojis[elem.emoji]
            if emojiData then
                local elemWidth = emojiData.size + 2
                
                if currentWidth + elemWidth > maxWidth and #currentLine > 0 then
                    table.insert(lines, currentLine)
                    currentLine = {}
                    currentWidth = 0
                end
                
                table.insert(currentLine, elem)
                currentWidth = currentWidth + elemWidth
            end
        end
    end
    
    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end
    
    return lines
end

function SleepChat.DrawTextElements(line, startX, startY, font, alpha)
    local xOffset = 0
    alpha = alpha or 255
    
    for _, elem in ipairs(line) do
        if elem.type == "text" then
            draw.SimpleText(elem.text, font, startX + xOffset, startY, Color(elem.color.r, elem.color.g, elem.color.b, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            surface.SetFont(font)
            local tw = surface.GetTextSize(elem.text)
            xOffset = xOffset + tw
        elseif elem.type == "emoji" then
            local emojiData = SleepChat.Emojis[elem.emoji]
            local mat = EmojiMaterials[elem.emoji]
            
            if mat and not mat:IsError() and emojiData then
                surface.SetDrawColor(255, 255, 255, alpha)
                surface.SetMaterial(mat)
                local size = emojiData.size
                
                if font then
                    surface.SetFont(font)
                    local _, textHeight = surface.GetTextSize("A")
                    local emojiYOffset = startY + (textHeight - size) / 2
                    surface.DrawTexturedRect(startX + xOffset, emojiYOffset, size, size)
                else
                    surface.DrawTexturedRect(startX + xOffset, startY, size, size)
                end
                
                xOffset = xOffset + size + 2
            end
        end
    end
    
    return xOffset
end

SleepChat.GetEmojiMaterials = function() return EmojiMaterials end
