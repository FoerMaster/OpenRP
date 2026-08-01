util.AddNetworkString('voting')
util.AddNetworkString('voting_end')

roleplay.Vote = roleplay.Vote or {
    votings = {}
}

local function allVoted(voting)
    return table.Count(voting.votes) >= table.Count(voting.voters)
end

local function resend(id, voting, ply)
    net.Start('voting')
        net.WriteString(id)
        net.WriteString(voting.text)
        net.WriteUInt(math.ceil(timer.TimeLeft('vote_' .. id)), 8)
    net.Send(ply)
end

local function close(id, voting)
    local pending = {}

    for ply in pairs(voting.voters) do
        if (IsValid(ply) and voting.votes[ply] == nil) then
            table.insert(pending, ply)
        end
    end

    if #pending == 0 then return end

    net.Start('voting_end')
        net.WriteString(id)
    net.Send(pending)
end

function roleplay.Vote.Start(id, requestText, delay, callback, excludePlayers, onFailCallback)
    if roleplay.Vote.votings[id] then return false end
    if (!hook.Run('OnVoteStart', id, requestText, delay)) then return false end

    local voters = {}
    for _, ply in player.Iterator() do
        if (excludePlayers and table.HasValue(excludePlayers, ply)) then continue end
        voters[ply] = true
    end

    if table.IsEmpty(voters) then return false end

    roleplay.Vote.votings[id] = {
        text = requestText,
        voters = voters,
        votes = {},
        callback = callback,
        onFail = onFailCallback
    }

    net.Start('voting')
        net.WriteString(id)
        net.WriteString(requestText)
        net.WriteUInt(delay, 8)
    net.Send(table.GetKeys(voters))

    timer.Create('vote_' .. id, delay, 1, function()
        roleplay.Vote.Finish(id)
    end)

    hook.Run('VoteStarted', id, requestText, delay)

    return true
end

function roleplay.Vote.Finish(id)
    local voting = roleplay.Vote.votings[id]
    if !voting then return end

    roleplay.Vote.votings[id] = nil
    timer.Remove('vote_' .. id)
    close(id, voting)

    local yes, no = 0, 0

    for _, choice in pairs(voting.votes) do
        if choice then
            yes = yes + 1
        else
            no = no + 1
        end
    end

    local passed = yes > no

    if passed then
        voting.callback(yes, no)
    elseif voting.onFail then
        voting.onFail(yes, no)
    end

    hook.Run('VoteFinished', id, yes, no, passed)
end

function roleplay.Vote.Running(id)
    return roleplay.Vote.votings[id] != nil
end

function roleplay.Vote.Cancel(id)
    local voting = roleplay.Vote.votings[id]
    if !voting then return end

    roleplay.Vote.votings[id] = nil
    timer.Remove('vote_' .. id)
    close(id, voting)

    hook.Run('VoteCancelled', id)
end

net.Receive('voting', function(_, ply)
    local id = net.ReadString()
    local choice = net.ReadBool()

    local voting = roleplay.Vote.votings[id]
    if !voting then return end
    if !voting.voters[ply] then return end
    if voting.votes[ply] != nil then return end
    if (!hook.Run('OnPlayerVote', ply, id, choice)) then
        resend(id, voting, ply)
        return
    end

    voting.votes[ply] = choice

    hook.Run('PlayerVoted', ply, id, choice)

    if allVoted(voting) then
        roleplay.Vote.Finish(id)
    end
end)

function roleplay.Vote.Cleanup(ply)
    for id, voting in pairs(roleplay.Vote.votings) do
        voting.voters[ply] = nil
        voting.votes[ply] = nil

        if allVoted(voting) then
            roleplay.Vote.Finish(id)
        end
    end
end