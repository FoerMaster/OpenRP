hook.Run("RolePlay.Loading")

include('sh_init.lua')

function GM:OnAchievementAchieved() end

hook.Call("RolePlay.Loaded", GM)