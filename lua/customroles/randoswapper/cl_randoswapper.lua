local hook = hook
local net = net

local AddHook = hook.Add

-------------
-- CONVARS --
-------------

local randoswapper_healthstation_reduce_max = GetConVar("ttt_randoswapper_healthstation_reduce_max")
local randoswapper_max_swaps = GetConVar("ttt_randoswapper_max_swaps")

------------------
-- TRANSLATIONS --
------------------

AddHook("TTTRolePopupParams", "Randoswapper_TTTRolePopupParams", function(cli)
    if not cli:IsRandoswapper() then return end

    return { randoswapper = ROLE_STRINGS[ROLE_RANDOSWAPPER] }
end)

------------
-- EVENTS --
------------

AddHook("TTTSyncEventIDs", "Randoswapper_TTTSyncEventIDs", function()
    EVENT_RANDOSWAPPER = EVENTS_BY_ROLE[ROLE_RANDOSWAPPER]
    local swap_icon = Material("icon16/arrow_refresh_small.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation
    Event(EVENT_RANDOSWAPPER, {
        text = function(e)
            return PT("ev_randoswapped", {victim = e.vic, attacker = e.att})
        end,
        icon = function(e)
            return swap_icon, "Randoswapped"
        end})
end)

net.Receive("TTT_RandoswapperSwapped", function(len)
    local victim = net.ReadString()
    local attacker = net.ReadString()
    local vicsid = net.ReadString()
    CLSCORE:AddEvent({
        id = EVENT_RANDOSWAPPER,
        vic = victim,
        att = attacker,
        sid64 = vicsid,
        bonus = 2
    })
end)

-------------
-- SCORING --
-------------

-- Show who the current randoswapper killed (if anyone)
AddHook("TTTScoringSummaryRender", "Randoswapper_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
    if not IsPlayer(ply) then return end

    if ply:IsRandoswapper() then
        local swappedWith = ply:GetNWString("RandoswappedWith", "")
        if #swappedWith > 0 then
            return roleFileName, groupingRole, roleColor, name, swappedWith, LANG.GetTranslation("score_randoswapper_killed")
        end
    end
end)

--------------
-- TUTORIAL --
--------------

AddHook("TTTTutorialRoleText", "Randoswapper_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_RANDOSWAPPER then
        local roleColor = GetRoleTeamColor(ROLE_TEAM_JESTER)
        local html = "The " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester</span> role whose goal is to be killed by another player and steal their role while also triggering a Randomat event."

        html = html .. "<span style='display: block; margin-top: 10px;'>After <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>swapping</span>, they take over the goal of their new role.</span>"
        html = html .. "<span style='display: block; margin-top: 10px;'>Be careful, the player who <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>kills the " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .."</span> then <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>becomes the " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .."</span>. Make sure to not kill them back!</span>"

        local max_swaps = randoswapper_max_swaps:GetInt()
        if max_swaps > 0 then
            html = html .. "<span style='display: block; margin-top: 10px;'>If the " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .. " is killed more than " .. max_swaps .. " time(s), they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>become " .. ROLE_STRINGS_EXT[ROLE_SWAPPER] .. "</span> instead.</span>"
        end

        if randoswapper_healthstation_reduce_max:GetBool() then
            html = html .. "<span style='display: block; margin-top: 10px;'>When the " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .. " uses a health station, their <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>maximum health is reduced</span> toward their current health instead of them being healed.</span>"
        end

        return html
    end
end)