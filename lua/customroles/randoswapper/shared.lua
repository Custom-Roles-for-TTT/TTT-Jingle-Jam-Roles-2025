AddCSLuaFile()

local hook = hook

local AddHook = hook.Add

local ROLE = {}

ROLE.nameraw = "randoswapper"
ROLE.name = "Randoswapper"
ROLE.nameplural = "Randoswappers"
ROLE.nameext = "a Randoswapper"
ROLE.nameshort = "rsw"

ROLE.desc = [[You are {role}! {traitors} think you are {ajester} and you
deal no damage however, if anyone kills you, they become
the {randoswapper} and you trigger a Randomat event,
then take their role and can join the fight.]]
ROLE.shortdesc = "Swaps roles with their killer and triggers a Randomat event instead of dying."

ROLE.team = ROLE_TEAM_JESTER

ROLE.convars =
{
    {
        cvar = "ttt_randoswapper_notify_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"None", "Detective and Traitor", "Traitor", "Detective", "Everyone"},
        isNumeric = true
    },
    {
        cvar = "ttt_randoswapper_notify_killer",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoswapper_notify_sound",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoswapper_notify_confetti",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoswapper_killer_health",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_randoswapper_respawn_health",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_randoswapper_weapon_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Don't swap anything", "Swap role weapons", "Swap all weapons"},
        isNumeric = true
    },
    {
        cvar = "ttt_randoswapper_healthstation_reduce_max",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoswapper_swap_lovers",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_randoswapper_max_swaps",
        type = ROLE_CONVAR_TYPE_NUM
    }
}

ROLE.translations = {
    ["english"] = {
        ["ev_randoswapped"] = "{victim} randoswapped with {attacker}",
        ["score_randoswapper_killed"] = "Killed"
    }
}

RegisterRole(ROLE)

-- Randoswapper weapon modes
RANDOSWAPPER_WEAPON_NONE = 0
RANDOSWAPPER_WEAPON_ROLE = 1
RANDOSWAPPER_WEAPON_ALL = 2

------------------
-- ROLE CONVARS --
------------------

CreateConVar("ttt_randoswapper_healthstation_reduce_max", "1", FCVAR_REPLICATED, "Whether the randoswappers's max health should be reduced to match their current health", 0, 1)
local randoswapper_max_swaps = CreateConVar("ttt_randoswapper_max_swaps", "5", FCVAR_REPLICATED, "The maximum number of times the randoswapper can swap before they become a regular swapper. Set to \"0\" to allow swapping forever")

-------------------
-- ROLE FEATURES --
-------------------

ROLE_SELECTION_PREDICATE[ROLE_RANDOSWAPPER] = function()
    -- Make sure the Randomat exists
    return Randomat and Randomat.TriggerRandomEvent
end

AddHook("TTTIsPlayerRespawning", "Randoswapper_TTTIsPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("IsSwapping", false) then
        return true
    end
end)

AddHook("TTTRoleSpawnsArtificially", "Randoswapper_TTTRoleSpawnsArtificially", function(role)
    if role == ROLE_SWAPPER and util.CanRoleSpawn(ROLE_RANDOSWAPPER) and randoswapper_max_swaps:GetInt() > 0 then
        return true
    end
end)