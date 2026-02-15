local hook = hook
local player = player
local surface = surface
local table = table

local AddHook = hook.Add
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "yorkshireman"
ROLE.name = "Yorkshireman"
ROLE.nameplural = "Yorkshiremen"
ROLE.nameext = "a Yorkshireman"
ROLE.nameshort = "ysm"

ROLE.desc = [[You are {role}!
TODO]]
ROLE.shortdesc = "TODO"

ROLE.team = ROLE_TEAM_INNOCENT

-- TODO: This thing is completely broken
--ROLE.loadout = {"weapon_ttt_guard_dog"}

ROLE.convars =
{
}

ROLE.translations = {
    ["english"] = {
        ["yorkshireman_cooldown_hud"] = "Pie ready in: {time}"
    }
}

------------------
-- ROLE CONVARS --
------------------

local yorkshireman_pie_cooldown = CreateConVar("ttt_yorkshireman_pie_cooldown", "30", FCVAR_REPLICATED, "How long (in seconds) after the Yorkshireman eats pie before another one is ready", 1, 60)

if SERVER then
    AddCSLuaFile()

    -------------------
    -- ROLE FEATURES --
    -------------------

    ROLE.selectionpredicate = function()
        return file.Exists("models/tea/teacup.mdl", "GAME")
    end

    ROLE.onroleassigned = function(ply)
        -- Use a slight delay to make sure nothing else is changing this player's role first
        timer.Simple(0.25, function()
            if not IsPlayer(ply) then return end
            if not ply:IsYorkshireman() then return end

            -- Remove any heavy weapon they have
            local activeWep = ply.GetActiveWeapon and ply:GetActiveWeapon()
            for _, w in ipairs(ply:GetWeapons()) do
                if w.Kind == WEAPON_HEAVY then
                    -- If we are removing the active weapon, switch to something we know they'll have instead
                    if activeWep == w then
                        activeWep = nil
                        timer.Simple(0.25, function()
                            ply:SelectWeapon("weapon_zm_carry")
                        end)
                    end

                    ply:StripWeapon(WEPS.GetClass(w))
                end
            end
            -- And replace it with the shotgun
            ply:Give("weapon_ysm_dbshotgun")

            -- TODO: Spawn tea
        end)
    end

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Yorkshireman_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:ClearProperty("TTTYorkshiremanCooldownStart", v)
        end
    end)
end

if CLIENT then

    ---------
    -- HUD --
    ---------

    local hide_role = GetConVar("ttt_hide_role")

    AddHook("TTTHUDInfoPaint", "Yorkshireman_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not cli:IsActiveYorkshireman() then return end

        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        if not cli.TTTYorkshiremanCooldownStart then return end

        local remaining = cli.TTTYorkshiremanCooldownStart + yorkshireman_pie_cooldown:GetInt() - CurTime()
        local text = LANG.GetParamTranslation("yorkshireman_cooldown_hud", {time = util.SimpleTime(remaining, "%02i:%02i")})
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels there are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "yorkshiremanCooldown")
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Yorkshireman_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_YORKSHIREMAN then
            -- TODO
        end
    end)
end

RegisterRole(ROLE)