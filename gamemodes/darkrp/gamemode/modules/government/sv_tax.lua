roleplay.Tax = roleplay.Tax or {}

local ANNOUNCE_COLOR = Color(120, 180, 255)

local percent = roleplay.Config.TaxMin:GetInt()

function roleplay.Tax.Collector()
    for _, ply in player.Iterator() do
        if ply:HasJobFlag(JOB_FLAG_COLLECT_TAX) then return ply end
    end
end

function roleplay.Tax.Price(price)
    if !roleplay.Tax.Collector() then return math.floor(price) end

    return math.floor(price * (1 + percent * 0.01))
end

function roleplay.Tax.Collect(ply, salary)
    local collector = roleplay.Tax.Collector()
    if !collector then return 0 end
    if collector == ply then return 0 end

    local tax = math.floor(salary * percent * 0.01)
    if tax <= 0 then return 0 end

    collector:AddMoney(tax)
    collector:NotifyInfo('TaxCollected', ply:Nick(), tax)

    return tax
end

roleplay.Chat.AddCommand('settax', function(sender, arguments)
    local value = tonumber(arguments[1])
    if !value then
        sender:ChatError('InvalidAmount')
        return
    end

    value = math.floor(value)

    local min = roleplay.Config.TaxMin:GetInt()
    local max = roleplay.Config.TaxMax:GetInt()

    if (value < min or value > max) then
        sender:ChatError('TaxRange', min, max)
        return
    end

    if (!hook.Run('OnPlayerChangeTax', sender, value)) then
        sender:ChatError('TaxCantChange')
        return
    end

    percent = value

    roleplay.Chat.Broadcast(ANNOUNCE_COLOR, roleplay.L('TaxChanged', percent))

    hook.Run('PlayerChangedTax', sender, percent)
end)
