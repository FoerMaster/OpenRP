function PLAYER:SetJob(job)
    local oldJob = self:Job()
    if (oldJob and oldJob.ID == job.ID) then return false end

    if (!hook.Run("OnPlayerBecomeJob", self, job, oldJob)) then return false end

    player_manager.SetPlayerClass(self, job.ID)

    self:Spawn()

    hook.Run("PlayerBecameJob", self, job, oldJob)

    return true
end

chat.AddCommand('become', function(sender, arguments, noCommand)
    local query = string.lower(tostring(arguments[1]))

    if sender.LastJobChange and sender.LastJobChange > CurTime() then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["ToFastJobChange"])
        return
    end

    sender.LastJobChange = CurTime() + GAMEMODE.Config.Defaults.NextJobChange

    if (string.len(query) < 4) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["InvalidJob"])
        return
    end

    for _, job in pairs(player_manager.GetPlayerClasses()) do
        if (!job.ID) then continue end
        if (job.ID != query) then continue end

        if (!sender:SetJob(job)) then
            sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantBecomeJob"])
            return
        end

        sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["JobChanged"], job.DisplayName))
        return
    end

    sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["InvalidJob"])
end)
