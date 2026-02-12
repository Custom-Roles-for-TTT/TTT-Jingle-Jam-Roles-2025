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
ROLE.shortdesc = "Places a safe that they must defend from being picked open for the rest of the round"

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
        ["safekeeper_hud_warmup"] = "You will get your safe in: {time}"
    }
}

ROLE.haspassivewin = true

------------------
-- ROLE CONVARS --
------------------

local safekeeper_pick_time = CreateConVar("ttt_safekeeper_pick_time", "30", FCVAR_REPLICATED, "How long (in seconds) it takes to pick a safe", 1, 60)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_SafekeeperPlaySound")

    local safekeeper_pick_grace_time = CreateConVar("ttt_safekeeper_pick_grace_time", 0.25, FCVAR_NONE, "How long (in seconds) before the pick progress of a safe is reset when a player stops looking at it", 0, 1)
    local safekeeper_warmup_time_min = CreateConVar("ttt_safekeeper_warmup_time_min", "30", FCVAR_NONE, "Minimum time (in seconds) before the Safekeeper will be given their safe", 1, 60)
    local safekeeper_warmup_time_max = CreateConVar("ttt_safekeeper_warmup_time_max", "60", FCVAR_NONE, "Maximum time (in seconds) before the Safekeeper will be given their safe", 1, 120)
    local safekeeper_drop_time = CreateConVar("ttt_safekeeper_drop_time", "30", FCVAR_NONE, "How long (in seconds) before the Safekeeper will automatically drop their safe", 1, 60)

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
    AddHook("WeaponEquip", "Safekeeper_WeaponEquip", function(wep, ply)
        if not IsPlayer(ply) then return end
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

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Safekeeper_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTSafekeeperLastPickTime = nil
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

    ----------------------
    -- SAFE REVEAL HALO --
    ----------------------

    AddHook("PreDrawHalos", "Safekeeper_Highlight_PreDrawHalos", function()
        if not client then
            client = LocalPlayer()
        end

        local targets = {}
        for _, e in ipairs(EntsFindByClass("ttt_safekeeper_safe")) do
            if not IsValid(e) then continue end

            local placer = e:GetPlacer()
            -- Show the safe to everyone if it's revealed, or just the placer if it isn't
            if e.TTTSafekeeperSafeRevealed or (IsPlayer(placer) and client == placer) then
                TableInsert(targets, e)
            end
        end

        if #targets == 0 then return end

        halo.Add(targets, COLOR_WHITE, 1, 1, 1, true, true)
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
            html = html .. "<span style='display: block; margin-top: 10px;'>To win, the " .. ROLE_STRINGS[ROLE_SAFEKEEPER] .. " must place their safe and it <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>must remain unpicked</span> for the rest of the round.</span>"

            -- TODO: Alternate win condition, if it is added

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