local Scent = EvilCrawler.Scent
local Victim = EvilCrawler.Victim
local Hearing = EvilCrawler.Hearing
local Creature = EvilCrawler.Creature
local Proxy = EvilCrawler.Proxy
local Souls = Evil.SoulDigestion({ id = "evil_crawler", tricks = { slip = 3, dodge = 5, outrun = 2 } })
EvilCrawler.Souls = Souls

local cv_puppet = CreateConVar("evil_crawler_puppet", "0", 0, "Debug: 1 makes every crawler walk to wherever the player who spawned it is aiming and attack npcs near there, instead of hunting on its own. Set it in the server console")
local cv_debug = GetConVar("evil_crawler_debug_scent")
local ai_ignoreplayers = GetConVar("ai_ignoreplayers")
local ai_disabled = GetConVar("ai_disabled")

function EvilCrawler.IgnoresPlayers()
	return EvilCrawler.Setting("attack_players") == 0 or (ai_ignoreplayers and ai_ignoreplayers:GetBool())
end

local THINK_INTERVAL = 0.25
local QUICK_INTERVAL = 0.1
local SNAP = 22
local SNAGGED = { 120, 400 }
local SNIFF_RADIUS = 400
local SCENT_THRESHOLD = 0.12
local TOUCH_RANGE = 220
local TREMOR_RANGE = 1000
local TREMOR_SPEED = 150
local SIGHT_CLEAR = 500
local SIGHT_STILL, SIGHT_RUN = 0.2, 400
local SIGHT_CROUCH = 0.5
local SIGHT_LIT = 2
local FIRED_TIME = 1
local SIGHT_GAIN = 3
local SIGHT_FADE = 0.25
local NOTICE = 0.35
local LEAD = 0.6
local REACHED = 72
local SKIP_AHEAD = 260
local RETRACE_TIME = 4
local RETRACE_BACK = 30
local LIFT = Vector(0, 0, 16)
local SEARCH_TIME = 8
local SEARCH_SPREAD = 300
local HUNT_MEMORY = 4
local LOST_MEMORY = 20
local LOST_PULL = 3
local STUCK_TIME = 2.5
local OVER_VEER = 0.5
local VEER_SPREAD = 0.6
local LEAP_RANGE = 800
local LEAP_SPEED = 600
local LEAP_ARCS = { 1, 1.5 }
local LEAP_GAP = 3
local LEAP_MISS = 150
local POUNCE_REACH = 450
local TIP_GAP = 45
local TIP_FUZZ = 700
local HUNGRY_PULL = 2
local DEATH_PULL = 4
local SNIFF_TIME = 5
local FEAR_PULL = 1.5
local GRUDGE_PULL = 2.5
local GRUDGE_HOLD = 8
local GRUDGE_OUTWEIGH = 2
local RAGE_BALK = 4
local BALK_STEP = 48
local BALK_NEAR = 220
local FLEE_TIME = 8
local FLEE_MIN = 3
local HIDE_SPREAD = { 2 / 3, 4 / 3 }
local HIDE_SIGHT = 1500
local HIDE_CEILING = 3
local SEEN_RESET = 1
local ANGER_MAX = 3
local ANGER_FADE = 180
local ANGER_PACE = 0.15
local KNOW_PACE = 0.15
local PAIN_SOUNDS = { "npc/barnacle/barnacle_die1.wav", "npc/barnacle/barnacle_die2.wav" }
local PAIN_HIT_SOUND = "physics/flesh/flesh_squishy_impact_hard2.wav"
local SHOT_RADIUS = 0.9
local RAGE_WINDOW = 30
local RAGE_REACH = 110
local RAGE_SOUND = "ambient/fire/gascan_ignite1.wav"
local RAGE_LOOP = "ambient/fire/fire_med_loop1.wav"
local OUT_SPREAD = { 0.8, 1.2 }
local OUT_SOUND = "physics/flesh/flesh_squishy_impact_hard4.wav"
local BREATH_LOOP = "npc/zombie_poison/pz_breathe_loop1.wav"
local WAKE_SOUND = "npc/barnacle/barnacle_tongue_pull1.wav"
local RISE_TIME = 1.2
local TIRED_SLOW = 0.5
local DEATH_SOUND = "physics/flesh/flesh_bloody_break.wav"
local DOORS = { prop_door_rotating = true, func_door = true, func_door_rotating = true }
local BASH_GAP = 2
local LISTEN_TIME = 12
local MUFFLE = 0.5
local PILOT_PACE = { 0.35, 1 }
local PILOT_LEAP = 300
local VISIT_CELL = 512
local VISIT_FORGET = 120
local HEADINGS = 6
local TEAR_STALL = 0.75
local TEAR_LAPSE = 2
local TEAR_GAP = 0.5
local TEAR_TIME = { 1.5, 5 }
local TEAR_MASS = 400
local TEAR_PASS = 6
local TEAR_PUSH = 600
local METAL_STRAIN = {
	"physics/metal/metal_box_strain1.wav", "physics/metal/metal_box_strain2.wav",
	"physics/metal/metal_box_strain3.wav", "physics/metal/metal_box_strain4.wav",
}
local METAL_BREAK = { "physics/metal/metal_box_break1.wav", "physics/metal/metal_box_break2.wav" }
local WOOD_STRAIN = { "physics/wood/wood_strain2.wav", "physics/wood/wood_strain3.wav", "physics/wood/wood_strain4.wav" }
local WOOD_BREAK = { "physics/wood/wood_crate_break1.wav", "physics/wood/wood_crate_break2.wav" }
local WALL_RANGE = 400
local SEEK_STEP = 24
local SEEK_STEPS = 24
local GAP_LEVELS = { 1, 0.5, 0.25 }
local ROUTE_GAP = 1
local WAY_TIME = 5
local SKIRT_TIME = 15
local SKIRT_MIN = 96
local STUCK_BACK = 1
local THROWN = { prop_physics = true, prop_physics_multiplayer = true, prop_physics_respawnable = true }
local THROW_GAP = { 2.5, 5 }
local THROW_REACH = 140
local THROW_RANGE = { 160, 1400 }
local THROW_MASS = 150
local THROW_SPEED = 1300
local THROW_SOUNDS = { "npc/zombie/claw_miss1.wav", "npc/zombie/claw_miss2.wav" }
local BASH_SOUNDS = { "physics/wood/wood_box_impact_hard3.wav", "physics/wood/wood_panel_impact_hard1.wav" }

local RHYTHM = {
	roam = { pace = 0.09, go = { 3, 8 }, stop = { 1, 4 } },
	search = { pace = 0.55, go = { 0.3, 0.8 }, stop = { 0.5, 1.6 } },
	listen = { pace = 0.8, go = { 0.4, 1.1 }, stop = { 0.2, 0.8 }, freeze = { 0.4, 0.9 } },
	scavenge = { pace = 1.2, go = { 0.6, 1.5 }, stop = { 0.08, 0.3 } },
	track = { pace = 0.7, go = { 0.4, 1.1 }, stop = { 0.3, 1.2 } },
	hunt = { pace = 1, go = { 0.6, 1.5 }, stop = { 0.08, 0.3 }, freeze = { 0.3, 0.7 } },
	chase = { pace = 1, go = { 0.6, 1.5 }, stop = { 0.08, 0.3 } },
	strike = { pace = 0 },
	drag = { pace = 1.15 },
	feed = { pace = 0 },
	flee = { pace = 1.2 },
	hide = { pace = 0 },
	grapple = { pace = 0 },
	stunned = { pace = 0 },
	watch = { pace = 0 },
	rage = { pace = 1.3 },
	out = { pace = 0 },
	dead = { pace = 0 },
}
local MOOD = {
	roam = 0, search = 1, listen = 1, scavenge = 1, track = 1, chase = 2, hunt = 2, strike = 2, drag = 2, feed = 1, flee = 2, hide = 0, grapple = 2,
	stunned = 0, watch = 2, rage = 2, out = 0, dead = 0,
}
local CHASING = { search = true, listen = true, track = true, chase = true, hunt = true }
local TRAILING = { track = true, chase = true }
local STATE_COLOR = {
	roam = Color(120, 120, 120), search = Color(255, 200, 0), listen = Color(180, 255, 0), scavenge = Color(140, 0, 0), track = Color(255, 120, 0), hunt = Color(255, 0, 0),
	chase = Color(255, 60, 60), flee = Color(0, 200, 255), hide = Color(0, 80, 160), watch = Color(255, 0, 255), rage = Color(255, 60, 0),
}

local function Perceivable(ent)
	if ent:IsFlagSet(FL_NOTARGET) then return false end
	if Creature(ent) then return EvilCrawler.Living(ent) and not ent.EvilCrawlerVictim end
	return ent:Alive()
		and not ent.EvilCrawlerVictim
		and not EvilCrawler.Held(ent)
		and not EvilCrawler.Noclipping(ent)
		and ent:GetObserverMode() == OBS_MODE_NONE
end

local function Cell(p)
	return math.floor(p.x / VISIT_CELL) .. " " .. math.floor(p.y / VISIT_CELL) .. " " .. math.floor(p.z / VISIT_CELL)
end

local function Mover(ent)
	if not ent:IsPlayer() then return ent end
	return ent:InVehicle() and ent:GetVehicle() or EvilCrawler.Fake(ent) or ent
end

function ENT:Clear(from, ent, to, mask)
	local tr = self:Trace(from, to or Proxy(ent):WorldSpaceCenter(), mask)
	if not tr.Hit then return true end
	local body = Mover(ent)
	return IsValid(tr.Entity) and (tr.Entity == body or tr.Entity == body:GetParent())
end

function ENT:SurfaceDistance(point)
	local to = point - self:GetPos()
	return (to - self.BodyUp * to:Dot(self.BodyUp)):Length()
end

function ENT:Reached(point)
	return self:SurfaceDistance(point) < REACHED and self:GetPos():Distance(point) < REACHED + self.BodyHeight
end

function ENT:Feels(ent, pos)
	if not Perceivable(ent) or (ent:IsPlayer() and not self:Wants(ent)) then return false end
	local center = Proxy(ent):WorldSpaceCenter()
	local d = center:Distance(pos)
	if self.Spotted[ent] and self.InView[ent] then return true, d end
	local body = Mover(ent)
	local creature = Creature(ent)
	local speed = creature and (ent.EvilCrawlerSpeed or 0) or body:GetVelocity():Length()
	local tremor = d < TREMOR_RANGE and (creature or body ~= ent or ent:IsOnGround()) and speed > TREMOR_SPEED
	if (d < TOUCH_RANGE * self.Scale or tremor) and self:Clear(pos, ent) then return true, d end
	return false
end

function ENT:Visibility(ent, pos, now)
	if not Perceivable(ent) or (ent:IsPlayer() and not self:Wants(ent)) then return 0 end
	local range = EvilCrawler.Setting("sight_range") * self:Wits()
	local center = Proxy(ent):WorldSpaceCenter()
	local d = center:Distance(pos)
	if d >= range then return 0 end
	if not self:Clear(pos, ent, Proxy(ent):EyePos(), MASK_OPAQUE) and not self:Clear(pos, ent, center, MASK_OPAQUE) then return 0 end

	local speed = Creature(ent) and (ent.EvilCrawlerSpeed or 0) or Mover(ent):GetVelocity():Length()
	local v = Lerp(math.min(1, speed / SIGHT_RUN), SIGHT_STILL, 1)
	v = v * math.min(1, 1 - (d - SIGHT_CLEAR) / math.max(1, range - SIGHT_CLEAR))
	if ent:IsPlayer() and ent:Crouching() then v = v * SIGHT_CROUCH end
	if (ent:IsPlayer() and ent:FlashlightIsOn()) or now - (ent.EvilCrawlerFiredAt or -math.huge) < FIRED_TIME then
		v = v * SIGHT_LIT
	end
	return v
end

function ENT:Look(now)
	local pos = self:GetPos()
	local dt = math.min(now - (self.LastLook or now), THINK_INTERVAL * 2)
	self.LastLook = now
	self.Awareness = self.Awareness or {}
	self.Spotted = self.Spotted or {}
	self.InView = {}

	local seen = {}
	local function look(ent)
		local v = self:Visibility(ent, pos, now)
		if v <= 0 then return end
		seen[ent] = v
		self.InView[ent] = true
		self.Awareness[ent] = self.Awareness[ent] or 0
	end
	for _, ply in ipairs(player.GetAll()) do look(ply) end
	if self:IsHungry() then
		for npc in pairs(Scent.npcs) do
			if IsValid(npc) and self:IsEdible(npc) then look(npc) end
		end
	end

	for ent, sure in pairs(self.Awareness) do
		local v = seen[ent] or 0
		sure = math.Clamp(sure + (v * SIGHT_GAIN - SIGHT_FADE) * dt, 0, 1)
		if self.Spotted[ent] and v > 0 then sure = 1 end
		if sure >= 1 then
			self.Spotted[ent] = true
		elseif sure < NOTICE then
			self.Spotted[ent] = nil
		end
		if sure <= 0 or not IsValid(ent) then
			self.Awareness[ent], self.Spotted[ent] = nil, nil
		else
			self.Awareness[ent] = sure
		end
	end
	if self.Grudge and self.InView[self.Grudge] then self.GrudgeAt = now end
end

function ENT:Glimpse()
	local best, bestSure
	for ent in pairs(self.InView) do
		local sure = self.Awareness[ent] or 0
		if sure >= NOTICE and not self.Spotted[ent] and (not best or sure > bestSure) then best, bestSure = ent, sure end
	end
	return best
end

function ENT:Lead(ent)
	if not ent:IsPlayer() then return ent:GetPos() end
	local from = Proxy(ent):GetPos() + Vector(0, 0, 32)
	local tr = self:Trace(from, from + Mover(ent):GetVelocity() * LEAD)
	return tr.HitPos + tr.HitNormal * 16 - Vector(0, 0, 32)
end

function ENT:Sense()
	local pos = self:GetPos()
	local now = CurTime()
	local meal, mealDist, person, personDist

	if self:IsHungry() then
		for npc in pairs(Scent.npcs) do
			if IsValid(npc) and self:IsEdible(npc) and not self:Balks(npc, now) then
				local felt, d = self:Feels(npc, pos)
				if felt and (not meal or d < mealDist) then meal, mealDist = npc, d end
			end
		end
	end
	if meal then return meal end

	for _, ply in ipairs(player.GetAll()) do
		if not self:Balks(ply, now) then
			local felt, d = self:Feels(ply, pos)
			if felt and (not person or d < personDist) then person, personDist = ply, d end
		end
	end
	return person
end

function ENT:Appeal(node, now)
	local trail, owner = node.trail, node.trail.owner
	local spent = self.Spent[trail]
	if spent and node.time <= spent then return 0 end
	if trail.death then
		if EvilCrawler.Setting("eat_corpses") == 0 or not self:IsHungry() or owner and (not self:IsCarrion(owner) or self:Shuns(owner, now)) then return 0 end
		return Scent.Intensity(node, now) * DEATH_PULL
	end
	if not IsValid(owner) or self:Balks(owner, now) then return 0 end
	local w = 1
	if node.npc then
		if not (self:IsHungry() and self:IsEdible(owner)) then return 0 end
		w = HUNGRY_PULL
	elseif not self:WouldTake(owner) then
		return 0
	end
	if node.fear then w = w * FEAR_PULL end
	if owner == self.Grudge then w = w * GRUDGE_PULL end
	if owner == self.Hunted and now - self.SensedAt < LOST_MEMORY then w = w * LOST_PULL end
	return Scent.Intensity(node, now) * w
end

function ENT:Spend(node)
	for _, trail in ipairs(node.trail.cloud or { node.trail }) do
		self.Spent[trail] = math.max(self.Spent[trail] or node.time, node.time)
	end
end

function ENT:Smells(node)
	return not self:Trace(self:GetPos(), node.pos + LIFT).Hit
end

function ENT:FollowTrail(node)
	local pos = self:GetPos()
	while node.next and not node.next.dead do
		if self:Reached(node.pos) or not self.Retrace and node.next.pos:Distance(pos) < SKIP_AHEAD and self:Smells(node.next) then
			node = node.next
		else
			break
		end
	end
	return node
end

function ENT:Tread(node, now)
	if self.Footing and self.Footing.trail ~= node.trail then self.Footing, self.FootAt = nil, now end
	local foot, n = self.Footing, node
	for _ = 1, 8 do
		if not n or foot and n.time <= foot.time then return end
		if self:Reached(n.pos) then
			self.Footing, self.FootAt, self.ProgressTime = n, now, now
			return
		end
		n = n.prev
	end
end

function ENT:Backtrack(node)
	if self.Footing then return self.Footing end
	local pos, best, bestDist = self:GetPos(), nil, math.huge
	local n = node.prev
	for _ = 1, RETRACE_BACK do
		if not n then break end
		local d = n.pos:Distance(pos)
		if d < bestDist and self:Smells(n) then best, bestDist = n, d end
		n = n.prev
	end
	return best
end

function ENT:Pickup(ent, at)
	local trail = IsValid(ent) and Scent.active[ent]
	local n, best, bestDist = trail and trail.last, nil, SNIFF_RADIUS
	while n do
		local d = n.pos:Distance(at)
		if d < bestDist then best, bestDist = n, d end
		n = n.prev
	end
	return best
end

function ENT:Around(center, spread)
	local offset = VectorRand() * spread
	return center + offset - self.BodyUp * offset:Dot(self.BodyUp)
end

function ENT:SetState(state)
	local r = RHYTHM[state]
	if state ~= self.State then
		local first = r.freeze or r.go
		self.Still = r.freeze ~= nil
		self.FitUntil = first and CurTime() + math.Rand(first[1], first[2]) or 0
		self.OverSince = nil
	end
	self.State = state
	self.Pace = r.pace
	self:SetMood(MOOD[state])
end

function ENT:Ponder()
	local now = CurTime()
	local pos = self:GetPos()
	self:Murmur(now)

	if self:GetAct() ~= EvilCrawler.ACT_NONE then
		self:PonderAct(now)
		return
	end
	if self:Piloted() then
		self.Goal, self.Way, self.Trail = nil, nil, nil
		self:SetPrey(NULL)
		return
	end
	if self.State == "rage" and self:Rampage(now) then return end
	self:Cool(now)
	if self.State == "flee" and self:LyingLow(now) then return end

	local puppet = cv_puppet:GetBool()
	local meal = not puppet and self:Carrion()
	local reek = not meal and not puppet and self:Reeks(pos, now)
	local looked, prey
	if (meal or reek) and self.State ~= "hide" then
		self:Look(now)
		looked, prey = true, self:Sense()
		local hunted = self.State == "hunt" and IsValid(self.Hunted) and Creature(self.Hunted) and now - self.SensedAt < HUNT_MEMORY
		if prey and Creature(prey) or hunted then meal, reek = nil, nil end
	end
	if meal then
		self.Taunt = nil
		self:SetPrey(NULL)
		if self:Scavenge(meal) then return end
		self:SetState("scavenge")
		self.Goal = self:Approach(meal, now)
		return
	end
	if reek then
		local heart = reek.trail.last
		if not self:Reached(heart.pos) then
			self.Taunt = nil
			self:SetPrey(NULL)
			self:SetState("scavenge")
			self.Trail, self.Goal = reek, self:Approach(reek.trail.owner, now)
			return
		end
		self:Spend(heart)
	end
	if self:LyingLow(now) then return end

	self.Puppeting = cv_puppet:GetBool()
	if self.Puppeting then
		self.Goal = self:PuppetGoal()
		self.Pace = 0.4
		for npc in pairs(Scent.npcs) do
			if IsValid(npc) and self:CanAttack(npc) then
				self:StartStrike(npc)
				return
			end
		end
		return
	end

	self.Visited = self.Visited or {}
	self.Visited[Cell(pos)] = now

	if not looked then
		self:Look(now)
		prey = self:Sense()
	end
	self:SetPrey(prey or NULL)
	if prey then
		self.Taunt = nil
		if self:CanAttack(prey) then
			self:StartStrike(prey)
			return
		end
		if Proxy(prey):WorldSpaceCenter():Distance(pos) < BALK_NEAR * self.Scale then
			self:Closes(prey, pos, now)
		elseif self.Closing == prey then
			self.Closing = nil
		end
		self:SetState("hunt")
		self.Trail = nil
		self.Goal = Proxy(prey):GetPos()
		self.LastKnown = self:Lead(prey)
		self.Hunted, self.SensedAt = prey, now
		if self:Pounce(prey, now) then return end
		self:Overhead(prey, now)
		return
	end
	if self.State == "hunt" then
		if self:Balks(self.Hunted, now) then
			self:SetState("roam")
			self.Goal = nil
		else
			if now - self.SensedAt < HUNT_MEMORY and not self:Reached(self.LastKnown) then
				self.Goal = self.LastKnown
				return
			end
			self:SetState("search")
			self.Goal = self.LastKnown
			self.SearchUntil = now + SEARCH_TIME
			self.Trail = self:Pickup(self.Hunted, self.LastKnown)
		end
	end

	local glimpse = self:Glimpse()
	if glimpse then
		self:SetPrey(glimpse)
		self:SetState("watch")
		self.Goal = nil
		self.LastKnown = Proxy(glimpse):GetPos()
		return
	end
	if self.State == "watch" then
		self:SetState("search")
		self.Goal = self.LastKnown
		self.SearchUntil = now + SEARCH_TIME
	end

	local noise, loud = self:Listen(now)
	if noise and loud >= (self.State == "listen" and self.Loud * 0.5 or self.State == "chase" and 0.5 or self.State == "track" and 0.3 or 0) then
		self:SetState("listen")
		self.Noise, self.Loud = noise, loud
		self.Goal, self.LastKnown, self.Trail = noise.pos, noise.pos, nil
		self.Pace = RHYTHM.listen.pace * Lerp(loud, 0.6, 1.2)
	end
	if self.State == "listen" then
		if not self:Reached(self.Goal) and now - self.Noise.time < LISTEN_TIME then return end
		self:SetState("search")
		self.SearchUntil = now + SEARCH_TIME
		self.Taunt = self.Noise
	end

	self.Spent = self.Spent or setmetatable({}, { __mode = "k" })
	if not TRAILING[self.State] then self.Footing, self.FootAt, self.Retrace = nil, now, nil end
	local node = self.Trail
	if node and (node.dead or self:Appeal(node, now) < SCENT_THRESHOLD * 0.5) then node, self.Retrace = nil, nil end
	if not self.Retrace then
		self.WeighScent = self.WeighScent or function(n, t) return self:Appeal(n, t) end
		self.ReachScent = self.ReachScent or function(n) return self:Smells(n) end
		local whiff, strength = Scent.Strongest(pos, SNIFF_RADIUS, now, self.WeighScent, self.ReachScent)
		local behind = node and whiff and whiff.trail == node.trail and whiff.time < node.time
		if whiff and strength >= SCENT_THRESHOLD and not behind and (not node or strength > self:Appeal(node, now) * 1.5) then
			node = whiff
		end
	end

	if node then
		node = self:FollowTrail(node)
		self:Tread(node, now)
		if self.Retrace and self.Footing and self.Footing.time >= self.Retrace.time then self.Retrace = nil end
	end
	if node and now - self.FootAt > RETRACE_TIME and not self:Reached(node.pos) then
		local back = not self.Retrace and self:Backtrack(node)
		if back and back ~= node then
			self.Retrace, node, self.FootAt = node, back, now
		else
			self.Spent[node.trail] = node.trail.last.time
			self.Retrace, node = nil, nil
		end
	end
	if node then
		if self.SniffNode ~= node then
			self.SniffNode = not node.next and self:Reached(node.pos) and node or nil
			self.SniffedAt = now
		elseif now - self.SniffedAt > SNIFF_TIME then
			self:Spend(node)
			node = nil
		end
	end
	if node then
		self.Trail = node
		self.Taunt = nil
		if node.trail.death then
			self:SetState("scavenge")
		elseif node.trail.owner == self.Hunted and now - self.SensedAt < LOST_MEMORY then
			self:SetState("chase")
		else
			self:SetState("track")
			self.Pace = RHYTHM.track.pace * Lerp(math.min(1, Scent.Intensity(node, now)), 0.6, 1)
		end
		if node.next or not self:Reached(node.pos) then
			self.Goal = node.pos
		elseif not self.Goal or self:Reached(self.Goal) or self.Goal:Distance(node.pos) > 200 then
			self.Goal = self:Around(node.pos, 150)
		end
		return
	end
	self.Trail = nil

	if self.Breach and now < self.BreachUntil and not self:Reached(self.Breach) then
		self.Goal = self.Breach
		return
	end
	self.Breach = nil

	if self.State == "search" and now < self.SearchUntil then
		if self:Reached(self.Goal) then self.Goal = self:Around(self.LastKnown, SEARCH_SPREAD) end
		return
	end
	if self:Tipped(now) then return end

	if self.Taunt then
		local by = self.Taunt.source
		self:Enrage(IsValid(by) and by:IsPlayer() and by or nil, now)
		self.Taunt = nil
	end
	if self.State ~= "roam" or now > (self.NextVeer or 0) then
		self.Heading = self:FreshHeading(pos, now)
		self.NextVeer = now + math.Rand(4, 9)
	end
	local fled = self.Hunted
	if self.State == "search" and IsValid(fled) and fled:IsPlayer() and fled:Alive() and now - self.SensedAt < LOST_MEMORY then
		Souls:Watch(fled, "outrun")
	end
	self:SetState("roam")
	self.Goal = pos + self.Heading * 1000
end

function ENT:Reeks(pos, now)
	self.Spent = self.Spent or setmetatable({}, { __mode = "k" })
	self.WeighDeath = self.WeighDeath or function(n, t) return n.trail.death and n.trail.owner and self:Appeal(n, t) or 0 end
	self.ReachScent = self.ReachScent or function(n) return self:Smells(n) end
	local whiff, strength = Scent.Strongest(pos, SNIFF_RADIUS, now, self.WeighDeath, self.ReachScent)
	return strength >= SCENT_THRESHOLD and whiff
end

function ENT:FreshHeading(pos, now)
	local best, bestAge
	for _ = 1, HEADINGS do
		local dir = VectorRand():GetNormalized()
		local seen = self.Visited[Cell(pos + dir * 800)]
		local age = seen and now - seen or VISIT_FORGET
		if not best or age > bestAge then best, bestAge = dir, age end
	end
	return best
end

function ENT:Heeds(source)
	if not IsValid(source) then return true end
	local owner = source:GetOwner()
	if IsValid(owner) then source = owner end
	if source:IsPlayer() then return Perceivable(source) and self:Wants(source) end
	if Creature(source) then return self:IsHungry() and self:IsEdible(source) end
	return true
end

function ENT:Listen(now)
	local since = self.HeardAt or now
	self.HeardAt = now
	local mult = EvilCrawler.Setting("hearing") * self:Wits()
	if mult <= 0 then return end
	local pos, best, bestLoud = self:GetPos()
	for _, n in ipairs(Hearing.Recent(now)) do
		if n.time > since and self:Heeds(n.source) then
			local range = n.range * mult
			local d = n.pos:Distance(pos)
			if d < range and self:Trace(pos, n.pos + LIFT).Hit then range = range * MUFFLE end
			local loud = 1 - d / range
			if loud > 0 and (not best or loud > bestLoud) then best, bestLoud = n, loud end
		end
	end
	return best, bestLoud
end

function ENT:CheckProgress(now)
	local goal = self.Way and self.Way[1] or self.Goal
	if not goal then return end

	if not self.ProgressGoal or self.ProgressGoal:Distance(goal) > 100 then
		self.ProgressGoal, self.BestDist, self.ProgressTime = goal, math.huge, now
	end

	if self.Still then
		self.ProgressTime = now
		return
	end

	local d = self:SurfaceDistance(goal)
	if d < self.BestDist - 16 or self:Reached(goal) then
		self.BestDist, self.ProgressTime = d, now
	elseif now - self.ProgressTime > STUCK_TIME and not (self.Tearing and now - self.TearAt < TEAR_LAPSE) then
		self.BestDist, self.ProgressTime = d, now
		self.Way = nil
		if self.SkirtSide then self.SkirtSide = 3 - self.SkirtSide end
		self.NextRoute = now + STUCK_BACK
		self:Unstick(goal, now, STUCK_BACK, goal)
	end
end

function ENT:Opening(p, into, up)
	local h = self.BodyHeight
	local squeeze = EvilCrawler.Setting("squeeze") > 0
	local doors = EvilCrawler.Setting("open_doors") > 0
	for i, k in ipairs(GAP_LEVELS) do
		if i > 1 and not squeeze then break end
		local from = p - up * (h * (1 - k))
		local tr = self:Trace(from, from + into * (h * 3))
		if not tr.Hit or doors and IsValid(tr.Entity) and DOORS[tr.Entity:GetClass()] then return true end
	end
	return false
end

function ENT:Route(now)
	local goal = self.Goal
	if self.Way then
		if not goal or now > self.WayUntil or self.Way.goal:Distance(goal) > 300 then
			self.Way = nil
		elseif self:Reached(self.Way[1]) then
			table.remove(self.Way, 1)
			if #self.Way == 0 then self.Way = nil end
		end
		if self.Way then return end
	end
	if not goal or self.Puppeting or now < (self.NextRoute or 0) or self.BodyUp.z < 0.7 or self:GetSwimming() then return end
	self.NextRoute = now + ROUTE_GAP

	local pos, up, h = self:GetPos(), self.BodyUp, self.BodyHeight
	local to = goal - pos
	if math.abs(to:Dot(up)) > h * 2 then return end
	to = to - up * to:Dot(up)
	local dist = to:Length()
	if dist < h * 2 then return end
	local tr = self:Trace(pos, pos + to * (math.min(dist, WALL_RANGE) / dist))
	if not tr.Hit or tr.StartSolid or IsValid(tr.Entity) and DOORS[tr.Entity:GetClass()] then return end
	local n = tr.HitNormal - up * tr.HitNormal:Dot(up)
	if n:LengthSqr() < 0.25 then return end
	n:Normalize()

	local along, base = n:Cross(up), tr.HitPos + n * h
	local side = self:Side(goal, to:Dot(along) >= 0 and 1 or 2, now)
	local reach, far, order = { base, base }, {}, { side, 3 - side }
	for i = 1, SEEK_STEPS do
		for _, s in ipairs(order) do
			local last = reach[s]
			if last then
				local p = base + along * ((s == 1 and 1 or -1) * i * SEEK_STEP)
				if self:Trace(last, p).Hit then
					reach[s] = false
				else
					reach[s], far[s] = p, p
					if self:Opening(p, -n, up) then
						self.Way = { p, p - n * (h * 3), goal = goal }
						self.WayUntil = now + WAY_TIME
						return
					end
				end
			end
		end
	end
	if now - self.SkirtSince > SKIRT_TIME then return end
	for _, s in ipairs(order) do
		local p = far[s]
		if p and p:Distance(base) >= SKIRT_MIN and not self:Reached(p) then
			self.SkirtSide = s
			self.Way = { p, goal = goal }
			self.WayUntil = now + WAY_TIME
			return
		end
	end
end

function ENT:Side(goal, toward, now)
	if not self.SkirtGoal or self.SkirtGoal:Distance(goal) > 300 then
		self.SkirtGoal, self.SkirtSide, self.SkirtSince = goal, toward, now
	end
	return self.SkirtSide
end

function ENT:Unstick(to, now, time, from)
	if self:GetSwimming() then
		self:Veer(now, time, from)
		return
	end
	if self:Leap(to, now) then return end
	if self.BodyUp.z < -0.5 then
		self.LetGoUntil = now + 0.4
	else
		self:Veer(now, time, from)
	end
end

function ENT:Leap(to, now, meant)
	if now < (self.NextLeap or 0) or self:GetAct() ~= EvilCrawler.ACT_NONE then return false end
	local from = self:GetPos()
	if not meant and self.LeapFrom and from:Distance(self.LeapFrom) < LEAP_MISS and to:Distance(self.LeapTo) < LEAP_MISS then return false end
	local d = to + LIFT - from
	local dist = d:Length()
	if dist > LEAP_RANGE or dist < REACHED then return false end
	local g = EvilCrawler.GRAVITY
	for _, arc in ipairs(LEAP_ARCS) do
		local t = math.max(0.35, dist / LEAP_SPEED) * arc
		local vel = d / t + Vector(0, 0, g * t / 2)
		local last, clear = from, true
		for i = 1, 6 do
			local s = t * i / 6
			local p = from + vel * s - Vector(0, 0, g * s * s / 2)
			if self:Trace(last, p).Hit then clear = false break end
			last = p
		end
		if clear then
			self.Vel = vel
			self.LetGoUntil = now + t * 0.6
			self.NextLeap = now + t + LEAP_GAP
			self.LeapFrom, self.LeapTo = from, to
			self.ProgressTime = now + t
			return true
		end
	end
	return false
end

function ENT:Bash(door, at)
	if not DOORS[door:GetClass()] then
		self:Tear(door, at)
		return
	end
	local now = CurTime()
	if now < (door.EvilCrawlerBashed or 0) or EvilCrawler.Setting("open_doors") == 0 then return end
	door.EvilCrawlerBashed = now + BASH_GAP
	door:Fire("Unlock")
	if door:GetClass() == "prop_door_rotating" then
		door:Fire("OpenAwayFrom", "!activator", 0, self)
	else
		door:Fire("Open")
	end
	sound.Play(BASH_SOUNDS[math.random(#BASH_SOUNDS)], at, 85, math.random(80, 95))
end

function ENT:Tear(ent, at)
	local now = CurTime()
	if EvilCrawler.Setting("tear") == 0 or ent:IsVehicle() or ent:IsWorld() then return end
	local breaching = now < (self.BreachUntil or 0) and self:GetAct() == EvilCrawler.ACT_NONE
	if not (CHASING[self.State] or self.State == "rage" or breaching) or now - (self.ProgressTime or now) < TEAR_STALL then return end
	if self.Tearing ~= ent or now - self.TearAt > TEAR_LAPSE then
		local phys = ent:GetPhysicsObject()
		local mass = IsValid(phys) and phys:GetMass() or TEAR_MASS
		self.Tearing, self.TearStart = ent, now
		self.TearNeed = Lerp(math.min(1, mass / TEAR_MASS), TEAR_TIME[1], TEAR_TIME[2])
	end
	self.TearAt = now
	if self.Goal then self.Breach, self.BreachUntil = self.Goal, math.max(self.BreachUntil or 0, now + TEAR_LAPSE) end
	local wood = ent:GetMaterialType() == MAT_WOOD
	if now >= (self.NextRend or 0) then
		self.NextRend = now + TEAR_GAP * math.Rand(0.7, 1.3)
		local strain = wood and WOOD_STRAIN or METAL_STRAIN
		sound.Play(strain[math.random(#strain)], at, 90, math.random(80, 110))
		util.ScreenShake(at, 2, 8, 0.4, 700)
		if not wood then
			local fx = EffectData()
			fx:SetOrigin(at)
			fx:SetNormal(-self.Facing)
			fx:SetMagnitude(2)
			fx:SetRadius(3)
			util.Effect("Sparks", fx)
		end
		ent:TakeDamage(15, self, self)
	end
	if now - self.TearStart < self.TearNeed then return end
	self.Tearing = nil
	if self.Breach then self.BreachUntil = now + TEAR_PASS end
	local snap = wood and WOOD_BREAK or METAL_BREAK
	sound.Play(snap[math.random(#snap)], at, 95, math.random(80, 100))
	if not IsValid(ent) then return end
	self.Torn = self.Torn or {}
	self.Torn[ent] = now + TEAR_PASS
	local phys = ent:GetPhysicsObject()
	if ent:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(phys) then
		constraint.RemoveAll(ent)
		phys:EnableMotion(true)
		phys:Wake()
		phys:ApplyForceCenter((ent:WorldSpaceCenter() - self:GetPos()):GetNormalized() * phys:GetMass() * TEAR_PUSH)
	end
end

function ENT:Veer(now, time, from)
	local pos, up = self:GetPos(), self.BodyUp
	local dir = (self:Around(pos, 1) - pos):GetNormalized()
	if from then
		local away = pos - from
		away = away - up * away:Dot(up)
		if away:LengthSqr() > 1 then dir = (away:GetNormalized() + dir * VEER_SPREAD):GetNormalized() end
	end
	self.Detour = dir * 400
	self.DetourUntil = now + time
end

function ENT:Tipped(now)
	local hunter = EvilCrawler.Setting("hunter")
	if hunter <= 0 or EvilCrawler.IgnoresPlayers() or not self:IsHungry() then return false end
	if not self.NextTip then self.NextTip = now + TIP_GAP / hunter * math.Rand(0.3, 1) end
	if now < self.NextTip then return false end
	self.NextTip = now + TIP_GAP / hunter * math.Rand(0.7, 1.3)
	local picks = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE and not ply:IsFlagSet(FL_NOTARGET)
			and not EvilCrawler.Noclipping(ply) and self:Wants(ply) then
			picks[#picks + 1] = ply
		end
	end
	if #picks == 0 then return false end
	local fuzz = TIP_FUZZ / hunter
	self.LastKnown = Proxy(picks[math.random(#picks)]):GetPos() + Vector(math.Rand(-fuzz, fuzz), math.Rand(-fuzz, fuzz), 0)
	self:SetState("search")
	self.Goal = self.LastKnown
	self.SearchUntil = now + SEARCH_TIME * 2
	return true
end

function ENT:Pounce(prey, now)
	if self.BodyUp.z > -0.5 or self:GetSwimming() then return false end
	local pos, at = self:GetPos(), Proxy(prey):GetPos()
	if pos.z - at.z < self.BodyHeight * 2 then return false end
	if Vector(at.x - pos.x, at.y - pos.y, 0):Length() > POUNCE_REACH * self.Scale or not self:Clear(pos, prey) then return false end
	return self:Leap(at, now)
end

function ENT:Overhead(prey, now)
	prey = Proxy(prey)
	if self:GetSwimming() or self:SurfaceDistance(prey:GetPos()) >= REACHED then
		self.OverSince = nil
		return
	end
	if self.DetourUntil and now < self.DetourUntil then return end
	local below = (prey:WorldSpaceCenter() - self:GetPos()):Dot(self.BodyUp) < -self.BodyHeight
	self.OverSince = self.OverSince or now
	if below and self.BodyUp.z < -0.5 or now - self.OverSince > EvilCrawler.Setting("reroute_time") / self:Wits() then
		self.OverSince = nil
		self:Unstick(prey:GetPos(), now, OVER_VEER, prey:GetPos())
	end
end

function ENT:Fits(now)
	local r = RHYTHM[self.State]
	if self.Puppeting or not (r and r.go) then
		self.Still = false
		return
	end
	if now < self.FitUntil then return end
	self.Still = not self.Still
	local span = self.Still and r.stop or r.go
	self.FitUntil = now + math.Rand(span[1], span[2])
end

function ENT:Winded()
	local tired = self.Tired or 0
	if tired <= 0 then return 1 end
	local span = EvilCrawler.Setting("tired_time")
	if span <= 0 then
		self.Tired = 0
		return 1
	end
	if CHASING[self.State] and not self.Still then self.Tired = math.max(0, tired - FrameTime() / span) end
	return 1 - TIRED_SLOW * self.Tired
end

function ENT:Switched()
	if not (ai_disabled and ai_disabled:GetBool()) then return false end
	if self:Awake() and self:GetAct() ~= EvilCrawler.ACT_NONE then self:Release() end
	self:SetPrey(NULL)
	self:SetMood(0)
	self.DetourUntil = nil
	return true
end

function ENT:Steer()
	if self.Off then return nil, 0, SNAP end
	local now = CurTime()
	if now >= (self.NextThought or 0) then
		self.NextThought = now + ((self.Pace or 0) > 0.3 and QUICK_INTERVAL or THINK_INTERVAL)
		self:Ponder()
		self:Route(now)
		self:CheckProgress(now)
		if cv_debug:GetBool() and self.Goal then
			local c = STATE_COLOR[self.State] or color_white
			debugoverlay.Line(self:GetPos(), self.Goal, THINK_INTERVAL, c, true)
			debugoverlay.Text(self:GetPos() + self.BodyUp * 40, (self.State or "puppet") .. " " .. #(self.Hits or {}), THINK_INTERVAL)
		end
	end

	local pilot = self:Piloted()
	if pilot and (self:GetAct() == EvilCrawler.ACT_NONE or self.Jabbing) then return self:Drive(pilot, now) end

	local burst = EvilCrawler.Setting("burst") * self:Winded()
	if self.DetourUntil and now < self.DetourUntil then
		return self:GetPos() + self.Detour, (self.Pace or 0) * burst, SNAP
	end
	if now < (self.RiseUntil or 0) then return nil, 0, SNAP end
	self:Fits(now)
	if self.Still then return nil, 0, SNAP end
	local pace = self.Pace or 0
	if CHASING[self.State] then pace = pace * (1 + ANGER_PACE * (self.Anger or 0) + KNOW_PACE * self:Knows("outrun")) end
	if self.State == "drag" then
		pace = pace * (1 - math.Clamp(((self.HoldLag or 0) - SNAGGED[1]) / (SNAGGED[2] - SNAGGED[1]), 0, 0.9))
	end
	return self.Way and self.Way[1] or self.Goal, pace * burst, SNAP
end

local EYE_FLAGS = 65536 + 131072
local SCATTER_RANGE = 3000
local PRESENCE_REACH = 400

local function Disposition()
	return EvilCrawler.Setting("npcs_fight") > 0 and D_HT or D_NU
end

local function Fights(npc)
	return IsValid(npc) and npc:IsNPC() and npc:GetClass() ~= "npc_bullseye"
end

function ENT:Expose()
	local eye = ents.Create("npc_bullseye")
	eye:SetPos(self:GetPos())
	eye:SetParent(self)
	eye:SetKeyValue("spawnflags", tostring(EYE_FLAGS))
	eye:Spawn()
	eye:Activate()
	eye.HandlePerceivedRelationship = function() return self:HandlePerceivedRelationship() end
	self:DeleteOnRemove(eye)
	self.Eye = eye
	self:AddEFlags(EFL_DONTBLOCKLOS)
	self:AddFlags(FL_OBJECT)
	self.DrGBase_Target = true
	self.VJ_ID_Destructible = true
	self.MovementType = VJ_MOVETYPE_STATIONARY
	Evil.Presence(self, { reach = PRESENCE_REACH })

	local d = Disposition()
	for _, npc in ipairs(ents.GetAll()) do
		if Fights(npc) then npc:AddEntityRelationship(eye, d, 0) end
	end
end

local function Eyes()
	local eyes = {}
	for _, crawler in ipairs(ents.FindByClass("evil_crawler")) do
		if IsValid(crawler.Eye) then eyes[#eyes + 1] = crawler.Eye end
	end
	return eyes
end

local function Meet(ent, eyes)
	local d = Disposition()
	if ent.IsDrGNextbot then ent:SetClassRelationship("evil_crawler", d, 2) end
	if not Fights(ent) then return end
	for _, eye in ipairs(eyes) do ent:AddEntityRelationship(eye, d, 0) end
end

hook.Add("OnEntityCreated", "EvilCrawlerEnemy", function(ent)
	if not (ent:IsNPC() or ent:IsNextBot()) then return end
	timer.Simple(0, function()
		if IsValid(ent) then Meet(ent, Eyes()) end
	end)
end)

cvars.AddChangeCallback("evil_crawler_npcs_fight", function()
	local eyes = Eyes()
	for _, ent in ipairs(ents.GetAll()) do Meet(ent, eyes) end
end, "EvilCrawlerEnemy")

function ENT:HandlePerceivedRelationship()
	return self:Awake() and Disposition() or D_NU
end

function ENT:Scatter(now)
	local pos, eye = self:GetPos(), self.Eye
	Evil.Frighten(pos, SCATTER_RANGE, self.OutUntil - now, true)
	self.Cowed = {}
	for _, ent in ipairs(ents.FindInSphere(pos, SCATTER_RANGE)) do
		if ent.IsDrGNextbot then
			ent:SetEntityRelationship(self, D_FR, 3)
			self.Cowed[ent] = true
		elseif Fights(ent) and IsValid(eye) then
			ent:AddEntityRelationship(eye, D_FR, 99)
			self.Cowed[ent] = true
		end
	end
end

function ENT:Regroup()
	if not self.Cowed then return end
	local d = Disposition()
	for ent in pairs(self.Cowed) do
		if IsValid(ent) and ent.IsDrGNextbot then
			ent:SetEntityRelationship(self, D_NU, 1)
		elseif IsValid(ent) and IsValid(self.Eye) then
			ent:AddEntityRelationship(self.Eye, d, 0)
		end
	end
	self.Cowed = nil
end

timer.Create("EvilCrawlerEnemy", 1, 0, function()
	local crawlers = ents.FindByClass("evil_crawler")
	if #crawlers == 0 then return end
	for npc in pairs(Scent.npcs) do
		local list, memory
		if IsValid(npc) and not npc.IsZBaseNPC then list, memory = npc.RelationshipEnts, npc.RelationshipMemory end
		if istable(list) and istable(memory) then
			for _, crawler in ipairs(crawlers) do
				if not table.HasValue(list, crawler) then
					memory[crawler] = memory[crawler] or {}
					list[#list + 1] = crawler
				end
			end
		end
	end
end)

function ENT:OnTakeDamage(dmg)
	if dmg:GetDamage() <= 0 then return end
	local attacker, from = dmg:GetAttacker(), dmg:GetDamagePosition()
	timer.Simple(0, function()
		if IsValid(self) then self:Hurt(attacker, from) end
	end)
end

function ENT:Hurt(attacker, from)
	local now = CurTime()
	if self:GetAct() == EvilCrawler.ACT_DEAD then return end

	if now >= (self.NextPain or 0) then
		self.NextPain = now + 1.5
		self:EmitSound(PAIN_SOUNDS[math.random(#PAIN_SOUNDS)], 85, math.random(135, 155))
	end
	if self.Off then return end
	if self:GetAct() == EvilCrawler.ACT_OUT then
		self:Blame(attacker)
		if IsValid(attacker) and attacker:IsPlayer() then self.Blows = self.Blows + 1 end
		if EvilCrawler.Setting("killable") > 0 and self.Blows >= EvilCrawler.Setting("kill_hits") * self:Birth() then self:Die() end
		return
	end
	if self:Raging(now) then
		self:Blame(attacker)
		self.Blows = (self.Blows or 0) + self:Weight(attacker)
		local need = EvilCrawler.Setting("knockout_hits")
		if need > 0 and self.Blows >= need then self:KnockOut(now) end
		return
	end
	if EvilCrawler.Setting("knockout_anytime") > 0 and self:Battered(now, self:Weight(attacker)) then
		self:Blame(attacker)
		self:KnockOut(now)
		return
	end
	if self:Provoked(now, self:Weight(attacker)) then
		self:Rage(attacker, now)
		return
	end
	if self.State == "flee" then
		self:Accuse(attacker, now)
		return
	end
	self:Enrage(attacker, now)
	if not self:Flinches(now, self:Weight(attacker)) then return end

	if self:GetAct() ~= EvilCrawler.ACT_NONE then self:Release() end
	self:Flee(IsValid(attacker) and attacker:EyePos() or from, now)
	self.Trail = nil
	self.DetourUntil = nil
end

function ENT:Blame(by)
	if not IsValid(by) or by == self or by:IsWorld() then return end
	self:Accuse(by, CurTime())
	self.LastKnown = Proxy(self.Grudge):GetPos()
end

function ENT:Awake()
	local act = self:GetAct()
	return act ~= EvilCrawler.ACT_OUT and act ~= EvilCrawler.ACT_DEAD
end

function ENT:KnockOut(now)
	if self:GetAct() ~= EvilCrawler.ACT_NONE then self:Release() end
	self:SetRageUntil(now)
	if self.Roar then self.Roar:FadeOut(1) end
	self:SetPrey(NULL)
	self:SetAct(EvilCrawler.ACT_OUT)
	self:SetActStart(now)
	self:SetState("out")
	self.Blows = 0
	self.OutUntil = now + EvilCrawler.Setting("knockout_time") * math.Rand(OUT_SPREAD[1], OUT_SPREAD[2])
	self.LetGoUntil = self.OutUntil
	self.Goal, self.Trail, self.DetourUntil = nil, nil, nil
	self.Breach, self.BreachUntil = nil, nil
	self:Scatter(now)
	self:EmitSound(OUT_SOUND, 80, math.random(70, 80))
	self:EmitSound(PAIN_SOUNDS[math.random(#PAIN_SOUNDS)], 85, math.random(70, 85))
	self.Breath = self.Breath or CreateSound(self, BREATH_LOOP)
	self.Breath:PlayEx(0.35, 150)
end

function ENT:Wake(now)
	self:SetAct(EvilCrawler.ACT_NONE)
	self:Regroup()
	if self.Breath then self.Breath:FadeOut(0.5) end
	self:EmitSound(WAKE_SOUND, 80, math.random(60, 70))
	self.LetGoUntil = nil
	self.RiseUntil = now + RISE_TIME
	self.Tired = 1
	self.Anger = ANGER_MAX
	self.CalmAt = now + ANGER_FADE
	self.Spent = nil
	self.HeardAt, self.Noise, self.Taunt = now, nil, nil
	self:SetState("search")
	self.Goal = self.LastKnown
	self.SearchUntil = now + SEARCH_TIME
	if IsValid(self.Grudge) then self.Hunted, self.SensedAt = self.Grudge, now end
end

function ENT:Die()
	local pos = self:GetPos()
	self:SetAct(EvilCrawler.ACT_DEAD)
	self:SetActStart(CurTime())
	self:SetState("dead")
	self.LetGoUntil = math.huge
	if self.Breath then self.Breath:Stop() end
	self:Regroup()
	if IsValid(self.Eye) then self.Eye:Remove() end
	self:Empty()
	for _ = 1, 4 do
		local fx = EffectData()
		fx:SetOrigin(pos + VectorRand() * 12)
		fx:SetNormal(VectorRand())
		fx:SetColor(BLOOD_COLOR_YELLOW)
		util.Effect("BloodImpact", fx)
	end
	self:EmitSound(DEATH_SOUND, 80, math.random(80, 95))
	self:EmitSound(PAIN_SOUNDS[math.random(#PAIN_SOUNDS)], 90, math.random(55, 65))
	SafeRemoveEntityDelayed(self, EvilCrawler.CORPSE_TIME)
end

function ENT:Raging(now)
	return now < self:GetRageUntil()
end

function ENT:Weight(attacker)
	return (IsValid(attacker) and attacker:IsPlayer() and 1 or EvilCrawler.Setting("npc_hits")) / self:Birth()
end

function ENT:Provoked(now, w)
	if EvilCrawler.Setting("rage_time") <= 0 then return false end
	self.Hits = self.Hits or {}
	self.Hits[#self.Hits + 1] = { now, w }
	while now - self.Hits[1][1] > RAGE_WINDOW do table.remove(self.Hits, 1) end
	local sum = 0
	for _, hit in ipairs(self.Hits) do sum = sum + hit[2] end
	return sum >= EvilCrawler.Setting("rage_hits")
end

function ENT:Battered(now, w)
	local need = EvilCrawler.Setting("knockout_hits")
	if need <= 0 then return false end
	if now - (self.BlowAt or -math.huge) > RAGE_WINDOW then self.Blows = 0 end
	self.Blows, self.BlowAt = self.Blows + w, now
	return self.Blows >= need
end

function ENT:Flinches(now, w)
	if EvilCrawler.Setting("flee") == 0 then return false end
	if now - (self.StungAt or -math.huge) > RAGE_WINDOW then self.Stings = 0 end
	self.Stings, self.StungAt = self.Stings + w, now
	if self.Stings < EvilCrawler.Setting("flee_hits") + EvilCrawler.Setting("nerve") * (self.Fled or 0) then return false end
	self.Stings = 0
	self.Fled = (self.Fled or 0) + 1
	return true
end

function ENT:Rage(by, now)
	self.Hits, self.Blows = nil, 0
	if self:GetAct() ~= EvilCrawler.ACT_NONE then self:Release() end
	self:Accuse(by, now)
	self.Closing = nil
	self:SetRageUntil(now + EvilCrawler.Setting("rage_time"))
	self:SetState("rage")
	self.Trail, self.DetourUntil, self.Goal = nil, nil, nil
	self:EmitSound(RAGE_SOUND, 90, 80)
	self.Roar = self.Roar or CreateSound(self, RAGE_LOOP)
	self.Roar:Stop()
	self.Roar:PlayEx(1, 120)
end

local function Burnable(ent)
	if not IsValid(ent) or not (ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot()) then return false end
	if ent.EvilCrawlerVictim or ent:IsFlagSet(FL_NOTARGET) then return false end
	if ent:IsPlayer() then
		return ent:Alive() and not EvilCrawler.IgnoresPlayers() and not ent:HasGodMode()
			and not EvilCrawler.Noclipping(ent) and ent:GetObserverMode() == OBS_MODE_NONE
	end
	return Creature(ent) and EvilCrawler.Living(ent) and ent:GetClass() ~= "npc_bullseye" and not Victim.Shrugged(ent)
end

function ENT:Accuse(by, now)
	if not IsValid(by) or by == self or by:IsWorld() then return end
	local held = self.Grudge
	if by ~= held and Burnable(held) and now - (self.GrudgeAt or -math.huge) < GRUDGE_HOLD
		and self:Weight(by) <= self:Weight(held) * GRUDGE_OUTWEIGH then
		return
	end
	self.Grudge, self.GrudgeAt = by, now
end

function ENT:Balks(ent, now)
	return self.Balked ~= nil and (self.Balked[ent] or 0) > now
end

function ENT:Quarry(now)
	local pos = self:GetPos()
	local grudge = Burnable(self.Grudge) and self.Grudge or nil
	if grudge and not self:Balks(grudge, now) then
		if self:Clear(pos, grudge, nil, MASK_OPAQUE) then self.GrudgeAt = now end
		if now - (self.GrudgeAt or -math.huge) < GRUDGE_HOLD then return grudge end
	end
	local best, bestDist = nil, EvilCrawler.Setting("sight_range") * self:Wits()
	for _, ent in ipairs(ents.FindInSphere(pos, bestDist)) do
		if ent ~= grudge and Burnable(ent) and not self:Balks(ent, now) then
			local d = Proxy(ent):WorldSpaceCenter():Distance(pos)
			if d < bestDist and self:Clear(pos, ent, nil, MASK_OPAQUE) then best, bestDist = ent, d end
		end
	end
	if not best then return grudge end
	self.Grudge, self.GrudgeAt = best, now
	return best
end

function ENT:Closes(target, pos, now)
	local d = Proxy(target):NearestPoint(pos):Distance(pos)
	if self.Closing ~= target or d < self.ClosestIn - BALK_STEP then
		self.Closing, self.ClosestIn, self.ClosedAt = target, d, now
	elseif now - self.ClosedAt > RAGE_BALK then
		self.Balked = self.Balked or setmetatable({}, { __mode = "k" })
		self.Balked[target] = now + GRUDGE_HOLD
		self.Closing = nil
	end
end

function ENT:Rampage(now)
	if not self:Raging(now) then
		if self.Roar then self.Roar:FadeOut(1) end
		self:Flee(nil, now)
		return false
	end

	local pos = self:GetPos()
	local target = self:Quarry(now)
	self:SetPrey(target or NULL)
	if not target then
		if not self.Goal or self:Reached(self.Goal) then self.Goal = self:Around(pos, 600) end
		return true
	end
	if Proxy(target):NearestPoint(pos):Distance(pos) < RAGE_REACH * self.Scale and self:Reachable(target) then
		self:Sear(target)
		return true
	end
	self.Goal = Proxy(target):GetPos()
	self:Hurl(target, now)
	self:Closes(target, pos, now)
	self:Overhead(target, now)
	return true
end

function ENT:Throwable(ent)
	if not THROWN[ent:GetClass()] or ent:GetMoveType() ~= MOVETYPE_VPHYSICS or ent:IsPlayerHolding() or Evil.Owner(ent) then return end
	local phys = ent:GetPhysicsObject()
	if not IsValid(phys) or not phys:IsMotionEnabled() or constraint.HasConstraints(ent) then return end
	if phys:GetMass() > THROW_MASS * self.Scale then return end
	return phys
end

function ENT:Hurl(target, now)
	if EvilCrawler.Setting("throw") == 0 or now < (self.NextHurl or 0) or not Burnable(target) then return false end
	self.NextHurl = now + math.Rand(THROW_GAP[1], THROW_GAP[2])
	local pos = self:GetPos()
	local aim = Proxy(target):WorldSpaceCenter()
	local d = aim:Distance(pos)
	if d < THROW_RANGE[1] or d > THROW_RANGE[2] or not self:Clear(pos, target, nil, MASK_OPAQUE) then return false end
	local best, bestPhys, bestMass
	for _, ent in ipairs(ents.FindInSphere(pos, THROW_REACH * self.Scale)) do
		local phys = self:Throwable(ent)
		if phys and (not best or phys:GetMass() > bestMass)
			and not util.TraceLine({ start = ent:WorldSpaceCenter(), endpos = aim, filter = { ent, self, target }, mask = MASK_SOLID_BRUSHONLY }).Hit then
			best, bestPhys, bestMass = ent, phys, phys:GetMass()
		end
	end
	if not best then return false end
	local from = best:WorldSpaceCenter()
	local t = math.max(0.15, from:Distance(aim) / THROW_SPEED)
	local fall = -physenv.GetGravity().z
	local vel = (aim - from) / t + Vector(0, 0, 0.5 * fall * t)
	bestPhys:Wake()
	bestPhys:SetVelocity(vel)
	bestPhys:AddAngleVelocity(VectorRand() * 400)
	self.Torn = self.Torn or {}
	self.Torn[best] = now + 2
	sound.Play(THROW_SOUNDS[math.random(#THROW_SOUNDS)], from, 80, math.random(70, 90))
	return true
end

function ENT:ShotHits(src, dir, range, shooter)
	if self:GetAct() == EvilCrawler.ACT_DEAD then return end
	local center = self:GetPos()
	local r = self.BodyHeight * SHOT_RADIUS
	local t = (center - src):Dot(dir)
	local miss = (src + dir * t):DistToSqr(center)
	if t < 0 or miss > r * r then return end
	local enter = math.max(0, t - math.sqrt(r * r - miss))
	if enter > range then return end

	local hit = src + dir * enter
	local tr = util.TraceLine({ start = src, endpos = hit, mask = MASK_SHOT, filter = shooter })
	if tr.Hit and tr.Entity ~= self then return end
	return hit, enter
end

hook.Add("EntityFireBullets", "EvilCrawlerShot", function(shooter, data)
	shooter.EvilCrawlerFiredAt = CurTime()
	local dir = data.Dir:GetNormalized()
	local range = data.Distance or 56756
	local filter = { shooter, data.IgnoreEntity }
	local struck, hit, nearest
	for _, crawler in ipairs(ents.FindByClass("evil_crawler")) do
		local p, d = crawler:ShotHits(data.Src, dir, range, filter)
		if p and (not nearest or d < nearest) then struck, hit, nearest = crawler, p, d end
	end
	if not struck then return end

	local fx = EffectData()
	fx:SetOrigin(hit)
	fx:SetNormal(-dir)
	fx:SetColor(BLOOD_COLOR_YELLOW)
	util.Effect("BloodImpact", fx)
	sound.Play(PAIN_HIT_SOUND, hit, 70, math.random(90, 110), 0.7)

	local attacker = IsValid(data.Attacker) and data.Attacker or shooter
	struck:Hurt(attacker, hit)

	data.Distance = nearest
	return true
end)

function ENT:Flee(threat, now, slink)
	self:SetPrey(NULL)
	self:SetState("flee")
	self.Goal = self:FindLair(threat)
	self.FleeFrom, self.FledAt = threat, now
	self.FleeUntil = now + FLEE_TIME
	self.Slunk = slink
	self.Breach, self.BreachUntil = nil, nil
end

function ENT:Watcher()
	local pos = self:GetPos()
	for _, ent in ipairs(ents.FindInSphere(pos, HIDE_SIGHT)) do
		if (ent:IsPlayer() or Creature(ent)) and ent:GetClass() ~= "npc_bullseye" and Perceivable(ent)
			and not self:Trace(ent:EyePos(), pos, MASK_OPAQUE).Hit then
			return ent
		end
	end
end

function ENT:LyingLow(now)
	if self.State == "flee" then
		self:Hurl(self.Grudge, now)
		if self.Goal and not self:Reached(self.Goal) and now < self.FleeUntil then return true end
		if now - (self.FledAt or 0) < FLEE_MIN then
			self.Goal = self:FindLair(self.FleeFrom)
			return true
		end
		self:SetState("hide")
		if not self.Slunk then
			self.RestNeed = EvilCrawler.Setting("hide_time") * math.Rand(HIDE_SPREAD[1], HIDE_SPREAD[2])
			self.HideUntil = now + self.RestNeed * HIDE_CEILING
		end
		self.Rest, self.RestAt, self.SeenSince = 0, now, nil
	end
	if self.State ~= "hide" then return false end
	if self.Rest < self.RestNeed and now < self.HideUntil then
		self.Goal = nil
		local watcher = self:Watcher()
		if watcher then
			self.SeenSince = self.SeenSince or now
			if now - self.SeenSince > SEEN_RESET then self:Flee(watcher:EyePos(), now, true) end
		else
			self.Rest = self.Rest + now - self.RestAt
			self.SeenSince = nil
		end
		self.RestAt = now
		return true
	end
	self:SetState("roam")
	return false
end

function ENT:Enrage(by, now)
	self:Accuse(by, now)
	self.Anger = math.min(ANGER_MAX, (self.Anger or 0) + 1)
	self.CalmAt = now + ANGER_FADE
end

function ENT:Cool(now)
	if (self.Anger or 0) > 0 and now > self.CalmAt then
		self.Anger = self.Anger - 1
		self.CalmAt = now + ANGER_FADE
		if self.Anger == 0 then self.Grudge = nil end
	end
end

local function Flat(v, up)
	return v - up * v:Dot(up)
end

function ENT:Drive(pilot, now)
	local input = pilot.EvilCrawlerDrive
	if not input then return nil, 0, SNAP end
	local pos, up = self:GetPos(), self.BodyUp
	local ang = input.ang
	local aim = ang:Forward()
	if bit.band(input.buttons, IN_ATTACK) ~= 0 then self:PilotStrike(pilot, aim) end
	if bit.band(input.buttons, IN_JUMP) ~= 0 then
		local tr = self:Trace(pos, pos + aim * LEAP_RANGE)
		local to = tr.HitPos - aim * 16
		if tr.Hit and (to - pos):Dot(up) < 0 and to:Distance(pos) < PILOT_LEAP then
			local dir = Flat(aim, up)
			if dir:LengthSqr() < 0.01 then dir = self.Facing end
			dir = dir:GetNormalized()
			to = self:Trace(pos, pos + dir * PILOT_LEAP).HitPos - dir * 16
		end
		if self:Leap(to, now, true) then return nil, 0, SNAP end
	end

	local ahead = Flat(aim, up) + Flat(ang:Up(), up) * math.max(0, -aim:Dot(up))
	local wish = ahead:GetNormalized() * math.Clamp(input.fwd, -1, 1) + Flat(ang:Right(), up):GetNormalized() * math.Clamp(input.side, -1, 1)
	if wish:LengthSqr() < 0.01 then return nil, 0, SNAP end
	local pace = bit.band(input.buttons, IN_SPEED) ~= 0 and PILOT_PACE[2] or PILOT_PACE[1]
	return pos + wish:GetNormalized() * (self.BodyHeight * 4), pace * EvilCrawler.Setting("burst") * self:Winded(), SNAP
end

function ENT:PuppetGoal()
	local ply = self.Master
	if not IsValid(ply) then return end

	local eye = ply:EyePos()
	local tr = util.TraceLine({ start = eye, endpos = eye + ply:GetAimVector() * 4096, filter = { ply, self } })
	if tr.Hit then return tr.HitPos end
end
