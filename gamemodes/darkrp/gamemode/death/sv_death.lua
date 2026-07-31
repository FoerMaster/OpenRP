roleplay.Death = roleplay.Death or {}

function PLAYER:DropDeathMoney()
    local amount = math.floor(math.min(self:Money() * roleplay.Config.DeathMoneyPercent:GetFloat(), roleplay.Config.DeathMoneyMax:GetInt()))

    if amount <= 0 then return end

    local allow, custom = hook.Run("OnPlayerDropDeathMoney", self, amount)
    if (!allow) then return end

    amount = math.floor(custom or amount)

    local money = self:DropMoney(amount)
    if !money then return end

    self:NotifyError('DeathMoneyLost', amount)

    hook.Run("PlayerDroppedDeathMoney", self, amount, money)
end

function PLAYER:DemoteOnDeath()
    if !self:HasJobFlag(JOB_FLAG_DEMOTE_ON_DEATH) then return end

    local oldJob = self:Job()
    local job = roleplay.Jobs[roleplay.DefaultJob()]

    if oldJob.ID == job.ID then return end

    -- Класс ставим напрямую: PLAYER:SetJob зовет Spawn и возродил бы игрока сразу
    player_manager.SetPlayerClass(self, job.ID)

    hook.Run("PlayerBecameJob", self, job, oldJob)

    self:NotifyError('DemotedOnDeath', oldJob.DisplayName)
end

function roleplay.Death.Handle(ply)
    if !IsValid(ply:GetRagdollEntity()) then
        ply:CreateRagdoll()
    end

    ply:SetNetVar('respawn_at', CurTime() + roleplay.Config.RespawnDelay:GetInt())
    ply:DropDeathMoney()
    ply:DemoteOnDeath()
end

function roleplay.Death.TryRespawn(ply)
    if ply:Alive() then return end
    if CurTime() < ply:GetNetVar('respawn_at', 0) then return end

    local ragdoll = ply:GetRagdollEntity()
    if IsValid(ragdoll) then ragdoll:Remove() end

    ply:SetNetVar('respawn_at', 0)
    ply:Spawn()
end
