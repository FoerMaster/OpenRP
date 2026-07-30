hook.Run("RolePlay.Loading")

include('sh_init.lua')

-- База: сетевые переменные, конфиг и локализация, от них зависят все модули
include('netvars.lua')
include('config.lua')
include('lang.lua')

-- Команды и профессии: регистратор выполняет файлы из jobs/,
-- поэтому команды (TEAM_*) должны быть объявлены раньше
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

net.Receive('notify', function()
    local text = net.ReadString()
    local type = net.ReadUInt(3)
    local time = net.ReadUInt(5)

    notification.AddLegacy(text, type, time)
    surface.PlaySound('buttons/lightswitch2.wav')
end)

hook.Call("RolePlay.Loaded", GM)
