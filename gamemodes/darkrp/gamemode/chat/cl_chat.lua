roleplay.Chat = roleplay.Chat or {}

roleplay.Chat.HiddenTypes = {
    ['joinleave'] = true,
    ['namechange'] = true,
    ['servermsg'] = true,
    ['teamchange'] = true
}

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
