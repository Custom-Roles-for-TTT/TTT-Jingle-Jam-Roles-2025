local ents = ents
local hook = hook
local player = player

local AddHook = hook.Add
local CreateEntity = ents.Create
local PlayerIterator = player.Iterator

local ROLE = {}

ROLE.nameraw = "chef"
ROLE.name = "Chef"
ROLE.nameplural = "Chefs"
ROLE.nameext = "a Chef"
ROLE.nameshort = "chf"

ROLE.desc = [[You are {role}!
]]
ROLE.shortdesc = ""

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars =
{
    {
        cvar = "ttt_chef_cook_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_overcook_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_damage_own_stove",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_chef_warn_damage",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_chef_warn_destroy",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_chef_hat_enabled",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["chf_stove_name"] = "Stove",
        ["chf_stove_name_health"] = "Stove ({current}/{max})",
        ["chf_stove_hint_start"] = "Press {usekey} to start cooking",
        ["chf_stove_hint_progress"] = "Cooking: {time} remaining",
        ["chf_stove_hint_retrieve_2"] = "Press {usekey} to retrieve cooked food before it burns in {time}!",
        ["chf_stove_hint_retrieve_3"] = "Press {usekey} to retrieve burnt food",
        ["chf_stove_damaged"] = "Your Stove has been damaged!",
        ["chf_stove_help_pri"] = "Use {primaryfire} to place your Stove on the ground",
        ["chf_stove_help_sec"] = "Use {secondaryfire} to change the food and buff type",
        ["chf_stove_type_label"] = "Stove Type: ",
        ["chf_stove_type_0"] = "None",
        ["chf_stove_type_1"] = "Burger",
        ["chf_stove_type_2"] = "Hot Dog",
        ["chf_stove_type_3"] = "Fish",
        ["chf_buff_type_label"] = "Buff Type: ",
        ["chf_buff_type_0"] = "None",
        ["chf_buff_type_1"] = "Speed Boost",
        ["chf_buff_type_2"] = "Health Regen.",
        ["chf_buff_type_3"] = "Damage Boost"
    }
}

if SERVER then
    ------------------
    -- ROLE CONVARS --
    ------------------

    local hat_enabled = CreateConVar("ttt_chef_hat_enabled", "1", FCVAR_NONE, "Whether the chef gets a hat", 0, 1)

    -------------------
    -- ROLE FEATURES --
    -------------------

    ROLE.onroleassigned = function(ply)
        if not hat_enabled:GetBool() then return end
        if not IsPlayer(ply) then return end

        -- If they already have a hat, don't put another on
        if IsValid(ply.hat) then return end

        -- Don't put a hat on a player who doesn't have a head
        local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
        if not bone then return end

        local hat = CreateEntity("ttt_chef_hat")
        if not IsValid(hat) then return end

        hat:SetPos(ply:GetPos())
        hat:SetAngles(ply:GetAngles())
        hat:SetParent(ply)

        ply.TTTChefHat = hat
        hat:Spawn()
    end

    AddHook("TTTPlayerRoleChanged", "Chef_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole == newRole then return end
        if oldRole ~= ROLE_CHEF then return end
        if not IsValid(ply.TTTChefHat) then return end

        SafeRemoveEntity(ply.TTTChefHat)
        ply.TTTChefHat = nil
    end)
end

RegisterRole(ROLE)

-- Role features
CHEF_FOOD_TYPE_NONE = 0
CHEF_FOOD_TYPE_BURGER = 1
CHEF_FOOD_TYPE_HOTDOG = 2
CHEF_FOOD_TYPE_FISH = 3

AddHook("TTTPrepareRound", "Chef_PrepareRound", function()
    for _, v in PlayerIterator() do
        SafeRemoveEntity(v.TTTChefHat)
    end
end)