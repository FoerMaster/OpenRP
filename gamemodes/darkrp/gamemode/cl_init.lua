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

-- Правительство
include('modules/government/sh_election.lua')
include('modules/government/cl_election.lua')
include('modules/government/cl_laws.lua')
include('modules/government/sh_license.lua')

-- Экономика
include('economy/sh_player.lua')

-- Двери
include('doors/sh_door.lua')

-- Строительство
include('building/sh_aps.lua')

-- Смерть
include('death/cl_death.lua')

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

function GM:PhysgunPickup(ply, ent)
    return roleplay.CanPhysgun(ply, ent)
end

function GM:GravGunPunt(ply, ent)
    return false
end

function GM:Think()
    roleplay.HUD.UpdateCursor()
    roleplay.Vote.Prune()
end

-- Цепочка повторяет базовый геймод: своей реализацией мы ее замещаем,
-- а от нее зависят транспорт, JOB:CalcView и WEAPON:CalcView
function GM:CalcView(ply, origin, angles, fov, znear, zfar)
    local death = roleplay.Death.CalcView(ply)
    if death then return death end

    local view = {
        origin = origin,
        angles = angles,
        fov = fov,
        znear = znear,
        zfar = zfar,
        drawviewer = false
    }

    local vehicle = ply:GetVehicle()
    if IsValid(vehicle) then return hook.Run("CalcVehicleView", vehicle, ply, view) end

    player_manager.RunClass(ply, "CalcView", view)

    local weapon = ply:GetActiveWeapon()
    if (IsValid(weapon) and weapon.CalcView) then
        local pos, ang, weaponFov = weapon:CalcView(ply, Vector(view.origin), Angle(view.angles), view.fov)

        view.origin, view.angles, view.fov = pos or view.origin, ang or view.angles, weaponFov or view.fov
    end

    return view
end

function GM:HUDPaint()
    roleplay.HUD.Draw()
    roleplay.Death.Draw()
end

net.Receive('notify', function()
    local text = net.ReadString()
    local kind = net.ReadUInt(3)
    local time = net.ReadUInt(5)

    notification.AddLegacy(text, kind, time)
    surface.PlaySound('buttons/lightswitch2.wav')
end)

hook.Call("RolePlay.Loaded", GM)
