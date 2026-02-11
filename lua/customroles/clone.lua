local hook = hook
local player = player
local table = table
local util = util

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "clone"
ROLE.name = "Clone"
ROLE.nameplural = "Clones"
ROLE.nameext = "a Clone"
ROLE.nameshort = "cln"

ROLE.desc = [[You are {role}!

Use your Target Picker to choose a
player and become their perfect clone.

You will win with their team, but be
careful... if they die, so will you!]]
ROLE.shortdesc = "Chooses a player to become a clone of and then wins with that player's team"

ROLE.team = ROLE_TEAM_JESTER

ROLE.translations = {
    ["english"] = {
        ["ev_cloneplayercloned"] = "{clone} cloned {target}!",
        ["clone_targetid"] = "CLONED",
        ["score_clone_cloned"] = "Cloned",
        ["clonetargetpicker_help_pri"] = "Press {primaryfire} to choose a player as your target."
    }
}

ROLE.convars = {
    {
        cvar = "ttt_clone_perfect_clone",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_clone_target_detectives",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_clone_minimum_radius",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

RegisterRole(ROLE)

------------------
-- ROLE CONVARS --
------------------

local clone_perfect_clone = CreateConVar("ttt_clone_perfect_clone", "0", FCVAR_REPLICATED, "Whether the Clone copies their target's model perfectly. If \"false\", some aspect of the clone will be wrong (such as skin, bodygroup, size, etc.)", 0, 1)
local clone_target_detectives = CreateConVar("ttt_clone_target_detectives", "0", FCVAR_REPLICATED, "Whether the Clone can target detective roles", 0, 1)

if SERVER then
    util.AddNetworkString("TTT_ClonePlayerCloned")

    -------------------
    -- ROLE FEATURES --
    -------------------

    AddHook("PostPlayerDeath", "Clone_PostPlayerDeath", function(ply)
        local sid64 = ply:SteamID64()
        for _, p in PlayerIterator() do
            if not p:IsClone() then continue end
            if not p:Alive() or p:IsSpec() then continue end

            if p.TTTCloneTarget == sid64 then
                p:QueueMessage(MSG_PRINTBOTH, "The player you cloned has died and took you with them")
                p:Kill()
            end
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Clone_Initialize", function()
        EVENT_CLONEPLAYERCLONED = GenerateNewEventID(ROLE_CLONE)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Clone_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:ClearProperty("TTTCloneTarget")
        end
    end)
end

if CLIENT then
    ---------------
    -- TARGET ID --
    ---------------

    AddHook("TTTTargetIDPlayerText", "Clone_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if cli:IsClone() and IsPlayer(ent) and ent:SteamID64() == cli.TTTCloneTarget and not cli:IsRoleAbilityDisabled() then
            -- Don't overwrite text
            if text then
                -- Don't overwrite secondary text either
                if secondary_text then return end
                return text, col, LANG.GetTranslation("clone_targetid"), ROLE_COLORS_RADAR[ROLE_CLONE]
            else
                return LANG.GetTranslation("clone_targetid"), ROLE_COLORS_RADAR[ROLE_CLONE]
            end
        end
    end)

    ROLE.istargetidoverridden = function(ply, target, showJester)
        if not ply:IsClone() then return end
        if not IsPlayer(target) then return end
        if ply:IsRoleAbilityDisabled() then return end

        ------ icon , ring , text
        return false, false, target:SteamID64() == ply.TTTCloneTarget
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    AddHook("TTTScoreboardPlayerName", "Clone_TTTScoreboardPlayerName", function(ply, cli, text)
        if cli:IsClone() and ply:SteamID64() == cli.TTTCloneTarget and not cli:IsRoleAbilityDisabled() then
            local newText = " (" .. LANG.GetTranslation("clone_targetid") .. ")"
            return ply:Nick() .. newText
        end
    end)

    ROLE.isscoreboardinfooverridden = function(ply, target)
        if not ply:IsClone() then return end
        if not IsPlayer(target) then return end
        if ply:IsRoleAbilityDisabled() then return end

        -- Shared logic
        local show = target:SteamID64() == ply.TTTCloneTarget

        ------ name, role
        return show, false
    end

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTScoringSecondaryWins", "Clone_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        for _, p in PlayerIterator() do
            if not p:IsClone() then continue end

            local targetSid64 = p.TTTCloneTarget
            local target = player.GetBySteamID64(targetSid64)
            if not IsPlayer(target) then continue end

            -- Associate win type with the target player to see if they match
            local targetRole = target:GetRole()
            local cloneWins = false
            if WINS_BY_ROLE[targetRole] and wintype == WINS_BY_ROLE[targetRole] then
                cloneWins = true
            -- Fallback to this just in case
            elseif (target:IsInnocentTeam() and wintype == WIN_INNOCENT) or
                    (target:IsTraitorTeam() and wintype == WIN_TRAITOR) or
                    (target:IsMonsterTeam() and wintype == WIN_MONSTER) then
                cloneWins = true
            end

            -- If they match, the clone wins too
            if cloneWins then
                TableInsert(secondary_wins, ROLE_CLONE)
                return
            end
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Clone_TTTSyncEventIDs", function()
        EVENT_CLONEPLAYERCLONED = EVENTS_BY_ROLE[ROLE_CLONE]
        local cloned_icon = Material("icon16/user_suit.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_CLONEPLAYERCLONED, {
            text = function(e)
                return PT("ev_cloneplayercloned", {clone = e.clone, target = e.target})
            end,
            icon = function(e)
                return cloned_icon, "Cloned"
            end})
    end)

    net.Receive("TTT_ClonePlayerCloned", function(len)
        local clone = net.ReadString()
        local target = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_CLONEPLAYERCLONED,
            clone = clone,
            target = target
        })
    end)

    hook.Add("TTTScoringSummaryRender", "Clone_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if not IsPlayer(ply) then return end
        if not ply:IsClone() then return end

        local targetSid64 = ply.TTTCloneTarget
        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then return end

        return roleFileName, groupingRole, roleColor, name, target:Nick(), LANG.GetTranslation("score_clone_cloned")
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Clone_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_CLONE then
            local T = LANG.GetTranslation
            local roleColor = ROLE_COLORS[ROLE_CLONE]
            local html = "The " .. ROLE_STRINGS[ROLE_CLONE] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester role</span> who chooses a player to clone using their Target Picker device."

            -- Targets
            html = html .. "<span style='display: block; margin-top: 10px;'>Their target can be <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>any "
            if not clone_target_detectives:GetBool() then
                html = html .. "non-" .. T("detective") .. " "
            end
            html = html .. "role</span>.</span>"

            -- Cloning
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_CLONE] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>becomes a"
            if not clone_perfect_clone:GetBool() then
                html = html .. "n im"
            else
                html = html .. " "
            end
            html = html .. "perfect clone</span> of their target, copying their model, skin, bodygroups, and color."
            if not clone_perfect_clone:GetBool() then
                html = html .. " One aspect of the clone <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will be wrong</span> so keen-eyed players will be able to identify the " .. ROLE_STRINGS[ROLE_CLONE] .. "."
            end
            html = html .. "</span>"

            -- Win condition
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_CLONE] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>wins with their target's team</span> at the end of the round.</span>"

            return html
        end
    end)
end