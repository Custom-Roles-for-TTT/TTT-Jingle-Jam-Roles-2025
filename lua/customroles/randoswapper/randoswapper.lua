AddCSLuaFile()

local hook = hook
local ipairs = ipairs
local IsValid = IsValid
local net = net
local player = player
local table = table
local timer = timer
local util = util

local AddHook = hook.Add
local PlayerIterator = player.Iterator

util.AddNetworkString("TTT_RandoswapperSwapped")

-------------
-- CONVARS --
-------------

CreateConVar("ttt_randoswapper_notify_mode", "0", FCVAR_NONE, "The logic to use when notifying players that a randoswapper was killed. Killer is notified unless \"ttt_randoswapper_notify_killer\" is disabled", 0, 4)
CreateConVar("ttt_randoswapper_notify_killer", "1", FCVAR_NONE, "Whether to notify a randoswapper's killer", 0, 1)
CreateConVar("ttt_randoswapper_notify_sound", "0", FCVAR_NONE, "Whether to play a cheering sound when a randoswapper is killed", 0, 1)
CreateConVar("ttt_randoswapper_notify_confetti", "0", FCVAR_NONE, "Whether to throw confetti when a randoswapper is a killed", 0, 1)
CreateConVar("ttt_randoswapper_killer_health", "100", FCVAR_NONE, "The amount of health the randoswapper's killer should set to. Set to \"0\" to kill them", 1, 200)
local randoswapper_respawn_health = CreateConVar("ttt_randoswapper_respawn_health", "100", FCVAR_NONE, "What amount of health to give the randoswapper when they are killed and respawned", 1, 200)
local randoswapper_weapon_mode = CreateConVar("ttt_randoswapper_weapon_mode", "1", FCVAR_NONE, "How to handle weapons when the randoswapper is killed", 0, 2)
local randoswapper_swap_lovers = CreateConVar("ttt_randoswapper_swap_lovers", "1", FCVAR_NONE, "Whether the randoswapper should swap lovers with their attacker or not", 0, 1)

local randoswapper_killer_health = GetConVar("ttt_randoswapper_killer_health")
local randoswapper_max_swaps = GetConVar("ttt_randoswapper_max_swaps")

------------
-- EVENTS --
------------

AddHook("Initialize", "Randoswapper_Initialize", function()
    EVENT_RANDOSWAPPER = GenerateNewEventID(ROLE_RANDOSWAPPER)
end)

-----------------
-- KILL CHECKS --
-----------------

local function RandoswapperKilledNotification(attacker, victim)
    JesterTeamKilledNotification(attacker, victim,
        -- getkillstring
        function(ply)
            local target = "someone"
            if ply:IsTraitorTeam() or attacker:IsDetectiveLike() then
                target = ROLE_STRINGS_EXT[attacker:GetRole()] .. " (" .. attacker:Nick() .. ")"
            end
            return "The " .. ROLE_STRINGS[ROLE_RANDOSWAPPER] .. " (" .. victim:Nick() .. ") has swapped with " .. target .. "!"
        end)
end

-- Pre-generate all of this information because we need the owner's weapon info even after they've been destroyed due to (temporary) death
local function GetPlayerWeaponInfo(ply)
    local ply_weapons = {}
    for _, w in ipairs(ply:GetWeapons()) do
        local primary_ammo = nil
        local primary_ammo_type = nil
        if w.Primary and w.Primary.Ammo ~= "none" then
            primary_ammo_type = w.Primary.Ammo
            primary_ammo = ply:GetAmmoCount(primary_ammo_type)
        end

        local secondary_ammo = nil
        local secondary_ammo_type = nil
        if w.Secondary and w.Secondary.Ammo ~= "none" and w.Secondary.Ammo ~= primary_ammo_type then
            secondary_ammo_type = w.Secondary.Ammo
            secondary_ammo = ply:GetAmmoCount(secondary_ammo_type)
        end

        table.insert(ply_weapons, {
            class = WEPS.GetClass(w),
            category = w.Category,
            primary_ammo = primary_ammo,
            primary_ammo_type = primary_ammo_type,
            secondary_ammo = secondary_ammo,
            secondary_ammo_type = secondary_ammo_type
        })
    end
    return ply_weapons
end

local function GivePlayerWeaponAndAmmo(ply, weap_info)
    ply:Give(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(weap_info.primary_ammo, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(weap_info.secondary_ammo, weap_info.secondary_ammo_type)
    end
end

local function StripPlayerWeaponAndAmmo(ply, weap_info)
    ply:StripWeapon(weap_info.class)
    if weap_info.primary_ammo then
        ply:SetAmmo(0, weap_info.primary_ammo_type)
    end
    if weap_info.secondary_ammo then
        ply:SetAmmo(0, weap_info.secondary_ammo_type)
    end
end

local function CopyLoverNWVars(copyTo, copyFrom, cupidSID, loverSID)
    local cupid = player.GetBySteamID64(cupidSID)
    local lover = player.GetBySteamID64(loverSID)

    copyTo:SetNWString("TTTCupidShooter", cupidSID)
    copyTo:SetNWString("TTTCupidLover", loverSID)
    if lover and IsPlayer(lover) then
        lover:SetNWString("TTTCupidLover", copyTo:SteamID64())
        lover:QueueMessage(MSG_PRINTBOTH, copyTo:Nick() .. " has swapped with " .. copyFrom:Nick() .. " and is now your lover.")
    end

    if cupid then
        if cupid:GetNWString("TTTCupidTarget1", "") == copyFrom:SteamID64() then
            cupid:SetNWString("TTTCupidTarget1", copyTo:SteamID64())
        else
            cupid:SetNWString("TTTCupidTarget2", copyTo:SteamID64())
        end
        local message = copyTo:Nick() .. " has swapped with " .. copyFrom:Nick() .. " and is now "
        if #loverSID == 0 then
            message = message .. "waiting to be paired with a lover."
        else
            message = message .. "in love with " .. lover:Nick() .. "."
        end
        cupid:QueueMessage(MSG_PRINTBOTH, message)

        if #loverSID == 0 then
            message = copyFrom:Nick() .. " had been hit by cupid's arrow so you are now waiting to be paired with a lover."
        else
            message = copyFrom:Nick() .. " was in love so you are now in love with " .. lover:Nick() .. "."
        end
        copyTo:QueueMessage(MSG_PRINTBOTH, message)
    end
end

local function SwapCupidLovers(attacker, randoswapper)
    local attCupidSID = attacker:GetNWString("TTTCupidShooter", "")
    local attLoverSID = attacker:GetNWString("TTTCupidLover", "")
    local swaCupidSID = randoswapper:GetNWString("TTTCupidShooter", "")
    local swaLoverSID = randoswapper:GetNWString("TTTCupidLover", "")
    CopyLoverNWVars(randoswapper, attacker, attCupidSID, attLoverSID)
    CopyLoverNWVars(attacker, randoswapper, swaCupidSID, swaLoverSID)
end

local swapCount = 0
AddHook("PlayerDeath", "Randoswapper_KillCheck_PlayerDeath", function(victim, infl, attacker)
    local valid_kill = IsPlayer(attacker) and attacker ~= victim and GetRoundState() == ROUND_ACTIVE
    if not valid_kill then return end
    if not victim:IsRandoswapper() or victim:IsRoleAbilityDisabled() then return end

    victim:SetNWBool("IsRandoswapping", true)
    RandoswapperKilledNotification(attacker, victim)
    attacker:SetNWString("RandoswappedWith", victim:Nick())

    -- Only bother saving the attacker weapons if we're going to do something with them
    local weapon_mode = randoswapper_weapon_mode:GetInt()
    local attacker_weapons = nil
    if weapon_mode > RANDOSWAPPER_WEAPON_NONE then
        attacker_weapons = GetPlayerWeaponInfo(attacker)
    end
    local victim_weapons = GetPlayerWeaponInfo(victim)

    timer.Create("Randoswapping_" .. victim:SteamID64(), 0.01, 1, function()
        local body = victim.server_ragdoll or victim:GetRagdollEntity()
        victim:SetRole(attacker:GetRole())
        victim:SpawnForRound(true)
        victim:SetHealth(randoswapper_respawn_health:GetInt())
        if IsValid(body) then
            victim:SetPos(FindRespawnLocation(body:GetPos()) or body:GetPos())
            victim:SetEyeAngles(Angle(0, body:GetAngles().y, 0))
            body:Remove()
        end

        attacker:MoveRoleState(victim)
        local max_swaps = randoswapper_max_swaps:GetInt()
        if max_swaps > 0 and swapCount > max_swaps then
            attacker:SetRole(ROLE_SWAPPER)
            -- Set the swapper's tracking value too
            attacker:SetNWString("RandoswappedWith", victim:Nick())
        else
            swapCount = swapCount + 1
            attacker:SetRole(ROLE_RANDOSWAPPER)
            Randomat:TriggerRandomEvent(attacker)
        end

        local health = randoswapper_killer_health:GetInt()
        local attCupidSID = attacker:GetNWString("TTTCupidShooter", "")
        local vicCupidSID = victim:GetNWString("TTTCupidShooter", "")
        if randoswapper_swap_lovers:GetBool() and (#attCupidSID > 0 or #vicCupidSID > 0) and attCupidSID ~= vicCupidSID then -- If the attacker is going to live, only swap lovers if the attacker and the randoswapper arent in love with each other
            SwapCupidLovers(attacker, victim)
        end
        attacker:SetHealth(health)
        SetRoleMaxHealth(attacker)
        SendFullStateUpdate()

        victim:SetNWBool("IsRandoswapping", false)

        timer.Simple(0.2, function()
            if weapon_mode == RANDOSWAPPER_WEAPON_ALL then
                -- Strip everything but the sure-thing weapons
                for _, w in ipairs(attacker_weapons) do
                    if w.class ~= "weapon_ttt_unarmed" and w.class ~= "weapon_zm_carry" then
                        StripPlayerWeaponAndAmmo(attacker, w)
                    end
                end
                attacker:SetFOV(0, 0)

                -- Give the opposite player's weapons back
                for _, w in ipairs(attacker_weapons) do
                    GivePlayerWeaponAndAmmo(victim, w)
                end
                for _, w in ipairs(victim_weapons) do
                    GivePlayerWeaponAndAmmo(attacker, w)
                end
            else
                if weapon_mode == RANDOSWAPPER_WEAPON_ROLE then
                    -- Remove all role weapons from the attacker and give them to the victim
                    for _, w in ipairs(attacker_weapons) do
                        if w.category == WEAPON_CATEGORY_ROLE then
                            StripPlayerWeaponAndAmmo(attacker, w)
                            -- Give the attacker a regular crowbar to compensate for the killer crowbar that was removed
                            if w.class == "weapon_kil_crowbar" then
                                attacker:Give("weapon_zm_improvised")
                            end
                            GivePlayerWeaponAndAmmo(victim, w)
                        end
                    end
                    attacker:SetFOV(0, 0)

                    -- Give the attacker all of the victim's role weapons
                    for _, w in ipairs(victim_weapons) do
                        if w.category == WEAPON_CATEGORY_ROLE then
                            GivePlayerWeaponAndAmmo(attacker, w)
                        end
                    end
                end

                -- Give the victim all their weapons back
                for _, w in ipairs(victim_weapons) do
                    -- Don't give the victim back their old role weapons
                    if w.category == WEAPON_CATEGORY_ROLE then continue end
                    GivePlayerWeaponAndAmmo(victim, w)
                end
            end

            -- Have each player select their crowbar to hide role weapons
            attacker:SelectWeapon("weapon_zm_improvised")
            victim:SelectWeapon("weapon_zm_improvised")
        end)
    end)

    net.Start("TTT_RandoswapperSwapped")
    net.WriteString(victim:Nick())
    net.WriteString(attacker:Nick())
    net.WriteString(victim:SteamID64())
    net.Broadcast()
end)

AddHook("TTTStopPlayerRespawning", "Randoswapper_TTTStopPlayerRespawning", function(ply)
    if not IsPlayer(ply) then return end
    if ply:Alive() then return end

    if ply:GetNWBool("IsRandoswapping", false) then
        timer.Remove("Randoswapping_" .. ply:SteamID64())
        ply:SetNWBool("IsRandoswapping", false)
    end
end)

AddHook("TTTCupidShouldLoverSurvive", "Randoswapper_TTTCupidShouldLoverSurvive", function(ply, lover)
    if ply:GetNWBool("IsRandoswapping", false) or lover:GetNWBool("IsRandoswapping", false) then
        return true
    end
end)

AddHook("TTTPrepareRound", "Randoswapper_TTTPrepareRound", function()
    swapCount = 0
    for _, v in PlayerIterator() do
        v:SetNWString("RandoswappedWith", "")
        v:SetNWBool("IsRandoswapping", false)
        timer.Remove("Randoswapping_" .. v:SteamID64())
    end
end)