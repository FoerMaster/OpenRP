local WIDTH = 300
local MARGIN = 20
local PADDING = 12
local HEADER = 68
local ROW_HEIGHT = 36
local ROW_GAP = 4
local AVATAR = 28

local BG_COLOR = Color(30, 30, 30, 250)
local ROW_COLOR = Color(45, 45, 45, 255)
local ROW_HOVER_COLOR = Color(62, 62, 62, 255)
local FILL_COLOR = Color(28, 91, 232, 255)
local SUBTITLE_COLOR = Color(150, 150, 150)
local VOTES_COLOR = Color(215, 215, 215)

local FONT_TITLE = roleplay.Kit.Fonts.Title
local FONT_LABEL = roleplay.Kit.Fonts.Label

local state = {
    phase = roleplay.Election.PHASE_NONE,
    endsAt = 0,
    revealed = false,
    candidates = {}
}

local panel
local rows = {}

function roleplay.Election.Send(candidate)
    if state.phase != roleplay.Election.PHASE_VOTING then return end
    if state.revealed then return end
    if !IsValid(candidate) then return end

    net.Start('election')
        net.WriteEntity(candidate)
    net.SendToServer()
end

local function buildRow(parent, ply)
    local row = vgui.Create('DButton', parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, ROW_GAP)
    row:SetTall(ROW_HEIGHT)
    row:SetText('')
    row.player = ply
    row.votes = 0
    row.share = 0

    row.Paint = function(self, w, h)
        local pickable = state.phase == roleplay.Election.PHASE_VOTING and !state.revealed

        RNDX.Rect(0, 0, w, h):Rad(6):Color(self.Hovered and pickable and ROW_HOVER_COLOR or ROW_COLOR):Draw()

        if (state.revealed and self.share > 0) then
            RNDX.Rect(0, 0, w * self.share, h):Rad(6):Color(FILL_COLOR):Draw()
        end

        draw.SimpleText(IsValid(self.player) and self.player:Nick() or '', FONT_LABEL, ROW_HEIGHT, h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        if state.revealed then
            draw.SimpleText(self.votes, FONT_LABEL, w - 10, h * 0.5, VOTES_COLOR, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    row.DoClick = function(self)
        roleplay.Election.Send(self.player)
    end

    local avatar = vgui.Create('AvatarImage', row)
    avatar:SetSize(AVATAR, AVATAR)
    avatar:SetPos(4, (ROW_HEIGHT - AVATAR) * 0.5)
    avatar:SetPlayer(ply, 32)
    avatar:SetMouseInputEnabled(false)

    return row
end

local function build()
    local frame = vgui.Create('DPanel')
    frame:SetMouseInputEnabled(true)
    frame:DockPadding(PADDING, PADDING, PADDING, PADDING)
    frame.Paint = function(_, w, h)
        RNDX.Rect(0, 0, w, h):Rad(8):Color(BG_COLOR):Draw()
    end

    local title = vgui.Create('DLabel', frame)
    title:Dock(TOP)
    title:SetTall(18)
    title:SetFont(FONT_TITLE)
    title:SetColor(color_white)
    title:SetText(roleplay.L('ElectionTitle'))

    local subtitle = vgui.Create('DLabel', frame)
    subtitle:Dock(TOP)
    subtitle:DockMargin(0, 2, 0, 8)
    subtitle:SetTall(16)
    subtitle:SetFont(FONT_LABEL)
    subtitle:SetColor(SUBTITLE_COLOR)
    subtitle.Think = function(self)
        local key = state.phase == roleplay.Election.PHASE_VOTING and 'ElectionVotingTimer' or 'ElectionSignupTimer'

        self:SetText(roleplay.L(key, math.ceil(math.max(state.endsAt - CurTime(), 0))))
    end

    frame.list = vgui.Create('DPanel', frame)
    frame.list:Dock(FILL)
    frame.list:SetPaintBackground(false)

    return frame
end

local function matches()
    if #rows != #state.candidates then return false end

    for i, entry in ipairs(state.candidates) do
        if rows[i].player != entry.player then return false end
    end

    return true
end

function roleplay.Election.Refresh()
    if #state.candidates == 0 then
        if IsValid(panel) then
            panel:Remove()
        end

        rows = {}
        return
    end

    if !IsValid(panel) then
        panel = build()
        rows = {}
    end

    if !matches() then
        panel.list:Clear()
        rows = {}

        for i, entry in ipairs(state.candidates) do
            rows[i] = buildRow(panel.list, entry.player)
        end
    end

    local total = 0

    for _, entry in ipairs(state.candidates) do
        total = total + entry.votes
    end

    for i, entry in ipairs(state.candidates) do
        rows[i].votes = entry.votes
        rows[i].share = total > 0 and entry.votes / total or 0
    end

    local height = HEADER + #rows * (ROW_HEIGHT + ROW_GAP) - ROW_GAP

    panel:SetSize(WIDTH, height)
    panel:SetPos(MARGIN, ScrH() - height - MARGIN)
    panel:InvalidateLayout(true)
end

net.Receive('election', function()
    local phase = net.ReadUInt(2)
    local remaining = net.ReadUInt(12)
    local revealed = net.ReadBool()
    local count = net.ReadUInt(8)

    local candidates = {}

    for _ = 1, count do
        local ply = net.ReadEntity()
        local votes = revealed and net.ReadUInt(8) or 0

        if IsValid(ply) then
            candidates[#candidates + 1] = { player = ply, votes = votes }
        end
    end

    if (phase == roleplay.Election.PHASE_VOTING and state.phase != phase) then
        surface.PlaySound('buttons/button17.wav')
    end

    state.phase = phase
    state.endsAt = CurTime() + remaining
    state.revealed = revealed
    state.candidates = candidates

    roleplay.Election.Refresh()
end)
