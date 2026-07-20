function ENTITY:DoorInit()
    self:SetNetVar('door_data', {
        name = nil,
        team_owner = nil,
        main_owner = nil,
        job_owner = nil,
        can_be_owned = true,
        sub_owners = {}
    })
    self:Fire("unlock")
end

function ENTITY:DoorUpdate(changes)
    local data = table.Copy(self:DoorRawData())

    for k, v in pairs(changes) do
        data[k] = v
    end

    self:SetNetVar('door_data', data)
end

function ENTITY:SetDoorTeam(teamID)
    local data = table.Copy(self:DoorRawData())
    data.team_owner = teamID
    self:SetNetVar('door_data', data)
end

function ENTITY:SetDoorCanBeOwned(can)
    self:DoorUpdate({
        can_be_owned = can
    })
end

function ENTITY:SetDoorJob(job_class)
    local data = table.Copy(self:DoorRawData())
    data.job_owner = job_class
    self:SetNetVar('door_data', data)
end

function ENTITY:SetDoorMainOwner(ply)
    self:DoorUpdate({
        main_owner = ply:SteamID()
    })
end

function ENTITY:SetDoorName(name)
    self:DoorUpdate({ name = name })
end

function ENTITY:AddDoorSubOwner(ply)
    local data = table.Copy(self:DoorRawData())
    data.sub_owners[ply:SteamID()] = true
    self:SetNetVar('door_data', data)
    ply._SubOwnedDoors[self] = true
end

function ENTITY:RemoveDoorSubOwner(ply)
    local data = table.Copy(self:DoorRawData())
    data.sub_owners[ply:SteamID()] = nil
    self:SetNetVar('door_data', data)
    ply._SubOwnedDoors[self] = nil
end

function ENTITY:ClearDoorOwnership()
    self:Fire("unlock")

    for _, subOwner in ipairs(self:DoorSubOwners()) do
        subOwner._SubOwnedDoors[self] = nil
    end

    local data = table.Copy(self:DoorRawData())
    data.name = nil
    data.main_owner = nil
    data.sub_owners = {}
    self:SetNetVar('door_data', data)
end

function ENTITY:ClearDoorSubOwners()
    for _, subOwner in ipairs(self:DoorSubOwners()) do
        subOwner._SubOwnedDoors[self] = nil
    end

    local data = table.Copy(self:DoorRawData())
    data.sub_owners = {}
    self:SetNetVar('door_data', data)
end

function ENTITY:CanBeChangeNameBy(ply)
    return self:DoorMainOwner() == ply
end

function ENTITY:CanBeOpenedBy(ply)

    if (self:DoorMainOwner() == ply) then
        return true
    end

    for _, subOwner in ipairs(self:DoorSubOwners()) do
        if (subOwner == ply) then
            return true
        end
    end

    if (self:DoorTeam() != nil and ply:Team() == self:DoorTeam()) then
        return true
    end

    if (self:DoorJob() != nil and player_manager.GetPlayerClass(ply) == self:DoorJob()) then
        return true
    end

    return hook.Run("OnPlayerCanBeOpenDoor", self, ply)

end

function ENTITY:GetPartnerDoor()
    local myPos = self:LocalToWorld(self:OBBCenter())
    local best, bestDist

    for _, other in ipairs(ents.FindInSphere(myPos, 128)) do
        if other ~= self and other:IsDoor() and other:GetClass() == self:GetClass() then
            local d = myPos:DistToSqr(other:LocalToWorld(other:OBBCenter()))
            if not bestDist or d < bestDist then
                best, bestDist = other, d
            end
        end
    end

    return best
end
