AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("evil_crawler/sh_ik.lua")
AddCSLuaFile("evil_crawler/sh_morph.lua")
AddCSLuaFile("evil_crawler/sh_struggle.lua")
AddCSLuaFile("evil_crawler/cl_struggle.lua")
AddCSLuaFile("evil_crawler/cl_flesh.lua")
AddCSLuaFile("evil_crawler/cl_remains.lua")
AddCSLuaFile("evil_crawler/cl_stomach.lua")
include("shared.lua")
if not Evil then return end
include("sv_brain.lua")
include("sv_attack.lua")

local cv_probes = CreateConVar("evil_crawler_debug_probes", "0", 0, "Draw surface probes (needs developer 1)")

local GRAVITY = EvilCrawler.GRAVITY
local STICK_RATE = 8
local HOLD_RATE = 10
local GRIP = 0.05
local REGRIP = 0.2
local PROBE_REACH = 2.2
local RUSH_SPEED = 250
local CROUCH = { 300, 1000, 0.35 }
local SWINGS = { prop_door_rotating = true, func_door_rotating = true }
local LEVELS = { 1, 0.5, 0.25 }
local AHEAD = 1.5
local ROOM_PAD = 40
local ROOM_MIN = 10
local SQUEEZED = 0.35
local DUCK_RATE, RISE_RATE = 12, 4
local FACING = -0.5
local GAP_GRIP = 0.1
local GAP_HOLD = 2
local WATER = bit.bor(CONTENTS_WATER, CONTENTS_SLIME)
local SWIM_PACE = 0.6
local SWIM_PUSH = 9
local SWIM_DRAG = 1.6
local SWIM_TURN = 5
local SURFACE = 8
local SINK = Vector(0, 0, -20)
local SINK_GRAVITY = 0.15

local DOWN, RING = { Vector(0, 0, -1) }, {}
for i = 0, 7 do
	local a = i / 8 * math.pi * 2
	local h = Vector(math.cos(a), math.sin(a), 0)
	DOWN[#DOWN + 1] = (h * 0.7 - Vector(0, 0, 1)):GetNormalized()
	DOWN[#DOWN + 1] = (h * 1.6 - Vector(0, 0, 1)):GetNormalized()
	RING[#RING + 1] = h
end
local WRAP_DEPTHS = { 1.15, 1.6 }
local PROBE_COLOR = Color(0, 200, 255)

local function Rotate(v, axis, angle)
	local c, s = math.cos(angle), math.sin(angle)
	return v * c + axis:Cross(v) * s + axis * (axis:Dot(v) * (1 - c))
end

local function Turn(up, facing, n, t)
	local axis = up:Cross(n)
	local s, c = axis:Length(), up:Dot(n)
	if s < 1e-4 then
		if c > 0 then return up, facing end
		axis = facing
	else
		axis = axis / s
	end
	local angle = math.atan2(s, c) * t
	return Rotate(up, axis, angle):GetNormalized(), Rotate(facing, axis, angle):GetNormalized()
end

function ENT:SpawnFunction(ply, tr, class)
	if not tr.Hit then return end

	local ent = ents.Create(class)
	ent:SetPos(tr.HitPos + tr.HitNormal * self.BodyHeight * EvilCrawler.Setting("size"))
	ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
	ent.Master = ply
	ent.SpawnUp = tr.HitNormal
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self:SetModel("models/props_junk/PopCan01a.mdl")
	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	if self:GetSeed() == 0 then self:SetSeed(math.random(1, 2 ^ 30)) end
	if self:GetBorn() <= 0 then self:SetBorn(EvilCrawler.Setting("size")) end
	local morph = EvilCrawler.Grow(self:GetSeed())
	self.BaseHeight = morph.height
	self:Resize()
	self:SetSaveValue("m_takedamage", 2)
	Evil.Stomach(self)

	local up = self.SpawnUp or Vector(0, 0, 1)
	local facing = self:GetForward()
	facing = facing - up * facing:Dot(up)
	if facing:LengthSqr() < 1e-4 then facing = up:Angle():Up() end

	self.BodyUp = up
	self.Facing = facing:GetNormalized()
	self.Vel = Vector()
	self.Falling = false
	self.Room = self.BodyHeight
	self:Expose()
end

function ENT:Resize()
	local size = self:Size()
	if size == self.Scale then return end
	self.Scale = size
	self.BodyHeight = self.BaseHeight * size
	self:SetCollisionBounds(Vector(-12, -12, -12) * size, Vector(12, 12, 12) * size)
end

function ENT:Think()
	self.Off = self:Switched()
	self:Resize()
	self:Crawl(FrameTime())
	self:UpdateAct(CurTime())
	self:NextThink(CurTime())
	return true
end

function ENT:SenseSurface(pos, fwd, left, up, move)
	local h = self.BodyHeight
	local reach = h * PROBE_REACH
	local normal, point, grip = Vector(), Vector(), 0

	local function probe(from, dir, len, weight)
		local tr = self:Trace(from, from + dir * len)
		if not tr.Hit or tr.StartSolid or tr.HitSky or tr.HitNoDraw then return false end
		if IsValid(tr.Entity) and SWINGS[tr.Entity:GetClass()] then return false end
		if cv_probes:GetBool() then debugoverlay.Line(from, tr.HitPos, 0.05, PROBE_COLOR, true) end
		local near = 1 - math.min(1, tr.HitPos:Distance(pos) / reach)
		local w = weight * near * near
		if self.Gap and tr.HitNormal:Dot(self.Gap) < FACING then w = w * GAP_GRIP end
		normal:Add(tr.HitNormal * w)
		point:Add(tr.HitPos * w)
		grip = grip + w
		return true
	end

	local function world(v)
		return fwd * v.x + left * v.y + up * v.z
	end

	local downHits = 0
	for _, d in ipairs(DOWN) do
		if probe(pos, world(d), reach, 1) then downHits = downHits + 1 end
	end

	for _, d in ipairs(RING) do
		local dir = world(d)
		probe(pos, dir, h * 1.5, math.max(0.25, dir:Dot(move)))
	end

	if downHits < #DOWN * 0.6 then
		for _, depth in ipairs(WRAP_DEPTHS) do
			local below = pos - up * (h * depth)
			for _, d in ipairs(RING) do
				local dir = world(d)
				probe(below + dir * (h * 1.3), -dir, h * 1.3, math.max(0.3, dir:Dot(move)))
			end
		end
	end

	if grip <= 0 then return nil, nil, 0 end
	return normal:GetNormalized(), point / grip, grip
end

function ENT:Headroom(pos, up, height, dir)
	local h = self.BodyHeight
	local floor = pos - up * height
	local squeeze = EvilCrawler.Setting("squeeze") > 0
	local room, ceiling = math.huge, h + ROOM_PAD
	if squeeze then
		local tr = self:Trace(floor + up, floor + up * ceiling)
		if tr.Hit and not tr.StartSolid then
			ceiling = (tr.HitPos - floor):Dot(up)
			room = math.max(ceiling * 0.5, ceiling - ROOM_PAD)
		end
	end
	if not dir then return room end

	for i, k in ipairs(LEVELS) do
		if i > 1 and not squeeze then break end
		local from = floor + up * (h * k)
		if h * k < ceiling then
			local tr = self:Trace(from, from + dir * (h * AHEAD))
			if i == 1 and IsValid(tr.Entity) then self:Bash(tr.Entity, tr.HitPos) end
			if not tr.Hit then return i > 1 and math.min(room, h * k) or room, dir end
		end
	end
	return room
end

function ENT:Wet(at)
	return bit.band(util.PointContents(at), WATER) ~= 0
end

function ENT:SafeMove(from, to)
	local tr = self:Trace(from, to)
	if not tr.Hit then return to end
	if IsValid(tr.Entity) then self:Bash(tr.Entity, tr.HitPos) end
	if tr.StartSolid then return from end
	self.Vel = self.Vel - tr.HitNormal * math.min(0, self.Vel:Dot(tr.HitNormal))
	return tr.HitPos + tr.HitNormal
end

function ENT:Crawl(dt)
	local h = self.BodyHeight
	local pos = self:GetPos()
	local up, fwd = self.BodyUp, self.Facing
	local move = self.Vel:LengthSqr() > 100 and self.Vel:GetNormalized() or fwd
	local normal, anchor, grip = self:SenseSurface(pos, fwd, up:Cross(fwd), up, move)

	local now = CurTime()
	local loose = grip < (self.Falling and REGRIP or GRIP)
	local held = now < (self.LetGoUntil or 0)
	self.Falling = loose or held
	local wet = self:Wet(pos)

	local target, topSpeed, accel
	if not self.Falling or wet and not held then target, topSpeed, accel = self:Steer() end
	if not held and now < (self.LetGoUntil or 0) then
		held = true
		self.Falling = true
	end
	local swimming = self:GetSwimming()
	local swim = wet and not held and (loose or not target and swimming
		or target and self:Wet(target) and (swimming or (target - pos):Dot(up) > h * 0.5)) or false
	self:SetSwimming(swim)

	local speed = self.Vel:Length()
	local rush = math.max(1, speed / RUSH_SPEED)
	local crouch = math.Clamp((speed - CROUCH[1]) / (CROUCH[2] - CROUCH[1]), 0, 1) * CROUCH[3]

	if swim then
		self.Falling, self.Gap = false, nil
		local _, u = EvilCrawler.Stroke(self:GetSeed(), now)
		local push = target and u < EvilCrawler.STROKE_PUSH
		local want = SINK
		if target then
			local to = target - pos
			want = push and to:GetNormalized() * topSpeed * SWIM_PACE * math.Clamp((to:Length() - 24) / (h * 1.5), 0, 1) or vector_origin
		end
		self.Vel = LerpVector(1 - math.exp(-dt * (push and SWIM_PUSH or SWIM_DRAG)), self.Vel, want)
		local step = pos + self.Vel * dt
		if self.Vel.z > 0 and not self:Wet(step + vector_up * SURFACE) then
			self.Vel.z = 0
			step = pos + self.Vel * dt
		end
		pos = self:SafeMove(pos, step)

		if self.Vel:LengthSqr() > 400 then
			fwd = LerpVector(1 - math.exp(-dt * SWIM_TURN), fwd, self.Vel:GetNormalized()):GetNormalized()
		end
		up = up - fwd * up:Dot(fwd)
		if up:LengthSqr() < 1e-4 then up = fwd:Angle():Up() end
		up:Normalize()
	elseif not self.Falling then
		up, fwd = Turn(up, fwd, normal, 1 - math.exp(-dt * STICK_RATE * rush))

		local wish = Vector()
		if target then
			local to = target - pos
			local flat = to - up * to:Dot(up)
			local along = flat:Length()
			if self.Puppeting and along < to:Length() * 0.3 then flat, along = fwd, h * 3 end
			wish = flat:GetNormalized() * topSpeed * math.Clamp((along - 24) / (h * 1.5), 0, 1)
		end

		local height = (pos - anchor):Dot(normal)
		local dir = wish:LengthSqr() > 1 and wish:GetNormalized() or nil
		local room, gap = self:Headroom(pos, normal, height, dir)
		if dir then
			self.Gap, self.GapAt = gap, now
		elseif now - (self.GapAt or 0) > GAP_HOLD then
			self.Gap = nil
		end
		room = math.Clamp(room, ROOM_MIN, h)
		self.Room = Lerp(1 - math.exp(-dt * (room < self.Room and DUCK_RATE or RISE_RATE)), self.Room, room)
		local squeeze = math.Round(1 - self.Room / h, 2)
		if squeeze ~= self:GetSqueeze() then self:SetSqueeze(squeeze) end
		wish = wish * math.max(SQUEEZED, math.min(1, self.Room / self.BaseHeight))

		self.Vel = LerpVector(1 - math.exp(-dt * accel), self.Vel, wish)
		self.Vel = self.Vel - up * self.Vel:Dot(up)

		local err = math.min(h * (1 - crouch), self.Room) - height
		pos = self:SafeMove(pos, pos + self.Vel * dt + normal * (err * (1 - math.exp(-dt * HOLD_RATE * rush))))
	else
		self.Gap = nil
		up, fwd = Turn(up, fwd, vector_up, 1 - math.exp(-dt * 3))
		self.Vel = self.Vel - vector_up * (GRAVITY * (wet and SINK_GRAVITY or 1) * dt)
		if wet then self.Vel = self.Vel * math.exp(-dt * SWIM_DRAG) end
		local want = pos + self.Vel * dt
		pos = self:SafeMove(pos, want)
		if pos ~= want then self.Vel = self.Vel * math.exp(-dt * 6) end
	end

	if not self.Falling and not swim and self.Vel:LengthSqr() > 100 then
		fwd = LerpVector(1 - math.exp(-dt * 6 * rush), fwd, self.Vel:GetNormalized())
	end
	fwd = fwd - up * fwd:Dot(up)
	if fwd:LengthSqr() < 1e-4 then fwd = up:Angle():Up() end
	fwd:Normalize()

	self.BodyUp = up
	self.Facing = fwd
	self:SetPos(pos)
	self:SetAngles(fwd:AngleEx(up))
end
