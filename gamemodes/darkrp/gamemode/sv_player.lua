function GM:PlayerInitialSpawn(ply, transition)
    ply._EntityCounts = {}
    ply._OwnedEntity = {}
    ply._SpawnCooldown = 0
    ply._OwnedDoors = {}
    ply._SubOwnedDoors = {}

    ply:SetMoney(self.Config.Defaults.Money)
    player_manager.SetPlayerClass(ply, self.Config.Defaults.Job)

    timer.Create("rp_salary_" .. ply:UserID(), self.Config.Defaults.SalaryEverySeconds, 0, function()
        if IsValid(ply) then
            ply:GiveSalary()
        end
    end)
end

function GM:PlayerDisconnected(ply)
    timer.Remove("rp_salary_" .. ply:UserID())

    ply:SellAllDoors()
    ply:LeaveAllDoors()

    roleplay.CancelJobVotes(ply)
    roleplay.Vote.Cleanup(ply)
end

function GM:PlayerLoadout(ply)
    ply:StripWeapons()
    ply:RemoveAllAmmo()
    player_manager.RunClass(ply, "Loadout")
end

function GM:PlayerSpawnObject(ply)
    return true
end

function GM:PlayerSpawnProp(ply, model)
    if not IsValid(ply) then return true end
    return ply:CheckLimit("props")
end

function GM:PlayerButtonDown(ply, button)
    numpad.Activate(ply, button)

    if (!ply:Alive() and button > KEY_NONE and button <= KEY_LAST) then
        roleplay.Death.TryRespawn(ply)
    end
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
    roleplay.Death.Handle(ply)
end

function GM:PlayerDeathThink(ply)
end

function GM:OnPlayerDropDeathMoney(ply, amount)
    local allow, custom = player_manager.RunClass(ply, "CanDropDeathMoney", amount)
    if allow != nil then return allow, custom end

    return true, amount
end

function GM:PlayerDroppedDeathMoney(ply, amount, ent)
    player_manager.RunClass(ply, "OnDroppedDeathMoney", amount, ent)
end

function GM:PlayerButtonUp(ply, button)
    numpad.Deactivate(ply, button)
end

function GM:CanTool(ply, trace, _)
    local ent = trace.Entity

    if ent:IsWorld() then
        return true
    elseif not IsValid(ent) then
        return false
    end

    if not ent:IsOwnedBy(ply) then
        ply:Notify(self.Lang['NotYourEntity'], 1)
        return false
    end

    return true
end

function GM:PhysgunPickup( ply, ent )
    if not IsValid(ent) or ent.DontAllowPhysgun or ent:IsPlayer() then return false end

    return ent:IsOwnedBy(ply)
end

function GM:GravGunPickupAllowed( ply, ent )
    if not IsValid(ent) or ent:IsPlayer() then return false end

    local phys = ent:GetPhysicsObject()
    return IsValid(phys) and phys:IsMotionEnabled()
end

function GM:CanPlayerUnfreeze( ply, entity, physobject )
	return false
end

function GM:OnPhysgunReload(_,pl)
	return false
end

function GM:OnPhysgunPickup( ply, ent )
    if (ent:IsProp()) then
        ent:Ghost()
    end
end

function GM:PhysgunDrop( ply, ent )
    if (ent:CanUnGhost()) then
        ent:UnGhost()
    end

    local phys = ent:GetPhysicsObject()
    if (IsValid(phys)) then
        phys:EnableMotion(false)
        phys:SetDragCoefficient(0)
        phys:SetMass(0)
    end
end

function GM:OnPlayerDropMoney(ply, amount)
    local allow = player_manager.RunClass(ply, "CanDropMoney", amount)
    if allow != nil then return allow end

    return true
end

function GM:PlayerDroppedMoney(ply, amount, ent)
    player_manager.RunClass(ply, "OnDroppedMoney", amount, ent)
end

function GM:OnPlayerTransferMoney(ply, target, amount)
    local allow = player_manager.RunClass(ply, "CanTransferMoney", target, amount)
    if allow != nil then return allow end

    return true
end

function GM:PlayerTransferedMoney(ply, target, amount)
    player_manager.RunClass(ply, "OnTransferedMoney", target, amount)
end

function GM:OnPlayerCanBeOpenDoor(door, ply)
    local allow = player_manager.RunClass(ply, "CanOpenDoor", door)
    if allow != nil then return allow end

    return false
end

function GM:OnPlayerBuyDoor(ply, ent)
    local canBuy, cost = player_manager.RunClass(ply, "CanBuyDoor", ent)
    if canBuy != nil then return canBuy, cost end
    if ply:HasJobFlag(JOB_FLAG_CANT_BUY_DOOR) then return false, 0 end

    return true, self.Config.Defaults.DoorCost
end

function GM:PlayerBoughtDoor(ply, ent, cost)
    player_manager.RunClass(ply, "OnBoughtDoor", ent, cost)
end

function GM:OnPlayerSellDoor(ply, ent)
    local canSell, refund = player_manager.RunClass(ply, "CanSellDoor", ent)
    if canSell != nil then return canSell, refund end

    return true, math.floor(self.Config.Defaults.DoorCost * self.Config.Defaults.DoorSellPercent)
end

function GM:PlayerSoldDoor(ply, ent, refund)
    player_manager.RunClass(ply, "OnSoldDoor", ent, refund)
end

function GM:PlayerRenamedDoor(ply, ent, name)
    player_manager.RunClass(ply, "OnRenamedDoor", ent, name)
end

function GM:OnPlayerAddDoorOwner(ply, ent, target)
    local allow = player_manager.RunClass(ply, "CanAddDoorOwner", ent, target)
    if allow != nil then return allow end
    if target:HasJobFlag(JOB_FLAG_CANT_BUY_DOOR) then return false end

    return true
end

function GM:PlayerAddedDoorOwner(ply, ent, target)
    player_manager.RunClass(ply, "OnAddedDoorOwner", ent, target)
end

function GM:PlayerRemovedDoorOwner(ply, ent, target)
    player_manager.RunClass(ply, "OnRemovedDoorOwner", ent, target)
end

function GM:PlayerLeftDoor(ply, ent)
    player_manager.RunClass(ply, "OnLeftDoor", ent)
end

function GM:PlayerCheckLimit(ply, class, count, limit)
    return player_manager.RunClass(ply, "CheckBuildLimit", class, count, limit)
end

function GM:PlayerSpawnedProp(ply, model, ent)
    player_manager.RunClass(ply, "OnSpawnedProp", model, ent)
end

function GM:OnPlayerGotSalary(ply, salary)
    local canGot, custom = player_manager.RunClass(ply, "OnSalary", salary)
    if canGot != nil then return canGot, custom end
    return true, salary
end

function GM:OnPlayerBecomeJob(ply, job, oldJob)
    local allow = job:CanJoin(ply)
    if allow != nil then return allow end

    if (job.MaxPlayers >= 0 and roleplay.CountJobPlayers(job) >= job.MaxPlayers) then return false end

    return true
end

function GM:PlayerBecameJob(ply, job, oldJob)
    player_manager.RunClass(ply, "OnJoined", oldJob)
end

function GM:PlayerSay(sender, text, teamChat)
    if (!string.StartsWith(text, '/')) then return text end

    roleplay.Chat.RunCommand(sender, text)

    return ""
end

function GM:OnPlayerChatCommand(sender,command,arguments, noCmd)
    return true
end

function PLAYER:Notify(text, type, time)
    net.Start('notify')
        net.WriteString(text)
        net.WriteUInt(type or 0, 3)
        net.WriteUInt(time or 5, 5)
    net.Send(self)
end

function PLAYER:NotifyError(key, ...)
    self:Notify(roleplay.L(key, ...), 1)
end

function PLAYER:NotifyInfo(key, ...)
    self:Notify(roleplay.L(key, ...), 0)
end

function GM:ShowTeam(ply)
    local ent = ply:GetEyeTrace().Entity
    ply:BuyDoor(ent)
end