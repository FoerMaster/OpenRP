hook.Run("RolePlay.Loading")

AddCSLuaFile('sh_init.lua')
include('sh_init.lua')

util.AddNetworkString('notify')

function GM:InitPostEntity()
end

hook.Call("RolePlay.Loaded", GM)