if SERVER then
    AddCSLuaFile()
end

local hook = hook
local math = math
local net = net
local string = string
local table = table

local AddHook = hook.Add
local MathRound = math.Round
local StringGSub = string.gsub
local RemoveHook = hook.Remove
local TableInsert = table.insert

ENT.Type = "anim"

ENT.DidCollide = false

local food_model =
{
    [CHEF_FOOD_TYPE_BURGER] = "models/food/burger.mdl",
    [CHEF_FOOD_TYPE_HOTDOG] = "models/food/hotdog.mdl",
    [CHEF_FOOD_TYPE_FISH] = "models/props/de_inferno/goldfish.mdl"
}

function ENT:SetupDataTables()
   self:NetworkVar("Int", "FoodType")
   self:NetworkVar("Bool", "Burnt")
   self:NetworkVar("Entity", "Chef")
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
    self:AddSolidFlags(FSOLID_TRIGGER)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

    if SERVER then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

local function AddBuffHook(ply, entIndex, foodType, amount)
    if foodType ~= CHEF_FOOD_TYPE_BURGER and foodType ~= CHEF_FOOD_TYPE_FISH then return end
    if not IsPlayer(ply) then return end

    if SERVER then
        net.Start("TTTChefFoodAddHook")
            net.WriteUInt(entIndex, 16)
            net.WriteUInt(foodType, 2)
            net.WriteFloat(amount)
        net.Send(ply)
    end

    local hookType, hookName
    if foodType == CHEF_FOOD_TYPE_BURGER then
        hookType = "TTTSpeedMultiplier"
        hookName = "Chef_" .. hookType .. "_" .. foodType .. "_" .. entIndex
        AddHook(hookType, hookName, function(tgt, mults)
            if not IsPlayer(tgt) then return end
            if tgt ~= ply then return end
            TableInsert(mults, 1 + amount)
        end)
    elseif foodType == CHEF_FOOD_TYPE_FISH then
        hookType = "ScalePlayerDamage"
        hookName = "Chef_" .. hookType .. "_" .. foodType .. "_" .. entIndex
        AddHook(hookType, hookName, function(tgt, hitgroup, dmginfo)
            if not IsPlayer(tgt) then return end

            local att = dmginfo:GetAttacker()
            if not IsPlayer(att) then return end
            if att ~= ply then return end

            dmginfo:ScaleDamage(1 + amount)
        end)
    end

    if not ply.TTTChefHooks then
        ply.TTTChefHooks = {}
    end
    ply.TTTChefHooks[hookName] = hookType
end

local function RemoveBuffHook(ply, entIndex, foodType)
    if foodType ~= CHEF_FOOD_TYPE_BURGER and foodType ~= CHEF_FOOD_TYPE_FISH then return end
    if not IsPlayer(ply) then return end
    if not ply.TTTChefHooks then return end

    if SERVER then
        net.Start("TTTChefFoodRemoveHook")
            net.WriteUInt(entIndex, 16)
            net.WriteUInt(foodType, 2)
        net.Send(ply)
    end

    local hookType, hookName
    if foodType == CHEF_FOOD_TYPE_BURGER then
        hookType = "TTTSpeedMultiplier"
        hookName = "Chef_" .. hookType .. "_" .. foodType .. "_" .. entIndex
    elseif foodType == CHEF_FOOD_TYPE_FISH then
        hookType = "ScalePlayerDamage"
        hookName = "Chef_" .. hookType .. "_" .. foodType .. "_" .. entIndex
    end

    RemoveHook(hookType, hookName)
    ply.TTTChefHooks[hookName] = nil
end

if CLIENT then
    local client = nil
    net.Receive("TTTChefFoodAddHook", function()
        if not IsValid(client) then
            client = LocalPlayer()
        end

        local entIndex = net.ReadUInt(16)
        local foodType = net.ReadUInt(2)
        local amount = net.ReadFloat()
        AddBuffHook(client, entIndex, foodType, amount)
    end)

    net.Receive("TTTChefFoodRemoveHook", function()
        if not IsValid(client) then
            client = LocalPlayer()
        end

        local entIndex = net.ReadUInt(16)
        local foodType = net.ReadUInt(2)
        RemoveBuffHook(client, entIndex, foodType)
    end)
end

if SERVER then
    util.AddNetworkString("TTTChefFoodAddHook")
    util.AddNetworkString("TTTChefFoodRemoveHook")

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

    function ENT:Touch(ent)
        if not IsValid(self) then return end
        if self.DidCollide then return end

        if not IsPlayer(ent) then return end

        self.DidCollide = true

        local foodType = self:GetFoodType()
        local isBurnt = self:GetBurnt()
        local foodName = GetFoodName(foodType, isBurnt)
        ent:QueueMessage(MSG_PRINTTALK, "You ate a " .. foodName .. " and now you feel " .. GetFoodEffect(foodType, isBurnt))

        local entIndex = self:EntIndex()
        local timerId = "TTTChef_" .. StringGSub(foodName, "%s+", "") .. "_" .. entIndex
        if not ent.TTTChefTimers then
            ent.TTTChefTimers = {}
        end
        TableInsert(ent.TTTChefTimers, timerId)

        local time
        if isBurnt then
            time = GetConVar("ttt_chef_burnt_time"):GetInt()
            local interval = GetConVar("ttt_chef_burnt_interval"):GetInt()
            local amount = GetConVar("ttt_chef_burnt_amount"):GetInt()
            local repetitions = MathRound(time / interval)
            local chef = self:GetChef()
            timer.Create(timerId, interval, repetitions, function()
                if not IsPlayer(ent) then
                    timer.Remove(timerId)
                    return
                end

                local dmginfo = DamageInfo()
                dmginfo:SetDamage(amount)
                dmginfo:SetAttacker(chef or game.GetWorld())
                dmginfo:SetInflictor(chef or game.GetWorld())
                dmginfo:SetDamageType(DMG_SLASH)
                ent:TakeDamageInfo(dmginfo)
            end)
        else
            if foodType == CHEF_FOOD_TYPE_HOTDOG then
                time = GetConVar("ttt_chef_hotdog_time"):GetInt()
                local interval = GetConVar("ttt_chef_hotdog_interval"):GetInt()
                local amount = GetConVar("ttt_chef_hotdog_amount"):GetInt()
                local repetitions = MathRound(time / interval)
                timer.Create(timerId, interval, repetitions, function()
                    if not IsPlayer(ent) then
                        timer.Remove(timerId)
                        return
                    end

                    local hp = ent:Health()
                    ent:SetHealth(hp + amount)
                end)
            else
                local amount
                if foodType == CHEF_FOOD_TYPE_BURGER then
                    time = GetConVar("ttt_chef_burger_time"):GetInt()
                    amount = GetConVar("ttt_chef_burger_amount"):GetFloat()
                else
                    time = GetConVar("ttt_chef_fish_time"):GetInt()
                    amount = GetConVar("ttt_chef_fish_amount"):GetFloat()
                end
                AddBuffHook(ent, entIndex, foodType, amount)
                timer.Create(timerId, time, 1, function()
                    RemoveBuffHook(ent, entIndex, foodType)
                end)
            end
        end

        -- Tell the eater when the effects end too
        TableInsert(ent.TTTChefTimers, timerId .. "_End")
        timer.Create(timerId .. "_End", time, 1, function()
            if not IsPlayer(ent) then return end
            ent:QueueMessage(MSG_PRINTTALK, "The effects of the " .. foodName .. " you ate have faded.")
        end)

        self:Remove()
    end
end