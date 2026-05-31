AddCSLuaFile()

local math = math
local net = net
local pairs = pairs
local table = table

local MathRandom = math.random
local TableInsert = table.insert

if CLIENT then
    SWEP.PrintName          = "Gacha Roller"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
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

-- TODO: Set this to the roll time + some delay
SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = 0
SWEP.Primary.Sound          = ""

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
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
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Epic].Chance then
        targetRarity = GAMER.Rarities.Epic
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Rare].Chance then
        targetRarity = GAMER.Rarities.Rare
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Uncommon].Chance then
        targetRarity = GAMER.Rarities.Uncommon
    end

    local prizes = {}
    for _, prize in pairs(GAMER.Prizes) do
        -- TODO: Check if this player already has a unique prize. If so, skip other unique prizes
        -- TODO: What happens if a player gets a duplicate?
        if prize.Rarity == targetRarity then
            TableInsert(prizes, prize)
        end
    end

    -- TODO: What if prizes is empty somehow?

    -- TODO: For testing
    if #prizes == 0 then
        prizes = {GAMER.Prizes["doritos"]}
    end

    return prizes[MathRandom(#prizes)]
end

function SWEP:PrimaryAttack()
    if self:GetNextPrimaryFire() > CurTime() then return end
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if GetRoundState() ~= ROUND_ACTIVE then return end

    local ammo = self:Clip1()
    if ammo <= 0 then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    self:SetClip1(ammo - 1)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    if SERVER then
        local prize = ChooseRandomPrize(owner)
        net.Start("TTTGamerGachaStart")
            net.WriteString(prize.Id)
        net.Send(owner)

        -- TODO: Start the prize's effect after the display timer elapses

        if ammo == 1 then
            self:Remove()
        end
    end
end

function SWEP:DryFire() return false end

-- TODO: End all prize effects on round state changes (End, Prep, etc.)