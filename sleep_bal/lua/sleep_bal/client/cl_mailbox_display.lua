BoiteLettre = BoiteLettre or {}
BoiteLettre.ClientMailboxCache = BoiteLettre.ClientMailboxCache or {}
BoiteLettre.NextMailboxCacheRefresh = BoiteLettre.NextMailboxCacheRefresh or 0

function BoiteLettre.GetClientMailboxes()
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

surface.CreateFont("BoiteLettre_Text", {
    font = "Inter Black",
    size = 24,
    weight = 900,
    antialias = true
})

local iconMat = Material("ssl3p/bal/e-key.png", "smooth")

hook.Add("PostDrawTranslucentRenderables", "BoiteLettre_DrawDisplay", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    
    local plyPos = ply:GetPos()
    
    for _, ent in ipairs(BoiteLettre.GetClientMailboxes()) do
        if IsValid(ent) and plyPos:DistToSqr(ent:GetPos()) <= (600 * 600) then
            local _, maxs = ent:OBBMins(), ent:OBBMaxs()
            local topPos = ent:LocalToWorld(Vector(0, 0, maxs.z + 15))
            local ang = Angle(0, ply:EyeAngles().y - 90, 90)
            cam.IgnoreZ(true)
            cam.Start3D2D(topPos, ang, 0.3)
                local text = "POUR OUVRIR"
                surface.SetFont("BoiteLettre_Text")
                local textW, _ = surface.GetTextSize(text)
                local iconSize = 32
                local spacing = 10
                local totalWidth = iconSize + spacing + textW
                local startX = -totalWidth / 2
                surface.SetDrawColor(255, 255, 255, 255)
                surface.SetMaterial(iconMat)
                surface.DrawTexturedRect(startX, -iconSize / 2, iconSize, iconSize)
                draw.SimpleText(text, "BoiteLettre_Text", startX + iconSize + spacing, 0, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            cam.End3D2D()
            cam.IgnoreZ(false)
        end
    end
end)
