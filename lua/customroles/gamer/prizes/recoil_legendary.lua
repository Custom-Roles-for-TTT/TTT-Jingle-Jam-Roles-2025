local PRIZE = {
    Id = "recoil_legendary",
    Name = "gamer_prize_recoil_legendary_name",
    Description = "gamer_prize_recoil_desc",
    DescriptionParams = { amt = "100" },
    Rarity = GAMER.Rarities.Legendary,
    Icon = Material("vgui/ttt/gamer/prizes/recoil.png"),
    SillyName = "gamer_prize_mouse_legendary",
    SillyIcon = Material("vgui/ttt/gamer/prizes/mouse_legendary.png")
}

function PRIZE:Start(ply)
    if SERVER then
        self:AddHook("WeaponEquip", ply, function(weap, p)
            if not IsPlayer(ply) then return end
            if p ~= ply then return end
            GAMER.AdjustWeaponRecoil(weap, 1, p)
        end)
    end
    for _, weap in ipairs(ply:GetWeapons()) do
        GAMER.AdjustWeaponRecoil(weap, 1)
    end
end

GAMER.AddPrize(PRIZE)