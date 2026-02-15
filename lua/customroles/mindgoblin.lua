local hook = hook
local math = math
local net = net
local player = player
local string = string
local table = table
local timer = timer
local util = util

local AddHook = hook.Add
local MathRound = math.Round
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "mindgoblin"
ROLE.name = "Mind Goblin"
ROLE.nameplural = "Mind Goblins"
ROLE.nameext = "a Mind Goblin"
ROLE.nameshort = "mgb"
ROLE.team = ROLE_TEAM_JESTER

ROLE.desc = [[You are {role}! You will possess
the person who kills you. But you're nice
so you can give them buffs and if they win,
so do you!]]
ROLE.shortdesc = "Possesses their killer, allowing them to give buffs and help get a shared win."

ROLE.convars =
{
    {
        cvar = "ttt_mindgoblin_possess_power_starting",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_power_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_power_rate",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_dissolve",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_mindgoblin_possess_heal_cost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_heal_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_speed_cost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_speed_factor",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_mindgoblin_possess_speed_length",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_damage_cost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_damage_factor",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_mindgoblin_possess_damage_length",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_resist_cost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_mindgoblin_possess_resist_factor",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_mindgoblin_possess_resist_length",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE.translations = {
    ["english"] = {
        ["ev_mindgoblin_possess"] = "{victim} started possessing {attacker}",
        ["mindgoblin_possess_title"] = "WILLPOWER",
        ["mindgoblin_possess_heal"] = "Heal",
        ["mindgoblin_possess_heal_desc"] = "Press backward to heal {target}",
        ["mindgoblin_possess_speed"] = "Speed",
        ["mindgoblin_possess_speed_desc"] = "Press forward to hasten {target}",
        ["mindgoblin_possess_damage"] = "Damage Boost",
        ["mindgoblin_possess_damage_desc"] = "Press right to boost {target}'s damage",
        ["mindgoblin_possess_resist"] = "Damage Resist",
        ["mindgoblin_possess_resist_desc"] = "Press left to boost {target}'s damage resist"
    }
}

------------------
-- ROLE CONVARS --
------------------

local mindgoblin_possess_power_max = CreateConVar("ttt_mindgoblin_possess_power_max", "100", FCVAR_REPLICATED, "The maximum amount of power a Mind Goblin can have when possessing their killer", 1, 200)

local mindgoblin_possess_heal_cost = CreateConVar("ttt_mindgoblin_possess_heal_cost", "50", FCVAR_REPLICATED, "The amount of power to spend when a Mind Goblin is healing their killer via a possession. Set to 0 to disable", 0, 100)
local mindgoblin_possess_heal_amount = CreateConVar("ttt_mindgoblin_possess_heal_amount", "25", FCVAR_REPLICATED, "The amount of health to heal the target for over time when a Mind Goblin uses the heal power", 1, 100)

local mindgoblin_possess_speed_cost = CreateConVar("ttt_mindgoblin_possess_speed_cost", "25", FCVAR_REPLICATED, "The amount of power to spend when a Mind Goblin is speeding up their killer attack via a possession. Set to 0 to disable", 0, 100)
local mindgoblin_possess_speed_factor = CreateConVar("ttt_mindgoblin_possess_speed_factor", "0.5", FCVAR_REPLICATED, "The speed boost to give the target (e.g. 0.5 = 50% faster movement)", 0.1, 1)
local mindgoblin_possess_speed_length = CreateConVar("ttt_mindgoblin_possess_speed_length", "10", FCVAR_REPLICATED, "How long (in seconds) the target's speed boost lasts", 1, 60)

local mindgoblin_possess_damage_cost = CreateConVar("ttt_mindgoblin_possess_damage_cost", "75", FCVAR_REPLICATED, "The amount of power to spend when a Mind Goblin is increasing the damage of their killer via a possession. Set to 0 to disable", 0, 100)
local mindgoblin_possess_damage_factor = CreateConVar("ttt_mindgoblin_possess_damage_factor", "0.25", FCVAR_REPLICATED, "The damage bonus that the target has against other players (e.g. 0.25 = 25% extra damage)", 0.05, 1)
local mindgoblin_possess_damage_length = CreateConVar("ttt_mindgoblin_possess_damage_length", "10", FCVAR_REPLICATED, "How long (in seconds) the target's damage boost lasts", 1, 60)

local mindgoblin_possess_resist_cost = CreateConVar("ttt_mindgoblin_possess_resist_cost", "75", FCVAR_REPLICATED, "The amount of power to spend when a Mind Goblin is giving their killer damage resist via a possession. Set to 0 to disable", 0, 100)
local mindgoblin_possess_resist_factor = CreateConVar("ttt_mindgoblin_possess_resist_factor", "0.25", FCVAR_REPLICATED, "The damage resist that the target has against other players (e.g. 0.25 = 25% less damage)", 0.05, 1)
local mindgoblin_possess_resist_length = CreateConVar("ttt_mindgoblin_possess_resist_length", "10", FCVAR_REPLICATED, "How long (in seconds) the target's damage resist lasts", 1, 60)

-------------------
-- ROLE FEATURES --
-------------------

local speedPlayers = {}
AddHook("TTTSpeedMultiplier", "MindGoblin_TTTSpeedMultiplier", function(ply, mults)
    if not ply:Alive() or ply:IsSpec() then return end
    local sid = ply:SteamID64()
    local speedFactor
    if speedPlayers[sid] and speedPlayers[sid] > 0 then
        speedFactor = 1 + (mindgoblin_possess_speed_factor:GetFloat() * speedPlayers[sid])
    end

    if speedFactor then
        TableInsert(mults, speedFactor)
    end
end)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_MindGoblinPossess")
    util.AddNetworkString("TTT_MindGoblinSpeedStart")
    util.AddNetworkString("TTT_MindGoblinSpeedEnd")
    util.AddNetworkString("TTT_MindGoblinHealStart")
    util.AddNetworkString("TTT_MindGoblinHealEnd")

    ------------------
    -- ROLE CONVARS --
    ------------------

    local mindgoblin_dissolve = CreateConVar("ttt_mindgoblin_dissolve", "1", FCVAR_NONE, "Whether the Mind Goblin's body should dissolve when they die", 0, 1)
    local mindgoblin_possess_power_rate = CreateConVar("ttt_mindgoblin_possess_power_rate", "10", FCVAR_NONE, "The amount of power to regain per second when a Mind Goblin is possessing their killer", 1, 25)
    local mindgoblin_possess_power_starting = CreateConVar("ttt_mindgoblin_possess_power_starting", "0", FCVAR_NONE, "The amount of power to the Mind Goblin starts with", 0, 200)

    -------------------
    -- ROLE FEATURES --
    -------------------

    AddHook("PlayerDeath", "MindGoblin_PlayerDeath", function(victim, inflictor, attacker)
        if not IsPlayer(victim) then return end
        if not victim:IsMindGoblin() then return end
        if victim:IsRoleAbilityDisabled() then return end

        if mindgoblin_dissolve:GetBool() then
            local ragdoll = victim.server_ragdoll or victim:GetRagdollEntity()
            if ragdoll then
                ragdoll:Dissolve()
            end
        end

        local validKill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
        if not validKill then return end

        if attacker:IsVictimChangingRole(victim) then return end

        if not attacker:Alive() or attacker:IsSpec() then
            victim:QueueMessage(MSG_PRINTBOTH, "Your attacker is already dead so you have nobody to possess.")
            return
        end

        victim:SetProperty("TTTMindGoblinPossessing", true, victim)
        victim:SetProperty("TTTMindGoblinPossessingTarget", attacker:SteamID64())
        victim:SetProperty("TTTMindGoblinPossessingPower", mindgoblin_possess_power_starting:GetInt(), victim)
        local power_rate = mindgoblin_possess_power_rate:GetInt()
        timer.Create("MindGoblinPossessingPower_" .. victim:SteamID64(), 1 / power_rate, 0, function()
            -- Make sure the victim is still in the correct spectate mode
            local spec_mode = victim:GetObserverMode()
            if spec_mode ~= OBS_MODE_CHASE and spec_mode ~= OBS_MODE_IN_EYE then
                victim:Spectate(OBS_MODE_CHASE)
            end

            local power = victim.TTTMindGoblinPossessingPower or 0
            local new_power = math.Clamp(power + 1, 0, mindgoblin_possess_power_max:GetInt())
            victim:SetProperty("TTTMindGoblinPossessingPower", new_power, victim)
        end)

        -- Lock the victim's view on their attacker
        timer.Create("MindGoblinPossessingSpectate_" .. victim:SteamID64(), 1, 1, function()
            victim:SetRagdollSpec(false)
            victim:Spectate(OBS_MODE_CHASE)
            victim:SpectateEntity(attacker)
        end)

        attacker:QueueMessage(MSG_PRINTCENTER, "You have been possessed.")
        victim:QueueMessage(MSG_PRINTCENTER, "Your attacker has been possessed.")

        net.Start("TTT_MindGoblinPossess")
            net.WriteString(victim:Nick())
            net.WriteString(attacker:Nick())
        net.Broadcast()
    end)

    local timerIds = {}
    local damagePlayers = {}
    local resistPlayers = {}
    AddHook("KeyPress", "MindGoblin_KeyPress", function(ply, key)
        if not IsPlayer(ply) then return end
        if not ply:IsMindGoblin() then return end

        local power = ply.TTTMindGoblinPossessingPower or 0
        if power <= 0 then return end

        local target = ply:GetObserverMode() ~= OBS_MODE_ROAMING and ply:GetObserverTarget() or nil
        if not IsPlayer(target) then return end

        local heal_cost = mindgoblin_possess_heal_cost:GetInt()
        local speed_cost = mindgoblin_possess_speed_cost:GetInt()
        local damage_cost = mindgoblin_possess_damage_cost:GetInt()
        local resist_cost = mindgoblin_possess_resist_cost:GetInt()

        local spent
        local verb
        local plySid64 = ply:SteamID64()
        local targetSid64 = target:SteamID64()
        local goblinSubject = "your target, " .. target:Nick()
        local targetSubject = "you"
        if key == IN_BACK and power >= heal_cost then
            if target:Health() >= target:GetMaxHealth() then return end

            local timerId = "MindGoblinHealBuff_" .. plySid64 .. "_" .. targetSid64
            if timer.Exists(timerId) then return end

            net.Start("TTT_MindGoblinHealStart")
                net.WriteString(targetSid64)
            net.Broadcast()

            local heal_amount = mindgoblin_possess_heal_amount:GetInt()

            timerIds[timerId] = true
            -- Test this
            timer.Create(timerId, 1, heal_amount, function()
                if target:Alive() and not target:IsSpec() then
                    local hp = target:Health()
                    if hp < target:GetMaxHealth() then
                        target:SetHealth(hp + 1)
                    end
                end
            end)

            timerIds[timerId .. "_Smoke"] = true
            timer.Create(timerId .. "_Smoke", heal_amount, 1, function()
                timer.Remove(timerId)
                timer.Remove(timerId .. "_Smoke")
                net.Start("TTT_MindGoblinHealEnd")
                    net.WriteString(targetSid64)
                net.Broadcast()
            end)

            spent = heal_cost
            verb = "healed"
        elseif key == IN_FORWARD and power >= speed_cost then
            local timerId = "MindGoblinSpeedBuff_" .. plySid64 .. "_" .. targetSid64
            if timer.Exists(timerId) then return end

            if not speedPlayers[targetSid64] then
                speedPlayers[targetSid64] = 0
            end
            speedPlayers[targetSid64] = speedPlayers[targetSid64] + 1

            timerIds[timerId] = true
            timer.Create(timerId, mindgoblin_possess_speed_length:GetInt(), 1, function()
                timer.Remove(timerId)
                net.Start("TTT_MindGoblinSpeedEnd")
                    net.WriteString(targetSid64)
                net.Send(target)

                speedPlayers[targetSid64] = speedPlayers[targetSid64] - 1
            end)

            net.Start("TTT_MindGoblinSpeedStart")
                net.WriteString(targetSid64)
            net.Send(target)

            spent = speed_cost
            verb = "hastened"
        elseif key == IN_MOVERIGHT and power >= damage_cost then
            local timerId = "MindGoblinDamageBuff_" .. plySid64 .. "_" .. targetSid64
            if timer.Exists(timerId) then return end

            if not damagePlayers[targetSid64] then
                damagePlayers[targetSid64] = 0
            end
            damagePlayers[targetSid64] = damagePlayers[targetSid64] + 1

            timerIds[timerId] = true
            timer.Create(timerId, mindgoblin_possess_damage_length:GetInt(), 1, function()
                timer.Remove(timerId)
                damagePlayers[targetSid64] = damagePlayers[targetSid64] - 1
            end)

            spent = damage_cost
            verb = "buffed"
            goblinSubject = goblinSubject .. "'s damage"
            targetSubject = targetSubject .. "r damage"
        elseif key == IN_MOVELEFT and power >= resist_cost then
            local timerId = "MindGoblinResistBuff_" .. plySid64 .. "_" .. targetSid64
            if timer.Exists(timerId) then return end

            if not resistPlayers[targetSid64] then
                resistPlayers[targetSid64] = 0
            end
            resistPlayers[targetSid64] = resistPlayers[targetSid64] + 1

            timerIds[timerId] = true
            timer.Create(timerId, mindgoblin_possess_resist_length:GetInt(), 1, function()
                timer.Remove(timerId)
                resistPlayers[targetSid64] = resistPlayers[targetSid64] - 1
            end)

            spent = resist_cost
            verb = "buffed"
            goblinSubject = goblinSubject .. "'s damage resistance"
            targetSubject = targetSubject .. "r damage resistance"
        end

        if not spent then return end

        ply:QueueMessage(MSG_PRINTBOTH, "You have " .. verb .. " " .. goblinSubject)
        target:QueueMessage(MSG_PRINTBOTH, ROLE_STRINGS_EXT[ROLE_MINDGOBLIN] .. " has " .. verb .. " " .. targetSubject .. "!")
        ply:SetProperty("TTTMindGoblinPossessingPower", power - spent, ply)
    end)

    AddHook("EntityTakeDamage", "MindGoblin_EntityTakeDamage", function(ply, dmginfo)
        local att = dmginfo:GetAttacker()
        -- If the attacker is buffed, scale their damage up
        if IsPlayer(att) and att:Alive() and not att:IsSpec() then
            local attSid64 = att:SteamID64()
            if damagePlayers[attSid64] and damagePlayers[attSid64] > 0 then
                dmginfo:ScaleDamage(1 + mindgoblin_possess_damage_factor:GetFloat())
            end
        end

        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end

        -- If the victim has resistance, scale their damage up
        local plySid64 = ply:SteamID64()
        if resistPlayers[plySid64] and resistPlayers[plySid64] > 0 then
            dmginfo:ScaleDamage(1 - mindgoblin_possess_resist_factor:GetFloat())
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("Initialize", "MindGoblin_Initialize", function()
        EVENT_MINDGOBLIN = GenerateNewEventID(ROLE_MINDGOBLIN)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "MindGoblin_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:ClearProperty("TTTMindGoblinPossessingTarget")
            v:ClearProperty("TTTMindGoblinPossessing", v)
            v:ClearProperty("TTTMindGoblinPossessingPower", v)
            timer.Remove("MindGoblinPossessingPower_" .. v:SteamID64())
            timer.Remove("MindGoblinPossessingSpectate_" .. v:SteamID64())
        end

        for timerId, _ in pairs(timerIds) do
            timer.Remove(timerId)
        end
        timerIds = {}
        speedPlayers = {}
        damagePlayers = {}
        resistPlayers = {}
    end)
end

if CLIENT then
    ROLE.shouldshowspectatorhud = function(ply)
        return ply.TTTMindGoblinPossessing
    end

    -------------------
    -- ROLE FEATURES --
    -------------------

    local healPlayers = {}
    net.Receive("TTT_MindGoblinHealStart", function()
        local sid64 = net.ReadString()
        if not healPlayers[sid64] then
            healPlayers[sid64] = 0
        end
        healPlayers[sid64] = healPlayers[sid64] + 1
    end)

    net.Receive("TTT_MindGoblinHealEnd", function()
        local sid64 = net.ReadString()
        if not healPlayers[sid64] then return end
        healPlayers[sid64] = healPlayers[sid64] - 1
    end)

    AddHook("TTTShouldPlayerSmoke", "MindGoblin_TTTShouldPlayerSmoke", function(ply, cli, shouldSmoke, smokeParticle, smokeOffset)
        local sid64 = ply:SteamID64()
        if healPlayers[sid64] and healPlayers[sid64] > 0 then
            return true, COLOR_GREEN
        end
    end)

    net.Receive("TTT_MindGoblinSpeedStart", function()
        local cli = LocalPlayer()
        if not IsPlayer(cli) then return end
        if not cli:Alive() or cli:IsSpec() then return end

        local sid64 = net.ReadString()
        if not speedPlayers[sid64] then
            speedPlayers[sid64] = 0
        end
        speedPlayers[sid64] = speedPlayers[sid64] + 1
    end)

    net.Receive("TTT_MindGoblinSpeedEnd", function()
        local cli = LocalPlayer()
        if not IsPlayer(cli) then return end

        local sid64 = net.ReadString()
        if not speedPlayers[sid64] then return end
        speedPlayers[sid64] = speedPlayers[sid64] - 1
    end)

    ---------
    -- HUD --
    ---------

    AddHook("TTTSpectatorShowHUD", "MindGoblin_TTTSpectatorShowHUD", function(cli, tgt)
        if not cli:IsMindGoblin() or not IsPlayer(tgt) then return end

        local L = LANG.GetUnsafeLanguageTable()

        local willpower_colors = {
            border = COLOR_WHITE,
            background = Color(17, 115, 135, 222),
            fill = Color(82, 226, 255, 255)
        }

        local powers = {}
        local speed_cost = mindgoblin_possess_speed_cost:GetInt()
        if speed_cost > 0 then
            TableInsert(powers, {name = L.mindgoblin_possess_speed, key = "up", cost = speed_cost, desc = string.Interp(L.mindgoblin_possess_speed_desc, {target = tgt:Nick()})})
        end
        local heal_cost = mindgoblin_possess_heal_cost:GetInt()
        if heal_cost > 0 then
            TableInsert(powers, {name = L.mindgoblin_possess_heal, key = "down", cost = heal_cost, desc = string.Interp(L.mindgoblin_possess_heal_desc, {target = tgt:Nick()})})
        end
        local resist_cost = mindgoblin_possess_resist_cost:GetInt()
        if resist_cost > 0 then
            TableInsert(powers, {name = L.mindgoblin_possess_resist, key = "left", cost = resist_cost, desc = string.Interp(L.mindgoblin_possess_resist_desc, {target = tgt:Nick()})})
        end
        local damage_cost = mindgoblin_possess_damage_cost:GetInt()
        if damage_cost > 0 then
            TableInsert(powers, {name = L.mindgoblin_possess_damage, key = "right", cost = damage_cost, desc = string.Interp(L.mindgoblin_possess_damage_desc, {target = tgt:Nick()})})
        end

        if #powers == 0 then return end

        local current_power = cli.TTTMindGoblinPossessingPower or 0
        local max_power = mindgoblin_possess_power_max:GetInt()

        CRHUD:PaintPowersHUD(cli, powers, max_power, current_power, willpower_colors, L.mindgoblin_possess_title)
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTSyncEventIDs", "MindGoblin_TTTSyncEventIDs", function()
        EVENT_MINDGOBLIN = EVENTS_BY_ROLE[ROLE_MINDGOBLIN]
        local possess_icon = Material("icon16/group.png")
        local PT = LANG.GetParamTranslation
        local Event = CLSCORE.DeclareEventDisplay
        Event(EVENT_MINDGOBLIN, {
            text = function(e)
                return PT("ev_mindgoblin_possess", {victim = e.vic, attacker = e.att})
            end,
            icon = function(e)
                return possess_icon, "Possess"
            end})
    end)

    net.Receive("TTT_MindGoblinPossess", function(len)
        local victim = net.ReadString()
        local attacker = net.ReadString()
        CLSCORE:AddEvent({
            id = EVENT_MINDGOBLIN,
            vic = victim,
            att = attacker
        })
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTScoringSecondaryWins", "MindGoblin_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        for _, p in PlayerIterator() do
            if p:Alive() or not p:IsSpec() then continue end
            if not p:IsMindGoblin() then continue end

            local targetSid64 = p.TTTMindGoblinPossessingTarget
            if not targetSid64 or #targetSid64 == 0 then continue end

            local target = player.GetBySteamID64(targetSid64)
            if not IsPlayer(target) then continue end
            if not target:Alive() or target:IsSpec() then continue end

            TableInsert(secondary_wins, ROLE_MINDGOBLIN)
            return
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "MindGoblin_TTTPrepareRound", function()
        speedPlayers = {}
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "MindGoblin_TTTTutorialRoleText", function(role, titleLabel)
        if role ~= ROLE_MINDGOBLIN then return end

        local T = LANG.GetTranslation
        local roleColor = ROLE_COLORS[ROLE_MINDGOBLIN]

        local html = "The " .. ROLE_STRINGS[ROLE_MINDGOBLIN] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. T("jester") .. " role</span> who becomes more powerful after they die."

        local max = mindgoblin_possess_power_max:GetInt()
        local heal_cost = mindgoblin_possess_heal_cost:GetInt()
        local speed_cost = mindgoblin_possess_speed_cost:GetInt()
        local damage_cost = mindgoblin_possess_damage_cost:GetInt()
        local resist_cost = mindgoblin_possess_resist_cost:GetInt()

        -- Possessing powers
        if heal_cost > 0 or speed_cost > 0 or damage_cost > 0 or resist_cost > 0 then
            html = html .. "<span style='display: block; margin-top: 10px'>While dead, the " .. ROLE_STRINGS[ROLE_MINDGOBLIN] .. " will possess their killer, generating up to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>" .. max .. " possession power</span> over time. This possession power can be used on the following actions:</span>"

            html = html .. "<ul style='margin-top: 0'>"
            if heal_cost > 0 then
                local heal_amount = mindgoblin_possess_heal_amount:GetInt()
                html = html .. "<li>Heal (Cost: " .. heal_cost .. ") - <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Heal the target</span> for " .. heal_amount .. " HP when using your heal key</li>"
            end
            if speed_cost > 0 then
                local speed_factor = mindgoblin_possess_speed_factor:GetFloat()
                local speed_length = mindgoblin_possess_speed_length:GetInt()
                html = html .. "<li>Speed Boost (Cost: " .. speed_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>run " .. MathRound(speed_factor * 100) .. "% faster</span> for " .. speed_length .. " second(s) using your speed boost key</li>"
            end
            if damage_cost > 0 then
                local damage_factor = mindgoblin_possess_damage_factor:GetFloat()
                local damage_length = mindgoblin_possess_damage_length:GetInt()
                html = html .. "<li>Damage Boost (Cost: " .. damage_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>do " .. MathRound(damage_factor * 100) .. "% more damage</span> for " .. damage_length .. " second(s) using your damage boost key</li>"
            end
            if resist_cost > 0 then
                local resist_factor = mindgoblin_possess_resist_factor:GetFloat()
                local resist_length = mindgoblin_possess_resist_length:GetInt()
                html = html .. "<li>Damage Resistance (Cost: " .. resist_cost .. ") - Make the target <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>take " .. MathRound(resist_factor * 100) .. "% less damage</span> for " .. resist_length .. " second(s) using your damage resist key</li>"
            end
            html = html .. "</ul>"
        end

        html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_MINDGOBLIN] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>shares the win with their killer</span> so they want to use the buffs to help as much as possible.</span>"

        return html
    end)
end

RegisterRole(ROLE)