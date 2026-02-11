AddCSLuaFile()

local SetMDL = FindMetaTable("Entity").SetModel
if not SetMDL then return end

local math = math
local net = net
local player = player
local ipairs = ipairs
local util = util

local MathRandom = math.random
local PlayerIterator = player.Iterator

if CLIENT then
    SWEP.PrintName          = "Target Picker"
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

SWEP.Primary.Delay          = 0.2
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 0.2
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_CLONE}
SWEP.InLoadoutForDefault    = {ROLE_CLONE}

if SERVER then
    CreateConVar("ttt_clone_minimum_radius", "5", FCVAR_NONE, "The minimum radius of the clone's device in meters. Set to 0 to disable", 0, 30)
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("clonetargetpicker_help_pri", nil, true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end

    self:DrawShadow(false)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

local function GetRandomWithExclude(min, max, exclude)
    if max == min then return exclude end

    local target = exclude
    while target == exclude do
        target = MathRandom(min, max)
    end
    return target
end

-- From The Stig's "Leg Day" Randomat event
local boneList = {"ValveBiped.Bip01_Pelvis", "ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_L_Toe0", "ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Toe0"}
local boneModList = {Vector(0, 0, -38), Vector(-3.9, 0, 0), Vector(-16, 0, 0), Vector(-16, 0, 0), Vector(-6.31, 0, 0), Vector(3.9, 0, 0), Vector(-16, 0, 0), Vector(-16, 0, 0), Vector(-6.31, 0, 0)}
local function ScalePlayerLegs(ply, scale)
    for i = 1, #boneList do
        local boneId = ply:LookupBone(boneList[i])
        if boneId ~= nil then
            local currentScale = ply:GetManipulateBoneScale(boneId)
            ply:ManipulateBoneScale(boneId, Vector(scale * currentScale[1], scale * currentScale[2], scale * currentScale[3]))
            ply:ManipulateBonePosition(boneId, boneModList[i] - boneModList[i] * scale)
        end
    end
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if owner:IsRoleAbilityDisabled() then return end

    local trace = util.GetPlayerTrace(owner)
    local tr = util.TraceLine(trace)
    if IsPlayer(tr.Entity) then
        local ply = tr.Entity
        local radius = GetConVar("ttt_clone_minimum_radius"):GetFloat() * UNITS_PER_METER
        if radius == 0 or ply:GetPos():Distance(owner:GetPos()) <= radius then
            if not GetConVar("ttt_clone_target_detectives"):GetBool() and ply:IsDetectiveTeam() then
                owner:QueueMessage(MSG_PRINTCENTER, "You cannot clone " .. ROLE_STRINGS_EXT[ROLE_DETECTIVE] .. ", choose someone else!")
                return
            end

            local perfect_clone = GetConVar("ttt_clone_perfect_clone"):GetBool()
            SetMDL(owner, ply:GetModel())

            -- Change bodygroups more often because there's usually more of them
            local imperfect_bodygroup = not perfect_clone and MathRandom(100) <= 75
            for _, value in ipairs(ply:GetBodyGroups()) do
                local target_group = ply:GetBodygroup(value.id)
                local group_count = ply:GetBodygroupCount(value.id)
                if imperfect_bodygroup and group_count > 1 then
                    local temp_group = GetRandomWithExclude(1, group_count, target_group)
                    -- Don't change any of the other body parameters if this changed
                    perfect_clone = temp_group ~= target_group
                    target_group = temp_group
                end

                owner:SetBodygroup(value.id, target_group)
            end

            -- Skin count is 0-indexed for some reason
            local skin_count = ply:SkinCount() - 1
            local target_skin = ply:GetSkin()
            -- If we need to make this imperfect and there are multiple skins...
            if not perfect_clone and skin_count > 0 then
                local temp_skin = GetRandomWithExclude(0, skin_count, target_skin)
                -- Don't change any of the other body parameters if this changed
                perfect_clone = temp_skin ~= target_skin
                target_skin = temp_skin
            end
            owner:SetSkin(target_skin)

            owner:SetColor(ply:GetColor())

            if not perfect_clone then
                -- If nothing has been tweaked yet, make them a little bit shorter
                -- This seems to automatically reset when the round restarts so we don't have to do anything about it
                ScalePlayerLegs(owner, 0.9)
            end

            owner:SetProperty("TTTCloneTarget", ply:SteamID64())
            net.Start("TTT_ClonePlayerCloned")
                net.WriteString(owner:Nick())
                net.WriteString(ply:Nick())
            net.Broadcast()

            -- Let everyone know
            local message = " now a perfect clone of " .. ply:Nick() .. "!"
            owner:QueueMessage(MSG_PRINTBOTH, "You are" .. message)
            message = owner:Nick() .. " is" .. message
            for _, p in PlayerIterator() do
                if owner == p then continue end
                p:QueueMessage(MSG_PRINTBOTH, message)
            end

            self:Remove()
        end
    end
end

function SWEP:SecondaryAttack() end