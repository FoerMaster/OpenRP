function PLAYER:HasJobFlag(flag)
    return table.HasValue(self:Job().Flags, flag)
end

function PLAYER:Job()
    local id = player_manager.GetPlayerClass(self)

    return (id and roleplay.Jobs[id]) or roleplay.Jobs[GAMEMODE.Config.Defaults.Job]
end
