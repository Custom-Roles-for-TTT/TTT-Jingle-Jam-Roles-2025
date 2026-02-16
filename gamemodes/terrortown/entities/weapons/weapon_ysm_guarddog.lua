if SERVER then
	AddCSLuaFile()
end

local ents = ents

local EntCreate = ents.Create

if CLIENT then
    SWEP.PrintName          = "Guard Dog"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 72
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/c_arms.mdl"
SWEP.WorldModel             = ""

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "normal"
SWEP.Kind                   = WEAPON_ROLE

SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.InLoadoutFor           = {ROLE_YORKSHIREMAN}
SWEP.InLoadoutForDefault    = {ROLE_YORKSHIREMAN}

SWEP.Primary.Delay          = 0.25
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 0.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.Sound        = ""

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    if CLIENT then
        self:AddHUDHelp("ysm_guarddog_help_pri", "ysm_guarddog_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

if SERVER then
    SWEP.DogSpawned         = false
    SWEP.DogEnt             = nil
    SWEP.DogMaxSpawnDist    = 100

    function SWEP:SpawnDog()
        if self.DogEnt ~= nil then return end

        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end

        local tr = owner:GetEyeTrace()
        if not tr.Hit then return end
        if tr.HitPos:Distance(owner:GetPos()) > self.DogMaxSpawnDist then return end

        local pos = tr.HitPos + Vector(0, 0, 5)
        local dog = EntCreate("ttt_ysm_dog")
        dog:SetController(owner)
        dog:SetPos(pos)
        dog:SetAngles(owner:GetAngles())
        dog:Spawn()
        dog:Activate()
        owner.TTTYorkshiremanDog = dog
    end

    function SWEP:PrimaryAttack()
        if self.DogEnt == nil then
            self:SpawnDog()
            return
        end

        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end

        local tr = owner:GetEyeTrace()
        if tr.Hit and IsValid(tr.Entity) then
            self.DogEnt:SetEnemy(tr.Enemy)
        end
    end

    function SWEP:SecondaryAttack()
        if self.DogEnt == nil then
            self:SpawnDog()
            return
        end

        self.DogEnt:ClearTarget()
    end

    function SWEP:Reload()
        if self.DogEnt == nil then
            self:SpawnDog()
            return
        end

        self.DogEnt:HandleStuck()
    end

    function SWEP:OnDrop()
        self:Remove()
    end
else
    function SWEP:PrimaryAttack() end
    function SWEP:SecondaryAttack() end
    function SWEP:Reload() end
end