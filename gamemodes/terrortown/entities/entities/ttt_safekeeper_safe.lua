if SERVER then
    AddCSLuaFile()
end

local table = table

local safekeeper_move_safe = CreateConVar("ttt_safekeeper_move_safe", "1", FCVAR_REPLICATED, "Whether an Safekeeper can move their safe", 0, 1)

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

                local placer = safe:GetPlacer()
                if not IsPlayer(placer) then return nil end

                local hint = txt
                if placer ~= client then
                    hint = hint .. "_pick"
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

ENT.CollisionMins = Vector(-15.5, -13.5, -2.5)
ENT.CollisionMaxs = Vector(13.2, 14, 28.7)

AccessorFuncDT(ENT, "Open", "Open")
AccessorFuncDT(ENT, "EndTime", "EndTime")
AccessorFuncDT(ENT, "State", "State")
AccessorFuncDT(ENT, "Placer", "Placer")

function ENT:SetupDataTables()
   self:DTVar("Bool", 0, "Open")
   self:DTVar("Int", 0, "EndTime")
   self:DTVar("Int", 1, "State")
   self:DTVar("Entity", 0, "Placer")
end

function ENT:Initialize()
    self:SetModel(self.SafeModel)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)

    local scale = Vector(0.5, 0.5, 0.5)
    for i=0, self:GetBoneCount() - 1 do
        self:ManipulateBoneScale(i, scale)
    end

    -- TODO: This isn't rotated correctly
    self:SetCollisionBounds(self.CollisionMins, self.CollisionMaxs)
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
    local safekeeper_warn_pick_start = CreateConVar("ttt_safekeeper_warn_pick_start", "1", FCVAR_NONE, "Whether to warn an safe's owner is warned when someone starts picking it", 0, 1)

    function ENT:Use(activator)
        if not IsPlayer(activator) or not activator:IsActive() then return end
        if self:GetOpen() then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end
        if activator == placer then
            if not safekeeper_move_safe:GetBool() then return end

            activator:Give("weapon_sfk_safeplacer")
            self:SetPlacer(nil)
            self:Remove()
            return
        end

        local curTime = CurTime()

        -- If this is a new activator, start tracking how long they've been using it for
        local stealTarget = activator.SafekeeperPickTarget
        if self ~= stealTarget then
            if safekeeper_warn_pick_start:GetBool() then
                placer:QueueMessage(MSG_PRINTBOTH, "Your safe is being picked!")
                -- TODO: Sound?
            end
            activator:SetProperty("SafekeeperPickTarget", self, activator)
            activator:SetProperty("SafekeeperPickStart", curTime, activator)
        end

        -- Keep track of the last time they used it so we can time it out
        activator.SafekeeperLastPickTime = curTime
    end

    function ENT:Open(opener)
        if not IsPlayer(opener) then return end
        if not opener:Alive() or opener:IsSpec() then return end

        self:SetOpen(true)
        -- TODO: Change to model "Base1" Submodel 1? Maybe bodygroups?
        -- TODO: Spawn weapons
    end

    -- Copied from C4
    function ENT:WeldToGround(state)
        if state then
           -- getgroundentity does not work for non-players
           -- so sweep ent downward to find what we're lying on
           local ignore = player.GetAll()
           table.insert(ignore, self)

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