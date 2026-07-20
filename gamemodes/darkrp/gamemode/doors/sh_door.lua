function ENTITY:DoorRawData()
    return self:GetNetVar('door_data', {
        name = nil,
        team_owner = nil,
        main_owner = nil,
        job_owner = nil,
        can_be_owned = true,
        sub_owners = {}
    })
end

function ENTITY:DoorMainOwner()
    local ownerSteamID = self:DoorRawData().main_owner
    return ownerSteamID and player.GetBySteamID(ownerSteamID) or NULL
end

function ENTITY:DoorName()
    return self:DoorRawData().name
end

function ENTITY:DoorTeam()
    return self:DoorRawData().team_owner
end

function ENTITY:DoorJob()
    return self:DoorRawData().job_owner
end

function ENTITY:DoorCanBeOwned()
    return self:DoorRawData().can_be_owned
end

function ENTITY:DoorIsOwned()
    local data = self:DoorRawData()
    return data.main_owner != nil or data.team_owner != nil or data.job_owner != nil
end

function ENTITY:DoorSubOwners()
    local subOwners = self:DoorRawData().sub_owners
    local toPlayers = {}

    for steamID,v in pairs(subOwners) do
        local ply = player.GetBySteamID(steamID)
        if (ply and IsValid(ply)) then
            table.insert(toPlayers, ply)
        end
        
    end
    return toPlayers
end