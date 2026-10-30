local Victim = EvilCrawler.Victim
local Creature = EvilCrawler.Creature
local Proxy = EvilCrawler.Proxy
local Souls = EvilCrawler.Souls
local ACT_NONE, ACT_STRIKE, ACT_DRAG, ACT_FEED =
	EvilCrawler.ACT_NONE, EvilCrawler.ACT_STRIKE, EvilCrawler.ACT_DRAG, EvilCrawler.ACT_FEED
local ACT_GRAPPLE, ACT_STUN, ACT_SEAR = EvilCrawler.ACT_GRAPPLE, EvilCrawler.ACT_STUN, EvilCrawler.ACT_SEAR
local HELD_VAR, FREE_VAR = EvilCrawler.HELD_VAR, EvilCrawler.FREE_VAR

local IMPACT_TIME = EvilCrawler.STRIKE_WINDUP + EvilCrawler.STRIKE_LUNGE

local ATTACK_REACH = 140
local MISS_REACH = ATTACK_REACH * 1.5
local PULL_TIME = EvilCrawler.PULL_TIME
local TRAIL_RATE = 1.5
local TRAIL_SPEED = 250
local FEEDERS = EvilCrawler.FEEDERS
local BITE_IN, BITE_RIP = EvilCrawler.BITE_IN, EvilCrawler.BITE_RIP
local BiteCycle, BiteBone = EvilCrawler.BiteCycle, EvilCrawler.BiteBone
local PARTS, CurrentPart = EvilCrawler.PARTS, EvilCrawler.CurrentPart
local TORSO_TIME = 6
local FINISH_TIME = 2
local GULP_DEPTH = 5
local HEAVE_DEPTH = 22
local GULP_RATE = EvilCrawler.GULP_RATE
local FEED_CAP = 60
local STAB_FORCE = 120
local RIP_FORCE = 350
local DRAINED = 40
local TURN_SPEED = 35
local SNAG_LAG = 300
local SNAG_TIME = 1.5
local DRAG_TIME = 15
local ANGER_HUNGER = 0.5
local LAIR_TRIES = 12
local LAIR_RANGE = { 700, 2500 }
local OUT_OF_SIGHT = 1500
local DISTURB_RANGE = 330
local PRESS_GAIN = 0.1
local PRESS_RATE = 16
local PRESS_BURST = 4
local SLIP = 0.3
local ESCAPE_MEMORY = 90
local KNOW_MAX = 3
local KNOW_GRIP = 0.5
local KNOW_REACH = 0.25
local REEL = 0.45
local LIFT = 18
local NIP_TIME = { 0.45, 0.9 }
local NIP_DAMAGE = 2
local THROWN = { 420, 220 }
local STUN_KNOCK = 300
local SPOOKED = 60
local FLUNG = { 900, 420, 120 }
local SPIN = 900
local BURN_TIME = 6
local CHARRED = Color(70, 50, 45)
local CARRION_RANGE = 1500
local LEFTOVER_RANGE = 4000
local REEK_REFRESH = 40
local REEK_MOVED = 150
local FRESH_TIME = 60
local AIRBORNE = 10
local REEK_FRESH, REEK_STALE = 3, 1.5
local SMELL_NEAR = 600
local RING_TRIES = 12
local RING_GAP = 1
local CRAVE_GAP = 2
local CRAVE_CLOSER = 48
local GIVE_UP = 10
local SHUN_TIME = 60
local carrion = {}

local WINDUP_SOUNDS = { "npc/barnacle/barnacle_tongue_pull1.wav", "npc/barnacle/barnacle_tongue_pull2.wav" }
local LUNGE_SOUND = "npc/zombie/claw_miss1.wav"
local GRAB_SOUNDS = {
	"physics/body/body_medium_impact_soft1.wav",
	"physics/body/body_medium_impact_soft3.wav",
	"physics/body/body_medium_impact_soft5.wav",
}
local STAB_SOUNDS = {
	"physics/flesh/flesh_impact_bullet1.wav",
	"physics/flesh/flesh_impact_bullet3.wav",
	"physics/flesh/flesh_impact_bullet5.wav",
}
local CRUNCH_SOUNDS = { "npc/barnacle/barnacle_crunch2.wav", "npc/barnacle/barnacle_crunch3.wav" }
local RIP_SOUNDS = {
	"physics/flesh/flesh_bloody_break.wav",
	"physics/flesh/flesh_squishy_impact_hard1.wav",
	"physics/flesh/flesh_squishy_impact_hard3.wav",
	"physics/flesh/flesh_squishy_impact_hard4.wav",
}
local CONSUME_SOUNDS = {
	"physics/body/body_medium_break2.wav",
	"physics/body/body_medium_break3.wav",
	"physics/body/body_medium_break4.wav",
}
local GULP_SOUNDS = { "npc/barnacle/barnacle_gulp1.wav", "npc/barnacle/barnacle_gulp2.wav" }
local NIP_SOUNDS = { "physics/flesh/flesh_impact_bullet2.wav", "physics/flesh/flesh_impact_bullet4.wav" }
local STUN_SOUNDS = { "npc/barnacle/barnacle_die1.wav", "npc/barnacle/barnacle_die2.wav" }
local STUN_CRACK = "physics/flesh/flesh_squishy_impact_hard2.wav"
local SEAR_SOUNDS = { "weapons/physcannon/energy_disintegrate4.wav", "weapons/physcannon/energy_disintegrate5.wav" }
local SEAR_GRAB = "ambient/fire/ignite.wav"
local SIDES = { Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0) }
local SKULL, RIB = "models/gibs/hgibs.mdl", "models/gibs/hgibs_rib.mdl"
local SCAPULA, SPINE = "models/gibs/hgibs_scapula.mdl", "models/gibs/hgibs_spine.mdl"
local BONES = { { SKULL }, { SCAPULA, SCAPULA, RIB }, { RIB, RIB, SPINE }, { SPINE } }
local SPIT_DELAY = { 1, 2 }
local SPIT_SPEED = { 120, 280 }
local SPIT_SOUNDS = { "npc/barnacle/barnacle_bark1.wav", "npc/barnacle/barnacle_bark2.wav" }
local MAX_BONES = 60
local MAX_VOICES = 12
local MURMUR_GAP = { 25, 60 }
local MUFFLED = 15
local PILOT_STRIKE_GAP = 0.25
local PILOT_AIM = 0.85
local JAB_RADIUS = 40
local INSIDE_VAR = EvilCrawler.INSIDE_VAR
local spat = {}

function ENT:IsEdible(ent)
	if not Creature(ent) or not EvilCrawler.Living(ent) or ent.EvilCrawlerVictim or EvilCrawler.Held(ent) or Victim.Shrugged(ent) then return false end
	if EvilCrawler.Setting("attack_npcs") == 0 and ent ~= self.Grudge then return false end
	if ent:IsNextBot() then return true end
	if ent:GetMoveType() ~= MOVETYPE_STEP then return false end
	local size = ent:OBBMaxs() - ent:OBBMins()
	return size.z >= 30 and size.z <= 100 and math.max(size.x, size.y) <= 60
end

function ENT:IsHungry()
	return CurTime() >= (self.SatedUntil or 0)
end

function ENT:Wants(ply)
	if EvilCrawler.IgnoresPlayers() or ply:HasGodMode() then return false end
	if ply:LookupBone("ValveBiped.Bip01_Spine2") == nil then return false end
	local digesting = CurTime() - (self.FedAt or -math.huge) < EvilCrawler.Setting("digest_time")
	return not digesting or ply == self.Grudge
end

function ENT:WouldTake(ply)
	return self:Wants(ply) and ply:Alive() and not ply.EvilCrawlerVictim and not EvilCrawler.Held(ply)
end

function ENT:CanAttack(ent)
	if Proxy(ent):WorldSpaceCenter():Distance(self:GetPos()) >= ATTACK_REACH * self.Scale then return false end
	if not self:Reachable(ent) then return false end
	if ent:IsPlayer() then return self:WouldTake(ent) end
	return self:IsHungry() and self:IsEdible(ent)
end

function ENT:Reachable(ent)
	local pos = self:GetPos()
	return self:Clear(pos, ent) or self:Clear(pos, ent, Proxy(ent):EyePos())
end

function ENT:StartStrike(npc)
	npc.EvilCrawlerVictim = self
	sound.Play(WINDUP_SOUNDS[math.random(#WINDUP_SOUNDS)], self:GetPos(), 60, math.random(70, 85), 0.7)

	self:SetPrey(NULL)
	self:SetVictim(npc)
	self:SetAct(ACT_STRIKE)
	self:SetActStart(CurTime())
	self:SetState("strike")
	self.Lunged = false
	self.DetourUntil = nil
end

function ENT:Sear(victim)
	victim.EvilCrawlerVictim = self
	sound.Play(SEAR_GRAB, Proxy(victim):WorldSpaceCenter(), 80, math.random(90, 110))
	self:SetPrey(NULL)
	self:SetVictim(victim)
	self:SetAct(ACT_SEAR)
	self:SetActStart(CurTime())
	self.Goal = nil
end

local function Fling(body, vel)
	body:SetColor(CHARRED)
	body:Ignite(BURN_TIME)
	for i = 0, body:GetPhysicsObjectCount() - 1 do
		local phys = body:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			phys:SetVelocity(vel + VectorRand() * FLUNG[3])
			phys:AddAngleVelocity(VectorRand() * SPIN)
		end
	end
end

local function Dissolve(ent)
	local dissolver = ents.Create("env_entity_dissolver")
	if ent:GetName() == "" then ent:SetName("evil_crawler_sear" .. ent:EntIndex()) end
	dissolver:SetKeyValue("dissolvetype", "0")
	dissolver:Spawn()
	dissolver:Fire("Dissolve", ent:GetName())
	dissolver:Fire("Kill", "", 0.1)
end

function ENT:Incinerate(victim)
	self:Release()
	victim.EvilCrawlerVictim = nil
	if victim:IsPlayer() and (not victim:Alive() or victim:GetObserverMode() ~= OBS_MODE_NONE) then return end
	if not victim:IsPlayer() and Victim.Shrugs(victim, self) then return end
	if victim:IsPlayer() and victim:InVehicle() then Victim.Yank(victim, self:GetPos()) end
	local center = Proxy(victim):WorldSpaceCenter()

	local fx = EffectData()
	fx:SetOrigin(center)
	util.Effect("cball_explode", fx)
	sound.Play(SEAR_SOUNDS[math.random(#SEAR_SOUNDS)], center, 85, math.random(90, 110))
	sound.Play(RIP_SOUNDS[math.random(#RIP_SOUNDS)], center, 85, math.random(70, 85))

	local away = center - self:GetPos()
	away.z = 0
	away = away:LengthSqr() > 1 and away:GetNormalized() or self.Facing
	local vel = away * FLUNG[1] + vector_up * FLUNG[2]

	if victim:IsNPC() and IsValid(victim:GetActiveWeapon()) then victim:DropWeapon() end
	local body = victim:IsPlayer() and Victim.Fall(victim) or Victim.Body(victim)
	if not IsValid(body) then
		local dmg = DamageInfo()
		dmg:SetDamage(math.max(victim:Health(), 1) * 10 + 1000)
		dmg:SetDamageType(victim:IsPlayer() and DMG_GENERIC or DMG_DISSOLVE)
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamagePosition(center)
		victim:TakeDamageInfo(dmg)
		if IsValid(victim) and not victim:IsPlayer() and EvilCrawler.Living(victim) then Dissolve(victim) end
		return
	end

	Fling(body, vel)
	if victim:IsPlayer() and EvilCrawler.Fake(victim) == body then
		Victim.Slay(victim)
		return
	end
	if victim:IsPlayer() then
		body:SetNW2Entity(EvilCrawler.OWNER_VAR, victim)
		body:SetNW2Vector(EvilCrawler.COLOR_VAR, victim:GetPlayerColor())
		victim:KillSilent()
		victim:AddDeaths(1)
		hook.Run("PlayerDeath", victim, self, self)
		victim:Spectate(OBS_MODE_CHASE)
		victim:SpectateEntity(body)
		return
	end
	hook.Run("OnNPCKilled", victim, self, self)
	victim:Remove()
end

function ENT:Release()
	local victim = self:GetVictim()
	if IsValid(victim) and victim.EvilCrawlerVictim == self then victim.EvilCrawlerVictim = nil end
	if IsValid(victim) and carrion[victim] and not self.Devoured then self.Leftover = victim end
	if IsValid(victim) and not self.Devoured and victim.EvilCrawlerPlayer then self:LetGoOf(victim.EvilCrawlerPlayer) end
	if IsValid(victim) and victim:IsPlayer() then self:LetGo(victim) end
	self:SetVictim(NULL)
	self:SetAct(ACT_NONE)
	self.Lair = nil
	self.CarryDir = nil
	self.BiteStage = nil
	self.BitePart = nil
	self.Devoured = nil
	self.Jabbing = nil
	self.SnaggedSince = nil
end

function ENT:Mercy()
	local victim = self:GetVictim()
	if not IsValid(victim) then return false end
	if victim:IsPlayer() then
		if not victim:HasGodMode() then return false end
		self:Release()
		return true
	end
	if not Victim.Spared(victim) then return false end
	self:Release()
	Victim.Spare(victim)
	return true
end

local function Smooth(t)
	return t * t * (3 - 2 * t)
end

local function Core(corpse)
	if corpse.EvilCrawlerCore then return corpse.EvilCrawlerCore end
	local count, center, mass = corpse:GetPhysicsObjectCount(), Vector(), 0
	for i = 0, count - 1 do
		local phys = corpse:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			center:Add(phys:LocalToWorld(phys:GetMassCenter()) * phys:GetMass())
			mass = mass + phys:GetMass()
		end
	end
	if mass <= 0 then return 0 end
	center:Div(mass)
	local best, bestDist = 0, math.huge
	for i = 0, count - 1 do
		local phys = corpse:GetPhysicsObjectNum(i)
		if IsValid(phys) then
			local d = phys:LocalToWorld(phys:GetMassCenter()):DistToSqr(center)
			if d < bestDist then best, bestDist = i, d end
		end
	end
	corpse.EvilCrawlerCore = best
	return best
end

local function Chest(corpse)
	local bone = corpse:LookupBone("ValveBiped.Bip01_Spine2")
	local index = bone and corpse:TranslateBoneToPhysBone(bone) or -1
	return corpse:GetPhysicsObjectNum(index >= 0 and index or Core(corpse))
end

local function Partless(corpse)
	return not CurrentPart(corpse) and corpse:GetNW2Int(EvilCrawler.EATEN_VAR, 0) == 0 and not EvilCrawler.Shared(corpse)
end

local function Fleshy(rag)
	return rag:LookupBone("ValveBiped.Bip01_Spine2") ~= nil or rag:GetPhysicsObjectCount() > 1
end

local function Rotting(rag)
	if not IsValid(rag) or Victim.bodies[rag] or rag.EvilCrawlerVictim or rag.EvilDowned or EvilCrawler.Faker(rag) then return false end
	if not CurrentPart(rag) and not Partless(rag) then return false end
	if EvilCrawler.Shared(rag) then return true end
	local chest = Chest(rag)
	return IsValid(chest) and chest:IsMotionEnabled()
end

function ENT:IsCarrion(rag)
	return Rotting(rag)
end

function ENT:Heart(rag)
	return Chest(rag):GetPos()
end

function ENT:Shun(corpse, now)
	self.Shunned = self.Shunned or setmetatable({}, { __mode = "k" })
	self.Shunned[corpse] = now + SHUN_TIME
	self.Craving = nil
	if self.Leftover == corpse then self.Leftover = nil end
end

function ENT:Shuns(corpse, now)
	return self.Shunned ~= nil and (self.Shunned[corpse] or 0) > now
end

function ENT:Ring(corpse, now)
	self.Rings = self.Rings or setmetatable({}, { __mode = "k" })
	local seen = self.Rings[corpse]
	if seen and now - seen.at < RING_GAP and not (seen.node and seen.node.dead) then return seen end
	local pos, heart = self:GetPos(), self:Heart(corpse)
	seen = { at = now, open = not self:Trace(pos, heart).Hit, node = false }
	self.Rings[corpse] = seen
	if seen.open then return seen end
	local nodes = {}
	for _, trail in ipairs(EvilCrawler.Scent.reeks[corpse] or {}) do
		local node = trail.first
		while node do
			if not node.dead then nodes[#nodes + 1] = { node, node.pos:Distance(pos) + node.pos:Distance(heart) } end
			node = node.next
		end
	end
	table.sort(nodes, function(a, b) return a[2] < b[2] end)
	for i = 1, math.min(#nodes, RING_TRIES) do
		if self:Smells(nodes[i][1]) then
			seen.node = nodes[i][1]
			break
		end
	end
	return seen
end

function ENT:Approach(corpse, now)
	local pos, heart = self:GetPos(), self:Heart(corpse)
	local goal = heart
	local ring = self:Ring(corpse, now)
	if not ring.open and ring.node then
		ring.node = self:FollowTrail(ring.node)
		goal = ring.node.pos
	end
	local left = pos:Distance(goal) + goal:Distance(heart)
	if self.Craving ~= corpse or now - self.CravedAt > CRAVE_GAP then
		self.Craving, self.CraveLeft, self.CraveSince = corpse, left, now
	elseif left < self.CraveLeft - CRAVE_CLOSER then
		self.CraveLeft, self.CraveSince = left, now
	elseif now - self.CraveSince > GIVE_UP then
		self:Shun(corpse, now)
	end
	self.CravedAt = now
	return goal
end

function ENT:Carrion()
	if EvilCrawler.Setting("eat_corpses") == 0 or not self:IsHungry() then return end
	local now, pos, best, bestDist = CurTime(), self:GetPos()
	for rag in pairs(carrion) do
		if self:IsCarrion(rag) and not self:Shuns(rag, now) then
			local heart = self:Heart(rag)
			local d = heart:Distance(pos)
			if not best or d < bestDist then
				local known = rag == self.Leftover and d < LEFTOVER_RANGE
				local smelt = d < CARRION_RANGE and now - (rag.EvilCrawlerDiedAt or now) > AIRBORNE
				local way = smelt and d >= SMELL_NEAR and self:Ring(rag, now)
				if way then smelt = way.open or way.node ~= false end
				if known or smelt or d < CARRION_RANGE and self:Clear(pos, rag, heart, MASK_OPAQUE) then
					best, bestDist = rag, d
				end
			end
		end
	end
	return best
end

function ENT:Scavenge(corpse)
	local center = self:Heart(corpse)
	if center:Distance(self:GetPos()) >= ATTACK_REACH * self.Scale or not self:Clear(self:GetPos(), corpse, center) then return false end
	for i = 0, corpse:GetPhysicsObjectCount() - 1 do
		local phys = corpse:GetPhysicsObjectNum(i)
		if IsValid(phys) then phys:Wake() end
	end
	sound.Play(GRAB_SOUNDS[math.random(#GRAB_SOUNDS)], center, 75, math.random(80, 95))
	self:SetPrey(NULL)
	self:SetVictim(corpse)
	self.CarryDir = (center - self:GetPos()):GetNormalized()
	self.Eaten = 0
	if EvilCrawler.Shared(corpse) then self:FeedHere(CurTime()) else self:StartDrag(CurTime()) end
	return true
end

hook.Add("OnEntityCreated", "EvilCrawlerCarrion", function(ent)
	if ent:GetClass() ~= "prop_ragdoll" then return end
	timer.Simple(0, function()
		if IsValid(ent) and Fleshy(ent) then
			carrion[ent] = true
			ent.EvilCrawlerDiedAt = CurTime()
		end
	end)
end)

hook.Add("EntityRemoved", "EvilCrawlerCarrion", function(ent)
	carrion[ent] = nil
end)

hook.Add("PostPlayerDeath", "EvilCrawlerCarrion", function(ply)
	local rag = ply:GetRagdollEntity()
	if carrion[rag] then rag.EvilCrawlerDiedAt = CurTime() end
end)

for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
	if Fleshy(ent) then
		carrion[ent] = true
		ent.EvilCrawlerDiedAt = ent.EvilCrawlerDiedAt or CurTime()
	end
end

timer.Create("EvilCrawlerReek", 1, 0, function()
	if EvilCrawler.Setting("eat_corpses") == 0 or #ents.FindByClass("evil_crawler") == 0 then return end
	local now = CurTime()
	for rag in pairs(carrion) do
		if Rotting(rag) then
			local pos = rag:GetPos()
			if now >= (rag.EvilCrawlerReekAt or 0) or pos:Distance(rag.EvilCrawlerReekPos) > REEK_MOVED then
				rag.EvilCrawlerReekAt, rag.EvilCrawlerReekPos = now + REEK_REFRESH, pos
				local fresh = now - (rag.EvilCrawlerDiedAt or now) < FRESH_TIME
				EvilCrawler.Scent.Reek(pos, rag, fresh and REEK_FRESH or REEK_STALE)
			end
		end
	end
end)

function ENT:Sate(now)
	self.FedAt = now
	self.SatedUntil = now + EvilCrawler.Setting("sated_time") / (1 + ANGER_HUNGER * (self.Anger or 0)) / self:Wits()
end

function ENT:Strike(npc)
	local now = CurTime()
	if not IsValid(npc) or not EvilCrawler.Living(npc) or Victim.Shrugs(npc, self) then
		self:Release()
		return
	end
	local center = npc:WorldSpaceCenter()
	local dir = (center - self:GetPos()):GetNormalized()

	if npc.DropWeapon and IsValid(npc:GetActiveWeapon()) then npc:DropWeapon() end

	local corpse = Victim.Grab(npc, self)
	if not IsValid(corpse) then
		self:Release()
		self:Skewer(npc, now)
		return
	end
	sound.Play(GRAB_SOUNDS[math.random(#GRAB_SOUNDS)], center, 75, math.random(80, 95))

	self:SetVictim(corpse)
	self.CarryDir = dir
	self.Eaten = 0
	self:StartDrag(now)
end

function ENT:Skewer(npc, now)
	local center = npc:WorldSpaceCenter()
	if EvilCrawler.Integrating() then
		self:SetTaken(self:GetTaken() + #PARTS)
		sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], center, 75, math.random(45, 55))
		hook.Run("OnNPCKilled", npc, self, self)
		npc:Remove()
		self:Sate(now)
		return
	end
	local fx = EffectData()
	fx:SetOrigin(center)
	fx:SetNormal(self.BodyUp)
	fx:SetScale(10)
	fx:SetColor(BLOOD_COLOR_RED)
	fx:SetFlags(7)
	util.Effect("bloodspray", fx)
	util.Effect("BloodImpact", fx)
	sound.Play(RIP_SOUNDS[math.random(#RIP_SOUNDS)], center, 80, math.random(85, 100))
	sound.Play(CRUNCH_SOUNDS[math.random(#CRUNCH_SOUNDS)], center, 75, math.random(80, 95))

	local dmg = DamageInfo()
	dmg:SetDamage(math.max(npc:Health(), 1) * 10 + 1000)
	dmg:SetDamageType(DMG_SLASH)
	dmg:SetAttacker(self)
	dmg:SetInflictor(self)
	dmg:SetDamagePosition(center)
	npc:TakeDamageInfo(dmg)
	if IsValid(npc) and EvilCrawler.Living(npc) then
		Victim.Shrug(npc)
		return
	end
	self:Spit(BONES[1])
	self:Sate(now)
end

function ENT:Seize(ply, now)
	if not ply:Alive() or ply:HasGodMode() or EvilCrawler.Noclipping(ply) then
		self:Release()
		return
	end
	if ply:InVehicle() then Victim.Yank(ply, self:GetPos()) end
	sound.Play(GRAB_SOUNDS[math.random(#GRAB_SOUNDS)], Proxy(ply):WorldSpaceCenter(), 75, math.random(80, 95))

	local rag = EvilCrawler.Fake(ply)
	self.SeizedAt = rag and Chest(rag):GetPos() or ply:GetPos()
	self.NextNip = now + math.Rand(NIP_TIME[1], NIP_TIME[2])
	self.CarryDir = (Proxy(ply):WorldSpaceCenter() - self:GetPos()):GetNormalized()
	ply.EvilCrawlerFree = 0
	ply:SetNW2Float(FREE_VAR, 0)
	ply:SetNW2Entity(HELD_VAR, self)
	if not rag then ply:SetMoveType(MOVETYPE_NONE) end
	ply:ViewPunch(Angle(-12, math.Rand(-8, 8), math.Rand(-10, 10)))
	EvilCrawler.Scent.Frighten(self.SeizedAt, 600, 20)

	self:SetAct(ACT_GRAPPLE)
	self:SetActStart(now)
	self:SetState("grapple")
end

function ENT:LetGo(ply)
	if EvilCrawler.Holder(ply) ~= self then return end
	ply:SetNW2Entity(HELD_VAR, NULL)
	if not EvilCrawler.Fake(ply) then ply:SetMoveType(MOVETYPE_WALK) end
end

function ENT:Knows(trick)
	return self.Know and self.Know[trick] or 0
end

function ENT:Learn(ply)
	local skills = IsValid(ply) and Souls:Digest(ply)
	if not skills then return end
	self.Know = self.Know or {}
	for trick, k in pairs(skills) do self.Know[trick] = math.min(KNOW_MAX, (self.Know[trick] or 0) + k) end
	return skills
end

function ENT:Meal(corpse)
	corpse.EvilCrawlerMeals = corpse.EvilCrawlerMeals or {}
	local v = corpse.EvilCrawlerMeals[self]
	if v then return v end
	local st = self.EvilStomach
	if corpse.EvilCrawlerWho then
		v = st:Add(table.Copy(corpse.EvilCrawlerWho))
	else
		v = st:Eat(corpse, { kind = "corpse" })
	end
	v.parts = 0
	corpse.EvilCrawlerMeals[self] = v
	return v
end

function ENT:Finish(corpse, v)
	if v.digested then return end
	v.tricks = self:Learn(corpse.EvilCrawlerPlayer)
	self.EvilStomach:Settle(v)
end

function ENT:EvilStomachProgress()
	local out = {}
	for _, v in ipairs(self.EvilStomach.victims) do
		if not v.digested then out[#out + 1] = { v.n, v.parts / #PARTS } end
	end
	return out
end

function ENT:EvilStomachSummary()
	return { gorged = self:GetGorged(), know = self.Know }
end

function ENT:GripOn(ply)
	local recent = CurTime() - (ply.EvilCrawlerEscapedAt or -math.huge) < ESCAPE_MEMORY
	local tighten = 1 + EvilCrawler.Setting("escape_tighten") * (recent and ply.EvilCrawlerEscapes or 0)
	return SLIP * self:Wits() * tighten * (1 + KNOW_GRIP * self:Knows("slip"))
end

function ENT:Grapple(ply, now)
	if not ply:Alive() or ply:HasGodMode() or ply:GetObserverMode() ~= OBS_MODE_NONE then
		self:Release()
		return
	end
	local span = EvilCrawler.StruggleTime()
	local t = now - self:GetActStart()
	if t >= span then
		self:Overpower(ply, now)
		return
	end

	local from = self.SeizedAt
	local want = from + (self:GetPos() - from) * (REEL * Smooth(t / span)) + vector_up * (LIFT * math.min(1, t * 4))
	local rag = EvilCrawler.Fake(ply)
	if rag then
		local chest = Chest(rag)
		chest:SetVelocity((want - chest:GetPos()) * 8)
	else
		local mins, maxs = ply:GetHull()
		local tr = util.TraceHull({
			start = ply:GetPos(), endpos = want, mins = mins, maxs = maxs, mask = MASK_PLAYERSOLID, filter = { ply, self },
		})
		if not tr.StartSolid then ply:SetPos(tr.HitPos) end
	end

	ply.EvilCrawlerFree = math.max(0, ply.EvilCrawlerFree - FrameTime() * self:GripOn(ply))
	ply:SetNW2Float(FREE_VAR, ply.EvilCrawlerFree)

	if now >= self.NextNip then
		self.NextNip = now + math.Rand(NIP_TIME[1], NIP_TIME[2])
		ply:TakeDamage(NIP_DAMAGE, self, self)
		ply:ViewPunch(Angle(math.Rand(2, 5), math.Rand(-3, 3), math.Rand(-4, 4)))
		sound.Play(NIP_SOUNDS[math.random(#NIP_SOUNDS)], ply:WorldSpaceCenter(), 60, math.random(130, 160), 0.5)
	end
end

function ENT:Struggled(ply)
	if self:GetAct() ~= ACT_GRAPPLE or self:GetVictim() ~= ply then return end
	local now = CurTime()
	local credit = math.min(PRESS_BURST, (ply.EvilCrawlerCredit or PRESS_BURST) + (now - (ply.EvilCrawlerPressAt or now)) * PRESS_RATE)
	ply.EvilCrawlerPressAt = now
	ply.EvilCrawlerCredit = math.max(0, credit - 1)
	if credit < 1 then return end

	ply.EvilCrawlerFree = ply.EvilCrawlerFree + PRESS_GAIN
	ply:ViewPunch(Angle(math.Rand(-3, 3), math.Rand(-3, 3), math.Rand(-5, 5)))
	if ply.EvilCrawlerFree >= 1 then
		self:BrokeFree(ply, now)
		return
	end
	ply:SetNW2Float(FREE_VAR, ply.EvilCrawlerFree)
	if math.random() < 0.35 then
		sound.Play(GRAB_SOUNDS[math.random(#GRAB_SOUNDS)], ply:WorldSpaceCenter(), 60, math.random(100, 120), 0.5)
	end
end

function ENT:BrokeFree(ply, now)
	self:Release()
	ply:SetNW2Float(FREE_VAR, 0)
	local recent = now - (ply.EvilCrawlerEscapedAt or -math.huge) < ESCAPE_MEMORY
	ply.EvilCrawlerEscapes = (recent and ply.EvilCrawlerEscapes or 0) + 1
	ply.EvilCrawlerEscapedAt = now
	Souls:Watch(ply, "slip")
	Evil.Scare(ply, SPOOKED)

	local away = ply:WorldSpaceCenter() - self:GetPos()
	away.z = 0
	away = away:LengthSqr() > 1 and away:GetNormalized() or self.Facing
	local push = away * THROWN[1] + vector_up * THROWN[2]
	local rag = EvilCrawler.Fake(ply)
	if rag then
		for i = 0, rag:GetPhysicsObjectCount() - 1 do rag:GetPhysicsObjectNum(i):AddVelocity(push) end
	else
		ply:SetVelocity(push)
	end
	ply:ViewPunch(Angle(-15, 0, math.Rand(-10, 10)))
	self:Stun(ply, now)
end

function ENT:Stun(by, now)
	self:SetAct(ACT_STUN)
	self:SetActStart(now)
	self:SetState("stunned")
	self.StunUntil = now + EvilCrawler.STUN_TIME
	self.LetGoUntil = now + 0.3
	self.Vel = (self:GetPos() - by:WorldSpaceCenter()):GetNormalized() * STUN_KNOCK
	self.Goal = nil
	self:EmitSound(STUN_SOUNDS[math.random(#STUN_SOUNDS)], 90, math.random(160, 185))
	sound.Play(STUN_CRACK, self:GetPos(), 75, math.random(70, 85))
	self:Enrage(by, now)
end

function ENT:Overpower(ply, now)
	self:LetGo(ply)
	ply.EvilCrawlerVictim = nil
	local rag = Victim.Take(ply, self)
	if not IsValid(rag) then
		self:Release()
		local dmg = DamageInfo()
		dmg:SetDamage(math.max(ply:Health(), 1) * 10 + 1000)
		dmg:SetDamageType(DMG_GENERIC)
		dmg:SetAttacker(self)
		dmg:SetInflictor(self)
		dmg:SetDamagePosition(ply:WorldSpaceCenter())
		ply:TakeDamageInfo(dmg)
		return
	end
	sound.Play(GRAB_SOUNDS[math.random(#GRAB_SOUNDS)], rag:GetPos(), 75, math.random(70, 85))
	self:SetVictim(rag)
	self.Eaten = 0
	self:StartDrag(now)
end

function ENT:FeedHere(now)
	self:GetVictim().EvilCrawlerVictim = self
	self.Lair = self:GetPos()
	self:SetAct(ACT_FEED)
	self:SetActStart(now)
	self:SetState("feed")
	self.BiteStage = nil
	self.BitePart = nil
	self.FeedUntil = now + PULL_TIME + (Partless(self:GetVictim()) and TORSO_TIME or FEED_CAP)
end

function ENT:StartDrag(now)
	if self:Piloted() then
		self:FeedHere(now)
		return
	end
	self:GetVictim().EvilCrawlerVictim = self
	self:SetAct(ACT_DRAG)
	self:SetActStart(now)
	self:SetState("drag")
	self.Lair = self:FindLair()
	self.ActDeadline = now + DRAG_TIME
	self.BiteStage = nil
	self.BitePart = nil
end

local function NearestPlayer(spot)
	local nearest = math.huge
	if EvilCrawler.IgnoresPlayers() then return nearest end
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE then nearest = math.min(nearest, Proxy(ply):GetPos():Distance(spot)) end
	end
	return nearest
end

function ENT:FindLair(threat)
	local pos = self:GetPos()
	local best, bestScore = pos, -math.huge
	for _ = 1, LAIR_TRIES do
		local dir = VectorRand()
		dir.z = dir.z * 0.3
		dir:Normalize()
		local tr = self:Trace(pos, pos + dir * math.Rand(LAIR_RANGE[1], LAIR_RANGE[2]))
		local spot = tr.HitPos - dir * 32

		local score = math.min(NearestPlayer(spot), 3000)
		if threat then
			score = score + math.min(threat:Distance(spot), 3000)
			if self:Trace(threat, spot).Hit then score = score + OUT_OF_SIGHT end
		end
		if self:Trace(spot, spot + Vector(0, 0, 400)).Hit then score = score + 600 end
		for _, side in ipairs(SIDES) do
			if self:Trace(spot, spot + side * 200).Hit then score = score + 150 end
		end
		if score > bestScore then best, bestScore = spot, score end
	end
	return best
end

function ENT:Disturbed()
	if EvilCrawler.IgnoresPlayers() then return false end
	local pos = self:GetPos()
	for _, ply in ipairs(player.GetAll()) do
		if ply:Alive() and ply:GetObserverMode() == OBS_MODE_NONE
			and Proxy(ply):WorldSpaceCenter():Distance(pos) < DISTURB_RANGE then
			return true
		end
	end
	return false
end

function ENT:Pull(now)
	if self:GetAct() ~= ACT_FEED then return 0 end
	local t = now - self:GetActStart()
	return math.Clamp((t + 0.06 * math.sin(t * 12)) / PULL_TIME, 0, 1)
end

function ENT:HoldPoint(now, dt)
	local pos, up, h = self:GetPos(), self.BodyUp, self.BodyHeight
	local dir = self.CarryDir or -self.Facing
	local speed = self.Vel:Length()
	if speed > 20 then
		local rate = TRAIL_RATE * math.max(1, speed / TRAIL_SPEED)
		dir = LerpVector(1 - math.exp(-dt * rate), dir, -self.Facing)
	end
	dir = dir - up * dir:Dot(up)
	if dir:LengthSqr() < 1e-4 then dir = -self.Facing end
	dir:Normalize()
	self.CarryDir = dir

	local carry = pos - up * (h * 0.6) + dir * (h * 1.1)
	local t = now - self:GetActStart() - PULL_TIME
	local mouth = pos
	if EvilCrawler.Setting("abdomen") > 0 then mouth = pos - up * (math.min(h, self.Room) * EvilCrawler.BELLY.tall) end
	if self:GetAct() == ACT_FEED and t > 0 then
		mouth = mouth + up * ((EvilCrawler.Integrating() and HEAVE_DEPTH or GULP_DEPTH) * math.max(0, math.sin(t * GULP_RATE * math.pi * 2)) ^ 2)
	end
	return LerpVector(Smooth(self:Pull(now)), carry, mouth)
end

local function BitePhys(corpse, name)
	local bone = corpse:LookupBone(name)
	local index = bone and corpse:TranslateBoneToPhysBone(bone) or -1
	if index < 0 then index = math.random(0, corpse:GetPhysicsObjectCount() - 1) end
	local phys = corpse:GetPhysicsObjectNum(index)
	return IsValid(phys) and phys
end

function ENT:Held(corpse)
	local part = CurrentPart(corpse)
	if not part or (part == 1 and self:GetAct() ~= ACT_FEED) then return { Chest(corpse) } end
	local held = {}
	for _, name in ipairs(PARTS[part].grip) do
		local phys = BitePhys(corpse, name)
		if phys then held[#held + 1] = phys end
	end
	return held
end

function ENT:HoldCorpse(corpse, hold, stiffness, grip)
	local held = self:Held(corpse)
	local side = self.BodyUp:Cross(self.Facing)
	self.HoldLag = 0
	for i, phys in ipairs(held) do
		if IsValid(phys) then
			local at = hold + side * ((i - (#held + 1) / 2) * 7)
			local p = phys:GetPos()
			self.HoldLag = math.max(self.HoldLag, p:Distance(at))
			if p:Distance(at) > 600 then
				self:Release()
				return
			end
			phys:SetVelocity(LerpVector(0.5 * grip, phys:GetVelocity(), (at - p) * stiffness + self.Vel))
		end
	end

	local now = CurTime()
	local first = held[1]
	if self.HoldLag > SNAG_LAG or IsValid(first) and self:Trace(self:GetPos(), first:GetPos()).Hit then
		self.SnaggedSince = self.SnaggedSince or now
		if now - self.SnaggedSince > SNAG_TIME then self:Release() end
	else
		self.SnaggedSince = nil
	end
end

function ENT:Stab(phys)
	local p, up = phys:GetPos(), self.BodyUp
	phys:ApplyForceCenter(-up * phys:GetMass() * STAB_FORCE)

	local fx = EffectData()
	fx:SetOrigin(p)
	fx:SetNormal(up)
	util.Effect("BloodImpact", fx)
	util.Decal("Blood", p + up * 24, p - up * 24, self)
	sound.Play(STAB_SOUNDS[math.random(#STAB_SOUNDS)], p, 70, math.random(80, 100), 0.8)
	if math.random() < 0.5 then
		sound.Play(CRUNCH_SOUNDS[math.random(#CRUNCH_SOUNDS)], p, 65, math.random(85, 110), 0.6)
	end
end

function ENT:Rip(phys, corpse)
	local p, up = phys:GetPos(), self.BodyUp
	local dir = (up + VectorRand() * 0.5):GetNormalized()
	phys:ApplyForceCenter(dir * phys:GetMass() * RIP_FORCE)

	local fx = EffectData()
	fx:SetOrigin(p)
	fx:SetNormal(dir)
	fx:SetScale(6)
	fx:SetColor(BLOOD_COLOR_RED)
	fx:SetFlags(3)
	util.Effect("bloodspray", fx)
	util.Effect("BloodImpact", fx)
	util.Decal("Blood", p, p - up * 200 + VectorRand() * 40, corpse)
	sound.Play(RIP_SOUNDS[math.random(#RIP_SOUNDS)], p, 72, math.random(85, 110), 0.8)

	Victim.Wound(corpse, self, p)
	self.Eaten = (self.Eaten or 0) + 1
	local k = math.min(1, self.Eaten / DRAINED)
	corpse:SetColor(Color(255 - 150 * k, 255 - 205 * k, 255 - 205 * k))

	timer.Simple(EvilCrawler.LUMP_TIME, function()
		if IsValid(self) then
			sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], self:GetPos(), 60, math.random(70, 90), 0.6)
		end
	end)
end

function ENT:Knead(phys)
	phys:ApplyForceCenter(-self.BodyUp * phys:GetMass() * STAB_FORCE * 0.4)
end

function ENT:Suck(phys, corpse)
	local p = phys:GetPos()
	phys:ApplyForceCenter((self:GetPos() - p):GetNormalized() * phys:GetMass() * RIP_FORCE * 0.5)

	Victim.Wound(corpse, self, p)
	self.Eaten = (self.Eaten or 0) + 1
	local k = math.min(1, self.Eaten / DRAINED)
	corpse:SetColor(Color(255 - 165 * k, 255 - 190 * k, 255 - 175 * k))
end

local function Shrink(corpse, bones)
	if not IsValid(corpse) then return end
	for _, bone in ipairs(bones) do corpse:ManipulateBoneScale(bone, Vector(0, 0, 0)) end
end

local function Strip(corpse, part, delay)
	local bones = EvilCrawler.PartBones(corpse, part)
	if delay then timer.Simple(delay, function() Shrink(corpse, bones) end) else Shrink(corpse, bones) end
	for _, bone in ipairs(bones) do
		local index = corpse:TranslateBoneToPhysBone(bone)
		if index >= 0 and corpse:TranslatePhysBoneToBone(index) == bone then
			local phys = corpse:GetPhysicsObjectNum(index)
			if IsValid(phys) then phys:EnableCollisions(false) end
		end
	end
end

function ENT:Consume(corpse, part, now)
	local p = self:GetPos()
	Strip(corpse, part, EvilCrawler.Integrating() and EvilCrawler.SLURP_TIME)
	self:SetGorged(self:GetGorged() + 1)
	if EvilCrawler.Integrating() then
		self:TakeIn(corpse, part, now)
		return
	end
	corpse:SetNW2Int(EvilCrawler.EATEN_VAR, bit.bor(corpse:GetNW2Int(EvilCrawler.EATEN_VAR, 0), bit.lshift(1, part - 1)))

	local fx = EffectData()
	fx:SetOrigin(p)
	fx:SetNormal(self.BodyUp)
	fx:SetScale(10)
	fx:SetColor(BLOOD_COLOR_RED)
	fx:SetFlags(7)
	util.Effect("bloodspray", fx)
	for _ = 1, 3 do util.Decal("Blood", p, p - self.BodyUp * 200 + VectorRand() * 80, corpse) end
	sound.Play(CONSUME_SOUNDS[math.random(#CONSUME_SOUNDS)], p, 80, math.random(85, 100))
	timer.Simple(0.6, function()
		if IsValid(self) then
			sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], self:GetPos(), 70, math.random(55, 70))
		end
	end)

	self:Swallowed(corpse, part, now)
	self:Spit(BONES[part])
end

function ENT:Swallowed(corpse, part, now)
	local v = self:Meal(corpse)
	v.parts = math.min(v.parts + 1, #PARTS)
	if not CurrentPart(corpse) then
		v.parts = #PARTS
		self:Finish(corpse, v)
		self.Devoured = true
		self.FeedUntil = math.min(self.FeedUntil, now + FINISH_TIME)
	end
	Victim.Maimed(corpse, PARTS[part].grip[1], self)
	hook.Run("EvilCrawlerAte", self, corpse, part)
end

function ENT:Gulp(corpse)
	local p = self:GetPos()
	local v = self:Meal(corpse)
	v.parts = #PARTS
	self:Finish(corpse, v)
	self.Devoured = true
	self:SetGorged(self:GetGorged() + #PARTS)
	if EvilCrawler.Integrating() then
		self:SetTaken(self:GetTaken() + #PARTS)
		sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], p, 75, math.random(40, 50))
		return
	end
	local fx = EffectData()
	fx:SetOrigin(corpse:WorldSpaceCenter())
	fx:SetNormal(self.BodyUp)
	fx:SetScale(10)
	fx:SetColor(BLOOD_COLOR_RED)
	fx:SetFlags(7)
	util.Effect("bloodspray", fx)
	for _ = 1, 3 do util.Decal("Blood", p, p - self.BodyUp * 200 + VectorRand() * 80, corpse) end
	sound.Play(CONSUME_SOUNDS[math.random(#CONSUME_SOUNDS)], p, 80, math.random(75, 90))
	timer.Simple(0.6, function()
		if IsValid(self) then
			sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], self:GetPos(), 75, math.random(45, 60))
		end
	end)
end

function ENT:TakeIn(corpse, part, now)
	self:SetTaken(self:GetTaken() + 1)
	corpse:SetNW2Bool(EvilCrawler.WHOLE_VAR, true)
	corpse:SetNW2Int(EvilCrawler.EATEN_VAR, bit.bor(corpse:GetNW2Int(EvilCrawler.EATEN_VAR, 0), bit.lshift(1, part - 1)))
	sound.Play(GULP_SOUNDS[math.random(#GULP_SOUNDS)], self:GetPos(), 75, math.random(45, 55))

	local voice = corpse.EvilCrawlerVoice
	if voice and not corpse.EvilCrawlerInside then
		corpse.EvilCrawlerInside = true
		self.Voices = self.Voices or {}
		table.insert(self.Voices, { lines = voice, pitch = corpse.EvilCrawlerPitch })
		if #self.Voices > MAX_VOICES then table.remove(self.Voices, 1) end
	end
	self:Swallowed(corpse, part, now)
	self:KeepInside(corpse.EvilCrawlerPlayer)
end

function ENT:Murmur(now)
	local voices = self.Voices
	if not voices or not voices[1] or EvilCrawler.Setting("victim_voices") == 0 then return end
	self.NextMurmur = self.NextMurmur or now + math.Rand(MURMUR_GAP[1], MURMUR_GAP[2])
	if now < self.NextMurmur or self:GetAct() ~= ACT_NONE then return end
	self.NextMurmur = now + math.Rand(MURMUR_GAP[1], MURMUR_GAP[2])
	local v = voices[math.random(#voices)]
	local lines = IsValid(self:GetPrey()) and v.lines.help or v.lines.die
	self:EmitSound(lines[math.random(#lines)], 68, (v.pitch or 100) - 8, 0.6, CHAN_VOICE, 0, MUFFLED)
end

function ENT:Piloted()
	local ply = self:GetPilot()
	if IsValid(ply) and not ply:Alive() and EvilCrawler.Inside(ply) == self then return ply end
end

function ENT:KeepInside(ply)
	if not IsValid(ply) or ply:Alive() or EvilCrawler.Setting("pilot") == 0 or EvilCrawler.Inside(ply) then return end
	ply:SetNW2Entity(INSIDE_VAR, self)
end

function ENT:Board(ply)
	if not IsValid(ply) or EvilCrawler.Inside(ply) ~= self then return end
	if self:Piloted() then
		self:LetGoOf(ply)
		return
	end
	self:SetPilot(ply)
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(self)
end

function ENT:LetGoOf(ply)
	if not IsValid(ply) or EvilCrawler.Inside(ply) ~= self then return end
	ply:SetNW2Entity(INSIDE_VAR, NULL)
	ply.EvilCrawlerDrive = nil
	if self:GetPilot() == ply then self:SetPilot(NULL) end
end

function ENT:LetOut(ply)
	self:LetGoOf(ply)
	if ply:Alive() then return end
	ply:UnSpectate()
	ply:Spawn()
end

function ENT:Empty()
	for _, ply in ipairs(player.GetAll()) do self:LetGoOf(ply) end
end

local function Takeable(ply)
	return not EvilCrawler.IgnoresPlayers() and ply:Alive() and not ply:HasGodMode() and not ply.EvilCrawlerVictim
		and not EvilCrawler.Held(ply) and ply:LookupBone("ValveBiped.Bip01_Spine2") ~= nil
end

function ENT:Catchable(ent, pilot)
	if ent == pilot or ent == self then return false end
	if ent:IsPlayer() then return Takeable(ent) end
	return self:IsEdible(ent)
end

function ENT:PilotStrike(pilot, aim)
	local now = CurTime()
	if now < (self.NextPilotStrike or 0) or self:GetAct() ~= ACT_NONE then return end
	self.NextPilotStrike = now + PILOT_STRIKE_GAP
	local pos, up = self:GetPos(), self.BodyUp
	local reach = ATTACK_REACH * self.Scale
	local best, bestDot = nil, PILOT_AIM
	for _, ent in ipairs(ents.FindInSphere(pos, reach)) do
		if self:Catchable(ent, pilot) then
			local d = (Proxy(ent):WorldSpaceCenter() - pos):GetNormalized():Dot(aim)
			if d > bestDot and self:Clear(pos, ent) then best, bestDot = ent, d end
		end
	end
	if best then
		self:StartStrike(best)
		return
	end

	local dir = aim - up * aim:Dot(up)
	if dir:LengthSqr() < 0.01 then dir = self.Facing end
	dir:Normalize()
	self.Jabbing = self:Trace(pos, pos + dir * reach - up * (self.BodyHeight * 0.4)).HitPos
	self.Lunged = false
	self:SetStabAt(self.Jabbing)
	self:SetPrey(NULL)
	self:SetVictim(NULL)
	self:SetAct(ACT_STRIKE)
	self:SetActStart(now)
end

function ENT:JabHit(from, to)
	local pilot = self:Piloted()
	local r = JAB_RADIUS * self.Scale
	local best, bestDist
	for _, ent in ipairs(ents.FindInSphere((from + to) * 0.5, from:Distance(to) * 0.5 + r * 2)) do
		local corpse = carrion[ent] and EvilCrawler.Setting("eat_corpses") > 0 and self:IsCarrion(ent)
		if corpse or self:Catchable(ent, pilot) then
			local d = util.DistanceToLine(from, to, corpse and self:Heart(ent) or Proxy(ent):WorldSpaceCenter())
			if d < r and (not best or d < bestDist) and self:Clear(from, ent) then best, bestDist = ent, d end
		end
	end
	return best
end

function ENT:Jabbed(now)
	local t = now - self:GetActStart()
	if not self.Lunged and t >= EvilCrawler.STRIKE_WINDUP then
		self.Lunged = true
		sound.Play(LUNGE_SOUND, self:GetPos(), 62, math.random(70, 90), 0.4)
	end
	if t < IMPACT_TIME then return end
	local hit = self:JabHit(self:GetPos(), self.Jabbing)
	self:Release()
	if not hit then return end
	if carrion[hit] then
		self:Scavenge(hit)
		return
	end
	hit.EvilCrawlerVictim = self
	self:SetVictim(hit)
	self:SetAct(ACT_STRIKE)
	if hit:IsPlayer() then self:Seize(hit, now) else self:Strike(hit) end
end

hook.Add("StartCommand", "EvilCrawlerPilot", function(ply, cmd)
	local crawler = EvilCrawler.Inside(ply)
	if not crawler then
		ply.EvilCrawlerLetGo = nil
		return
	end
	local now = CurTime()
	if cmd:KeyDown(IN_USE) then
		ply.EvilCrawlerLetGo = ply.EvilCrawlerLetGo or now
		if now - ply.EvilCrawlerLetGo >= EvilCrawler.LET_GO_TIME then crawler:LetOut(ply) end
	else
		ply.EvilCrawlerLetGo = nil
	end
	ply.EvilCrawlerDrive = { fwd = cmd:GetForwardMove(), side = cmd:GetSideMove(), ang = cmd:GetViewAngles(), buttons = cmd:GetButtons() }
	cmd:ClearButtons()
end)

util.AddNetworkString("EvilCrawlerLetGo")

net.Receive("EvilCrawlerLetGo", function(_, ply)
	local crawler = EvilCrawler.Inside(ply)
	if crawler then crawler:LetOut(ply) end
end)

hook.Add("PlayerDeathThink", "EvilCrawlerPilot", function(ply)
	if EvilCrawler.Inside(ply) then return false end
end)

hook.Add("PlayerSpawn", "EvilCrawlerPilot", function(ply)
	local crawler = EvilCrawler.Inside(ply)
	if crawler then crawler:LetGoOf(ply) end
end)

function ENT:Spit(models)
	if not models then return end
	timer.Simple(math.Rand(SPIT_DELAY[1], SPIT_DELAY[2]), function()
		if not IsValid(self) then return end
		local pos, up = self:GetPos(), self.BodyUp
		sound.Play(SPIT_SOUNDS[math.random(#SPIT_SOUNDS)], pos, 70, math.random(80, 100), 0.8)
		for _, model in ipairs(models) do
			local bone = ents.Create("prop_physics")
			bone:SetModel(model)
			bone:SetPos(pos + VectorRand() * 4)
			bone:SetAngles(AngleRand())
			bone:Spawn()
			bone:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
			local phys = bone:GetPhysicsObject()
			if IsValid(phys) then
				phys:SetVelocity((up + VectorRand() * 0.6):GetNormalized() * math.Rand(SPIT_SPEED[1], SPIT_SPEED[2]))
				phys:AddAngleVelocity(VectorRand() * 600)
			end
			spat[#spat + 1] = bone
			if #spat > MAX_BONES then SafeRemoveEntity(table.remove(spat, 1)) end
		end
	end)
end

function ENT:Feed(corpse, now)
	local t = now - self:GetActStart() - PULL_TIME
	if t < 0 then return end

	local seed = self:GetSeed()
	local whole = EvilCrawler.Integrating()
	self.BiteStage = self.BiteStage or {}
	self.BitePart = self.BitePart or {}
	for k = 1, FEEDERS do
		local n, u = BiteCycle(k, t)
		local stage = n * 3 + (u < BITE_IN and 0 or u < BITE_RIP and 1 or 2)
		local last = self.BiteStage[k]
		self.BiteStage[k] = stage
		if last and stage ~= last and stage % 3 ~= 0 then
			if stage % 3 == 1 then self.BitePart[k] = CurrentPart(corpse) or false end
			local part = self.BitePart[k] or nil
			local phys = BitePhys(corpse, BiteBone(seed, k, n, part))
			if phys then
				if stage % 3 == 1 then
					if whole then self:Knead(phys) else self:Stab(phys) end
					Victim.Pierced(corpse)
				else
					if whole then self:Suck(phys, corpse) else self:Rip(phys, corpse) end
					if part and part == CurrentPart(corpse) then
						corpse.EvilCrawlerRips = (corpse.EvilCrawlerRips or 0) + 1
						if corpse.EvilCrawlerRips >= math.max(2, math.ceil(PARTS[part].rips / self:Wits())) then
							corpse.EvilCrawlerRips = 0
							self:Consume(corpse, part, now)
						end
					end
				end
			end
		end
	end

	local chest = Chest(corpse)
	if IsValid(chest) then
		local want = chest:WorldToLocalVector(self.BodyUp) * (TURN_SPEED * math.sin(t * 0.35 + seed % 7))
		chest:AddAngleVelocity((want - chest:GetAngleVelocity()) * 0.05)
	end
end

function ENT:PonderAct(now)
	local act = self:GetAct()
	if not self:Awake() then
		self.Goal = nil
		return
	end
	if self.Jabbing then
		self.Goal = nil
		return
	end
	if self:Mercy() then
		self.Goal = nil
		return
	end
	if act ~= ACT_STUN and not IsValid(self:GetVictim()) then
		self:Release()
		return
	end
	if act == ACT_STRIKE then
		self.Goal, self.Pace = Proxy(self:GetVictim()):GetPos(), 1
	elseif act == ACT_GRAPPLE or act == ACT_SEAR then
		self.Goal = nil
	elseif act == ACT_STUN then
		self.Goal = nil
		if now >= self.StunUntil then self:Release() end
	elseif act == ACT_DRAG then
		self.Goal = self.Lair
		local there = self:Reached(self.Lair) or now > self.ActDeadline
		if there and Victim.Fighting(self:GetVictim()) then
			self.Goal = nil
			if self:Disturbed() then self:StartDrag(now) end
		elseif there then
			self:SetAct(ACT_FEED)
			self:SetActStart(now)
			self:SetState("feed")
			self.FeedUntil = now + PULL_TIME + FEED_CAP
			if not CurrentPart(self:GetVictim()) then
				self.FeedUntil = now + PULL_TIME + TORSO_TIME
			end
		end
	elseif act == ACT_FEED then
		self.Goal = nil
		local victim = self:GetVictim()
		local shared = EvilCrawler.Shared(victim)
		if not self.Devoured and not shared and not self:Piloted() and self:Disturbed() then
			self:StartDrag(now)
		elseif now > self.FeedUntil then
			if Victim.Alive(victim) then Victim.Kill(victim, self) end
			if not self.Devoured and Partless(victim) then self:Gulp(victim) end
			if self.Devoured and not shared then
				self:Board(victim.EvilCrawlerPlayer)
				victim:Remove()
			end
			self:Sate(now)
			self:Release()
		end
	end
end

function ENT:UpdateAct(now)
	local act = self:GetAct()
	if act == EvilCrawler.ACT_OUT and now >= self.OutUntil then self:Wake(now) end
	if act == ACT_NONE or act == ACT_STUN or not self:Awake() then return end

	if self.Jabbing then
		self:Jabbed(now)
		return
	end
	local victim = self:GetVictim()
	if not IsValid(victim) then
		self:Release()
		return
	end
	if self:Mercy() then return end

	if act == ACT_STRIKE then
		if not EvilCrawler.Living(victim) then
			self:Release()
			return
		end
		local t = now - self:GetActStart()
		if not self.Lunged and t >= EvilCrawler.STRIKE_WINDUP then
			self.Lunged = true
			sound.Play(LUNGE_SOUND, self:GetPos(), 75, math.random(60, 75))
		end
		if t >= IMPACT_TIME then
			local center = Proxy(victim):WorldSpaceCenter()
			local reach = MISS_REACH * self.Scale * (1 + KNOW_REACH * self:Knows("dodge"))
			if center:Distance(self:GetPos()) >= reach or not self:Reachable(victim) then
				if victim:IsPlayer() then Souls:Watch(victim, "dodge") end
				self:Release()
			elseif victim:IsPlayer() then
				self:Seize(victim, now)
			else
				self:Strike(victim)
			end
		end
	elseif act == ACT_GRAPPLE then
		self:Grapple(victim, now)
	elseif act == ACT_SEAR then
		if now - self:GetActStart() >= EvilCrawler.SEAR_TIME then self:Incinerate(victim) end
	else
		self:HoldCorpse(victim, self:HoldPoint(now, FrameTime()), 8, 1)
		if self:GetAct() == ACT_FEED then self:Feed(victim, now) end
	end
end

function ENT:OnRemove()
	self:Release()
	self:Empty()
	if self.Roar then self.Roar:Stop() end
	if self.Breath then self.Breath:Stop() end
end
