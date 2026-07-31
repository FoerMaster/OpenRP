roleplay.Config = roleplay.Config or {}

local FLAGS = FCVAR_ARCHIVE + FCVAR_NOTIFY

local SETTINGS = {
    StartMoney = { 'rp_start_money', '50000', 'Стартовые деньги при первом заходе' },
    SalaryDelay = { 'rp_salary_delay', '600', 'Период начисления зарплаты, секунд' },
    MaxDropMoney = { 'rp_max_drop_money', '10000', 'Максимум за один /dropmoney' },

    DoorCost = { 'rp_door_cost', '1200', 'Цена покупки двери' },
    DoorSellPercent = { 'rp_door_sell_percent', '0.66', 'Доля цены, возвращаемая при продаже двери' },
    MaxDoors = { 'rp_max_doors', '5', 'Сколько дверей может держать один игрок' },
    MaxDoorNameLength = { 'rp_max_door_name_length', '16', 'Предел длины названия двери, символов' },

    JobChangeDelay = { 'rp_job_change_delay', '120', 'Пауза между сменами профессии, секунд' },
    JobVoteSeconds = { 'rp_job_vote_seconds', '20', 'Время голосования за устройство на работу' },
    DemoteVoteSeconds = { 'rp_demote_vote_seconds', '30', 'Время голосования за увольнение' },
    MinPlayersToDemote = { 'rp_min_players_to_demote', '4', 'Минимум игроков для команды /demote' },

    CommandDelay = { 'rp_command_delay', '2', 'Пауза между чат-командами, секунд' },
    TalkRadius = { 'rp_talk_radius', '300', 'Радиус слышимости текстового чата' },
    VoiceRadius = { 'rp_voice_radius', '300', 'Радиус слышимости голосового чата' },

    RespawnDelay = { 'rp_respawn_delay', '10', 'Задержка перед возрождением, секунд' },
    DeathMoneyPercent = { 'rp_death_money_percent', '0.3', 'Доля кошелька, выпадающая при смерти' },
    DeathMoneyMax = { 'rp_death_money_max', '10000', 'Потолок потери денег за одну смерть' },

    SafeFallSpeed = { 'rp_safe_fall_speed', '580', 'Скорость падения без урона' },
    FatalFallSpeed = { 'rp_fatal_fall_speed', '1024', 'Скорость падения со смертельным уроном' }
}

if (SERVER) then
    for key, setting in pairs(SETTINGS) do
        roleplay.Config[key] = CreateConVar(setting[1], setting[2], FLAGS, setting[3])
    end

    roleplay.Config.Limits = {
        ['props'] = CreateConVar('rp_limit_props', '100', FLAGS, 'Сколько пропов может заспавнить игрок')
    }

    CreateConVar('rp_default_job', 'citizen', FLAGS + FCVAR_REPLICATED, 'Профессия, выдаваемая при заходе')
end

roleplay.Config.AllowedProps = {
    [''] = true
}

function roleplay.DefaultJob()
    local cvar = GetConVar('rp_default_job')

    return cvar and cvar:GetString() or 'citizen'
end
