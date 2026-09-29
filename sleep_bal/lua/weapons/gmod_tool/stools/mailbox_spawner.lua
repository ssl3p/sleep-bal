TOOL.Category = "Sleep"
TOOL.Name = "Boîtes aux lettres Spawner"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    language.Add("tool.mailbox_spawner.name", "Boîtes aux lettres Spawner")
    language.Add("tool.mailbox_spawner.desc", "Placez des boîtes aux lettres")
    language.Add("tool.mailbox_spawner.left", "Placer une boîte aux lettres")
    language.Add("tool.mailbox_spawner.right", "Aucune action")
    
    TOOL.PreviewPos = Vector(0, 0, 0)
    TOOL.PreviewAng = Angle(0, 0, 0)
    TOOL.PreviewValid = false
    TOOL.PreviewModel = nil
    
    TOOL.MailboxList = {}
end

function TOOL:GetPlacementTrace()
    local ply = self:GetOwner()
    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 5000,
        filter = ply
    })
    
    return trace
end

function TOOL:LeftClick(trace)
    if CLIENT then return true end
    
    if not trace.Hit then return false end

    local ply = self:GetOwner()
    if not IsValid(ply) or (not ply:IsAdmin() and not ply:IsSuperAdmin()) then return false end
    
    local pos = trace.HitPos
    local ang = Angle(0, ply:EyeAngles().y, 0)
    
    if SERVER then
        local id = BoiteLettre.Database.Add(pos, ang)
        BoiteLettre.SpawnMailbox(pos, ang, id)
    end
    
    return true
end

function TOOL:RightClick(trace)
    return false
end

function TOOL:Think()
    if CLIENT then
        local trace = self:GetPlacementTrace()
        
        if trace.Hit then
            self.PreviewPos = trace.HitPos
            self.PreviewAng = Angle(0, self:GetOwner():EyeAngles().y, 0)
            self.PreviewValid = true
        else
            self.PreviewValid = false
        end
    end
end

function TOOL:Holster()
    if CLIENT and IsValid(self.PreviewModel) then
        self.PreviewModel:Remove()
        self.PreviewModel = nil
    end
    return true
end

if CLIENT then
    hook.Add("PostDrawTranslucentRenderables", "MailboxSpawner_DrawPreview", function()
        local ply = LocalPlayer()
        local wep = ply:GetActiveWeapon()
        
        if not IsValid(wep) or wep:GetClass() != "gmod_tool" then return end
        if wep:GetMode() != "mailbox_spawner" then return end
        
        local tool = wep:GetToolObject()
        if not tool then return end
        
        if tool.PreviewValid then
            if not IsValid(tool.PreviewModel) then
                tool.PreviewModel = ClientsideModel("models/props/cs_militia/mailbox01.mdl", RENDERGROUP_TRANSLUCENT)
                tool.PreviewModel:SetNoDraw(true)
            end
            
            tool.PreviewModel:SetPos(tool.PreviewPos)
            tool.PreviewModel:SetAngles(tool.PreviewAng)
            
            tool.PreviewModel:SetRenderMode(RENDERMODE_TRANSCOLOR)
            local col = tool.PreviewModel:GetColor()
            tool.PreviewModel:SetColor(Color(col.r, col.g, col.b, 127))
            
            tool.PreviewModel:DrawModel()
            
            tool.PreviewModel:SetColor(Color(col.r, col.g, col.b, 255))
        elseif IsValid(tool.PreviewModel) then
            tool.PreviewModel:Remove()
            tool.PreviewModel = nil
        end
    end)
    
    local function RequestMailboxList()
        net.Start("BoiteLettre_GetList")
        net.SendToServer()
    end
    
    net.Receive("BoiteLettre_GetList", function()
        local list = {}
        local count = net.ReadUInt(16)
        for i = 1, count do
            list[i] = {
                id = net.ReadInt(32),
                pos = net.ReadVector(),
                ang = net.ReadAngle()
            }
        end
        
        local stored = weapons.GetStored("gmod_tool")
        if stored and stored.Tool and stored.Tool.mailbox_spawner then
            stored.Tool.mailbox_spawner.MailboxList = list
            if stored.Tool.mailbox_spawner.PopulateList then
                stored.Tool.mailbox_spawner.PopulateList()
            end
        end
    end)
    
    function TOOL.BuildCPanel(panel)
        panel:Help("Cliquez gauche pour placer une boîte aux lettres")
        panel:Help(" ")
        panel:Help("Liste des boîtes aux lettres :")

        panel:Button("Rafraîchir la liste").DoClick = function()
            RequestMailboxList()
        end

        local listview = vgui.Create("DListView", panel)
        listview:Dock(FILL)
        listview:SetMultiSelect(false)
        listview:SetDataHeight(22)
        listview:AddColumn("ID"):SetFixedWidth(40)
        listview:AddColumn("Position")

        local function Populate()
            listview:Clear()

            local stored = weapons.GetStored("gmod_tool")
            if not stored or not stored.Tool or not stored.Tool.mailbox_spawner then return end

            local data = stored.Tool.mailbox_spawner.MailboxList or {}
            for _, boite in ipairs(data) do
                local posText = string.format("%d,%d,%d", math.floor(boite.pos.x), math.floor(boite.pos.y), math.floor(boite.pos.z))
                local line = listview:AddLine(boite.id, posText)
                line._boiteData = boite
            end
        end

        function listview:OnRowRightClick(rowIndex, row)
            local boite = row._boiteData
            if not boite then return end

            local menu = DermaMenu()
            
            BoiteLettre = BoiteLettre or {}
            BoiteLettre.HighlightedIds = BoiteLettre.HighlightedIds or {}
            
            local isHighlighted = BoiteLettre.HighlightedIds[boite.id] or false
            local toggleText = isHighlighted and "Masquer la lueur" or "Afficher la lueur"
            
            menu:AddOption(toggleText, function()
                if BoiteLettre.HighlightedIds[boite.id] then
                    BoiteLettre.HighlightedIds[boite.id] = nil
                else
                    BoiteLettre.HighlightedIds[boite.id] = true
                end
            end)
            
            menu:AddOption("Supprimer", function()
                Derma_Query(
                    "Voulez-vous vraiment supprimer cette boîte ?",
                    "Confirmation",
                    "Oui", function()
                        net.Start("BoiteLettre_Remove")
                        net.WriteInt(boite.id, 32)
                        net.SendToServer()
                        timer.Simple(0.3, RequestMailboxList)
                    end,
                    "Non", function() end
                )
            end)
            
            menu:Open()
        end

        function listview:DoDoubleClick(rowIndex, row)
            local boite = row._boiteData
            if not boite then return end
            LocalPlayer():SetPos(boite.pos + Vector(0, 0, 50))
        end

        local stored = weapons.GetStored("gmod_tool")
        stored.Tool.mailbox_spawner.ListView = listview
        stored.Tool.mailbox_spawner.PopulateList = Populate

        RequestMailboxList()
        timer.Simple(0.2, Populate)
    end
end
