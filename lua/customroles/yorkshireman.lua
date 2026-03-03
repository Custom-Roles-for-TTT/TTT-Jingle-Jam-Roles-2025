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

ROLE.desc = [[You are {role}! You want to collect
Cups of Tea that spawn around the map
while mostly minding your own business.

Don't let others get in your way, and eat
some of your Pie to heal if things go badly.]]
ROLE.shortdesc = "They crave tea and just want to mind their own business and meander around eating pie and keeping their tea craving at bay."

ROLE.team = ROLE_TEAM_INDEPENDENT
ROLE.haspassivewin = true

ROLE.convars =
{
    {
        cvar = "ttt_yorkshireman_tea_spawn",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_tea_collect",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_pie_cooldown",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_pie_heal",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_shotgun_damage",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_dog_health",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_yorkshireman_dog_damage",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    }
}

ROLE.translations = {
    ["english"] = {
        ["yorkshireman_collect_hud"] = "Tea drank: {collected}/{total}",
        ["yorkshireman_cooldown_hud"] = "Pie ready in: {time}",
        ["ysm_dog_name"] = "Guard Dog",
        ["ysm_dog_name_health"] = "Guard Dog ({current}/{max})",
        ["ysm_tea"] = "Cup of Tea",
        ["ysm_tea_hint"] = "Press {usekey} to drink",
        ["ysm_guarddog_help_pri"] = "Press {primaryfire} to set target, {secondaryfire} to clear",
        ["ysm_guarddog_help_sec"] = "Press {reload} to unstuck",
        ["score_ysm_collected"] = "Collected"
    }
}

------------------
-- ROLE CONVARS --
------------------

local yorkshireman_tea_spawn = CreateConVar("ttt_yorkshireman_tea_spawn", "20", FCVAR_REPLICATED, "How many cups of tea should be spawned around the map", 1, 60)
local yorkshireman_tea_collect = CreateConVar("ttt_yorkshireman_tea_collect", "15", FCVAR_REPLICATED, "How many cups of tea should the Yorkshireman needs to collect to win", 1, 60)

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

        self:QueueMessage(MSG_PRINTCENTER, "You've had a lovely cup of tea =)", nil, "ysmTea")
        self:EmitSound("yorkshireman/drink.mp3", 100, 100, 1, CHAN_ITEM)

        SafeRemoveEntity(ent)
    end

    ROLE.selectionpredicate = function()
        return navmesh.IsLoaded() and navmesh.GetNavAreaCount() > 0 and file.Exists("models/tea/teacup.mdl", "GAME")
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

            -- Fall back to using player locations if we can't find anything else
            if #spawns == 0 then
                for _, p in PlayerIterator() do
                    TableInsert(spawns, p)
                end
            end

            for i=1, yorkshireman_tea_spawn:GetInt() do
                local spawn = spawns[MathRandom(#spawns)]
                local pos = spawn:GetPos()
                local tea = CreateEnt("ttt_yorkshireman_tea")
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

    --  Make the dog automatically attack anyone that damages the Yorkshireman if they don't already have an explicit target
    AddHook("PostEntityTakeDamage", "Yorkshireman_PostEntityTakeDamage", function(ent, dmginfo, wasDamageTaken)
        if not wasDamageTaken then return end
        if not IsPlayer(ent) then return end
        if not ent:IsActiveYorkshireman() then return end

        -- Ignore these damage types and assume the rest are purposeful from a direct weapon
        if dmginfo:IsFallDamage() or dmginfo:IsExplosionDamage() then return end

        local dog = ent.TTTYorkshiremanDog
        if not IsValid(dog) then return end
        if dog:HasEnemy() then return end

        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end
        if not att:Alive() or att:IsSpec() then return end

        dog:SetEnemy(att)
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Yorkshireman_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            SafeRemoveEntity(v.TTTYorkshiremanDog)
            v.TTTYorkshiremanDog = nil
            v:ClearProperty("TTTYorkshiremanCollected")
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

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTScoringSummaryRender", "Yorkshireman_TTTScoringSummaryRender", function(ply, roleFileName, groupingRole, roleColor, name, startingRole, finalRole)
        if not IsPlayer(ply) then return end
        if not ply:IsYorkshireman() then return end

        local collected = ply.TTTYorkshiremanCollected or 0
        local _, total = GetTeaLimits()

        return roleFileName, groupingRole, roleColor, name, collected .. "/" .. total, LANG.GetTranslation("score_ysm_collected")
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
            surface.SetTextColor(0, 200, 0, 230)
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
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_YORKSHIREMAN] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to collect Tea Cups around the map and keep their tea craving at bay."

            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_YORKSHIREMAN] .. " needs to <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>collect " .. yorkshireman_tea_collect:GetInt() .. " Cup(s) of Tea</span> to finally be able to relax and share the win with whoever is left.</span>"

            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_YORKSHIREMAN] .. "'s trusty <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>Guard Dog</span> will stay by their side and defend them from any threats.</span>"

            html = html .. "<span style='display: block; margin-top: 10px;'>When they feel weak, they can <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>eat some Pie</span> to regain health (and heal their Guard Dog).</span>"

            return html
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