local ents = ents
local math = math

local EntsCreate = ents.Create
local MathCeil = math.ceil

AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Button Transformer"
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

SWEP.InLoadoutFor           = {ROLE_BUTTON}
SWEP.InLoadoutForDefault    = {ROLE_BUTTON}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 3
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.Sound        = ""

SWEP.Button                 = nil
SWEP.TransformBackTime      = nil

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)

    if CLIENT then
        self:AddHUDHelp("btn_transformer_help_pri", "btn_transformer_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:Equip()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    if self:GetNextPrimaryFire() > CurTime() then return end
    if IsValid(self.Button) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DETONATE)

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    local ent = EntsCreate("ttt_button_button")
    if not IsValid(ent) then return end

    -- Spawn the button at a little bit less than eye level
    local eyes = owner:EyePos()
    local feet = owner:GetPos()
    local height = (eyes.z - feet.z) * 0.8
    local pos = feet + Vector(0, 0, height)

    ent:SetPos(pos)
    -- Make sure the button is on the ground
    ent:DropToFloor(MASK_BLOCKLOS)
    local floor = ent:GetPos()
    ent:SetPos(floor + Vector(0, 0, height))

    ent:SetHeight(height)

    ent.ButtonPly = owner
    ent:Spawn()

    owner:SetParent(ent)

    owner:Spectate(OBS_MODE_CHASE)
    owner:SpectateEntity(ent)
    owner.ButtonEnt = ent

    -- The transformer stays in their hand so hide it from view
    owner:DrawViewModel(false)
    owner:DrawWorldModel(false)

    self.Button = ent
    self.TransformBackTime = CurTime() + self.Secondary.Delay
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    if not IsValid(self.Button) then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if self.Button:GetPressed() then
        owner:ClearQueuedMessage("btnTransformerBlock")
        owner:QueueMessage(MSG_PRINTBOTH, "You can't transform back while the timer is running...", nil, "btnTransformerBlock")
        return
    end

    if self.TransformBackTime and self.TransformBackTime > CurTime() then
        local remaining = MathCeil(self.TransformBackTime - CurTime())
        local plural = remaining > 1 and "s" or ""
        owner:ClearQueuedMessage("btnTransformerBlock")
        owner:QueueMessage(MSG_PRINTBOTH, "You have to wait about " .. remaining .. " more second" .. plural .. " before changing back...", nil, "btnTransformerBlock")
        return
    end

    owner:SetParent(nil)
    owner:SpectateEntity(nil)
    owner:UnSpectate()
    local pos = owner:GetPos()
    owner:SetPos(pos - Vector(0, 0, owner.ButtonEnt:GetHeight()))
    owner:DrawViewModel(true)
    owner:DrawWorldModel(true)
    owner:SetNoDraw(false)

    owner.ButtonEnt = nil

    self.Button:Remove()
    self.Button = nil
    self.TransformBackTime = nil
end

function SWEP:OnDrop()
    self:Remove()
end

if SERVER then
    function SWEP:Holster()
        -- Don't let them switch weapons while they are a button
        return not IsValid(self.Button)
    end
end