AddCSLuaFile()

SWEP.PrintName = "Ключи"
SWEP.Category  = "DarkRP"
SWEP.Author    = ""
SWEP.Spawnable = false

SWEP.Slot         = 1
SWEP.SlotPos      = 0
SWEP.DrawAmmo     = false
SWEP.DrawCrosshair = true
SWEP.HoldType     = "normal"

SWEP.Base       = "weapon_base"
SWEP.ViewModel  = ""
SWEP.WorldModel = ""

SWEP.Primary.ClipSize    = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic   = false
SWEP.Primary.Ammo        = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

SWEP.DoorRange = 100

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.3)
    self:ToggleDoor("lock")
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 0.3)
    self:ToggleDoor("unlock")
end

function SWEP:ToggleDoor(state)
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local tr = owner:GetEyeTrace()
    local door = tr.Entity

    if not IsValid(door) or not door:IsDoor() then return end
    if owner:GetShootPos():Distance(tr.HitPos) > self.DoorRange then return end

    if door:DoorIsOwned() and not door:CanBeOpenedBy(owner) then
        self:Knock(door)
        return
    end

    door:Fire(state)

    local partner = door:GetPartnerDoor()
    if IsValid(partner) then
        partner:Fire(state)
    end

    self:EmitSound("doors/door_latch3.wav")
end

function SWEP:Knock(door)
    door:EmitSound("physics/wood/wood_crate_impact_hard2.wav", 80, math.random(95, 105))
end

function SWEP:Reload()
end
