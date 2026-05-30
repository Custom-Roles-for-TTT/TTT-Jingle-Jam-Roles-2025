local file = file
local ipairs = ipairs
local table = table

local FileFind = file.Find
local TableHasValue = table.HasValue
local TableInsert = table.insert

local ROLE = {}

ROLE.nameraw = "gamer"
ROLE.name = "Gamer"
ROLE.nameplural = "Gamers"
ROLE.nameext = "a Gamer"
ROLE.nameshort = "gmr"

ROLE.desc = [[]]
ROLE.shortdesc = ""

ROLE.team = ROLE_TEAM_DETECTIVE

ROLE.translations = {
    ["english"] = {
        ["gamer_rarity_common"] = "Common",
        ["gamer_rarity_uncommon"] = "Uncommon",
        ["gamer_rarity_rare"] = "Rare",
        ["gamer_rarity_epic"] = "Epic",
        ["gamer_rarity_legendary"] = "Legendary",
        ["gamer_prize_display_format"] = "{name} [{rarity}]",
        ["gamer_prize_doritos_name"] = "Doritos",
        ["gamer_prize_doritos_desc"] = "Get two free gacha rolls"
    }
}

EQUIP_GAMER_DORITOS   = EQUIP_GAMER_DORITOS   or GenerateNewEquipmentID()
EQUIP_GAMER_MTDEW     = EQUIP_GAMER_MTDEW     or GenerateNewEquipmentID()
EQUIP_GAMER_CHEETOS   = EQUIP_GAMER_CHEETOS   or GenerateNewEquipmentID()
EQUIP_GAMER_SPAGHETTI = EQUIP_GAMER_SPAGHETTI or GenerateNewEquipmentID()
EQUIP_GAMER_MILK      = EQUIP_GAMER_MILK      or GenerateNewEquipmentID()
EQUIP_GAMER_GACHA     = EQUIP_GAMER_GACHA     or GenerateNewEquipmentID()

local function InitializeEquipment()
    if DefaultEquipment then
        DefaultEquipment[ROLE_GAMER] = {
            EQUIP_GAMER_DORITOS,
            EQUIP_GAMER_MTDEW,
            EQUIP_GAMER_CHEETOS,
            EQUIP_GAMER_SPAGHETTI,
            EQUIP_GAMER_MILK,
            EQUIP_GAMER_GACHA
        }
    end

    if EquipmentItems then
        if not EquipmentItems[ROLE_GAMER] then
            EquipmentItems[ROLE_GAMER] = {}
        end

        -- If we haven't already registered this item, add it to the list
        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_DORITOS) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_DORITOS,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_doritos",
                name = "item_gamer_doritos",
                desc = "item_gamer_doritos_desc",
                norandom = true
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_MTDEW) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_MTDEW,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_mtdew",
                name = "item_gamer_mtdew",
                desc = "item_gamer_mtdew_desc",
                norandom = true
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_CHEETOS) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_CHEETOS,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_cheetos",
                name = "item_gamer_cheetos",
                desc = "item_gamer_cheetos_desc",
                norandom = true
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_SPAGHETTI) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_SPAGHETTI,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_spaghetti",
                name = "item_gamer_spaghetti",
                desc = "item_gamer_spaghetti_desc",
                norandom = true
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_MILK) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_MILK,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_milk",
                name = "item_gamer_milk",
                desc = "item_gamer_milk_desc",
                norandom = true
            })
        end

        if not table.HasItemWithPropertyValue(EquipmentItems[ROLE_GAMER], "id", EQUIP_GAMER_GACHA) then
            TableInsert(EquipmentItems[ROLE_GAMER], {
                id = EQUIP_GAMER_GACHA,
                type = "item_passive",
                material = "vgui/ttt/gamer/icon_gacha",
                name = "item_gamer_gacha",
                desc = "item_gamer_gacha_desc",
                norandom = true
            })
        end
    end
end
InitializeEquipment()

hook.Add("Initialize", "Gamer_Equipment_Initialize", InitializeEquipment)
hook.Add("TTTPrepareRound", "Gamer_Equipment_Initialize", InitializeEquipment)

RegisterRole(ROLE)

GAMER = GAMER or {}
GAMER.Rarities = GAMER.Rarities or {
    Common = 1,
    Uncommon = 2,
    Rare = 3,
    Epic = 4,
    Legendary = 5
}
GAMER.Config = GAMER.Config or {
    Rarities = {
        [GAMER.Rarities.Common] = { Name = "gamer_rarity_common", Color = Color(166, 166, 166), Chance = 0.50 },
        [GAMER.Rarities.Uncommon] = { Name = "gamer_rarity_uncommon", Color = Color(0, 182, 33), Chance = 0.20 },
        [GAMER.Rarities.Rare] = { Name = "gamer_rarity_rare", Color = Color(0, 146, 240), Chance = 0.15 },
        [GAMER.Rarities.Epic] = { Name = "gamer_rarity_epic", Color = Color(143, 21, 185), Chance = 0.10 },
        [GAMER.Rarities.Legendary] = { Name = "gamer_rarity_legendary", Color = Color(255, 192, 0), Chance = 0.05 }
    }
    -- TODO: Timing?
}
GAMER.Prizes = GAMER.Prizes or {}

function GAMER.AddPrize(prize)
    if GAMER.Prizes[prize.Id] then return end

    if type(prize.Rarity) ~= "number" or not TableHasValue(GAMER.Rarities, prize.Rarity) then
        ErrorNoHaltWithStack("Invalid rarity ('" .. prize.Rarity .. "') for prize with ID: " .. prize.Id)
        return
    end

    GAMER.Prizes[prize.Id] = prize
end

local files, _ = FileFind("customroles/gamer/prizes/*.lua", "LUA")
for _, fil in ipairs(files) do
    if SERVER then
        AddCSLuaFile("customroles/gamer/prizes/" .. fil)
    end
    include("customroles/gamer/prizes/" .. fil)
end