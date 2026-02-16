local math = math

local MathRandom = math.random

if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function(tea)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        return {
            name = "ysm_tea",
            hint = "ysm_tea_hint",
            fmt  = function(ent, txt)
                if not client:IsActiveYorkshireman() then return nil end
                return LANG.GetParamTranslation(txt, hint_params)
            end
        }
    end
    ENT.AutomaticFrameAdvance = true
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
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if SERVER then
        self:SetUseType(SIMPLE_USE)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

if SERVER then
    function ENT:Use(activator)
        if not IsValid(self) then return end
        if self.DidCollide then return end

        if not IsPlayer(activator) then return end
        if not activator:IsActiveYorkshireman() then return end

        self.DidCollide = true
        activator:YorkshiremanCollect(self)
    end
end