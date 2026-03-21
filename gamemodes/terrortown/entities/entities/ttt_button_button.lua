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
        hook.Add("PreDrawHalos", "Button_PreDrawHalos_" .. self:EntIndex(), function()
            if self:GetPressed() then
                halo.Add({self}, COLOR_RED, 1, 1, 1, true, true)
            elseif LocalPlayer():IsTraitorTeam() then
                halo.Add({self}, COLOR_GREEN, 1, 1, 1, true, true)
            end
        end)

        local mat = Material("dev/graygrid")
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
    function ENT:Use(activator)
        if self.PressCooldown > CurTime() then return end

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

                if self.ButtonPly.TTTButtonPresses then
                    self.ButtonPly:SetProperty("TTTButtonPresses", self.ButtonPly.TTTButtonPresses + 1)
                else
                    self.ButtonPly:SetProperty("TTTButtonPresses", 1)
                end
                if self.ButtonPly.TTTButtonPresses == button_presses_to_win:GetInt() then
                    net.Start("TTT_UpdateButtonWins")
                    net.Broadcast()
                end

                -- TODO: Sound when button is reset
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
            net.WriteString("alarm")
            net.Broadcast()
        end

        -- For some reason even though use type is SIMPLE_USE it can still trigger multiple times in a single press
        self.PressCooldown = CurTime() + 0.1
    end
end

if CLIENT then
    function ENT:OnRemove()
        hook.Remove("PreDrawHalos", "Button_PreDrawHalos_" .. self:EntIndex())
        hook.Remove("PostDrawTranslucentRenderables", "Button_PostDrawTranslucentRenderables_" .. self:EntIndex())
    end
end