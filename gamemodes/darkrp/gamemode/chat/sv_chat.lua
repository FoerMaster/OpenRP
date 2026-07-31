roleplay.Chat = roleplay.Chat or {}
roleplay.Chat.Commands = {}

util.AddNetworkString('chat_message')

function roleplay.Chat.AddCommand(command, callback)
    roleplay.Chat.Commands[command] = callback
end

function PLAYER:SendChat(...)
    local count = select('#', ...)

    net.Start('chat_message')
        net.WriteUInt(count, 8)

        for i = 1, count do
            local part = select(i, ...)

            if IsColor(part) then
                net.WriteBool(true)
                net.WriteColor(part, false)
            else
                net.WriteBool(false)
                net.WriteString(tostring(part))
            end
        end
    net.Send(self)
end

function roleplay.Chat.Broadcast(...)
    for _, ply in player.Iterator() do
        ply:SendChat(...)
    end
end

function PLAYER:ChatError(key, ...)
    self:SendChat(roleplay.Colors.Error, roleplay.L(key, ...))
end

function PLAYER:ChatSuccess(key, ...)
    self:SendChat(roleplay.Colors.Success, roleplay.L(key, ...))
end

function roleplay.FindPlayer(argument)
    if (!argument or argument == '') then return nil end

    local id = tonumber(argument)

    if (id) then
        local ply = Player(id)
        return IsValid(ply) and ply or nil
    end

    local query = string.lower(argument)
    local found

    for _, ply in player.Iterator() do
        if (string.find(string.lower(ply:Nick()), query, 1, true)) then
            if (found) then return nil, true end

            found = ply
        end
    end

    return found
end

function roleplay.ParseAmount(argument)
    local amount = tonumber(argument)
    if (!amount) then return nil end

    amount = math.floor(amount)
    if (amount <= 0) then return nil end

    return amount
end

function roleplay.Chat.RunCommand(sender, text)
    local arguments = string.Explode("%s+", text, true)
    local command = string.lower(string.sub(table.remove(arguments, 1), 2))
    local noCommand = table.concat(arguments, " ")

    local callback = roleplay.Chat.Commands[command]

    if (callback == nil) then
        sender:ChatError('CommandNotFound')
        return
    end

    if (hook.Run('OnPlayerChatCommand', sender, command, arguments, noCommand) == false) then return end

    if (sender.LastCommand and sender.LastCommand > CurTime()) then
        sender:ChatError("StopCommandSpamming")
        sender.LastCommand = CurTime() + roleplay.Config.CommandDelay:GetInt()
        return
    end

    sender.LastCommand = CurTime() + roleplay.Config.CommandDelay:GetInt()

    callback(sender, arguments, noCommand)

    hook.Run('PlayerChatCommand', sender, command, arguments, noCommand)
end
