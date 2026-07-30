roleplay.Kit = roleplay.Kit or {}

local FONT_CACHE = {}

local function createFont(family, size, bold)
    local key = family .. size .. (bold and 'B' or 'R')
    local name = FONT_CACHE[key]

    if (name) then return name end

    name = 'OpenRP_' .. key

    surface.CreateFont(name, {
        font = family,
        extended = true,
        size = size,
        weight = bold and 700 or 500,
        antialias = true
    })

    FONT_CACHE[key] = name

    return name
end

roleplay.Kit.FontConfig = {
    Button = { family = 'Montserrat', size = 17, bold = true },
    Label = { family = 'Onest', size = 18, bold = false },
    Title = { family = 'Onest', size = 16, bold = true },
}

roleplay.Kit.Fonts = {}

for role, cfg in pairs(roleplay.Kit.FontConfig) do
    roleplay.Kit.Fonts[role] = createFont(cfg.family, cfg.size, cfg.bold)
end

local MATERIAL = Material('models/openrp/ui_kit.png', 'noclamp smooth')

local TEX_W, TEX_H = 500, 500
local SPRITE_W, SPRITE_H = 39, 32
local SEGMENT = 13

roleplay.Kit.ButtonHeight = SPRITE_H

local U0, U1, U2, U3 = 0, SEGMENT / TEX_W, (SPRITE_W - SEGMENT) / TEX_W, SPRITE_W / TEX_W
local V0, V1 = 0, SPRITE_H / TEX_H

function roleplay.Kit.DrawButton(x, y, w, h, color)
    if (w <= 0 or h <= 0) then return end

    surface.SetMaterial(MATERIAL)
    surface.SetDrawColor(color)

    surface.DrawTexturedRectUV(x, y, SEGMENT, h, U0, V0, U1, V1)
    surface.DrawTexturedRectUV(x + w - SEGMENT, y, SEGMENT, h, U2, V0, U3, V1)
    surface.DrawTexturedRectUV(x + SEGMENT, y, math.max(w - SEGMENT * 2, 0), h, U1, V0, U2, V1)
end

local SKIN = table.Copy(derma.GetNamedSkin('Default'))

local BUTTON_DISABLED = Color(255, 255, 255, 120)
local BUTTON_PRESSED = Color(0, 0, 0, 70)
local BUTTON_HOVERED = Color(255, 255, 255, 45)
local BUTTON_GLOW = Color(28, 91, 232, 30)

function SKIN:PaintButton(panel, w, h)
    if (panel.m_bBackground == false) then return end

    roleplay.Kit.DrawButton(0, 0, w, h, panel:IsEnabled() and color_white or BUTTON_DISABLED)

    if (panel:IsEnabled()) then
        if (panel.Depressed or panel:GetToggle()) then
            roleplay.Kit.DrawButton(0, 0, w, h, BUTTON_PRESSED)
        elseif (panel.Hovered) then
            roleplay.Kit.DrawButton(0, 0, w, h, BUTTON_HOVERED)
        end
    end

    RNDX.Rect(0, 0, w, h):Rad(13):Color(BUTTON_GLOW):Shadow(15, 0, 0, 0):Draw()
end

derma.DefineSkin('OpenRP', 'OpenRP UI Kit', SKIN)
