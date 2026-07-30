hook.Run("RolePlay.Loading")

include('sh_init.lua')

include('netvars.lua')
include('config.lua')
include('lang.lua')
include('teams.lua')
include('sh_jobs.lua')
include('sh_registrator.lua')

-- Ядро
include('sh_player.lua')

-- Чат
include('chat/cl_chat.lua')

-- VGUI
include('vgui/cl_skin.lua')

-- Голосования
include('voting/cl_init.lua')

-- Экономика
include('economy/sh_player.lua')

-- Двери
include('doors/sh_door.lua')

include('hud/cl_init.lua')

function GM:OnAchievementAchieved() end

function GM:ChatText(index, name, text, messageType)
    return roleplay.Chat.HiddenTypes[messageType] == true
end

function GM:HUDShouldDraw(name)
    return not roleplay.HUD.Hidden[name]
end

function GM:PlayerBindPress(ply, bind, pressed)
    return roleplay.Vote.HandleBind(bind, pressed)
end

function GM:Think()
    roleplay.HUD.UpdateCursor()
    roleplay.Vote.Prune()
end

function GM:HUDPaint()
    roleplay.HUD.Draw()
end

net.Receive('notify', function()
    local text = net.ReadString()
    local kind = net.ReadUInt(3)
    local time = net.ReadUInt(5)

    notification.AddLegacy(text, kind, time)
    surface.PlaySound('buttons/lightswitch2.wav')
end)

hook.Call("RolePlay.Loaded", GM)
