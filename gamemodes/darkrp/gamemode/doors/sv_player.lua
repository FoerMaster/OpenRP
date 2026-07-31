function PLAYER:CountDoors()
    return table.Count(self._OwnedDoors)
end

function PLAYER:BuyDoor(ent)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:NotifyError('NotLookingAtDoor')
        return
    end

    if !ent:DoorCanBeOwned() then
        self:NotifyError('DoorCantBeOwned')
        return
    end

    if (ent:DoorRawData().main_owner != nil) then
        self:NotifyError('DoorAlreadyOwned')
        return
    end

    if (ent:DoorTeam() != nil or ent:DoorJob() != nil) then
        self:NotifyError('DoorReserved')
        return
    end

    local limit = roleplay.Config.MaxDoors:GetInt()
    if (self:CountDoors() >= limit) then
        self:NotifyError('DoorLimit', limit)
        return
    end

    local canBuy, cost = hook.Run("OnPlayerBuyDoor", self, ent)
    if (!canBuy) then
        self:NotifyError('DoorCantBuy')
        return
    end

    cost = cost or roleplay.Config.DoorCost:GetInt()
    if (!self:CanAfford(cost)) then
        self:NotifyError('NotEnoughMoney')
        return
    end

    self:AddMoney(-cost)
    ent:SetDoorMainOwner(self)
    self._OwnedDoors[ent] = true

    self:NotifyInfo('DoorBought', cost)

    hook.Run("PlayerBoughtDoor", self, ent, cost)
end

function PLAYER:SellDoor(ent, quiet)
    if (!IsValid(ent) or !ent:IsDoor()) then
        if (!quiet) then self:NotifyError('NotLookingAtDoor') end
        return
    end

    if (!ent:IsDoorMainOwner(self)) then
        if (!quiet) then self:NotifyError('DoorNotYours') end
        return
    end

    local canSell, refund = hook.Run("OnPlayerSellDoor", self, ent)
    if (!canSell) then
        if (!quiet) then self:NotifyError('DoorCantSell') end
        return
    end

    refund = refund or math.floor(roleplay.Config.DoorCost:GetInt() * roleplay.Config.DoorSellPercent:GetFloat())

    self:AddMoney(refund)
    ent:ClearDoorOwnership()
    self._OwnedDoors[ent] = nil

    if (!quiet) then self:NotifyInfo('DoorSold', refund) end

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
        self:NotifyInfo('DoorsSold', sold, total)
    end
end

function PLAYER:RenameDoor(ent, name)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:NotifyError('NotLookingAtDoor')
        return
    end

    if (!ent:CanBeChangeNameBy(self)) then
        self:NotifyError('DoorNotYours')
        return
    end

    ent:SetDoorName(name)

    self:NotifyInfo('DoorRenamed', name)

    hook.Run("PlayerRenamedDoor", self, ent, name)
end

function PLAYER:AddDoorOwner(ent, target)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:NotifyError('NotLookingAtDoor')
        return
    end

    if (!ent:IsDoorMainOwner(self)) then
        self:NotifyError('DoorNotYours')
        return
    end

    if (target == self) then
        self:NotifyError('DoorCantAddSelf')
        return
    end

    if (ent:IsDoorSubOwner(target)) then
        self:NotifyError('DoorAlreadySubOwner')
        return
    end

    if (!hook.Run("OnPlayerAddDoorOwner", self, ent, target)) then
        self:NotifyError('DoorCantAddOwner')
        return
    end

    ent:AddDoorSubOwner(target)

    self:NotifyInfo('DoorOwnerAdded', target:Nick())
    target:NotifyInfo('DoorOwnerAddedYou', self:Nick())

    hook.Run("PlayerAddedDoorOwner", self, ent, target)
end

function PLAYER:RemoveDoorOwner(ent, target)
    if (!IsValid(ent) or !ent:IsDoor()) then
        self:NotifyError('NotLookingAtDoor')
        return
    end

    if (!ent:IsDoorMainOwner(self)) then
        self:NotifyError('DoorNotYours')
        return
    end

    if (!ent:IsDoorSubOwner(target)) then
        self:NotifyError('DoorTargetNotSubOwner')
        return
    end

    ent:RemoveDoorSubOwner(target)

    self:NotifyInfo('DoorOwnerRemoved', target:Nick())
    target:NotifyInfo('DoorOwnerRemovedYou', self:Nick())

    hook.Run("PlayerRemovedDoorOwner", self, ent, target)
end

function PLAYER:LeaveDoor(ent, quiet)
    if (!IsValid(ent) or !ent:IsDoor()) then
        if (!quiet) then self:NotifyError('NotLookingAtDoor') end
        return
    end

    if (!ent:IsDoorSubOwner(self)) then
        if (!quiet) then self:NotifyError('DoorNotSubOwner') end
        return
    end

    ent:RemoveDoorSubOwner(self)

    if (!quiet) then self:NotifyInfo('DoorLeft') end

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
        self:NotifyInfo('DoorsLeft', left)
    end

    return left
end

roleplay.Chat.AddCommand('unown', function(sender)
    sender:SellDoor(sender:GetEyeTrace().Entity)
end)

roleplay.Chat.AddCommand('title', function(sender, arguments, noCommand)
    local name = string.Trim(noCommand)

    if (name == '') then
        sender:NotifyError('DoorNameRequired')
        return
    end

    local limit = roleplay.Config.MaxDoorNameLength:GetInt()
    local length = utf8.len(name)

    if (!length or length > limit) then
        sender:NotifyError('DoorNameTooLong', limit)
        return
    end

    sender:RenameDoor(sender:GetEyeTrace().Entity, name)
end)

roleplay.Chat.AddCommand('addowner', function(sender, arguments)
    local target = roleplay.FindPlayer(arguments[1])

    if (!target) then
        sender:NotifyError('PlayerNotFound')
        return
    end

    sender:AddDoorOwner(sender:GetEyeTrace().Entity, target)
end)

roleplay.Chat.AddCommand('removeowner', function(sender, arguments)
    local target = roleplay.FindPlayer(arguments[1])

    if (!target) then
        sender:NotifyError('PlayerNotFound')
        return
    end

    sender:RemoveDoorOwner(sender:GetEyeTrace().Entity, target)
end)

roleplay.Chat.AddCommand('leavedoor', function(sender)
    sender:LeaveDoor(sender:GetEyeTrace().Entity)
end)

roleplay.Chat.AddCommand('leavealldoors', function(sender)
    if (sender:LeaveAllDoors() == 0) then
        sender:NotifyError('DoorNoSubOwned')
    end
end)
