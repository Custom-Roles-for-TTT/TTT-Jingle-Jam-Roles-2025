AddCSLuaFile()

if CLIENT then
    SWEP.PrintName          = "Safe"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/sudisteprops/simple_safe.mdl"
-- For some reason, setting this to the model we actually want to use
-- is creating a second model floating in the sky, but if we set it to an
-- invalid model then nothing shows up. Setting it to an empty string
-- causes "DrawWorldModel" to be skipped, so here we are with fake.mdl
SWEP.WorldModel             = "fake.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = false
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "normal"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = false
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.InLoadoutFor           = {}
SWEP.InLoadoutForDefault    = {}

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
    if CLIENT then
        self:AddHUDHelp("sfk_safe_help_pri", "sfk_safe_help_sec", true)
    end
    self:SetWeaponHoldType(self.HoldType)
end

if CLIENT then
    local function ScaleModel(mdl, amt)
        local scale = Vector(amt, amt, amt)
        for i=0, mdl:GetBoneCount() - 1 do
            mdl:ManipulateBoneScale(i, scale)
        end
    end

    function SWEP:GetViewModelPosition(pos, ang)
        ang:RotateAroundAxis(ang:Right(), -90)
        pos = pos + (ang:Up() * 45) + (ang:Forward() * 20)
        return pos, ang
    end

    function SWEP:PreDrawViewModel(vm, weapon, ply, flags)
        ScaleModel(vm, 0.5)
    end

    -- Reset the scale of the view model after drawing it to fix a weird case where other weapons got scaled down
    -- even after the player no longer had this one
    function SWEP:PostDrawViewModel(vm, weapon, ply, flags)
        ScaleModel(vm, 1)
    end

    -- Adapted from: https://wiki.facepunch.com/gmod/WEAPON:DrawWorldModel
    SWEP.ClientWorldModel = nil
    function SWEP:DrawWorldModel(flags)
        if not IsValid(self.ClientWorldModel) or self.ClientWorldModel == NULL then
            self.ClientWorldModel = ClientsideModel(self.ViewModel)
            self.ClientWorldModel:SetNoDraw(true)
            ScaleModel(self.ClientWorldModel, 0.5)
        end

        local owner = self:GetOwner()

        if IsValid(owner) then
            -- Set the safe roughly 1/2 way up the player's model and out in front a little bit
            local offsetVec = Vector(30, 0, -5)
            local heightPos = owner:GetPos() + Vector(0, 0, owner:GetHeight() / 2)
            local wepPos = self:GetPos()
            local mergedPos = Vector(wepPos.x, wepPos.y, heightPos.z)

            -- Rotate it so the dial shows in the front
            local offsetAng = Angle(0, 90, 0)

            -- Translate it into the world
            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, mergedPos, self:GetAngles())

            self.ClientWorldModel:SetPos(newPos)
            self.ClientWorldModel:SetAngles(newAng)

            self.ClientWorldModel:SetupBones()
        else
            self.ClientWorldModel:SetPos(self:GetPos())
            self.ClientWorldModel:SetAngles(self:GetAngles())
        end

        self.ClientWorldModel:DrawModel()
    end

    function SWEP:OnRemove()
        SafeRemoveEntity(self.ClientWorldModel)
        self.ClientWorldModel = nil
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    local safe = ents.Create("ttt_safekeeper_safe")
    local eyeAngles = owner:EyeAngles()
    local ang = Angle(0, eyeAngles.y, 0)
    ang:RotateAroundAxis(Vector(0, 0, 1), 90)

    -- Drop the safe in front of the player
    local offset = owner:GetShootPos() + eyeAngles:Forward() * 50
    offset.z = owner:GetPos().z + 5

    -- Spawn the safe
    safe:SetPos(offset)
    safe:SetAngles(ang)
    safe:SetPlacer(owner)
    safe:Spawn()
    safe:Activate()

    owner:SetProperty("TTTSafekeeperSafe", safe:EntIndex())
    owner:ClearProperty("TTTSafekeeperDropTime", owner)
    self:Remove()
end

function SWEP:SecondaryAttack() end

function SWEP:Reload()
   return false
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Holster(wep)
    -- Drop the safe when the player changes weapons or dies
    self:PrimaryAttack()
end