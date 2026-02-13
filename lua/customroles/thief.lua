local hook = hook
local ipairs = ipairs
local math = math
local player = player
local surface = surface
local table = table
local util = util
local weapons = weapons

local AddHook = hook.Add
local MathRandom = math.random
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "thief"
ROLE.name = "Thief"
ROLE.nameplural = "Thieves"
ROLE.nameext = "a Thief"
ROLE.nameshort = "thf"

ROLE.desc = [[You are {role}!
TODO]]
ROLE.shortdesc = "TODO"

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.convars =
{
    {
        cvar = "ttt_thief_is_innocent",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_thief_is_traitor",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_thief_steal_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Proximity-based", "Using Thieves' Tools"},
        isNumeric = true,
        numericOffset = 0
    },
    {
        cvar = "ttt_thief_steal_success_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_failure_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_cost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_notify_delay_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_notify_delay_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_proximity_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_proximity_float_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_thief_steal_proximity_require_los",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_thief_steal_proximity_distance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE.translations =
{
    ["english"] =
    {
        ["thfsteal_stealing"] = "STEALING FROM {target}",
        ["thfsteal_failed"] = "STEALING FAILED",
        ["thief_hud"] = "Steal cooldown: {time}",
        ["win_thief"] = "The {role} has stolen its way to victory!",
        ["ev_win_thief"] = "The {role} has stolen its way to victory!",
        ["ev_thiefstolen"] = "{thief} stole {item} from {victim}"
    }
}

THIEF_STEAL_MODE_PROXIMITY = 0
THIEF_STEAL_MODE_TOOLS = 1

THIEF_STEAL_STATE_IDLE = 0
THIEF_STEAL_STATE_STEALING = 1
THIEF_STEAL_STATE_LOSING = 2
THIEF_STEAL_STATE_LOST = 3
THIEF_STEAL_STATE_STOLEN = 4
THIEF_STEAL_STATE_COOLDOWN = 5

------------------
-- ROLE CONVARS --
------------------

local thief_is_innocent = CreateConVar("ttt_thief_is_innocent", "0", FCVAR_REPLICATED, "Whether the Thief should be on the innocent team", 0, 1)
local thief_is_traitor = CreateConVar("ttt_thief_is_traitor", "0", FCVAR_REPLICATED, "Whether the Thief should be on the traitor team", 0, 1)
local thief_steal_success_cooldown = CreateConVar("ttt_thief_steal_success_cooldown", "30", FCVAR_REPLICATED, "How long (in seconds) after the Thief steals something before they can try to steal another thing", 0, 60)
local thief_steal_cost = CreateConVar("ttt_thief_steal_cost", "0", FCVAR_REPLICATED, "Whether stealing a weapon from a player requires a credit. Enables credit looting for innocent and independent Thieves on new round", 0, 1)
local thief_steal_notify_delay_min = CreateConVar("ttt_thief_steal_notify_delay_min", "10", FCVAR_REPLICATED, "The minimum delay before a player is notified they've been robbed. Set to \"0\" to disable notifications", 0, 30)
local thief_steal_notify_delay_max = CreateConVar("ttt_thief_steal_notify_delay_max", "30", FCVAR_REPLICATED, "The maximum delay before a player is notified they've been robbed", 3, 60)
local thief_steal_proximity_time = CreateConVar("ttt_thief_steal_proximity_time", "15", FCVAR_REPLICATED, "How long (in seconds) it takes the Thief to steal something from a target. Only used when \"ttt_thief_steal_mode 0\" is set", 1, 60)

-------------------
-- ROLE FEATURES --
-------------------

AddHook("TTTUpdateRoleState", "Thief_TTTUpdateRoleState", function()
    local is_innocent = thief_is_innocent:GetBool()
    -- Thieves cannot be both Innocents and Traitors so don't make them Traitors if they are already Innocents
    local is_traitor = not is_innocent and thief_is_traitor:GetBool()
    INNOCENT_ROLES[ROLE_THIEF] = is_innocent
    TRAITOR_ROLES[ROLE_THIEF] = is_traitor
    INDEPENDENT_ROLES[ROLE_THIEF] = not is_innocent and not is_traitor

    -- Only let thieves loot credits if they have something that costs credits
    -- NOTE: If they are on the traitor team, this is ignored so we don't have to even bother checking
    CAN_LOOT_CREDITS_ROLES[ROLE_THIEF] = thief_steal_cost:GetInt() > 0
end)

if SERVER then
    local plymeta = FindMetaTable("Player")
    if not plymeta then return end

    AddCSLuaFile()

    util.AddNetworkString("TTT_ThiefItemStolen")

    ------------------
    -- ROLE CONVARS --
    ------------------

    local thief_steal_mode = CreateConVar("ttt_thief_steal_mode", "0", FCVAR_NONE, "How stealing a weapon from a player works. 0 - Steal automatically when in proximity. 1 - Steal using their Thieves' Tools", 0, 1)
    local thief_steal_failure_cooldown = CreateConVar("ttt_thief_steal_failure_cooldown", "3", FCVAR_NONE, "How long (in seconds) after the Thief loses their target before they can try to steal another thing", 0, 60)
    local thief_steal_proximity_float_time = CreateConVar("ttt_thief_steal_proximity_float_time", "3", FCVAR_NONE, "The amount of time (in seconds) it takes for the Thief to lose their target after getting out of range. Only used when \"ttt_thief_steal_mode 0\" is set", 0, 60)
    local thief_steal_proximity_require_los = CreateConVar("ttt_thief_steal_proximity_require_los", "1", FCVAR_NONE, "Whether the Thief requires line-of-sight to steal something. Only used when \"ttt_thief_steal_mode 0\" is set", 0, 1)
    local thief_steal_proximity_distance = CreateConVar("ttt_thief_steal_proximity_distance", "5", FCVAR_NONE, "How close (in meters) the Thief needs to be to their target to start stealing. Only used when \"ttt_thief_steal_mode 0\" is set", 1, 15)

    -------------------
    -- ROLE FEATURES --
    -------------------

    function plymeta:ThiefSteal(target)
        if not self:Alive() or self:IsSpec() then return end
        if not IsPlayer(target) then return end
        if not target:Alive() or target:IsSpec() then return end

        -- TODO: Steal a weapon and set the property on the weapon so the thief can get it
        local item = "something"

        -- TODO: Notify the thief

        self:SetProperty("TTTThiefStealStartTime", CurTime(), self)
        self:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_COOLDOWN, self)

        net.Start("TTT_ThiefItemStolen")
            net.WriteString(self:Nick())
            net.WriteString(target:Nick())
            net.WriteString(item)
        net.Broadcast()

        local steal_notify_delay_min = thief_steal_notify_delay_min:GetInt()
        local steal_notify_delay_max = thief_steal_notify_delay_max:GetInt()
        if steal_notify_delay_min > steal_notify_delay_max then
            steal_notify_delay_max = steal_notify_delay_max
        end

        -- Send message (after a random delay) that this player has been robbed, but only if it's enabled
        if steal_notify_delay_min <= 0 then return end

        local delay = MathRandom(steal_notify_delay_max, steal_notify_delay_max)
        timer.Create("TTTThiefNotifyDelay_" .. target:SteamID64(), delay, 1, function()
            if not IsPlayer(target) then return end
            if not target:Alive() or target:IsSpec() then return end

            local message = "You have been been robbed by the " .. ROLE_STRINGS[ROLE_THIEF] .. "!"
            target:QueueMessage(MSG_PRINTBOTH, message)
        end)
    end

    AddHook("TTTPlayerAliveThink", "Thief_TTTPlayerAliveThink_Steal", function(ply)
        if not ply:IsThief() then return end
        if ply.TTTThiefDisabled then return end

        local startTime = ply.TTTThiefStealStartTime
        local targetSid64 = ply.TTTThiefStealTarget

        -- If this role has their ability disabled, clear any set tracking variables and continue
        -- Clearing the state is required to get the progress bar to disappear if they were
        -- actively stealing when it begins
        if ply:IsRoleAbilityDisabled() then
            if startTime then
                ply:ClearProperty("TTTThiefStealStartTime", ply)
                ply:ClearProperty("TTTThiefStealLostTime", ply)
            end

            if ply.TTTThiefStealState then
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
            end

            if targetSid64 and #targetSid64 > 0 then
                ply:ClearProperty("TTTThiefStealTarget", ply)
            end

            -- Use a server-side property to track this so we can short-circuit the processing loop and prevent repeated hook calls
            ply.TTTThiefDisabled = false
            return
        end

        local curTime = CurTime()
        local state = ply.TTTThiefStealState or THIEF_STEAL_STATE_IDLE

        -- Keep track of the success cooldown
        if state == THIEF_STEAL_STATE_COOLDOWN then
            local steal_success_cooldown = thief_steal_success_cooldown:GetInt()
            if curTime - (startTime + steal_success_cooldown) >= 0 then
                ply:ClearProperty("TTTThiefStealStartTime", ply)
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
            end
            return
        end

        if thief_steal_mode:GetInt() ~= THIEF_STEAL_MODE_PROXIMITY then return end

        local proximity_require_los = thief_steal_proximity_require_los:GetBool()
        local proximity_distance = thief_steal_proximity_distance:GetFloat() * UNITS_PER_METER
        local proxyDistanceSqr = proximity_distance * proximity_distance

        -- If we don't already have a target, find one
        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then
            local closestPly
            local closestPlyDist = -1
            for _, p in PlayerIterator() do
                if p == ply then continue end
                if not p:Alive() or p:IsSpec() then continue end

                local distance = p:GetPos():DistToSqr(ply:GetPos())
                if distance < proxyDistanceSqr and (closestPlyDist == -1 or distance < closestPlyDist) then
                    if proximity_require_los and not ply:IsLineOfSightClear(p) then continue end
                    closestPlyDist = distance
                    closestPly = p
                end
            end

            if IsPlayer(closestPly) then
                ply:SetProperty("TTTThiefStealTarget", closestPly:SteamID64(), ply)
            end
            return
        end

        local steal_failure_cooldown = thief_steal_failure_cooldown:GetInt()

        -- Handle the target dying
        if not target:Alive() or target:IsSpec() then
            if state ~= THIEF_STEAL_STATE_LOST and steal_failure_cooldown > 0 then
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_LOST, ply)
                -- Wait for the cooldown after losing before resetting
                ply:SetProperty("TTTThiefStealStartTime", curTime + steal_failure_cooldown, ply)
            elseif curTime > startTime or steal_failure_cooldown == 0 then
                -- After the buffer time has passed, reset the variables for the thief
                ply:ClearProperty("TTTThiefStealTarget", ply)
                ply:ClearProperty("TTTThiefStealStartTime", ply)
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
            end
            return
        end

        -- Handle the distance checks
        local proxy_float_time = thief_steal_proximity_float_time:GetInt()
        local distance = target:GetPos():DistToSqr(ply:GetPos())
        if state == THIEF_STEAL_STATE_IDLE then
            ply:SetProperty("TTTThiefStealStartTime", curTime)
            ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_STEALING, ply)
        elseif state == THIEF_STEAL_STATE_STEALING then
            if distance > proxyDistanceSqr or (proximity_require_los and not ply:IsLineOfSightClear(target)) then
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_LOSING, ply)
                ply:SetProperty("TTTThiefStealLostTime", curTime + proxy_float_time, ply)
            end
        elseif state == THIEF_STEAL_STATE_LOSING then
            if curTime > ply.TTTThiefStealLostTime then
                if steal_failure_cooldown > 0 then
                    ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_LOST, ply)
                    -- Wait for the cooldown after losing before resetting
                    ply:SetProperty("TTTThiefStealStartTime", curTime + steal_failure_cooldown, ply)
                else
                    ply:ClearProperty("TTTThiefStealTarget", ply)
                    ply:ClearProperty("TTTThiefStealStartTime", ply)
                    ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
                end
            elseif distance <= proxyDistanceSqr and (not proximity_require_los or ply:IsLineOfSightClear(target)) then
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_STEALING, ply)
                ply:ClearProperty("TTTThiefStealLostTime", ply)
            end
        elseif state == THIEF_STEAL_STATE_LOST and curTime > startTime then
            ply:ClearProperty("TTTThiefStealTarget", ply)
            ply:ClearProperty("TTTThiefStealStartTime", ply)
            ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
        end

        local proximity_time = thief_steal_proximity_time:GetInt()
        if state == THIEF_STEAL_STATE_STEALING or state == THIEF_STEAL_STATE_LOSING then
            -- If we're done dousing, mark the target and reset the thief state
            if curTime - startTime > proximity_time then
                ply:ClearProperty("TTTThiefStealTarget", ply)
                ply:ClearProperty("TTTThiefStealLostTime", ply)
                ply:ThiefSteal(target)
            end
        end
    end)

    AddHook("TTTOnRoleAbilityEnabled", "Thief_TTTOnRoleAbilityEnabled", function(ply)
        if not IsPlayer(ply) or not ply:IsThief() then return end
        ply.TTTThiefDisabled = false
    end)

    AddHook("Initialize", "Thief_Initialize", function()
        WIN_THIEF = GenerateNewWinID(ROLE_THIEF)
        EVENT_THIEFSTOLEN = GenerateNewEventID(ROLE_THIEF)
    end)

    -- Thief can only use the weapons they steal
    ROLE.onroleassigned = function(ply)
        -- Use a slight delay to make sure nothing else is changing this player's role first
        timer.Simple(0.25, function()
            if not IsPlayer(ply) then return end
            ply:StripWeapons()
            ply:Give("weapon_ttt_unarmed")
        end)
    end

    AddHook("PlayerCanPickupWeapon", "Thief_PlayerCanPickupWeapon", function(ply, wep)
        if not IsPlayer(ply) then return end
        if not ply:IsActiveThief() then return end
        if not IsValid(wep) then return end

        local wepClass = WEPS.GetClass(wep)
        if wepClass ~= "weapon_ttt_unarmed" and not wep.TTTThiefStolen then
            return false
        end
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTCheckForWin", "Thief_TTTCheckForWin", function()
        if not INDEPENDENT_ROLES[ROLE_THIEF] then return end

        local thief_alive = false
        local other_alive = false
        for _, v in PlayerIterator() do
            if v:IsActive() then
                if v:IsThief() then
                    thief_alive = true
                elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                    other_alive = true
                end
            end
        end

        if thief_alive and not other_alive then
            return WIN_THIEF
        end
    end)

    AddHook("TTTPrintResultMessage", "Thief_TTTPrintResultMessage", function(type)
        if type == WIN_THIEF then
            LANG.Msg("win_thief", { role = ROLE_STRINGS[ROLE_THIEF] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_THIEF] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Thief_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTThiefDisabled = false
            v:ClearProperty("TTTThiefStealTarget", v)
            v:ClearProperty("TTTThiefStealStartTime", v)
            v:ClearProperty("TTTThiefStealLostTime", v)
            v:ClearProperty("TTTThiefStealState", v)
            timer.Remove("TTTThiefNotifyDelay_" .. v:SteamID64())
        end
    end)
end

if CLIENT then
    ------------------
    -- STEALING HUD --
    ------------------

    local hide_role = GetConVar("ttt_hide_role")

    local client
    AddHook("HUDPaint", "Thief_HUDPaint", function()
        if not client then
            client = LocalPlayer()
        end

        if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
        if not client:IsThief() then return end

        local state = client.TTTThiefStealState
        if not state or state == THIEF_STEAL_STATE_IDLE or state == THIEF_STEAL_STATE_COOLDOWN then return end

        local targetSid64 = client.TTTThiefStealTarget
        if not targetSid64 or #targetSid64 == 0 then return end

        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then return end

        local proximity_time = thief_steal_proximity_time:GetInt()
        local endTime = client.TTTThiefStealStartTime + proximity_time

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w = 300
        local T = LANG.GetTranslation
        local PT = LANG.GetParamTranslation

        if state == THIEF_STEAL_STATE_LOST then
            local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
            CRHUD:PaintProgressBar(x, y, w, color, T("thfsteal_failed"), 1)
        elseif state >= THIEF_STEAL_STATE_STEALING then
            if endTime < 0 then return end

            local text = PT("thfsteal_stealing", {target = target:Nick()})
            local color = Color(0, 255, 0, 155)
            if state == THIEF_STEAL_STATE_LOSING then
                color = Color(255, 255, 0, 155)
            end

            local progress = math.min(1, 1 - ((endTime - CurTime()) / proximity_time))
            CRHUD:PaintProgressBar(x, y, w, color, text, progress)
        end
    end)

    AddHook("TTTHUDInfoPaint", "Thief_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not cli:IsActiveThief() then return end

        if cli.TTTThiefStealState ~= THIEF_STEAL_STATE_COOLDOWN then return end
        if not cli.TTTThiefStealStartTime then return end

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local remaining = cli.TTTThiefStealStartTime + thief_steal_success_cooldown:GetInt() - CurTime()
        local text = LANG.GetParamTranslation("thief_hud", {time = util.SimpleTime(remaining, "%02i:%02i")})
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "thief")
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTSyncWinIDs", "Thief_TTTSyncWinIDs", function()
        WIN_THIEF = WINS_BY_ROLE[ROLE_THIEF]
    end)

    AddHook("TTTScoringWinTitle", "Thief_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
        if wintype == WIN_THIEF then
            return { txt = "hilite_win_role_singular", params = { role = utf8.upper(ROLE_STRINGS[ROLE_THIEF]) }, c = ROLE_COLORS[ROLE_THIEF] }
        end
    end)

    ------------
    -- EVENTS --
    ------------

    local function GetWeaponName(item)
        local wep = util.WeaponForClass(item) or weapons.Get(item)
        if wep and (wep.PrintName or wep.GetPrintName) then
            return LANG.TryTranslation(wep.PrintName or wep:GetPrintName())
        end

        -- Sometimes the direct methods don't seem to work, so we'll do a loop if they fail
        for _, v in ipairs(weapons.GetList()) do
            if item == WEPS.GetClass(v) then
                return LANG.TryTranslation(v.GetPrintName and v:GetPrintName() or v.PrintName or item)
            end
        end

        return item
    end

    AddHook("TTTEventFinishText", "Thief_TTTEventFinishText", function(e)
        if e.win == WIN_THIEF then
            return LANG.GetParamTranslation("ev_win_thief", { role = string.lower(ROLE_STRINGS[ROLE_THIEF]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Thief_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_THIEF then
            return win_string, ROLE_STRINGS[ROLE_THIEF]
        end
    end)

    AddHook("TTTSyncEventIDs", "Thief_TTTSyncEventIDs", function()
        EVENT_THIEFSTOLEN = EVENTS_BY_ROLE[ROLE_THIEF]
        local swap_icon = Material("icon16/lock_open.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_THIEFSTOLEN, {
            text = function(e)
                return PT("ev_thiefstolen", {thief = e.thf, victim = e.vic, item = e.item})
            end,
            icon = function(e)
                return swap_icon, "Item stolen"
            end})
    end)

    net.Receive("TTT_ThiefItemStolen", function(len)
        local thief = net.ReadString()
        local victim = net.ReadString()
        local item = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_THIEFSTOLEN,
            thf = thief,
            vic = victim,
            item = GetWeaponName(item)
        })
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Thief_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_THIEF then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_THIEF] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to be the last player standing."

            -- TODO

            return html
        end
    end)
end

RegisterRole(ROLE)