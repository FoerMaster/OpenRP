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
    DemoteImmunity = { 'rp_demote_immunity', '300', 'Сколько игрока нельзя увольнять после устройства, секунд' },

    ElectionMinPlayers = { 'rp_election_min_players', '3', 'Игроков на сервере, начиная с которых должность разыгрывается выборами' },
    ElectionSignupSeconds = { 'rp_election_signup_seconds', '300', 'Время приема кандидатов, секунд' },
    ElectionVoteSeconds = { 'rp_election_vote_seconds', '300', 'Время голосования за кандидатов, секунд' },
    ElectionMaxCandidates = { 'rp_election_max_candidates', '5', 'Максимум кандидатов на выборах' },

    LawsEditDelay = { 'rp_laws_edit_delay', '180', 'Пауза между изменениями законов города, секунд' },
    LawMaxLength = { 'rp_law_max_length', '64', 'Предел длины одного закона, символов' },

    LotteryDelay = { 'rp_lottery_delay', '1200', 'Пауза между лотереями, секунд' },
    LotteryVoteSeconds = { 'rp_lottery_vote_seconds', '60', 'Время приема ставок в лотерею' },
    LotteryMinPrice = { 'rp_lottery_min_price', '1000', 'Минимальная ставка в лотерее' },
    LotteryMaxPrice = { 'rp_lottery_max_price', '1000000', 'Максимальная ставка в лотерее' },

    TaxMin = { 'rp_tax_min', '0', 'Минимальный налог, процентов' },
    TaxMax = { 'rp_tax_max', '30', 'Максимальный налог, процентов' },

    CommandDelay = { 'rp_command_delay', '2', 'Пауза между чат-командами, секунд' },
    AdvertCost = { 'rp_advert_cost', '1500', 'Цена одного сообщения в /advert' },
    AdvertDelay = { 'rp_advert_delay', '60', 'Пауза между сообщениями в /advert, секунд' },
    TalkRadius = { 'rp_talk_radius', '300', 'Радиус слышимости текстового чата' },
    VoiceRadius = { 'rp_voice_radius', '300', 'Радиус слышимости голосового чата' },

    RespawnDelay = { 'rp_respawn_delay', '10', 'Задержка перед возрождением, секунд' },
    DeathMoneyPercent = { 'rp_death_money_percent', '0.3', 'Доля кошелька, выпадающая при смерти' },
    DeathMoneyMax = { 'rp_death_money_max', '10000', 'Потолок потери денег за одну смерть' },

    ShipDiscount = { 'rp_ship_discount', '0.8', 'Доля цены при покупке ящиком' },
    CrateHealth = { 'rp_crate_health', '100', 'Прочность ящика' },

    SafeFallSpeed = { 'rp_safe_fall_speed', '580', 'Скорость падения без урона' },
    FatalFallSpeed = { 'rp_fatal_fall_speed', '1024', 'Скорость падения со смертельным уроном' }
}

if SERVER then
    for key, setting in pairs(SETTINGS) do
        roleplay.Config[key] = CreateConVar(setting[1], setting[2], FLAGS, setting[3])
    end

    roleplay.Config.Limits = {
        ['props'] = CreateConVar('rp_limit_props', '100', FLAGS, 'Сколько пропов может заспавнить игрок')
    }

    CreateConVar('rp_default_job', 'citizen', FLAGS + FCVAR_REPLICATED, 'Профессия, выдаваемая при заходе')
    CreateConVar('rp_laws_max', '6', FLAGS + FCVAR_REPLICATED, 'Сколько законов может держать город')

    roleplay.Config.Engine = {
        physcannon_pullforce = '0',
        physcannon_tracelength = '100',
        collision_shake_amp = '0',
        collision_shake_freq = '0',
        collision_shake_time = '0',
        sv_alltalk = '0',
        mp_show_voice_icons = '0'
    }
end

roleplay.Config.AllowedProps = {
    [''] = true
}

function roleplay.DefaultJob()
    local cvar = GetConVar('rp_default_job')

    return cvar and cvar:GetString() or 'citizen'
end

function roleplay.MaxLaws()
    local cvar = GetConVar('rp_laws_max')

    return math.Clamp(cvar and cvar:GetInt() or 6, 1, 15)
end
