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

ROLE.loadout = {"weapon_ttt_guard_dog"}

ROLE.convars =
{
}

ROLE.translations = {
    ["english"] = {
    }
}

if SERVER then
    AddCSLuaFile()

    -------------------
    -- ROLE FEATURES --
    -------------------

    ROLE.selectionpredicate = function()
        return file.Exists("models/tea/teacup.mdl", "GAME")
    end

    ROLE.onroleassigned = function(ply)
        if not ply:IsYorkshireman() then return end

        -- TODO: Spawn tea
    end
end

if CLIENT then
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