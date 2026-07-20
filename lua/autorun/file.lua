function file.AutoInclude(path)
    local fileName = string.GetFileFromFilename(path)
    if string.find(fileName, '_sv.lua', 1, true) or string.StartsWith(fileName, 'sv_') then
        if SERVER then
            include(path)
        end
        return true, false
    elseif string.find(fileName, '_cl.lua', 1, true) or string.StartsWith(fileName, 'cl_') then
        if SERVER then
            AddCSLuaFile(path)
        end
        if CLIENT then
            include(path)
        end
        return false, true
    else
        if SERVER then
            AddCSLuaFile(path)
        end
        include(path)
        return true, true
    end
end