roleplay.Vote = roleplay.Vote or {
    votings = {},
    w = 200,
    x = ScrW() - 210,
    y = (ScrH() / 2) - 100
}

local MAX_LINES = 5
local FONT = roleplay.Kit.Fonts.Label
local META_FONT = roleplay.Kit.Fonts.Label
local CHROME = 96

function roleplay.Vote.Active()
    return roleplay.Vote.votings[1]
end

local UTF8_CHAR = '[%z\1-\127\194-\244][\128-\191]*'

local function tokenize(text, width)
    local tokens = {}

    for i, word in ipairs(string.Explode(' ', text)) do
        local part = ''
        local head = true

        for char in string.gmatch(word, UTF8_CHAR) do
            if (part != '' and surface.GetTextSize(part .. char) > width) then
                table.insert(tokens, { text = part, glue = !head or i == 1 })
                part = char
                head = false
            else
                part = part .. char
            end
        end

        table.insert(tokens, { text = part, glue = !head or i == 1 })
    end

    return tokens
end

local function fit(text, width)
    surface.SetFont(FONT)

    local ellipsis, lineHeight = surface.GetTextSize('…')
    local out = {}
    local line = ''
    local lines = 1

    for _, token in ipairs(tokenize(text, width)) do
        local sep = token.glue and '' or ' '
        local limit = lines == MAX_LINES and width - ellipsis or width
        local test = line == '' and token.text or line .. sep .. token.text

        if (line == '' or surface.GetTextSize(test) <= limit) then
            line = test
        elseif lines == MAX_LINES then
            table.insert(out, line .. '…')
            return table.concat(out, '\n'), MAX_LINES * lineHeight
        else
            table.insert(out, line)
            lines = lines + 1
            line = token.text
        end
    end

    table.insert(out, line)

    return table.concat(out, '\n'), lines * lineHeight
end

local function build()
    local panel = vgui.Create('DPanel')
    panel:SetMouseInputEnabled(true)
    panel:DockPadding(10, 8, 10, 10)
    panel.Paint = function(_, w, h)
        RNDX.Rect(0, 0, w, h):Rad(8):Color(30, 30, 30, 250):Draw()

        local voting = roleplay.Vote.Active()
        RNDX.Circle(16, 16, 8):Color(255, 255, 255, 5):Outline(8):Angles(0, 360):Draw()
        RNDX.Circle(16, 16, 8):Color(28, 91, 232, 255):Outline(8):Angles(0, 0 + (360 * math.max(voting.endsAt - CurTime(), 0) / voting.delay)):Draw()
    end

    local head = vgui.Create('DPanel', panel)
    head:Dock(TOP)
    head:SetTall(15)
    head:DockPadding(20, -2, 0, 2)
    head:SetPaintBackground(false)

    panel.time = vgui.Create('DLabel', head)
    panel.time:Dock(LEFT)
    panel.time:SetFont(META_FONT)
    panel.time.Think = function(self)
        local voting = roleplay.Vote.Active()
        if !voting then return end

        self:SetText(roleplay.L('VoteSeconds', math.ceil(math.max(voting.endsAt - CurTime(), 0))))
        self:SizeToContents()
    end

    local buttons = vgui.Create('DPanel', panel)
    buttons:Dock(BOTTOM)
    buttons:SetTall(roleplay.Kit.ButtonHeight)
    buttons:SetPaintBackground(false)

    panel.no = vgui.Create('DButton', buttons)
    panel.no:Dock(RIGHT)
    panel.no:DockMargin(6, 0, 0, 0)
    panel.no:SetText(roleplay.L('VoteNo'))
    panel.no:SetFont(roleplay.Kit.Fonts.Button)
    panel.no:SetTextColor(color_white)
    panel.no:SetSkin('OpenRP')
    panel.no.DoClick = function()
        roleplay.Vote.Send(false)
    end

    panel.yes = vgui.Create('DButton', buttons)
    panel.yes:Dock(FILL)
    panel.yes:SetText(roleplay.L('VoteYes'))
    panel.yes:SetFont(roleplay.Kit.Fonts.Button)
    panel.yes:SetTextColor(color_white)
    panel.yes:SetSkin('OpenRP')
    panel.yes.DoClick = function()
        roleplay.Vote.Send(true)
    end

    panel.text = vgui.Create('DLabel', panel)
    panel.text:Dock(TOP)
    panel.text:DockMargin(0, 8, 0, 8)
    panel.text:SetFont(FONT)
    panel.text:SetContentAlignment(5)
    panel.text:SetWrap(true)
    panel.text:SetColor(color_white)

    return panel
end

function roleplay.Vote.Refresh()
    local voting = roleplay.Vote.Active()

    if !voting then
        if IsValid(roleplay.Vote.panel) then
            roleplay.Vote.panel:Remove()
        end
        return
    end

    if !IsValid(roleplay.Vote.panel) then
        roleplay.Vote.panel = build()
    end

    local text, height = fit(voting.text, roleplay.Vote.w - 20)

    roleplay.Vote.panel.text:SetText(text)
    roleplay.Vote.panel.text:SetTall(height)
    roleplay.Vote.panel.no:SetWide((roleplay.Vote.w - 26) * 0.5)

    roleplay.Vote.panel:SetSize(roleplay.Vote.w, CHROME + height)
    roleplay.Vote.panel:InvalidateLayout(true)
    roleplay.Vote.panel:SetPos(roleplay.Vote.x or ScrW() * 0.5 - roleplay.Vote.w * 0.5, roleplay.Vote.y)
end

function roleplay.Vote.Remove(id)
    for i, voting in ipairs(roleplay.Vote.votings) do
        if voting.id == id then
            table.remove(roleplay.Vote.votings, i)
            roleplay.Vote.Refresh()
            return
        end
    end
end

function roleplay.Vote.Prune()
    local changed = false

    for i = #roleplay.Vote.votings, 1, -1 do
        if roleplay.Vote.votings[i].endsAt <= CurTime() then
            table.remove(roleplay.Vote.votings, i)
            changed = true
        end
    end

    if changed then
        roleplay.Vote.Refresh()
    end
end

function roleplay.Vote.Send(choice)
    local voting = roleplay.Vote.Active()
    if !voting then return end

    net.Start('voting')
        net.WriteString(voting.id)
        net.WriteBool(choice)
    net.SendToServer()

    table.remove(roleplay.Vote.votings, 1)
    roleplay.Vote.Refresh()
end

net.Receive('voting', function()
    local id = net.ReadString()
    local text = net.ReadString()
    local delay = net.ReadUInt(8)

    table.insert(roleplay.Vote.votings, {
        id = id,
        text = text,
        delay = delay,
        endsAt = CurTime() + delay
    })

    roleplay.Vote.Refresh()

    surface.PlaySound('buttons/button17.wav')
end)

net.Receive('voting_end', function()
    roleplay.Vote.Remove(net.ReadString())
end)

function roleplay.Vote.HandleBind(bind, pressed)
    if (!roleplay.Vote.Active() or !pressed) then return end

    if bind == 'gm_showhelp' then
        roleplay.Vote.Send(true)
        return true
    end

    if bind == 'gm_showteam' then
        roleplay.Vote.Send(false)
        return true
    end
end
