AddCSLuaFile()

local hook = hook
local render = render
local surface = surface
local table = table
local util = util

local AddHook = hook.Add
local RemoveHook = hook.Remove
local TableInsert = table.insert

if CLIENT then
    SWEP.PrintName          = "Stove Placer"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/c_toolgun.mdl"
SWEP.WorldModel             = "models/weapons/w_toolgun.mdl"
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
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.InLoadoutFor           = {ROLE_CHEF}
SWEP.InLoadoutForDefault    = {ROLE_CHEF}

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

SWEP.GhostMinBounds         = Vector(-6.5, -9.4, -12.2)
SWEP.GhostMaxBounds         = Vector(6.5, 9.4, 12.2)

SWEP.SelectedFoodType       = CHEF_FOOD_TYPE_NONE
SWEP.StoveModel             = "models/props_forest/stove01.mdl"

local stove_health = CreateConVar("ttt_chef_stove_health", "500", FCVAR_REPLICATED, "How much health the stove should have", 1, 2000)

function SWEP:Initialize()
    if CLIENT then
        self:AddHUDHelp("chf_stove_help_pri", "chf_stove_help_sec", true)

        local hide_role = GetConVar("ttt_hide_role")
        local hookId = "Chef_TTTHUDInfoPaint_" .. self:EntIndex()
        AddHook("TTTHUDInfoPaint", hookId, function(client, label_left, label_top, active_labels)
            if hide_role:GetBool() then return end
            if not IsValid(self) then
                RemoveHook("TTTHUDInfoPaint", hookId)
                return
            end

            local owner = self:GetOwner()
            if not IsPlayer(owner) then return end
            if client ~= owner then return end

            surface.SetFont("TabLarge")
            surface.SetTextColor(255, 255, 255, 230)

            local text = LANG.GetTranslation("chf_buff_type_label") .. LANG.GetTranslation("chf_buff_type_" .. self.SelectedFoodType)
            local _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels there are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            TableInsert(active_labels, "chef_buff")

            text = LANG.GetTranslation("chf_stove_type_label") .. LANG.GetTranslation("chf_stove_type_" .. self.SelectedFoodType)
            _, h = surface.GetTextSize(text)

            -- Move this up again for the previous label
            label_top = label_top + 20

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            TableInsert(active_labels, "chef_stove")
        end)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:GetAimTrace(owner)
    local aimStart = owner:EyePos()
    local aimDir = owner:GetAimVector()
    local len = 128

    local aimTrace = util.TraceHull({
        start = aimStart,
        endpos = aimStart + aimDir * len,
        mins = self.GhostMinBounds,
        maxs = self.GhostMaxBounds,
        filter = owner
    })

    -- This only counts as hitting if the thing we hit is below us
    return aimTrace, aimTrace.Hit and aimTrace.HitNormal.z > 0.7
end

function SWEP:PrimaryAttack()
    if CLIENT then return end
    if self.SelectedFoodType == CHEF_FOOD_TYPE_NONE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if owner:IsRoleAbilityDisabled() then return end

    local tr, hit = self:GetAimTrace(owner)
    if not hit then return end

    local stove = ents.Create("ttt_chef_stove")
    local eyeAngles = owner:EyeAngles()
    local ang = Angle(0, eyeAngles.y, 0)
    ang:RotateAroundAxis(Vector(0, 0, 1), 180)

    local offset = owner:GetAimVector() * 15
    offset.z = -5

    -- Spawn the stove
    stove:SetPos(tr.HitPos - offset)
    stove:SetAngles(ang)
    stove:SetPlacer(owner)
    stove:SetFoodType(self.SelectedFoodType)

    local health = stove_health:GetInt()
    stove:SetHealth(health)
    stove:SetMaxHealth(health)

    stove:Spawn()

    self:Remove()
end

function SWEP:SecondaryAttack()
    if not IsFirstTimePredicted() then return end
    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    self.SelectedFoodType = self.SelectedFoodType + 1
    if self.SelectedFoodType > CHEF_FOOD_TYPE_FISH then
        self.SelectedFoodType = CHEF_FOOD_TYPE_NONE
    end

    if CLIENT then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    net.Start("TTTChefFoodChanged")
        net.WriteUInt(self.SelectedFoodType, 3)
    net.Send(owner)
end

function SWEP:ViewModelDrawn()
    if SERVER then return end
    if self.SelectedFoodType == CHEF_FOOD_TYPE_NONE then return end

    local owner = self:GetOwner()
    if not IsPlayer(owner) then return end

    if not IsValid(self.GhostEnt) then
        self.GhostEnt = ClientsideModel(self.StoveModel)
        -- Scale this down to match (roughly) the size it will be in the world
        self.GhostEnt:SetModelScale(0.6)
    end

    -- Draw a box where the stove will be placed, colored GREEN for a good location and RED for a bad one
    local tr, hit = self:GetAimTrace(owner)
    local eyeAngles = owner:EyeAngles()
    local ang = Angle(0, eyeAngles.y, 0)
    ang:RotateAroundAxis(Vector(0, 0, 1), 180)

    render.Model({
        model = self.StoveModel,
        pos = tr.HitPos - Vector(0, 0, 5),
        angle = ang
    }, self.GhostEnt)
    render.DrawWireframeBox(tr.HitPos, ang, Vector(-6.5, -9.4, -14.5), Vector(8, 9.4, 10), hit and COLOR_GREEN or COLOR_RED, true)
end

function SWEP:Reload()
   return false
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:OnRemove()
    if CLIENT then
        SafeRemoveEntity(self.GhostEnt)
        self.GhostEnt = nil

        local owner = self:GetOwner()
        if IsValid(owner) and owner == LocalPlayer() and owner:Alive() then
            RunConsoleCommand("lastinv")
        end
    end
end

function SWEP:Think()
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end