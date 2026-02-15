local math = math

local MathRandom = math.random

if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"

ENT.DidCollide = false

local function RandomizeBodygroup(ent, name)
    if MathRandom(2) == 2 then return end

    local boneId = ent:FindBodygroupByName(name)
    if boneId >= 0 then
        ent:SetBodygroup(boneId, 1)
    end
end

function ENT:Initialize()
    self:SetModel("models/tea/teacup.mdl")
    RandomizeBodygroup(self, "plate")
    RandomizeBodygroup(self, "teabag")

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

    if SERVER then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

if SERVER then
    -- TODO: Change to "use" instead
    function ENT:PhysicsCollide(data, physObj)
        if not IsValid(self) then return end
        if self.DidCollide then return end

        local ent = data.HitEntity
        if not IsPlayer(ent) then return end
        if not ent:IsActiveYorkshireman() then return end

        self.DidCollide = true
        ent:YorkshiremanCollect(self)
    end
end