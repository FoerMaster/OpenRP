AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "roleplay_base"
ENT.PrintName = "Ящик"
ENT.Model     = "models/props_junk/wood_crate001a.mdl"

function ENT:SetupDataTables()
    self.BaseClass.SetupDataTables(self)

    self:NetworkVar("String", 0, "Stored")
end

if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)

        self:SetCollisionGroup(COLLISION_GROUP_NONE)
        self:SetHealth(roleplay.Config.CrateHealth:GetInt())
    end

    function ENT:Drop(amount)
        local ent = ents.Create(self:GetStored())
        if (!IsValid(ent)) then return nil end

        ent:SetPos(self:GetPos() + self:GetUp() * 16)
        ent:SetAngles(AngleRand())
        ent:SetCount(amount)
        ent:Spawn()

        local owner = self:GetRPOwner()
        if (IsValid(owner)) then
            owner:AddCount(self:GetStored(), ent)
        end

        return ent
    end

    function ENT:Use(activator, caller, useType, value)
        if (!IsValid(activator) or !activator:IsPlayer()) then return end
        if (self:GetCount() < 1) then return end

        local owner = self:GetRPOwner()
        if (IsValid(owner) and !owner:CheckLimit(self:GetStored())) then return end

        if (!self:Drop(1)) then return end

        self:SetCount(self:GetCount() - 1)

        if (self:GetCount() < 1) then
            self:Remove()
        end
    end

    function ENT:OnTakeDamage(dmginfo)
        self:SetHealth(self:Health() - dmginfo:GetDamage())
        if (self:Health() > 0) then return end

        self:Drop(self:GetCount())
        self:Remove()
    end
end
