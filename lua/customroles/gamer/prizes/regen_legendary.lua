local math = math

local MathMin = math.min

local PRIZE = {
    Id = "regen_legendary",
    Name = "gamer_prize_regen_name",
    Description = "gamer_prize_regen_desc",
    Rarity = GAMER.Rarities.Legendary,
    Icon = Material("vgui/ttt/gamer/prizes/regen.png"),
    SillyName = "gamer_prize_hotpockets",
    SillyIcon = Material("vgui/ttt/gamer/prizes/hotpockets.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end
    self:AddTimer(ply, 1, 0, function()
        if not IsPlayer(ply) then return end
        if not ply:Alive() or ply:IsSpec() then return end

        local hp = ply:Health()
        local max = ply:GetMaxHealth()
        local newHp = MathMin(max, hp + (max * 0.15))
        if hp ~= newHp then
            ply:SetHealth(newHp)
        end
    end)
end

GAMER.AddPrize(PRIZE)