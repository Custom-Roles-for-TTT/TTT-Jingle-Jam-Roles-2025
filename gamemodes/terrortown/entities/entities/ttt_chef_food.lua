if SERVER then
    AddCSLuaFile()
end

ENT.Type = "anim"

ENT.DidCollide = false

local food_model =
{
    [CHEF_FOOD_TYPE_BURGER] = "models/food/burger.mdl",
    [CHEF_FOOD_TYPE_HOTDOG] = "models/food/hotdog.mdl",
    [CHEF_FOOD_TYPE_FISH] = "models/props/de_inferno/goldfish.mdl"
}

AccessorFuncDT(ENT, "FoodType", "FoodType")
AccessorFuncDT(ENT, "Burnt", "Burnt")
AccessorFuncDT(ENT, "Chef", "Chef")

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "FoodType")
   self:DTVar("Bool", 0, "Burnt")
   self:DTVar("Entity", 0, "Chef")
end

function ENT:Initialize()
    self:SetModel(food_model[self:GetFoodType()])
    if self:GetBurnt() then
        self:SetColor(COLOR_BLACK)
    end

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
    end
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if SERVER then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end

    -- TODO: Fix not being able to pick these up most of the time
end

if SERVER then
    function ENT:PhysicsCollide(data, physObj)
        if not self.DidCollide then
            -- TODO: Buff/debuff
            self.DidCollide = true
        end

        --self:Remove()
    end
end