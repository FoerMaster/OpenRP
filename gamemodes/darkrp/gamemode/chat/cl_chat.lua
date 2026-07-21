function GM:ChatText(index, name, text, messageType)

    if messageType == "joinleave" or
        messageType == "namechange" or
        messageType == "servermsg" or
        messageType == "teamchange" then return true end

end

net.Receive('chat_message', function()
    local count = net.ReadUInt(8)
    local parts = {}

    for i = 1, count do
        if net.ReadBool() then
            parts[i] = net.ReadColor(false)
        else
            parts[i] = net.ReadString()
        end
    end

    chat.AddText(unpack(parts))
end)
