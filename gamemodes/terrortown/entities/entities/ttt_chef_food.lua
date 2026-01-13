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
    local function GetFoodName(foodType, isBurnt)
        local name = isBurnt and "burnt " or ""
        if foodType == CHEF_FOOD_TYPE_BURGER then
            return name .. "Burger"
        elseif foodType == CHEF_FOOD_TYPE_HOTDOG then
            return name .. "Hot Dog"
        end
        return name .. "Fish"
    end

    local function GetFoodEffect(foodType, isBurnt)
        if isBurnt then
            return "kinda sick and a bit weak."
        end

        if foodType == CHEF_FOOD_TYPE_BURGER then
            return "like you can move a bit faster."
        elseif foodType == CHEF_FOOD_TYPE_HOTDOG then
            return "like you're slowly getting healthier."
        end
        return "like you're a bit more powerful."
    end

    function ENT:PhysicsCollide(data, physObj)
        if not IsValid(self) then return end
        if self.DidCollide then return end

        local ent = data.HitEntity
        if not IsPlayer(ent) then return end

        ent:QueueMessage(MSG_PRINTTALK, "You ate a " .. GetFoodName(self:GetFoodType(), self:GetBurnt()) .. " and now you feel " .. GetFoodEffect(self:GetFoodType(), self:GetBurnt()))
        -- TODO: Buff/debuff effects
        self.DidCollide = true
        self:Remove()
    end
end