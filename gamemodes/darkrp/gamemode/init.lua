hook.Run("RolePlay.Loading")

AddCSLuaFile('sh_init.lua')
include('sh_init.lua')

hook.Call("RolePlay.Loaded", GM)