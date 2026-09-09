local PRIZE = {
    Id = "supergamer",
    Name = "gamer_prize_supergamer_name",
    Description = "gamer_prize_supergamer_desc",
    Rarity = GAMER.Rarities.Legendary,
    Icon = Material("vgui/ttt/gamer/prizes/supergamer.png"),
    IsUnique = true,
    SillyName = "gamer_prize_powerglove",
    SillyIcon = Material("vgui/ttt/gamer/prizes/powerglove.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end

    local storedWeap = weapons.Get("weapon_ttt_jetpack")
    local weaponData = { }
    if not ply:CanCarryWeapon(storedWeap) then
        for _, weap in ipairs(ply:GetWeapons()) do
            if weap.Kind == storedWeap.Kind then
                weaponData.Weapon = weap
                weaponData.Kind = weap.Kind
                weap.Kind = 100
                break
            end
        end
    end

    -- Get a PAP'd jetpack
    local given = ply:Give("weapon_ttt_jetpack")
    if IsValid(given) then
        given.Kind = 99
        if IsValid(weaponData.Weapon) then
            weaponData.Weapon.Kind = weaponData.Kind
        end
        TTTPAP:ApplyRandomUpgrade(given)
    end

    -- and a PHD Flopper
    ply:Give("ttt_perk_phd")

    -- Take 1/2 damage from everything
    self:AddHook("EntityTakeDamage", ply, function(ent, dmginfo)
        if not IsPlayer(ent) then return end
        if ply ~= ent then return end
        dmginfo:ScaleDamage(0.5)
    end)
end

function PRIZE:CanStart(ply)
    if not TTTPAP then return false end
    return weapons.Get("weapon_ttt_jetpack") ~= nil and weapons.Get("ttt_perk_phd") ~= nil
end

GAMER.AddPrize(PRIZE)