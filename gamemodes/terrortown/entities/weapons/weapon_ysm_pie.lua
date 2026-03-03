local math = math

local MathMin = math.min

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
SWEP.UseHands               = false
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
end

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
        if not IsValid(self.ClientWorldModel) or self.ClientWorldModel == NULL then return end

        local owner = self:GetOwner()

        if IsValid(owner) then
            -- Don't show the pie if it's on cooldown
            if owner.TTTYorkshiremanCooldownEnd then return end

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
        if not IsValid(owner) or owner.TTTYorkshiremanCooldownEnd then
            return false
        end
        return true
    end

    function SWEP:OnRemove()
        SafeRemoveEntity(self.ClientWorldModel)
        self.ClientWorldModel = nil
    end

    function SWEP:PrimaryAttack() end
end

if SERVER then
    local yorkshireman_pie_cooldown = CreateConVar("ttt_yorkshireman_pie_cooldown", "30", FCVAR_NONE, "How long (in seconds) after the Yorkshireman eats pie before another one is ready", 1, 60)
    local yorkshireman_pie_heal = CreateConVar("ttt_yorkshireman_pie_heal", "15", FCVAR_NONE, "How much health the Yorkshireman should gain after eating a pie", 1, 100)

    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        local eaten = false
        local heal = yorkshireman_pie_heal:GetInt()

        -- Heal the dog, if they have one
        local dog = owner.TTTYorkshiremanDog
        if IsValid(dog) and dog:Alive() then
            local dogHp = dog:Health()
            local dogMax = dog:GetMaxHealth()
            if dogHp < dogMax then
                dog:EmitSound("cr4ttt_dog_eat", 100, 100, 1, CHAN_ITEM)
                dog:SetHealth(MathMin(dogMax, dogHp + heal))
                eaten = true
            end
        end

        local hp = owner:Health()
        local max = owner:GetMaxHealth()
        if hp < max then
            owner:EmitSound("yorkshireman/eat.mp3", 100, 100, 1, CHAN_ITEM)
            owner:SetHealth(MathMin(max, hp + heal))
            eaten = true
        end

        -- If either the player or the dog have eaten, put the pie on cooldown
        if eaten then
            owner:SetProperty("TTTYorkshiremanCooldownEnd", CurTime() + yorkshireman_pie_cooldown:GetInt(), owner)
        end
    end
end

function SWEP:SecondaryAttack() end

function SWEP:Think() end