local cvars = cvars
local hook = hook
local math = math
local net = net
local player = player
local timer = timer
local util = util
local table = table

local AddHook = hook.Add
local MathMin = math.min
local MathRandom = math.random
local PlayerIterator = player.Iterator
local TableInsert = table.insert
local TableEmpty = table.Empty

util.AddNetworkString("TTTGamerGachaStart")
util.AddNetworkString("TTTGamerMilkFart")
util.AddNetworkString("TTTGamerRecoilAdjust")
util.AddNetworkString("TTTGamerRecoilReset")

------------------
-- ROLE CONVARS --
------------------

local gamer_spaghetti_amount = CreateConVar("ttt_gamer_spaghetti_amount", "5", FCVAR_REPLICATED, "The amount of health a player should regain per interval after they eat spaghetti", 1, 25)
local gamer_spaghetti_interval = CreateConVar("ttt_gamer_spaghetti_interval", "5", FCVAR_REPLICATED, "How often a player who eats spaghetti should regain health", 1, 60)
local gamer_milk_fall_damage_reduction = CreateConVar("ttt_gamer_milk_fall_damage_reduction", "1", FCVAR_REPLICATED, "The percentage of a player's fall damage to reduce after they drink choccy milk (e.g. 1 = 100% = 0 fall damage)", 0.1, 1)
local gamer_milk_melee_damage_bonus = CreateConVar("ttt_gamer_milk_melee_damage_bonus", "0.25", FCVAR_REPLICATED, "The percentage to add to a player's melee damage after they drink choccy milk (e.g. 0.25 = 25% = 125% total melee damage)", 0.1, 1)
local gamer_milk_fart_interval_min = CreateConVar("ttt_gamer_milk_fart_interval_min", "15", FCVAR_REPLICATED, "The minimum amount of time (in seconds) between milk farts", 1, 30)
local gamer_milk_fart_interval_max = CreateConVar("ttt_gamer_milk_fart_interval_max", "45", FCVAR_REPLICATED, "The maximum amount of time (in seconds) between milk farts", 1, 60)

local gamer_gacha_only_mode = GetConVar("ttt_gamer_gacha_only_mode")

----------------
-- ROLE LOGIC --
----------------

local function Gamer_TTTOrderedEquipment(ply, id, isequip)
    if not isequip then return end

    if isequip == EQUIP_GAMER_DORITOS then
        -- If the player doesn't have the gacha roller already, give it to them
        local gacha
        if ply:HasWeapon("weapon_gmr_gacha") then
            gacha = ply:GetWeapon("weapon_gmr_gacha")
        else
            gacha = ply:Give("weapon_gmr_gacha")
        end

        -- And give it some ammo
        if gamer_gacha_only_mode:GetBool() then
            ply:AddCredits(2)
        else
            if IsValid(gacha) then
                gacha:SetClip1(math.max(0, gacha:Clip1()) + 2)
            end
        end
        ply:EmitSound("gamer/doritos.mp3", 100, 100, 1, CHAN_ITEM)
    elseif isequip == EQUIP_GAMER_MTDEW then
        if not ply:IsRoleAbilityDisabled() then
            if ply.SetMaxJumpLevel then
                ply:SetMaxJumpLevel(ply:GetMaxJumpLevel() + 1)
            else
                ply:SetJumpPower(ply:GetJumpPower() + GAMER.Config.JumpPower)
            end
        end
        ply:EmitSound("gamer/mtdew.mp3", 100, 100, 1, CHAN_ITEM)
    elseif isequip == EQUIP_GAMER_CHEETOS then
        if not ply:IsRoleAbilityDisabled() then
            -- Heal the player to max
            local hp = ply:Health()
            local max = ply:GetMaxHealth()
            if hp < max then
                ply:SetHealth(max)
            end
        end

        -- If the player doesn't have the cheeto fingers already, give it to them
        local fingers
        if ply:HasWeapon("weapon_gmr_cheeto_fingers") then
            fingers = ply:GetWeapon("weapon_gmr_cheeto_fingers")
        else
            fingers = ply:Give("weapon_gmr_cheeto_fingers")
        end

        -- And give it some ammo
        if IsValid(fingers) then
            fingers:SetClip1(math.max(0, fingers:Clip1()) + 1)
        end
        ply:EmitSound("gamer/cheetos.mp3", 100, 100, 1, CHAN_ITEM)
    elseif isequip == EQUIP_GAMER_SPAGHETTI then
        ply:EmitSound("gamer/spaghetti.mp3", 100, 100, 1, CHAN_ITEM)
    elseif isequip == EQUIP_GAMER_MILK then
        ply:EmitSound("gamer/milk.mp3", 100, 100, 1, CHAN_ITEM)
    end
end

local function Gamer_TTTPlayerAliveThink(ply)
    if not IsPlayer(ply) then return end

    local hasSpaghetti = ply:HasEquipmentItem(EQUIP_GAMER_SPAGHETTI)
    local hasMilk = ply:HasEquipmentItem(EQUIP_GAMER_MILK)
    if not hasSpaghetti and not hasMilk then return end
    if not ply:IsActiveGamer() or ply:IsRoleAbilityDisabled() then return end

    if hasSpaghetti then
        local lastHeal = ply.TTTGamerSpaghettiHealTime or 0
        local curTime = CurTime()
        if lastHeal + gamer_spaghetti_interval:GetInt() > curTime then return end

        ply.TTTGamerSpaghettiHealTime = curTime

        local hp = ply:Health()
        local newHp = MathMin(ply:GetMaxHealth(), hp + gamer_spaghetti_amount:GetInt())
        if hp >= newHp then return end

        ply:SetHealth(newHp)
    end

    if hasMilk then
        local nextMilkFart = ply.TTTGamerNextMilkFart or 0
        local curTime = CurTime()
        if nextMilkFart <= curTime then
            local min = gamer_milk_fart_interval_min:GetInt()
            local max = gamer_milk_fart_interval_max:GetInt()
            if max < min then
                max = min
            end
            ply.TTTGamerNextMilkFart = curTime + MathRandom(min, max)

            ply:EmitSound("gamer/fart.mp3", 100, 100, 1, CHAN_ITEM)

            net.Start("TTTGamerMilkFart")
                net.WritePlayer(ply)
            net.Broadcast()
        end
    end
end

local function Gamer_Milk_EntityTakeDamage(ent, dmginfo)
    if not IsPlayer(ent) then return end

    -- Reduce fall damage if the victim has had milk
    if ent:HasEquipmentItem(EQUIP_GAMER_MILK) then
        if not ent:IsActiveGamer() or ent:IsRoleAbilityDisabled() then return end
        if not dmginfo:IsFallDamage() then return end
        dmginfo:ScaleDamage(1 - gamer_milk_fall_damage_reduction:GetFloat())
    end

    local att = dmginfo:GetAttacker()
    -- Boost melee damage if the attacker has had milk
    if IsPlayer(att) and att:HasEquipmentItem(EQUIP_GAMER_MILK) then
        if not att:IsActiveGamer() or att:IsRoleAbilityDisabled() then return end
        if not dmginfo:IsDamageType(DMG_SLASH) and not dmginfo:IsDamageType(DMG_CLUB) then return end
        dmginfo:ScaleDamage(1 + gamer_milk_melee_damage_bonus:GetFloat())
    end
end

AddHook("TTTUpdateRoleState", "Gamer_TTTUpdateRoleState", function()
    local gacha = weapons.GetStored("weapon_gmr_gacha")
    if GetConVar("ttt_gamer_gacha_only_mode"):GetBool() then
        TableInsert(gacha.InLoadoutFor, ROLE_GAMER)
    else
        TableEmpty(gacha.InLoadoutFor)
    end
end)

-- In "Gacha-only" mode, credits are treated as ammunition for the Gacha Roller
-- Initialize it with the same number of credits the player has to start
local function Gamer_PlayerLoadout(ply)
    if not gamer_gacha_only_mode:GetBool() then return end
    timer.Simple(0, function()
        if not IsPlayer(ply) then return end

        local gacha = ply:GetWeapon("weapon_gmr_gacha")
        if not IsValid(gacha) then return end

        gacha:SetClip1(ply:GetCredits())
    end)
end

-- And update it any time the player's credits change
local function Gamer_TTTPlayerCreditsChanged(ply, amt)
    if not gamer_gacha_only_mode:GetBool() then return end

    local gacha = ply:GetWeapon("weapon_gmr_gacha")
    if not IsValid(gacha) then return end

    gacha:SetClip1(ply:GetCredits())
end

-------------
-- CLEANUP --
-------------

local function Cleanup()
    local jumps = cvars.Number("multijump_default_jumps", 1)
    for _, p in PlayerIterator() do
        timer.Remove("TTTGmrGachaPrize_" .. p:SteamID64())
        p.TTTGamerSpaghettiHealTime = nil
        p.TTTGamerHasUniquePrize = nil
        p.TTTGamerNextMilkFart = nil
        p.TTTGamerPrizes = nil

        p:ClearProperty("TTTGamerCheetoMarked")
        if p.SetMaxJumpLevel then
            p:SetMaxJumpLevel(jumps)
        else
            p:SetJumpPower(GAMER.Config.JumpPower)
        end
    end
end

AddHook("TTTPrepareRound", "Gamer_TTTPrepareRound", Cleanup)

------------------
-- REGISTRATION --
------------------

ROLE_REGISTERED_HOOKS[ROLE_GAMER] = {
    ["EntityTakeDamage"] = Gamer_Milk_EntityTakeDamage,
    ["PlayerLoadout"] = Gamer_PlayerLoadout,
    ["TTTEndRound"] = Cleanup,
    ["TTTOrderedEquipment"] = Gamer_TTTOrderedEquipment,
    ["TTTPlayerAliveThink"] = Gamer_TTTPlayerAliveThink,
    ["TTTPlayerCreditsChanged"] = Gamer_TTTPlayerCreditsChanged
}