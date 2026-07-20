GM.Jobs = GM.Jobs or {}

local JOBS_PATH = 'gamemodes/' .. engine.ActiveGamemode() .. '/jobs/'

local function register(id, job)
    local class = {
        DisplayName = job.Name,
        Team = job.Team,
        WalkSpeed = job.WalkSpeed,
        RunSpeed = job.RunSpeed,
        JumpPower = job.JumpPower,
        MaxHealth = job.MaxHealth,
        MaxArmor = job.MaxArmor,
        StartHealth = job.StartHealth,
        StartArmor = job.StartArmor,
    }

    if job.Model then
        function class:SetModel(ply)
            local model = job.Model
            if istable(model) then
                model = model[math.random(#model)]
            end
            ply:SetModel(model)
        end
    end

    player_manager.RegisterPlayerClass(id, class, 'player_default')
end

for _, fileName in ipairs(file.Find(JOBS_PATH .. '*.lua', 'GAME')) do
    local code = file.Read(JOBS_PATH .. fileName, 'GAME')
    if not code then continue end

    JOB = {}
    RunString(code, 'jobs/' .. fileName)

    local job = JOB
    JOB = nil

    job.ID = string.StripExtension(fileName)
    GM.Jobs[job.ID] = job

    register(job.ID, job)
end
