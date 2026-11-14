if SERVER then
    AddCSLuaFile()
end

local hook = hook

local button_presses_to_win = GetConVar("ttt_button_presses_to_win")
local button_reset_mode = GetConVar("ttt_button_reset_mode")
local button_traitor_activate_only = GetConVar("ttt_button_traitor_activate_only")
local button_countdown_length = GetConVar("ttt_button_countdown_length")
local button_countdown_pause = GetConVar("ttt_button_countdown_pause")

if CLIENT then
    local hint_params = {usekey = Key("+use", "USE")}

    ENT.TargetIDHint = function(button)
        local client = LocalPlayer()
        if not IsPlayer(client) then return end

        return {
            name = LANG.GetTranslation("but_button_name"),
            hint = "but_button_hint",
            fmt  = function(ent, txt)
                if not IsValid(button) then return nil end
                if client == button:GetPlayer() then return nil end
                if not client:Alive() or client:IsSpec() then return nil end

                local hint = txt
                if button:GetPressed() then
                    local resetMode = button_reset_mode:GetInt()
                    if (resetMode == BUTTON_RESET_BLOCK_PRESSER and client == button:GetPresser()) or
                        (resetMode == BUTTON_RESET_BLOCK_TRAITORS and client:IsTraitorTeam()) then
                        hint = hint .. "_blocked"
                    else
                        hint = hint .. "_stop"
                    end
                elseif client:IsTraitorTeam() or not button_traitor_activate_only:GetBool() then
                    if GetGlobalBool("ttt_button_pressed", false) then
                        hint = hint .. "_double"
                    else
                        hint = hint .. "_start"
                    end
                else
                    return nil
                end

                return LANG.GetParamTranslation(hint, hint_params)
            end
        }
    end
    ENT.AutomaticFrameAdvance = true
else
    ENT.BlockList = {}
end

ENT.Type = "anim"

ENT.CanUseKey = true
ENT.ButtonModel = "models/maxofs2d/button_05.mdl"

ENT.PressCooldown = -1

function ENT:SetupDataTables()
    self:NetworkVar("Bool", "Pressed")
    self:NetworkVar("Entity", "Presser")
    self:NetworkVar("Entity", "Player")
    self:NetworkVar("Float", "Height")
end

function ENT:Initialize()
    self:SetPressed(false)
    self:SetModel(self.ButtonModel)
    self:SetColor(COLOR_GREEN)

    if SERVER then
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
    end
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE)

    if CLIENT then
        local beacon_back = surface.GetTextureID("vgui/ttt/beacon_back")
        local beacon_btn = surface.GetTextureID("vgui/ttt/beacon_btn")
        hook.Add("HUDPaint", "Button_HUDPaint_" .. self:EntIndex(), function()
            local client = LocalPlayer()
            if self:GetPressed() or client:IsTraitorTeam() then
                local pos = self:GetPos()

                local alpha = math.Clamp((pos:DistToSqr(client:EyePos()) - 1600) / 4800, 0, 1) -- Fade out the radar ping as you get closer to the button
                if alpha > 0 then
                    local target = {pos = pos}

                    surface.SetFont("HudSelectionText")

                    surface.SetTexture(beacon_back)
                    surface.SetTextColor(0, 0, 0, 0)
                    if self:GetPressed() then
                        surface.SetDrawColor(255, 0, 0, 230 * alpha)
                    else
                        surface.SetDrawColor(0, 255, 0, 230 * alpha)
                    end
                    RADAR:DrawTarget(target, 16, 0.5)

                    surface.SetTexture(beacon_btn)
                    surface.SetTextColor(255, 255, 255, 255 * alpha)
                    surface.SetDrawColor(255, 255, 255, 255 * alpha)
                    RADAR:DrawTarget(target, 16, 0.5)
                end
            end
        end)

        local mat = Material("vgui/ttt/btn_graygrid") -- Use our own material here because the default dev_graygrid is 'LightmappedGeneric' which doesn't play nice with drawing quads for some reason
        hook.Add("PostDrawTranslucentRenderables", "Button_PostDrawTranslucentRenderables_" .. self:EntIndex(), function(depth, skybox)
            local top = self:GetPos()
            local bottom = top - Vector(0, 0, self:GetHeight())
            local radius = 6
            local width = 4
            render.SetMaterial(mat)
            render.DrawQuad(top + Vector(radius, -width, 0), top + Vector(radius, width, 0), bottom + Vector(radius, width, 0), bottom + Vector(radius, -width, 0))
            render.DrawQuad(top + Vector(-radius, width, 0), top + Vector(-radius, -width, 0), bottom + Vector(-radius, -width, 0), bottom + Vector(-radius, width, 0))
            render.DrawQuad(top + Vector(width, radius, 0), top + Vector(-width, radius, 0), bottom + Vector(-width, radius, 0), bottom + Vector(width, radius, 0))
            render.DrawQuad(top + Vector(-width, -radius, 0), top + Vector(width, -radius, 0), bottom + Vector(width, -radius, 0), bottom + Vector(-width, -radius, 0))
            render.DrawQuad(top + Vector(-radius, -width, 0), top + Vector(-width, -radius, 0), bottom + Vector(-width, -radius, 0), bottom + Vector(-radius, -width, 0))
            render.DrawQuad(top + Vector(radius, width, 0), top + Vector(width, radius, 0), bottom + Vector(width, radius, 0), bottom + Vector(radius, width, 0))
            render.DrawQuad(top + Vector(-width, radius, 0), top + Vector(-radius, width, 0), bottom + Vector(-radius, width, 0), bottom + Vector(-width, radius, 0))
            render.DrawQuad(top + Vector(width, -radius, 0), top + Vector(radius, -width, 0), bottom + Vector(radius, -width, 0), bottom + Vector(width, -radius, 0))
        end)
    end
end

if SERVER then
    ENT.TimerElapsed = false

    function ENT:Think()
        local curTime = CurTime()
        local timerEnd = GetGlobalFloat("ttt_button_timer_end", -1)
        if timerEnd ~= -1 and curTime > timerEnd then
            if self.TimerElapsed then return end

            self.TimerElapsed = true

            -- If we're debugging, don't end the round
            if GetConVar("ttt_debug_preventwin"):GetBool() then
                return
            end

            -- Stop the win checks so someone else doesn't steal the traitor's win
            StopWinChecks()
            -- Delay the actual end for a bit so the net message has a chance to send so the button gets the win too
            timer.Simple(0.5, function() EndRound(WIN_TRAITOR) end)
            return
        end

        self:NextThink(curTime + 0.1)
        return true
    end

    function ENT:Use(activator)
        if self.TimerElapsed then return end
        if self.PressCooldown > CurTime() then return end

        local buttonPly = self:GetPlayer()
        if activator == buttonPly then return end

        if self:GetPressed() then
            local resetMode = button_reset_mode:GetInt()
            if resetMode == BUTTON_RESET_BLOCK_NONE or
                (resetMode == BUTTON_RESET_BLOCK_PRESSER and activator ~= self:GetPresser()) or
                (resetMode == BUTTON_RESET_BLOCK_TRAITORS and not activator:IsTraitorTeam()) then

                self:SetPressed(false)
                self:SetColor(COLOR_GREEN)
                SetGlobalBool("ttt_button_pressed", false)

                local remaining = math.max(0, GetGlobalFloat("ttt_button_timer_end", -1) - CurTime())
                SetGlobalFloat("ttt_button_timer_end", -1)
                if button_countdown_pause:GetBool() then
                    SetGlobalFloat("ttt_button_time_left", remaining)
                else
                    net.Start("TTT_ButtonResetSounds")
                    net.Broadcast()
                end

                if buttonPly.TTTButtonPresses then
                    buttonPly:SetProperty("TTTButtonPresses", buttonPly.TTTButtonPresses + 1)
                else
                    buttonPly:SetProperty("TTTButtonPresses", 1)
                end
                if buttonPly.TTTButtonPresses >= button_presses_to_win:GetInt() then
                    net.Start("TTT_UpdateButtonWins")
                    net.Broadcast()
                end

                net.Start("TTT_ButtonPlaySound")
                net.WriteString("hl1/fvox/bell.wav")
                net.Broadcast()
            end
        elseif (activator:IsTraitorTeam() or not button_traitor_activate_only:GetBool()) and not GetGlobalBool("ttt_button_pressed", false) then
            self:SetPresser(activator)
            self:SetPressed(true)
            self:SetColor(COLOR_RED)
            SetGlobalBool("ttt_button_pressed", true)

            local remaining = GetGlobalFloat("ttt_button_time_left", -1)
            if button_countdown_pause:GetBool() and remaining > 0 then
                SetGlobalFloat("ttt_button_timer_end", CurTime() + remaining)
            else
                SetGlobalFloat("ttt_button_timer_end", CurTime() + button_countdown_length:GetFloat())
            end

            net.Start("TTT_ButtonPlaySound")
            net.WriteString("button/alarm.wav")
            net.Broadcast()
        end

        -- For some reason even though use type is SIMPLE_USE it can still trigger multiple times in a single press
        self.PressCooldown = CurTime() + 0.1
    end
end

if CLIENT then
    function ENT:OnRemove()
        hook.Remove("HUDPaint", "Button_HUDPaint_" .. self:EntIndex())
        hook.Remove("PostDrawTranslucentRenderables", "Button_PostDrawTranslucentRenderables_" .. self:EntIndex())
    end
end