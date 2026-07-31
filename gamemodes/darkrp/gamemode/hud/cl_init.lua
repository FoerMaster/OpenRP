roleplay.HUD = roleplay.HUD or {}

roleplay.HUD.Hidden = {
    ['CHudHealth'] = true,
    ['CHudBattery'] = true,
    ['CHudAmmo'] = true,
    ['CHudCrosshair'] = true,
    ['CHudCloseCaption'] = true,
    ['CHudDamageIndicator'] = true,
    ['CHudHistoryResource'] = true,
    ['CHudDeathNotice'] = true,
    ['CHudGeiger'] = true,
    ['CHudHintDisplay'] = true,
    ['CHudMessage'] = true,
    ['CHudPoisonDamageIndicator'] = true,
    ['CHudSecondaryAmmo'] = true,
    ['CHudSquadStatus'] = true,
    ['CHudTrain'] = true,
    ['CHudVehicle'] = true,
    ['CHudWeapon'] = true,
    ['CHudZoom'] = true,
    ['CHUDQuickInfo'] = true,
    ['CTargetID'] = true,
    ['CHudSuitPower'] = true
}

local cursorShown = false
local cursorLocked = false
local togglePressed = false

function roleplay.HUD.UpdateCursor()
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
end

-- TODO: заглушка на дебажном шрифте, переделать на нормальный худ
function roleplay.HUD.Draw()
    local ply = LocalPlayer()
    local job = ply:Job()

    draw.DrawText(job.DisplayName, "DebugOverlay", 5, 5, job.Color)
    draw.DrawText(string.format("Зарплата: %s денег", job.Salary), "DebugOverlay", 5, 20, color_white)
    draw.DrawText(string.format("Кошелек: %s денег", ply:Money()), "DebugOverlay", 5, 35, color_white)
end
