net.Receive("BoiteLettre_OpenMenu", function()
    local id = net.ReadInt(32)
    local isLocked = net.ReadBool()
    local steamids = net.ReadString()
    if not GtaLib then return end

    local menu = GtaLib:createMenu("", "Boîte aux lettres N°"..id, false)
    surface.PlaySound("sound/ssl3p/open.wav")

    local function build(m)
        if isLocked then
            local plySid = LocalPlayer():SteamID64() or LocalPlayer():SteamID()
            local sids = string.Explode(",", steamids)
            local hasAccess = false
            for _, sid in ipairs(sids) do
                if string.Trim(sid) == plySid then
                    hasAccess = true
                    break
                end
            end
            
            if hasAccess then
                net.Start("BoiteLettre_Withdraw")
                net.WriteInt(id, 32)
                net.SendToServer()
                return
            else
                GtaLib:separator(m, "Boîte verrouillée", { textColor = Color(255, 0, 50) })
                GtaLib:button(m, "Fermer", "", {
                    onActive = function()
                        menu.closeMenu()
                    end
                }, { textColor = Color(220, 50, 50) })
                return
            end
        end

        GtaLib:button(m, "Stockage", "", {
            onActive = function()
                menu.closeMenu()
                BoiteLettre = BoiteLettre or {}
                BoiteLettre.PendingDeposit = BoiteLettre.PendingDeposit or {}
                BoiteLettre.PendingDeposit[id] = { amount = 0, accessSid = "", weapons = {} }
                local storageMenu = GtaLib:createMenu("", "Stockage - Boîte aux lettres N°"..id, false)

                local function storageBuild(mm)
                    GtaLib:separator(mm, "Choisissez ce que vous voulez stocké", { textColor = Color(255, 0, 50) })
                    GtaLib:lineSeparator(mm)

                    local pending = BoiteLettre.PendingDeposit[id]
                    local rightText = pending.amount > 0 and ("$"..pending.amount) or ""
                    GtaLib:button(mm, "Déposer de l'argent", "", {
                        onActive = function()
                            Derma_StringRequest(
                                "Déposer",
                                "Montant à déposer dans la boîte:",
                                "0",
                                function(text)
                                    local amount = tonumber(text)
                                    if amount and amount > 0 then
                                        BoiteLettre.PendingDeposit[id].amount = amount
                                    end
                                end
                            )
                        end
                    }, { textColor = Color(255, 255, 255), rightText = rightText, rightTextColor = Color(20, 200, 20) })

                    local weaponsSubMenu = GtaLib:createSubMenu(storageMenu, "", "Déposer des armes", function(wm)
                        local ply = LocalPlayer()
                        local weapons = ply:GetWeapons()
                        local blacklist = BoiteLettre.Config.WeaponBlacklist or {}
                        
                        local validWeapons = {}
                        for _, wep in ipairs(weapons) do
                            local class = wep:GetClass()
                            local isBlacklisted = false
                            for _, bl in ipairs(blacklist) do
                                if class == bl then
                                    isBlacklisted = true
                                    break
                                end
                            end
                            if not isBlacklisted then
                                table.insert(validWeapons, wep)
                            end
                        end
                        
                        if #validWeapons == 0 then
                            GtaLib:separator(wm, "Aucune arme disponible", { textColor = Color(255, 0, 50) })
                        else
                            for _, wep in ipairs(validWeapons) do
                                local class = wep:GetClass()
                                local printName = wep:GetPrintName() or class
                                local isSel = BoiteLettre.PendingDeposit[id].weapons[class] ~= nil
                                
                                GtaLib:button(wm, printName, "", {
                                    onActive = function()
                                        if isSel then
                                            BoiteLettre.PendingDeposit[id].weapons[class] = nil
                                        else
                                            BoiteLettre.PendingDeposit[id].weapons[class] = true
                                        end
                                    end
                                }, { rightText = isSel and "✔" or "", rightTextColor = Color(20, 200, 20) })
                            end
                        end
                    end, false)

                    local weaponCount = table.Count(pending.weapons)
                    local weaponRightText = weaponCount > 0 and weaponCount or ""
                    GtaLib:button(mm, "Déposer des armes", "", {
                        onActive = function()
                            mm.submenu = weaponsSubMenu
                        end
                    }, { textColor = Color(255, 255, 255), rightText = weaponRightText, rightTextColor = Color(20, 200, 20) })

                    GtaLib:separator(mm, "A qui donnez vous la clés", { textColor = Color(255, 0, 50) })
                    GtaLib:lineSeparator(mm)

                    local playersSubMenu = GtaLib:createSubMenu(storageMenu, "", "Joueur ayant accès", function(pm)
                        local list = player.GetAll()
                        table.sort(list, function(a,b) return (a:Nick() or "") < (b:Nick() or "") end)
                        for _, pl in ipairs(list) do
                            local sid = pl:SteamID64() or pl:SteamID() or ""
                            local isSel = (BoiteLettre.PendingDeposit[id].accessSid or "") == sid
                            GtaLib:button(pm, pl:Nick(), "", {
                                onActive = function()
                                    if isSel then
                                        BoiteLettre.PendingDeposit[id].accessSid = ""
                                    else
                                        BoiteLettre.PendingDeposit[id].accessSid = sid
                                    end
                                end
                            }, { rightText = isSel and "✔" or "", rightTextColor = Color(20, 200, 20) })
                        end
                    end, false)

                    GtaLib:button(mm, "Joueur ayant accès", "", {
                        onActive = function()
                            mm.submenu = playersSubMenu
                        end
                    }, { textColor = Color(255, 255, 255) })

                    GtaLib:button(mm, "Confirmer", "", {
                        onActive = function()
                            local pending = BoiteLettre.PendingDeposit[id]
                            if pending.amount <= 0 and table.Count(pending.weapons) == 0 then
                                notification.AddLegacy("Aucun contenu à déposer", NOTIFY_ERROR, 3)
                                surface.PlaySound("buttons/button10.wav")
                                return
                            end
                            
                            local weaponsList = {}
                            for class in pairs(pending.weapons) do
                                table.insert(weaponsList, class)
                            end
                            
                            net.Start("BoiteLettre_DepositMoney")
                            net.WriteInt(id, 32)
                            net.WriteFloat(pending.amount)
                            net.WriteString(pending.accessSid)
                            net.WriteUInt(#weaponsList, 8)
                            for _, class in ipairs(weaponsList) do
                                net.WriteString(class)
                            end
                            net.SendToServer()
                            storageMenu.closeMenu()
                        end
                    }, { textColor = Color(20, 200, 20) })
                end

                GtaLib:drawMenu(storageMenu, storageBuild)
            end
        }, { textColor = Color(255, 255, 255) })

        GtaLib:button(m, "Fermer", "", {
            onActive = function()
                menu.closeMenu()
            end
        }, { textColor = Color(220, 50, 50) })
    end

    GtaLib:drawMenu(menu, build)
end)

net.Receive("BoiteLettre_DepositResult", function()
    net.ReadInt(32)
    local ok = net.ReadBool()
    net.ReadFloat()
    local msg = net.ReadString()
    if ok then
        surface.PlaySound("buttons/button14.wav")
    else
        notification.AddLegacy(msg ~= "" and msg or "Action impossible", NOTIFY_ERROR, 4)
        surface.PlaySound("buttons/button10.wav")
    end
end)

net.Receive("BoiteLettre_WithdrawResult", function()
    local amount = net.ReadFloat()
    notification.AddLegacy("Vous avez récupéré le contenu ($"..amount..")", NOTIFY_GENERIC, 4)
    surface.PlaySound("buttons/button14.wav")
end)
