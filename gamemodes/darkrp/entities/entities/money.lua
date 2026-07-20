AddCSLuaFile()

ENT.Type      = "anim"
ENT.Base      = "roleplay_base"
ENT.PrintName = "Деньги"
ENT.Model     = "models/props/cs_assault/money.mdl"

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "Amount")
end

function ENT:Use(activator, caller, useType, value)
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if self._taken then return end
    self._taken = true

    activator:AddMoney(self:GetAmount())

    self:Remove()
end
