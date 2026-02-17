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
local TableHasValue = table.HasValue
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "thief"
ROLE.name = "Thief"
ROLE.nameplural = "Thieves"
ROLE.nameext = "a Thief"
ROLE.nameshort = "thf"

ROLE.desc = [[You are {role}! {comrades}
Steal weapons from other players by
{method}.{cost}]]
ROLE.shortdesc = "Can only obtain weapons by stealing from other players. Steal something good and survive!"

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
        type = ROLE_CONVAR_TYPE_BOOL
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
        ["thf_tools_help_pri"] = "Use {primaryfire} to attack, like a normal Crowbar",
        ["thf_tools_help_sec"] = "Use {secondaryfire} to rob a player",
        ["thf_tools_help_sec_cost"] = "Use {secondaryfire} to rob a player. Costs {credits} credit",
        ["thfsteal_stealing"] = "STEALING FROM {target}",
        ["thfsteal_failed"] = "STEALING FAILED",
        ["thief_credits_hud"] = "Current Credits: {credits}",
        ["thief_cooldown_hud"] = "Steal cooldown: {time}",
        ["thief_steal_notify"] = "You stole \"{item}\" from {victim}!",
        ["win_thief"] = "The {role} has stolen its way to victory!",
        ["ev_win_thief"] = "The {role} has stolen its way to victory!",
        ["ev_thiefstolen"] = "{thief} stole \"{item}\" from {victim}"
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
local thief_steal_mode = CreateConVar("ttt_thief_steal_mode", "0", FCVAR_REPLICATED, "How stealing a weapon from a player works. 0 - Steal automatically when in proximity. 1 - Steal using their Thieves' Tools", 0, 1)
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

    if SERVER then
        local tools = weapons.GetStored("weapon_thf_thievestools")
        if thief_steal_mode:GetInt() == THIEF_STEAL_MODE_PROXIMITY then
            tools.InLoadoutFor = {}
        else
            tools.InLoadoutFor = tools.InLoadoutForDefault
        end
    end
end)

if SERVER then
    local plymeta = FindMetaTable("Player")
    if not plymeta then return end

    AddCSLuaFile()

    util.AddNetworkString("TTT_ThiefItemStolen")

    ------------------
    -- ROLE CONVARS --
    ------------------

    local thief_steal_failure_cooldown = CreateConVar("ttt_thief_steal_failure_cooldown", "3", FCVAR_NONE, "How long (in seconds) after the Thief loses their target before they can try to steal another thing", 0, 60)
    local thief_steal_proximity_float_time = CreateConVar("ttt_thief_steal_proximity_float_time", "3", FCVAR_NONE, "The amount of time (in seconds) it takes for the Thief to lose their target after getting out of range. Only used when \"ttt_thief_steal_mode 0\" is set", 0, 60)
    local thief_steal_proximity_require_los = CreateConVar("ttt_thief_steal_proximity_require_los", "1", FCVAR_NONE, "Whether the Thief requires line-of-sight to steal something. Only used when \"ttt_thief_steal_mode 0\" is set", 0, 1)
    local thief_steal_proximity_distance = CreateConVar("ttt_thief_steal_proximity_distance", "5", FCVAR_NONE, "How close (in meters) the Thief needs to be to their target to start stealing. Only used when \"ttt_thief_steal_mode 0\" is set", 1, 15)

    -------------------
    -- ROLE FEATURES --
    -------------------

    local allowedWeaponClasses = {"weapon_ttt_unarmed", "weapon_zm_carry", "weapon_thf_thievestools"}

    local function CanBeStolen(thief, wep)
        -- Don't try to steal role weapons
        if wep.Category == WEAPON_CATEGORY_ROLE then return false end

        local wepClass = WEPS.GetClass(wep)
        -- Or weapons the thief can get
        if TableHasValue(allowedWeaponClasses, wepClass) then return false end
        -- Or weapons the thief already has
        if thief:HasWeapon(wepClass) then return false end

        -- Or weapons that the thief can't carry because something is already in that slot
        if not thief:CanCarryType(wep.Kind) then return false end

        return true
    end

    AddHook("Initialize", "Thief_Initialize", function()
        WIN_THIEF = GenerateNewWinID(ROLE_THIEF)
        EVENT_THIEFSTOLEN = GenerateNewEventID(ROLE_THIEF)
    end)

    function plymeta:CanThiefStealFrom()
        if TRAITOR_ROLES[ROLE_THIEF] then
            return not self:IsGlitch() and not self:IsTraitorTeam()
        end
        if INNOCENT_ROLES[ROLE_THIEF] then
            return not self:IsDetectiveLike()
        end
        return true
    end

    function plymeta:ThiefSteal(target)
        if not self:Alive() or self:IsSpec() then return end
        if not IsPlayer(target) then return end
        if not target:Alive() or target:IsSpec() then return end

        local curTime = CurTime()

        -- Find a weapon for the thief to steal
        local items = {}
        local activeWep = target.GetActiveWeapon and target:GetActiveWeapon()
        for _, w in ipairs(target:GetWeapons()) do
            if not CanBeStolen(self, w) then continue end

            -- Ignore the active weapon for now, we'll use that as a fallback so it's not obvious the target has been robbed
            if w == activeWep then continue end

            TableInsert(items, w)
        end

        local item
        -- Choose a random item from the list
        if #items > 0 then
            item = items[MathRandom(#items)]
        -- If we didn't find anything worth stealing, see if the active weapon is an option
        elseif activeWep and CanBeStolen(self, activeWep) then
            item = activeWep
        end

        -- If no valid weapons are found, set to "LOST" state for the quick reset
        -- And tell them why it failed
        if not item then
            local steal_failure_cooldown = thief_steal_failure_cooldown:GetInt()
            if steal_failure_cooldown > 0 then
                self:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_LOST, self)
                self:SetProperty("TTTThiefStealStartTime", curTime + steal_failure_cooldown, self)
            end
            self:QueueMessage(MSG_PRINTCENTER, target:Nick() .. " has nothing worth stealing, try someone else!")
            return
        end

        -- Steal the weapon and set the property on the weapon so the thief can get it
        local itemClass = WEPS.GetClass(item)
        target:StripWeapon(itemClass)
        self.TTTThiefStolenWeapon = {
            class = itemClass,
            clip1 = item:Clip1(),
            clip2 = item:Clip2(),
            PAPUpgrade = item.PAPUpgrade
        }
        self:Give(itemClass)

        if thief_steal_cost:GetBool() then
            self:SubtractCredits(1)
        end
        self:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_COOLDOWN, self)
        self:SetProperty("TTTThiefStealStartTime", curTime, self)

        net.Start("TTT_ThiefItemStolen")
            net.WritePlayer(self)
            net.WriteString(target:Nick())
            net.WriteString(itemClass)
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
            target:QueueMessage(MSG_PRINTBOTH, "You have been been robbed by the " .. ROLE_STRINGS[ROLE_THIEF] .. "!")
        end)
    end

    local function ClearTracking(ply)
        if ply.TTTThiefStealStartTime then
            ply:ClearProperty("TTTThiefStealStartTime", ply)
        end
        if ply.TTTThiefStealLostTime then
            ply:ClearProperty("TTTThiefStealLostTime", ply)
        end

        if ply.TTTThiefStealState then
            ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
        end

        local targetSid64 = ply.TTTThiefStealTarget
        if targetSid64 and #targetSid64 > 0 then
            ply:ClearProperty("TTTThiefStealTarget", ply)
        end
    end

    AddHook("TTTPlayerRoleChanged", "Thief_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole == newRole then return end
        if ply:CanThiefStealFrom() then return end

        local sid64 = ply:SteamID64()
        for _, p in PlayerIterator() do
            if not p:IsThief() then continue end
            if p.TTTThiefStealTarget == sid64 then
                p:QueueMessage(MSG_PRINTBOTH, ply:Nick() .. " is now an ally so you've decided to stop trying to rob them")
                ClearTracking(p)
            end
        end
    end)

    AddHook("TTTPlayerAliveThink", "Thief_TTTPlayerAliveThink_Steal", function(ply)
        if GetRoundState() ~= ROUND_ACTIVE then return end
        if not ply:IsThief() then return end
        if ply.TTTThiefDisabled then return end

        -- If this role has their ability disabled, clear any set tracking variables and continue
        -- Clearing the state is required to get the progress bar to disappear if they were
        -- actively stealing when it begins
        if ply:IsRoleAbilityDisabled() then
            ClearTracking(ply)

            -- Use a server-side property to track this so we can short-circuit the processing loop and prevent repeated hook calls
            ply.TTTThiefDisabled = false
            return
        end

        local curTime = CurTime()
        local startTime = ply.TTTThiefStealStartTime
        local state = ply.TTTThiefStealState

        -- Keep track of the success cooldown
        if state == THIEF_STEAL_STATE_COOLDOWN then
            local steal_success_cooldown = thief_steal_success_cooldown:GetInt()
            if curTime - (startTime + steal_success_cooldown) >= 0 then
                ClearTracking(ply)
            end
            return
        end

        if thief_steal_mode:GetInt() ~= THIEF_STEAL_MODE_PROXIMITY then return end

        -- Don't let the player track anything if they don't have the credits to pay for it
        if thief_steal_cost:GetBool() and ply:GetCredits() <= 0 then
            ClearTracking(ply)
            return
        end

        local proximity_require_los = thief_steal_proximity_require_los:GetBool()
        local proximity_distance = thief_steal_proximity_distance:GetFloat() * UNITS_PER_METER
        local proxyDistanceSqr = proximity_distance * proximity_distance

        -- If we don't already have a target, find one
        local targetSid64 = ply.TTTThiefStealTarget
        local target = player.GetBySteamID64(targetSid64)
        if not IsPlayer(target) then
            local closestPly
            local closestPlyDist = -1
            for _, p in PlayerIterator() do
                if p == ply then continue end
                if not p:Alive() or p:IsSpec() then continue end
                -- Don't steal from people we know (or think) are friends
                if not p:CanThiefStealFrom() then continue end

                local distance = p:GetPos():DistToSqr(ply:GetPos())
                if distance < proxyDistanceSqr and (closestPlyDist == -1 or distance < closestPlyDist) then
                    if proximity_require_los and not ply:IsLineOfSightClear(p) then continue end
                    closestPlyDist = distance
                    closestPly = p
                end
            end

            if IsPlayer(closestPly) then
                ply:SetProperty("TTTThiefStealTarget", closestPly:SteamID64(), ply)
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_IDLE, ply)
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
                ClearTracking(ply)
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
                    ClearTracking(ply)
                end
            elseif distance <= proxyDistanceSqr and (not proximity_require_los or ply:IsLineOfSightClear(target)) then
                ply:SetProperty("TTTThiefStealState", THIEF_STEAL_STATE_STEALING, ply)
                ply:ClearProperty("TTTThiefStealLostTime", ply)
            end
        elseif state == THIEF_STEAL_STATE_LOST and curTime > startTime then
            ClearTracking(ply)
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

    -- Thief can only use the weapons they steal, plus the allowed defaults, their thieves' tools, and any melee weapons
    ROLE.onroleassigned = function(ply)
        -- Use a slight delay to make sure nothing else is changing this player's role first
        timer.Simple(0.25, function()
            if not IsPlayer(ply) then return end
            if not ply:IsActiveThief() then return end

            local activeWep = ply.GetActiveWeapon and ply:GetActiveWeapon()
            for _, w in ipairs(ply:GetWeapons()) do
                if w.Kind == WEAPON_MELEE then continue end

                local wepClass = WEPS.GetClass(w)
                if not TableHasValue(allowedWeaponClasses, wepClass) then
                    -- If we are removing the active weapon, switch to something we know they'll have instead
                    if activeWep == w then
                        timer.Simple(0.25, function()
                            if thief_steal_mode:GetInt() == THIEF_STEAL_MODE_TOOLS then
                                ply:SelectWeapon("weapon_thf_thievestools")
                            else
                                ply:SelectWeapon("weapon_zm_carry")
                            end
                        end)
                    end
                    ply:StripWeapon(wepClass)
                end
            end
        end)
    end

    AddHook("PlayerCanPickupWeapon", "Thief_PlayerCanPickupWeapon", function(ply, wep)
        if not IsPlayer(ply) then return end
        if not ply:IsActiveThief() then return end
        if not IsValid(wep) then return end
        if wep.Kind == WEAPON_MELEE then return end

        local wepClass = WEPS.GetClass(wep)
        if ply.TTTThiefStolenWeapon and ply.TTTThiefStolenWeapon.class == wepClass then
            return true
        end

        if not TableHasValue(allowedWeaponClasses, wepClass) then
            return false
        end
    end)

    AddHook("WeaponEquip", "Thief_WeaponEquip", function(wep, ply)
        if not IsPlayer(ply) then return end
        if not ply:IsActiveThief() then return end
        if not IsValid(wep) then return end

        local wepClass = WEPS.GetClass(wep)
        local data = ply.TTTThiefStolenWeapon
        if data and data.class == wepClass then
            -- Transfer weapon ammo
            wep:SetClip1(data.clip1)
            wep:SetClip2(data.clip2)

            -- Transfer the PAP upgrade over if it had one
            if TTTPAP and data.PAPUpgrade then
                TTTPAP:ApplyUpgrade(wep, data.PAPUpgrade)
            end

            -- Reset the property for the next steal
            ply.TTTThiefStolenWeapon = nil
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
        elseif thief_alive then
            return WIN_NONE
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
            v.TTTThiefStolenWeapon = nil
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

    local icon_tex = Material("icon16/coins.png")
    AddHook("TTTHUDInfoPaint", "Thief_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not cli:IsActiveThief() then return end

        surface.SetFont("TabLarge")

        local text
        local _, h

        local steal_cost = thief_steal_cost:GetBool()
        if steal_cost then
            local credits = client:GetCredits()
            if credits == 0 then
                surface.SetTextColor(255, 0, 0, 230)
            else
                surface.SetTextColor(255, 255, 255, 230)
            end
            text = LANG.GetParamTranslation("thief_credits_hud", {credits = credits})
            _, h = surface.GetTextSize(text)

            -- Move this up based on how many other labels there are
            label_top = label_top + (20 * #active_labels)

            local icon_x, icon_y = 16, 16
            surface.SetMaterial(icon_tex)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(label_left, ScrH() - label_top - icon_y, icon_x, icon_y)

            label_left = label_left + 20

            surface.SetTextPos(label_left, ScrH() - label_top - h)
            surface.DrawText(text)

            -- Track that the label was added so others can position accurately
            TableInsert(active_labels, "thiefCredits")
        end

        if cli.TTTThiefStealState ~= THIEF_STEAL_STATE_COOLDOWN then return end
        if not cli.TTTThiefStealStartTime then return end

        local remaining = cli.TTTThiefStealStartTime + thief_steal_success_cooldown:GetInt() - CurTime()
        text = LANG.GetParamTranslation("thief_cooldown_hud", {time = util.SimpleTime(remaining, "%02i:%02i")})
        _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels there are
        if steal_cost then
            label_top = label_top + 20
            label_left = label_left - 20
        else
            label_top = label_top + (20 * #active_labels)
        end

        surface.SetTextColor(255, 255, 255, 230)
        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "thiefCooldown")
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
        local swap_icon = Material("icon16/money.png")
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
        local thief = net.ReadPlayer()
        local victim = net.ReadString()
        local item = GetWeaponName(net.ReadString())

        if not IsPlayer(thief) then return end

        local message = LANG.GetParamTranslation("thief_steal_notify", {item = item, victim = victim})
        thief:QueueMessage(MSG_PRINTBOTH, message)

        CLSCORE:AddEvent({
            id = EVENT_THIEFSTOLEN,
            thf = thief:Nick(),
            vic = victim,
            item = item
        })
    end)

    ----------------
    -- ROLE POPUP --
    ----------------

    AddHook("TTTRolePopupParams", "Thief_TTTRolePopupParams", function(cli)
        if not cli:IsThief() then return end

        local params = {
            comrades = ""
        }
        if cli:IsIndependentTeam() then
            params.comrades = "Kill all others to win!\n"
        else cli:IsInnocentTeam()
            params.comrades = "Work with your team to win!\n"
        end

        if thief_steal_cost:GetBool() then
            params.cost = "\n\nStealing costs 1 credit per item."
        else
            params.cost = ""
        end

        if thief_steal_mode:GetInt() == THIEF_STEAL_MODE_PROXIMITY then
            params.method = "staying near a target"
        else
            params.method = "using your Thieves' Tools on a target"
        end

        return params
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Thief_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_THIEF then
            local roleColor
            local html = "The " .. ROLE_STRINGS[ROLE_THIEF] .. " is "
            local winCondition
            if INDEPENDENT_ROLES[ROLE_THIEF] then
                roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
                html = html .. "an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent role</span> role"
                winCondition = "be the last player standing"
            else
                local roleTeam = player.GetRoleTeam(ROLE_THIEF, true)
                local roleTeamName
                roleTeamName, roleColor = GetRoleTeamInfo(roleTeam)
                html = html .. "a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. roleTeamName .. " team</span>"
                winCondition = "help their team win"
            end
            html = html .. " whose goal is to steal weapons from their enemies and " .. winCondition .. "."

            -- Steal mode
            local steal_mode = thief_steal_mode:GetInt()
            html = html .. "<span style='display: block; margin-top: 10px;'>To steal a weapon from a player, the " .. ROLE_STRINGS[ROLE_THIEF] .. " must <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>"
            local extra = ""
            if steal_mode == THIEF_STEAL_MODE_PROXIMITY then
                html = html .. "stay near"
                extra = " for " .. thief_steal_proximity_time:GetInt() .. " second(s)"
            else
                html = html .. "use their Thieves' Tools on"
            end
            html = html .. " a target of their choosing</span>" .. extra .. ".</span>"

            -- Cost
            if thief_steal_cost:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>Stealing a weapon from a player <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>costs 1 credit</span> which you can get from the normal sources.</span>"
            end

            -- Show a warning about the notification delay if its enabled
            local delay_min = thief_steal_notify_delay_min:GetInt()
            local delay_max = thief_steal_notify_delay_max:GetInt()
            if delay_min > delay_max then
                delay_min = delay_max
            end

            if delay_min > 0 then
                html = html .. "<span style='display: block; margin-top: 10px;'>Be careful though! Players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified when they are robbed</span> after a short delay. Be sure to be sneaky or blend in with other players to disguise that you are the " .. ROLE_STRINGS[ROLE_THIEF] .. ".</span>"
            end

            -- Cooldown
            local steal_success_cooldown = thief_steal_success_cooldown:GetInt()
            if steal_success_cooldown > 0 then
                html = html .. "<span style='display: block; margin-top: 10px;'>After successfully stealing a weapon, the " .. ROLE_STRINGS[ROLE_THIEF] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>must wait " .. steal_success_cooldown .. " second(s)</span> before they can steal again.</span>"
            end

            return html
        end
    end)
end

RegisterRole(ROLE)
