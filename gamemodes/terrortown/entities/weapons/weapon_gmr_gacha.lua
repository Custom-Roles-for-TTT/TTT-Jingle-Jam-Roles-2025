AddCSLuaFile()

local math = math
local net = net
local pairs = pairs
local table = table

local MathRandom = math.random
local TableHasValue = table.HasValue
local TableInsert = table.insert

if CLIENT then
    SWEP.PrintName          = "Gacha Roller"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
else
    util.AddNetworkString("TTTGachaPrizeStart")
end

SWEP.ViewModel              = "models/weapons/c_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = 0
SWEP.Primary.Sound          = ""

SWEP.InLoadoutFor = {}

local gacha_only_mode = GetConVar("ttt_gamer_gacha_only_mode")

function SWEP:Initialize()
    self.Primary.Delay = GAMER.Config.Timing.Animations.Reset
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("gmr_gacha_help_pri", "gmr_gacha_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end

local function ChooseRandomPrize(ply)
    local chance = MathRandom()
    local targetRarity = GAMER.Rarities.Common
    if chance <= GAMER.Config.Rarities[GAMER.Rarities.Legendary].Chance then
        targetRarity = GAMER.Rarities.Legendary
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Epic].Chance + GAMER.Config.Rarities[GAMER.Rarities.Legendary].Chance then
        targetRarity = GAMER.Rarities.Epic
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Rare].Chance + GAMER.Config.Rarities[GAMER.Rarities.Epic].Chance + GAMER.Config.Rarities[GAMER.Rarities.Legendary].Chance then
        targetRarity = GAMER.Rarities.Rare
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Uncommon].Chance + GAMER.Config.Rarities[GAMER.Rarities.Rare].Chance + GAMER.Config.Rarities[GAMER.Rarities.Epic].Chance + GAMER.Config.Rarities[GAMER.Rarities.Legendary].Chance then
        targetRarity = GAMER.Rarities.Uncommon
    end

    local prizes = {
        [GAMER.Rarities.Common] = {},
        [GAMER.Rarities.Uncommon] = {},
        [GAMER.Rarities.Rare] = {},
        [GAMER.Rarities.Epic] = {},
        [GAMER.Rarities.Legendary] = {}
    }
    for _, prize in pairs(GAMER.Prizes) do
        if prize.IsUnique and ply.TTTGamerHasUniquePrize then continue end

        if ply.TTTGamerPrizes and TableHasValue(ply.TTTGamerPrizes, prize.Id) then continue end
        if not prize:CanStart(ply) then continue end

        TableInsert(prizes[prize.Rarity], prize)
    end

    if #prizes[targetRarity] > 0 then
        return prizes[targetRarity][MathRandom(#prizes[targetRarity])]
    end

    -- If we can't find any prizes of the target rarity check the next lowest rarity and try again until we find a prize or run out of lower rarities
    local nextRarity = targetRarity - 1
    while nextRarity >= GAMER.Rarities.Common do
        if #prizes[nextRarity] > 0 then
            return prizes[nextRarity][MathRandom(#prizes[nextRarity])]
        end
        nextRarity = nextRarity - 1
    end

    -- If there are still no prizes in any of the lower rarities, check the next highest rarity and try again until we find a prize or run out of higher rarities
    nextRarity = targetRarity + 1
    while nextRarity <= GAMER.Rarities.Legendary do
        if #prizes[nextRarity] > 0 then
            return prizes[nextRarity][MathRandom(#prizes[nextRarity])]
        end
        nextRarity = nextRarity + 1
    end

    -- TODO: If there still aren't any prizes then what...
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    if GetRoundState() ~= ROUND_ACTIVE then return end

    local ammo = self:Clip1()
    if ammo <= 0 then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    local timerId = "TTTGmrGachaPrize_" .. owner:SteamID64()
    if timer.Exists(timerId) then return end

    if owner:IsRoleAbilityDisabled() then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    owner:LagCompensation(true)

    if gacha_only_mode:GetBool() then
        if SERVER then
            owner:SubtractCredits(1)
        end
    else
        self:SetClip1(ammo - 1)
    end
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    if SERVER then
        local prize = ChooseRandomPrize(owner)
        net.Start("TTTGamerGachaStart")
            net.WriteString(prize.Id)
        net.Send(owner)

        timer.Create(timerId, GAMER.Config.Timing.Effect, 1, function()
            timer.Remove(timerId)
            if not IsPlayer(owner) then return end
            prize:Start(owner)
            net.Start("TTTGachaPrizeStart")
                net.WriteString(prize.Id)
            net.Send(owner)

            if prize.IsUnique then
                owner.TTTGamerHasUniquePrize = true
            end

            if not owner.TTTGamerPrizes then
                owner.TTTGamerPrizes = {}
            end
            TableInsert(owner.TTTGamerPrizes, prize.Id)
        end)

        if ammo == 1 and not gacha_only_mode:GetBool() then
            self:Remove()
        end
    end

    owner:LagCompensation(false)
end

function SWEP:DryFire() return false end