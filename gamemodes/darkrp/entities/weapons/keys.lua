AddCSLuaFile()

SWEP.PrintName = "Ключи"
SWEP.Category = "DarkRP"
SWEP.Author = ""
SWEP.Spawnable = false

SWEP.Slot = 1
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.HoldType = "normal"

SWEP.Base = "weapon_base"
SWEP.ViewModel = "models/weapons/keys_vm/v_keys.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true
SWEP.ViewModelFOV = 72
SWEP.VMOffset = Vector(-2.5, 0, 0)

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.DoorRange = 70

local FRAMES = {
	{0.00, {}},
	{0.30, {
		["ValveBiped.Bip01_R_Forearm"] = Angle(7.8098, -124.382, 0),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(0, -19.3117, 15.1685),
	}},
	{0.40, {
		["ValveBiped.Bip01_R_Forearm"] = Angle(3.68538, -101.385, 1.93108),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(0, -33.3695, 15.1685),
	}},
	{0.50, {
		["ValveBiped.Bip01_R_Forearm"] = Angle(3.68538, -112.726, -0.148692),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(0, -19.3117, 15.1685),
	}},
	{0.60, {
		["ValveBiped.Bip01_R_Forearm"] = Angle(3.68538, -95.4582, 7.26057),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(0, -32.7006, 15.1685),
	}},
	{0.74, {
		["ValveBiped.Bip01_R_Forearm"] = Angle(3.68538, -112.726, -0.148692),
		["ValveBiped.Bip01_R_UpperArm"] = Angle(0, -19.3117, 15.1685),
	}},
	{1.00, {}},
}

if LuaAnim then LuaAnim.Register("keys_knock", FRAMES) end

function SWEP:Initialize()
	self:SetHoldType(self.HoldType)
end

function SWEP:PrimaryAttack()
	self:SetNextSecondaryFire(CurTime() + 1)
    self:SetNextPrimaryFire(CurTime() + 1)
	self:ToggleDoor("lock", false)
end

function SWEP:SecondaryAttack()
	self:SetNextSecondaryFire(CurTime() + 1)
    self:SetNextPrimaryFire(CurTime() + 1)
	self:ToggleDoor("unlock", true)
end

function SWEP:ToggleDoor(state, hard)
	local ply = self:GetOwner()
	if not IsValid(ply) then return end

	local tr = ply:GetEyeTrace()
	local door = tr.Entity

	if not IsValid(door) or not door:IsDoor() then return end
	if ply:GetShootPos():Distance(tr.HitPos) > self.DoorRange then return end

	if not door:CanBeOpenedBy(ply) then
		self:Knock(door, hard)
		return
	end

	if CLIENT then return end

	door:Fire(state)

	local partner = door:GetPartnerDoor()
	if IsValid(partner) then partner:Fire(state) end

	self:EmitSound("doors/door_latch3.wav")
end

function SWEP:Knock(door, hard)
	if not IsFirstTimePredicted() then return end

	self.Idle = CurTime() + (self:PlayAnim(hard and "hard" or "soft") or 1)

	if CLIENT then return end

	local ply = self:GetOwner()
	if IsValid(ply) then ply:RunLuaAnimation(FRAMES) end

	for _, t in ipairs({0.2, 0.5}) do
		timer.Simple(t, function()
			if not IsValid(door) then return end
            if (hard) then
                door:EmitSound("physics/wood/wood_crate_impact_hard1.wav", 80, math.random(120, 175))
            else
                door:EmitSound("physics/wood/wood_crate_impact_hard2.wav", 80, math.random(120, 175))
            end
		end)
	end
end

function SWEP:GetVM()
	local ply = self:GetOwner()
	return IsValid(ply) and ply:GetViewModel()
end

function SWEP:PlayAnim(name)
	local vm = self:GetVM()
	if not IsValid(vm) then return end

	local seq = vm:LookupSequence(name)
	if seq < 0 then return end

	vm:SendViewModelMatchingSequence(seq)
	vm:SetPlaybackRate(1)

	return vm:SequenceDuration(seq)
end

function SWEP:Deploy()
	local vm = self:GetVM()
	if IsValid(vm) then vm:SetBodygroup(0, 1) end

	self:PlayAnim("idle")
	self.Idle = nil

	return true
end

function SWEP:Holster()
	local vm = self:GetVM()
	if IsValid(vm) then vm:SetBodygroup(0, 0) end

	return true
end

function SWEP:Think()
	if not self.Idle or CurTime() < self.Idle then return end

	self.Idle = nil
	self:PlayAnim("idle")
end

function SWEP:Reload()
end

function SWEP:GetViewModelPosition(pos, ang)
	local off = self.VMOffset

	pos = pos + ang:Forward() * off.x + ang:Right() * off.y + ang:Up() * off.z

	return pos, ang
end
