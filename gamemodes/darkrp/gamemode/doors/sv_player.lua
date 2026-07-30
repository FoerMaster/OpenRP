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

    if (ent:DoorRawData().main_owner != nil) then
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

    if (!ent:IsDoorMainOwner(self)) then
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

function PLAYER:RenameDoor(ent, name)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1)
        return
    end

    if (!ent:CanBeChangeNameBy(self)) then
        self:Notify(GAMEMODE.Lang['DoorNotYours'], 1)
        return
    end

    ent:SetDoorName(name)

    self:Notify(string.format(GAMEMODE.Lang['DoorRenamed'], name))

    hook.Run("PlayerRenamedDoor", self, ent, name)
end

function PLAYER:AddDoorOwner(ent, target)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1)
        return
    end

    if (!ent:IsDoorMainOwner(self)) then
        self:Notify(GAMEMODE.Lang['DoorNotYours'], 1)
        return
    end

    if (target == self) then
        self:Notify(GAMEMODE.Lang['DoorCantAddSelf'], 1)
        return
    end

    if (ent:IsDoorSubOwner(target)) then
        self:Notify(GAMEMODE.Lang['DoorAlreadySubOwner'], 1)
        return
    end

    if (!hook.Run("OnPlayerAddDoorOwner", self, ent, target)) then
        self:Notify(GAMEMODE.Lang['DoorCantAddOwner'], 1)
        return
    end

    ent:AddDoorSubOwner(target)

    self:Notify(string.format(GAMEMODE.Lang['DoorOwnerAdded'], target:Nick()))
    target:Notify(string.format(GAMEMODE.Lang['DoorOwnerAddedYou'], self:Nick()))

    hook.Run("PlayerAddedDoorOwner", self, ent, target)
end

function PLAYER:RemoveDoorOwner(ent, target)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1)
        return
    end

    if (!ent:IsDoorMainOwner(self)) then
        self:Notify(GAMEMODE.Lang['DoorNotYours'], 1)
        return
    end

    if (!ent:IsDoorSubOwner(target)) then
        self:Notify(GAMEMODE.Lang['DoorTargetNotSubOwner'], 1)
        return
    end

    ent:RemoveDoorSubOwner(target)

    self:Notify(string.format(GAMEMODE.Lang['DoorOwnerRemoved'], target:Nick()))
    target:Notify(string.format(GAMEMODE.Lang['DoorOwnerRemovedYou'], self:Nick()))

    hook.Run("PlayerRemovedDoorOwner", self, ent, target)
end

function PLAYER:LeaveDoor(ent, quiet)
    if (!IsValid(ent) or !ent:IsDoor()) then
        if (!quiet) then self:Notify(GAMEMODE.Lang['NotLookingAtDoor'], 1) end
        return
    end

    if (!ent:IsDoorSubOwner(self)) then
        if (!quiet) then self:Notify(GAMEMODE.Lang['DoorNotSubOwner'], 1) end
        return
    end

    ent:RemoveDoorSubOwner(self)

    if (!quiet) then self:Notify(GAMEMODE.Lang['DoorLeft']) end

    hook.Run("PlayerLeftDoor", self, ent)

    return true
end

function PLAYER:LeaveAllDoors()
    local left = 0

    for ent in pairs(table.Copy(self._SubOwnedDoors)) do
        if (self:LeaveDoor(ent, true)) then
            left = left + 1
        end
    end

    if (left > 0) then
        self:Notify(string.format(GAMEMODE.Lang['DoorsLeft'], left))
    end

    return left
end

chat.AddCommand('unown', function(sender)
    sender:SellDoor(sender:GetEyeTrace().Entity)
end)

chat.AddCommand('title', function(sender, arguments, noCommand)
    local name = string.Trim(noCommand)

    if (name == '') then
        sender:Notify(GAMEMODE.Lang['DoorNameRequired'], 1)
        return
    end

    local limit = GAMEMODE.Config.Defaults.MaxDoorNameLength
    local length = utf8.len(name)

    if (!length or length > limit) then
        sender:Notify(string.format(GAMEMODE.Lang['DoorNameTooLong'], limit), 1)
        return
    end

    sender:RenameDoor(sender:GetEyeTrace().Entity, name)
end)

chat.AddCommand('addowner', function(sender, arguments)
    local target = Player(tonumber(arguments[1]) or -1)

    if (!IsValid(target)) then
        sender:Notify(GAMEMODE.Lang['PlayerNotFound'], 1)
        return
    end

    sender:AddDoorOwner(sender:GetEyeTrace().Entity, target)
end)

chat.AddCommand('removeowner', function(sender, arguments)
    local target = Player(tonumber(arguments[1]) or -1)

    if (!IsValid(target)) then
        sender:Notify(GAMEMODE.Lang['PlayerNotFound'], 1)
        return
    end

    sender:RemoveDoorOwner(sender:GetEyeTrace().Entity, target)
end)

chat.AddCommand('leavedoor', function(sender)
    sender:LeaveDoor(sender:GetEyeTrace().Entity)
end)

chat.AddCommand('leavealldoors', function(sender)
    if (sender:LeaveAllDoors() == 0) then
        sender:Notify(GAMEMODE.Lang['DoorNoSubOwned'], 1)
    end
end)
