if SERVER then
    AddCSLuaFile()
end

if CLIENT then
    ENT.TargetIDHint = function(dog)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local name
        if not IsValid(dog) or dog:GetController() ~= client then
            name = LANG.GetTranslation("ysm_dog_name")
        else
            name = LANG.GetParamTranslation("ysm_dog_name_health", { current = dog:Health(), max = dog:GetMaxHealth() })
        end

        return {
            name = name,
            hint = nil
        }
    end
    ENT.AutomaticFrameAdvance = true
end

ENT.Type         = "nextbot"
ENT.Base         = "base_nextbot"

ENT.LoseDistance = 2000
ENT.SearchRadius = 1000

-- TODO: Skeleton, movement, targeting, unstuck, sounds
-- TODO: Health regen by convar?

if SERVER then
    CreateConVar("ttt_yorkshireman_dog_health", "100", FCVAR_NONE, "How much health the Yorkshireman's Guard Dog should have", 1, 200)
    CreateConVar("ttt_yorkshireman_dog_damage", "20", FCVAR_NONE, "How much damage the Yorkshireman's Guard Dog should do", 1, 200)
end

AccessorFuncDT(ENT, "Damage", "Damage")
AccessorFuncDT(ENT, "Controller", "Controller")
AccessorFuncDT(ENT, "Enemy", "Enemy")

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "Damage")
   self:DTVar("Entity", 1, "Controller")
   self:DTVar("Entity", 0, "Enemy")
end

function ENT:Initialize()
    self:SetModel("models/cr4ttt_ysm/npc_dog.mdl")

    if SERVER then
        local health = GetConVar("ttt_yorkshireman_dog_health"):GetInt()
        self:SetHealth(health)
        self:SetMaxHeal(health)
        self:SetDamage(GetConVar("ttt_yorkshireman_dog_damage"):GetInt())

        self:SetVar("Attacking", false)
        self:SetEnemy(nil)

        -- TODO: Register sounds
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end