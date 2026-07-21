function PLAYER:HasJobFlag(flag)
    local classTable = player_manager.GetPlayerClassTable(self)
    local flags = classTable.Flags or {}

    return table.HasValue(flags, flag)
end

function PLAYER:Job()
    return player_manager.GetPlayerClassTable(self)
end