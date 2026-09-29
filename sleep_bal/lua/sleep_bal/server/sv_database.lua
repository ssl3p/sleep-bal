BoiteLettre = BoiteLettre or {}
BoiteLettre.Database = {}

function BoiteLettre.Database.Init()
    sql.Query([[CREATE TABLE IF NOT EXISTS boite_au_lettre (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pos_x REAL NOT NULL,
        pos_y REAL NOT NULL,
        pos_z REAL NOT NULL,
        angle REAL NOT NULL
    )]])

    sql.Query([[CREATE TABLE IF NOT EXISTS boite_contenu (
        mailbox_id INTEGER PRIMARY KEY,
        money REAL DEFAULT 0,
        weapons TEXT DEFAULT '',
        steamid TEXT DEFAULT '',
        locked INTEGER DEFAULT 0,
        deposit_time INTEGER DEFAULT 0
    )]])
end

function BoiteLettre.Database.AddDepositMoney(mailbox_id, amount, storerSid, accessSid, weapons)
    local steamCombo = tostring(storerSid or "") .. "," .. tostring(accessSid or "")
    local steamComboEscaped = sql.SQLStr(steamCombo, true)
    local weaponsStr = util.TableToJSON(weapons or {})
    local existing = sql.QueryRow(string.format("SELECT * FROM boite_contenu WHERE mailbox_id = %d", tonumber(mailbox_id or 0)))
    local currentTime = os.time()
    
    if existing then
        local newMoney = tonumber(existing.money or 0) + tonumber(amount or 0)
        local existingWeapons = util.JSONToTable(existing.weapons or "{}") or {}
        for _, wep in ipairs(weapons or {}) do
            table.insert(existingWeapons, wep)
        end
        local newWeaponsStr = util.TableToJSON(existingWeapons)
        sql.Query(string.format([[UPDATE boite_contenu SET money = %f, weapons = '%s', steamid = '%s', locked = 1, deposit_time = %d WHERE mailbox_id = %d]], 
            newMoney, sql.SQLStr(newWeaponsStr, true), steamComboEscaped, currentTime, tonumber(mailbox_id or 0)))
    else
        sql.Query(string.format([[INSERT INTO boite_contenu (mailbox_id, money, weapons, steamid, locked, deposit_time)
            VALUES (%d, %f, '%s', '%s', %d, %d)]], tonumber(mailbox_id or 0), tonumber(amount or 0), sql.SQLStr(weaponsStr, true), steamComboEscaped, 1, currentTime))
    end
end

function BoiteLettre.Database.Add(pos, ang)
    sql.Query(string.format([[INSERT INTO boite_au_lettre (pos_x, pos_y, pos_z, angle)
        VALUES (%f, %f, %f, %f)]], pos.x, pos.y, pos.z, ang.y))
    return tonumber(sql.QueryValue("SELECT last_insert_rowid()"))
end

function BoiteLettre.Database.Remove(id)
    id = tonumber(id or 0)
    sql.Query(string.format("DELETE FROM boite_au_lettre WHERE id = %d", id))
    sql.Query(string.format("DELETE FROM boite_contenu WHERE mailbox_id = %d", id))
end

function BoiteLettre.Database.GetAll()
    local result = sql.Query("SELECT * FROM boite_au_lettre")
    if not result then return {} end
    
    local boites = {}
    for _, row in ipairs(result) do
        table.insert(boites, {
            id = tonumber(row.id),
            pos = Vector(tonumber(row.pos_x), tonumber(row.pos_y), tonumber(row.pos_z)),
            ang = Angle(0, tonumber(row.angle or 0), 0)
        })
    end
    return boites
end

function BoiteLettre.Database.GetByID(id)
    id = tonumber(id or 0)
    local result = sql.QueryRow(string.format("SELECT * FROM boite_au_lettre WHERE id = %d", id))
    if not result then return nil end
    
    return {
        id = tonumber(result.id),
        pos = Vector(tonumber(result.pos_x), tonumber(result.pos_y), tonumber(result.pos_z)),
        ang = Angle(0, tonumber(result.angle or 0), 0)
    }
end

function BoiteLettre.Database.GetContenu(mailbox_id)
    local result = sql.QueryRow(string.format("SELECT * FROM boite_contenu WHERE mailbox_id = %d", tonumber(mailbox_id or 0)))
    if not result then return nil end
    
    return {
        mailbox_id = tonumber(result.mailbox_id),
        money = tonumber(result.money or 0),
        weapons = result.weapons or "",
        steamid = result.steamid or "",
        locked = tonumber(result.locked or 0),
        deposit_time = tonumber(result.deposit_time or 0)
    }
end

function BoiteLettre.Database.ResetContenu(mailbox_id)
    sql.Query(string.format([[UPDATE boite_contenu SET money = 0, weapons = '', steamid = '', locked = 0, deposit_time = 0 WHERE mailbox_id = %d]], tonumber(mailbox_id or 0)))
end

function BoiteLettre.Database.GetAllLockedContenu()
    local results = sql.Query("SELECT * FROM boite_contenu WHERE locked = 1")
    if not results then return {} end
    
    local list = {}
    for _, result in ipairs(results) do
        table.insert(list, {
            mailbox_id = tonumber(result.mailbox_id),
            money = tonumber(result.money or 0),
            weapons = result.weapons or "",
            steamid = result.steamid or "",
            locked = tonumber(result.locked or 0),
            deposit_time = tonumber(result.deposit_time or 0)
        })
    end
    return list
end

hook.Add("Initialize", "BoiteLettre_InitDB", function()
    BoiteLettre.Database.Init()
end)

timer.Create("BoiteLettre_CheckExpiration", 60, 0, function()
    local expireTime = tonumber(BoiteLettre.Config.Time) or 360
    local currentTime = os.time()
    local allContenu = BoiteLettre.Database.GetAllLockedContenu()
    
    for _, contenu in ipairs(allContenu) do
        if contenu.deposit_time > 0 and (currentTime - contenu.deposit_time) >= expireTime then
            BoiteLettre.Database.ResetContenu(contenu.mailbox_id)
            print("[BoiteLettre] Contenu de la boîte N°" .. contenu.mailbox_id .. " expiré et supprimé")
        end
    end
end)
