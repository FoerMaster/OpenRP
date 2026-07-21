GM.ChatCommands = {}

util.AddNetworkString('chat_message')

function chat.AddCommand(command, fallback)
    (GAMEMODE or GM).ChatCommands[command] = fallback
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

function GM:PlayerSay(sender, text, teamChat)
    if string.StartsWith(text, '/') then
        local arguments = string.Explode("%s+", text, true)
        local command = string.lower(string.sub(table.remove(arguments, 1), 2))
        local noCommand = table.concat(arguments, " ")

        local callback = self.ChatCommands[command]
        if callback != nil then
            if (hook.Run('OnPlayerChatCommand', sender, command, arguments, noCommand) == false) then
                return ""
            end

            callback(sender, arguments, noCommand)

            hook.Run('PlayerChatCommand', sender, command, arguments, noCommand)
        else
            sender:SendChat(Color(255, 69, 69), self.Lang['CommandNotFound'])
        end

        return ""
    end
    return text
end
