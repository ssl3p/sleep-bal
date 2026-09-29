BoiteLettre = BoiteLettre or {}
BoiteLettre.HighlightedIds = BoiteLettre.HighlightedIds or {}

BoiteLettre.ClientMailboxCache = BoiteLettre.ClientMailboxCache or {}
BoiteLettre.NextMailboxCacheRefresh = BoiteLettre.NextMailboxCacheRefresh or 0

BoiteLettre.GetClientMailboxes = BoiteLettre.GetClientMailboxes or function()
    if BoiteLettre.NextMailboxCacheRefresh > CurTime() then
        return BoiteLettre.ClientMailboxCache
    end

    BoiteLettre.NextMailboxCacheRefresh = CurTime() + 1
    BoiteLettre.ClientMailboxCache = {}

    for _, ent in ipairs(ents.FindByModel("models/props/cs_militia/mailbox01.mdl")) do
        if IsValid(ent) and ent:GetNWInt("BoiteLettre_ID", 0) > 0 then
            table.insert(BoiteLettre.ClientMailboxCache, ent)
        end
    end

    return BoiteLettre.ClientMailboxCache
end

function BoiteLettre.ToggleHighlight(id)
    if BoiteLettre.HighlightedIds[id] then
        BoiteLettre.HighlightedIds[id] = nil
    else
        BoiteLettre.HighlightedIds[id] = true
    end
end

hook.Add("PreDrawHalos", "BoiteLettre_DrawHalo", function()
    BoiteLettre = BoiteLettre or {}
    BoiteLettre.HighlightedIds = BoiteLettre.HighlightedIds or {}
    
    local mailboxes = {}
    for _, ent in ipairs(BoiteLettre.GetClientMailboxes()) do
        if IsValid(ent) then
            local id = ent:GetNWInt("BoiteLettre_ID", 0)
            if id > 0 and BoiteLettre.HighlightedIds[id] then
                table.insert(mailboxes, ent)
            end
        end
    end

    if #mailboxes > 0 then
        halo.Add(mailboxes, Color(255, 50, 50, 255), 3, 3, 2, true, true)
    end
end)
