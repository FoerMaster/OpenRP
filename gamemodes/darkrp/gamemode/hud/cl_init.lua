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


function GM:HUDPaint()
    local job = LocalPlayer():Job()
    draw.DrawText(job.DisplayName, "DebugOverlay", 5, 5, job.Color)
    draw.DrawText(string.format("Зарплата: %s денег",job.Salary), "DebugOverlay", 5, 20 , color_white)
        draw.DrawText(string.format("Кошелек: %s денег",LocalPlayer():Money()), "DebugOverlay", 5, 35 , color_white)
end