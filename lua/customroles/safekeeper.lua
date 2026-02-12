local hook = hook

local AddHook = hook.Add

local ROLE = {}

ROLE.nameraw = "safekeeper"
ROLE.name = "Safekeeper"
ROLE.nameplural = "Safekeepers"
ROLE.nameext = "a Safekeeper"
ROLE.nameshort = "sfk"

ROLE.desc = [[You are {role}!
]]
ROLE.shortdesc = ""

ROLE.team = ROLE_TEAM_INDEPENDENT

ROLE.convars =
{
}

ROLE.translations = {
    ["english"] = {
        ["sfk_safe_help_pri"] = "Use {primaryfire} to drop your Safe on the ground",
        ["sfk_safe_name"] = "Safe",
        ["sfk_safe_hint"] = "Press {usekey} to pick up",
        ["sfk_safe_hint_pick"] = "Hold {usekey} to pick open",
        ["safekeeper_picking"] = "PICKING"
    }
}

ROLE.haspassivewin = true

RegisterRole(ROLE)

------------------
-- ROLE CONVARS --
------------------

local safekeeper_pick_time = CreateConVar("ttt_safekeeper_pick_time", "30", FCVAR_REPLICATED, "How long (in seconds) it takes to pick a safe", 1, 60)

if SERVER then
    AddCSLuaFile()

    local safekeeper_warn_pick_complete = CreateConVar("ttt_safekeeper_warn_pick_complete", "1", FCVAR_NONE, "Whether to warn an safe's owner is warned when it is picked", 0, 1)
    local safekeeper_pick_grace_time = CreateConVar("ttt_safekeeper_pick_grace_time", 0.25, FCVAR_NONE, "How long (in seconds) before the pick progress of a safe is reset when a player stops looking at it", 0, 1)

    --------------------
    -- PICK TRACKING --
    --------------------

    AddHook("TTTPlayerAliveThink", "Safekeeper_TTTPlayerAliveThink", function(ply)
        if ply.SafekeeperLastPickTime == nil then return end

        local pickTarget = ply.SafekeeperPickTarget
        if not IsValid(pickTarget) then return end

        local pickStart = ply.SafekeeperPickStart
        if not pickStart or pickStart <= 0 then return end

        local curTime = CurTime()

        -- If it's been too long since the user used the ankh, stop tracking their progress
        if curTime - ply.SafekeeperLastPickTime >= safekeeper_pick_grace_time:GetFloat() then
            ply.SafekeeperLastPickTime = nil
            ply:SetProperty("SafekeeperPickTarget", nil, ply)
            ply:SetProperty("SafekeeperPickStart", 0, ply)
            return
        end

        -- If they haven't used this item long enough then keep waiting
        if curTime - pickStart < safekeeper_pick_time:GetInt() then return end

        local placer = pickTarget:GetPlacer()
        if IsPlayer(placer) and safekeeper_warn_pick_complete:GetBool() then
            placer:QueueMessage(MSG_PRINTBOTH, "Your safe has been picked!")
            -- TODO: Sound?
        end

        pickTarget:Open(ply)
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

        local pickTarget = client.SafekeeperPickTarget
        if not IsValid(pickTarget) then return end

        local pickStart = client.SafekeeperPickStart
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
end