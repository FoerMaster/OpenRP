local GHOST_COLOR      = Color(255, 255, 255, 100)
local UNGHOST_COLOR    = Color(255, 255, 255, 255)
local GHOST_PADDING    = Vector(7, 7, 7)

local function worldAABB(self, padding)
    local mins, maxs = self:OBBMins(), self:OBBMaxs()
    local wMin, wMax
    for x = 0, 1 do
        for y = 0, 1 do
            for z = 0, 1 do
                local corner = self:LocalToWorld(Vector(
                    x == 0 and mins.x or maxs.x,
                    y == 0 and mins.y or maxs.y,
                    z == 0 and mins.z or maxs.z
                ))
                if (not wMin) then
                    wMin, wMax = Vector(corner), Vector(corner)
                else
                    wMin.x = math.min(wMin.x, corner.x); wMax.x = math.max(wMax.x, corner.x)
                    wMin.y = math.min(wMin.y, corner.y); wMax.y = math.max(wMax.y, corner.y)
                    wMin.z = math.min(wMin.z, corner.z); wMax.z = math.max(wMax.z, corner.z)
                end
            end
        end
    end

    return wMin - padding, wMax + padding
end

function ENTITY:GetRPOwner()
    return self:GetNetVar('owner')
end

function ENTITY:IsOwnedBy(ply)
    return self:GetRPOwner() == ply
end

function ENTITY:Ghost()
    if (not IsValid(self)) then return end
    self.ghostedAt = CurTime() + 120
    self:SetRenderMode(RENDERMODE_TRANSALPHA)
    self:SetColor(GHOST_COLOR)
    self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

function ENTITY:IsGhosted()
    return self:GetRenderMode() == RENDERMODE_TRANSALPHA and self:GetCollisionGroup() == COLLISION_GROUP_WORLD
end

function ENTITY:UnGhost()
    self.ghostedAt = nil
    self:SetRenderMode(RENDERMODE_NORMAL)
    self:SetColor(UNGHOST_COLOR)
    self:SetCollisionGroup(COLLISION_GROUP_NONE)
end

function ENTITY:CanUnGhost()
    if (not IsValid(self) or !self:IsProp()) then return false end

    local mins, maxs = worldAABB(self, GHOST_PADDING)
    for _, v in ipairs(ents.FindInBox(mins, maxs)) do
        if (v:IsPlayer() and v:Alive() and v:GetMoveType() != MOVETYPE_NOCLIP) then
            return false
        end
    end

    return true
end

timer.Create("APSJanitor", 300, 0, function()
    for _, ent in ipairs(ents.GetAll()) do
        if (IsValid(ent) and not ent:IsPlayerHolding() and ent:IsGhosted() and ent.ghostedAt != nil and ent.ghostedAt < CurTime()) then
            ent:Remove()
        end
    end
end)