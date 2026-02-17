AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Thieves' Tools"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 54
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel             = "models/weapons/w_crowbar.mdl"
SWEP.Weight                 = 5

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "melee"
SWEP.Kind                   = WEAPON_ROLE

SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.InLoadoutFor           = {}
SWEP.InLoadoutForDefault    = {ROLE_THIEF}

SWEP.Primary.Damage         = 20
SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil

SWEP.Secondary.Delay        = 0.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.Sound        = ""

function SWEP:Initialize()
    if CLIENT then
        local params = {}
        local secondary = "thf_tools_help_sec"
        if GetConVar("ttt_thief_steal_cost"):GetBool() then
            secondary = secondary .. "_cost"
            params.credits = 1
        end
        self:AddHUDHelp("thf_tools_help_pri", secondary, true, params)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:PrimaryAttack()
    local crowbar = weapons.GetStored("weapon_zm_improvised")
    -- It's hacky but it saves a lot of code duplication...
    if crowbar then
        if not self.OpenEnt then
            self.OpenEnt = crowbar.OpenEnt
        end
        return crowbar.PrimaryAttack(self)
    end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_VM_MISSCENTER)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    if not owner:IsActiveThief() then return end

    -- If the thief doesn't have enough credits, let them know
    if GetConVar("ttt_thief_steal_cost"):GetBool() and owner:GetCredits() <= 0 then
        owner:ClearQueuedMessage("thiefCredits")
        owner:QueueMessage(MSG_PRINTCENTER, "You don't have enough credits!", nil, "thiefCredits")
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        return
    end

    local spos = owner:GetShootPos()
    local sdest = spos + (owner:GetAimVector() * 70)
    local tr = util.TraceLine({ start = spos, endpos = sdest, filter = owner, mask = MASK_SHOT_HULL })
    local hitEnt = tr.Entity

    -- If the thief they can't use their abilities or they don't hit
    -- something they can rob then they effectively miss
    if owner:IsRoleAbilityDisabled() or tr.HitWorld or not IsPlayer(hitEnt) or not hitEnt:Alive() or hitEnt:IsSpec() then
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        return
    end

    -- Don't steal from people we know (or think) are friends
    if not hitEnt:CanThiefStealFrom() then
        owner:ClearQueuedMessage("thiefTarget")
        owner:QueueMessage(MSG_PRINTCENTER, "You can't steal from allies!", nil, "thiefTarget")
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        return
    end

    self:SendWeaponAnim(ACT_VM_HITCENTER)
    owner:ThiefSteal(hitEnt)
end

function SWEP:OnDrop()
    self:Remove()
end
