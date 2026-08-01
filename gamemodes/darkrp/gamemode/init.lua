hook.Run("RolePlay.Loading")

resource.AddFile('resource/fonts/Montserrat-Regular.ttf')
resource.AddFile('resource/fonts/Montserrat-Bold.ttf')
resource.AddFile('resource/fonts/Onest-Regular.ttf')
resource.AddFile('resource/fonts/Onest-Bold.ttf')

AddCSLuaFile('sh_init.lua')
AddCSLuaFile('cl_init.lua')

AddCSLuaFile('netvars.lua')
AddCSLuaFile('config.lua')
AddCSLuaFile('lang.lua')
AddCSLuaFile('teams.lua')
AddCSLuaFile('sh_jobs.lua')
AddCSLuaFile('sh_registrator.lua')
AddCSLuaFile('sh_player.lua')
AddCSLuaFile('economy/sh_player.lua')
AddCSLuaFile('doors/sh_door.lua')
AddCSLuaFile('building/sh_aps.lua')
AddCSLuaFile('modules/government/sh_election.lua')
AddCSLuaFile('modules/government/sh_license.lua')
AddCSLuaFile('modules/government/cl_election.lua')
AddCSLuaFile('modules/government/cl_laws.lua')
AddCSLuaFile('chat/cl_chat.lua')
AddCSLuaFile('vgui/cl_skin.lua')
AddCSLuaFile('voting/cl_init.lua')
AddCSLuaFile('death/cl_death.lua')
AddCSLuaFile('hud/cl_init.lua')

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

-- Ядро: хуки геймода
include('sh_player.lua')
include('sv_entities.lua')
include('sv_player.lua')

-- Чат
include('chat/sv_chat.lua')
include('chat/sv_channels.lua')

-- Голосования
include('voting/sv_init.lua')

-- Смена профессий
include('sv_jobs.lua')

-- Правительство
include('modules/government/sh_election.lua')
include('modules/government/sv_election.lua')
include('modules/government/sv_laws.lua')
include('modules/government/sv_lottery.lua')
include('modules/government/sv_tax.lua')
include('modules/government/sh_license.lua')
include('modules/government/sv_license.lua')

-- Экономика
include('economy/sh_player.lua')
include('economy/sv_player.lua')

-- Двери
include('doors/sh_door.lua')
include('doors/sv_door.lua')
include('doors/sv_player.lua')

-- Смерть
include('death/sv_death.lua')

-- Магазин
include('shop/sv_shop.lua')

-- Строительство
include('building/sh_aps.lua')
include('building/sv_player.lua')
include('building/sv_aps.lua')
include('building/sv_command.lua')

util.AddNetworkString('notify')

function GM:InitPostEntity()
    for command, value in pairs(roleplay.Config.Engine) do
        RunConsoleCommand(command, value)
    end

    roleplay.Shop.Setup()
    roleplay.Laws.Setup()
end

hook.Call("RolePlay.Loaded", GM)
