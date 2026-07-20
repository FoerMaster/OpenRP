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
