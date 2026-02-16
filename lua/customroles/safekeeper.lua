local ents = ents
local hook = hook
local math = math
local net = net
local player = player
local surface = surface
local table = table

local AddHook = hook.Add
local EntsFindByClass = ents.FindByClass
local MathRandom = math.random
local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "safekeeper"
ROLE.name = "Safekeeper"
ROLE.nameplural = "Safekeepers"
ROLE.nameext = "a Safekeeper"
ROLE.nameshort = "sfk"

ROLE.desc = [[You are {role}!

Place your safe somewhere on the map
and keep it defended.
If it remains unopened by the end
of the round, you win!]]
ROLE.shortdesc = "Places a safe that they must defend from being picked open for the rest of the round."

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.convars =
{
    {
        cvar = "ttt_safekeeper_drop_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_safekeeper_move_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_safekeeper_move_safe",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_safekeeper_pick_grace_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_safekeeper_pick_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_safekeeper_warmup_time_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_safekeeper_warmup_time_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_safekeeper_warn_pick_start",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_safekeeper_warn_pick_complete",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_safekeeper_weapons_dropped",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE.translations = {
    ["english"] = {
        ["sfk_safe_help_pri"] = "Use {primaryfire} to drop your safe on the ground",
        ["sfk_safe_help_sec"] = "Switching weapons, dying, and getting too tired will drop the safe automatically",
        ["sfk_safe_name"] = "Safe",
        ["sfk_safe_hint"] = "Press {usekey} to pick up",
        ["sfk_safe_hint_nomove"] = "Don't let anyone open it!",
        ["sfk_safe_hint_cooldown"] = "Too tired to pick up... ({time})",
        ["sfk_safe_hint_pick"] = "Hold {usekey} to pick open",
        ["sfk_safe_hint_open"] = "Already picked and looted",
        ["safekeeper_picking"] = "PICKING",
        ["safekeeper_hud_drop"] = "You will drop your safe in: {time}",
        ["safekeeper_hud_warmup"] = "You will get your safe in: {time}",
        ["safekeeper_target_looter"] = "LOOTER",
        ["ev_safekeeperpicked"] = "{safekeeper}'s safe was picked open by {picker}"
    }
}

ROLE.haspassivewin = true

------------------
-- ROLE CONVARS --
------------------

local safekeeper_pick_time = CreateConVar("ttt_safekeeper_pick_time", "15", FCVAR_REPLICATED, "How long (in seconds) it takes to pick a safe", 1, 60)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_SafekeeperPlaySound")
    util.AddNetworkString("TTT_SafekeeperSafePicked")

    local safekeeper_pick_grace_time = CreateConVar("ttt_safekeeper_pick_grace_time", 0.25, FCVAR_NONE, "How long (in seconds) before the pick progress of a safe is reset when a player stops looking at it", 0, 1)
    local safekeeper_warmup_time_min = CreateConVar("ttt_safekeeper_warmup_time_min", "30", FCVAR_NONE, "Minimum time (in seconds) before the Safekeeper will be given their safe", 1, 60)
    local safekeeper_warmup_time_max = CreateConVar("ttt_safekeeper_warmup_time_max", "60", FCVAR_NONE, "Maximum time (in seconds) before the Safekeeper will be given their safe", 1, 120)
    local safekeeper_drop_time = CreateConVar("ttt_safekeeper_drop_time", "15", FCVAR_NONE, "How long (in seconds) before the Safekeeper will automatically drop their safe", 1, 60)

    --------------------
    -- PICK TRACKING --
    --------------------

    AddHook("TTTPlayerAliveThink", "Safekeeper_TTTPlayerAliveThink_Picking", function(ply)
        if ply.TTTSafekeeperLastPickTime == nil then return end

        local pickTarget = ply.TTTSafekeeperPickTarget
        if not IsValid(pickTarget) then return end

        local pickStart = ply.TTTSafekeeperPickStart
        if not pickStart or pickStart <= 0 then return end

        local curTime = CurTime()

        -- If it's been too long since the user used the ankh, stop tracking their progress
        if curTime - ply.TTTSafekeeperLastPickTime >= safekeeper_pick_grace_time:GetFloat() then
            ply.TTTSafekeeperLastPickTime = nil
            ply:ClearProperty("TTTSafekeeperPickTarget", ply)
            ply:ClearProperty("TTTSafekeeperPickStart", ply)
            return
        end

        -- If they haven't used this item long enough then keep waiting
        if curTime - pickStart < safekeeper_pick_time:GetInt() then return end

        pickTarget:Open(ply)
    end)

    -------------------
    -- ROLE FEATURES --
    -------------------

    ROLE.onroleassigned = function(ply)
        if not IsPlayer(ply) then return end
        if not ply:IsSafekeeper() then return end

        local safeTimeMin = safekeeper_warmup_time_min:GetInt()
        local safeTimeMax = safekeeper_warmup_time_max:GetInt()
        if safeTimeMax < safeTimeMin then
            safeTimeMax = safeTimeMin
        end

        local safeTime = MathRandom(safeTimeMin, safeTimeMax)
        ply:SetProperty("TTTSafekeeperWarmupTime", CurTime() + safeTime, ply)
    end

    -- Drop the safe when the player they hold it for too long
    AddHook("TTTPlayerAliveThink", "Safekeeper_TTTPlayerAliveThink", function(ply)
        if not IsPlayer(ply) then return end
        if not ply:IsSafekeeper() then return end

        if ply.TTTSafekeeperWarmupTime then
            local remaining = ply.TTTSafekeeperWarmupTime - CurTime()
            if remaining <= 0 then
                ply:Give("weapon_sfk_safeplacer")
                ply:ClearProperty("TTTSafekeeperWarmupTime", ply)
            end
            return
        end

        if not ply.TTTSafekeeperDropTime then return end

        local remaining = ply.TTTSafekeeperDropTime - CurTime()
        if remaining > 0 then return end

        local wep = ply:GetWeapon("weapon_sfk_safeplacer")
        if not IsValid(wep) then return end

        wep:PrimaryAttack()
    end)

    -- Automatically switch to the safe placers when they player gets it and
    -- start the auto-drop timer
    -- Also track who loots the items that come out of the safe
    AddHook("WeaponEquip", "Safekeeper_WeaponEquip", function(wep, ply)
        if not IsPlayer(ply) then return end

        -- If this weapon is from a Safekeeper's safe,
        -- keep track of which Safekeepers this person has looted
        if wep.TTTSafekeeperSpawnedBy and #wep.TTTSafekeeperSpawnedBy > 0 then
            if wep.TTTSafekeeperTracked then return end

            -- Only track the first player who picks it up, but don't reset "spawned by"
            -- so that the Safekeeper can never pick it up, even by colluding
            wep.TTTSafekeeperTracked = true

            local lootedList
            if ply.TTTSafekeeperLootedList then
                lootedList = ply.TTTSafekeeperLootedList
            else
                lootedList = {}
            end

            if not TableHasValue(lootedList, wep.TTTSafekeeperSpawnedBy) then
                TableInsert(lootedList, wep.TTTSafekeeperSpawnedBy)
                ply:SetProperty("TTTSafekeeperLootedList", lootedList)

                local safekeeper = player.GetBySteamID64(wep.TTTSafekeeperSpawnedBy)
                if IsPlayer(safekeeper) and safekeeper:Alive() and not safekeeper:IsSpec() then
                    safekeeper:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " has looted something from your safe, get them!")
                end
            end
            return
        end

        if not ply:IsActiveSafekeeper() then return end

        local wepClass = WEPS.GetClass(wep)
        if wepClass ~= "weapon_sfk_safeplacer" then return end

        -- Slight delay before equipping to make sure they actually have it
        timer.Simple(0.1, function()
            if not IsPlayer(ply) then return end
            ply:SelectWeapon(wepClass)

            local drop_time = safekeeper_drop_time:GetInt()
            ply:SetProperty("TTTSafekeeperDropTime", CurTime() + drop_time, ply)
        end)
        ply:ClearProperty("TTTSafekeeperSafe")
    end)

    -- Mark the safe for a dead Safekeeper as revealed and tell everyone
    AddHook("TTTBodyFound", "Safekeeper_TTTBodyFound", function(ply, deadply, rag)
        if not IsPlayer(deadply) then return end

        local safeEntIdx = deadply.TTTSafekeeperSafe
        if not safeEntIdx then return end

        local safe = Entity(safeEntIdx)
        if not IsValid(safe) then return end

        -- Tell all the other players about the safe
        for _, v in PlayerIterator() do
            if v == deadply then
                v:QueueMessage(MSG_PRINTBOTH, "Your body has been found, revealing your safe to everyone")
            else
                v:QueueMessage(MSG_PRINTBOTH, "A " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. "'s body has been found and their safe's location has been revealed!")
            end
        end
        safe:SetProperty("TTTSafekeeperSafeRevealed", true)
    end)

    -- If this weapon comes from a Safekeeper's safe, the Safekeeper cannot pick it up
    AddHook("PlayerCanPickupWeapon", "Safekeeper_PlayerCanPickupWeapon", function(ply, wep)
        if not IsPlayer(ply) then return end
        if not IsValid(wep) then return end
        if not ply:IsSafekeeper() then return end

        if wep.TTTSafekeeperSpawnedBy == ply:SteamID64() then
            return false
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "Safekeeper_Initialize", function()
        EVENT_SAFEKEEPERPICKED = GenerateNewEventID(ROLE_SAFEKEEPER)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Safekeeper_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTSafekeeperLastPickTime = nil
            v:ClearProperty("TTTSafekeeperLootedList")
            v:ClearProperty("TTTSafekeeperSafe")
            v:ClearProperty("TTTSafekeeperPickTarget", v)
            v:ClearProperty("TTTSafekeeperPickStart", v)
            v:ClearProperty("TTTSafekeeperDropTime", v)
            v:ClearProperty("TTTSafekeeperWarmupTime", v)
        end
    end)

    ----------------
    -- DISCONNECT --
    ----------------

    -- On disconnect, destroy the safe if they have one
    AddHook("PlayerDisconnected", "Safekeeper_PlayerDisconnected", function(ply)
        if not IsPlayer(ply) then return end

        local safeEntIdx = ply.TTTSafekeeperSafe
        if not safeEntIdx then return end

        local safe = Entity(safeEntIdx)
        if not IsValid(safe) then return end

        SafeRemoveEntity(safe)
    end)
end

if CLIENT then
    --------------------
    -- PICK PROGRESS --
    --------------------

    local client
    AddHook("HUDPaint", "Safekeeper_HUDPaint", function()
        if not client then
            client = LocalPlayer()
        end

        local pickTarget = client.TTTSafekeeperPickTarget
        if not IsValid(pickTarget) then return end

        local pickStart = client.TTTSafekeeperPickStart
        if not pickStart or pickStart <= 0 then return end

        local curTime = CurTime()
        local pickTime = safekeeper_pick_time:GetInt()
        local endTime = pickStart + pickTime
        local progress = math.min(1, 1 - ((endTime - curTime) / pickTime))

        local text = LANG.GetTranslation("safekeeper_picking")

        local x = ScrW() / 2
        local y = ScrH() / 2
        local w = 300
        CRHUD:PaintProgressBar(x, y, w, COLOR_GREEN, text, progress)
    end)

    net.Receive("TTT_SafekeeperPlaySound", function()
        local soundType = net.ReadString()
        surface.PlaySound("safekeeper/" .. soundType .. ".mp3")
    end)

    ---------------
    -- TARGET ID --
    ---------------

    -- Show skull icon over the looters' heads
    AddHook("TTTTargetIDPlayerTargetIcon", "Safekeeper_TTTTargetIDPlayerTargetIcon", function(ply, cli, showJester)
        if not cli:IsSafekeeper() then return end
        if not IsPlayer(ply) then return end
        if not ply.TTTSafekeeperLootedList then return end
        if not TableHasValue(ply.TTTSafekeeperLootedList, cli:SteamID64()) then return end
        if ply:ShouldActLikeJester() then return end
        if cli:IsRoleAbilityDisabled() then return end

        return "kill", true, ROLE_COLORS_SPRITE[ROLE_SAFEKEEPER], "down"
    end)

    -- And "LOOTER" under their name
    hook.Add("TTTTargetIDPlayerText", "Safekeeper_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if not cli:IsSafekeeper() then return end
        if not IsPlayer(ent) then return end
        if not ent.TTTSafekeeperLootedList then return end
        if not TableHasValue(ent.TTTSafekeeperLootedList, cli:SteamID64()) then return end
        if ent:ShouldActLikeJester() then return end
        if cli:IsRoleAbilityDisabled() then return end

        -- Don't overwrite text
        if text then
            -- Don't overwrite secondary text either
            if secondary_text then return end
            return text, col, LANG.GetTranslation("safekeeper_target_looter"), ROLE_COLORS_RADAR[ROLE_SAFEKEEPER]
        end
        return LANG.GetTranslation("safekeeper_target_looter"), ROLE_COLORS_RADAR[ROLE_SAFEKEEPER]
    end)

    ROLE.istargetidoverridden = function(ply, target, showJester)
        if not ply:IsSafekeeper() then return end
        if not IsPlayer(target) then return end
        if not target.TTTSafekeeperLootedList then return end
        if not TableHasValue(target.TTTSafekeeperLootedList, ply:SteamID64()) then return end
        if target:ShouldActLikeJester() then return end
        if ply:IsRoleAbilityDisabled() then return end

        ------ icon,  ring,  text
        return false, false, true
    end

    ---------------
    -- HIGHLIGHT --
    ---------------

    ROLE.istargethighlighted = function(ply, target)
        if not ply:IsSafekeeper() then return end
        if not IsPlayer(target) then return end
        if not target.TTTSafekeeperLootedList then return end
        if target:ShouldActLikeJester() then return end
        if ply:IsRoleAbilityDisabled() then return end

        return TableHasValue(target.TTTSafekeeperLootedList, ply:SteamID64())
    end

    AddHook("PreDrawHalos", "Safekeeper_PreDrawHalos_Highlight", function()
        if not client then
            client = LocalPlayer()
        end

        local isSafekeeper = client:IsSafekeeper() and not client:IsRoleAbilityDisabled()
        -- Highlight anyone who has looted this Safekeeper's safe
        if isSafekeeper then
            local sid64 = client:SteamID64()
            local looters = {}
            for _, p in PlayerIterator() do
                if client == p then continue end
                if not p:Alive() or p:IsSpec() then continue end
                if not p.TTTSafekeeperLootedList then continue end
                if p:ShouldActLikeJester() then continue end

                if TableHasValue(p.TTTSafekeeperLootedList, sid64) then
                    TableInsert(looters, p)
                end
            end

            if #looters > 0 then
                halo.Add(looters, COLOR_RED, 1, 1, 1, true, true)
            end
        end

        local safes = {}
        for _, e in ipairs(EntsFindByClass("ttt_safekeeper_safe")) do
            if not IsValid(e) then continue end

            local placer = e:GetPlacer()
            -- Show the safe to everyone if it's revealed, or just the placer if it isn't
            if e.TTTSafekeeperSafeRevealed or (isSafekeeper and IsPlayer(placer) and client == placer) then
                TableInsert(safes, e)
            end
        end

        if #safes == 0 then return end

        halo.Add(safes, COLOR_WHITE, 1, 1, 1, true, true)
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "Safekeeper_TTTSyncEventIDs", function()
        EVENT_SAFEKEEPERPICKED = EVENTS_BY_ROLE[ROLE_SAFEKEEPER]
        local swap_icon = Material("icon16/lock_open.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_SAFEKEEPERPICKED, {
            text = function(e)
                return PT("ev_safekeeperpicked", {safekeeper = e.sfk, picker = e.pick})
            end,
            icon = function(e)
                return swap_icon, "Safe Picked"
            end})
    end)

    net.Receive("TTT_SafekeeperSafePicked", function(len)
        local safekeeper = net.ReadString()
        local picker = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_SAFEKEEPERPICKED,
            sfk = safekeeper,
            pick = picker
        })
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTScoringSecondaryWins", "Safekeeper_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        for _, p in PlayerIterator() do
            if not p:IsSafekeeper() then continue end

            local safeEntIdx = p.TTTSafekeeperSafe
            if not safeEntIdx then continue end

            local safe = Entity(safeEntIdx)
            if not IsValid(safe) then continue end

            -- If the safe is still closed, they win
            if not safe:GetOpen() then
                TableInsert(secondary_wins, ROLE_SAFEKEEPER)
                return
            else
                local sid64 = p:SteamID64()
                local foundAlive = false
                -- Check that all the looters are dead
                for _, l in PlayerIterator() do
                    if p == l then continue end
                    if not l.TTTSafekeeperLootedList then continue end
                    if l:ShouldActLikeJester() then continue end

                    -- We only need to find one to prevent the safekeeper from winning, so break early once we find one
                    if TableHasValue(l.TTTSafekeeperLootedList, sid64) and l:Alive() and not l:IsSpec() then
                        foundAlive = true
                        break
                    end
                end

                if foundAlive then continue end

                -- If we made it through everyone without finding a living looter then the Safekeeper wins
                TableInsert(secondary_wins, ROLE_SAFEKEEPER)
                return
            end
        end
    end)

    ---------
    -- HUD --
    ---------

    AddHook("TTTHUDInfoPaint", "Safekeeper_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if not cli:IsActiveSafekeeper() then return end

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining
        local msgType
        if cli.TTTSafekeeperWarmupTime then
            remaining = cli.TTTSafekeeperWarmupTime - CurTime()
            msgType = "warmup"
        elseif cli.TTTSafekeeperDropTime then
            remaining = cli.TTTSafekeeperDropTime - CurTime()
            msgType = "drop"
        end

        if not remaining or remaining <= 0 then return end

        local text = LANG.GetParamTranslation("safekeeper_hud_" .. msgType, { time = util.SimpleTime(remaining, "%02i:%02i") })
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "safekeeper")
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Safekeeper_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_SAFEKEEPER then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role that is given a safe after a random delay to place somewhere on the map."

            -- Win condition
            html = html .. "<span style='display: block; margin-top: 10px;'>To win, the " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. " must place their safe and <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>keep it protected</span> for the rest of the round.</span>"

            -- Alternate win condition
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. "'s safe is picked open, they can still win by <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>tracking down and killing anyone who got loot</span> from it.</span>"

            -- Auto-drop
            html = html .. "<span style='display: block; margin-top: 10px;'>The safe is quite heavy and so it <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will automatically drop</span> if the " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. " holds it for too long, tries to switch weapons, or is killed.</span>"

            -- Move
            local move_safe = cvars.Bool("ttt_safekeeper_move_safe", false)
            if move_safe then
                html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. "'s safe <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>can be moved</span> by the " .. ROLE_STRINGS[ROLE_SAFEKEEPER]
                -- Move delay
                local move_cooldown = GetConVar("ttt_safekeeper_move_cooldown"):GetInt()
                if move_cooldown > 0 then
                    html = html .. " once every " .. move_cooldown .. " second(s)"
                end
                html = html .. ".</span>"
            end

            -- Pick time
            html = html .. "<span style='display: block; margin-top: 10px;'>The safe is full of shop weapons and other players can spend " .. safekeeper_pick_time:GetInt() .. " second(s) of continuous focus <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>to pick it open</span> and spill its loot on the ground.</span>"

            return html
        end
    end)
end

RegisterRole(ROLE)