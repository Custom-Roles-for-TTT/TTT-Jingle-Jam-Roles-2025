local PRIZE = {
    Id = "jump_uncommon",
    Name = "gamer_prize_jump_name",
    NameParams = { amt = "Triple" },
    Description = "gamer_prize_jump_desc",
    DescriptionParams = { amt = "3x" },
    Rarity = GAMER.Rarities.Uncommon,
    Icon = Material("vgui/ttt/gamer/prizes/jump.png"),
    SillyName = "gamer_prize_keyboard_uncommon",
    SillyIcon = Material("vgui/ttt/gamer/prizes/keyboard_uncommon.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end
    -- No need to undo Triple Jump because it's already done in the server-side role cleanup
    if ply.SetMaxJumpLevel then
        ply:SetMaxJumpLevel(ply:GetMaxJumpLevel() + 1)
    else
        ply:SetJumpPower(ply:GetJumpPower() + (GAMER.Config.JumpPower * 2))
    end
end

GAMER.AddPrize(PRIZE)