roleplay.Laws = roleplay.Laws or {}

local TITLE_COLOR = Color(120, 180, 255)
local LINE_HEIGHT = 15
local MARGIN = 5

local laws = {}
local lines = {}
local panel

local function build()
    local frame = vgui.Create('DFrame')
    frame:SetSize(420, 320)
    frame:Center()
    frame:SetTitle(roleplay.L('LawsEditTitle'))
    frame:MakePopup()

    local save = vgui.Create('DButton', frame)
    save:Dock(BOTTOM)
    save:DockMargin(5, 0, 5, 5)
    save:SetTall(24)
    save:SetText(roleplay.L('LawsSave'))

    local bottom = vgui.Create('DPanel', frame)
    bottom:Dock(BOTTOM)
    bottom:DockMargin(5, 0, 5, 5)
    bottom:DockPadding(4, 4, 4, 4)
    bottom:SetTall(60)

    local entry = vgui.Create('DTextEntry', bottom)
    entry:Dock(TOP)
    entry:SetTall(22)

    local add = vgui.Create('DButton', bottom)
    add:Dock(TOP)
    add:DockMargin(0, 4, 0, 0)
    add:SetTall(22)

    local list = vgui.Create('DScrollPanel', frame)
    list:Dock(FILL)
    list:DockMargin(5, 5, 5, 5)

    local working = table.Copy(laws)

    local function refresh()
        list:Clear()

        for i, law in ipairs(working) do
            local row = vgui.Create('DPanel', list)
            row:Dock(TOP)
            row:DockMargin(0, 0, 0, 4)
            row:SetTall(24)

            local remove = vgui.Create('DButton', row)
            remove:Dock(RIGHT)
            remove:SetWide(80)
            remove:SetText(roleplay.L('LawsRemove'))
            remove.DoClick = function()
                table.remove(working, i)
                refresh()
            end

            local label = vgui.Create('DLabel', row)
            label:Dock(FILL)
            label:DockMargin(4, 0, 4, 0)
            label:SetText(i .. '. ' .. law)
            label:SetDark(true)
        end

        local limit = roleplay.MaxLaws()

        add:SetText(roleplay.L('LawsAdd') .. ' (' .. #working .. '/' .. limit .. ')')
        add:SetEnabled(#working < limit)
    end

    add.DoClick = function()
        local text = string.Trim(entry:GetValue())
        if text == '' then return end

        working[#working + 1] = text
        entry:SetValue('')

        refresh()
    end

    save.DoClick = function()
        net.Start('laws_edit')
            net.WriteUInt(#working, 4)

            for _, law in ipairs(working) do
                net.WriteString(law)
            end
        net.SendToServer()

        frame:Close()
    end

    refresh()

    return frame
end

-- TODO: заглушка на дебажном шрифте, переделать вместе с основным худом
function roleplay.Laws.Draw()
    if #lines == 0 then return end

    local x = ScrW() - MARGIN

    draw.DrawText(roleplay.L('LawsTitle'), 'DebugOverlay', x, MARGIN, TITLE_COLOR, TEXT_ALIGN_RIGHT)

    for i, line in ipairs(lines) do
        draw.DrawText(line, 'DebugOverlay', x, MARGIN + i * LINE_HEIGHT, color_white, TEXT_ALIGN_RIGHT)
    end
end

net.Receive('laws', function()
    local count = net.ReadUInt(4)

    laws = {}
    lines = {}

    for i = 1, count do
        laws[i] = net.ReadString()
        lines[i] = i .. '. ' .. laws[i]
    end
end)

net.Receive('laws_edit', function()
    if IsValid(panel) then
        panel:Remove()
    end

    panel = build()
end)
