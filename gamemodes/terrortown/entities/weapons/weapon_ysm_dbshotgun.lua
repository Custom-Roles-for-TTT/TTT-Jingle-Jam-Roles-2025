if SERVER then AddCSLuaFile() end

local IsValid = IsValid
local math = math

SWEP.HoldType = "shotgun"

if CLIENT then
    SWEP.PrintName = "Double Barrel"
    SWEP.Slot = 2
end

SWEP.Base = "weapon_tttbase"
SWEP.Category = WEAPON_CATEGORY_ROLE

SWEP.Kind = WEAPON_HEAVY

-- Don't use a loadout because we may need to remove a weapon in the same slot first
SWEP.InLoadoutFor = {}
SWEP.InLoadoutForDefault = {}

SWEP.Primary.Ammo = "Buckshot"
SWEP.Primary.Damage = 10
SWEP.Primary.Cone = 0.13
SWEP.Primary.Delay = 0.5
SWEP.Primary.ClipSize = 2
SWEP.Primary.ClipMax = 2
SWEP.Primary.DefaultClip = 4
SWEP.Primary.Automatic = true
SWEP.Primary.NumShots = 12
SWEP.Primary.Sound = "weapons/ttt/dbsingle.wav"
SWEP.Primary.Recoil = 15

SWEP.Secondary.Sound = "weapons/ttt/dbblast.wav"
SWEP.Secondary.Recoil = 40

SWEP.AmmoEnt = "item_box_buckshot_ttt"
SWEP.AllowDrop = false
SWEP.UseHands = false
SWEP.ReloadTimer = 0

SWEP.ViewModelFlip = false
SWEP.ViewModelFOV = 70
SWEP.ViewModel = "models/weapons/v_old_doublebarrel.mdl"
SWEP.WorldModel = "models/weapons/w_old_doublebarrel.mdl"

local yorkshireman_shotgun_damage = CreateConVar("ttt_yorkshireman_shotgun_damage", "10", FCVAR_REPLICATED, "How much damage the Yorkshireman's double barrel shotgun should do", 0, 100)

function SWEP:SetupDataTables()
    self:NetworkVar("Bool", "Reloading")
end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
    return self.BaseClass.Initialize(self)
end

function SWEP:Deploy()
    self.Primary.Damage = yorkshireman_shotgun_damage:GetInt()
    self.ReloadTimer = 0
    self:SetReloading(false)
    return self.BaseClass.Deploy(self)
end

function SWEP:OnDrop()
   self:Remove()
end

function SWEP:CanPrimaryAttack()
    if self:Clip1() <= 0 then
        self:EmitSound("Weapon_Shotgun.Empty")
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        return false
    end
    return true
end

function SWEP:GetHeadshotMultiplier(victim, dmginfo)
    local att = dmginfo:GetAttacker()
    if not IsValid(att) then return 2 end

    local dist = victim:GetPos():Distance(att:GetPos())
    local d = math.max(0, dist - 140)

    -- decay from 3 to 1 as distance increases
    return 1 + math.max(0, 2 - 0.002 * (d ^ 1.25))
end

function SWEP:SecondaryAttack(worldsnd)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local bullets = self:Clip1()
    if bullets == 0 then
        self:Reload()
        return
    end

    local bulletSound
    local bulletRecoil
    if bullets == 1 then
        bulletSound = self.Primary.Sound
        bulletRecoil = self.Primary.Recoil
    else
        bulletSound = self.Secondary.Sound
        bulletRecoil = self.Secondary.Recoil
    end

    if not worldsnd then
        self:EmitSound(bulletSound, self.Primary.SoundLevel)
    elseif SERVER then
        sound.Play(bulletSound, self:GetPos(), self.Primary.SoundLevel)
    end

    self:ShootBullet(self.Primary.Damage, bulletRecoil, self.Primary.NumShots * bullets, self:GetPrimaryCone())
    self:TakePrimaryAmmo(bullets)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if SERVER then
        -- Give them the ammo back so they have infinite ammo, but have to reload
        owner:GiveAmmo(bullets, self.Primary.Ammo)
    end

    if owner:IsNPC() or not owner.ViewPunch then return end
    owner:ViewPunch(Angle(math.Rand(-0.2, -0.1) * bulletRecoil, math.Rand(-0.1, 0.1) * bulletRecoil, 0))
end

function SWEP:Reload()
    if self:GetReloading() then return end
    if not IsFirstTimePredicted() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    if self:Clip1() >= self.Primary.ClipSize then return end

    owner:GetViewModel():SetPlaybackRate(2)
    self:StartReload()
end

function SWEP:StartReload()
    if self:GetReloading() then return false end
    if not IsFirstTimePredicted() then return false end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return false end
    if self:Clip1() >= self.Primary.ClipSize then return false end

    self:SetReloading(true)
    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
    self.ReloadTimer = CurTime() + self:SequenceDuration()

    return true
end

function SWEP:PerformReload()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then return end
    if self:Clip1() >= self.Primary.ClipSize then return end

    owner:RemoveAmmo(1, self.Primary.Ammo, false)
    self:SetClip1(self:Clip1() + 1)
    self:SendWeaponAnim(ACT_VM_RELOAD)
    self.ReloadTimer = CurTime() + self:SequenceDuration()
end

function SWEP:FinishReload()
    self:SetReloading(false)
    self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
    self.ReloadTimer = CurTime() + self:SequenceDuration()
end

function SWEP:Think()
    if not self:GetReloading() then return end
    if not IsFirstTimePredicted() then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    if owner:KeyDown(IN_ATTACK) then
        self:FinishReload()
        return
    end

    if self.ReloadTimer <= CurTime() then
        if owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
            self:FinishReload()
        elseif self:Clip1() < self.Primary.ClipSize then
            self:PerformReload()
        else
            self:FinishReload()
        end
    end
end