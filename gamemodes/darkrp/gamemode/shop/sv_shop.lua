roleplay.Shop = roleplay.Shop or {}

function roleplay.Shop.Get(class)
    local item = scripted_ents.Get(class)
    if (!item or !item.Buyable) then return nil end

    return item
end

function roleplay.Shop.Setup()
    for class in pairs(scripted_ents.GetList()) do
        if (roleplay.Config.Limits[class]) then continue end
        if (!roleplay.Shop.Get(class)) then continue end

        roleplay.Config.Limits[class] = CreateConVar('rp_limit_' .. class, '1',
            FCVAR_ARCHIVE + FCVAR_NOTIFY, 'Сколько предметов ' .. class .. ' может держать игрок')
    end
end

function roleplay.Shop.CanBuy(ply, class)
    local item = roleplay.Shop.Get(class)

    if (!item) then
        ply:ChatError('ShopUnknownItem')
        return nil
    end

    if (item.Jobs and !table.HasValue(item.Jobs, ply:Job().ID)) then
        ply:ChatError('ShopWrongJob')
        return nil
    end

    if (!ply:CheckLimit(class)) then return nil end

    return item
end

local function spawnPosition(ply)
    local trace = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 100,
        filter = ply
    })

    return trace.HitPos + trace.HitNormal * 16
end

function roleplay.Shop.Place(ply, class, count)
    local ent = ents.Create(class)
    if (!IsValid(ent)) then return nil end

    ent:SetPos(spawnPosition(ply))
    ent:SetAngles(Angle(0, ply:EyeAngles().yaw + 180, 0))
    ent:SetCount(count)
    ent:Spawn()

    return ent
end

function roleplay.Shop.Buy(ply, class)
    local item = roleplay.Shop.CanBuy(ply, class)
    if (!item) then return end

    local price = item.Price or 0

    if (!ply:CanAfford(price)) then
        ply:ChatError('NotEnoughMoney')
        return
    end

    local ent = roleplay.Shop.Place(ply, class, 1)
    if (!IsValid(ent)) then return end

    ply:AddCount(class, ent)
    ply:AddMoney(-price)

    ply:SendChat(roleplay.Colors.Money, roleplay.L('ShopBought', item.PrintName or class, price))
end

function roleplay.Shop.BuyShip(ply, class)
    local item = roleplay.Shop.CanBuy(ply, class)
    if (!item) then return end

    if (!item.CanBuyShip) then
        ply:ChatError('ShopNoShip')
        return
    end

    local count = item.ShipCount
    local price = math.floor(count * (item.Price or 0) * roleplay.Config.ShipDiscount:GetFloat())

    if (!ply:CanAfford(price)) then
        ply:ChatError('NotEnoughMoney')
        return
    end

    local crate = roleplay.Shop.Place(ply, 'roleplay_crate', count)
    if (!IsValid(crate)) then return end

    crate:SetStored(class)

    ply:AddCount(class, crate)
    ply:AddMoney(-price)

    ply:SendChat(roleplay.Colors.Money, roleplay.L('ShopBoughtShip', item.PrintName or class, count, price))
end

roleplay.Chat.AddCommand('buyent', function(sender, arguments)
    roleplay.Shop.Buy(sender, string.lower(tostring(arguments[1])))
end)

roleplay.Chat.AddCommand('buyentship', function(sender, arguments)
    roleplay.Shop.BuyShip(sender, string.lower(tostring(arguments[1])))
end)
