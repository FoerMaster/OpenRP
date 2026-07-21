GM.Version = "2.3.2"
GM.Name = "DarkRP"
GM.Author = "By Foer"

PLAYER = FindMetaTable("Player")
ENTITY = FindMetaTable("Entity")

-- База: сетевые переменные и конфиг, от них зависят все модули
file.AutoInclude('netvars.lua')
file.AutoInclude('config.lua')

-- Команды и профессии: регистратор выполняет файлы из jobs/,
-- поэтому команды (TEAM_*) должны быть объявлены раньше
file.AutoInclude('teams.lua')
file.AutoInclude('sh_jobs.lua')
file.AutoInclude('sh_registrator.lua')

-- Ядро: хуки геймода
file.AutoInclude('sh_player.lua')
file.AutoInclude('sv_entities.lua')
file.AutoInclude('sv_player.lua')

-- Экономика
file.AutoInclude('economy/sh_player.lua')
file.AutoInclude('economy/sv_player.lua')

-- Двери
file.AutoInclude('doors/sh_door.lua')
file.AutoInclude('doors/sv_door.lua')
file.AutoInclude('doors/sv_player.lua')

-- Строительство
file.AutoInclude('building/sv_player.lua')
file.AutoInclude('building/sv_aps.lua')
file.AutoInclude('building/sv_command.lua')
