if SERVER then
    AddCSLuaFile()
end

local ents = ents
local hook = hook
local ipairs = ipairs
local math = math
local table = table
local timer = timer

local CreateEntity = ents.Create
local MathRandom = math.random
local MathRand = math.Rand
local TableInsert = table.insert
local TableRemove = table.remove

local safekeeper_move_safe = CreateConVar("ttt_safekeeper_move_safe", "1", FCVAR_REPLICATED, "Whether an Safekeeper can move their safe", 0, 1)
local safekeeper_move_cooldown = CreateConVar("ttt_safekeeper_move_cooldown", "30", FCVAR_REPLICATED, "How long a Safekeeper must wait after placing their safe before they can move it again", 0, 120)

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function(safe)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        return {
            name = LANG.GetTranslation("sfk_safe_name"),
            hint = "sfk_safe_hint",
            fmt  = function(ent, txt)
                if not IsValid(safe) then return nil end
                if not client:Alive() or client:IsSpec() then return nil end

                local placer = safe:GetPlacer()
                if not IsPlayer(placer) then return nil end

                local remaining = safe:GetEndTime() - CurTime()
                local hint = txt
                if safe:GetOpen() then
                    hint = hint .. "_open"
                elseif placer ~= client then
                    hint = hint .. "_pick"
                elseif not safekeeper_move_safe:GetBool() then
                    hint = hint .. "_nomove"
                elseif safekeeper_move_cooldown:GetInt() > 0 and remaining > 0 then
                    hint = hint .. "_cooldown"
                    hint_params.time = util.SimpleTime(remaining, "%02i:%02i")
                end

                return LANG.GetParamTranslation(hint, hint_params)
            end
        }
    end
    ENT.AutomaticFrameAdvance = true
end

ENT.Type = "anim"

ENT.CanUseKey = true
ENT.SafeModel = "models/sudisteprops/simple_safe.mdl"

function ENT:SetupDataTables()
   self:NetworkVar("Bool", "Open")
   self:NetworkVar("Int", "EndTime")
   self:NetworkVar("Int", "State")
   self:NetworkVar("Entity", "Placer")
end

function ENT:Initialize()
    self:SetEndTime(CurTime() + safekeeper_move_cooldown:GetInt())
    self:SetModel(self.SafeModel)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

    if SERVER then
        self:SetUseType(CONTINUOUS_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        self:WeldToGround(true)
    end
end

if SERVER then
    local safekeeper_weapons_dropped = CreateConVar("ttt_safekeeper_weapons_dropped", "4", FCVAR_NONE, "How many weapons the Safekeeper's safe drops when it is picked open", 0, 10)
    local safekeeper_warn_pick_start = CreateConVar("ttt_safekeeper_warn_pick_start", "1", FCVAR_NONE, "Whether to warn a safe's owner when someone starts picking it", 0, 1)
    local safekeeper_warn_pick_complete = CreateConVar("ttt_safekeeper_warn_pick_complete", "1", FCVAR_NONE, "Whether to warn a safe's owner when it is picked", 0, 1)

    function ENT:Use(activator)
        if self:GetOpen() then return end
        if not IsPlayer(activator) or not activator:IsActive() then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        local curTime = CurTime()
        if activator == placer then
            if not safekeeper_move_safe:GetBool() then return end

            if (self:GetEndTime() - curTime) > 0 then return end

            activator:Give("weapon_sfk_safeplacer")
            self:SetPlacer(nil)
            self:Remove()
            return
        end

        -- If this is a new activator, start tracking how long they've been using it for
        local stealTarget = activator.TTTSafekeeperPickTarget
        if self ~= stealTarget then
            if safekeeper_warn_pick_start:GetBool() then
                placer:ClearQueuedMessage("sfkSafePickStart")
                placer:QueueMessage(MSG_PRINTBOTH, "Your safe is being picked!", nil, "sfkSafePickStart")
                net.Start("TTT_SafekeeperPlaySound")
                    net.WriteString("pick")
                net.Send(placer)
            end
            activator:SetProperty("TTTSafekeeperPickTarget", self, activator)
            activator:SetProperty("TTTSafekeeperPickStart", curTime, activator)
        end

        -- Keep track of the last time they used it so we can time it out
        activator.TTTSafekeeperLastPickTime = curTime
    end

    function ENT:Open(opener)
        if self:GetOpen() then return end
        if not IsPlayer(opener) then return end
        if not opener:Alive() or opener:IsSpec() then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if safekeeper_warn_pick_complete:GetBool() then
            placer:QueueMessage(MSG_PRINTBOTH, "Your safe has been picked by " .. opener:Nick() .. ", get them!")
            net.Start("TTT_SafekeeperPlaySound")
                net.WriteString("open")
            net.Send(placer)
        end

        net.Start("TTT_SafekeeperSafePicked")
            net.WriteString(placer:Nick())
            net.WriteString(opener:Nick())
        net.Broadcast()

        self:SetOpen(true)
        -- Change to model "Base1" Submodel 1 to show the door as open
        local boneId = self:FindBodygroupByName("Base1")
        if boneId >= 0 then
            self:SetBodygroup(boneId, 1)
        end

        local placerSid64 = placer:SteamID64()
        local lootedList
        if opener.TTTSafekeeperLootedList then
            lootedList = opener.TTTSafekeeperLootedList
        else
            lootedList = {}
        end
        TableInsert(lootedList, placerSid64)
        opener:SetProperty("TTTSafekeeperLootedList", lootedList)

        local lootTable = {}
        local safe = self
        timer.Create("SafekeeperSafeWeaponDrop_" .. self:EntIndex(), 0.05, safekeeper_weapons_dropped:GetInt(), function()
            if not IsValid(safe) then return end

            if #lootTable == 0 then -- Rebuild the loot table if we run out
                for _, v in ipairs(weapons.GetList()) do
                    if v and not v.AutoSpawnable and v.CanBuy and #v.CanBuy > 0 and v.AllowDrop then
                        TableInsert(lootTable, WEPS.GetClass(v))
                    end
                end
            end

            local idx = MathRandom(1, #lootTable)
            local wep = lootTable[idx]
            TableRemove(lootTable, idx)

            -- Make the weapons spawn in front of the safe based on the direction it's facing
            local ang = safe:GetAngles()
            -- Rotate the angle to reflect which side is actually the front
            ang:RotateAroundAxis(Vector(0, 0, 1), 90)
            -- Push it forward so it looks they are coming out of the door
            local pos = safe:GetPos() + ang:Forward() * -10
            local ent = CreateEntity(wep)
            ent:SetPos(pos)
            ent.TTTSafekeeperSpawnedBy = placerSid64
            ent:Spawn()

            local phys = ent:GetPhysicsObject()
            if IsValid(phys) then
                phys:ApplyForceCenter(Vector(MathRand(-5, 5), MathRand(-5, 5), 25) * phys:GetMass())
            end
        end)

        hook.Call("TTTSafekeeperSafePicked", nil, placer, opener, self)
    end

    function ENT:OnRemove()
        timer.Remove("SafekeeperSafeWeaponDrop_" .. self:EntIndex())
    end

    -- Copied from C4
    function ENT:WeldToGround(state)
        if state then
           -- getgroundentity does not work for non-players
           -- so sweep ent downward to find what we're lying on
           local ignore = player.GetAll()
           TableInsert(ignore, self)

           local tr = util.TraceEntity({ start = self:GetPos(), endpos = self:GetPos() - Vector(0, 0, 16), filter = ignore, mask = MASK_SOLID }, self)

           -- Start by increasing weight/making uncarryable
           local phys = self:GetPhysicsObject()
           if IsValid(phys) then
              -- Could just use a pickup flag for this. However, then it's easier to
              -- push it around.
              self.OrigMass = phys:GetMass()
              phys:SetMass(150)
           end

           if tr.Hit and (IsValid(tr.Entity) or tr.HitWorld) then
              -- "Attach" to a brush if possible
              if IsValid(phys) and tr.HitWorld then
                 phys:EnableMotion(false)
              end

              -- Else weld to objects we cannot pick up
              local entphys = tr.Entity:GetPhysicsObject()
              if IsValid(entphys) and entphys:GetMass() > CARRY_WEIGHT_LIMIT then
                 constraint.Weld(self, tr.Entity, 0, 0, 0, true)
              end

              -- Worst case, we are still uncarryable
           end
        else
           constraint.RemoveConstraints(self, "Weld")
           local phys = self:GetPhysicsObject()
           if IsValid(phys) then
              phys:EnableMotion(true)
              phys:SetMass(self.OrigMass or 10)
           end
        end
     end
end