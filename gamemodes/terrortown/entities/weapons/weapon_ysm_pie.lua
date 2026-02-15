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
SWEP.HoldType               = "grenade"
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

-- TODO: Skeleton, model, eat, cooldown