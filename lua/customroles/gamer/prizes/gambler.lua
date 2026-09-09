local PRIZE = {
    Id = "gambler",
    Name = "gamer_prize_gambler_name",
    Description = "gamer_prize_gambler_desc",
    Rarity = GAMER.Rarities.Epic,
    Icon = Material("vgui/ttt/gamer/prizes/gambler.png"),
    IsUnique = true,
    SillyName = "gamer_prize_scratchcard",
    SillyIcon = Material("vgui/ttt/gamer/prizes/scratchcard.png")
}

local function AssignRandomWeapons(ply)
    if not IsPlayer(ply) then return end
    if not ply:Alive() or ply:IsSpec() then return end

    for _, weap in ipairs(ply:GetWeapons()) do
        if weap.Kind == WEAPON_HEAVY or weap.Kind == WEAPON_PISTOL or weap.Kind == WEAPON_NADE then
            ply:StripWeapon(WEPS.GetClass(weap))
        end
    end

    local weps = weapons.GetList()
    table.Shuffle(weps)

    local hasHeavy = false
    local hasPistol = false
    local hasNade = false
    for _, weap in ipairs(weps) do
        if weap.Kind == WEAPON_HEAVY then
            if hasHeavy then continue end
            local given = ply:Give(WEPS.GetClass(weap))
            given.AllowDrop = false
            hasHeavy = true
        end

        if weap.Kind == WEAPON_PISTOL then
            if hasPistol then continue end
            local given = ply:Give(WEPS.GetClass(weap))
            given.AllowDrop = false
            hasPistol = true
        end

        if weap.Kind == WEAPON_NADE then
            if hasNade then continue end
            local given = ply:Give(WEPS.GetClass(weap))
            given.AllowDrop = false
            hasNade = true
        end

        if hasHeavy and hasPistol and hasNade then
            break
        end
    end
end

function PRIZE:Start(ply)
    if CLIENT then return end

    AssignRandomWeapons(ply)
    self:AddTimer(ply, 10, 0, function()
        AssignRandomWeapons(ply)
    end)

    -- But you get a 50% damage bonus
    self:AddHook("EntityTakeDamage", ply, function(ent, dmginfo)
        if not IsPlayer(ent) then return end
        if ply ~= ent then return end
        dmginfo:ScaleDamage(1.5)
    end)
end

GAMER.AddPrize(PRIZE)