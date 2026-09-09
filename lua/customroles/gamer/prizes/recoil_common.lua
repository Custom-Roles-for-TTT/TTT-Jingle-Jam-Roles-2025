local PRIZE = {
    Id = "recoil_common",
    Name = "gamer_prize_recoil_common_name",
    Description = "gamer_prize_recoil_desc",
    DescriptionParams = { amt = "20" },
    Rarity = GAMER.Rarities.Common,
    Icon = Material("vgui/ttt/gamer/prizes/recoil.png"),
    SillyName = "gamer_prize_mouse_common",
    SillyIcon = Material("vgui/ttt/gamer/prizes/mouse_common.png")
}

function PRIZE:Start(ply)
    if SERVER then
        self:AddHook("WeaponEquip", ply, function(weap, p)
            if not IsPlayer(ply) then return end
            if p ~= ply then return end
            GAMER.AdjustWeaponRecoil(weap, 0.2, p)
        end)
    end
    for _, weap in ipairs(ply:GetWeapons()) do
        GAMER.AdjustWeaponRecoil(weap, 0.2)
    end
end

GAMER.AddPrize(PRIZE)