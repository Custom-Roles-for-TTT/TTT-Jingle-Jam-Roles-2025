local hook = hook
local ipairs = ipairs
local math = math
local player = player
local string = string
local surface = surface
local table = table
local util = util
local weapons = weapons

local AddHook = hook.Add
local MathRandom = math.random
local PlayerIterator = player.Iterator
local StringUpper = string.upper
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "armsdealer"
ROLE.name = "Arms Dealer"
ROLE.nameplural = "Arms Dealers"
ROLE.nameext = "an Arms Dealer"
ROLE.nameshort = "adl"

ROLE.desc = [[You are {role}! Make arms deals with
the players you trust, but be sure to do
it sneakily so their enemies don't see you
as a threat.

Successfully make {deals} deal(s) while surviving
the chaos you cause to share the win.]]
ROLE.shortdesc = "Makes arms deals sneakily while trying to survive the chaos they cause."

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.convars =
{
    {
        cvar = "ttt_armsdealer_target_innocents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_target_detectives",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_target_traitors",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_target_independents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_target_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_target_monsters",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_deal_require_los",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_armsdealer_deal_target_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_success_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_notify_delay_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_notify_delay_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_to_win",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_failure_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_float_time",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_armsdealer_deal_distance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE.translations = {
    ["english"] = {
        ["adldeal_dealing"] = "DEALING TO {target}",
        ["adldeal_failed"] = "DEALING FAILED",
        ["armsdealer_collect_hud"] = "Dealt Weapons: {dealt}/{total}",
        ["armsdealer_cooldown_hud"] = "Deal Cooldown: {time}",
        ["armsdealer_deal_notify"] = "You dealt \"{item}\" to {target}!",
        ["ev_armsdealerdealt"] = "{armsdealer} dealt \"{item}\" to {target}",
        ["score_adl_dealt"] = "Dealt",
        ["score_adl_weapons"] = "{count} Weapon(s)",
        ["armsdealer_targetid"] = "COOLDOWN: {time}"
    }
}

ARMSDEALER_DEAL_STATE_IDLE = 0
ARMSDEALER_DEAL_STATE_DEALING = 1
ARMSDEALER_DEAL_STATE_LOSING = 2
ARMSDEALER_DEAL_STATE_LOST = 3
ARMSDEALER_DEAL_STATE_COOLDOWN = 4

------------------
-- ROLE CONVARS --
------------------

local armsdealer_deal_target_cooldown = CreateConVar("ttt_armsdealer_deal_target_cooldown", "30", FCVAR_REPLICATED, "How long (in seconds) after the Arms Dealer deals something to a target before that target can be dealt to again", 0, 60)
local armsdealer_deal_success_cooldown = CreateConVar("ttt_armsdealer_deal_success_cooldown", "0", FCVAR_REPLICATED, "How long (in seconds) after the Arms Dealer deals something before they can deal with anyone again", 0, 60)
local armsdealer_deal_notify_delay_min = CreateConVar("ttt_armsdealer_deal_notify_delay_min", "0", FCVAR_REPLICATED, "The minimum delay before a player is notified a weapon has been dealt to them. Set to \"-1\" to disable notifications. Set this and \"ttt_armsdealer_deal_notify_delay_max\" to \"0\" to notify instantly", -1, 30)
local armsdealer_deal_notify_delay_max = CreateConVar("ttt_armsdealer_deal_notify_delay_max", "30", FCVAR_REPLICATED, "The maximum delay before a player is notified a weapon has been dealt to them. Set this and \"ttt_armsdealer_deal_notify_delay_min\" to \"0\" to notify instantly", 0, 60)
local armsdealer_deal_time = CreateConVar("ttt_armsdealer_deal_time", "15", FCVAR_REPLICATED, "How long (in seconds) it takes the Arms Dealer to deal a weapon to a target", 1, 60)
local armsdealer_deal_to_win = CreateConVar("ttt_armsdealer_deal_to_win", "15", FCVAR_REPLICATED, "How many weapons the Arms Dealer has to deal to get a secondary win", 1, 25)
local armsdealer_target_innocents = CreateConVar("ttt_armsdealer_target_innocents", "0", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be an innocent role (not including detectives)", 0, 1)
local armsdealer_target_detectives = CreateConVar("ttt_armsdealer_target_detectives", "1", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be a detective role", 0, 1)
local armsdealer_target_traitors = CreateConVar("ttt_armsdealer_target_traitors", "1", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be a traitor role", 0, 1)
local armsdealer_target_independents = CreateConVar("ttt_armsdealer_target_independents", "1", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be an independent role", 0, 1)
local armsdealer_target_jesters = CreateConVar("ttt_armsdealer_target_jesters", "0", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be a jester role", 0, 1)
local armsdealer_target_monsters = CreateConVar("ttt_armsdealer_target_monsters", "1", FCVAR_REPLICATED, "Whether the Arms Dealer's target can be a monster role", 0, 1)

if SERVER then
    local plymeta = FindMetaTable("Player")
    if not plymeta then return end

    AddCSLuaFile()

    util.AddNetworkString("TTT_ArmsDealerItemDealt")

    ------------------
    -- ROLE CONVARS --
    ------------------

    local armsdealer_deal_failure_cooldown = CreateConVar("ttt_armsdealer_deal_failure_cooldown", "3", FCVAR_NONE, "How long (in seconds) after the Arms Dealer loses their target before they can try to deal another thing", 0, 60)
    local armsdealer_deal_float_time = CreateConVar("ttt_armsdealer_deal_float_time", "3", FCVAR_NONE, "The amount of time (in seconds) it takes for the Arms Dealer to lose their target after getting out of range", 0, 60)
    local armsdealer_deal_require_los = CreateConVar("ttt_armsdealer_deal_require_los", "1", FCVAR_NONE, "Whether the Arms Dealer requires line-of-sight to deal something", 0, 1)
    local armsdealer_deal_distance = CreateConVar("ttt_armsdealer_deal_distance", "5", FCVAR_NONE, "How close (in meters) the Arms Dealer needs to be to their target to start dealing", 1, 15)

    function plymeta:CanArmsDealerDealTo()
        if self.TTTArmsDealerCooldownTime and CurTime() < (self.TTTArmsDealerCooldownTime + armsdealer_deal_target_cooldown:GetInt()) then return false end
        if self:IsGlitch() or self:IsTraitorTeam() then return armsdealer_target_traitors:GetBool() end
        if self:IsInnocentTeam() then
            if self:IsDetectiveTeam() then return armsdealer_target_detectives:GetBool() end
            return armsdealer_target_innocents:GetBool()
        end
        if self:IsIndependentTeam() then return armsdealer_target_independents:GetBool() end
        if self:IsJesterTeam() then return armsdealer_target_jesters:GetBool() end
        if self:IsMonsterTeam() then return armsdealer_target_monsters:GetBool() end

        return false
    end

    AddHook("Initialize", "ArmsDealer_Initialize", function()
        EVENT_ARMSDEALERDEALT = GenerateNewEventID(ROLE_ARMSDEALER)
    end)

    local function ClearTracking(ply)
        if ply.TTTArmsDealerDealStartTime then
            ply:ClearProperty("TTTArmsDealerDealStartTime", ply)
        end
        if ply.TTTArmsDealerDealLostTime then
            ply:ClearProperty("TTTArmsDealerDealLostTime", ply)
        end

        if ply.TTTArmsDealerDealState then
            ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_IDLE, ply)
        end

        local targetSid64 = ply.TTTArmsDealerDealTarget
        if targetSid64 and #targetSid64 > 0 then
            ply:ClearProperty("TTTArmsDealerDealTarget", ply)
        end
    end

    AddHook("TTTPlayerRoleChanged", "ArmsDealer_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole == newRole then return end
        if ply:CanArmsDealerDealTo() then return end

        local sid64 = ply:SteamID64()
        for _, p in PlayerIterator() do
            if not p:IsArmsDealer() then continue end
            if p.TTTArmsDealerDealTarget == sid64 then
                p:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " is no longer a valid target for your dealing")
                ClearTracking(p)
            end
        end
    end)

    AddHook("TTTPlayerAliveThink", "ArmsDealer_TTTPlayerAliveThink_Deal", function(ply)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not ply:IsArmsDealer() then return end
        if ply.TTTArmsDealerDisabled then return end

        -- If this role has their ability disabled, clear any set tracking variables and continue
        -- Clearing the state is required to get the progress bar to disappear if they were
        -- actively dealing when it begins
        if ply:IsRoleAbilityDisabled() then
            ClearTracking(ply)

            -- Use a server-side property to track this so we can short-circuit the processing loop and prevent repeated hook calls
            ply.TTTArmsDealerDisabled = false
            return
        end

        local curTime = CurTime()
        local startTime = ply.TTTArmsDealerDealStartTime
        local state = ply.TTTArmsDealerDealState

        -- Keep track of the success cooldown
        if state == ARMSDEALER_DEAL_STATE_COOLDOWN then
            local deal_success_cooldown = armsdealer_deal_success_cooldown:GetInt()
            if curTime - (startTime + deal_success_cooldown) >= 0 then
                ClearTracking(ply)
            end
            return
        end

        local require_los = armsdealer_deal_require_los:GetBool()
        local deal_distance = armsdealer_deal_distance:GetFloat() * UNITS_PER_METER
        local dealDistanceSqr = deal_distance * deal_distance

        -- If we don't already have a target, find one
        local targetSid64 = ply.TTTArmsDealerDealTarget
        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then
            local closestPly
            local closestPlyDist = -1
            for _, p in PlayerIterator() do
                if p == ply then continue end
                if not p:Alive() or p:IsSpec() then continue end
                -- Don't deal to people we don't trust
                if not p:CanArmsDealerDealTo() then continue end

                local distance = p:GetPos():DistToSqr(ply:GetPos())
                if distance < dealDistanceSqr and (closestPlyDist == -1 or distance < closestPlyDist) then
                    if require_los and not ply:IsLineOfSightClear(p) then continue end
                    closestPlyDist = distance
                    closestPly = p
                end
            end

            if IsPlayer(closestPly) then
                ply:SetProperty("TTTArmsDealerDealTarget", closestPly:SteamID64(), ply)
                ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_IDLE, ply)
            end
            return
        end

        local deal_failure_cooldown = armsdealer_deal_failure_cooldown:GetInt()

        -- Handle the target dying
        if not target:Alive() or target:IsSpec() then
            if state ~= ARMSDEALER_DEAL_STATE_LOST and deal_failure_cooldown > 0 then
                ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_LOST, ply)
                -- Wait for the cooldown after losing before resetting
                ply:SetProperty("TTTArmsDealerDealStartTime", curTime + deal_failure_cooldown, ply)
            elseif curTime > startTime or deal_failure_cooldown == 0 then
                -- After the buffer time has passed, reset the variables for the armsdealer
                ClearTracking(ply)
            end
            return
        end

        -- Handle the distance checks
        local proxy_float_time = armsdealer_deal_float_time:GetInt()
        local distance = target:GetPos():DistToSqr(ply:GetPos())
        if state == ARMSDEALER_DEAL_STATE_IDLE then
            ply:SetProperty("TTTArmsDealerDealStartTime", curTime)
            ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_DEALING, ply)
        elseif state == ARMSDEALER_DEAL_STATE_DEALING then
            if distance > dealDistanceSqr or (require_los and not ply:IsLineOfSightClear(target)) then
                ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_LOSING, ply)
                ply:SetProperty("TTTArmsDealerDealLostTime", curTime + proxy_float_time, ply)
            end
        elseif state == ARMSDEALER_DEAL_STATE_LOSING then
            if curTime > ply.TTTArmsDealerDealLostTime then
                if deal_failure_cooldown > 0 then
                    ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_LOST, ply)
                    -- Wait for the cooldown after losing before resetting
                    ply:SetProperty("TTTArmsDealerDealStartTime", curTime + deal_failure_cooldown, ply)
                else
                    ClearTracking(ply)
                end
            elseif distance <= dealDistanceSqr and (not require_los or ply:IsLineOfSightClear(target)) then
                ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_DEALING, ply)
                ply:ClearProperty("TTTArmsDealerDealLostTime", ply)
            end
        elseif state == ARMSDEALER_DEAL_STATE_LOST and curTime > startTime then
            ClearTracking(ply)
        end

        local deal_time = armsdealer_deal_time:GetInt()
        if state == ARMSDEALER_DEAL_STATE_DEALING or state == ARMSDEALER_DEAL_STATE_LOSING then
            -- If we're done dousing, mark the target and reset the armsdealer state
            if curTime - startTime > deal_time then
                ply:ClearProperty("TTTArmsDealerDealTarget", ply)
                ply:ClearProperty("TTTArmsDealerDealLostTime", ply)

                local items = {}
                for _, v in ipairs(weapons.GetList()) do
                    if not v then continue end

                    -- Only allow weapons that can be bought, can be dropped, and don't spawn on their own
                    if v.AutoSpawnable or not v.AllowDrop then continue end
                    if not v.CanBuy or #v.CanBuy == 0 then continue end

                    -- Also make sure the target can use this weapon
                    local wepClass = WEPS.GetClass(v)
                    if target:HasWeapon(wepClass) then continue end
                    if not target:CanCarryType(v.Kind) then continue end

                    TableInsert(items, wepClass)
                end

                local item
                -- Choose a random item from the list
                if #items > 0 then
                    item = items[MathRandom(#items)]
                end

                -- Set the cooldown early so we try other targets if they can't hold any of the found weapons
                target:SetProperty("TTTArmsDealerCooldownTime", curTime, ply)

                -- If no valid weapons are found, set to "LOST" state for the quick reset
                -- And tell them why it failed
                if not item then
                    if deal_failure_cooldown > 0 then
                        ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_LOST, ply)
                        ply:SetProperty("TTTArmsDealerDealStartTime", curTime + deal_failure_cooldown, ply)
                    end
                    ply:ClearQueuedMessage("adlDealFailed")
                    ply:QueueMessage(MSG_PRINTCENTER, target:Nick() .. " has no room for your weapons, try someone else!", nil, "adlDealFailed")
                    return
                end

                -- Do the deal
                ply:SetProperty("TTTArmsDealerDealState", ARMSDEALER_DEAL_STATE_COOLDOWN, ply)
                ply:SetProperty("TTTArmsDealerDealStartTime", curTime, ply)
                ply:SetProperty("TTTArmsDealerDealt", (ply.TTTArmsDealerDealt or 0) + 1)

                net.Start("TTT_ArmsDealerItemDealt")
                    net.WritePlayer(ply)
                    net.WritePlayer(target)
                    net.WriteString(item)
                net.Broadcast()

                -- If we're dealing to a glitch and innocents aren't valid targets, just pretend
                if target:IsGlitch() and not armsdealer_target_innocents:GetBool() then return end

                target:Give(item)

                local deal_notify_delay_min = armsdealer_deal_notify_delay_min:GetInt()
                local deal_notify_delay_max = armsdealer_deal_notify_delay_max:GetInt()
                if deal_notify_delay_min > deal_notify_delay_max then
                    deal_notify_delay_max = deal_notify_delay_max
                end

                -- Send message (after a random delay) that this player has been dealt a weapon, but only if it's enabled
                if deal_notify_delay_min < 0 then return end

                local function DoNotify()
                    if not IsPlayer(target) then return end
                    if not target:Alive() or target:IsSpec() then return end
                    target:QueueMessage(MSG_PRINTBOTH, "The " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. " as dealt you a weapon!")
                end

                -- Notify instantly
                if deal_notify_delay_min == 0 then
                    DoNotify()
                else
                    local delay = MathRandom(deal_notify_delay_max, deal_notify_delay_max)
                    timer.Create("TTTArmsDealerNotifyDelay_" .. target:SteamID64(), delay, 1, DoNotify)
                end
            end
        end
    end)

    AddHook("TTTOnRoleAbilityEnabled", "ArmsDealer_TTTOnRoleAbilityEnabled", function(ply)
        if not IsPlayer(ply) or not ply:IsArmsDealer() then return end
        ply.TTTArmsDealerDisabled = false
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "ArmsDealer_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTArmsDealerDisabled = false
            v:ClearProperty("TTTArmsDealerDealt")
            v:ClearProperty("TTTArmsDealerCooldownTime")
            v:ClearProperty("TTTArmsDealerDealTarget", v)
            v:ClearProperty("TTTArmsDealerDealStartTime", v)
            v:ClearProperty("TTTArmsDealerDealLostTime", v)
            v:ClearProperty("TTTArmsDealerDealState", v)
            timer.Remove("TTTArmsDealerNotifyDelay_" .. v:SteamID64())
        end
    end)
end

if CLIENT then
    ---------------
    -- TARGET ID --
    ---------------

    local function GetRoleColor(ply)
        local roleTeam = ply:GetRoleTeam()
        if roleTeam == ROLE_TEAM_DETECTIVE then
            return ROLE_COLORS[ROLE_DETECTIVE]
        elseif ply:IsGlitch() or roleTeam == ROLE_TEAM_TRAITOR then
            return ROLE_COLORS[ROLE_TRAITOR]
        elseif roleTeam == ROLE_TEAM_INNOCENT then
            return ROLE_COLORS[ROLE_INNOCENT]
        end
        return GetRoleTeamColor(roleTeam)
    end

    -- Show a revealed target's team info (NOT ROLE)
    AddHook("TTTTargetIDPlayerRoleIcon", "ArmsDealer_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
        -- Don't overwrite something we already know
        if role then return end
        if not cli:IsArmsDealer() then return end
        if not IsPlayer(ply) then return end
        if not ply.TTTArmsDealerRevealed then return end
        if cli:IsRoleAbilityDisabled() then return end

        -- Simplify the "special" colors back to normal
        role = ply:GetRole()
        if DETECTIVE_ROLES[role] then
            role = ROLE_DETECTIVE
        elseif role == ROLE_GLITCH or TRAITOR_ROLES[role] then
            role = ROLE_TRAITOR
        elseif INNOCENT_ROLES[role] then
            role = ROLE_INNOCENT
        end

        return ROLE_NONE, false, role
    end)

    AddHook("TTTTargetIDPlayerRing", "ArmsDealer_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
        -- Don't overwrite something we already know
        if ring_visible then return end
        if not cli:IsArmsDealer() then return end
        if not IsPlayer(ent) then return end
        if not ent.TTTArmsDealerRevealed then return end
        if cli:IsRoleAbilityDisabled() then return end

        return true, GetRoleColor(ent)
    end)

    AddHook("TTTTargetIDPlayerText", "ArmsDealer_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        -- Don't bother if something else is already showing both texts
        if text and secondary_text then return end
        if not cli:IsArmsDealer() then return end
        if not IsPlayer(ent) then return end
        if cli:IsRoleAbilityDisabled() then return end

        local primary, primaryCol
        local secondary, secondaryCol
        -- Show a target's cooldown, if they have one
        if ent.TTTArmsDealerCooldownTime then
            local remaining = (ent.TTTArmsDealerCooldownTime + armsdealer_deal_target_cooldown:GetInt()) - CurTime()
            if remaining > 0 then
                primary = LANG.GetParamTranslation("armsdealer_targetid", { time = util.SimpleTime(remaining, "%02i:%02i") })
                primaryCol = ROLE_COLORS_RADAR[ROLE_ARMSDEALER]
            end
        end

        -- And their team (NOT ROLE), if revealed and previously unknown
        if not ent:IsDetectiveTeam() and ent.TTTArmsDealerRevealed then
            local roleTeam = ent:GetRoleTeam()
            if ent:IsGlitch() then
                roleTeam = ROLE_TEAM_TRAITOR
            end
            local roleTeamName = GetRoleTeamName(roleTeam)
            local teamReveal = LANG.GetParamTranslation("target_unknown_team", { targettype = StringUpper(roleTeamName) })

            -- Move the cooldown down below the role info
            if primary then
                secondary = primary
                secondaryCol = primaryCol
            end
            primary = teamReveal
            primaryCol = GetRoleColor(ent)
        end

        if not primary then return end

        -- Don't overwrite text
        if text then
            return text, col, primary, primaryCol
        else
            return primary, primaryCol, secondary, secondaryCol
        end
    end)

    ROLE.istargetidoverridden = function(ply, target, showJester)
        if not ply:IsArmsDealer() then return end
        if not IsPlayer(ply) then return end
        if ply:IsRoleAbilityDisabled() then return end

        local iconRing = false
        local text = false
        if target.TTTArmsDealerCooldownTime then
            local remaining = (target.TTTArmsDealerCooldownTime + armsdealer_deal_target_cooldown:GetInt()) - CurTime()
            if remaining > 0 then
                text = true
            end
        end

        if target.TTTArmsDealerRevealed then
            iconRing = true
            text = true
        end

        ------ icon    , ring    , text
        return iconRing, iconRing, text
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    AddHook("TTTScoreboardPlayerRole", "ArmsDealer_TTTScoreboardPlayerRole", function(ply, cli, c, roleStr)
        -- Don't overwrite something we already know
        if roleStr and #roleStr ~= 0 then return end
        if not cli:IsArmsDealer() then return end
        if not IsPlayer(ply) then return end
        if not ply.TTTArmsDealerRevealed then return end
        if cli:IsRoleAbilityDisabled() then return end

        -- Simplify the "special" colors back to normal
        local role = ply:GetRole()
        if DETECTIVE_ROLES[role] then
            role = ROLE_DETECTIVE
        elseif role == ROLE_GLITCH or TRAITOR_ROLES[role] then
            role = ROLE_TRAITOR
        elseif INNOCENT_ROLES[role] then
            role = ROLE_INNOCENT
        end

        return ROLE_COLORS_SCOREBOARD[role], ROLE_STRINGS_SHORT[ROLE_NONE]
    end)

    ROLE.isscoreboardinfooverridden = function(ply, target, showJester)
        if not ply:IsArmsDealer() then return end
        if not IsPlayer(target) then return end
        if not target.TTTArmsDealerRevealed then return end
        if ply:IsRoleAbilityDisabled() then return end

        ------ name , role
        return false, true
    end

    ------------------
    -- DEALING HUD --
    ------------------

    local hide_role = GetConVar("ttt_hide_role")

    local client
    AddHook("HUDPaint", "ArmsDealer_HUDPaint", function()
        if not client then
            client = LocalPlayer()
        end

        if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
        if not client:IsArmsDealer() then return end

        local state = client.TTTArmsDealerDealState
        if not state or state == ARMSDEALER_DEAL_STATE_IDLE or state == ARMSDEALER_DEAL_STATE_COOLDOWN then return end

        local targetSid64 = client.TTTArmsDealerDealTarget
        if not targetSid64 or #targetSid64 == 0 then return end

        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then return end

        local deal_time = armsdealer_deal_time:GetInt()
        local endTime = client.TTTArmsDealerDealStartTime + deal_time

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w = 300
        local T = LANG.GetTranslation
        local PT = LANG.GetParamTranslation

        if state == ARMSDEALER_DEAL_STATE_LOST then
            local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
            CRHUD:PaintProgressBar(x, y, w, color, T("adldeal_failed"), 1)
        elseif state >= ARMSDEALER_DEAL_STATE_DEALING then
            if endTime < 0 then return end

            local text = PT("adldeal_dealing", {target = target:Nick()})
            local color = Color(0, 255, 0, 155)
            if state == ARMSDEALER_DEAL_STATE_LOSING then
                color = Color(255, 255, 0, 155)
            end

            local progress = math.min(1, 1 - ((endTime - CurTime()) / deal_time))
            CRHUD:PaintProgressBar(x, y, w, color, text, progress)
        end
    end)

    AddHook("TTTHUDInfoPaint", "ArmsDealer_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not cli:IsActiveArmsDealer() then return end

        surface.SetFont("TabLarge")

        local text
        local _, h

        local deal_to_win = armsdealer_deal_to_win:GetInt()
        if deal_to_win > 0 then
            local dealt = cli.TTTArmsDealerDealt or 0
            if dealt >= deal_to_win then
                surface.SetTextColor(0, 200, 0, 230)
            else
                surface.SetTextColor(255, 255, 255, 230)
            end
            text = LANG.GetParamTranslation("armsdealer_collect_hud", {dealt = dealt, total = deal_to_win})
            _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels there are
            label_top = label_top + (20 * #active_labels)

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            TableInsert(active_labels, "armsdealerCredits")
        end

        if cli.TTTArmsDealerDealState ~= ARMSDEALER_DEAL_STATE_COOLDOWN then return end
        if not cli.TTTArmsDealerDealStartTime then return end

        local remaining = cli.TTTArmsDealerDealStartTime + armsdealer_deal_success_cooldown:GetInt() - CurTime()
        text = LANG.GetParamTranslation("armsdealer_cooldown_hud", {time = util.SimpleTime(remaining, "%02i:%02i")})
        _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels there are
        if deal_to_win > 0 then
            label_top = label_top + 20
        else
            label_top = label_top + (20 * #active_labels)
        end

        surface.SetTextColor(255, 255, 255, 230)
        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "armsdealerCooldown")
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTScoringSecondaryWins", "ArmsDealer_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        local deal_to_win = armsdealer_deal_to_win:GetInt()
        for _, p in PlayerIterator() do
            if not p:IsArmsDealer() then continue end

            local dealt = p.TTTArmsDealerDealt or 0
            if dealt >= deal_to_win then
                TableInsert(secondary_wins, ROLE_ARMSDEALER)
                return
            end
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

    AddHook("TTTSyncEventIDs", "ArmsDealer_TTTSyncEventIDs", function()
        EVENT_ARMSDEALERDEALT = EVENTS_BY_ROLE[ROLE_ARMSDEALER]
        local deal_icon = Material("icon16/group_go.png")
        local Event = CLSCORE.DeclareEventDisplay
        local PT = LANG.GetParamTranslation
        Event(EVENT_ARMSDEALERDEALT, {
            text = function(e)
                return PT("ev_armsdealerdealt", {armsdealer = e.adl, target = e.tar, item = e.item})
            end,
            icon = function(e)
                return deal_icon, "Item dealt"
            end})
    end)

    net.Receive("TTT_ArmsDealerItemDealt", function(len)
        local armsdealer = net.ReadPlayer()
        local target = net.ReadPlayer()
        local item = GetWeaponName(net.ReadString())

        if not IsPlayer(target) then return end
        if not IsPlayer(armsdealer) then return end

        -- Mark the target as known to the Arms Dealer and reveal any previously-unknown team affiliation
        target.TTTArmsDealerRevealed = true

        -- If this client is the armsdealer that did the dealing, use this
        -- method to also notify them of what they dealt
        if not client then
            client = LocalPlayer()
        end
        if client == armsdealer then
            local message = LANG.GetParamTranslation("armsdealer_deal_notify", {item = item, target = target:Nick()})
            client:ClearQueuedMessage("adlDealFailed")
            client:QueueMessage(MSG_PRINTBOTH, message)
        end

        CLSCORE:AddEvent({
            id = EVENT_ARMSDEALERDEALT,
            adl = armsdealer:Nick(),
            tar = target:Nick(),
            item = item
        })
    end)

    AddHook("TTTScoringSummaryRender", "ArmsDealer_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if not IsPlayer(ply) then return end
        if not ply:IsArmsDealer() then return end

        local dealt = ply.TTTArmsDealerDealt or 0
        local deal_to_win = armsdealer_deal_to_win:GetInt()
        if deal_to_win > 0 then
            dealt = dealt .. "/" .. deal_to_win
        end
        return roleFileName, groupingRole, roleColor, name, LANG.GetParamTranslation("score_adl_weapons", {count = dealt}), LANG.GetTranslation("score_adl_dealt")
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "ArmsDealer_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTArmsDealerRevealed = false
        end
    end)

    ----------------
    -- ROLE POPUP --
    ----------------

    AddHook("TTTRolePopupParams", "ArmsDealer_TTTRolePopupParams", function(cli)
        if cli:IsArmsDealer() then
            return { deals = armsdealer_deal_to_win:GetInt() }
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "ArmsDealer_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_ARMSDEALER then
            local T = LANG.GetTranslation
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to sneakily make " .. armsdealer_deal_to_win:GetInt() .. " arms deal(s) while surviving the chaos they cause."

            local target_innocents = armsdealer_target_innocents:GetBool()
            local target_detectives = armsdealer_target_detectives:GetBool()
            local target_traitors = armsdealer_target_traitors:GetBool()
            local target_independents = armsdealer_target_independents:GetBool()
            local target_jesters = armsdealer_target_jesters:GetBool()
            local target_monsters = armsdealer_target_monsters:GetBool()
            html = html .. "<span style='display: block; margin-top: 10px;'>They can deal with any role that is a member of <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>"
            if target_innocents and target_detectives and target_traitors and target_independents and target_jesters and target_monsters then
                html = html .. "any team</span>.</span>"
            else
                html = html .. "the following</span>:<ul>"
                if target_innocents then
                    html = html .. "<li>" .. T("innocents") .. "</li>"
                end
                if target_detectives then
                    html = html .. "<li>" .. T("detectives") .. "</li>"
                end
                if target_traitors then
                    html = html .. "<li>" .. T("traitors") .. "</li>"
                end
                if target_independents then
                    html = html .. "<li>" .. T("independents") .. "</li>"
                end
                if target_jesters then
                    html = html .. "<li>" .. T("jesters") .. "</li>"
                end
                if target_monsters then
                    html = html .. "<li>" .. T("monsters") .. "</li>"
                end
                html = html .. "</ul></span>"
            end

            html = html .. "<span style='display: block; margin-top: 10px;'>To deal a weapon to a player, the " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. " must <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>stay near a target of their choosing</span> for " .. armsdealer_deal_time:GetInt() .. " second(s).</span>"

            -- Show a warning about the notification delay if its enabled
            local delay_min = armsdealer_deal_notify_delay_min:GetInt()
            local delay_max = armsdealer_deal_notify_delay_max:GetInt()
            if delay_min > delay_max then
                delay_min = delay_max
            end

            if delay_min >= 0 then
                local time = "after a short delay"
                if delay_min == 0 then
                    time = "immediately"
                end
                html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified when they are given a weapon</span> " .. time .. ". Be sure to be sneaky or blend in with other players to disguise that you are the " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. ".</span>"
            end

            -- Cooldown
            local deal_target_cooldown = armsdealer_deal_target_cooldown:GetInt()
            if deal_target_cooldown > 0 then
                html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. " can only deal to the same target again <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>after waiting " .. deal_target_cooldown .. " second(s)</span> to encourage seeking out multiple targets.</span>"
            end

            local deal_success_cooldown = armsdealer_deal_success_cooldown:GetInt()
            if deal_success_cooldown > 0 then
                html = html .. "<span style='display: block; margin-top: 10px;'>After successfully dealing a weapon, the " .. ROLE_STRINGS[ROLE_ARMSDEALER] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>must wait " .. deal_success_cooldown .. " second(s)</span> before they can deal to any player again.</span>"
            end

            return html
        end
    end)
end

RegisterRole(ROLE)