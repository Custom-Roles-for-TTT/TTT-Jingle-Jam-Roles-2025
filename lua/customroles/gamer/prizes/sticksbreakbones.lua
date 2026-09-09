local PRIZE = {
    Id = "sticksbreakbones",
    Name = "gamer_prize_sticksbreakbones_name",
    Description = "gamer_prize_sticksbreakbones_desc",
    Rarity = GAMER.Rarities.Epic,
    Icon = Material("vgui/ttt/gamer/prizes/sticksbreakbones.png"),
    IsUnique = true,
    SillyName = "gamer_prize_grass",
    SillyIcon = Material("vgui/ttt/gamer/prizes/grass.png")
}

function PRIZE:Start(ply)
    if CLIENT then return end

    self:AddHook("EntityTakeDamage", ply, function(ent, dmginfo)
        if not IsPlayer(ent) then return end

        local isMeleeDamage = dmginfo:IsDamageType(DMG_SLASH) or dmginfo:IsDamageType(DMG_CLUB)
        -- The player with this prize only takes melee damage
        if ply == ent then
            if not isMeleeDamage then
                dmginfo:ScaleDamage(0)
            end
            return
        end

        local att = dmginfo:GetAttacker()
        if IsPlayer(att) and att == ply then
            -- Can only do melee damage
            if not isMeleeDamage then
                dmginfo:ScaleDamage(0)
            -- But does 50% more
            else
                dmginfo:ScaleDamage(1.5)
            end
        end
    end)
end

GAMER.AddPrize(PRIZE)