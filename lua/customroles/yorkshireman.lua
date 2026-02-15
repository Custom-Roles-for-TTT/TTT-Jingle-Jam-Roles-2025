local ents = ents
local hook = hook
local math = math
local player = player
local surface = surface
local string = string
local table = table

local AddHook = hook.Add
local CreateEnt = ents.Create
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local MathMin = math.min
local MathRandom = math.random
local MathRand = math.Rand

local ROLE = {}

ROLE.nameraw = "yorkshireman"
ROLE.name = "Yorkshireman"
ROLE.nameplural = "Yorkshiremen"
ROLE.nameext = "a Yorkshireman"
ROLE.nameshort = "ysm"

ROLE.desc = [[You are {role}!
TODO]]
ROLE.shortdesc = "TODO"

ROLE.team = ROLE_TEAM_INDEPENDENT
ROLE.haspassivewin = true
-- TODO: This thing is completely broken
--ROLE.loadout = {"weapon_ttt_guard_dog"}

ROLE.convars =
{
}

ROLE.translations = {
    ["english"] = {
        ["yorkshireman_collect_hud"] = "Tea drank: {collected}/{total}",
        ["yorkshireman_cooldown_hud"] = "Pie ready in: {time}",
        ["ysm_tea"] = "Cup of Tea",
        ["ysm_tea_hint"] = "Press {usekey} to drink"
    }
}

------------------
-- ROLE CONVARS --
------------------

local yorkshireman_pie_cooldown = CreateConVar("ttt_yorkshireman_pie_cooldown", "30", FCVAR_REPLICATED, "How long (in seconds) after the Yorkshireman eats pie before another one is ready", 1, 60)
local yorkshireman_tea_spawn = CreateConVar("ttt_yorkshireman_tea_spawn", "15", FCVAR_REPLICATED, "How many cups of tea should be spawned around the map", 1, 60)
local yorkshireman_tea_collect = CreateConVar("ttt_yorkshireman_tea_collect", "10", FCVAR_REPLICATED, "How many cups of tea should the Yorkshireman needs to collect to win", 1, 60)

local function GetTeaLimits()
    local spawn = yorkshireman_tea_spawn:GetInt()
    local total = MathMin(spawn, yorkshireman_tea_collect:GetInt())

    return spawn, total
end

if SERVER then
    local plymeta = FindMetaTable("Player")
    if not plymeta then return end

    AddCSLuaFile()

    util.AddNetworkString("TTT_YorkshiremanWin")

    -------------------
    -- ROLE FEATURES --
    -------------------

    function plymeta:YorkshiremanCollect(ent)
        if not IsValid(ent) then return end
        if not self:IsYorkshireman() then return end
        if not self:Alive() or self:IsSpec() then return end

        local collected = (self.TTTYorkshiremanCollected or 0) + 1
        self:SetProperty("TTTYorkshiremanCollected", collected)

        local _, total = GetTeaLimits()
        if collected >= total then
            net.Start("TTT_YorkshiremanWin")
            net.Broadcast()
        end

        -- TODO: Show message in chat
        -- TODO: Play drinking sound

        SafeRemoveEntity(ent)
    end

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

            -- Use weapon spawns as the spawn locations for tea
            local spawns = {}
            for _, e in ents.Iterator() do
                local entity_class = e:GetClass()
                if (string.StartsWith(entity_class, "weapon_") or string.StartsWith(entity_class, "item_")) and not IsValid(e:GetParent()) then
                    TableInsert(spawns, e)
                end
            end

            for i=1, yorkshireman_tea_spawn:GetInt() do
                local spawn = spawns[MathRandom(#spawns)]
                local pos = spawn:GetPos()
                local tea = CreateEnt("ttt_ysm_tea")
                tea:SetPos(pos + Vector(MathRand(2, 5), 5, MathRand(2, 5)))
                tea:Spawn()
                tea:Activate()
            end
        end)
    end

    AddHook("TTTPlayerAliveThink", "Yorkshireman_TTTPlayerAliveThink", function(ply)
        if not IsValid(ply) then return end
        if not ply.TTTYorkshiremanCooldownEnd then return end

        if CurTime() >= ply.TTTYorkshiremanCooldownEnd then
            ply:ClearProperty("TTTYorkshiremanCooldownEnd", ply)
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Yorkshireman_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v:ClearProperty("TTTYorkshiremanCollected", v)
            v:ClearProperty("TTTYorkshiremanCooldownEnd", v)
        end
    end)
end

if CLIENT then
    ----------------
    -- WIN CHECKS --
    ----------------

    local ysm_wins = false
    net.Receive("TTT_YorkshiremanWin", function()
        ysm_wins = true
    end)

    AddHook("TTTScoringSecondaryWins", "Yorkshireman_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if not ysm_wins then return end
        TableInsert(secondary_wins, ROLE_YORKSHIREMAN)
    end)

    ---------
    -- HUD --
    ---------

    local hide_role = GetConVar("ttt_hide_role")

    AddHook("TTTHUDInfoPaint", "Yorkshireman_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
        if hide_role:GetBool() then return end
        if not cli:IsYorkshireman() then return end

        surface.SetFont("TabLarge")

        local collected = cli.TTTYorkshiremanCollected or 0
        local _, total = GetTeaLimits()

        if collected >= total then
            surface.SetTextColor(0, 150, 0, 230)
        else
            surface.SetTextColor(255, 255, 255, 230)
        end

        local text = LANG.GetParamTranslation("yorkshireman_collect_hud", {total = total, collected = collected})
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels there are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        TableInsert(active_labels, "yorkshiremanCooldown")

        if not cli:Alive() or cli:IsSpec() then return end
        if not cli.TTTYorkshiremanCooldownEnd then return end

        local remaining = cli.TTTYorkshiremanCooldownEnd - CurTime()
        text = LANG.GetParamTranslation("yorkshireman_cooldown_hud", {time = util.SimpleTime(remaining, "%02i:%02i")})
        _, h = surface.GetTextSize(text)

        -- Move this up again for the label we just rendered
        label_top = label_top + 20

        surface.SetTextColor(255, 255, 255, 230)
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

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Yorkshireman_TTTPrepareRound", function()
        ysm_wins = false
    end)
end

RegisterRole(ROLE)