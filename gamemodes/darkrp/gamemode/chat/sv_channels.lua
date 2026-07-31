local NAME_COLOR = Color(200, 200, 200)
local PRIVATE_COLOR = Color(255, 130, 220)

local advertReadyAt = {}

local CHANNELS = {
    ic = {
        Local = true
    },
    looc = {
        Tag = '[LOOC] ',
        Color = Color(120, 200, 255),
        Local = true
    },
    me = {
        Tag = '[ME] ',
        Color = Color(190, 150, 255),
        Local = true,
        Action = true
    },
    ooc = {
        Tag = '[OOC] ',
        Color = Color(120, 200, 255)
    },
    advert = {
        Tag = '[ADVERT] ',
        Color = Color(255, 190, 90)
    },
    call = {
        Tag = '[911] ',
        Color = Color(255, 90, 90),
        Flag = JOB_FLAG_RECEIVE_911
    }
}

local function nearby(sender)
    local radius = roleplay.Config.TalkRadius:GetInt()
    local origin = sender:GetPos()
    local out = {}

    for _, ply in player.Iterator() do
        if (ply:GetPos():DistToSqr(origin) <= radius * radius) then
            out[#out + 1] = ply
        end
    end

    return out
end

local function withFlag(sender, flag)
    local out = { sender }

    for _, ply in player.Iterator() do
        if (ply != sender and ply:HasJobFlag(flag)) then
            out[#out + 1] = ply
        end
    end

    return out
end

local function receivers(sender, channel)
    if (channel.Local) then return nearby(sender) end
    if (channel.Flag) then return withFlag(sender, channel.Flag) end

    return player.GetAll()
end

function roleplay.Chat.Send(sender, id, text)
    local channel = CHANNELS[id]
    if (!channel) then return end

    text = string.Trim(text)
    if (text == '') then
        sender:ChatError('ChatEmpty')
        return
    end

    local targets = receivers(sender, channel)

    if (#targets < 2 and channel.Flag) then
        sender:ChatError('ChatNoReceivers')
        return
    end

    for _, ply in ipairs(targets) do
        if (channel.Action) then
            ply:SendChat(channel.Color, channel.Tag, sender:Nick() .. ' ' .. text)
        elseif (channel.Tag) then
            ply:SendChat(channel.Color, channel.Tag, NAME_COLOR, sender:Nick() .. ': ', color_white, text)
        else
            ply:SendChat(NAME_COLOR, sender:Nick() .. ': ', color_white, text)
        end
    end
end

function roleplay.Chat.SendPrivate(sender, target, text)
    text = string.Trim(text)
    if (text == '') then
        sender:ChatError('ChatEmpty')
        return
    end

    local header = string.format('[PM] %s → %s: ', sender:Nick(), target:Nick())

    sender:SendChat(PRIVATE_COLOR, header, color_white, text)
    target:SendChat(PRIVATE_COLOR, header, color_white, text)
end

function roleplay.Chat.Route(sender, text)
    text = string.Trim(text)
    if (text == '') then return end

    if (string.StartsWith(text, '//')) then
        roleplay.Chat.Send(sender, 'ooc', string.sub(text, 3))
        return
    end

    if (string.StartsWith(text, '/')) then
        roleplay.Chat.RunCommand(sender, text)
        return
    end

    roleplay.Chat.Send(sender, 'ic', text)
end

roleplay.Chat.AddCommand('ooc', function(sender, arguments, noCommand)
    roleplay.Chat.Send(sender, 'ooc', noCommand)
end)

roleplay.Chat.AddCommand('looc', function(sender, arguments, noCommand)
    roleplay.Chat.Send(sender, 'looc', noCommand)
end)

roleplay.Chat.AddCommand('me', function(sender, arguments, noCommand)
    roleplay.Chat.Send(sender, 'me', noCommand)
end)

roleplay.Chat.AddCommand('advert', function(sender, arguments, noCommand)
    local text = string.Trim(noCommand)

    if (text == '') then
        sender:ChatError('ChatEmpty')
        return
    end

    local steamID = sender:SteamID()
    local readyAt = advertReadyAt[steamID]

    if (readyAt and readyAt > CurTime()) then
        sender:ChatError('AdvertCooldown', math.ceil(readyAt - CurTime()))
        return
    end

    local cost = roleplay.Config.AdvertCost:GetInt()

    if (!sender:CanAfford(cost)) then
        sender:ChatError('NotEnoughMoney')
        return
    end

    roleplay.Chat.Send(sender, 'advert', text)

    sender:AddMoney(-cost)
    advertReadyAt[steamID] = CurTime() + roleplay.Config.AdvertDelay:GetInt()

    sender:SendChat(roleplay.Colors.Money, roleplay.L('AdvertPaid', cost))
end)

roleplay.Chat.AddCommand('911', function(sender, arguments, noCommand)
    roleplay.Chat.Send(sender, 'call', noCommand)
end)

roleplay.Chat.AddCommand('pm', function(sender, arguments)
    local target, ambiguous = roleplay.FindPlayer(arguments[1])

    if (ambiguous) then
        sender:ChatError('ChatAmbiguousName')
        return
    end

    if (!target) then
        sender:ChatError('PlayerNotFound')
        return
    end

    if (target == sender) then
        sender:ChatError('ChatPrivateSelf')
        return
    end

    roleplay.Chat.SendPrivate(sender, target, table.concat(arguments, ' ', 2))
end)
