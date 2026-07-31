function PLAYER:SetJob(job)
    local oldJob = self:Job()
    if (oldJob and oldJob.ID == job.ID) then return false end

    if (!hook.Run("OnPlayerBecomeJob", self, job, oldJob)) then return false end

    player_manager.SetPlayerClass(self, job.ID)

    self:Spawn()

    hook.Run("PlayerBecameJob", self, job, oldJob)

    return true
end

function roleplay.CountJobPlayers(job)
    local count = 0

    for _, ply in player.Iterator() do
        if (player_manager.GetPlayerClass(ply) == job.ID) then
            count = count + 1
        end
    end

    return count
end

function roleplay.JobHasFreeSlot(job)
    if (job.MaxPlayers < 0) then return true end

    return roleplay.CountJobPlayers(job) < job.MaxPlayers
end

local function canJoinJob(ply, job)
    return hook.Run("OnPlayerBecomeJob", ply, job, ply:Job()) != false
end

function roleplay.JobVoteID(ply)
    return 'job_vote_' .. ply:UserID()
end

function roleplay.DemoteVoteID(ply)
    return 'demote_vote_' .. ply:UserID()
end

local function startJobVote(sender, job)
    local id = roleplay.JobVoteID(sender)

    local started = roleplay.Vote.Start(id, roleplay.L('JobVoteRequest', sender:Nick(), job.DisplayName), roleplay.Config.JobVoteSeconds:GetInt(), function(yes, no)
        if (!IsValid(sender)) then return end

        if (!roleplay.JobHasFreeSlot(job)) then
            sender:ChatError("JobNoFreeSlots")
            return
        end

        if (!sender:SetJob(job)) then
            sender:ChatError("CantBecomeJob")
            return
        end

        sender:ChatSuccess("JobChanged", job.DisplayName)
    end, { sender }, function(yes, no)
        if (!IsValid(sender)) then return end

        sender:ChatError("JobVoteRejected", job.DisplayName)
    end)

    if (!started) then
        if (!sender:SetJob(job)) then
            sender:ChatError("CantBecomeJob")
            return
        end

        sender:ChatSuccess("JobChanged", job.DisplayName)
    end
end

local function startDemoteVote(sender, target, reason)
    local job = target:Job()
    local id = roleplay.DemoteVoteID(target)

    local started = roleplay.Vote.Start(id, roleplay.L('DemoteVoteRequest', sender:Nick(), target:Nick(), job.DisplayName, reason), roleplay.Config.DemoteVoteSeconds:GetInt(), function()
        if (!IsValid(target)) then return end

        target:SetJob(roleplay.Jobs[roleplay.DefaultJob()])
        target:ChatError("Demoted", job.DisplayName, reason)

        if (!IsValid(sender)) then return end

        sender:ChatSuccess("PlayerDemoted", target:Nick(), job.DisplayName)
    end, { sender, target }, function()
        if (!IsValid(sender) or !IsValid(target)) then return end

        sender:ChatError("DemoteVoteRejected", target:Nick())
    end)

    return started and id
end

roleplay.Chat.AddCommand('become', function(sender, arguments)
    local job = roleplay.Jobs[string.lower(tostring(arguments[1]))]

    if (!job) then
        sender:ChatError("InvalidJob")
        return
    end

    if (sender.LastJobChange and sender.LastJobChange > CurTime()) then
        sender:ChatError("ToFastJobChange")
        return
    end

    if (table.HasValue(job.Flags, JOB_FLAG_ELECTION)) then
        roleplay.Election.Request(sender, job)
        return
    end

    if (table.HasValue(job.Flags, JOB_FLAG_NEED_VOTE)) then
        if (!roleplay.JobHasFreeSlot(job)) then
            sender:ChatError("JobNoFreeSlots")
            return
        end

        if (!canJoinJob(sender, job)) then
            sender:ChatError("CantBecomeJob")
            return
        end

        sender.LastJobChange = CurTime() + roleplay.Config.JobChangeDelay:GetInt()

        startJobVote(sender, job)
        return
    end

    if (!sender:SetJob(job)) then
        sender:ChatError("CantBecomeJob")
        return
    end

    sender.LastJobChange = CurTime() + roleplay.Config.JobChangeDelay:GetInt()

    sender:ChatSuccess("JobChanged", job.DisplayName)
end)

roleplay.Chat.AddCommand('demote', function(sender, arguments)
    local target = roleplay.FindPlayer(arguments[1])

    if (!target) then
        sender:ChatError("PlayerNotFound")
        return
    end

    if (target == sender) then
        sender:ChatError("CantDemoteSelf")
        return
    end

    local reason = string.Trim(table.concat(arguments, ' ', 2))

    if (reason == '') then
        sender:ChatError("DemoteReasonRequired")
        return
    end

    if (target:HasJobFlag(JOB_FLAG_UNDISMISSABLE)) then
        sender:ChatError("CantDemoteJob")
        return
    end

    if (sender._DemoteVote and roleplay.Vote.Running(sender._DemoteVote)) then
        sender:ChatError("DemoteVoteYoursRunning")
        return
    end

    local readyAt = (target._JobJoinedAt or 0) + roleplay.Config.DemoteImmunity:GetInt()

    if (readyAt > CurTime()) then
        sender:ChatError("DemoteTooEarly", math.ceil(readyAt - CurTime()))
        return
    end

    local minPlayers = roleplay.Config.MinPlayersToDemote:GetInt()

    if (player.GetCount() < minPlayers) then
        sender:ChatError("NotEnoughPlayersToDemote", minPlayers)
        return
    end

    local id = startDemoteVote(sender, target, reason)

    if (!id) then
        sender:ChatError("DemoteVoteAlreadyStarted")
        return
    end

    sender._DemoteVote = id

    sender:ChatSuccess("DemoteVoteStarted", target:Nick())
end)
