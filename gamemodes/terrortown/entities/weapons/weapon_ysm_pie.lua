if CLIENT then
    SWEP.PrintName          = "Pie"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/cr4ttt_ysm/pie.mdl"
SWEP.WorldModel             = "models/cr4ttt_ysm/pie.mdl"
SWEP.Weight                 = 2

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

if CLIENT then
    local function ScaleModel(mdl, amt)
        local scale = Vector(amt, amt, amt)
        for i=0, mdl:GetBoneCount() - 1 do
            mdl:ManipulateBoneScale(i, scale)
        end
    end

    function SWEP:GetViewModelPosition(pos, ang)
        pos = pos + ang:Forward()*6 + ang:Right()*2.25 - ang:Up()*2
        return pos, ang
    end

    function SWEP:PreDrawViewModel(vm, weapon, ply, flags)
        ScaleModel(vm, 0.125)
    end

    -- Reset the scale of the view model after drawing it to fix a weird case where other weapons got scaled down
    -- even after the player no longer had this one
    function SWEP:PostDrawViewModel(vm, weapon, ply, flags)
        ScaleModel(vm, 1)
    end

    -- From: https://wiki.facepunch.com/gmod/WEAPON:DrawWorldModel
    SWEP.ClientWorldModel = ClientsideModel(SWEP.WorldModel)
    SWEP.ClientWorldModel:SetNoDraw(true)
    ScaleModel(SWEP.ClientWorldModel, 0.5)

    function SWEP:DrawWorldModel(flags)
        local owner = self:GetOwner()

        if IsValid(owner) then
            -- Don't show the pie if it's on cooldown
            if owner.TTTYorkshiremanCooldownStart then return end

            -- Specify a good position
            local offsetVec = Vector(5, -2.7, -3.4)
            local offsetAng = Angle(180, 90, 0)

            local bone = owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
            if not bone then
                self:DrawModel(flags)
                return
            end

            local matrix = owner:GetBoneMatrix(bone)
            if not matrix then
                self:DrawModel(flags)
                return
            end

            local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

            self.ClientWorldModel:SetPos(newPos)
            self.ClientWorldModel:SetAngles(newAng)

            self.ClientWorldModel:SetupBones()
        else
            self.ClientWorldModel:SetPos(self:GetPos())
            self.ClientWorldModel:SetAngles(self:GetAngles())
        end

        self.ClientWorldModel:DrawModel()
    end

    function SWEP:ShouldDrawViewModel()
        -- Don't show the pie if it's on cooldown
        local owner = self:GetOwner()
        if not IsValid(owner) or owner.TTTYorkshiremanCooldownStart then
            return false
        end
        return true
    end

    function SWEP:OnRemove()
        SafeRemoveEntity(self.ClientWorldModel)
        self.ClientWorldModel = nil
    end
end

function SWEP:Think() end

function SWEP:Initialize()
    self:SetWeaponHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    -- TODO: Heal, play sound
    print(owner, "PF")
    owner:SetProperty("TTTYorkshiremanCooldownStart", CurTime(), owner)
end

function SWEP:SecondaryAttack() end