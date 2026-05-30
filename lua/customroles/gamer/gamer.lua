local hook = hook
local math = math
local net = net
local table = table
local util = util

local AddHook = hook.Add
local MathRandom = math.random
local TableInsert = table.insert

util.AddNetworkString("TTTGamerGachaStart")

local function ChooseRandomPrize(ply)
    local chance = MathRandom()
    local targetRarity = GAMER.Rarities.Common
    if chance <= GAMER.Config.Rarities[GAMER.Rarities.Legendary].Chance then
        targetRarity = GAMER.Rarities.Legendary
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Epic].Chance then
        targetRarity = GAMER.Rarities.Epic
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Rare].Chance then
        targetRarity = GAMER.Rarities.Rare
    elseif chance <= GAMER.Config.Rarities[GAMER.Rarities.Uncommon].Chance then
        targetRarity = GAMER.Rarities.Uncommon
    end

    local prizes = {}
    for _, prize in pairs(GAMER.Prizes) do
        -- TODO: Check if this player already has a unique prize. If so, skip other unique prizes
        -- TODO: What happens if a player gets a duplicate?
        if prize.Rarity == targetRarity then
            TableInsert(prizes, prize)
        end
    end

    -- TODO: What if prizes is empty somehow?

    return prizes[MathRandom(#prizes)]
end

AddHook("TTTOrderedEquipment", function(ply, id, isequip)
    if id == EQUIP_GAMER_DORITOS then
        -- TODO: Gain 2 gacha rolls
    elseif id == EQUIP_GAMER_MTDEW then
        -- TODO: 20% speed increase and triple jump
    elseif id == EQUIP_GAMER_CHEETOS then
        -- TODO: Heals you to full and allows you to smear your dirty fingers on someone to track them through the round
    elseif id == EQUIP_GAMER_SPAGHETTI then
        -- TODO: Provides 5% health regen per second (unsure if permanent or not)
    elseif id == EQUIP_GAMER_MILK then
        -- TODO: ??
    elseif id == EQUIP_GAMER_GACHA then
        local prize = ChooseRandomPrize()
        net.Start("TTTGamerGachaStart")
            net.WriteString(prize.Id)
        net.Send(ply)
    end
end)