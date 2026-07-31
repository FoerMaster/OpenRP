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
    if amount <= 0 then return false end
    if !self:CanAfford(amount) then return false end
    if (!hook.Run('OnPlayerDropMoney', self, amount)) then return false end

    local trace = util.TraceLine({
        start = self:EyePos(),
        endpos = self:EyePos() + self:GetAimVector() * 50,
        filter = self
    })

    local money = ents.Create("money")
    if not IsValid(money) then return false end
    if self:Alive() then
        money:SetPos(trace.HitPos)
    else
        money:SetPos(self:GetPos())
    end
    money:SetAmount(amount)
    money:Spawn()
    self:AddMoney(-amount)

    hook.Run("PlayerDroppedMoney", self, amount, money)

    return true
end

function PLAYER:TransferMoney(ply, amount)
    if amount <= 0 then return false end
    if !self:CanAfford(amount) then return false end
    if !IsValid(ply) then return false end
    if (!hook.Run('OnPlayerTransferMoney', self, ply,amount)) then return false end

    self:AddMoney(-amount)
    ply:AddMoney(amount)

    hook.Run("PlayerTransferedMoney", self, ply,amount)

    return true
end

function PLAYER:GiveSalary()
    local job = self:Job()
    if (job.Salary <= 0) then return end

    local canGetSalary, salary = hook.Run("OnPlayerGotSalary", self, job.Salary)
    if (!canGetSalary) then return end

    salary = math.floor(salary)

    self:AddMoney(salary)

    self:NotifyInfo('SalaryReceived', salary)

    hook.Run("PlayerGotSalary", self, salary)

end

roleplay.Chat.AddCommand('dropmoney', function(sender, arguments)
    local amount = roleplay.ParseAmount(arguments[1])

    if (!amount) then
        sender:ChatError('InvalidAmount')
        return
    end

    local limit = roleplay.Config.MaxDropMoney:GetInt()
    if (amount > limit) then
        sender:ChatError('ToManyMoney', limit)
        return
    end

    if (!sender:CanAfford(amount)) then
        sender:ChatError('NotEnoughMoney')
        return
    end

    if (!sender:DropMoney(amount)) then return end

    sender:SendChat(roleplay.Colors.Money, roleplay.L('MoneyDropped', amount))
end)

roleplay.Chat.AddCommand('givemoney', function(sender, arguments)
    local amount = roleplay.ParseAmount(arguments[1])

    if (!amount) then
        sender:ChatError('InvalidAmount')
        return
    end

    if (!sender:CanAfford(amount)) then
        sender:ChatError('NotEnoughMoney')
        return
    end

    local target = sender:GetEyeTrace().Entity
    if (!IsValid(target) or !target:IsPlayer() or sender:GetPos():Distance(target:GetPos()) > 200) then
        sender:ChatError('NoPlayerInFront')
        return
    end

    if (target == sender) then
        sender:ChatError('CantGiveToSelf')
        return
    end

    if (!sender:TransferMoney(target, amount)) then return end

    sender:ChatSuccess('MoneyGiven', amount, target:Nick())
    target:ChatSuccess('MoneyReceived', sender:Nick(), amount)
end)