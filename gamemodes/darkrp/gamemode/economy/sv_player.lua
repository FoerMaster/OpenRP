function PLAYER:SetMoney(count)
    self:SetNetVar('money', count)
end

function PLAYER:AddMoney(count)
    local final = self:Money() + count
    self:SetMoney(final)
    return final
end

function PLAYER:CanAfford(cost)
    return self:Money() >= cost
end

function PLAYER:DropMoney(amount)
    if amount <= 0 then return end
    if !self:CanAfford(amount) then return end
    if (!hook.Run('OnPlayerDropMoney', self, amount)) then return end

    local trace = util.TraceLine({
        start = self:EyePos(),
        endpos = self:EyePos() + self:GetAimVector() * 50,
        filter = self
    })

    local money = ents.Create("money")
    if not IsValid(money) then return end
    if self:Alive() then
        money:SetPos(trace.HitPos)
    else
        money:SetPos(self:GetPos())
    end
    money:SetAmount(amount)
    money:Spawn()
    self:AddMoney(-amount)

    hook.Run("PlayerDroppedMoney", self, amount, money)
end

function PLAYER:TransferMoney(ply, amount)
    if amount <= 0 then return end
    if !self:CanAfford(amount) then return end
    if !IsValid(ply) then return end
    if (!hook.Run('OnPlayerTransferMoney', self, ply,amount)) then return end

    self:AddMoney(-amount)
    ply:AddMoney(amount)

    hook.Run("PlayerTransferedMoney", self, ply,amount)
end

function PLAYER:GiveSalary()
    local job = self:Job()
    if (job.Salary <= 0) then return end

    local canGetSalary, salary = hook.Run("OnPlayerGotSalary", self, job.Salary)
    if (!canGetSalary) then return end

    salary = math.floor(salary)

    self:AddMoney(salary)

    hook.Run("PlayerGotSalary", self, salary)

end

chat.AddCommand('dropmoney', function(sender, arguments)
    local amount = tonumber(arguments[1])
    if (!amount) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['InvalidAmount'])
        return
    end

    amount = math.floor(amount)
    if (amount <= 0) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['InvalidAmount'])
        return
    end

    if (amount > 10001) then
        sender:SendChat(Color(255, 69, 69), string.format(GAMEMODE.Lang['ToManyMoney'],10000))
        return
    end

    if (!sender:CanAfford(amount)) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['NotEnoughMoney'])
        return
    end

    sender:DropMoney(amount)
    sender:SendChat(Color(61, 213, 61), string.format(GAMEMODE.Lang['MoneyDropped'], amount))
end)

chat.AddCommand('givemoney', function(sender, arguments)
    local amount = tonumber(arguments[1])
    if (!amount) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['InvalidAmount'])
        return
    end

    amount = math.floor(amount)
    if (amount <= 0) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['InvalidAmount'])
        return
    end

    if (!sender:CanAfford(amount)) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['NotEnoughMoney'])
        return
    end

    local target = sender:GetEyeTrace().Entity
    if (!IsValid(target) or !target:IsPlayer() or sender:GetPos():Distance(target:GetPos()) > 200) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['NoPlayerInFront'])
        return
    end

    if (target == sender) then
        sender:SendChat(Color(255, 69, 69), GAMEMODE.Lang['CantGiveToSelf'])
        return
    end

    sender:TransferMoney(target, amount)
    sender:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang['MoneyGiven'], amount, target:Nick()))
    target:SendChat(Color(69, 255, 69), string.format(GAMEMODE.Lang['MoneyReceived'], sender:Nick(), amount))
end)