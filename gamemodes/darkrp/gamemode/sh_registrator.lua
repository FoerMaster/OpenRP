for _, fileName in ipairs(file.Find('jobs/*.lua', 'LUA')) do
    local path = 'jobs/' .. fileName

    if SERVER then
        AddCSLuaFile(path)
    end

    JOB = {}
    include(path)

    local job = JOB
    JOB = nil

    job.ID = string.StripExtension(fileName)
    player_manager.RegisterPlayerClass(job.ID, job, 'rp_player')
end
