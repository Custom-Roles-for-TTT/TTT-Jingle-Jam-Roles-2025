local table = table

local TableInsert = table.insert

local PRIZE = {
    Id = "speed_uncommon",
    Name = "gamer_prize_speed_name",
    Description = "gamer_prize_speed_desc",
    DescriptionParams = { amt = 20 },
    Rarity = GAMER.Rarities.Uncommon,
    Icon = Material("vgui/ttt/gamer/prizes/speed.png"),
    SillyName = "gamer_prize_monster_uncommon",
    SillyIcon = Material("vgui/ttt/gamer/prizes/monster_uncommon.png")
}

function PRIZE:Start(ply)
    self:AddHook("TTTSpeedMultiplier", ply, function(p, mults)
        if not IsPlayer(ply) then return end
        if ply ~= p then return end
        TableInsert(mults, 1.2)
    end)
    if GetConVar("ttt_gamer_gacha_silly_prizes"):GetBool() then
        ply:EmitSound("gamer/mtdew.mp3", 100, 100, 1, CHAN_ITEM)
    end
end

GAMER.AddPrize(PRIZE)