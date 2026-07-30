function GM:HUDShouldDraw(name)
    if  name == "CHudHealth" or
        name == "CHudBattery" or
        name == "CHudAmmo" or
        name == "CHudCrosshair" or
        name == "CHudCloseCaption" or
        name == "CHudDamageIndicator" or
        name == "CHudHistoryResource" or
        name == "CHudDeathNotice" or
        name == "CHudGeiger" or
        name == "CHudHintDisplay" or
        name == "CHudMessage" or
        name == "CHudPoisonDamageIndicator" or
        name == "CHudSecondaryAmmo" or
        name == "CHudSquadStatus" or
        name == "CHudTrain" or
        name == "CHudVehicle" or
        name == "CHudWeapon" or
        name == "CHudZoom" or
        name == "CHUDQuickInfo" or
        name == "CTargetID" or
        name == "CHudSuitPower" then
        return false
    end
    return true
end


local cursorShown = false
local cursorLocked = false
local togglePressed = false

hook.Add('Think', 'Cursor', function()
    local ply = LocalPlayer()
    if (!IsValid(ply) or ply:IsTyping()) then return end

    local toggle = input.IsKeyDown(KEY_F3)

    if (toggle and !togglePressed) then
        cursorLocked = !cursorLocked
    end

    togglePressed = toggle

    local show = cursorLocked or input.IsKeyDown(KEY_LALT) or input.IsKeyDown(KEY_C)

    if (show != cursorShown) then
        cursorShown = show
        gui.EnableScreenClicker(show)
    end
end)

function GM:HUDPaint()
    local job = LocalPlayer():Job()
    draw.DrawText(job.DisplayName, "DebugOverlay", 5, 5, job.Color)
    draw.DrawText(string.format("Зарплата: %s денег",job.Salary), "DebugOverlay", 5, 20 , color_white)
    draw.DrawText(string.format("Кошелек: %s денег",LocalPlayer():Money()), "DebugOverlay", 5, 35 , color_white)
end