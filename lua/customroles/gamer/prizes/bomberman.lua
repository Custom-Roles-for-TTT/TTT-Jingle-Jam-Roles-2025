local PRIZE = {
    Id = "bomberman",
    Name = "gamer_prize_bomberman_name",
    Description = "gamer_prize_bomberman_desc",
    Rarity = GAMER.Rarities.Epic,
    Icon = Material("vgui/ttt/gamer/prizes/bomberman.png"),
    IsUnique = true,
    SillyIcon = Material("vgui/ttt/gamer/prizes/bmcartridge.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end

    local storedWeap = weapons.Get("fp")
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

    local given = ply:Give("fp")
    if IsValid(given) then
        given.Kind = 99
        if IsValid(weaponData.Weapon) then
            weaponData.Weapon.Kind = weaponData.Kind
        end
    end

    self:AddHook("EntityTakeDamage", ply, function(ent, dmginfo)
        if not IsPlayer(ent) then return end
        if ply ~= ent then return end
        if not dmginfo:IsExplosionDamage() then return end
        dmginfo:ScaleDamage(0)
    end)
end

function PRIZE:CanStart(ply)
    return weapons.Get("fp") ~= nil
end

GAMER.AddPrize(PRIZE)