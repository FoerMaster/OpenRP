util.AddNetworkString('laws')
util.AddNetworkString('laws_edit')

roleplay.Laws = roleplay.Laws or {}

local ANNOUNCE_COLOR = Color(120, 180, 255)

local DEFAULT_KEYS = {
    'LawDefaultKill',
    'LawDefaultRaid',
    'LawDefaultWeapon',
    'LawDefaultPolice'
}

local laws = {}
local nextEditAt = 0

local function write()
    net.WriteUInt(#laws, 4)
    for _, law in ipairs(laws) do
        net.WriteString(law)
    end
end

function roleplay.Laws.Setup()
    laws = {}
    for _, key in ipairs(DEFAULT_KEYS) do
        laws[#laws + 1] = roleplay.L(key)
    end
end

function roleplay.Laws.Sync(ply)
    net.Start('laws')
        write()
    net.Send(ply)
end

local function read(ply)
    local count = net.ReadUInt(4)
    local incoming = {}
    for i = 1, count do
        incoming[i] = string.Trim(net.ReadString())
    end

    local max = roleplay.MaxLaws()
    if count > max then
        ply:ChatError('LawsLimit', max)
        return nil
    end

    local limit = roleplay.Config.LawMaxLength:GetInt()
    for _, law in ipairs(incoming) do
        if law == '' then
            ply:ChatError('LawsEmpty')
            return nil
        end

        local length = utf8.len(law)
        if (!length or length > limit) then
            ply:ChatError('LawsTooLong', limit)
            return nil
        end
    end

    return incoming
end

net.Receive('laws_edit', function(_, ply)
    if nextEditAt > CurTime() then
        ply:ChatError('LawsEditCooldown', math.ceil(nextEditAt - CurTime()))
        return
    end

    local incoming = read(ply)
    if !incoming then return end

    local allow, custom = hook.Run('OnPlayerEditLaws', ply, incoming)
    if (!allow) then
        ply:ChatError('LawsCantEdit')
        return
    end

    laws = custom or incoming
    nextEditAt = CurTime() + roleplay.Config.LawsEditDelay:GetInt()

    net.Start('laws')
        write()
    net.Broadcast()

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('LawsChanged'))

    hook.Run('PlayerEditedLaws', ply, laws)
end)

roleplay.Chat.AddCommand('editlaws', function(sender)
    if nextEditAt > CurTime() then
        sender:ChatError('LawsEditCooldown', math.ceil(nextEditAt - CurTime()))
        return
    end

    if (!hook.Run('OnPlayerEditLaws', sender, laws)) then
        sender:ChatError('LawsCantEdit')
        return
    end

    net.Start('laws_edit')
    net.Send(sender)
end)
