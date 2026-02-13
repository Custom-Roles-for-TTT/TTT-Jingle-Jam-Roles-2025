local hook = hook
local math = math
local net = net
local player = player
local table = table
local timer = timer

local AddHook = hook.Add
local CallHook = hook.Call
local MathFloor = math.floor
local MathRandom = math.random
local MathRound = math.Round
local PlayerIterator = player.Iterator
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "sibling"
ROLE.name = "Sibling"
ROLE.nameplural = "Siblings"
ROLE.nameext = "a Sibling"
ROLE.nameshort = "sib"

ROLE.desc = [[You are {role}! You get copies of your
target's shop purchases (and might steal them).

Your target is: {siblingtarget}
]]
ROLE.shortdesc = "Gets a copy of their targets shop purchases (and sometimes steals them)"

ROLE.team = ROLE_TEAM_INNOCENT

ROLE.convars =
{
    {
        cvar = "ttt_sibling_copy_count",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_sibling_steal_chance",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 1
    },
    {
        cvar = "ttt_sibling_share_mode",
        type = ROLE_CONVAR_TYPE_DROPDOWN,
        choices = {"Copy", "Chance to Steal", "Copy w/ Chance to Steal"},
        isNumeric = true,
        numericOffset = 0
    },
    {
        cvar = "ttt_sibling_target_innocents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_sibling_target_detectives",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_sibling_target_traitors",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_sibling_target_independents",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_sibling_target_jesters",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

ROLE.translations = {
    ["english"] = {
        ["sibling_targetid"] = "YOUR SIBLING"
    }
}

SIBLING_SHARE_MODE_COPY = 1
SIBLING_SHARE_MODE_STEAL = 2
SIBLING_SHARE_MODE_COPY_STEAL = 3

local function IsCopyMode(mode)
    return mode == SIBLING_SHARE_MODE_COPY or mode == SIBLING_SHARE_MODE_COPY_STEAL
end

local function IsStealMode(mode)
    return mode == SIBLING_SHARE_MODE_STEAL or mode == SIBLING_SHARE_MODE_COPY_STEAL
end

------------------
-- ROLE CONVARS --
------------------

local sibling_share_mode = CreateConVar("ttt_sibling_share_mode", "3", FCVAR_REPLICATED, "How to handle the sibling's \"share\" logic. 1 - Copy the purchased item. 2 - Chance to steal. 3 - Copy the purchased item with a chance to steal", 1, 3)
local sibling_copy_count = CreateConVar("ttt_sibling_copy_count", "1", FCVAR_REPLICATED, "How many times the sibling should copy their target's shop purchases. Set to \"0\" to copy all purchases. Only used when \"ttt_sibling_share_mode\" is set to a mode that copies", 0, 25)
local sibling_steal_chance = CreateConVar("ttt_sibling_steal_chance", "0.5", FCVAR_REPLICATED, "The chance that a sibling will steal their target's shop purchase instead of copying (e.g. 0.5 = 50% chance to steal). Only used when \"ttt_sibling_share_mode\" is set to a mode that steals", 0, 1)
local sibling_target_innocents = CreateConVar("ttt_sibling_target_innocents", "1", FCVAR_REPLICATED, "Whether the sibling's target can be an innocent role (not including detectives)", 0, 1)
local sibling_target_detectives = CreateConVar("ttt_sibling_target_detectives", "1", FCVAR_REPLICATED, "Whether the sibling's target can be a detective role", 0, 1)
local sibling_target_traitors = CreateConVar("ttt_sibling_target_traitors", "1", FCVAR_REPLICATED, "Whether the sibling's target can be a traitor role", 0, 1)
local sibling_target_independents = CreateConVar("ttt_sibling_target_independents", "1", FCVAR_REPLICATED, "Whether the sibling's target can be an independent role", 0, 1)
local sibling_target_jesters = CreateConVar("ttt_sibling_target_jesters", "1", FCVAR_REPLICATED, "Whether the sibling's target can be a jester role", 0, 1)
local sibling_target_monsters = CreateConVar("ttt_sibling_target_monsters", "1", FCVAR_REPLICATED, "Whether the sibling's target can be a monster role", 0, 1)

if SERVER then
    AddCSLuaFile()

    -------------------
    -- ROLE FEATURES --
    -------------------

    local function AssignTarget(ply)
        if not IsPlayer(ply) then return end
        if not ply:IsActiveSibling() then return end

        local targets = {}
        for _, p in PlayerIterator() do
            if ply == p then continue end
            if not IsPlayer(p) then continue end
            if not p:Alive() or p:IsSpec() then continue end
            if not p:CanUseShop() then continue end

            local role = p:GetRole()
            if INNOCENT_ROLES[role] then
                -- All detectives are innocent but not all innocents are detective
                if DETECTIVE_ROLES[role] then
                    if not sibling_target_detectives:GetBool() then continue end
                    TableInsert(targets, p)
                    continue
                end

                if not sibling_target_innocents:GetBool() then continue end
                TableInsert(targets, p)
            elseif TRAITOR_ROLES[role] then
                if not sibling_target_traitors:GetBool() then continue end
                TableInsert(targets, p)
            elseif INDEPENDENT_ROLES[role] then
                if not sibling_target_independents:GetBool() then continue end
                TableInsert(targets, p)
            elseif JESTER_ROLES[role] then
                if not sibling_target_jesters:GetBool() then continue end
                TableInsert(targets, p)
            elseif MONSTER_ROLES[role] then
                if not sibling_target_monsters:GetBool() then continue end
                TableInsert(targets, p)
            end
        end

        -- If we have no targets then this player can't be a sibling
        if #targets == 0 then
            ply:SetRole(ROLE_INNOCENT)
            return
        end

        local target = Entity(1)-- targets[MathRandom(#targets)]
        ply:SetProperty("TTTSiblingTarget", target:SteamID64(), ply)
        ply.TTTSiblingCopyCount = 0
        ply:QueueMessage(MSG_PRINTBOTH, target:Nick() .. " is your " .. ROLE_STRINGS[ROLE_SIBLING] .. "!")
    end

    local function CallShopHooks(isequip, id, ply)
        CallHook("TTTOrderedEquipment", GAMEMODE, ply, id, isequip, true)
        ply:AddBought(id)

        net.Start("TTT_BoughtItem")
        -- Not a boolean so we can't write it directly
        if isequip then
            net.WriteBit(true)
        else
            net.WriteBit(false)
        end
        if isequip then
            local bits = 16
            -- Only use 32 bits if the number of equipment items we have requires it
            if EQUIP_MAX >= 2^bits then
                bits = 32
            end

            net.WriteUInt(id, bits)
        else
            net.WriteString(id)
        end
        net.Send(ply)
    end

    ROLE.onroleassigned = function(ply)
        -- Use a slight delay to make sure nothing else is changing this player's role first
        timer.Simple(0.25, function()
            if not IsPlayer(ply) then return end
            AssignTarget(ply)
        end)
    end

    AddHook("TTTCanOrderEquipment", "Sibling_TTTCanOrderEquipment", function(ply, item, is_item)
        local share_mode = sibling_share_mode:GetInt()
        local copy_count = sibling_copy_count:GetInt()
        local steal_chance = sibling_steal_chance:GetFloat()
        local is_copy_mode = IsCopyMode(share_mode)
        local is_steal_mode = IsStealMode(share_mode)
        local stolen = false
        for _, p in PlayerIterator() do
            if not IsPlayer(p) then return end
            if not p:IsActiveSibling() then continue end
            if p:IsRoleAbilityDisabled() then continue end

            local target_sid64 = p.TTTSiblingTarget
            if target_sid64 ~= ply:SteamID64() then continue end

            -- Don't copy too many times
            if is_copy_mode and copy_count > 0 and p.TTTSiblingCopyCount >= copy_count then continue end

            -- Check if this should be stolen
            if is_steal_mode and not stolen and steal_chance > 0 and MathRandom() < steal_chance then
                stolen = true
            end

            -- If we're not copying and this wasn't stolen then don't actually give the sibling the item
            if not is_copy_mode and not stolen then continue end

            -- Give the sibling a copy of the item that was bought, if they can hold it
            if is_item then
                item = MathFloor(item)
                if p:HasEquipmentItem(item) then continue end
                p:GiveEquipmentItem(item)
            else
                local swep_table = weapons.GetStored(item)
                if not swep_table or not p:CanCarryWeapon(swep_table) then continue end

                local weap = p:Give(item)
                if weap and weap.WasBought then
                    weap:WasBought(p)
                end
            end

            if is_copy_mode then
                p.TTTSiblingCopyCount = p.TTTSiblingCopyCount + 1
            end
            CallShopHooks(is_item, item, p)
        end

        if stolen then
            ply:QueueMessage(MSG_PRINTBOTH, "Mum said you have to share!")
            return false
        end
    end)

    -------------
    -- CLEANUP --
    -------------

    AddHook("TTTPrepareRound", "Sibling_TTTPrepareRound", function()
        for _, v in PlayerIterator() do
            v.TTTSiblingCopyCount = nil
            v:ClearProperty("TTTSiblingTarget", v)
        end
    end)
end

if CLIENT then
    ---------------
    -- TARGET ID --
    ---------------

    AddHook("TTTTargetIDPlayerText", "Sibling_TTTTargetIDPlayerText", function(ent, cli, text, col, secondary_text)
        if cli:IsSibling() and IsPlayer(ent) and ent:SteamID64() == cli.TTTSiblingTarget and not cli:IsRoleAbilityDisabled() then
            -- Don't overwrite text
            if text then
                -- Don't overwrite secondary text either
                if secondary_text then return end
                return text, col, LANG.GetTranslation("sibling_targetid"), ROLE_COLORS_RADAR[ROLE_SIBLING]
            else
                return LANG.GetTranslation("sibling_targetid"), ROLE_COLORS_RADAR[ROLE_SIBLING]
            end
        end
    end)

    ROLE.istargetidoverridden = function(ply, target, showJester)
        if not ply:IsSibling() then return end
        if not IsPlayer(target) then return end
        if ply:IsRoleAbilityDisabled() then return end

        ------ icon , ring , text
        return false, false, target:SteamID64() == ply.TTTSiblingTarget
    end

    ----------------
    -- SCOREBOARD --
    ----------------

    AddHook("TTTScoreboardPlayerName", "Sibling_TTTScoreboardPlayerName", function(ply, cli, text)
        if cli:IsSibling() and ply:SteamID64() == cli.TTTSiblingTarget and not cli:IsRoleAbilityDisabled() then
            local newText = " (" .. LANG.GetTranslation("sibling_targetid") .. ")"
            return ply:Nick() .. newText
        end
    end)

    ROLE.isscoreboardinfooverridden = function(ply, target)
        if not ply:IsSibling() then return end
        if not IsPlayer(target) then return end
        if ply:IsRoleAbilityDisabled() then return end

        -- Shared logic
        local show = target:SteamID64() == ply.TTTSiblingTarget

        ------ name, role
        return show, false
    end

    ----------------
    -- ROLE POPUP --
    ----------------

    AddHook("TTTRolePopupParams", "Sibling_TTTRolePopupParams", function(cli)
        if cli:IsSibling() then
            local target = player.GetBySteamID64(cli.TTTSiblingTarget)
            local targetNick = "No one"
            if IsPlayer(target) then
                targetNick = target:Nick()
            end
            return { siblingtarget = targetNick }
        end
    end)

    --------------
    -- TUTORIAL --
    --------------

    AddHook("TTTTutorialRoleText", "Sibling_TTTTutorialRoleText", function(role, titleLabel)
        if role == ROLE_SIBLING then
            local T = LANG.GetTranslation
            local roleColor = ROLE_COLORS[ROLE_INNOCENT]
            local html = "The " .. ROLE_STRINGS[ROLE_SIBLING] .. " is a member of the <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>innocent team</span> who has a target assigned to them when the round starts."

            local target_innocents = sibling_target_innocents:GetBool()
            local target_detectives = sibling_target_detectives:GetBool()
            local target_traitors = sibling_target_traitors:GetBool()
            local target_independents = sibling_target_independents:GetBool()
            local target_jesters = sibling_target_jesters:GetBool()
            local target_monsters = sibling_target_monsters:GetBool()
            html = html .. "<span style='display: block; margin-top: 10px;'>Their target can be any role that has a shop and is a member of <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>"
            if target_innocents and target_detectives and target_traitors and target_independents and target_jesters and target_monsters then
                html = html .. "any team</span>.</span>"
            else
                html = html .. "the following</span>:<ul>"
                if target_innocents then
                    html = html .. "<li>" .. T("innocents") .. "</li>"
                end
                if target_detectives then
                    html = html .. "<li>" .. T("detectives") .. "</li>"
                end
                if target_traitors then
                    html = html .. "<li>" .. T("traitors") .. "</li>"
                end
                if target_independents then
                    html = html .. "<li>" .. T("independents") .. "</li>"
                end
                if target_jesters then
                    html = html .. "<li>" .. T("jesters") .. "</li>"
                end
                if target_monsters then
                    html = html .. "<li>" .. T("monsters") .. "</li>"
                end
                html = html .. "</ul></span>"
            end

            local share_mode = sibling_share_mode:GetInt()
            local steal_chance = sibling_steal_chance:GetFloat()
            local is_copy_mode = IsCopyMode(share_mode)
            local is_steal_mode = IsStealMode(share_mode) and steal_chance > 0

            local copy_count = sibling_copy_count:GetInt()
            html = html .. "<span style='display: block; margin-top: 10px;'>When their target buys something from the shop"

            if is_copy_mode then
                if copy_count > 0 then
                    html = html .. " the first "
                    if copy_count == 1 then
                        html = html .. "time"
                    else
                        html = html .. copy_count .. " times"
                    end
                end
                html = html .. ", the " .. ROLE_STRINGS[ROLE_SIBLING] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>also gets a copy</span>"

                if is_steal_mode then
                    html = html .. ".</span>"
                    html = html .. "<span style='display: block; margin-top: 10px;'>There is also"
                end
            elseif is_steal_mode then
                html = html .. ", there is"
            end

            if is_steal_mode then
                local pct = MathRound(steal_chance * 100) .. "%"
                html = html .. " a " .. pct .. " chance that the " .. ROLE_STRINGS[ROLE_SIBLING] .. " <span style='color: rgb(" .. roleColor.r .. ", " .. roleColor.g .. ", " .. roleColor.b .. ")'>will steal</span> their target's item, preventing them from getting it"
            end

            html = html .. ".</span>"

            return html
        end
    end)
end

RegisterRole(ROLE)