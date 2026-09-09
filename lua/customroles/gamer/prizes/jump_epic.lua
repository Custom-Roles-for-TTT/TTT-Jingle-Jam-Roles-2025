local PRIZE = {
    Id = "jump_epic",
    Name = "gamer_prize_jump_name",
    NameParams = { amt = "Quad" },
    Description = "gamer_prize_jump_desc",
    DescriptionParams = { amt = "4x" },
    Rarity = GAMER.Rarities.Epic,
    Icon = Material("vgui/ttt/gamer/prizes/jump.png"),
    SillyName = "gamer_prize_keyboard_epic",
    SillyIcon = Material("vgui/ttt/gamer/prizes/keyboard_epic.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end
    -- No need to undo Quad Jump because it's already done in the server-side role cleanup
    if ply.SetMaxJumpLevel then
        ply:SetMaxJumpLevel(ply:GetMaxJumpLevel() + 2)
    else
        ply:SetJumpPower(ply:GetJumpPower() + (GAMER.Config.JumpPower * 3))
    end
end

GAMER.AddPrize(PRIZE)