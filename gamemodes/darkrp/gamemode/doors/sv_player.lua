function PLAYER:BuyDoor(ent)
    if !IsValid(ent) then return end
    if !ent:IsDoor() then return end
    if !ent:DoorCanBeOwned() then return end
    if IsValid(ent:DoorMainOwner()) then return end
    if (ent:DoorTeam() != nil or ent:DoorJob() != nil) then return end

    local canBuy, cost = hook.Run("OnPlayerBuyDoor", self, ent)
    if (!canBuy) then return end

    cost = cost or GAMEMODE.Config.Defaults.DoorCost
    if (!self:CanAfford(cost)) then return end

    self:AddMoney(-cost)
    ent:SetDoorMainOwner(self)
    self._OwnedDoors[ent] = true

    hook.Run("PlayerBoughtDoor", self, ent, cost)
end

function PLAYER:SellDoor(ent)
    if !IsValid(ent) then return end
    if !ent:IsDoor() then return end
    if ent:DoorMainOwner() != self then return end

    local canSell, refund = hook.Run("OnPlayerSellDoor", self, ent)
    if (!canSell) then return end

    refund = refund or math.floor(GAMEMODE.Config.Defaults.DoorCost * GAMEMODE.Config.Defaults.DoorSellPercent)

    self:AddMoney(refund)
    ent:ClearDoorOwnership()
    self._OwnedDoors[ent] = nil

    hook.Run("PlayerSoldDoor", self, ent, refund)
end

function PLAYER:SellAllDoors()
    for ent in pairs(table.Copy(self._OwnedDoors)) do
        self:SellDoor(ent)
    end
end

function PLAYER:LeaveDoor(ent)
    if !IsValid(ent) then return end
    if !ent:IsDoor() then return end
    if !self._SubOwnedDoors[ent] then return end

    ent:RemoveDoorSubOwner(self)

    hook.Run("PlayerLeftDoor", self, ent)
end

function PLAYER:LeaveAllDoors()
    for ent in pairs(table.Copy(self._SubOwnedDoors)) do
        self:LeaveDoor(ent)
    end
end
