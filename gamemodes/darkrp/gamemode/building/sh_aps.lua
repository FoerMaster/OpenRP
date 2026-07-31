function ENTITY:GetRPOwner()
    return self:GetNetVar('owner')
end

function ENTITY:IsOwnedBy(ply)
    return self:GetRPOwner() == ply
end

function roleplay.CanPhysgun(ply, ent)
    if (!IsValid(ent) or !ent:IsProp()) then return false end

    return ent:IsOwnedBy(ply)
end
