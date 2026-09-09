local hook = hook
local file = file
local ipairs = ipairs
local math = math
local player = player
local table = table
local timer = timer

local AddHook = hook.Add
local FileFind = file.Find
local MathMax = math.max
local PlayerIterator = player.Iterator
local TableHasValue = table.HasValue
local TableInsert = table.insert
local TableRemove = table.remove

local ROLE = {}

ROLE.nameraw = "gamer"
ROLE.name = "Gamer"
ROLE.nameplural = "Gamers"
ROLE.nameext = "a Gamer"
ROLE.nameshort = "gmr"

ROLE.desc = [[You are {role}! As {adetective}, HQ has given you
special resources to find the {traitors}.

Buy snacks from your equipment shop to
get buffs and gacha rolls. Gacha can provide
a range of buffs of varying quality.

Press {menukey} to receive your equipment!]]
ROLE.shortdesc = "Buys snacks and gacha rolls for a chance at legendary buffs"

ROLE.team = ROLE_TEAM_DETECTIVE

ROLE.translations = {
    ["english"] = {
        -- Weapons
        ["gmr_cheeto_help_pri"] = "Use {primaryfire} to wipe Cheetos ® dust on a target",
        ["gmr_cheeto_help_sec"] = "making it easier to track their movements",
        ["gmr_gacha_help_pri"] = "Use {primaryfire} to use the gacha machine",
        ["gmr_gacha_help_sec"] = "for a chance at legendary buffs",
        -- Rarities
        ["gamer_rarity_common"] = "Common",
        ["gamer_rarity_uncommon"] = "Uncommon",
        ["gamer_rarity_rare"] = "Rare",
        ["gamer_rarity_epic"] = "Epic",
        ["gamer_rarity_legendary"] = "Legendary",
        -- Prizes
        ["gamer_prize_display_format"] = "{name} [{rarity}]",
        ["gamer_prize_speed_name"] = "Speed Boost",
        ["gamer_prize_speed_desc"] = "{amt}% speed increase",
        ["gamer_prize_speed_jump_name"] = "Super Long Jump",
        ["gamer_prize_speed_jump_desc"] = "50% speed increase, quad jump",
        ["gamer_prize_jump_name"] = "{amt} Jump",
        ["gamer_prize_jump_desc"] = "{amt} jump power",
        ["gamer_prize_credit_name"] = "Quick Cash",
        ["gamer_prize_credit_desc"] = "1 credit",
        ["gamer_prize_recoil_common_name"] = "Shoot Straight",
        ["gamer_prize_recoil_rare_name"] = "Shoot Straighter",
        ["gamer_prize_recoil_legendary_name"] = "Shoot Straightest",
        ["gamer_prize_recoil_desc"] = "{amt}% reduced recoil",
        ["gamer_prize_shop_name"] = "Snack Raid",
        ["gamer_prize_shop_desc"] = "Fill up with snacks{extra}",
        ["gamer_prize_regen_name"] = "Top it Up",
        ["gamer_prize_regen_desc"] = "Regenerate 15% health per second",
        ["gamer_prize_gun_name"] = "Lmao Bang",
        ["gamer_prize_gun_desc"] = "Get a Lmao Bang gun",
        ["gamer_prize_bomberman_name"] = "Bomberman",
        ["gamer_prize_bomberman_desc"] = "Become immune to explosions, get a barrel spawner",
        ["gamer_prize_sticksbreakbones_name"] = "Sticks Break Bones",
        ["gamer_prize_sticksbreakbones_desc"] = "Immune to all but melee damage but can only do melee damage (with a 50% bonus)",
        ["gamer_prize_gambler_name"] = "Gambler",
        ["gamer_prize_gambler_desc"] = "Your loadout is randomized every 10 seconds, however you gain a 50% damage bonus",
        ["gamer_prize_supergamer_name"] = "Supergamer",
        ["gamer_prize_supergamer_desc"] = "Get a PAP'd Jetpack, a PHD Flopper, and take 50% less damage",
        -- Silly Prize Names
        ["gamer_prize_monster_common"] = "Monster Energy®",
        ["gamer_prize_monster_uncommon"] = "Pipeline Punch Monster Energy®",
        ["gamer_prize_monster_rare"] = "Mango Loco Monster Energy®",
        ["gamer_prize_monster_epic"] = "White Monster Energy®",
        ["gamer_prize_mouse_common"] = "Logitech® M575",
        ["gamer_prize_mouse_rare"] = "Razer® Death Adder",
        ["gamer_prize_mouse_legendary"] = "Corsair® Scimitar Elite",
        ["gamer_prize_keyboard_uncommon"] = "IBM® Model M",
        ["gamer_prize_keyboard_epic"] = "Keychron® V6 Max",
        ["gamer_prize_keyboard_legendary"] = "Razer® Blackwidow V4 Pro",
        ["gamer_prize_powerglove"] = "NES Power Glove®",
        ["gamer_prize_token"] = "Arcade Token",
        ["gamer_prize_hotpockets"] = "Microwaved Hot Pockets®",
        ["gamer_prize_scratchcard"] = "Scratchcard",
        ["gamer_prize_grass"] = "Grass",
        -- Shop
        ["item_gamer_doritos"] = "Doritos®",
        ["item_gamer_doritos_desc"] = "Gain 2 gacha rolls",
        ["item_gamer_mtdew"] = "Mt. Dew®",
        ["item_gamer_mtdew_desc"] = "Increase your movement speed and gain some extra jump power",
        ["item_gamer_cheetos"] = "Cheetos®",
        ["item_gamer_cheetos_desc"] = "Heals you to full and allows you to smear your dirty fingers on someone to track them through the round",
        ["item_gamer_spaghetti"] = "Mom's Spaghetti",
        ["item_gamer_spaghetti_desc"] = "Heals you periodically for the rest of the round",
        ["item_gamer_milk"] = "Choccy Milk",
        ["item_gamer_milk_desc"] = "Reduces fall damage and increases melee damage. Hope you're not lactose intolerant though...",
        -- Config
        ["gamer_config_gacha_offset_x"] = "Gacha Machine X (horizontal) position",
        ["gamer_config_gacha_offset_y"] = "Gacha Machine Y (vertical) position",
        ["gamer_config_gacha_offset_reset"] = "Reset Gacha Machine position",
        -- Popup
        ["info_popup_gamer_gacha_only"] =[[You are {role}! As {adetective}, HQ has given you
special resources to find the {traitors}.

Use your gacha machine to get prizes that can
provide a range of buffs of varying quality.

Press {menukey} to receive your equipment!]]
    }
}

local gamer_mtdew_speed_boost = CreateConVar("ttt_gamer_mtdew_speed_boost", "0.2", FCVAR_REPLICATED, "The percentage to boost a player's speed after they drink a Mt. Dew (e.g. 0.2 = 20% = 120% total movement speed)", 0.1, 1)
local gamer_gacha_only_mode = CreateConVar("ttt_gamer_gacha_only_mode", "0", FCVAR_REPLICATED, "Whether the Gamer's unique shop items should instead be gacha prizes", 0, 1)

CreateConVar("ttt_gamer_gacha_silly_prizes", "0", FCVAR_REPLICATED, "Whether the names and icons of gacha prizes should be silly gamer themed items instead of simple descriptions and icons", 0, 1)

ROLE.convars = {
    {
        cvar = "ttt_gamer_mtdew_speed_boost",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_gamer_spaghetti_amount",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_gamer_spaghetti_interval",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_gamer_milk_fall_damage_reduction",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_gamer_milk_melee_damage_bonus",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 2
    },
    {
        cvar = "ttt_gamer_milk_fart_interval_min",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_gamer_milk_fart_interval_max",
        type = ROLE_CONVAR_TYPE_NUM,
        decimal = 0
    },
    {
        cvar = "ttt_gamer_gacha_only_mode",
        type = ROLE_CONVAR_TYPE_BOOL
    },
    {
        cvar = "ttt_gamer_gacha_silly_prizes",
        type = ROLE_CONVAR_TYPE_BOOL
    }
}

RegisterRole(ROLE)

---------------
-- EQUIPMENT --
---------------

EQUIP_GAMER_DORITOS   = EQUIP_GAMER_DORITOS   or GenerateNewEquipmentID()
EQUIP_GAMER_MTDEW     = EQUIP_GAMER_MTDEW     or GenerateNewEquipmentID()
EQUIP_GAMER_CHEETOS   = EQUIP_GAMER_CHEETOS   or GenerateNewEquipmentID()
EQUIP_GAMER_SPAGHETTI = EQUIP_GAMER_SPAGHETTI or GenerateNewEquipmentID()
EQUIP_GAMER_MILK      = EQUIP_GAMER_MILK      or GenerateNewEquipmentID()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_GAMER] = {
            EQUIP_GAMER_DORITOS,
            EQUIP_GAMER_MTDEW,
            EQUIP_GAMER_CHEETOS,
            EQUIP_GAMER_SPAGHETTI,
            EQUIP_GAMER_MILK
        }
    end

    if EquipmentItems then
        if not EquipmentItems[ROLE_GAMER] then
            EquipmentItems[ROLE_GAMER] = {}
        end

        if gamer_gacha_only_mode:GetBool() then
            -- If we are in gacha only mode then don't put these items in the Gamer's shop
            for i = #EquipmentItems[ROLE_GAMER], 1, -1 do
                local equipment = EquipmentItems[ROLE_GAMER][i]
                if equipment.id == EQUIP_GAMER_DORITOS or equipment.id == EQUIP_GAMER_MTDEW or equipment.id == EQUIP_GAMER_CHEETOS or equipment.id == EQUIP_GAMER_SPAGHETTI or equipment.id == EQUIP_GAMER_MILK then
                    TableRemove(EquipmentItems[ROLE_GAMER], i)
                end
            end
        else
            -- If we haven't already registered this item, add it to the list
            if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_DORITOS) then
                TableInsert(EquipmentItems[ROLE_GAMER], {
                    id = EQUIP_GAMER_DORITOS,
                    type = "item_active",
                    material = "vgui/ttt/gamer/icon_gamer_doritos",
                    name = "item_gamer_doritos",
                    desc = "item_gamer_doritos_desc",
                    norandom = true
                })
            end

            if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_MTDEW) then
                TableInsert(EquipmentItems[ROLE_GAMER], {
                    id = EQUIP_GAMER_MTDEW,
                    type = "item_passive",
                    material = "vgui/ttt/gamer/icon_gamer_mtdew",
                    name = "item_gamer_mtdew",
                    desc = "item_gamer_mtdew_desc",
                    norandom = true
                })
            end

            if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_CHEETOS) then
                TableInsert(EquipmentItems[ROLE_GAMER], {
                    id = EQUIP_GAMER_CHEETOS,
                    type = "item_active",
                    material = "vgui/ttt/gamer/icon_gamer_cheetos",
                    name = "item_gamer_cheetos",
                    desc = "item_gamer_cheetos_desc",
                    norandom = true
                })
            end

            if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_SPAGHETTI) then
                TableInsert(EquipmentItems[ROLE_GAMER], {
                    id = EQUIP_GAMER_SPAGHETTI,
                    type = "item_passive",
                    material = "vgui/ttt/gamer/icon_gamer_spaghetti",
                    name = "item_gamer_spaghetti",
                    desc = "item_gamer_spaghetti_desc",
                    norandom = true
                })
            end

            if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_MILK) then
                TableInsert(EquipmentItems[ROLE_GAMER], {
                    id = EQUIP_GAMER_MILK,
                    type = "item_passive",
                    material = "vgui/ttt/gamer/icon_gamer_milk",
                    name = "item_gamer_milk",
                    desc = "item_gamer_milk_desc",
                    norandom = true
                })
            end
        end
    end
end
InitializeEquipment()

AddHook("Initialize", "Gamer_Equipment_Initialize", InitializeEquipment)
AddHook("TTTPrepareRound", "Gamer_Equipment_Initialize", InitializeEquipment)

------------
-- CONFIG --
------------

GAMER = GAMER or {}
GAMER.Rarities = GAMER.Rarities or {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5
}
GAMER.Config = GAMER.Config or {
    CheetoColor = Color(255, 137, 40),
    JumpPower = 160,
    Rarities = {
        [GAMER.Rarities.Common] = { Name = "gamer_rarity_common", Color = Color(166, 166, 166), Chance = 0.50 },
        [GAMER.Rarities.Uncommon] = { Name = "gamer_rarity_uncommon", Color = Color(0, 182, 33), Chance = 0.20 },
        [GAMER.Rarities.Rare] = { Name = "gamer_rarity_rare", Color = Color(0, 146, 240), Chance = 0.15 },
        [GAMER.Rarities.Epic] = { Name = "gamer_rarity_epic", Color = Color(143, 21, 185), Chance = 0.10 },
        [GAMER.Rarities.Legendary] = { Name = "gamer_rarity_legendary", Color = Color(255, 192, 0), Chance = 0.05 }
    },
    Timing = {
        -- Slightly after the prize text and image fades in
        Effect = 5,
        Animations = {
            -- Move the balls around and rotate the handle
            Step1 = 1,
            Step2 = 1.5,
            Step3 = 2,
            -- Draw the prize ball
            Step4 = 2.5,
            -- Move the prize ball to the center of the screen
            Step5 = 3,
            -- Open the prize ball and draw the prize
            Step6 = 4,
            -- Fade in the prize text and image
            Step7 = 4.5,
            -- Fade out the prize ball, text, and image
            Step8 = 8,
            -- Reset
            Reset = 10
        }
    }
}
GAMER.Prizes = GAMER.Prizes or {}

------------------------
-- PRIZE REGISTRATION --
------------------------

local prize_meta =  {}
prize_meta.__index = prize_meta

function prize_meta:Start(ply) end
function prize_meta:End() end
function prize_meta:CanStart(ply) return true end

function prize_meta:AddTimer(ply, delay, repetitions, func, suffix)
    local id = "Gamer_" .. self.Id .. "_" .. ply:SteamID64()
    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. "_" .. suffix
    end
    timer.Create(id, delay, repetitions, func)

    self.Timers = self.Timers or {}
    TableInsert(self.Timers, id)
end

function prize_meta:RemoveTimer(ply, suffix)
    local id = "Gamer_" .. self.Id .. "_" .. ply:SteamID64()
    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. "_" .. suffix
    end
    for idx, tId in ipairs(self.Timers or {}) do
        if tId == id then
            timer.Remove(tId)
            table.remove(self.Timers, idx)
            return
        end
    end
end

function prize_meta:CleanUpTimers()
    if not self.Timers then return end

    for _, tId in ipairs(self.Timers) do
        print("Removing timer:", tId)
        timer.Remove(tId)
    end

    table.Empty(self.Timers)
end

function prize_meta:AddHook(hooktype, ply, func, suffix)
    func = func or self[hooktype]

    local id = "Gamer_" .. self.Id .. "_" .. hooktype .. "_" .. ply:SteamID64()
    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. "_" .. suffix
    end
    hook.Add(hooktype, id, func)

    self.Hooks = self.Hooks or {}
    TableInsert(self.Hooks, {hooktype, id})
end

function prize_meta:RemoveHook(hooktype, ply, suffix)
    local id = "Gamer_" .. self.Id .. "_" .. hooktype .. "_" .. ply:SteamID64()
    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. "_" .. suffix
    end
    for idx, ahook in ipairs(self.Hooks or {}) do
        if ahook[1] == hooktype and ahook[2] == id then
            hook.Remove(ahook[1], ahook[2])
            table.remove(self.Hooks, idx)
            return
        end
    end
end

function prize_meta:CleanUpHooks()
    if not self.Hooks then return end

    for _, ahook in ipairs(self.Hooks) do
        print("Removing hook:", ahook[1], ahook[2])
        hook.Remove(ahook[1], ahook[2])
    end

    table.Empty(self.Hooks)
end

function GAMER.AddPrize(prize)
    if GAMER.Prizes[prize.Id] then return end

    if type(prize.Rarity) ~= "number" or not TableHasValue(GAMER.Rarities, prize.Rarity) then
        ErrorNoHaltWithStack("Invalid rarity ('" .. prize.Rarity .. "') for prize with ID: " .. prize.Id)
        return
    end

    prize.IsUnique = prize.IsUnique or false
    prize.__index = prize
    setmetatable(prize, prize_meta)

    GAMER.Prizes[prize.Id] = prize
end

local files, _ = FileFind("customroles/gamer/prizes/*.lua", "LUA")
for _, fil in ipairs(files) do
    if SERVER then
        AddCSLuaFile("customroles/gamer/prizes/" .. fil)
    end
    include("customroles/gamer/prizes/" .. fil)
end

------------------------
-- MT DEW SPEED BOOST --
------------------------

AddHook("TTTSpeedMultiplier", "Gamer_TTTSpeedMultiplier", function(ply, mults)
    if ply:HasEquipmentItem(EQUIP_GAMER_MTDEW) then
        TableInsert(mults, 1 + gamer_mtdew_speed_boost:GetFloat())
    end
end)

-------------------
-- RECOIL PRIZES --
-------------------

function GAMER.AdjustWeaponRecoil(weap, pct, net_tgt)
    if weap.Primary and weap.Primary.Recoil then
        local amt
        if weap.Primary.OrigRecoil then
            amt = weap.Primary.OrigRecoil * pct
        else
            amt = weap.Primary.Recoil * pct
            weap.Primary.OrigRecoil = weap.Primary.Recoil
        end
        weap.Primary.Recoil = MathMax(0, weap.Primary.Recoil - amt)
    end

    if weap.Secondary and weap.Secondary.Recoil then
        local amt
        if weap.Secondary.OrigRecoil then
            amt = weap.Secondary.OrigRecoil * pct
        else
            amt = weap.Secondary.Recoil * pct
            weap.Secondary.OrigRecoil = weap.Secondary.Recoil
        end
        weap.Secondary.Recoil = MathMax(0, weap.Secondary.Recoil - amt)
    end

    if SERVER and net_tgt then
        net.Start("TTTGamerRecoilAdjust")
            net.WriteEntity(weap)
            net.WriteFloat(pct)
        net.Send(net_tgt)
    end
end

function GAMER.ResetWeaponRecoil(weap, net_tgt)
    if weap.Primary and weap.Primary.OrigRecoil then
        weap.Primary.Recoil = weap.Primary.OrigRecoil
        weap.Primary.OrigRecoil = nil
    end

    if weap.Secondary and weap.Secondary.OrigRecoil then
        weap.Secondary.Recoil = weap.Secondary.OrigRecoil
        weap.Secondary.OrigRecoil = nil
    end

    if SERVER and net_tgt then
        net.Start("TTTGamerRecoilReset")
            net.WriteEntity(weap)
        net.Send(net_tgt)
    end
end

if CLIENT then
    net.Receive("TTTGamerRecoilAdjust", function()
        local weap = net.ReadEntity()
        local pct = net.ReadFloat()
        if not IsValid(weap) then return end

        GAMER.AdjustWeaponRecoil(weap, pct)
    end)

    net.Receive("TTTGamerRecoilReset", function()
        local weap = net.ReadEntity()
        if not IsValid(weap) then return end

        GAMER.ResetWeaponRecoil(weap)
    end)
end

-------------
-- CLEANUP --
-------------

local function Cleanup()
    for _, prize in pairs(GAMER.Prizes) do
        prize:CleanUpHooks()
        prize:CleanUpTimers()
        prize:End()
    end

    for _, p in PlayerIterator() do
        for _, weap in ipairs(p:GetWeapons()) do
            GAMER.ResetWeaponRecoil(weap)
        end
    end
end

AddHook("TTTPrepareRound", "Gamer_Shared_TTTPrepareRound", Cleanup)
AddHook("TTTEndRound", "Gamer_Shared_TTTEndRound", Cleanup)