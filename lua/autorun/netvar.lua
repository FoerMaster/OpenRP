
if nw then return end
nw 				= {}

local vars 		= {}
local data 		= {
	[0] = {}
}
local globals 	= data[0]
local callbacks = {}

local nw_mt 	= {}
nw_mt.__index 	= nw_mt

debug.getregistry().nw = nw_mt

local ENTITY 	= FindMetaTable 'Entity'

local pairs 	= pairs
local Entity 	= Entity

local net_WriteUInt = net.WriteUInt
local net_ReadUInt 	= net.ReadUInt
local net_Start 	= net.Start
local net_Send 		= (SERVER) and net.Send or net.SendToServer
local net_Broadcast = net.Broadcast

function nw.Register(var, info) -- You must always call this on both the client and server. It will serioulsy break shit if you don't.
	local t = {
		Name = var,
		NetworkString = 'nw_' .. var,
		WriteFunc = net.WriteType,
		ReadFunc = net.ReadType,
		SendFunc = function(self, ent, value, recipients)
			if (recipients ~= nil) then
				net_Send(recipients)
			else
				net_Broadcast()
			end
		end,
	}
	setmetatable(t, nw_mt)
	vars[var] = t

	if (SERVER) then
		util.AddNetworkString(t.NetworkString)
	else
		net.Receive(t.NetworkString, function()
			local index, value = t:_Read()

			-- LocalPlayerVar, прилетевший до валидного LocalPlayer(): _Read вернул
			-- nil-индекс. Раньше такое сообщение записывалось в data[0] (глобалы)
			-- и навсегда мусорило nw.GetGlobal. Отбрасываем — сервер в любом
			-- случае продублирует состояние полным дампом на nw.PlayerSync.
			if (index == nil) then return end

			if (not data[index]) then
				data[index] = {}
			end

			data[index][var] = value

			t:_CallHook(index, value)
		end)
	end

	if (info ~= nil) then -- info arg is only for backwards support, plz dont use
		if info.Read then t:Read(info.Read) end
		if info.Write then t:Write(info.Write) end
		if info.LocalVar then t:SetLocal() end
		if info.GlobalVar then t:SetGlobal() end
		if info.Filter then t:Filter(info.Filter) end
	end

	return t:_Construct()
end

function nw_mt:Write(func, opt)
	self.WriteFunc = function(value)
		func(value, opt)
	end
	return self:_Construct()
end

function nw_mt:Read(func, opt)
	self.ReadFunc = function()
		return func(opt)
	end
	return self:_Construct()
end

function nw_mt:Filter(func)
	self.SendFunc = function(self, ent, value, recipients)
		net_Send(recipients or func(ent, value))
	end
	return self:_Construct()
end

function nw_mt:SetPlayer()
	self.PlayerVar = true
	return self:_Construct()
end

function nw_mt:SetLocalPlayer()
	self.LocalPlayerVar = true
	return self:_Construct()
end
nw_mt.SetLocal = nw_mt.SetLocalPlayer -- backward support

function nw_mt:SetGlobal()
	self.GlobalVar = true
	return self:_Construct()
end

function nw_mt:SetNoSync()
	self.NoSync = true
	return self:_Construct()
end

function nw_mt:SetHook(name)
	self.Hook = name
	return self
end

function nw_mt:_Send(ent, value, recipients)
	net_Start(self.NetworkString)
		self:_Write(ent, value)
	self:SendFunc(ent, value, recipients)
end

function nw_mt:_CallHook(index, value)
	if (self.Hook) then
		if (index != 0) then
			hook.Call(self.Hook, GAMEMODE, Entity(index), value)
		else
			hook.Call(self.Hook, GAMEMODE, value)
		end
	end
end

function nw_mt:_Construct()
	local WriteFunc = self.WriteFunc
	local ReadFunc 	= self.ReadFunc

	if self.PlayerVar then
		self._Write = function(self, ent, value)
			net_WriteUInt(ent:EntIndex(), 7)
			WriteFunc(value)
		end
		self._Read = function(self)
			return net_ReadUInt(7), ReadFunc()
		end
	elseif self.LocalPlayerVar then
		self._Write = function(self, ent, value)
			WriteFunc(value)
		end
		self._Read = function(self)
			-- Payload читаем всегда; индекс nil = "LocalPlayer ещё не создан",
			-- приёмник обязан отбросить такое сообщение (см. net.Receive выше).
			local value = ReadFunc()
			local lp = LocalPlayer()
			if (not IsValid(lp)) then return nil, value end
			return lp:EntIndex(), value
		end
		self.SendFunc = function(self, ent, value, recipients)
			net_Send(ent)
		end
	elseif self.GlobalVar then
		self._Write = function(self, ent, value)
			WriteFunc(value)
		end
		self._Read = function(self)
			return 0, ReadFunc()
		end
	else
		self._Write = function(self, ent, value)
			net_WriteUInt(ent:EntIndex(), 12)
			WriteFunc(value)
		end
		self._Read = function(self)
			return net_ReadUInt(12), ReadFunc()
		end
	end

	return self
end

function nw.GetGlobal(var)
	return globals[var]
end

function ENTITY:GetNetVar(var, default)
	local index = self:EntIndex()
	local v = data[index] and data[index][var]
	if v == nil then return default end
	return v
end

if (SERVER) then
	util.AddNetworkString 'nw.PlayerSync'
	util.AddNetworkString 'nw.NilEntityVar'
	util.AddNetworkString 'nw.NilPlayerVar'
	util.AddNetworkString 'nw.EntityRemoved'
	util.AddNetworkString 'nw.PlayerRemoved'

	net.Receive('nw.PlayerSync', function(len, pl)
		if (pl.EntityCreated ~= true) then
			hook.Call('PlayerEntityCreated', GAMEMODE, pl)

			pl.EntityCreated = true

			for index, _vars in pairs(data) do
				-- Индекс мог освободиться между EntityRemoved и этим дампом (или
				-- быть переиспользован NULL-сущностью): NULL:EntIndex() = 0 писал
				-- значение чужому индексу на клиенте. Глобалы (index 0) шлём всегда.
				local ent = Entity(index)
				if (index == 0 or IsValid(ent)) then
					for var, value in pairs(_vars) do
						if (not vars[var].LocalPlayerVar and not vars[var].NoSync) or (ent == pl) then
							vars[var]:_Send(ent, value, pl)
						end
					end
				end
			end

			if (callbacks[pl] ~= nil) then
				for i = 1, #callbacks[pl] do
					callbacks[pl][i](pl)
				end
			end
			callbacks[pl] = nil
		end
	end)

	hook.Add('EntityRemoved', 'nw.EntityRemoved', function(ent)
		-- отвалился до nw.PlayerSync — его WaitForPlayer-колбэки больше не нужны
		if (callbacks[ent] ~= nil) then callbacks[ent] = nil end

		local index = ent:EntIndex()
		if (index ~= 0) and (data[index] ~= nil) then -- For some reason this kept getting called on Entity(0), not sure why...
			hook.Call('nw.EntityRemoved', nil, ent)
			if ent:IsPlayer() then
				net_Start('nw.PlayerRemoved')
					net_WriteUInt(index, 7)
				net_Broadcast()
			else
				net_Start('nw.EntityRemoved')
					net_WriteUInt(index, 12)
				net_Broadcast()
			end
			
			data[index] = nil
		end
	end)

	function nw.WaitForPlayer(pl, cback)
		if pl.EntityCreated == true then
			cback(pl)
		else
			if callbacks[pl] == nil then
				callbacks[pl] = {}
			end
			callbacks[pl][#callbacks[pl] + 1] = cback
		end
	end

	function nw.SetGlobal(var, value)
		globals[var] = value
		if (value ~= nil) then
			vars[var]:_Send(0, value)
		else
			-- nil-синк адресуем ИМЕНЕМ переменной: порядковые ID расходились бы
			-- между сервером и клиентом, если какая-то переменная зарегистрирована
			-- только в одном реалме (например, аддоном) — и nil стирал бы чужую.
			net_Start('nw.NilEntityVar')
				net_WriteUInt(0, 12)
				net.WriteString(var)
			vars[var]:SendFunc(0, value)
		end
	end

	function ENTITY:SetNetVar(var, value)
		local index = self:EntIndex()

		if (not data[index]) then
			data[index] = {}
		end

		data[index][var] = value
		
		if (value ~= nil) then
			vars[var]:_Send(self, value)
		else
			if self:IsPlayer() then
				net_Start('nw.NilPlayerVar')
				net_WriteUInt(index, 7)
			else
				net_Start('nw.NilEntityVar')
				net_WriteUInt(index, 12)
			end
				net.WriteString(var)
			vars[var]:SendFunc(self, value)
		end
	end
else
	hook.Add('InitPostEntity', 'nw.InitPostEntity', function()
		net_Start('nw.PlayerSync')
		net_Send()
	end)

	net.Receive('nw.NilEntityVar', function()
		local index, name = net_ReadUInt(12), net.ReadString()
		if data[index] and vars[name] then
			data[index][name] = nil
		end
	end)

	net.Receive('nw.NilPlayerVar', function()
		local index, name = net_ReadUInt(7), net.ReadString()
		if data[index] and vars[name] then
			data[index][name] = nil
		end
	end)

	net.Receive('nw.EntityRemoved', function()
		data[net_ReadUInt(12)] = nil
	end)

	net.Receive('nw.PlayerRemoved', function()
		data[net_ReadUInt(7)] = nil
	end)
end