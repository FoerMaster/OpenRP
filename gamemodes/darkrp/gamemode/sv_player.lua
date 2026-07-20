function GM:PlayerInitialSpawn(ply, transition)
    ply._EntityCounts = {}
    ply._OwnedEntity = {}
    ply._SpawnCooldown = 0
    ply._OwnedDoors = {}
    ply._SubOwnedDoors = {}
end

function GM:PlayerDisconnected(ply)
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

    if trace.Entity:GetCOwner() ~= ply then
        return false
    end

    return true
end

function GM:PhysgunPickup( ply, ent )
    return IsValid(ent) and !ent.DontAllowPhysgun and ent:GetCOwner() == ply and not ent:IsPlayer()
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
    phys:EnableMotion(false)
    phys:SetDragCoefficient(0)
    phys:SetMass(0)
end

function GM:OnPlayerDropMoney(ply, amount)
    return true
end

function GM:OnPlayerCanBeOpenDoor(door, ply)
    return false
end

function GM:OnPlayerBuyDoor(ply, ent)
    return true, self.Config.Defaults.DoorCost
end

function GM:OnPlayerSellDoor(ply, ent)
    return true, math.floor(self.Config.Defaults.DoorCost * self.Config.Defaults.DoorSellPercent)
end