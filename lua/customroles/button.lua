local hook = hook
local math = math
local player = player
local string = string
local table = table

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local MathRad = math.rad
local MathSin = math.sin
local MathCos = math.cos
local MathMax = math.max
local MathFloor = math.floor
local StringSub = string.sub
local StringFormat = string.format
local TableInsert = table.insert
local Utf8Upper = utf8.upper

local ROLE = {}

ROLE.nameraw = "button"
ROLE.name = "Button"
ROLE.nameplural = "Buttons"
ROLE.nameext = "a Button"
ROLE.nameshort = "btn"

ROLE.desc = [[You are {role}! Get {traitors} to push
you enough times to win, but don't let the timer
run out without {aninnocent} turning you back or the
{traitors} will win instead!]]
ROLE.shortdesc = "Turns into a button that wants to be pressed to win, but if no one stops the countdown traitors win instead."

ROLE.team = ROLE_TEAM_JESTER

ROLE.convars =
{
    {
        cvar = "ttt_button_announce",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_button_presses_to_win",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_button_reset_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Everyone", "Not the activator", "Not traitors"},
        isNumeric = true,
        numericOffset = 0
    },
    {
        cvar = "ttt_button_traitor_activate_only",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_button_countdown_length",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 1
    },
    {
        cvar = "ttt_button_countdown_pause",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["btn_transformer_help_pri"] = "Use {primaryfire} to transform into a button",
        ["btn_transformer_help_sec"] = "Use {secondaryfire} to transform back",
        ["ev_win_button"] = "The {role} clicked their way to victory!",
        ["but_button_name"] = "Button",
        ["but_button_hint_start"] = "Press {usekey} to start the countdown",
        ["but_button_hint_stop"] = "Press {usekey} to stop the countdown",
        ["but_button_hint_blocked"] = "Someone else has to stop the countdown",
        ["but_button_hint_double"] = "Only one button can be active at a time"
    }
}

BUTTON_RESET_BLOCK_NONE = 0
BUTTON_RESET_BLOCK_PRESSER = 1
BUTTON_RESET_BLOCK_TRAITORS = 2

------------------
-- ROLE CONVARS --
------------------

local button_announce = CreateConVar("ttt_button_announce", "1", FCVAR_REPLICATED, "Whether to announce that there is a Button", 0, 1)
local button_presses_to_win = CreateConVar("ttt_button_presses_to_win", "3", FCVAR_REPLICATED, "How many times the Button needs to be activated to win.", 1, 10)
local button_reset_mode = CreateConVar("ttt_button_reset_mode", "1", FCVAR_REPLICATED, "Who is allowed to reset the Button's countdown. 0 - Everyone. 1 - Not the activator. 2 - Not traitors.", 0, 2)
local button_traitor_activate_only = CreateConVar("ttt_button_traitor_activate_only", "1", FCVAR_REPLICATED, "Whether only traitors are allowed to activate the Button and start the countdown.", 0, 1)
local button_countdown_length = CreateConVar("ttt_button_countdown_length", "15", FCVAR_REPLICATED, "How long the Button's countdown lasts before traitors win.", 1, 60)
local button_countdown_pause = CreateConVar("ttt_button_countdown_pause", "0", FCVAR_REPLICATED, "If the Button's countdown should pause instead of resetting.", 0, 1)

if SERVER then
    AddCSLuaFile()

    util.AddNetworkString("TTT_UpdateButtonWins")
    util.AddNetworkString("TTT_ResetButtonWins")
    util.AddNetworkString("TTT_ButtonPlaySound")
    util.AddNetworkString("TTT_ButtonResetSounds")

    ------------------
    -- ANNOUNCEMENT --
    ------------------

    -- Warn other players that there is a button
    AddHook("TTTBeginRound", "Button_Announce_TTTBeginRound", function()
        if not button_announce:GetBool() then return end

        timer.Simple(1.5, function()
            local hasButton = false
            for _, v in PlayerIterator() do
                if v:IsButton() then
                    hasButton = true
                end
            end

            if hasButton then
                for _, v in PlayerIterator() do
                    if not v:IsButton() then
                        v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_BUTTON] .. ".")
                    end
                end
            end
        end)
    end)

    ------------
    -- DAMAGE --
    ------------

    AddHook("EntityTakeDamage", "Button_EntityTakeDamage", function(ent, dmginfo)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end
        if not ent:IsButton() then return end

        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end

        dmginfo:SetDamage(0)
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("Initialize", "Button_Initialize", function()
        WIN_BUTTON = GenerateNewWinID(ROLE_BUTTON)
    end)

    AddHook("TTTCheckForWin", "Button_TTTCheckForWin", function()
        if GetGlobalBool("ttt_button_pressed") and CurTime() > GetGlobalFloat("ttt_button_timer_end", -1) then
            return WIN_TRAITOR
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Button_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:SetProperty("TTTButtonPresses", 0)
            -- If this player has a button attached to them (and vice versa), detach it
            if v.ButtonEnt then
                v.ButtonEnt:Remove()
                v.ButtonEnt = nil
                v:SetParent(nil)
            end
        end

        SetGlobalBool("ttt_button_pressed", false)
        SetGlobalFloat("ttt_button_timer_end", -1)
        SetGlobalFloat("ttt_button_time_left", -1)

        net.Start("TTT_ResetButtonWins")
        net.Broadcast()
    end)

    -------------------
    -- SANITY CHECKS --
    -------------------

    -- If the button's role changes, make sure they aren't stuck as a button
    AddHook("TTTPlayerRoleChanged", "Button_TTTPlayerRoleChanged", function(ply, oldRole, newRole)
        if oldRole == ROLE_BUTTON and newRole ~= ROLE_BUTTON then
            if ply.ButtonEnt then
                ply.ButtonEnt:Remove()
                ply.ButtonEnt = nil
                ply:SetParent(nil)
                ply:SpectateEntity(nil)
                ply:UnSpectate()
                ply:DrawViewModel(true)
                ply:DrawWorldModel(true)
                ply:SetNoDraw(false)
            end
        end
    end)
end

if CLIENT then
    -------------
    -- CONVARS --
    -------------

    local timer_offset_x = CreateClientConVar("ttt_button_timer_offset_x", "0", true, false, "The screen offset from the center to render the timer at, on the x axis (left-and-right)")
    local timer_offset_y = CreateClientConVar("ttt_button_timer_offset_y", "20", true, false, "The screen offset from the top to render the timer at, on the y axes (up-and-down)")

    concommand.Add("ttt_button_timer_offset_reset", function()
        timer_offset_x:SetInt(timer_offset_x:GetDefault())
        timer_offset_y:SetInt(timer_offset_y:GetDefault())
    end)

    local segmentWidth = 8
    local segmentLength = 28
    local segmentMargin = 2

    local timerWidth = 8*segmentWidth + 4*segmentLength + 8*segmentMargin
    local timerHeight = segmentWidth + 2*segmentLength + 4*segmentMargin

    AddHook("TTTSettingsRolesTabSections", "Button_TTTSettingsRolesTabSections", function(role, parentForm)
        if role ~= ROLE_BUTTON then return end

        -- Let the user move the timer within the bounds of the window
        local width = (ScrW() - timerWidth) / 2
        parentForm:NumSlider(LANG.GetTranslation("button_config_timer_offset_x"), "ttt_button_timer_offset_x", -width, width, 0)
        parentForm:NumSlider(LANG.GetTranslation("button_config_timer_offset_y"), "ttt_button_timer_offset_y", 0, ScrH() - timerHeight, 0)
        parentForm:Button(LANG.GetTranslation("button_config_timer_offset_reset"), "ttt_button_timer_offset_reset")
        return true
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTSyncWinIDs", "Button_TTTSyncWinIDs", function()
        WIN_BUTTON = WINS_BY_ROLE[ROLE_BUTTON]
    end)

    local buttonWins = false
    net.Receive("TTT_UpdateButtonWins", function()
        -- Log the win event with an offset to force it to the end
        buttonWins = true
        CLSCORE:AddEvent({
            id = EVENT_FINISH,
            win = WIN_BUTTON
        }, 1)
    end)

    local function ResetButtonWin()
        buttonWins = false
    end
    net.Receive("TTT_ResetButtonWins", ResetButtonWin)
    AddHook("TTTPrepareRound", "Button_WinTracking_TTTPrepareRound", ResetButtonWin)
    AddHook("TTTBeginRound", "Button_WinTracking_TTTBeginRound", ResetButtonWin)

    AddHook("TTTScoringSecondaryWins", "Button_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if buttonWins then
            TableInsert(secondary_wins, ROLE_BUTTON)
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTEventFinishText", "Button_TTTEventFinishText", function(e)
        if e.win == WIN_BUTTON then
            return LANG.GetParamTranslation("ev_win_button", { role = string.lower(ROLE_STRINGS[ROLE_BUTTON]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Button_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_BUTTON then
            return "ev_win_icon_also", ROLE_STRINGS[ROLE_BUTTON]
        end
    end)

    ---------
    -- HUD --
    ---------

    local function DrawSevenSegmentDigit(digit, x, y, w, l, m)
        -- Segment A (Top)
        if digit ~= "1" and digit ~= "4" then
            surface.DrawPoly({
                {x = x + w/2 + m,       y = y + w/2},
                {x = x + w + m,         y = y},
                {x = x + l + m,         y = y},
                {x = x + w/2 + l + m,   y = y + w/2},
                {x = x + l + m,         y = y + w},
                {x = x + w + m,         y = y + w}
            })
        end

        -- Segment B (Top Right)
        if digit ~= "5" and digit ~= "6" then
            surface.DrawPoly({
                {x = x + w/2 + l + 2*m, y = y + w/2 + m},
                {x = x + w + l + 2*m,   y = y + w + m},
                {x = x + w + l + 2*m,   y = y + l + m},
                {x = x + w/2 + l + 2*m, y = y + w/2 + l + m},
                {x = x + l + 2*m,       y = y + l + m},
                {x = x + l + 2*m,       y = y + w + m}
            })
        end

        -- Segment C (Bottom Right)
        if digit ~= "2" then
            surface.DrawPoly({
                {x = x + w/2 + l + 2*m, y = y + w/2 + l + 3*m},
                {x = x + w + l + 2*m,   y = y + w + l + 3*m},
                {x = x + w + l + 2*m,   y = y + 2*l + 3*m},
                {x = x + w/2 + l + 2*m, y = y + w/2 + 2*l + 3*m},
                {x = x + l + 2*m,       y = y + 2*l + 3*m},
                {x = x + l + 2*m,       y = y + w + l + 3*m}
            })
        end

        -- Segment D (Bottom)
        if digit ~= "1" and digit ~= "4" and digit ~= "7" then
            surface.DrawPoly({
                {x = x + w/2 + m,       y = y + w/2 + 2*l + 4*m},
                {x = x + w + m,         y = y + 2*l + 4*m},
                {x = x + l + m,         y = y + 2*l + 4*m},
                {x = x + w/2 + l + m,   y = y + w/2 + 2*l + 4*m},
                {x = x + l + m,         y = y + w + 2*l + 4*m},
                {x = x + w + m,         y = y + w + 2*l + 4*m}
            })
        end

        -- Segment E (Bottom Left)
        if digit == "2" or digit == "6" or digit == "8" or digit == "0" then
            surface.DrawPoly({
                {x = x + w/2,           y = y + w/2 + l + 3*m},
                {x = x + w,             y = y + w + l + 3*m},
                {x = x + w,             y = y + 2*l + 3*m},
                {x = x + w/2,           y = y + w/2 + 2*l + 3*m},
                {x = x,                 y = y + 2*l + 3*m},
                {x = x,                 y = y + w + l + 3*m}
            })
        end

        -- Segment F (Top Left)
        if digit ~= "1" and digit ~= "2" and digit ~= "3" and digit ~= "7" then
            surface.DrawPoly({
                {x = x + w/2,           y = y + w/2 + m},
                {x = x + w,             y = y + w + m},
                {x = x + w,             y = y + l + m},
                {x = x + w/2,           y = y + w/2 + l + m},
                {x = x,                 y = y + l + m},
                {x = x,                 y = y + w + m}
            })
        end

        -- Segment G (Center)
        if digit ~= "1" and digit ~= "7" and digit ~= "0" then
            surface.DrawPoly({
                {x = x + w/2 + m,       y = y + w/2 + l + 2*m},
                {x = x + w + m,         y = y + l + 2*m},
                {x = x + l + m,         y = y + l + 2*m},
                {x = x + w/2 + l + m,   y = y + w/2 + l + 2*m},
                {x = x + l + m,         y = y + w + l + 2*m},
                {x = x + w + m,         y = y + w + l + 2*m}
            })
        end
    end

    local function DrawCircle(x, y, r)
        x = x + r
        y = y + r
        local circle = {}

        for i = 0, 12 do
            local a = MathRad((i/10) * -360)
            TableInsert(circle, {x = x + MathSin(a) * r, y = y + MathCos(a) * r})
        end

        surface.DrawPoly(circle)
    end

    local function DrawSevenSegmentNumber(num, x, y, w, l, m)
        local display = StringFormat("%05.2f", num)
        for i = 1, #display do
            local digit = StringSub(display, i,i)
            if digit == "." then
                DrawCircle(x - w/2, y + 2*l + 4*m, w/2)
                x = x + w
            else
                DrawSevenSegmentDigit(digit, x, y, w, l, m)
                x = x + 2*w + l + 2*m
            end
        end

    end

    AddHook("HUDPaint", "Button_HUDPaint", function()
        local x = ((ScrW() - timerWidth) / 2) + timer_offset_x:GetInt();
        local y = timer_offset_y:GetInt();
        local remaining = MathMax(0, GetGlobalFloat("ttt_button_timer_end", -1) - CurTime())
        if GetGlobalBool("ttt_button_pressed", false) then
            surface.SetDrawColor(255, 0, 0, 192)
            DrawSevenSegmentNumber(remaining, x, y, segmentWidth, segmentLength, segmentMargin)
        elseif button_countdown_pause:GetBool() then
            local timeLeft = GetGlobalFloat("ttt_button_time_left", -1)
            if timeLeft > 0 then
                surface.SetDrawColor(0, 255, 0, 192)
                DrawSevenSegmentNumber(timeLeft, x, y, segmentWidth, segmentLength, segmentMargin)
            end
        end
    end)

    local redTint = {
        ["$pp_colour_addr"] = 0.1,
        ["$pp_colour_addg"] = 0,
        ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"] = 1,
        ["$pp_colour_colour"] = 1,
        ["$pp_colour_mulr"] = 0,
        ["$pp_colour_mulg"] = 0,
        ["$pp_colour_mulb"] = 0
    }
    AddHook("RenderScreenspaceEffects", "Button_RenderScreenspaceEffects", function()
        if not GetGlobalBool("ttt_button_pressed", false) then return end
        local remaining = MathMax(0, GetGlobalFloat("ttt_button_timer_end", -1) - CurTime())
        if MathFloor(remaining) % 2 == 0 then
            DrawColorModify(redTint)
        end
    end)

    ------------
    -- SOUNDS --
    ------------

    local countdownNumbers = {"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
    local playedNumber = {false, false, false, false, false, false, false, false, false, false}
    AddHook("Think", "Button_Think", function()
        if not GetGlobalBool("ttt_button_pressed", false) then return end

        local remaining = MathMax(0, GetGlobalFloat("ttt_button_timer_end", -1) - CurTime())
        for k, v in ipairs(playedNumber) do
            if not v and remaining < k then
                playedNumber[k] = true
                surface.PlaySound("button/" .. countdownNumbers[k] .. ".wav")
            end
        end
    end)

    local function ResetSounds()
        local countdown_length = button_countdown_length:GetFloat();
        for k, _ in ipairs(playedNumber) do
            playedNumber[k] = k > countdown_length
        end
    end

    AddHook("TTTPrepareRound", "Button_ResetSounds_TTTPrepareRound", function()
        ResetSounds()
    end)

    net.Receive("TTT_ButtonResetSounds", ResetSounds)

    net.Receive("TTT_ButtonPlaySound", function()
        local sound = net.ReadString()
        surface.PlaySound("button/" .. sound .. ".wav")
    end)

    ---------------
    -- TARGET ID --
    ---------------

    AddHook("TTTTargetIDPlayerRoleIcon", "Button_TTTTargetIDPlayerRoleIcon", function(ply, cli, role, noz, color_role, hideBeggar, showJester, hideBodysnatcher)
        if GetRoundState() < ROUND_ACTIVE then return end
        if cli:IsTraitorTeam() and ply:IsButton() then
            return ROLE_BUTTON, false, ROLE_BUTTON
        end
    end)

    AddHook("TTTTargetIDPlayerRing", "Button_TTTTargetIDPlayerRing", function(ent, cli, ring_visible)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end

        if cli:IsTraitorTeam() and ent:IsButton() then
            return true, ROLE_COLORS_RADAR[ROLE_BUTTON]
        end
    end)

    AddHook("TTTTargetIDPlayerText", "Button_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(ent) then return end

        if cli:IsTraitorTeam() and ent:IsButton() then
            return Utf8Upper(ROLE_STRINGS[ROLE_BUTTON]), ROLE_COLORS_RADAR[ROLE_BUTTON]
        end
    end)

    ROLE.istargetidoverridden = function(ply, target)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(target) then return end

        local visible = ply:IsTraitorTeam() and target:IsButton()
        ------ icon,    ring,    text
        return visible, visible, visible
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    AddHook("TTTScoreboardPlayerRole", "Button_TTTScoreboardPlayerRole", function(ply, cli, color, roleFileName)
        if GetRoundState() < ROUND_ACTIVE then return end
        if cli:IsTraitorTeam() and ply:IsButton() then
            return ROLE_COLORS_SCOREBOARD[ROLE_BUTTON], ROLE_STRINGS_SHORT[ROLE_BUTTON]
        end
    end)

    ROLE.isscoreboardinfooverridden = function(ply, target)
        if GetRoundState() < ROUND_ACTIVE then return end
        if not IsPlayer(target) then return end

        local visible = ply:IsTraitorTeam() and target:IsButton()
        ------ name,  role
        return false, visible
    end

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Button_TTTTutorialRoleText", function(role, titleLabel)
        -- TODO: Add tutorial
        if role == ROLE_BUTTON then
            local roleColor = ROLE_COLORS[ROLE_BUTTON]
            local html = "The " .. ROLE_STRINGS[ROLE_BUTTON] .. " is a <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>jester role</span>"
            html = html .. button_presses_to_win:GetInt() .. button_reset_mode:GetInt() .. button_traitor_activate_only:GetInt() -- Placeholders to make luacheck happy until I actually add the tutorial
            return html
        end
    end)
end

RegisterRole(ROLE)