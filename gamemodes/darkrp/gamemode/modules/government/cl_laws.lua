roleplay.Laws = roleplay.Laws or {}

local COLORS = roleplay.Kit.Colors

local laws = {}
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

local GRADIENT_MAT = Material("gui/gradient_up")
lawsMenu = lawsMenu or nil

if (lawsMenu and IsValid(lawsMenu)) then
    lawsMenu:Remove()
end

lawsMenu = vgui.Create("DPanel")
lawsMenu:SetSize(300,200)
lawsMenu:SetPos(15,15)
lawsMenu:DockPadding(0, 0, 0, 4)
lawsMenu.Paint = function(self,w,h)
    RNDX.Rect(0, 0, w, h)
        :Rad(8)
        :Blur(1)
        :Draw()
    RNDX.Rect(0, 0, w, h):Rad(8):Color(COLORS.Background):Draw()
    RNDX.Rect(0, 60, w, 3):Rad(8):Color(COLORS.Accent):Draw()
end
lawsMenu.rows = {}

function lawsMenu:ClearLaws()
    for k, v in pairs(self.rows) do
        v:Remove()
    end
end

function lawsMenu:PerformLayout()
    self:SizeToChildren(false, true)
end

lawsMenu.Header = vgui.Create("DPanel", lawsMenu)
lawsMenu.Header:Dock(TOP)
lawsMenu.Header:SetTall(60)
lawsMenu.Header.Paint = function(self,w,h)
    RNDX.Rect(0, 0, w, h):Radii(8,8,0,0):Material(GRADIENT_MAT):Color(COLORS.AccentGradient):Draw()
    draw.SimpleText(roleplay.L('LawsHudTitle'), roleplay.Kit.Fonts.Title, 18, (h/2)-9, COLORS.Text, 0, 1)
    draw.SimpleText(roleplay.L('LawsHudCount', #laws), roleplay.Kit.Fonts.Label, 18, (h/2)+9, COLORS.TextMuted, 0, 1)
end

function lawsMenu:UpdateLaws()
    self:ClearLaws()
    if (#laws == 0) then
        lawsMenu.rows[1] = vgui.Create("DPanel", lawsMenu)
        local row = lawsMenu.rows[1]
        row:Dock(TOP)
        row:DockPadding(18, 8, 18, 9)
        row.Paint = function(self, w, h) end

        local text = vgui.Create("DLabel", row)
        text:Dock(TOP)
        text:SetFont(roleplay.Kit.Fonts.Label)
        text:SetTextColor(COLORS.TextMuted)
        text:SetText(roleplay.L('LawsHudEmpty'))

        text:SetWrap(true)
        text:SetAutoStretchVertical(true)

        function row:PerformLayout()
            self:SizeToChildren(false, true)
        end
    end
    for k, v in pairs(laws) do
        lawsMenu.rows[k] = vgui.Create("DPanel", lawsMenu)
        local row = lawsMenu.rows[k]
        row:Dock(TOP)
        row:DockPadding(28, 8, 18, 9)
        row.Paint = function(self, w, h)
            draw.SimpleText(k, roleplay.Kit.Fonts.Numerate, 10, 10, COLORS.TextMuted, 0, 0)

            if (#laws != k) then
                surface.SetDrawColor(COLORS.Separator)
                surface.DrawRect(10, h-1, w-20, 1)
            end
        end

        local text = vgui.Create("DLabel", row)
        text:Dock(TOP)
        text:SetFont(roleplay.Kit.Fonts.Label)
        text:SetTextColor(COLORS.Text)
        text:SetText(v)

        text:SetWrap(true)
        text:SetAutoStretchVertical(true)

        function row:PerformLayout()
            self:SizeToChildren(false, true)
        end
    end
end

lawsMenu:UpdateLaws()

net.Receive('laws', function()
    local count = net.ReadUInt(4)

    laws = {}

    for i = 1, count do
        laws[i] = net.ReadString()
    end

    lawsMenu:UpdateLaws()
end)

net.Receive('laws_edit', function()
    if IsValid(panel) then
        panel:Remove()
    end

    panel = build()
end)
