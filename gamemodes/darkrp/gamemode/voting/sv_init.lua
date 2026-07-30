util.AddNetworkString('voting')
util.AddNetworkString('voting_end')

vote = vote or {
    votings = {}
}

local function allVoted(voting)
    return table.Count(voting.votes) >= table.Count(voting.voters)
end

local function close(id, voting)
    local pending = {}

    for ply in pairs(voting.voters) do
        if (IsValid(ply) and voting.votes[ply] == nil) then
            table.insert(pending, ply)
        end
    end

    if (#pending == 0) then return end

    net.Start('voting_end')
        net.WriteString(id)
    net.Send(pending)
end

function vote.Start(id, requestText, delay, callback, excludePlayers, onFailCallback)
    if (vote.votings[id]) then return false end

    local voters = {}

    for _, ply in ipairs(player.GetAll()) do
        if (excludePlayers and table.HasValue(excludePlayers, ply)) then continue end
        voters[ply] = true
    end

    if (table.IsEmpty(voters)) then return false end

    vote.votings[id] = {
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
        vote.Finish(id)
    end)

    return true
end

function vote.Finish(id)
    local voting = vote.votings[id]
    if (!voting) then return end

    vote.votings[id] = nil
    timer.Remove('vote_' .. id)
    close(id, voting)

    local yes, no = 0, 0

    for _, choice in pairs(voting.votes) do
        if (choice) then
            yes = yes + 1
        else
            no = no + 1
        end
    end

    if (yes > no) then
        voting.callback(yes, no)
    elseif (voting.onFail) then
        voting.onFail(yes, no)
    end
end

function vote.Cancel(id)
    local voting = vote.votings[id]
    if (!voting) then return end

    vote.votings[id] = nil
    timer.Remove('vote_' .. id)
    close(id, voting)
end

net.Receive('voting', function(_, ply)
    local id = net.ReadString()
    local choice = net.ReadBool()

    local voting = vote.votings[id]
    if (!voting) then return end
    if (!voting.voters[ply]) then return end
    if (voting.votes[ply] != nil) then return end

    voting.votes[ply] = choice

    if (allVoted(voting)) then
        vote.Finish(id)
    end
end)

hook.Add('PlayerDisconnected', 'VotingCleanup', function(ply)
    for id, voting in pairs(vote.votings) do
        voting.voters[ply] = nil
        voting.votes[ply] = nil

        if (allVoted(voting)) then
            vote.Finish(id)
        end
    end
end)