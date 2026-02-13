local ents = ents
local hook = hook
local player = player
local table = table
local timer = timer
local weapons = weapons

local AddHook = hook.Add
local CreateEntity = ents.Create
local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert
local WeaponsGetList = weapons.GetList

local ROLE = {}

ROLE.nameraw = "pinata"
ROLE.name = "Pinata"
ROLE.nameplural = "Piñatas"
ROLE.nameext = "a Piñata"
ROLE.nameshort = "pin"

ROLE.desc = [[You are {role}! All you want to do
is mind your own business, but unfortunately
someone figured out you drop valuable shop
weapons periodically after taking damage.

Keep away from aggressive players or use
the weapons that drop to defend yourself,
your strategy is up to you.]]
ROLE.shortdesc = "Drops weapons periodically when taking damage. Can only damage players that hurt them first."

ROLE.team = ROLE_TEAM_INDEPENDENT
ROLE.startinghealth = 150
ROLE.maxhealth = 150

ROLE.convars =
{
    {
        cvar = "ttt_pinata_damage_interval",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_pinata_announce",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations =
{
    ["english"] =
    {
        ["pinata_targetid"] = "DAMAGEABLE",
        ["win_pinata"] = "The {role} has survived unbroken!",
        ["ev_win_pinata"] = "The {role} has survived unbroken!"
    }
}

------------------
-- ROLE CONVARS --
------------------

local pinata_damage_interval = CreateConVar("ttt_pinata_damage_interval", "20", FCVAR_REPLICATED, "How much damage the piñata must take between weapon drops", 1, 100)
local pinata_announce = CreateConVar("ttt_pinata_announce", "1", FCVAR_REPLICATED, "Whether to announce to everyone that there is a piñata in the round", 0, 1)

if SERVER then
    AddCSLuaFile()

    -------------------
    -- ROLE FEATURES --
    -------------------

    ROLE.onroleassigned = function(ply)
        -- Use a slight delay to make sure nothing else is changing this player's role first
        timer.Simple(0.25, function()
            if not IsPlayer(ply) then return end
            ply.TTTPinataDamageTaken = 0
        end)
    end

    local function DropWeapon(wep, source_pos)
        local pos = source_pos + Vector(0, 0, 25)
        local ent = CreateEntity(wep)
        ent:SetPos(pos)
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if phys:IsValid() then phys:ApplyForceCenter(Vector(math.Rand(-100, 100), math.Rand(-100, 100), 300) * phys:GetMass()) end
    end

    AddHook("PostEntityTakeDamage", "Pinata_PostEntityTakeDamage", function(ent, dmginfo, taken)
        if not taken then return end
        if not IsPlayer(ent) or not ent:IsActivePinata() then return end
        if ent:IsRoleAbilityDisabled() then return end

        local dmg = dmginfo:GetDamage()
        ent.TTTPinataDamageTaken = ent.TTTPinataDamageTaken + dmg

        local damage_interval = pinata_damage_interval:GetInt()
        while ent.TTTPinataDamageTaken >= damage_interval do
            ent.TTTPinataDamageTaken  = ent.TTTPinataDamageTaken - damage_interval

            -- Drop a weapon
            local weps = WeaponsGetList()
            local wep = nil
            for _, v in RandomPairs(weps) do
                if v and not v.AutoSpawnable and v.CanBuy and #v.CanBuy > 0 and v.AllowDrop then
                    wep = WEPS.GetClass(v)
                    break
                end
            end

            -- Sanity check
            if wep then
                local pos = ent:GetPos()
                local ang = ent:GetAngles()
                -- Drop behind the player
                local new_pos = pos - (ang:Forward() * 100)
                DropWeapon(wep, new_pos)
            end
        end

        -- Keep track of which player damaged which piñatas
        local att = dmginfo:GetAttacker()
        if IsPlayer(att) then
            local pinatas_damaged = att.TTTPinatasDamaged or {}
            TableInsert(pinatas_damaged, ent:SteamID64())
            att:SetProperty("TTTPinatasDamaged", pinatas_damaged, ent)
        end
    end)

    -- Block damage from a piñata against a player unless they've damaged that piñata first
    AddHook("EntityTakeDamage", "Pinata_EntityTakeDamage", function(ent, dmginfo)
        if not IsPlayer(ent) then return end

        local att = dmginfo:GetAttacker()
        if not IsPlayer(att) then return end
        if not att:IsActivePinata() then return end

        if not ent.TTTPinatasDamaged or not TableHasValue(ent.TTTPinatasDamaged, att:SteamID64()) then
            dmginfo:ScaleDamage(0)
        end
    end)

    ------------------
    -- ANNOUNCEMENT --
    ------------------

    AddHook("TTTBeginRound", "Pinata_Announce_TTTBeginRound", function()
        if not pinata_announce:GetBool() then return end

        timer.Simple(1.5, function()
            local hasPinata = false
            for _, v in PlayerIterator() do
                if v:IsPinata() then
                    hasPinata = true
                end
            end

            if hasPinata then
                for _, v in PlayerIterator() do
                    if not v:IsPinata() then
                        v:QueueMessage(MSG_PRINTBOTH, "There is " .. ROLE_STRINGS_EXT[ROLE_PINATA] .. "!")
                    end
                end
            end
        end)
    end)

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("Initialize", "Pinata_Initialize", function()
        WIN_PINATA = GenerateNewWinID(ROLE_PINATA)
    end)

    AddHook("TTTCheckForWin", "Pinata_TTTCheckForWin", function()
        local pinata_alive = false
        local other_alive = false
        for _, v in PlayerIterator() do
            if v:IsActive() then
                if v:IsPinata() then
                    pinata_alive = true
                elseif not v:ShouldActLikeJester() and not ROLE_HAS_PASSIVE_WIN[v:GetRole()] then
                    other_alive = true
                end
            end
        end

        if pinata_alive and not other_alive then
            return WIN_PINATA
        end
    end)

    AddHook("TTTPrintResultMessage", "Pinata_TTTPrintResultMessage", function(type)
        if type == WIN_PINATA then
            LANG.Msg("win_pinata", { role = ROLE_STRINGS[ROLE_PINATA] })
            ServerLog("Result: " .. ROLE_STRINGS[ROLE_PINATA] .. " wins.\n")
            return true
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Pinata_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTPinataDamageTaken = nil
            v:ClearProperty("TTTPinatasDamaged")
        end
    end)
end

if CLIENT then
    ---------------
    -- TARGET ID --
    ---------------

    AddHook("TTTTargetIDPlayerText", "Pinata_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if cli:IsPinata() and IsPlayer(ent) and ent.TTTPinatasDamaged and TableHasValue(ent.TTTPinatasDamaged, cli:SteamID64()) and not cli:IsRoleAbilityDisabled() then
            -- Don't overwrite text
            if text then
                -- Don't overwrite secondary text either
                if secondary_text then return end
                return text, col, LANG.GetTranslation("pinata_targetid"), ROLE_COLORS_RADAR[ROLE_TRAITOR]
            else
                return LANG.GetTranslation("pinata_targetid"), ROLE_COLORS_RADAR[ROLE_TRAITOR]
            end
        end
    end)

    ROLE.istargetidoverridden = function(ply, target, showJester)
        if not ply:IsPinata() then return end
        if not IsPlayer(target) then return end
        if ply:IsRoleAbilityDisabled() then return end

        ------ icon , ring , text
        return false, false, target.TTTPinatasDamaged and TableHasValue(target.TTTPinatasDamaged, ply:SteamID64())
    end

    ----------------
    -- WIN CHECKS --
    ----------------

    AddHook("TTTSyncWinIDs", "Pinata_TTTSyncWinIDs", function()
        WIN_PINATA = WINS_BY_ROLE[ROLE_PINATA]
    end)

    AddHook("TTTScoringWinTitle", "Pinata_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
        if wintype == WIN_PINATA then
            return { txt = "hilite_win_role_singular", params = { role = utf8.upper(ROLE_STRINGS[ROLE_PINATA]) }, c = ROLE_COLORS[ROLE_PINATA] }
        end
    end)

    AddHook("TTTScoringSecondaryWins", "Pinata_TTTScoringSecondaryWins", function(wintype, secondary_wins)
        if wintype == WIN_PINATA then return end

        for _, p in PlayerIterator() do
            if not p:Alive() or p:IsSpec() then continue end
            if not p:IsPinata() then continue end

            TableInsert(secondary_wins, ROLE_PINATA)
            return
        end
    end)

    ------------
    -- EVENTS --
    ------------

    AddHook("TTTEventFinishText", "Pinata_TTTEventFinishText", function(e)
        if e.win == WIN_PINATA then
            return LANG.GetParamTranslation("ev_win_pinata", { role = string.lower(ROLE_STRINGS[ROLE_PINATA]) })
        end
    end)

    AddHook("TTTEventFinishIconText", "Pinata_TTTEventFinishIconText", function(e, win_string, role_string)
        if e.win == WIN_PINATA then
            return win_string, ROLE_STRINGS[ROLE_PINATA]
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Pinata_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_PINATA then
            local roleColor = GetRoleTeamColor(ROLE_TEAM_INDEPENDENT)
            local html = "The " .. ROLE_STRINGS[ROLE_PINATA] .. " is an <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>independent</span> role whose goal is to survive until the end of the round."

            if pinata_announce:GetBool() then
                html = html .. "<span style='display: block; margin-top: 10px;'>All players <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>are notified</span> when there is " .. ROLE_STRINGS_EXT[ROLE_PINATA] .. " in the round.</span>"
            end

            local damage_interval = pinata_damage_interval:GetInt()
            html = html .. "<span style='display: block; margin-top: 10px;'>Unfortunately for them, they <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>drop a random shop weapon</span> every " .. damage_interval .. " damage they take, which makes them a prime target.</span>"
            html = html .. "<span style='display: block; margin-top: 10px;'>The " .. ROLE_STRINGS[ROLE_PINATA] .. " also cannot deal damage <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>except to players that damage them first</span>.</span>"

            return html
        end
    end)
end

RegisterRole(ROLE)
-- Add the accent back after registering the role
timer.Simple(5, function()
    ROLE_STRINGS[ROLE_PINATA] = "Piñata"
end)