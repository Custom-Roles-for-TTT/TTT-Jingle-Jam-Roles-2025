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
    function SWEP:GetViewModelPosition(pos, ang)
        ang:RotateAroundAxis(ang:Right(), -90)
        pos = pos + (ang:Up() * 45) + (ang:Forward() * 20)
        return pos, ang
    end

    -- Adapted from: https://wiki.facepunch.com/gmod/WEAPON:DrawWorldModel
    SWEP.ClientWorldModel = nil
    function SWEP:DrawWorldModel(flags)
        if not IsValid(self.ClientWorldModel) or self.ClientWorldModel == NULL then
            self.ClientWorldModel = ClientsideModel(self.ViewModel)
            self.ClientWorldModel:SetNoDraw(true)
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

        local owner = self:GetOwner()
        if IsValid(owner) and owner == LocalPlayer() and owner:Alive() then
            RunConsoleCommand("lastinv")
        end
    end
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
	if not IsFirstTimePredicted() then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    -- Ignore the up-and-down component of where the player is aiming
    local aimVec = owner:GetAimVector()
    aimVec.z = 0
    -- Convert it to an angle and use that as the start position
    local eyeAngles = aimVec:Angle()
    local startPos = owner:GetPos()
    -- If the player is alive, place it in front of them
    if owner:Alive() and not owner:IsSpec() then
        startPos = startPos + eyeAngles:Forward() * 55
    end

    -- Find a location to drop the safe in front of the player
    local length = 100
    local tr = util.TraceLine({
        start = startPos + Vector(0, 0, 5),
        endpos = startPos + eyeAngles:Up() * -length
    })

    local safePos
    -- Make sure the hit isn't at the end of the length because that seems to mean it actually hasn't hit anything
    if tr.Hit and tr.HitPos:Distance(startPos) < length then
        safePos = tr.HitPos
        safePos.z = safePos.z + 5
    -- If we didn't find a place, let the user know and don't actually place the safe
    else
        owner:ClearQueuedMessage("sfkInvalidDrop")
        owner:QueueMessage(MSG_PRINTBOTH, "Could not find valid location for safe! Try somewhere else.", nil, "sfkInvalidDrop")
        return
    end

    local safe = ents.Create("ttt_safekeeper_safe")
    local ang = Angle(0, eyeAngles.y, 0)
    ang:RotateAroundAxis(Vector(0, 0, 1), 90)

    -- Spawn the safe
    safe:SetPos(safePos)
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
	if not IsFirstTimePredicted() then return end

    -- Drop the safe when the player changes weapons or dies
    self:PrimaryAttack()
    -- Don't actually let them holster it because if the drop fails then we want them to keep the safe
    -- If they are dead then this might not work very well but of well
    return false
end