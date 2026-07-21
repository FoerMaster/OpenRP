local doorClasses = {
    ["func_door"] = true,
    ["func_door_rotating"] = true,
    ["prop_door_rotating"] = true,
    ["func_movelinear"] = true
}

local ENTITY = FindMetaTable('Entity')

function ENTITY:IsDoor()
    return doorClasses[self:GetClass()] == true
end

function ENTITY:IsProp()
    return self:GetClass() == "prop_physics"
end
