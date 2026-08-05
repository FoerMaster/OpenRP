roleplay.HUD = roleplay.HUD or {}

local COLORS = roleplay.Kit.Colors

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

    if show != cursorShown then
        cursorShown = show
        gui.EnableScreenClicker(show)
    end
end

-- TODO: заглушка на дебажном шрифте, переделать на нормальный худ
function roleplay.HUD.Draw()
    local ply = LocalPlayer()
    local job = ply:Job()
    local health = ply:Health() / ply:GetMaxHealth()

    RNDX.Circle(55, ScrH()-55, 40):Blur(0.5):Draw()
    RNDX.Circle(55, ScrH()-55, 40):Color(COLORS.BackgroundSoft):Draw()

    RNDX.Circle(55, ScrH()-55, 40):Color(COLORS.Track):Outline(10):Angles(0, 360):Draw()
    RNDX.Circle(55, ScrH()-55, 25):Color(COLORS.Track):Angles(0, 360):Draw()

    RNDX.Circle(55, ScrH()-55, 40):Color(COLORS.Health):Outline(10):Angles(90, 90 + 360 * health):Draw()
    RNDX.Circle(55, ScrH()-55, 25):Color(COLORS.Armor):Angles(90, 90 + 360 * health):Draw()

    draw.DrawText(job.DisplayName, "DebugOverlay", 5, 5, job.Color)
    draw.DrawText(roleplay.L('HudSalary', job.Salary), "DebugOverlay", 5, 20, COLORS.Text)
    draw.DrawText(roleplay.L('HudWallet', ply:Money()), "DebugOverlay", 5, 35, COLORS.Text)
end
