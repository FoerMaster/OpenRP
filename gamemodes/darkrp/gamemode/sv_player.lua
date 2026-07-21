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
end

function GM:PlayerButtonUp(ply, button)
    numpad.Deactivate(ply, button)
end

function GM:CanTool(ply, trace, _)
    if trace.Entity:IsWorld() then
        return true
    elseif not IsValid(trace.Entity) then
        return false
    end

    return true
end

function GM:PhysgunPickup( ply, ent )
    return IsValid(ent) and !ent.DontAllowPhysgun and not ent:IsPlayer()
end

function GM:GravGunPickupAllowed( ply, ent )
    if not IsValid(ent) or ent:IsPlayer() or ent._deathRagdoll then return false end
    if ent._antilaggFrozen then return true end -- let players recover frozen runaway props
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
