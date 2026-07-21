local jobsDir = engine.ActiveGamemode() .. '/gamemode/jobs/'
local jobFiles = file.Find(jobsDir .. '*.lua', 'LUA')


for _, fileName in ipairs(jobFiles) do
    local path = 'jobs/' .. fileName

    if SERVER then
        AddCSLuaFile(path)
    end

    JOB = {}
    include(path)

    local job = JOB
    JOB = nil

    job.ID = string.StripExtension(fileName)
    player_manager.RegisterClass(job.ID, job, 'rp_player')
end
