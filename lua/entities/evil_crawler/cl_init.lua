include("shared.lua")
include("evil_crawler/cl_flesh.lua")
include("evil_crawler/cl_remains.lua")
include("evil_crawler/cl_struggle.lua")

local entMeta = FindMetaTable("Entity")
local math = math
local IsValid = IsValid

local cv_debug = CreateClientConVar("evil_crawler_debug", "0", false, false, "Draw foot targets")

language.Add("evil_crawler", "Evil Crawler")
killicon.Add("evil_crawler", "killicons/evil_crawler.png", Color(255, 80, 0))

local LEAD_TIME = 0.18
local SNAP_GAP = 0.5
local MAX_AIRBORNE = 0.4
local SKITTER = { 400, 1000, 0.6 }
local MAX_LEAD = 0.9
local FOOT_SOUND_GAP = 0.03
local MOOD_AGITATION = { [0] = 0, [1] = 0.45, [2] = 1 }
local THREAT_ARC = 35
local IK_ITERATIONS = 3
local LOD_DISTANCE = 1500
local MIN_SHRINK = 0.3
local SWIM_STILL = 60
local SWIM_FAST = 250
local SWIM_OPEN = 0.65

local ACT_NONE, ACT_STRIKE, ACT_DRAG, ACT_FEED =
	EvilCrawler.ACT_NONE, EvilCrawler.ACT_STRIKE, EvilCrawler.ACT_DRAG, EvilCrawler.ACT_FEED
local ACT_GRAPPLE, ACT_STUN, ACT_SEAR = EvilCrawler.ACT_GRAPPLE, EvilCrawler.ACT_STUN, EvilCrawler.ACT_SEAR
local ACT_OUT, ACT_DEAD = EvilCrawler.ACT_OUT, EvilCrawler.ACT_DEAD
local STUN_TIME = EvilCrawler.STUN_TIME
local WINDUP, LUNGE, WRAP_TIME = EvilCrawler.STRIKE_WINDUP, EvilCrawler.STRIKE_LUNGE, EvilCrawler.WRAP_TIME
local PULL_TIME = EvilCrawler.PULL_TIME
local BITE_JAB, BITE_IN, BITE_RIP = EvilCrawler.BITE_JAB, EvilCrawler.BITE_IN, EvilCrawler.BITE_RIP
local LUMP_TIME = EvilCrawler.LUMP_TIME
local BiteCycle, BiteBone, CurrentPart = EvilCrawler.BiteCycle, EvilCrawler.BiteBone, EvilCrawler.CurrentPart
local Stroke, STROKE_PUSH = EvilCrawler.Stroke, EvilCrawler.STROKE_PUSH
local STAB_DEPTH = 10
local SWALLOW_GAP = { 1.2, 2.2 }
local ROLE_COUNT = { [ACT_STRIKE] = 1, [ACT_DRAG] = 1, [ACT_FEED] = 1 + EvilCrawler.FEEDERS, [ACT_GRAPPLE] = 1, [ACT_SEAR] = 4 }
local CURL = 0.25
local SPRAWL = 0.85
local DEATH_CURL = 1.5
local CORPSE_TIME, ROT_TIME = EvilCrawler.CORPSE_TIME, EvilCrawler.ROT_TIME
local COIL_POINTS = 26
local REACH_POINTS = 8

local FOOT_SOUNDS = {
	"npc/antlion/foot1.wav",
	"npc/antlion/foot2.wav",
	"npc/antlion/foot3.wav",
	"npc/antlion/foot4.wav",
}
local SWIM_SOUNDS = {
	"player/footsteps/wade1.wav",
	"player/footsteps/wade2.wav",
	"player/footsteps/wade3.wav",
	"player/footsteps/wade4.wav",
}

local FLESH = Color(44, 34, 40)
local BONE = Color(170, 160, 145)
local BLOOD = Color(80, 6, 8)
local HOT = Color(255, 60, 15)
local WHITE_HOT = Color(255, 210, 140)
local HEAT_RISE, HEAT_FADE = 4, 1.5
local DEBUG_TARGET = Color(0, 255, 0)
local DEBUG_DANGLE = Color(255, 160, 0)

local Flesh = EvilCrawler.Flesh
local SolveChain = EvilCrawler.SolveChain
local CatmullRom = Flesh.CatmullRom

function ENT:Initialize()
	self:SetRenderBounds(Vector(-400, -400, -400), Vector(400, 400, 400))
	self:DestroyShadow()
end

function ENT:Think()
	local now = CurTime()
	local left = self:GetRageUntil() - now
	local want = left > 0 and math.min(1, left / HEAT_FADE) or 0
	self.Heat = math.Approach(self.Heat or 0, want, FrameTime() * HEAT_RISE)
	local heat = self.Heat
	if heat <= 0 then return end

	local light = DynamicLight(self:EntIndex())
	if light then
		light.pos = self:GetPos()
		light.r, light.g, light.b = 255, 90, 30
		light.brightness = 3 * heat
		light.size = 320
		light.decay = 1000
		light.dietime = now + 0.1
	end

	local morph = self.Morph
	if not morph or not self.LimbState or math.random() > heat * FrameTime() * 40 then return end
	local st = self.LimbState[morph.legs[math.random(#morph.legs)]]
	local p = st and st.points[math.random(#st.points)]
	if not p then return end
	self.Emitter = self.Emitter or ParticleEmitter(self:GetPos())
	local ember = self.Emitter:Add("effects/fire_embers" .. math.random(3), p)
	if not ember then return end
	ember:SetVelocity(VectorRand() * 30 + Vector(0, 0, 50))
	ember:SetGravity(Vector(0, 0, 80))
	ember:SetAirResistance(40)
	ember:SetDieTime(math.Rand(0.6, 1.2))
	ember:SetStartAlpha(255)
	ember:SetEndAlpha(0)
	ember:SetStartSize(math.Rand(3, 6))
	ember:SetEndSize(0)
end

function ENT:OnRemove()
	if self.Emitter then self.Emitter:Finish() end
end

function ENT:Creature(myTbl)
	local seed = myTbl.GetSeed(self)
	if seed == 0 then return end

	if myTbl.GrownFrom ~= seed then
		myTbl.GrownFrom = seed
		myTbl.Morph = EvilCrawler.Grow(seed)
		myTbl.BodyHeight = myTbl.Morph.height
		myTbl.LimbState = nil
	end
	return myTbl.Morph
end

local function Wobble(t, phase, freq)
	return Vector(
		math.sin(t * freq + phase) + 0.5 * math.sin(t * freq * 2.3 + phase * 1.7),
		math.sin(t * freq * 1.3 + phase * 2.1) + 0.5 * math.sin(t * freq * 2.9 + phase),
		math.sin(t * freq * 0.9 + phase * 3.3) + 0.5 * math.sin(t * freq * 3.1 + phase * 0.6)
	)
end

local function Smooth(t)
	return t * t * (3 - 2 * t)
end

local function Pose(st, limb, root, target, bow, t, shake, shrink)
	local pts = st.points
	local n = limb.segments + 1
	local wobble = limb.length * shake * shrink
	local lengths = limb.lengths
	if shrink < 1 then
		lengths = st.lengths or {}
		st.lengths = lengths
		for i, l in ipairs(limb.lengths) do lengths[i] = l * shrink end
	end
	for i = 1, n do
		local f = (i - 1) / (n - 1)
		local arch = math.sin(f * math.pi)
		local noise = Wobble(t, limb.phase + i * 1.9, limb.freq) * wobble + st.twitch
		pts[i] = LerpVector(f, root, target) + (bow + noise) * arch
	end
	SolveChain(pts, lengths, root, target, IK_ITERATIONS)
end

local function Resample(pts, m, out)
	local n = #pts
	for i = 1, m do
		local u = (i - 1) / (m - 1) * (n - 1)
		local seg = math.min(math.floor(u), n - 2)
		local s = seg + 1
		out[i] = CatmullRom(pts[math.max(s - 1, 1)], pts[s], pts[s + 1], pts[math.min(s + 2, n)], u - seg)
	end
	return out
end

local function Bone(ent, name)
	local bone = ent:LookupBone(name)
	return bone and ent:GetBonePosition(bone)
end

local PLAYER_CHEST = Vector(0, 0, 46)
local PLAYER_COIL = { Vector(0, 0, 12), Vector(0, 0, 58), 11 }

local function Chest(ent)
	if ent:IsPlayer() then return ent:GetPos() + PLAYER_CHEST end
	return Bone(ent, "ValveBiped.Bip01_Spine2") or ent:WorldSpaceCenter()
end

function ENT:AssignRoles(morph, act, victim, pos, fwd, left)
	local roles = {}
	if act == ACT_NONE or not IsValid(victim) then return roles end

	local d = victim:WorldSpaceCenter() - pos
	local yaw = math.deg(math.atan2(d:Dot(left), d:Dot(fwd)))
	local order = { unpack(morph.legs) }
	table.sort(order, function(a, b)
		return math.abs(math.AngleDifference(a.angle, yaw)) < math.abs(math.AngleDifference(b.angle, yaw))
	end)
	if act == ACT_STRIKE then
		self.Striker = order[1]
	elseif self.Striker then
		table.RemoveByValue(order, self.Striker)
		table.insert(order, 1, self.Striker)
	end

	local count = math.min(ROLE_COUNT[act] or 0, #order - 3)
	for k = 1, count do
		roles[order[k]] = { index = k, count = count }
	end
	return roles
end

local function BitePose(victim, seed, k, t, up, now, limb, bites)
	local n, u = BiteCycle(k, t)
	local center = victim:WorldSpaceCenter()
	local part = CurrentPart(victim)

	local function spot(m)
		local name = bites[m]
		if not name then
			name = BiteBone(seed, k, m, part)
			bites[m] = name
		end
		local p = Bone(victim, name) or center
		local side = p - center
		side = side - up * side:Dot(up)
		side = side:LengthSqr() > 1 and side:GetNormalized() or up:Angle():Right()
		local a = k * math.pi * 0.5 + m * 0.6
		side = side * math.cos(a) + up:Cross(side) * math.sin(a)
		return p + side * 3, p + up * 45 + side * 12, side
	end

	local bite, out, side = spot(n)
	local _, from = spot(n - 1)
	bites[n - 3] = nil
	local cocked = bite + up * 38 + side * 14
	local deep = bite + (bite - cocked):GetNormalized() * STAB_DEPTH

	if u < BITE_JAB then
		local f = u / BITE_JAB
		return LerpVector(Smooth(f), from, cocked) + Wobble(now * 11, limb.phase, limb.freq) * (2.5 * f), n, u
	elseif u < BITE_IN then
		local f = (u - BITE_JAB) / (BITE_IN - BITE_JAB)
		return LerpVector(f * f, cocked, deep), n, u
	elseif u < BITE_RIP then
		return deep + Wobble(now * 30, limb.phase, limb.freq) * 1.5, n, u
	end
	local f = (u - BITE_RIP) / (1 - BITE_RIP)
	return LerpVector(1 - (1 - f) ^ 3, deep, out), n, u
end

local function GripAxis(body)
	if body:IsPlayer() then
		local feet = body:GetPos()
		return feet + PLAYER_COIL[1], feet + PLAYER_COIL[2], PLAYER_COIL[3]
	end
	local part = CurrentPart(body)
	if part and part > 1 then
		local top = Bone(body, EvilCrawler.PARTS[part].grip[1])
		local lf, rf = Bone(body, "ValveBiped.Bip01_L_Foot"), Bone(body, "ValveBiped.Bip01_R_Foot")
		if top and lf and rf then return top, (lf + rf) * 0.5, 7 end
	end
	local pelvis = Bone(body, "ValveBiped.Bip01_Pelvis")
	local neck = Bone(body, "ValveBiped.Bip01_Neck1")
	if pelvis and neck then return pelvis, neck, 9 end
	local c = body:WorldSpaceCenter()
	return c - vector_up * 14, c + vector_up * 14, 9
end

local function Girth(body)
	if body:IsPlayer() then return GripAxis(body) end
	local c, size = body:WorldSpaceCenter(), body:OBBMaxs() - body:OBBMins()
	return c - vector_up * (size.z * 0.3), c + vector_up * (size.z * 0.3), math.min(size.x, size.y) * 0.5
end

local function Coil(st, leg, role, root, a, b, r, bulge, t)
	if root:DistToSqr(b) < root:DistToSqr(a) then a, b = b, a end
	local axis = b - a
	local span = axis:Length()
	axis = axis / math.max(span, 1)
	local u = axis:Cross(bulge)
	if u:LengthSqr() < 1e-4 then u = axis:Angle():Right() end
	u:Normalize()
	local v = axis:Cross(u)

	r = r + leg.width * 0.6
	local climb = math.Clamp(t / WRAP_TIME, 0, 1)
	local turns = 2 + (leg.phase % 1) * 0.8
	local spin = role.index % 2 == 0 and 1 or -1
	local theta0 = leg.phase

	local entry = a + (u * math.cos(theta0) + v * math.sin(theta0)) * r
	local mid = (root + entry) * 0.5 + bulge * (root:Distance(entry) * 0.3)

	local pts = st.coil or {}
	st.coil = pts
	for i = 1, REACH_POINTS do
		local f = (i - 1) / REACH_POINTS
		pts[i] = root * ((1 - f) ^ 2) + mid * (2 * (1 - f) * f) + entry * (f * f)
	end

	local helix = COIL_POINTS - REACH_POINTS
	for i = 0, helix - 1 do
		local f = i / (helix - 1) * climb
		local theta = theta0 + spin * f * turns * math.pi * 2
		pts[REACH_POINTS + 1 + i] = a + axis * (span * f) + (u * math.cos(theta) + v * math.sin(theta)) * r
	end
end

function ENT:FootTarget(myTbl, root, rest, up)
	local h = myTbl.BodyHeight

	local reach = myTbl.TraceMyTbl(self, myTbl, root, rest)
	if reach.Hit and not reach.HitSky then return reach.HitPos, true end

	local down = myTbl.TraceMyTbl(self, myTbl, rest, rest - up * (h * 1.6))
	if down.Hit and not down.HitSky then return down.HitPos, true end

	local back = myTbl.TraceMyTbl(self, myTbl, rest - up * (h + 12), root - up * (h + 12))
	if back.Hit then return back.HitPos, true end

	return rest - up * (h * 0.6), false
end

function ENT:NeighboursPlanted(leg)
	for _, other in ipairs(leg.neighbours) do
		local st = self.LimbState[other]
		if st and st.stepping then return false end
	end
	return true
end

function ENT:UpdateLimbs(myTbl, pos)
	local morph = myTbl.Creature(self, myTbl)
	if not morph then return end

	local now = UnPredictedCurTime()
	local dt = now - (myTbl.LastLimbUpdate or 0)
	if dt <= 0 then return end
	myTbl.LastLimbUpdate = now

	local ang = entMeta.GetAngles(self)

	if not myTbl.LimbState or dt > SNAP_GAP then
		myTbl.LimbState = {}
		myTbl.SmoothVel = Vector()
		myTbl.LastPos = pos
		myTbl.Churn = 0
		myTbl.Agitation = 0
	end

	myTbl.SmoothVel = LerpVector(math.min(1, dt * 20), myTbl.SmoothVel, (pos - myTbl.LastPos) / dt)
	myTbl.LastPos = pos
	local speed = myTbl.SmoothVel:Length()

	local prey = myTbl.GetPrey(self)
	local feel = IsValid(prey) and prey:EyePos()
	if feel then myTbl.LastFeel = feel end
	myTbl.Agitation = math.Approach(myTbl.Agitation, MOOD_AGITATION[myTbl.GetMood(self)] or 0, dt * 0.8)
	local agit = myTbl.Agitation

	local act, victim, actStart = myTbl.GetAct(self), myTbl.GetVictim(self), myTbl.GetActStart(self)
	local limp = act == ACT_OUT or act == ACT_DEAD

	if act == ACT_NONE then
		myTbl.Churn = myTbl.Churn + dt * morph.churn * (1 + math.sin(now * 0.3 + morph.phase)) * (1 + 2 * agit)
	end
	ang:RotateAroundAxis(ang:Up(), myTbl.Churn)

	local fwd, left, up = ang:Forward(), -ang:Right(), ang:Up()

	if myTbl.RolesAct ~= act or myTbl.RolesStart ~= actStart or myTbl.RolesVictim ~= victim then
		myTbl.RolesAct, myTbl.RolesStart, myTbl.RolesVictim = act, actStart, victim
		myTbl.Roles = myTbl.AssignRoles(self, morph, act, victim, pos, fwd, left)
	end

	local function toWorld(v) return pos + fwd * v.x + left * v.y + up * v.z end

	local lead = myTbl.SmoothVel * LEAD_TIME
	local maxLead = myTbl.BodyHeight * MAX_LEAD
	if lead:LengthSqr() > maxLead * maxLead then lead = lead:GetNormalized() * maxLead end
	local skitter = math.Clamp((speed - SKITTER[1]) / (SKITTER[2] - SKITTER[1]), 0, 1)
	local hurry = math.Clamp(1 - speed * 0.0015, 0.45, 1) * math.min(1, SKITTER[1] / math.max(speed, 1))
	local low = 1 - 0.65 * skitter
	local loud = math.Clamp(speed / SKITTER[2], 0, 1)
	local shake = 0.04 + 0.04 * agit
	local squeezed = math.max(MIN_SHRINK, 1 - myTbl.GetSqueeze(self))

	local swimming = myTbl.GetSwimming(self) and not limp
	local axis, lift, side, stroke
	if swimming then
		axis = speed > SWIM_STILL and myTbl.SmoothVel / speed or entMeta.GetForward(self)
		lift = entMeta.GetUp(self)
		lift = lift - axis * lift:Dot(axis)
		if lift:LengthSqr() < 1e-4 then lift = axis:Angle():Up() end
		lift:Normalize()
		side = axis:Cross(lift)
		local n, u = Stroke(myTbl.GetSeed(self), now)
		local open = u < STROKE_PUSH and 1 - Smooth(u / STROKE_PUSH) or u < SWIM_OPEN and 0 or Smooth((u - SWIM_OPEN) / (1 - SWIM_OPEN))
		local hover = 0.55 + 0.1 * math.sin(now * 1.5 + morph.phase)
		stroke = Lerp(math.Clamp(speed / SWIM_FAST, 0, 1), hover, open)
		if n ~= myTbl.LastStroke and speed > SWIM_STILL then
			sound.Play(SWIM_SOUNDS[math.random(#SWIM_SOUNDS)], pos, 60, math.random(70, 90), 0.4)
		end
		myTbl.LastStroke = n
	end
	local twitchRate = 0.2 + 1.2 * agit

	local threatYaw
	if feel and agit > 0.5 and speed < 60 then
		local d = feel - pos
		threatYaw = math.deg(math.atan2(d:Dot(left), d:Dot(fwd)))
	end

	local airborne, maxAirborne = 0, math.ceil(#morph.legs * Lerp(skitter, MAX_AIRBORNE, SKITTER[3]))
	for _, leg in ipairs(morph.legs) do
		local st = myTbl.LimbState[leg]
		if st and st.stepping then airborne = airborne + 1 end
	end

	for _, limb in ipairs(morph.legs) do
		local st = myTbl.LimbState[limb]
		if not st then
			st = { points = {}, twitch = Vector(), raise = 0, wrap = 0, lumps = {}, blood = 0 }
			myTbl.LimbState[limb] = st
		end
		st.lumps, st.blood = st.lumps or {}, st.blood or 0

		st.twitch = st.twitch * math.exp(-dt * 7)
		if math.random() < dt * twitchRate then
			st.twitch = VectorRand() * limb.length * 0.2
		end

		local root = toWorld(limb.root)

		local role = myTbl.Roles[limb]
		local shrink = role and 1 or squeezed
		local yaw = math.rad(limb.angle)
		local rest = pos + (fwd * math.cos(yaw) + left * math.sin(yaw)) * (limb.length * limb.spread * shrink) + lead
		local target, grounded = myTbl.FootTarget(self, myTbl, root, rest, up)
		if not grounded then
			target = target + Wobble(now * 2, limb.phase, limb.freq) * limb.length * 0.2
		end
		st.target, st.grounded = target, grounded
		st.foot = st.foot or target

		if role and (not IsValid(victim) or (act == ACT_FEED and role.index > 1 and now - actStart < PULL_TIME)) then
			role = nil
		end
		if role and st.stepping then
			st.stepping = false
			airborne = airborne - 1
		end

		local threatened = threatYaw and not role and not st.stepping
			and math.abs(math.AngleDifference(limb.angle, threatYaw)) < THREAT_ARC
		st.raise = math.Approach(st.raise, threatened and 1 or 0, dt * 2.5)

		if limp then
			local flat = pos + (fwd * math.cos(yaw) + left * math.sin(yaw)) * (limb.length * SPRAWL)
			local tr = myTbl.Trace(self, flat + up * (limb.length * 0.3), flat - up * limb.length)
			st.foot = LerpVector(math.min(1, dt * 5), st.foot, tr.Hit and tr.HitPos or flat)
			st.stepping = false
		elseif swimming then
			if st.stepping then
				st.stepping = false
				airborne = airborne - 1
			end
			local ring = side * math.cos(yaw) + lift * math.sin(yaw)
			local open = math.Clamp(stroke + (limb.phase % 1 - 0.5) * 0.1, 0, 1)
			local trail = pos - axis * (limb.length * 0.85) + ring * (limb.length * 0.2)
			local flare = pos + axis * (limb.length * 0.1) + ring * (limb.length * 0.65)
			st.foot = LerpVector(open, trail, flare) + Wobble(now * 3, limb.phase, limb.freq) * (limb.length * 0.05)
			st.ring = ring
		elseif st.stepping then
			st.t = st.t + dt / (limb.stepTime * hurry)
			if st.t >= 1 then
				st.stepping = false
				st.foot = target
				airborne = airborne - 1
				if grounded and now >= (myTbl.NextFootSound or 0) then
					myTbl.NextFootSound = now + FOOT_SOUND_GAP
					local snd = FOOT_SOUNDS[math.random(#FOOT_SOUNDS)]
					sound.Play(snd, target, 65 + 12 * loud, limb.pitch + math.random(-10, 10) + 15 * loud, 0.35 + 0.4 * loud)
				end
			end
		elseif not role and st.raise == 0 then
			if not grounded then
				st.foot = LerpVector(math.min(1, dt * 6), st.foot, target)
			else
				local drift = st.foot:Distance(target)
				local overreach = st.foot:Distance(root) > limb.length * shrink * 0.97
				if overreach or (drift > limb.stepDistance * shrink and airborne < maxAirborne and myTbl.NeighboursPlanted(self, limb)) then
					st.stepping, st.t, st.from = true, 0, st.foot
					airborne = airborne + 1
				end
			end
		end

		local foot = st.foot
		if st.stepping then
			local t = st.t
			foot = LerpVector(Smooth(t), st.from, target) + up * (math.sin(t * math.pi) * limb.stepHeight * low * shrink)
		end
		if st.raise > 0 and myTbl.LastFeel then
			local aim = root + (myTbl.LastFeel - root):GetNormalized() * (limb.length * 0.75) + up * (limb.length * 0.25)
				+ Wobble(now * 3, limb.phase, limb.freq) * (limb.length * 0.04)
			foot = LerpVector(Smooth(st.raise), foot, aim)
		end

		if act == ACT_STUN then
			local t = now - actStart
			local k = Smooth(math.Clamp(t / 0.12, 0, 1)) * Smooth(math.Clamp((STUN_TIME - t) / 0.8, 0, 1))
			local curled = root + (foot - root) * CURL - up * (limb.length * 0.1)
				+ Wobble(now * 26, limb.phase, limb.freq) * (limb.length * 0.04 * k)
			foot = LerpVector(k, foot, curled)
		end

		if act == ACT_DEAD then
			local k = Smooth(math.Clamp((now - actStart) / DEATH_CURL, 0, 1))
			local curled = root + (foot - root) * 0.2 + up * (limb.length * 0.3)
				+ Wobble(now * 30, limb.phase, limb.freq) * (limb.length * 0.03 * (1 - k))
			foot = LerpVector(k, foot, curled)
		end

		local holding = role and ((act == ACT_DRAG or act == ACT_FEED or act == ACT_GRAPPLE) and role.index == 1 or act == ACT_SEAR)
		if role then
			if act == ACT_STRIKE then
				local t = now - actStart
				local chest = Chest(victim)
				local away = root - chest
				away = (away - up * away:Dot(up)):GetNormalized()
				local cocked = root + up * (limb.length * 0.55) + away * (limb.length * 0.2)
					+ Wobble(now * 9, limb.phase, limb.freq) * (limb.length * 0.015)
				if t < WINDUP then
					foot = LerpVector(Smooth(t / WINDUP), foot, cocked)
				else
					local f = math.min(1, (t - WINDUP) / LUNGE)
					foot = LerpVector(f * f, cocked, chest + (chest - root):GetNormalized() * 8)
				end
			elseif holding then
				foot = Chest(victim)
			elseif act == ACT_FEED then
				st.bites = st.bites or {}
				local bite, n, u = BitePose(victim, myTbl.GetSeed(self), role.index - 1, now - actStart - PULL_TIME, up, now, limb, st.bites)
				st.work = math.Approach(st.work or 0, 1, dt * 3)
				foot = LerpVector(Smooth(st.work), foot, bite)
				local stage = u < BITE_IN and 0 or u < BITE_RIP and 1 or 2
				if st.biteN == n and st.biteStage ~= stage then
					if stage == 1 then st.blood = 1 end
					if stage == 2 then st.lumps[#st.lumps + 1] = now end
				end
				st.biteN, st.biteStage = n, stage
			end
		end
		if not (role and act == ACT_FEED) then st.work, st.bites = 0, nil end

		if act == ACT_FEED and role and role.index == 1 and now - actStart > PULL_TIME then
			if now >= (st.nextSwallow or 0) then
				if st.nextSwallow then st.lumps[#st.lumps + 1] = now end
				st.nextSwallow = now + math.Rand(SWALLOW_GAP[1], SWALLOW_GAP[2])
			end
		else
			st.nextSwallow = nil
		end
		while st.lumps[1] and now - st.lumps[1] > LUMP_TIME do table.remove(st.lumps, 1) end
		st.blood = math.max(0, st.blood - dt * 0.02)

		local bow = swimming and st.ring * (limb.length * 0.1) or up * (limb.length * shrink * (act == ACT_OUT and 0.08 or 0.35))
		Pose(st, limb, root, foot, bow, now, shake, shrink)

		if holding and not st.holdSince then st.holdSince = now end
		if not holding then st.holdSince = nil end
		if holding then
			local a, b, r
			if act == ACT_SEAR then a, b, r = Girth(victim) else a, b, r = GripAxis(victim) end
			Coil(st, limb, role, root, a, b, r, up, now - st.holdSince)
		end
		st.wrap = math.Approach(st.wrap, holding and 1 or 0, dt * (holding and 12 or 2.5))
	end
end

local drawing, drawNow, drawHeat, drawRot

local function LimbRadius(f, limb)
	local r = limb.width * (1 - 0.9 * f ^ 1.3)
	for k = 1, limb.segments - 1 do
		local d = (f - k / limb.segments) / 0.035
		r = r + limb.width * 0.12 * math.exp(-d * d)
	end
	for _, born in ipairs(drawing.lumps) do
		local d = (f - (1 - (drawNow - born) / LUMP_TIME)) / 0.07
		r = r + limb.width * 0.9 * math.exp(-d * d)
	end
	return r * drawRot
end

local function LimbColor(f, limb)
	local k = f ^ 3
	local b = limb.shade
	local r, g, bl = Lerp(k, FLESH.r, BONE.r), Lerp(k, FLESH.g, BONE.g), Lerp(k, FLESH.b, BONE.b)
	local stain = drawing.blood * math.Clamp((f - 0.55) / 0.3, 0, 1)
	r, g, bl = Lerp(stain, r, BLOOD.r) * b, Lerp(stain, g, BLOOD.g) * b, Lerp(stain, bl, BLOOD.b) * b
	if drawHeat <= 0 then return r, g, bl end
	local t = f ^ 2
	return Lerp(drawHeat, r, Lerp(t, HOT.r, WHITE_HOT.r)), Lerp(drawHeat, g, Lerp(t, HOT.g, WHITE_HOT.g)),
		Lerp(drawHeat, bl, Lerp(t, HOT.b, WHITE_HOT.b))
end

function ENT:Draw()
	local myTbl = entMeta.GetTable(self)
	local pos = entMeta.GetPos(self)

	myTbl.UpdateLimbs(self, myTbl, pos)
	local morph = myTbl.Morph
	if not morph or not myTbl.LimbState then return end

	local near = EyePos():DistToSqr(pos) < LOD_DISTANCE * LOD_DISTANCE
	local sides, sub = near and 6 or 4, near and 3 or 1

	drawNow = UnPredictedCurTime()
	drawHeat = (myTbl.Heat or 0) * (0.85 + 0.15 * math.sin(drawNow * 23 + math.sin(drawNow * 7) * 2))
	drawRot = 1
	if myTbl.GetAct(self) == ACT_DEAD then
		drawRot = 1 - Smooth(math.Clamp((drawNow - myTbl.GetActStart(self) - (CORPSE_TIME - ROT_TIME)) / ROT_TIME, 0, 1))
		if drawRot <= 0 then return end
	end
	Flesh.SampleLight(pos, drawHeat)
	render.SetMaterial(Flesh.Material)
	for _, limb in ipairs(morph.legs) do
		local st = myTbl.LimbState[limb]
		drawing = st
		if st.wrap > 0 and st.coil then
			local pts = Resample(st.points, COIL_POINTS, st.display or {})
			st.display = pts
			local b = Smooth(st.wrap)
			for i = 1, COIL_POINTS do pts[i] = LerpVector(b, pts[i], st.coil[i]) end
			Flesh.Tube(pts, sides, 1, LimbRadius, LimbColor, limb)
		else
			Flesh.Tube(st.points, sides, st.lumps[1] and sub * 2 or sub, LimbRadius, LimbColor, limb)
		end
	end

	if cv_debug:GetBool() then
		for _, leg in ipairs(morph.legs) do
			local st = myTbl.LimbState[leg]
			local c = st.grounded and DEBUG_TARGET or DEBUG_DANGLE
			render.DrawWireframeSphere(st.target, 3, 4, 4, c, true)
		end
	end
end
