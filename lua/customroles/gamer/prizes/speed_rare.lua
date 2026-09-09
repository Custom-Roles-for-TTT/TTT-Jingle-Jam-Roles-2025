local table = table

local TableInsert = table.insert

local PRIZE = {
    Id = "speed_rare",
    Name = "gamer_prize_speed_name",
    Description = "gamer_prize_speed_desc",
    DescriptionParams = { amt = 30 },
    Rarity = GAMER.Rarities.Rare,
    Icon = Material("vgui/ttt/gamer/prizes/speed.png"),
    SillyName = "gamer_prize_monster_rare",
    SillyIcon = Material("vgui/ttt/gamer/prizes/monster_rare.png")
}

function PRIZE:Start(ply)
    self:AddHook("TTTSpeedMultiplier", ply, function(p, mults)
        if not IsPlayer(ply) then return end
        if ply ~= p then return end
        TableInsert(mults, 1.3)
    end)
    if GetConVar("ttt_gamer_gacha_silly_prizes"):GetBool() then
        ply:EmitSound("gamer/mtdew.mp3", 100, 100, 1, CHAN_ITEM)
    end
end

GAMER.AddPrize(PRIZE)