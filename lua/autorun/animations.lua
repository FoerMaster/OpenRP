AddCSLuaFile()

if SERVER then util.AddNetworkString("LuaAnimation") end

LuaAnim = LuaAnim or {}
LuaAnim.Registered = LuaAnim.Registered or {}
LuaAnim.Names = LuaAnim.Names or {}

local ZERO = Angle(0, 0, 0)
local MAX_ENTRIES = 255

local nameOf = LuaAnim.Names

local function IsAnim(frames)
	if not istable(frames) or #frames == 0 or #frames > MAX_ENTRIES then return false end

	local names = {}

	for _, f in ipairs(frames) do
		if not istable(f) or not isnumber(f[1]) or not istable(f[2]) then return false end
		if table.Count(f[2]) > MAX_ENTRIES then return false end

		for name in pairs(f[2]) do names[name] = true end
	end

	return table.Count(names) <= MAX_ENTRIES
end

function LuaAnim.Register(name, frames)
	if not isstring(name) or not IsAnim(frames) then
		ErrorNoHalt("LuaAnim.Register: нужны имя и корректная таблица кадров\n")
		return
	end

	LuaAnim.Registered[name] = frames
	nameOf[frames] = name

	return frames
end

local function WriteAnim(frames)
	local names, index = {}, {}

	for _, f in ipairs(frames) do
		for name in pairs(f[2]) do
			if not index[name] then
				names[#names + 1] = name
				index[name] = #names
			end
		end
	end

	net.WriteUInt(#names, 8)
	for _, name in ipairs(names) do net.WriteString(name) end

	net.WriteUInt(#frames, 8)

	for _, f in ipairs(frames) do
		net.WriteFloat(f[1])
		net.WriteUInt(table.Count(f[2]), 8)

		for name, ang in pairs(f[2]) do
			net.WriteUInt(index[name], 8)
			net.WriteAngle(ang)
		end
	end
end

local function ReadAnim()
	local names = {}
	for i = 1, net.ReadUInt(8) do names[i] = net.ReadString() end

	local frames = {}

	for i = 1, net.ReadUInt(8) do
		local time = net.ReadFloat()
		local bones = {}

		for _ = 1, net.ReadUInt(8) do
			local name = names[net.ReadUInt(8)]
			local ang = net.ReadAngle()

			if name then bones[name] = ang end
		end

		frames[i] = { time, bones }
	end

	return frames
end

if CLIENT then
	local active = {}

	local function Smooth(f)
		return f * f * (3 - 2 * f)
	end

	local function PoseAt(frames, t)
		if t <= frames[1][1] then return frames[1][2] end
		if t >= frames[#frames][1] then return frames[#frames][2] end

		for i = 1, #frames - 1 do
			local a, b = frames[i], frames[i + 1]

			if t < b[1] then
				local span = b[1] - a[1]
				local frac = span > 0 and Smooth((t - a[1]) / span) or 0
				local out = {}

				for name in pairs(a[2]) do out[name] = true end
				for name in pairs(b[2]) do out[name] = true end

				for name in pairs(out) do
					out[name] = LerpAngle(frac, a[2][name] or ZERO, b[2][name] or ZERO)
				end

				return out
			end
		end

		return frames[#frames][2]
	end

	local function Apply(ply, bones, pose)
		for name in pairs(bones) do
			local id = ply:LookupBone(name)
			if id then ply:ManipulateBoneAngles(id, pose[name] or ZERO) end
		end
	end

	function LuaAnim.Stop(ply)
		local anim = active[ply]
		if not anim then return end

		active[ply] = nil
		if IsValid(ply) then Apply(ply, anim.bones, {}) end
	end

	function LuaAnim.Play(ply, frames)
		if not IsValid(ply) or not IsAnim(frames) then return false end

		LuaAnim.Stop(ply)

		local bones = {}
		for _, f in ipairs(frames) do
			for name in pairs(f[2]) do bones[name] = true end
		end

		active[ply] = {
			frames = frames,
			bones = bones,
			start = CurTime(),
			len = frames[#frames][1],
		}

		return true
	end

	hook.Add("Think", "LuaAnimation", function()
		for ply, anim in pairs(active) do
			if not IsValid(ply) then
				active[ply] = nil
			else
				local t = CurTime() - anim.start

				if t >= anim.len then
					LuaAnim.Stop(ply)
				else
					Apply(ply, anim.bones, PoseAt(anim.frames, t))
				end
			end
		end
	end)

	net.Receive("LuaAnimation", function()
		local ply = net.ReadEntity()

		if net.ReadBool() then
			if IsValid(ply) then LuaAnim.Stop(ply) end
			return
		end

		local frames

		if net.ReadBool() then
			frames = LuaAnim.Registered[net.ReadString()]
		else
			frames = ReadAnim()
		end

		if IsValid(ply) and frames then LuaAnim.Play(ply, frames) end
	end)
end

local PLAYER = FindMetaTable("Player")

function PLAYER:RunLuaAnimation(anim)
	local name, frames

	if isstring(anim) then
		name = anim
		frames = LuaAnim.Registered[anim]
	else
		frames = anim
		name = nameOf[anim]
	end

	if CLIENT then
		if not frames then return false end
		return LuaAnim.Play(self, frames)
	end

	if not name and not IsAnim(frames) then
		ErrorNoHalt("RunLuaAnimation: нужна таблица кадров или имя из LuaAnim.Register\n")
		return false
	end

	net.Start("LuaAnimation")
		net.WriteEntity(self)
		net.WriteBool(false)
		net.WriteBool(name != nil)

		if name then
			net.WriteString(name)
		else
			WriteAnim(frames)
		end
	net.SendPVS(self:WorldSpaceCenter())

	return true
end

function PLAYER:StopLuaAnimation()
	if CLIENT then
		LuaAnim.Stop(self)
		return
	end

	net.Start("LuaAnimation")
		net.WriteEntity(self)
		net.WriteBool(true)
	net.SendPVS(self:WorldSpaceCenter())
end
