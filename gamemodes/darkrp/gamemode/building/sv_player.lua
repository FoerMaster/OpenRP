function PLAYER:LimitHit(class)
-- TODO: Make hit limit
end

function PLAYER:GetCount(class, minus)
    if self._EntityCounts[class] then
        return self._EntityCounts[class] - (minus or 0)
    end
    return 0
end

function PLAYER:CheckLimit(class)
    local limit = GAMEMODE.Config.Limits[class]
    if limit == nil then return false end

    local currentCount = self:GetCount(class)

    local check = hook.Run("PlayerCheckLimit", self, class, currentCount, limit)

    if check != nil then
        if !check then self:LimitHit(class) end
        return check
    end

    if currentCount > limit - 1 then
        self:LimitHit(class)
        return false
    end

    return true
end

function PLAYER:AddCount(class,ent)
    if not IsValid(self) then return end

    self._EntityCounts[class] = (self._EntityCounts[class] or 0) + 1

    self._OwnedEntity[ent:EntIndex()] = ent

    ent:SetNetVar('owner', self)

    ent.OnRemoveCount = function()
        if not IsValid(self) then return end
        self._EntityCounts[class] = (self._EntityCounts[class] or 1) - 1
        self._OwnedEntity[ent:EntIndex()] = nil
    end
end

function PLAYER:GetTool(mode)
    local toolEnt = self:GetWeapon("gmod_tool")
    if not IsValid(toolEnt) or not toolEnt.GetToolObject then return nil end

    local tool = toolEnt:GetToolObject(mode)
    if not tool then return nil end

    return tool
end

function PLAYER:AddCleanup(type, ent)
    cleanup.Add(self, type, ent)
end

function PLAYER:CleanupProps()
    for entIndex, ent in pairs(self._OwnedEntity) do
        if ( IsValid(ent) and ent:IsProp() ) then
            ent:Remove()
            self._OwnedEntity[entIndex] = nil
        end
    end
    self._EntityCounts['props'] = 0
end

function PLAYER:CleanupEntities()
    for entIndex, ent in pairs(self._OwnedEntity) do
        if (IsValid(ent)) then
            ent:Remove()
        end
        self._OwnedEntity[entIndex] = nil
    end
    for class, _ in pairs(GAMEMODE.Config.Limits) do
        self._EntityCounts[class] = 0
    end
end

function PLAYER:CleanupAll()
    self:CleanupEntities()
    self:CleanupProps()
end