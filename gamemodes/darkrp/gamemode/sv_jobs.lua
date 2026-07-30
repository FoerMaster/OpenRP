function PLAYER:SetJob(job)
    local oldJob = self:Job()
    if (oldJob and oldJob.ID == job.ID) then return false end

    if (!hook.Run("OnPlayerBecomeJob", self, job, oldJob)) then return false end

    player_manager.SetPlayerClass(self, job.ID)

    self:Spawn()

    hook.Run("PlayerBecameJob", self, job, oldJob)

    return true
end

function jobHasFreeSlot(job)
    if (job.MaxPlayers < 0) then return true end

    local count = 0

    for _, other in ipairs(player.GetAll()) do
        if (player_manager.GetPlayerClass(other) == job.ID) then
            count = count + 1
        end
    end

    return count < job.MaxPlayers
end

local function canJoinJob(ply, job)
    return hook.Run("OnPlayerBecomeJob", ply, job, ply:Job()) != false
end

local function startJobVote(sender, job)
    local id = 'job_vote_' .. sender:UserID()

    local started = vote.Start(id, string.format(GAMEMODE.Lang["JobVoteRequest"], sender:Nick(), job.DisplayName), GAMEMODE.Config.Defaults.JobVoteSeconds, function(yes, no)
        if (!IsValid(sender)) then return end

        if (!jobHasFreeSlot(job)) then
            sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["JobNoFreeSlots"])
            return
        end

        if (!sender:SetJob(job)) then
            sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantBecomeJob"])
            return
        end

        sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["JobChanged"], job.DisplayName))
    end, { sender }, function(yes, no)
        if (!IsValid(sender)) then return end

        sender:SendChat(Color(255, 69, 69), string.format(GAMEMODE.Lang["JobVoteRejected"], job.DisplayName))
    end)

    if (!started) then
        if (!sender:SetJob(job)) then
            sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantBecomeJob"])
            return
        end

        sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["JobChanged"], job.DisplayName))
    end
end

local function startDemoteVote(sender, target, reason)
    local job = target:Job()
    local id = 'demote_vote_' .. target:UserID()

    return vote.Start(id, string.format(GAMEMODE.Lang["DemoteVoteRequest"], sender:Nick(), target:Nick(), job.DisplayName, reason), GAMEMODE.Config.Defaults.DemoteVoteSeconds, function()
        if (!IsValid(target)) then return end
        if (target:Job().ID != job.ID) then return end

        target:SetJob(player_manager.GetPlayerClasses()[GAMEMODE.Config.Defaults.Job])
        target:SendChat(Color(255, 69, 69), string.format(GAMEMODE.Lang["Demoted"], job.DisplayName, reason))

        if (!IsValid(sender)) then return end

        sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["PlayerDemoted"], target:Nick(), job.DisplayName))
    end, { sender, target }, function()
        if (!IsValid(sender) or !IsValid(target)) then return end

        sender:SendChat(Color(255, 69, 69), string.format(GAMEMODE.Lang["DemoteVoteRejected"], target:Nick()))
    end)
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

        if (table.HasValue(job.Flags or {}, JOB_FLAG_NEED_VOTE)) then
            if (!jobHasFreeSlot(job)) then
                sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["JobNoFreeSlots"])
                return
            end

            if (!canJoinJob(sender, job)) then
                sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantBecomeJob"])
                return
            end

            startJobVote(sender, job)
            return
        end

        if (!sender:SetJob(job)) then
            sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantBecomeJob"])
            return
        end

        sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["JobChanged"], job.DisplayName))
        return
    end

    sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["InvalidJob"])
end)

chat.AddCommand('demote', function(sender, arguments)
    local target = Player(tonumber(arguments[1]) or -1)

    if (!IsValid(target)) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["PlayerNotFound"])
        return
    end

    if (target == sender) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantDemoteSelf"])
        return
    end

    local reason = string.Trim(table.concat(arguments, ' ', 2))

    if (reason == '') then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["DemoteReasonRequired"])
        return
    end

    if (target:HasJobFlag(JOB_FLAG_UNDISMISSABLE)) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["CantDemoteJob"])
        return
    end

    local minPlayers = GAMEMODE.Config.Defaults.MinPlayersToDemote

    if (#player.GetAll() < minPlayers) then
        sender:SendChat(Color(255, 69, 69), string.format(GAMEMODE.Lang["NotEnoughPlayersToDemote"], minPlayers))
        return
    end

    if (!startDemoteVote(sender, target, reason)) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang["DemoteVoteAlreadyStarted"])
        return
    end

    sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang["DemoteVoteStarted"], target:Nick()))
end)

hook.Add('PlayerDisconnected', 'JobVotingCleanup', function(ply)
    vote.Cancel('job_vote_' .. ply:UserID())
    vote.Cancel('demote_vote_' .. ply:UserID())
end)
