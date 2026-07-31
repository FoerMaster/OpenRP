util.AddNetworkString('election')

local ANNOUNCE_COLOR = Color(120, 180, 255)
local TIMER = 'rp_election'

local election

local function candidateVotes()
    local out = {}

    for _, candidate in ipairs(election.candidates) do
        out[candidate] = 0
    end

    for _, choice in pairs(election.votes) do
        if (out[choice]) then
            out[choice] = out[choice] + 1
        end
    end

    return out
end

local function send(targets, reveal)
    if (#targets == 0) then return end

    local candidates = election and election.candidates or {}
    local votes = (election and reveal) and candidateVotes() or nil

    net.Start('election')
        net.WriteUInt(election and election.phase or roleplay.Election.PHASE_NONE, 2)
        net.WriteUInt(election and math.Clamp(math.ceil(election.endsAt - CurTime()), 0, 4095) or 0, 12)
        net.WriteBool(votes != nil)
        net.WriteUInt(#candidates, 8)

        for _, candidate in ipairs(candidates) do
            net.WriteEntity(candidate)

            if (votes) then
                net.WriteUInt(votes[candidate], 8)
            end
        end
    net.Send(targets)
end

local function broadcast()
    local revealed, hidden = {}, {}

    for _, ply in player.Iterator() do
        local list = (election and election.votes[ply]) and revealed or hidden
        list[#list + 1] = ply
    end

    send(revealed, true)
    send(hidden, false)
end

function roleplay.Election.Sync(ply)
    send({ ply }, false)
end

local function finish(winner)
    local job = election.job

    election = nil
    timer.Remove(TIMER)

    broadcast()

    if (IsValid(winner) and winner:SetJob(job)) then
        roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('ElectionWinner', winner:Nick(), job.DisplayName))
        return
    end

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('ElectionFailed'))
end

local function tally()
    local best, winners = -1, {}

    for candidate, count in pairs(candidateVotes()) do
        if (count > best) then
            best = count
            winners = { candidate }
        elseif (count == best) then
            winners[#winners + 1] = candidate
        end
    end

    finish(table.Random(winners))
end

local function allVoted()
    for _, ply in player.Iterator() do
        if (election.votes[ply] == nil) then return false end
    end

    return true
end

local function beginVoting()
    if (#election.candidates < 2) then
        finish(election.candidates[1])
        return
    end

    local delay = roleplay.Config.ElectionVoteSeconds:GetInt()

    election.phase = roleplay.Election.PHASE_VOTING
    election.endsAt = CurTime() + delay

    timer.Create(TIMER, delay, 1, tally)

    broadcast()

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('ElectionVotingStarted', delay))
end

local function start(ply, job)
    local delay = roleplay.Config.ElectionSignupSeconds:GetInt()

    election = {
        job = job,
        phase = roleplay.Election.PHASE_SIGNUP,
        endsAt = CurTime() + delay,
        candidates = { ply },
        votes = {}
    }

    timer.Create(TIMER, delay, 1, beginVoting)

    broadcast()

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('ElectionStarted', ply:Nick(), job.DisplayName, delay, job.ID))
end

local function join(ply)
    if (election.phase != roleplay.Election.PHASE_SIGNUP) then
        ply:ChatError('ElectionClosed')
        return
    end

    if (table.HasValue(election.candidates, ply)) then
        ply:ChatError('ElectionAlreadyCandidate')
        return
    end

    if (#election.candidates >= roleplay.Config.ElectionMaxCandidates:GetInt()) then
        ply:ChatError('ElectionFull')
        return
    end

    election.candidates[#election.candidates + 1] = ply

    broadcast()

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('ElectionJoined', ply:Nick()))
end

function roleplay.Election.Request(ply, job)
    if (!roleplay.JobHasFreeSlot(job)) then
        ply:ChatError('JobNoFreeSlots')
        return
    end

    if (player.GetCount() < roleplay.Config.ElectionMinPlayers:GetInt()) then
        if (!ply:SetJob(job)) then
            ply:ChatError('CantBecomeJob')
            return
        end

        ply:ChatSuccess('JobChanged', job.DisplayName)
        return
    end

    if (!election) then
        start(ply, job)
        return
    end

    if (election.job.ID != job.ID) then
        ply:ChatError('ElectionBusy')
        return
    end

    join(ply)
end

function roleplay.Election.Cleanup(ply)
    if (!election) then return end

    election.votes[ply] = nil

    local index = table.KeyFromValue(election.candidates, ply)
    if (index) then
        table.remove(election.candidates, index)
    end

    if (#election.candidates == 0) then
        finish(nil)
        return
    end

    if (election.phase == roleplay.Election.PHASE_VOTING and #election.candidates == 1) then
        finish(election.candidates[1])
        return
    end

    broadcast()
end

net.Receive('election', function(_, ply)
    local candidate = net.ReadEntity()

    if (!election) then return end
    if (election.phase != roleplay.Election.PHASE_VOTING) then return end
    if (election.votes[ply] != nil) then return end
    if (!table.HasValue(election.candidates, candidate)) then return end

    election.votes[ply] = candidate

    broadcast()

    if (allVoted()) then
        tally()
    end
end)
