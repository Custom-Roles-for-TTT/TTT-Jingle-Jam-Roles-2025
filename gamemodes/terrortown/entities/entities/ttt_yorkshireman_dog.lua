if SERVER then
    AddCSLuaFile()
end

local math = math

local MathRand = math.Rand
local MathRandom = math.random

if CLIENT then
    ENT.TargetIDHint = function(dog)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        local name
        if not IsValid(dog) or dog:GetController() ~= client then
            name = LANG.GetTranslation("ysm_dog_name")
        else
            name = LANG.GetParamTranslation("ysm_dog_name_health", { current = dog:Health(), max = dog:GetMaxHealth() })
        end

        return {
            name = name,
            hint = nil
        }
    end
    ENT.AutomaticFrameAdvance = true
end

ENT.Type         = "nextbot"
ENT.Base         = "base_nextbot"

ENT.LoseDistance = 2000
ENT.SearchRadius = 1000

if SERVER then
    CreateConVar("ttt_yorkshireman_dog_health", "100", FCVAR_NONE, "How much health the Yorkshireman's Guard Dog should have", 1, 200)
    CreateConVar("ttt_yorkshireman_dog_damage", "20", FCVAR_NONE, "How much damage the Yorkshireman's Guard Dog should do", 1, 200)
end

AccessorFuncDT(ENT, "Damage", "Damage")
AccessorFuncDT(ENT, "Controller", "Controller")

function ENT:SetupDataTables()
   self:DTVar("Int", 0, "Damage")
   self:DTVar("Entity", 0, "Controller")
end

function ENT:Initialize()
    self:SetModel("models/cr4ttt_ysm/npc_dog.mdl")

    if SERVER then
        local health = GetConVar("ttt_yorkshireman_dog_health"):GetInt()
        self:SetHealth(health)
        self:SetMaxHealth(health)
        self:SetDamage(GetConVar("ttt_yorkshireman_dog_damage"):GetInt())

        self:SetVar("Attacking", false)

        -- Register sounds
        sound.Add({
            name = "cr4ttt_dog_eat",
            sound = "yorkshireman/dog/eat.mp3"
        })
        sound.Add({
            name = "cr4ttt_dog_bark",
            sound = "yorkshireman/dog/bark.mp3"
        })
        sound.Add({
            name = "cr4ttt_dog_bite",
            sound = "yorkshireman/dog/bite.mp3"
        })
        sound.Add({
            name = "cr4ttt_dog_whine",
            sound = "yorkshireman/dog/whine.mp3"
        })
    end
end

if SERVER then
    ENT.MaxSpawnDist = 200

    ENT.WanderDist = 100
    ENT.FollowDist = 150*150
    ENT.ReturnDist = 350*350
    ENT.RunDist = 600*600

    ENT.IdleSpeed = 100
    ENT.WalkSpeed = 150
    ENT.RunSpeed = 450

    ENT.IdleAccel = 400
    ENT.HuntAccel = 900

    ENT.NextAttack = 0
    ENT.AttackDelay = 1

    ENT.LastYelp = 0
    ENT.YelpDelay = 5

    ENT.StuckTime = 3
    ENT.StuckDist = 500

    ENT.TrackPause = 0.25

    ENT.Enemy = nil

    -------------
    -- UNSTUCK --
    -------------

    function ENT:IsStuck()
        return self.loco:IsStuck()
    end

    function ENT:Unstuck()
        -- If we're stuck in our enemy just let it go
        if IsValid(self.Enemy) and self:GetRangeSquaredTo(self.Enemy) < self.StuckDist then return end

        local controller = self:GetController()
        if not IsPlayer(controller) then return end

        local tr = controller:GetEyeTrace()
        if not tr.Hit then return end
        if tr.HitPos:Distance(controller:GetPos()) > self.MaxSpawnDist then return end

        local pos = tr.HitPos + Vector(0, 0, 5)
        local ang = controller:EyeAngles()
        ang.x = 0
        self:ClearEnemy()
        self:SetPos(pos)
        self:SetAngles(ang)
    end

    ----------------------
    -- ENEMY MANAGEMENT --
    ----------------------

    function ENT:GetEnemy()
        return self.Enemy
    end

    function ENT:SetEnemy(enemy)
        self.Enemy = enemy
    end

    function ENT:ClearEnemy()
        self.Enemy = nil
    end

    function ENT:HasEnemy()
        if not IsPlayer(self.Enemy) then return false end

        return self.Enemy:Alive() and not self.Enemy:IsSpec()
    end

    function ENT:ChaseEnemy()
        if not IsPlayer(self.Enemy) then return end

        local path = Path("Follow")
        path:SetMinLookAheadDistance(300)
        path:SetGoalTolerance(20)
        path:Compute(self, self.Enemy:GetPos())
        if not path:IsValid() then return end
        while path:IsValid() and self:HasEnemy() do
            -- Update the path to the enemy as they move
            if path:GetAge() > 0.1 then
                path:Compute(self, self.Enemy:GetPos())
            end
            path:Update(self)

            if self:IsStuck() then
                self:HandleStuck()
                if self:IsStuck() then return end
            end

            coroutine.yield()
        end
    end

    function ENT:TrackEnemy()
        if not IsPlayer(self.Enemy) then return end

        local act = self:GetActivity()
        self:EmitSound("cr4ttt_dog_bark")
        self.loco:FaceTowards(self.Enemy:GetPos())
        self:PlaySequenceAndWait("ragdoll")
        coroutine.wait(self.TrackPause)
        self:StartActivity(ACT_RUN)
        self.loco:SetDesiredSpeed(self.RunSpeed)
        self.loco:SetAcceleration(self.HuntAccel)
        self:ChaseEnemy()
        self.loco:SetAcceleration(self.IdleAccel)
        self:PlaySequenceAndWait("Push_back_medium")
        self:StartActivity(act)
    end

    -----------
    -- LOGIC --
    -----------

    function ENT:RunBehaviour()
        local controller = self:GetController()
        if not IsPlayer(controller) then return end

        while true do
            if self:HasEnemy() then
                self:TrackEnemy()
            else
                local controllerDistSqr = self:GetRangeSquaredTo(controller)
                if controllerDistSqr >= self.ReturnDist then
                    local controllerPos = controller:GetPos()
                    self.loco:FaceTowards(controllerPos)
                    self.loco:SetAcceleration(self.IdleAccel)

                    -- If they are really far away, run
                    if controllerDistSqr >= self.RunDist then
                        self:StartActivity(ACT_RUN)
                        self.loco:SetDesiredSpeed(self.RunSpeed)
                    -- Otherwise just walk
                    else
                        self:StartActivity(ACT_WALK)
                        self.loco:SetDesiredSpeed(self.WalkSpeed)
                    end

                    -- Start trying to follow the controller
                    local path = Path("Follow")
                    path:SetMinLookAheadDistance(50)
                    path:SetGoalTolerance(20)
                    path:Compute(self, controllerPos)
                    if not path:IsValid() then
                        continue
                    end

                    while path:IsValid() and controllerDistSqr > self.FollowDist do
                        -- Update the path to the controller as they move
                        if path:GetAge() > 0.1 then
                            path:Compute(self, controller:GetPos())
                        end
                        path:Update(self)

                        if self:IsStuck() then
                            self:Unstuck()
                            if self:IsStuck() then break end
                            continue
                        end

                        if self:HasEnemy() then
                            self:TrackEnemy()
                        end

                        local act = self:GetActivity()
                        if controllerDistSqr >= self.RunDist then
                            if act ~= ACT_RUN then
                                self:StartActivity(ACT_RUN)
                                self.loco:SetDesiredSpeed(self.RunSpeed)
                            end
                        elseif act ~= ACT_WALK then
                            self:StartActivity(ACT_WALK)
                            self.loco:SetDesiredSpeed(self.WalkSpeed)
                        end

                        -- Update the distance to the controller for the next iteration
                        controllerDistSqr = self:GetRangeSquaredTo(controller)
                        coroutine.yield()
                    end
                else
                    -- Wander, maybe idle a bit
                    if MathRandom(1, 2) == 1 then
                        self:StartActivity(ACT_WALK)
                        self.loco:SetDesiredSpeed(self.IdleSpeed)
                        self:MoveToPos(self:GetPos() + Vector(MathRand(-1, 1), MathRand(-1, 1), 0) * self.WanderDist)
                    else
                        self:PlaySequenceAndWait("idle0")
                    end
                end
            end
            coroutine.wait(0.1)
        end
    end

    --------------------
    -- EVENT HANDLERS --
    --------------------

    function ENT:OnKilled(dmginfo)
        self:EmitSound("cr4ttt_dog_whine")
        self:BecomeRagdoll(dmginfo)
    end

    function ENT:HandleStuck()
        if not self:IsStuck() then return end
        self:Unstuck()
    end

    function ENT:OnContact(contact)
        local curTime = CurTime()
        if curTime < self.NextAttack then return end
        if not IsPlayer(contact) then return end
        if self.Enemy ~= contact then return end

        local controller = self:GetController()
        if not IsPlayer(controller) then return end

        self:EmitSound("cr4ttt_dog_bite")
        self.NextAttack = curTime + self.AttackDelay

        local dmg = DamageInfo()
        dmg:SetDamage(self:GetDamage())
        dmg:SetDamageType(DMG_SLASH)
        dmg:SetAttacker(controller)
        dmg:SetInflictor(self)
        dmg:SetWeapon(controller:GetWeapon("weapon_ysm_guarddog"))
        self.Enemy:TakeDamageInfo(dmg)
    end

    function ENT:OnOtherKilled(victim, dmginfo)
        if not IsValid(self.Enemy) then return end
        if self.Enemy ~= victim then return end
        self:ClearEnemy()
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end