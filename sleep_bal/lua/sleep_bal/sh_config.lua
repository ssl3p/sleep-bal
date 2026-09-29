BoiteLettre = BoiteLettre or {}
BoiteLettre.Config = BoiteLettre.Config or {}

BoiteLettre.Config.WeaponBlacklist = { -- liste des items black list
    "keys",
    "weapon_physcannon",
    "gmod_camera",
    "gmod_tool",
    "pocket",
    "weapon_physgun",
    "weapon_keypadchecker",
    "door_ram",
    "arrest_stick",
    "unarrest_stick",
    "stunstick",
    "weapon_crowbar",
    "weaponchecker",
    "weapon_fists"
}

BoiteLettre.Config.Time = 360 -- temp en seconde avant delete



-- NE PAS TOUCHER -- NO TOCAR -- SALE TOCAR -- J ARRETE PROMIS !


BoiteLettre.Economy = BoiteLettre.Economy or {}


local function darkrpCanAfford(ply, amt)
    if not DarkRP or not ply.canAfford then return nil end
    return ply:canAfford(amt)
end

local function darkrpAddMoney(ply, amt)
    if not DarkRP or not ply.addMoney then return nil end
    ply:addMoney(amt)
    return true
end

local function darkrpTakeMoney(ply, amt)
    if not DarkRP or not ply.addMoney then return nil end
    ply:addMoney(-amt)
    return true
end

function BoiteLettre.Economy.CanAfford(ply, amt)
    if type(amt) ~= "number" or amt <= 0 then return false end
    local ok = darkrpCanAfford(ply, amt)
    if ok ~= nil then return ok end
    return false
end

function BoiteLettre.Economy.Give(ply, amt)
    if type(amt) ~= "number" or amt == 0 then return false end
    local ok = darkrpAddMoney(ply, amt)
    if ok ~= nil then return ok end
    return false
end

function BoiteLettre.Economy.Take(ply, amt)
    if type(amt) ~= "number" or amt <= 0 then return false end
    local ok = darkrpTakeMoney(ply, amt)
    if ok ~= nil then return ok end
    return false
end
