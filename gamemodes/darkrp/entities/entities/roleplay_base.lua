AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "base_anim"
ENT.PrintName = "Roleplay Base"

ENT.Buyable = false
ENT.Price = 0
ENT.Jobs = nil
ENT.CanBuyShip = false
ENT.ShipCount = 5

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Count")
end

function ENT:Initialize()
    self:SetModel(self.Model)

    if SERVER then
        self:SetSolid(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetCollisionGroup(self.Buyable and COLLISION_GROUP_NONE or COLLISION_GROUP_DEBRIS_TRIGGER)

        if (self:GetCount() < 1) then
            self:SetCount(1)
        end

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end
    end
end

if SERVER then
    function ENT:OnUsed(ply)
    end

    function ENT:Use(activator, caller, useType, value)
        if (!self.Buyable) then return end
        if (!IsValid(activator) or !activator:IsPlayer()) then return end
        if (self:OnUsed(activator) == false) then return end

        self:TakeFromStack(1)

        hook.Run('PlayerUsedEntity', activator, self)
    end

    function ENT:TakeFromStack(amount)
        local left = math.max(self:GetCount() - amount, 0)

        self:SetCount(left)

        if (left <= 0) then
            self:Remove()
        end
    end

    function ENT:MergeStack(other)
        self:SetCount(self:GetCount() + other:GetCount())

        other:SetCount(0)
        other:Remove()
    end

    function ENT:PhysicsCollide(data, collider)
        if (!self.Buyable) then return end

        local other = data.HitEntity
        if (!IsValid(other) or other:GetClass() != self:GetClass()) then return end
        if (self:EntIndex() > other:EntIndex()) then return end
        if (self:GetRPOwner() != other:GetRPOwner()) then return end

        timer.Simple(0, function()
            if (!IsValid(self) or !IsValid(other)) then return end

            self:MergeStack(other)
        end)
    end
end

if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end
end
