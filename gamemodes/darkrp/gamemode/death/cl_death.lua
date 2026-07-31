roleplay.Death = roleplay.Death or {}

local VIEW = {
    origin = Vector(0, 0, 0),
    angles = Angle(0, 0, 0),
    fov = 90,
    znear = 1
}

local ZERO_SCALE = Vector(0, 0, 0)
local EYE_OFFSET = 8

local function hideHead(ragdoll)
    ragdoll.headHidden = true

    ragdoll:InvalidateBoneCache()
    ragdoll:SetupBones()

    for bone = 0, ragdoll:GetBoneCount() - 1 do
        if string.find(string.lower(ragdoll:GetBoneName(bone) or ''), 'head', 1, true) then
            local matrix = ragdoll:GetBoneMatrix(bone)
            if matrix then matrix:SetScale(ZERO_SCALE) end

            return
        end
    end
end

function roleplay.Death.CalcView(ply)
    if ply:Health() > 0 then return end

    local ragdoll = ply:GetRagdollEntity()
    if !IsValid(ragdoll) then return end

    local attachment = ragdoll:GetAttachment(ragdoll:LookupAttachment('eyes'))
    if !attachment then return end
    if !ragdoll.headHidden then
        hideHead(ragdoll)
    end

    VIEW.origin = attachment.Pos + attachment.Ang:Up() * EYE_OFFSET
    VIEW.angles = attachment.Ang

    return VIEW
end

function roleplay.Death.Draw()
    local ply = LocalPlayer()
    if ply:Alive() then return end

    local left = ply:GetNetVar('respawn_at', 0) - CurTime()
    local text = left > 0 and roleplay.L('DeathRespawn', math.ceil(left)) or roleplay.L('DeathPressKey')

    draw.DrawText(text, 'DebugOverlay', 5, 50, color_white)
end
