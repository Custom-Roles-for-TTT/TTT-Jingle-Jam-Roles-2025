local ents = ents
local hook = hook
local ipairs = ipairs
local pairs = pairs
local player = player
local timer = timer

local AddHook = hook.Add
local CreateEntity = ents.Create
local PlayerIterator = player.Iterator
local RemoveHook = hook.Remove
local TimerRemove = timer.Remove

local ROLE = {}

ROLE.nameraw = "chef"
ROLE.name = "Chef"
ROLE.nameplural = "Chefs"
ROLE.nameext = "a Chef"
ROLE.nameshort = "chf"

ROLE.desc = [[You are {role}! Place down a stove with
your chosen food to cook up some buffs
for your friends, and damage for your foes.]]
ROLE.shortdesc = "Cooks a chosen food for other players which provides a buff (or, if burnt, causes damage)"

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
    },
    {
        cvar = "ttt_chef_burger_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_burger_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_chef_hotdog_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_hotdog_interval",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_hotdog_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_fish_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_fish_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_chef_burnt_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_burnt_interval",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_chef_burnt_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
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

------------------
-- ROLE CONVARS --
------------------

local hat_enabled = CreateConVar("ttt_chef_hat_enabled", "1", FCVAR_REPLICATED, "Whether the chef gets a hat", 0, 1)
local burger_time = CreateConVar("ttt_chef_burger_time", "30", FCVAR_REPLICATED, "The amount of time the burger effect should last", 1, 120)
local burger_amount = CreateConVar("ttt_chef_burger_amount", "0.5", FCVAR_REPLICATED, "The percentage of speed boost that the burger eater should get (e.g. 0.5 = 50% speed boost)", 0.1, 1)
local hotdog_time = CreateConVar("ttt_chef_hotdog_time", "30", FCVAR_REPLICATED, "The amount of time the hot dog effect should last", 1, 120)
local hotdog_interval = CreateConVar("ttt_chef_hotdog_interval", "1", FCVAR_REPLICATED, "How often the hot dog eater's health should be restored", 1, 60)
local hotdog_amount = CreateConVar("ttt_chef_hotdog_amount", "1", FCVAR_REPLICATED, "The amount of the hot dog eater's health to restore per interval", 1, 50)
local fish_time = CreateConVar("ttt_chef_fish_time", "30", FCVAR_REPLICATED, "The amount of time the fish effect should last", 1, 120)
local fish_amount = CreateConVar("ttt_chef_fish_amount", "0.5", FCVAR_REPLICATED, "The percentage of damage boost that the fish eater should get (e.g. 0.5 = 50% damage boost)", 0.1, 1)
local burnt_time = CreateConVar("ttt_chef_burnt_time", "30", FCVAR_REPLICATED, "The amount of time the burnt food effect should last", 1, 120)
local burnt_interval = CreateConVar("ttt_chef_burnt_interval", "1", FCVAR_REPLICATED, "How often the burnt food eater's health should be removed", 1, 60)
local burnt_amount = CreateConVar("ttt_chef_burnt_amount", "1", FCVAR_REPLICATED, "The amount of the burnt food eater's health to remove per interval", 1, 50)

local function RemoveBuffs(ply)
    if SERVER then
        if ply.TTTChefTimers then
            for _, t in ipairs(ply.TTTChefTimers) do
                TimerRemove(t)
            end
            ply.TTTChefTimers = nil
        end
    end

    if ply.TTTChefHooks then
        if SERVER then
            net.Start("TTTChefFoodRemoveHooks")
            net.Send(ply)
        end

        for k, v in pairs(ply.TTTChefHooks) do
            if not v then continue end
            RemoveHook(v, k)
        end
        ply.TTTChefHooks = nil
    end
end

if SERVER then
    util.AddNetworkString("TTTChefFoodRemoveHooks")


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

    -- Remove buffs when a player dies
    AddHook("PostPlayerDeath", "Chef_PostPlayerDeath_Cleanup", function(ply)
        if not IsPlayer(ply) then return end
        RemoveBuffs(ply)
    end)
end

if CLIENT then
    AddCSLuaFile()

    -------------------
    -- ROLE FEATURES --
    -------------------

    local client
    net.Receive("TTTChefFoodRemoveHooks", function()
        if not IsValid(client) then
            client = LocalPlayer()
        end
        RemoveBuffs(client)
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Chef_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_CHEF then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INNOCENT)
            local html = "The " .. ROLE_STRINGS[ROLE_CHEF] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> whose goal is to help their team by cooking food which provides a buff."

            -- Stove
            html = html .. "<span style='display: block; margin-top: 10px;'>Choose a food and <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>place down a stove using the Stove Placer</span>, then interact with the placed stove to start cooking.</span>"

            -- Buffs
            html = html .. "<span style='display: block; margin-top: 10px;'>The possible foods (and their effects):<ul>"
                html = html .. "<li>Burger - Increases the player's <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>movement speed by " .. (burger_amount:GetFloat() * 100) .. "%</span> for " .. burger_time:GetInt() .. " second(s).</li>"
                html = html .. "<li>Hot Dog - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Heals the player</span> for " .. hotdog_amount:GetInt() .. " health every " .. hotdog_interval:GetInt() .. " second(s) for a total of " .. hotdog_time:GetInt() .. " seconds. Will heal over maximum health, if needed.</li>"
                html = html .. "<li>Fish - Increases the player's <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>damage by " .. (fish_amount:GetFloat() * 100) .. "%</span> for " .. fish_time:GetInt() .. " second(s).</li>"
            html = html .. "</ul></span>"

            -- Cook time
            html = html .. "<span style='display: block; margin-top: 10px;'>Food takes " .. GetConVar("ttt_chef_cook_time"):GetInt() .. " second(s) to cook and <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will burn</span> if left in the stove for more than " .. GetConVar("ttt_chef_overcook_time"):GetInt() .. " second(s) extra.</span>"

            -- Burnt effect
            html = html .. "<span style='display: block; margin-top: 10px;'><span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Burnt food hurts the player</span> for " .. burnt_amount:GetInt() .. " health every " .. burnt_interval:GetInt() .. " second(s) for a total of " .. burnt_time:GetInt() .. " seconds. Will kill the player if they reach 0 health.</span>"

            return html
        end
    end)
end

RegisterRole(ROLE)

-- Role features
CHEF_FOOD_TYPE_NONE = 0
CHEF_FOOD_TYPE_BURGER = 1
CHEF_FOOD_TYPE_HOTDOG = 2
CHEF_FOOD_TYPE_FISH = 3

-------------
-- CLEANUP --
-------------

AddHook("TTTPrepareRound", "Chef_PrepareRound", function()
    for _, p in PlayerIterator() do
        RemoveBuffs(p)
        if SERVER then
            SafeRemoveEntity(p.TTTChefHat)
        end
    end
end)