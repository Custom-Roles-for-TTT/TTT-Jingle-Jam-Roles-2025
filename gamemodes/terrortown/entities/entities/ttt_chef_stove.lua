if SERVER then
    AddCSLuaFile()
end

local ents = ents
local math = math
local table = table

local CreateEntity = ents.Create
local MathRand = math.Rand
local MathRandom = math.random
local MathRound = math.Round

-- State
CHEF_STOVE_STATE_IDLE = 0
CHEF_STOVE_STATE_COOKING = 1
CHEF_STOVE_STATE_DONE = 2
CHEF_STOVE_STATE_BURNT = 3

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function(stove)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local name
        if not IsValid(stove) or stove:GetPlacer() ~= client then
            name = LANG.GetTranslation("chf_stove_name")
        else
            name = LANG.GetParamTranslation("chf_stove_name_health", { current = stove:Health(), max = stove:GetMaxHealth() })
        end

        return {
            name = name,
            hint = "chf_stove_hint",
            fmt  = function(ent, txt)
                if not IsValid(stove) then return nil end

                local placer = stove:GetPlacer()
                if not IsPlayer(placer) then return nil end
                if placer ~= client then return nil end

                hint_params.food = LANG.GetTranslation("chf_stove_type_" .. stove:GetFoodType())

                local hint = txt
                local state = stove:GetState()
                if stove:GetOnFire() then
                    hint = hint .. "_onfire"
                elseif state == CHEF_STOVE_STATE_COOKING then
                    local remaining = stove:GetEndTime() - CurTime()
                    hint_params.time = util.SimpleTime(remaining, "%02i:%02i")
                    hint = hint .. "_progress"
                elseif state >= CHEF_STOVE_STATE_DONE then
                    local remaining = stove:GetOvercookTime() - CurTime()
                    hint_params.time = util.SimpleTime(remaining, "%02i:%02i")
                    hint = hint .. "_retrieve_" .. state
                else
                    hint = hint .. "_start"
                end

                return LANG.GetParamTranslation(hint, hint_params)
            end
        }
    end
    ENT.AutomaticFrameAdvance = true
end

ENT.Type = "anim"

ENT.CanUseKey = true
ENT.StoveModel = "models/props_forest/stove01.mdl"

if CLIENT then
    ENT.SmokeEmitter = nil
    ENT.SmokeNextPart = nil
    ENT.SmokeColorStart = COLOR_WHITE
    ENT.SmokeColorCooked = COLOR_GRAY
    ENT.SmokeColorBurnt = COLOR_BLACK
    ENT.SmokeParticle = "particle/snow.vmt"
    ENT.SmokeOffset = Vector(0, 0, 30)
end

local cook_time = CreateConVar("ttt_chef_cook_time", "30", FCVAR_REPLICATED, "How long (in seconds) it takes to cook food", 1, 60)
local overcook_time = CreateConVar("ttt_chef_overcook_time", "5", FCVAR_REPLICATED, "How long (in seconds) after food is finished cooking before it burns", 1, 60)
local overcook_fire_time = CreateConVar("ttt_chef_overcook_fire_time", "30", FCVAR_REPLICATED, "How long (in seconds) after food is burnt before it the stove catches fire. Set to \"0\" to disable", 0, 60)
local overcook_fire_lifetime = CreateConVar("ttt_chef_overcook_fire_lifetime", "20", FCVAR_REPLICATED, "How long (in seconds) the stove stays on fire once it ignites. Only used when \"ttt_chef_overcook_fire_time\" is greater than 0", 1, 60)

AccessorFuncDT(ENT, "FoodType", "FoodType")
AccessorFuncDT(ENT, "EndTime", "EndTime")
AccessorFuncDT(ENT, "OvercookTime", "OvercookTime")
AccessorFuncDT(ENT, "State", "State")
AccessorFuncDT(ENT, "Placer", "Placer")
AccessorFuncDT(ENT, "OnFire", "OnFire")

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "FoodType")
   self:DTVar("Int", 1, "EndTime")
   self:DTVar("Int", 2, "OvercookTime")
   self:DTVar("Int", 3, "State")
   self:DTVar("Entity", 0, "Placer")
   self:DTVar("Bool", 0, "OnFire")
end

function ENT:Initialize()
    self:SetModel(self.StoveModel)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

    if SERVER then
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        self:WeldToGround(true)
    end
end

function ENT:Think()
    local state = self:GetState()
    if state < CHEF_STOVE_STATE_COOKING then
        if CLIENT and self.SmokeEmitter then
            self.SmokeEmitter:Finish()
            self.SmokeEmitter = nil
        end
        return
    end

    local curTime = CurTime()
    if SERVER then
        if state <= CHEF_STOVE_STATE_DONE then
            self.FireEndTime = 0

            local endTime = self:GetEndTime()
            if endTime <= curTime then
                if self:GetOvercookTime() <= curTime then
                    self:SetState(CHEF_STOVE_STATE_BURNT)
                elseif state ~= CHEF_STOVE_STATE_DONE then
                    self:SetState(CHEF_STOVE_STATE_DONE)
                end
            end
        -- If we're on fire, automatically remove it after enough time
        elseif self:GetOnFire() then
            if curTime >= self.FireEndTime then
                self:RemoveFire()
            end
        -- If we haven't already been extinguished, check if it's time to add the fire
        elseif self.FireEndTime ~= nil then
            local timeBurnt = curTime - self:GetOvercookTime()
            if timeBurnt > overcook_fire_time:GetInt() then
                self:AddFire()
            end
        end
    elseif CLIENT then
        if not self.SmokeEmitter then self.SmokeEmitter = ParticleEmitter(self:GetPos()) end
        if not self.SmokeNextPart then self.SmokeNextPart = curTime end
        local pos = self:GetPos() + self.SmokeOffset
        -- Use DistToSqr as it's more efficient and this is called very frequently
        -- 9000000 = 3000^2
        local client = LocalPlayer()
        if self.SmokeNextPart < curTime and client:GetPos():DistToSqr(pos) <= 9000000 then
            self.SmokeEmitter:SetPos(pos)
            self.SmokeNextPart = curTime + MathRand(0.003, 0.01)
            local vec = Vector(MathRand(-8, 8), MathRand(-8, 8), MathRand(10, 55))
            local particle = self.SmokeEmitter:Add(self.SmokeParticle, self:LocalToWorld(vec))
            particle:SetVelocity(Vector(0, 0, 4) + VectorRand() * 3)
            particle:SetDieTime(MathRand(0.5, 2))
            particle:SetStartAlpha(MathRandom(150, 220))
            particle:SetEndAlpha(0)
            local size = MathRandom(1, 3)
            particle:SetStartSize(size)
            particle:SetEndSize(size + 1)
            particle:SetRoll(0)
            particle:SetRollDelta(0)
            local smokeColor
            if state == CHEF_STOVE_STATE_BURNT then
                smokeColor = self.SmokeColorBurnt
            else
                local startColor, endColor, progress
                if state == CHEF_STOVE_STATE_DONE then
                    startColor = self.SmokeColorCooked
                    endColor = self.SmokeColorBurnt
                    progress = (self:GetOvercookTime() - curTime) / overcook_time:GetInt()
                else
                    startColor = self.SmokeColorStart
                    endColor = self.SmokeColorCooked
                    progress = (self:GetEndTime() - curTime) / cook_time:GetInt()
                end

                smokeColor = {
                    r = MathRound(endColor.r + ((startColor.r - endColor.r) * progress)),
                    g = MathRound(endColor.g + ((startColor.g - endColor.g) * progress)),
                    b = MathRound(endColor.b + ((startColor.b - endColor.b) * progress))
                }
            end
            particle:SetColor(smokeColor.r, smokeColor.g, smokeColor.b)
        end
    end
end

if SERVER then
    ENT.FireEndTime = nil
    ENT.BlastRadius = 50
    ENT.BlastDamage = 10

    local damage_own_stove = CreateConVar("ttt_chef_damage_own_stove", "0", FCVAR_NONE, "Whether a stove's owner can damage it", 0, 1)
    local warn_damage = CreateConVar("ttt_chef_warn_damage", "1", FCVAR_NONE, "Whether to warn a stove's owner is warned when it is damaged", 0, 1)
    local warn_destroy = CreateConVar("ttt_chef_warn_destroy", "1", FCVAR_NONE, "Whether to warn a stove's owner is warned when it is destroyed", 0, 1)

    function ENT:OnTakeDamage(dmginfo)
        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        if att:ShouldActLikeJester() then return end
        if att == placer and not damage_own_stove:GetBool() then return end

        self:SetHealth(self:Health() - dmginfo:GetDamage())

        if IsPlayer(att) then
            DamageLog(Format("DMG: \t %s [%s] damaged stove %s [%s] for %d dmg", att:Nick(), ROLE_STRINGS[att:GetRole()], placer:Nick(), ROLE_STRINGS[placer:GetRole()], dmginfo:GetDamage()))
        end

        if self:Health() <= 0 then
            self:DestroyStove()
            if warn_destroy:GetBool() then
                placer:QueueMessage(MSG_PRINTBOTH, "Your Stove has been destroyed!")
            end
        elseif warn_damage:GetBool() then
            LANG.Msg(placer, "chf_stove_damaged")
        end
    end

    function ENT:Use(activator)
        if self:GetOnFire() then return end
        if not IsPlayer(activator) or not activator:IsActive() then return end

        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end
        if activator ~= placer then return end

        -- Completely disable the stove if the role ability is disabled
        -- This will also cause any cooking food to overcook by nature of not being able to stop it
        if placer:IsRoleAbilityDisabled() then return end

        local state = self:GetState()
        if state == CHEF_STOVE_STATE_COOKING then return end

        if state == CHEF_STOVE_STATE_IDLE then
            self:SetEndTime(CurTime() + cook_time:GetInt())
            self:SetOvercookTime(self:GetEndTime() + overcook_time:GetInt())
            self:SetState(CHEF_STOVE_STATE_COOKING)
        else
            local food = CreateEntity("ttt_chef_food")
            -- Spawn the food slightly in front of the stove
            food:SetPos(self:GetPos() + (self:GetAngles():Forward() * 20) + Vector(0, 0, 10))
            food:SetChef(placer)
            food:SetFoodType(self:GetFoodType())
            if state == CHEF_STOVE_STATE_BURNT then
                food:SetBurnt(true)
            end
            food:Spawn()

            self:SetState(CHEF_STOVE_STATE_IDLE)
        end
    end

    function ENT:DestroyStove()
        self:WeldToGround(false)

        local effect = EffectData()
        effect:SetOrigin(self:GetPos())
        util.Effect("cball_explode", effect)
        self:Remove()
    end

    function ENT:AddFire()
        local placer = self:GetPlacer()
        if not IsPlayer(placer) then return end

        local curTime = CurTime()
        local pos = self:GetPos() + Vector(0, 0, 50)

        self.FireEndTime = curTime + overcook_fire_lifetime:GetInt()
        self:SetOnFire(true)

        -- Spawn flame entity right on top
        local flame = CreateEntity("ttt_flame")
        flame:SetPos(pos)
        flame:SetDamageParent(placer)
        flame:SetOwner(placer)
        flame:SetDieTime(self.FireEndTime)
        flame:SetExplodeOnDeath(false)
        flame:Spawn()
        self.FireEnt = flame

        -- And explode a little bit
        local effect = EffectData()
        effect:SetStart(pos)
        effect:SetOrigin(pos)
        effect:SetScale(self.BlastRadius * 0.3)
        effect:SetRadius(self.BlastRadius)
        effect:SetMagnitude(self.BlastDamage)
        util.Effect("Explosion", effect, true, true)
        util.BlastDamage(self, placer, pos, self.BlastRadius, self.BlastDamage)
    end

    function ENT:RemoveFire()
        if not self:GetOnFire() then return end
        SafeRemoveEntity(self.FireEnt)
        self.FireEnt = nil
        self.FireEndTime = nil
        self:SetOnFire(false)
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