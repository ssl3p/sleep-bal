BoiteLettre = BoiteLettre or {}
BoiteLettre.Entities = {}

local function IsMailboxAdmin(ply)
    if not IsValid(ply) then return false end
    return ply:IsSuperAdmin() or ply:IsAdmin()
end

local function SendDepositResult(ply, mailbox_id, ok, amount, msg)
    net.Start("BoiteLettre_DepositResult")
    net.WriteInt(mailbox_id, 32)
    net.WriteBool(ok)
    net.WriteFloat(amount or 0)
    net.WriteString(msg or "")
    net.Send(ply)
end

function BoiteLettre.SpawnMailbox(pos, ang, dbID)
    local ent = ents.Create("prop_physics")
    if not IsValid(ent) then return nil end
    
    ent:SetModel("models/props/cs_militia/mailbox01.mdl")
    ent:SetPos(pos)
    ent:SetAngles(ang)
    ent:Spawn()
    ent:Activate()
    
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
    end
    
    ent.BoiteID = dbID
    ent:SetNWInt("BoiteLettre_ID", dbID)
    ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
    
    BoiteLettre.Entities[dbID] = ent
    
    return ent
end

function BoiteLettre.RemoveMailbox(id)
    if BoiteLettre.Entities[id] and IsValid(BoiteLettre.Entities[id]) then
        BoiteLettre.Entities[id]:Remove()
        BoiteLettre.Entities[id] = nil
    end
    
    BoiteLettre.Database.Remove(id)
end

function BoiteLettre.LoadAll()
    for id, ent in pairs(BoiteLettre.Entities) do
        if IsValid(ent) then
            ent:Remove()
        end
        BoiteLettre.Entities[id] = nil
    end

    local boites = BoiteLettre.Database.GetAll()
    for _, data in ipairs(boites) do
        BoiteLettre.SpawnMailbox(data.pos, data.ang, data.id)
    end
end

util.AddNetworkString("BoiteLettre_Remove")
util.AddNetworkString("BoiteLettre_GetList")
util.AddNetworkString("BoiteLettre_OpenMenu")
util.AddNetworkString("BoiteLettre_DepositMoney")
util.AddNetworkString("BoiteLettre_DepositResult")
util.AddNetworkString("BoiteLettre_Withdraw")
util.AddNetworkString("BoiteLettre_WithdrawResult")

net.Receive("BoiteLettre_Remove", function(len, ply)
    if not IsMailboxAdmin(ply) then return end

    local id = net.ReadInt(32)
    if id <= 0 or not BoiteLettre.Database.GetByID(id) then return end

    BoiteLettre.RemoveMailbox(id)
end)

hook.Add("PostCleanupMap", "BoiteLettre_ReloadAfterCleanup", function()
    BoiteLettre.LoadAll()
end)

hook.Add("EntityTakeDamage", "BoiteLettre_BlockDamage", function(ent, dmg)
    if not IsValid(ent) then return end
    if ent:GetNWInt("BoiteLettre_ID", 0) > 0 then return true end
end)

hook.Add("CanTool", "BoiteLettre_BlockToolgun", function(ply, tr, tool)
    local ent = tr.Entity
    if not IsValid(ent) then return end
    if ent:GetNWInt("BoiteLettre_ID", 0) > 0 then return false end
end)

hook.Add("GravGunPickupAllowed", "BoiteLettre_BlockGravGun", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetNWInt("BoiteLettre_ID", 0) > 0 then return false end
end)

hook.Add("AllowPlayerPickup", "BoiteLettre_BlockPlayerPickup", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetNWInt("BoiteLettre_ID", 0) > 0 then return false end
end)

net.Receive("BoiteLettre_GetList", function(len, ply)
    if not IsMailboxAdmin(ply) then return end

    local boites = BoiteLettre.Database.GetAll()
    
    net.Start("BoiteLettre_GetList")
    net.WriteUInt(#boites, 16)
    for _, boite in ipairs(boites) do
        net.WriteInt(boite.id, 32)
        net.WriteVector(boite.pos)
        net.WriteAngle(boite.ang)
    end
    net.Send(ply)
end)

hook.Add("InitPostEntity", "BoiteLettre_LoadAll", function()
    BoiteLettre.LoadAll()
end)

hook.Add("PlayerUse", "BoiteLettre_UseOpenMenu", function(ply, ent)
    if not IsValid(ply) or not IsValid(ent) then return end
    local id = ent:GetNWInt("BoiteLettre_ID", 0)
    if id <= 0 then return end
    
    local contenu = BoiteLettre.Database.GetContenu(id)
    
    net.Start("BoiteLettre_OpenMenu")
    net.WriteInt(id, 32)
    net.WriteBool(contenu ~= nil and contenu.locked == 1)
    net.WriteString(contenu and contenu.steamid or "")
    net.Send(ply)
    return false
end)

hook.Add("PhysgunPickup", "BoiteLettre_BlockPhysgun", function(ply, ent)
    if not IsValid(ent) then return end
    if ent:GetNWInt("BoiteLettre_ID", 0) > 0 then return false end
end)

local function IsMailboxUsableBy(ply, mailbox_id)
    if not isnumber(mailbox_id) then return false end
    local ent = BoiteLettre.Entities and BoiteLettre.Entities[mailbox_id]
    if not IsValid(ent) then return false end
    if not IsValid(ply) then return false end
    if ply:GetPos():DistToSqr(ent:GetPos()) > (250*250) then return false end
    return true
end

local function IsSteamIDLike(sid)
    if sid == "" then return true end
    if #sid > 32 then return false end
    if string.match(sid, "^%d+$") then return #sid >= 15 and #sid <= 20 end
    return string.match(sid, "^STEAM_%d:%d:%d+$") ~= nil
end


net.Receive("BoiteLettre_DepositMoney", function(len, ply)
    local mailbox_id = net.ReadInt(32)
    local amount = tonumber(net.ReadFloat()) or 0
    local accessSid = net.ReadString() or ""
    local weaponCount = net.ReadUInt(8)
    local weapons = {}
    for i = 1, weaponCount do
        table.insert(weapons, net.ReadString())
    end
    
    if not IsMailboxUsableBy(ply, mailbox_id) then return end
    if amount < 0 or amount > 1e9 then return end
    if not IsSteamIDLike(accessSid) then return end
    
    if amount <= 0 and #weapons == 0 then return end

    local contenu = BoiteLettre.Database.GetContenu(mailbox_id)
    if contenu and contenu.locked == 1 then
        SendDepositResult(ply, mailbox_id, false, amount, "Boîte déjà verrouillée")
        return
    end
    
    if amount > 0 then
        if not BoiteLettre or not BoiteLettre.Economy or not BoiteLettre.Economy.CanAfford(ply, amount) then
            SendDepositResult(ply, mailbox_id, false, amount, "Fonds insuffisants")
            return
        end

        local took = BoiteLettre.Economy.Take and BoiteLettre.Economy.Take(ply, amount)
        if not took then
            SendDepositResult(ply, mailbox_id, false, amount, "Transaction refusée")
            return
        end
    end
    
    local blacklist = BoiteLettre.Config.WeaponBlacklist or {}
    local validWeapons = {}
    for _, class in ipairs(weapons) do
        class = tostring(class or "")
        if #class <= 128 then
            local isBlacklisted = false
            for _, bl in ipairs(blacklist) do
                if class == bl then
                    isBlacklisted = true
                    break
                end
            end
            if not isBlacklisted and ply:HasWeapon(class) then
                table.insert(validWeapons, class)
                ply:StripWeapon(class)
            end
        end
    end

    if amount <= 0 and #validWeapons == 0 then return end

    BoiteLettre.Database.AddDepositMoney(mailbox_id, amount, ply:SteamID64() or ply:SteamID(), accessSid, validWeapons)

    if accessSid ~= "" then
        for _, pl in ipairs(player.GetAll()) do
            local plSid = pl:SteamID64() or pl:SteamID()
            if plSid == accessSid then
                pl:SendLua(string.format([[notification.AddLegacy("Vous avez reçu les clés de la boîte aux lettres numéro %d.", NOTIFY_GENERIC, 5)]], mailbox_id))
                break
            end
        end
    end

    SendDepositResult(ply, mailbox_id, true, amount, "")
end)

net.Receive("BoiteLettre_Withdraw", function(len, ply)
    local mailbox_id = net.ReadInt(32)
    if not IsMailboxUsableBy(ply, mailbox_id) then return end
    
    local contenu = BoiteLettre.Database.GetContenu(mailbox_id)
    if not contenu or contenu.locked ~= 1 then return end
    
    local plySid = ply:SteamID64() or ply:SteamID()
    local steamids = string.Explode(",", contenu.steamid or "")
    local hasAccess = false
    for _, sid in ipairs(steamids) do
        if string.Trim(sid) == plySid then
            hasAccess = true
            break
        end
    end
    
    if not hasAccess then return end
    
    if contenu.money > 0 and BoiteLettre.Economy and BoiteLettre.Economy.Give then
        BoiteLettre.Economy.Give(ply, contenu.money)
    end
    
    local weapons = util.JSONToTable(contenu.weapons or "{}") or {}
    for _, class in ipairs(weapons) do
        ply:Give(class)
    end
    
    local storerSid = string.Explode(",", contenu.steamid or "")[1]
    if storerSid and storerSid ~= "" then
        for _, pl in ipairs(player.GetAll()) do
            local plSid = pl:SteamID64() or pl:SteamID()
            if plSid == storerSid then
                pl:SendLua(string.format([[notification.AddLegacy("Le contenu de la boîte aux lettres N°%d a été récupéré", NOTIFY_GENERIC, 5)]], mailbox_id))
                break
            end
        end
    end
    
    BoiteLettre.Database.ResetContenu(mailbox_id)
    
    net.Start("BoiteLettre_WithdrawResult")
    net.WriteFloat(contenu.money)
    net.Send(ply)
end)
