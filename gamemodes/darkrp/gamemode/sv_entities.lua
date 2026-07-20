function GM:EntityRemoved(ent, _)
    if ent.OnRemoveCount then
        ent.OnRemoveCount()
    end
end

function GM:OnEntityCreated(ent)
    if (IsValid(ent) and ent:IsDoor()) then
        ent:DoorInit()
    end
end