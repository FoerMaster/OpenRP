roleplay.Lottery = roleplay.Lottery or {}

local ANNOUNCE_COLOR = Color(120, 180, 255)
local ID = 'lottery'

local lottery
local nextStartAt = 0

local function finish()
    local pool = {}
    for ply in pairs(lottery.participants) do
        if IsValid(ply) then
            pool[#pool + 1] = ply
        end
    end

    local bank = lottery.bank
    lottery = nil

    if #pool == 0 then
        roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('LotteryNoParticipants'))
        return
    end

    local winner = table.Random(pool)
    winner:AddMoney(bank)
    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('LotteryWinner', winner:Nick(), bank))

    hook.Run('LotteryFinished', winner, bank)
end

function roleplay.Lottery.Cleanup(ply)
    if !lottery then return end

    lottery.participants[ply] = nil
end

function roleplay.Lottery.CanVote(ply, id, choice)
    if id != ID then return end
    if !choice then return end
    if ply:CanAfford(lottery.price) then return end

    ply:ChatError('LotteryNoMoney')

    return false
end

function roleplay.Lottery.Voted(ply, id, choice)
    if id != ID then return end
    if !choice then return end
    if !ply:CanAfford(lottery.price) then return end

    ply:AddMoney(-lottery.price)
    lottery.participants[ply] = true
    lottery.bank = lottery.bank + lottery.price
end

roleplay.Chat.AddCommand('lottery', function(sender, arguments)
    local price = roleplay.ParseAmount(arguments[1])
    if !price then
        sender:ChatError('InvalidAmount')
        return
    end

    local min = roleplay.Config.LotteryMinPrice:GetInt()
    local max = roleplay.Config.LotteryMaxPrice:GetInt()

    if (price < min or price > max) then
        sender:ChatError('LotteryPriceRange', min, max)
        return
    end

    if nextStartAt > CurTime() then
        sender:ChatError('LotteryCooldown', math.ceil(nextStartAt - CurTime()))
        return
    end

    if lottery then
        sender:ChatError('LotteryAlreadyRunning')
        return
    end

    if (!hook.Run('OnPlayerStartLottery', sender, price)) then
        sender:ChatError('LotteryCantStart')
        return
    end

    local poor = {}
    for _, ply in player.Iterator() do
        if !ply:CanAfford(price) then
            poor[#poor + 1] = ply
        end
    end

    lottery = {
        price = price,
        participants = {},
        bank = 0
    }

    local started = roleplay.Vote.Start(ID, roleplay.L('LotteryRequest', price),
        roleplay.Config.LotteryVoteSeconds:GetInt(), finish, poor, finish)

    if !started then
        lottery = nil
        sender:ChatError('LotteryNoPlayers')
        return
    end

    nextStartAt = CurTime() + roleplay.Config.LotteryDelay:GetInt()
    sender:ChatSuccess('LotteryStarted', price)

    hook.Run('PlayerStartedLottery', sender, price)
end)
