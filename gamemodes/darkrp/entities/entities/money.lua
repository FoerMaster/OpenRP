AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "roleplay_base"
ENT.PrintName = "Деньги"
ENT.Model     = "models/openrp/money_00.mdl"

function ENT:Initialize()
    if (self:GetAmount() > 1000) then
        self.Model = "models/openrp/money_01.mdl"
    end

    self.BaseClass.Initialize(self)
end

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Amount")
end

if SERVER then
    function ENT:Use(activator, caller, useType, value)
        if not IsValid(activator) or not activator:IsPlayer() then return end
        if self._taken then return end
        self._taken = true

        activator:AddMoney(self:GetAmount())

        self:Remove()
    end
end