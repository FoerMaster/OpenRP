function PLAYER:CountDoors()
    return table.Count(self._OwnedDoors)
end

function PLAYER:BuyDoor(ent)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1)
        return
    end

    if !ent:DoorCanBeOwned() then
        self:Notify(GAMEMODE.Lang['DoorCantBeOwned'], 1)
        return
    end

    if IsValid(ent:DoorMainOwner()) then
        self:Notify(GAMEMODE.Lang['DoorAlreadyOwned'], 1)
        return
    end

    if (ent:DoorTeam() != nil or ent:DoorJob() != nil) then
        self:Notify(GAMEMODE.Lang['DoorReserved'], 1)
        return
    end

    local limit = GAMEMODE.Config.Defaults.MaxDoors
    if (self:CountDoors() >= limit) then
        self:Notify(string.format(GAMEMODE.Lang['DoorLimit'], limit), 1)
        return
    end

    local canBuy, cost = hook.Run("OnPlayerBuyDoor", self, ent)
    if (!canBuy) then
        self:Notify(GAMEMODE.Lang['DoorCantBuy'], 1)
        return
    end

    cost = cost or GAMEMODE.Config.Defaults.DoorCost
    if (!self:CanAfford(cost)) then
        self:Notify(GAMEMODE.Lang['NotEnoughMoney'], 1)
        return
    end

    self:AddMoney(-cost)
    ent:SetDoorMainOwner(self)
    self._OwnedDoors[ent] = true

    self:Notify(string.format(GAMEMODE.Lang['DoorBought'], cost))

    hook.Run("PlayerBoughtDoor", self, ent, cost)
end

function PLAYER:SellDoor(ent, quiet)
    if (!IsValid(ent) or !ent:IsDoor()) then
        if (!quiet) then self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1) end
        return
    end

    if ent:DoorMainOwner() != self then
        if (!quiet) then self:Notify(GAMEMODE.Lang['DoorNotYours'], 1) end
        return
    end

    local canSell, refund = hook.Run("OnPlayerSellDoor", self, ent)
    if (!canSell) then
        if (!quiet) then self:Notify(GAMEMODE.Lang['DoorCantSell'], 1) end
        return
    end

    refund = refund or math.floor(GAMEMODE.Config.Defaults.DoorCost * GAMEMODE.Config.Defaults.DoorSellPercent)

    self:AddMoney(refund)
    ent:ClearDoorOwnership()
    self._OwnedDoors[ent] = nil

    if (!quiet) then self:Notify(string.format(GAMEMODE.Lang['DoorSold'], refund)) end

    hook.Run("PlayerSoldDoor", self, ent, refund)

    return refund
end

function PLAYER:SellAllDoors()
    local sold, total = 0, 0

    for ent in pairs(table.Copy(self._OwnedDoors)) do
        local refund = self:SellDoor(ent, true)

        if (refund) then
            sold = sold + 1
            total = total + refund
        end
    end

    if (sold > 0) then
        self:Notify(string.format(GAMEMODE.Lang['DoorsSold'], sold, total))
    end
end

function PLAYER:LeaveDoor(ent)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1)
        return
    end

    if !self._SubOwnedDoors[ent] then
        self:Notify(GAMEMODE.Lang['DoorNotSubOwner'], 1)
        return
    end

    ent:RemoveDoorSubOwner(self)

    self:Notify(GAMEMODE.Lang['DoorLeft'])

    hook.Run("PlayerLeftDoor", self, ent)
end

function PLAYER:LeaveAllDoors()
    for ent in pairs(table.Copy(self._SubOwnedDoors)) do
        self:LeaveDoor(ent)
    end
end
