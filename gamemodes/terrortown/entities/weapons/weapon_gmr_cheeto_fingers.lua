AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Cheeto Fingers"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 10
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

-- TODO: Use a different model
SWEP.ViewModel              = ""
SWEP.WorldModel             = ""
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "normal"
SWEP.Kind                   = WEAPON_ROLE + 1

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

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
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

    -- TODO: Animation
    -- TODO: Color the hand orange?
    -- TODO: Mark someone as tracked (via halo?)

    if SERVER and self:Clip1() == 0 then
        self:Remove()
    end
end

function SWEP:DrawWorldModel(flags) end
function SWEP:DrawWorldModelTranslucent(flags) end