local concommand = concommand
local draw = draw
local hook = hook
local ipairs = ipairs
local surface = surface
local string = string
local table = table
local timer = timer
local math = math

local AddHook = hook.Add
local TableInsert = table.insert
local TableRemove = table.remove
local MathRandom = math.random
local MathRand = math.Rand
local MathSqrt = math.sqrt
local MathRad = math.rad
local MathPi = math.pi
local MathSin = math.sin
local MathCos = math.cos
local MathAtan2 = math.atan2

----------------
-- GACHA SIM --
----------------

local isAnimating = false
local drawPrizeBall = false
local drawPrize = false

local ballRadius = 25
local prizeBallRadius = 200
local gachaHeight = 300
local gachaWidth = 300
local bodyHeight = 200
local bodyOverlap = ballRadius * 2
local frameWidth = 15
local margin = 5
local outline = 2
local gravity = 0.3
local restitution = 0.2
local friction = 0.01

local gacha_offset_x = CreateClientConVar("ttt_gamer_gacha_offset_x", "50", true, false, "The screen offset from the left to render the gacha machine at, on the x axis (left-and-right)")
local gacha_offset_y = CreateClientConVar("ttt_gamer_gacha_offset_y", "0", true, false, "The screen offset from the center to render the gacha machine at, on the y axes (up-and-down)")

concommand.Add("ttt_gamer_gacha_offset_reset", function()
    gacha_offset_x:SetInt(gacha_offset_x:GetDefault())
    gacha_offset_y:SetInt(gacha_offset_y:GetDefault())
end)

AddHook("TTTSettingsRolesTabSections", "Gamer_TTTSettingsRolesTabSections", function(role, parentForm)
    if role ~= ROLE_GAMER then return end

    -- Let the user move the gacha machine within the bounds of the window
    local height = (ScrH() - gachaHeight) / 2
    parentForm:NumSlider(LANG.GetTranslation("gamer_config_gacha_offset_x"), "ttt_gamer_gacha_offset_x", 0, ScrW() - gachaWidth - bodyHeight + bodyOverlap, 0)
    parentForm:NumSlider(LANG.GetTranslation("gamer_config_gacha_offset_y"), "ttt_gamer_gacha_offset_y", -height, height, 0)
    parentForm:Button(LANG.GetTranslation("gamer_config_gacha_offset_reset"), "ttt_gamer_gacha_offset_reset")
    return true
end)

local xOffset = 0
local xOffsetTarget = 0
local handleAngle = 0
local handleAngleTarget = 0
local outputHeight = 1
local outputHeightTarget = 1
local prizePath = 0
local prizePathTarget = 0
local prizeOpen = 0
local prizeOpenTarget = 0
local prizeAlpha = 255
local prizeAlphaTarget = 255
local prizeTextAlpha = 0
local prizeTextAlphaTarget = 0

local boxMinX = gacha_offset_x:GetInt()
local boxMaxX = boxMinX + gachaWidth
local boxMinY = ((ScrH() - gachaHeight - bodyHeight + bodyOverlap) / 2) + gacha_offset_y:GetInt()
local boxMaxY = boxMinY + gachaHeight

local prizeBall = nil

local gachaBalls = {}
local function CreateBall(x, y, rarity)
    TableInsert(gachaBalls, {x=x, y=y, Rarity=rarity, vx=MathRand(-5,5), vy=MathRand(-5,5), a=MathRand(0, 2 * MathPi)})
end

local function RemoveBall()
    local closestIndex
    local closestDistSqr = -1
    local slotX = (boxMinX + boxMaxX) / 2
    local slotY = boxMaxY - ballRadius

    for i, ball in ipairs(gachaBalls) do
        local dx = ball.x - slotX
        local dy = ball.y - slotY
        local distSqr = dx * dx + dy * dy
        if closestDistSqr == -1 or distSqr < closestDistSqr then
            closestIndex = i
            closestDistSqr = distSqr
        end
    end
    TableRemove(gachaBalls, closestIndex)
end

local function AnimateGacha()
    isAnimating = true
    for x = boxMinX + ballRadius, boxMaxX - ballRadius, ballRadius * 2 do
        local offset = false
        for y = boxMinY + ballRadius, boxMaxY - ballRadius, ballRadius * 2 do
            offset = not offset

            local rarity = MathRandom(GAMER.Rarities.Uncommon, GAMER.Rarities.Legendary)
            if offset then
                CreateBall(x + MathRandom(-10, 10) + ballRadius, y + MathRandom(-10, 10), rarity)
            else
                CreateBall(x + MathRandom(-10, 10), y + MathRandom(-10, 10), rarity)
            end
        end
    end

    local leftSide = gacha_offset_x:GetInt() + (gachaWidth / 2) <= ScrW() / 2
    if leftSide then
        xOffset = -gachaWidth - gacha_offset_x:GetInt() - margin - outline
    else
        xOffset = ScrW() - gacha_offset_x:GetInt() + margin + (outline * 2)
    end
    xOffsetTarget = 0

    timer.Simple(1, function()
        RemoveBall()
        handleAngleTarget = (MathPi / 3)
    end)
    timer.Simple(1.5, function()
        RemoveBall()
        handleAngleTarget = (MathPi / 3) * 2
    end)
    timer.Simple(2, function()
        RemoveBall()
        handleAngleTarget = MathPi
    end)

    timer.Simple(2.5, function()
        outputHeightTarget = 0.2
        drawPrizeBall = true
    end)

    timer.Simple(3, function()
        prizePathTarget = 1

        leftSide = gacha_offset_x:GetInt() + (gachaWidth / 2) <= ScrW() / 2

        if leftSide then
            xOffsetTarget = -gachaWidth - gacha_offset_x:GetInt() - margin - outline
        else
            xOffsetTarget = ScrW() - gacha_offset_x:GetInt() + margin + (outline * 2)
        end
    end)

    timer.Simple(4, function()
        prizeOpenTarget = 1
        drawPrize = true
    end)

    timer.Simple(4.5, function()
        prizeTextAlphaTarget = 255
    end)

    timer.Simple(8, function()
        prizeAlphaTarget = 0
        prizeTextAlphaTarget = 0
    end)

    timer.Simple(10, function()
        handleAngle = 0
        handleAngleTarget = 0
        outputHeight = 1
        outputHeightTarget = 1
        prizePath = 0
        prizePathTarget = 0
        prizeOpen = 0
        prizeOpenTarget = 0
        prizeAlpha = 255
        prizeAlphaTarget = 255
        prizeTextAlpha = 0
        prizeTextAlphaTarget = 0
        gachaBalls = {}
        isAnimating = false
        drawPrizeBall = false
        drawPrize = false
    end)
end
concommand.Add("startgacha", function()
    if isAnimating then return end

    prizeBall = GAMER.Prizes["doritos"]
    AnimateGacha()
end)

net.Receive("TTTGamerGachaStart", function()
    if isAnimating then return end

    local prizeId = net.ReadString()
    prizeBall = GAMER.Prizes[prizeId]
    AnimateGacha()
end)

local function DrawBall(ball)
    local circlePoly = {}
    for i = 0, 32 do
        local a = MathRad((i/32) * -360) + ball.a - (ball.x / (ballRadius + outline))
        TableInsert(circlePoly, { x = ball.x + MathSin(a) * (ballRadius + outline) + xOffset, y = ball.y + MathCos(a) * (ballRadius + outline) })
    end
    surface.SetDrawColor(0, 0, 0)
    surface.DrawPoly(circlePoly)

    local semicirclePoly = {}
    for i = 0, 16 do
        local a = MathRad((i/32) * -360) + ball.a - (ball.x / ballRadius)
        TableInsert(semicirclePoly, { x = ball.x + MathSin(a) * ballRadius + xOffset, y = ball.y + MathCos(a) * ballRadius })
    end
    surface.SetDrawColor(GAMER.Config.Rarities[ball.Rarity].Color)
    surface.DrawPoly(semicirclePoly)

    semicirclePoly = {}
    for i = 16, 32 do
        local a = MathRad((i/32) * -360) + ball.a - (ball.x / ballRadius)
        TableInsert(semicirclePoly, { x = ball.x + MathSin(a) * ballRadius + xOffset, y = ball.y + MathCos(a) * ballRadius })
    end
    surface.SetDrawColor(255, 255, 255)
    surface.DrawPoly(semicirclePoly)
end

local function DrawPrizeBall()
    local x = prizePath * (ScrW() / 2) + (1 - prizePath) * (boxMaxX - (ballRadius * 2.5))
    local y = prizePath * (ScrH() / 2) + (1 - prizePath) * (boxMaxY + bodyHeight - bodyOverlap - (ballRadius * 1.5))
    local radius = prizePath * prizeBallRadius + (1 - prizePath) * ballRadius

    local yOffset = prizeOpen * ((ScrH() / 2) + margin)

    local semicirclePoly = {}
    for i = 0, 32 do
        local outlineShift = 0
        if i % 32 == 0 then
            outlineShift = outline
        end
        local a = MathRad((i/64) * -360) + (MathPi / 2)
        TableInsert(semicirclePoly, { x = x + MathSin(a) * (radius + outline), y = y + MathCos(a) * (radius + outline) + yOffset - outlineShift})
    end
    surface.SetDrawColor(0, 0, 0)
    surface.DrawPoly(semicirclePoly)

    semicirclePoly = {}
    for i = 32, 64 do
        local outlineShift = 0
        if i % 32 == 0 then
            outlineShift = outline
        end
        local a = MathRad((i/64) * -360) + (MathPi / 2)
        TableInsert(semicirclePoly, { x = x + MathSin(a) * (radius + outline), y = y + MathCos(a) * (radius + outline) - yOffset + outlineShift})
    end
    surface.DrawPoly(semicirclePoly)

    semicirclePoly = {}
    for i = 0, 32 do
        local a = MathRad((i/64) * -360) + (MathPi / 2)
        TableInsert(semicirclePoly, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius + yOffset })
    end
    surface.SetDrawColor(GAMER.Config.Rarities[prizeBall.Rarity].Color)
    surface.DrawPoly(semicirclePoly)

    semicirclePoly = {}
    for i = 32, 64 do
        local a = MathRad((i/64) * -360) + (MathPi / 2)
        TableInsert(semicirclePoly, { x = x + MathSin(a) * radius, y = y + MathCos(a) * radius - yOffset })
    end
    surface.SetDrawColor(255, 255, 255)
    surface.DrawPoly(semicirclePoly)
end

local function DrawOutlinedRect(x, y, width, height, r, g, b)
    surface.SetDrawColor(0, 0, 0)
    surface.DrawRect(x - outline + xOffset, y - outline, width + (outline * 2), height + (outline * 2))
    surface.SetDrawColor(r, g, b)
    surface.DrawRect(x + xOffset, y, width, height)
end

local function DrawHandle()
    handleAngle = handleAngle + (handleAngleTarget - handleAngle) * 0.1

    local x = (boxMinX + boxMaxX) / 2 + xOffset
    local y = boxMaxY - bodyOverlap + frameWidth + margin + outline + (ballRadius * 1.5)
    local outlinePoly = {}
    local fillPoly = {}

    TableInsert(outlinePoly, { x = x + MathCos(handleAngle - (MathPi / 2)) * ((ballRadius * 0.5) + outline), y = y + MathSin(handleAngle - (MathPi / 2)) * ((ballRadius * 0.5) + outline) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle - (MathPi / 2)) * ballRadius * 0.5, y = y + MathSin(handleAngle - (MathPi / 2)) * ballRadius * 0.5 })
    TableInsert(outlinePoly, { x = x + MathCos(handleAngle - (MathPi / 11)) * (ballRadius + outline + 0.5), y = y + MathSin(handleAngle - (MathPi / 11)) * (ballRadius + outline + 0.5) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle - (MathPi / 12)) * ballRadius, y = y + MathSin(handleAngle - (MathPi / 12)) * ballRadius })
    TableInsert(outlinePoly, { x = x + MathCos(handleAngle + (MathPi / 11)) * (ballRadius + outline + 0.5), y = y + MathSin(handleAngle + (MathPi / 11)) * (ballRadius + outline + 0.5) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle + (MathPi / 12)) * ballRadius, y = y + MathSin(handleAngle + (MathPi / 12)) * ballRadius })
    TableInsert(outlinePoly, { x = x + MathCos(handleAngle + (MathPi / 2)) * ((ballRadius * 0.5) + outline), y = y + MathSin(handleAngle + (MathPi / 2)) * ((ballRadius * 0.5) + outline) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle + (MathPi / 2)) * ballRadius * 0.5, y = y + MathSin(handleAngle + (MathPi / 2)) * ballRadius * 0.5 })
    TableInsert(outlinePoly, { x = x + MathCos(handleAngle + MathPi - (MathPi / 11)) * (ballRadius + outline + 0.5), y = y + MathSin(handleAngle + MathPi - (MathPi / 11)) * (ballRadius + outline + 0.5) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle + MathPi - (MathPi / 12)) * ballRadius, y = y + MathSin(handleAngle + MathPi - (MathPi / 12)) * ballRadius })
    TableInsert(outlinePoly, { x = x + MathCos(handleAngle + MathPi + (MathPi / 11)) * (ballRadius + outline + 0.5), y = y + MathSin(handleAngle + MathPi + (MathPi / 11)) * (ballRadius + outline + 0.5) })
    TableInsert(fillPoly, { x = x + MathCos(handleAngle + MathPi + (MathPi / 12)) * ballRadius, y = y + MathSin(handleAngle + MathPi + (MathPi / 12)) * ballRadius })

    surface.SetDrawColor(0, 0, 0)
    surface.DrawPoly(outlinePoly)
    surface.SetDrawColor(100, 100, 100)
    surface.DrawPoly(fillPoly)
end

local function DrawOutlinedText(text, font, x, y, color, xalign, yalign)
    local alpha = color.a
    local black = Color(0, 0, 0, alpha)
    draw.SimpleText(text, font, x + outline, y, black, xalign, yalign)
    draw.SimpleText(text, font, x - outline, y, black, xalign, yalign)
    draw.SimpleText(text, font, x, y + outline, black, xalign, yalign)
    draw.SimpleText(text, font, x, y - outline, black, xalign, yalign)
    draw.SimpleText(text, font, x + outline, y + outline, black, xalign, yalign)
    draw.SimpleText(text, font, x - outline, y - outline, black, xalign, yalign)
    draw.SimpleText(text, font, x - outline, y + outline, black, xalign, yalign)
    draw.SimpleText(text, font, x + outline, y - outline, black, xalign, yalign)
    draw.SimpleText(text, font, x, y, color, xalign, yalign)
end

AddHook("HUDPaint", "Gamer_HUDPaint", function()
    if not isAnimating then return end

    xOffset = xOffset + (xOffsetTarget - xOffset) * 0.1
    handleAngle = handleAngle + (handleAngleTarget - handleAngle) * 0.05
    outputHeight = outputHeight + (outputHeightTarget - outputHeight) * 0.1
    prizePath = prizePath + (prizePathTarget - prizePath) * 0.1
    prizeOpen = prizeOpen + (prizeOpenTarget - prizeOpen) * 0.1
    prizeAlpha = prizeAlpha + (prizeAlphaTarget - prizeAlpha) * 0.1
    prizeTextAlpha = prizeTextAlpha + (prizeTextAlphaTarget - prizeTextAlpha) * 0.1

    boxMinX = gacha_offset_x:GetInt()
    boxMaxX = boxMinX + gachaWidth
    boxMinY = ((ScrH() - gachaHeight - bodyHeight + bodyOverlap) / 2) + gacha_offset_y:GetInt()
    boxMaxY = boxMinY + gachaHeight

    surface.SetDrawColor(255, 255, 255, 127)
    surface.DrawRect(boxMinX + xOffset, boxMinY, boxMaxX - boxMinX, boxMaxY - boxMinY)

    for _, ball in ipairs(gachaBalls) do
        ball.vx = ball.vx * (1 - friction)
        ball.vy = ball.vy + gravity
        ball.x = ball.x + ball.vx
        ball.y = ball.y + ball.vy

        if ball.x - ballRadius < boxMinX then
            ball.x = boxMinX + ballRadius
            ball.vx = ball.vx * -restitution
        elseif ball.x + ballRadius > boxMaxX then
            ball.x = boxMaxX - ballRadius
            ball.vx = ball.vx * -restitution
        end

        if ball.y - ballRadius < boxMinY then
            ball.y = boxMinY + ballRadius
            ball.vy = ball.vy * -restitution
        elseif ball.y + ballRadius > boxMaxY then
            ball.y = boxMaxY - ballRadius
            ball.vy = ball.vy * -restitution
        end

        DrawBall(ball)
    end

    for i = 1, #gachaBalls do
        for j = i + 1, #gachaBalls do
            local ball1 = gachaBalls[i]
            local ball2 = gachaBalls[j]

            local dx = ball2.x - ball1.x
            local dy = ball2.y - ball1.y
            local dist = MathSqrt(dx * dx + dy * dy)
            if (dist < 2 * ballRadius) then
                local angle = MathAtan2(dy, dx)
                local sin = MathSin(angle)
                local cos = MathCos(angle)

                local v1 = ball1.vx * (1 - restitution)
                local v2 = ball2.vx * (1 - restitution)
                ball1.vx = ball1.vx - v1 + v2
                ball2.vx = ball2.vx - v2 + v1
                v1 = ball1.vy * (1 - restitution)
                v2 = ball2.vy * (1 - restitution)
                ball1.vy = ball1.vy - v1 + v2
                ball2.vy = ball2.vy - v2 + v1

                local overlap = 2 * ballRadius - dist
                ball1.x = ball1.x - (overlap / 2) * cos
                ball1.y = ball1.y - (overlap / 2) * sin
                ball2.x = ball2.x + (overlap / 2) * cos
                ball2.y = ball2.y + (overlap / 2) * sin
            end
        end
    end

    -- Body
    DrawOutlinedRect(boxMinX, boxMaxY - bodyOverlap, gachaWidth, bodyHeight, 150, 50, 50)

    -- Sides
    DrawOutlinedRect(boxMinX, boxMinY, frameWidth, gachaHeight + bodyHeight - bodyOverlap, 150, 150, 150)
    DrawOutlinedRect(boxMaxX - frameWidth, boxMinY, frameWidth, gachaHeight + bodyHeight - bodyOverlap, 150, 150, 150)

    -- Top
    DrawOutlinedRect(boxMinX - margin, boxMinY, gachaWidth + margin * 2, frameWidth + margin, 150, 50, 50)

    -- Divider
    DrawOutlinedRect(boxMinX - margin, boxMaxY - bodyOverlap, gachaWidth + margin * 2, frameWidth + margin, 100, 100, 100)

    -- Handle
    DrawOutlinedRect((boxMinX + boxMaxX) / 2 - (ballRadius * 1.5), boxMaxY - bodyOverlap + frameWidth + margin + outline, ballRadius * 3, ballRadius * 3, 150, 150, 150)
    DrawHandle()

    -- Output Slot
    surface.SetDrawColor(0, 0, 0)
    surface.DrawRect(boxMaxX - (ballRadius * 4) + xOffset, boxMaxY + bodyHeight - bodyOverlap - (ballRadius * 4), ballRadius * 3, ballRadius * 4)

    -- Prize
    if drawPrize then
        surface.SetDrawColor(255, 255, 255, prizeAlpha)
        surface.SetMaterial(prizeBall.Icon)
        surface.DrawTexturedRect(ScrW() / 2 - 128, ScrH() / 2 - 128, 256, 256)
        draw.NoTexture()

        local r, g, b = GAMER.Config.Rarities[prizeBall.Rarity].Color:Unpack()
        local prizeColor = Color(r, g, b, prizeTextAlpha)

        local name = LANG.GetTranslation(prizeBall.Name)
        local desc = LANG.GetTranslation(prizeBall.Description)
        local rarity = LANG.GetTranslation(GAMER.Config.Rarities[prizeBall.Rarity].Name)
        local text = string.upper(LANG.GetParamTranslation("gamer_prize_display_format", { name = name, rarity = rarity }))

        DrawOutlinedText(text, "TraitorState", ScrW() / 2, ScrH() / 2 + 160, prizeColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        DrawOutlinedText(desc, "TraitorStateSmall", ScrW() / 2, ScrH() / 2 + 192, Color(255, 255, 255, prizeTextAlpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Prize Ball
    if drawPrizeBall then
        DrawPrizeBall()
    end

    -- Cover
    DrawOutlinedRect(boxMaxX - (ballRadius * 4), boxMaxY + bodyHeight - bodyOverlap - (ballRadius * 4), ballRadius * 3, (ballRadius * 4) * outputHeight, 200, 200, 200)
end)

-- TODO: Stop all of this when the player dies or round state changes (End, Prep, etc.)