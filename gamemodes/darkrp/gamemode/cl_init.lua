hook.Run("RolePlay.Loading")

include('sh_init.lua')

function GM:OnAchievementAchieved() end

net.Receive('notify', function()
    local text = net.ReadString()
    local type = net.ReadUInt(3)
    local time = net.ReadUInt(5)

    notification.AddLegacy(text, type, time)
    surface.PlaySound('buttons/lightswitch2.wav')
end)



hook.Call("RolePlay.Loaded", GM)