EvilCrawler = EvilCrawler or {}
local Scent = EvilCrawler.Scent or {}
EvilCrawler.Scent = Scent

local DROP_INTERVAL = 0.25
local DROP_SPACING = 48
local LINGER_REFRESH = 3
local TELEPORT = 512
local HALF_LIFE = 45
local MAX_AGE = 240
local BLEED_TIME = 10
local NPC_SLOW, NPC_FAST = 40, 240
local FEAR = 1.5
local FIGHTING = 0.4
local CELL = 128
local DEATH_SPOKES = 8
local DEATH_STEP = 120
local DEATH_REACH = 960
local DEATH_LIFT = Vector(0, 0, 16)
local FRESH = 3

local cv_debug = CreateConVar("evil_crawler_debug_scent", "0", 0, "Draw scent trails (needs developer 1)")

Scent.cells = Scent.cells or {}
Scent.trails = Scent.trails or {}
Scent.active = Scent.active or {}
Scent.npcs = Scent.npcs or {}
Scent.reeks = Scent.reeks or {}

local function Creature(ent)
	return ent:IsNPC() or ent:IsNextBot()
end
EvilCrawler.Creature = Creature

function EvilCrawler.Living(ent)
	return ent:Health() > 0 or ent:IsNextBot() and ent:GetMaxHealth() <= 0
end

local function Own(ent, key)
	local tab = ent:GetTable()
	return tab and tab[key]
end
EvilCrawler.Own = Own

local function Ent(v)
	return IsEntity(v) and IsValid(v) and v
end

function EvilCrawler.Fake(ply)
	return Ent(Own(ply, "FakeRagdoll"))
end

function EvilCrawler.Proxy(ent)
	return EvilCrawler.Fake(ent) or ent
end

function EvilCrawler.Faker(rag)
	local ply = Ent(Own(rag, "ply"))
	return ply and ply:IsPlayer() and EvilCrawler.Fake(ply) == rag and ply
end

function EvilCrawler.Noclipping(ply)
	return ply:GetMoveType() == MOVETYPE_NOCLIP and not ply:InVehicle() and not EvilCrawler.Fake(ply)
end

function EvilCrawler.Held(ent)
	local owner = Evil.Owner(ent)
	if not owner then return false end
	if owner:IsPlayer() and not owner:Alive() or Creature(owner) and not EvilCrawler.Living(owner) then return false end
	local claimed, died = ent.EvilCrawlerClaimed, ent.EvilCrawlerDied
	return not (claimed and died and claimed <= died)
end

local function Key(ix, iy, iz)
	return (ix + 512) * 1048576 + (iy + 512) * 1024 + (iz + 512)
end

local function CellOf(pos)
	return math.floor(pos.x / CELL), math.floor(pos.y / CELL), math.floor(pos.z / CELL)
end

local function Insert(node)
	local key = Key(CellOf(node.pos))
	local cell = Scent.cells[key]
	if not cell then
		cell = {}
		Scent.cells[key] = cell
	end
	cell[node] = true
	node.cell = key
end

local function Remove(node)
	local cell = Scent.cells[node.cell]
	if cell then
		cell[node] = nil
		if next(cell) == nil then Scent.cells[node.cell] = nil end
	end
	node.dead = true
end

local function Air(cloud)
	for _, trail in ipairs(cloud) do
		local node = trail.first
		while node do
			Remove(node)
			node = node.next
		end
		Scent.trails[trail] = nil
	end
end

function Scent.Reek(pos, owner, strength)
	if owner and Scent.reeks[owner] then Air(Scent.reeks[owner]) end
	local now, center, cloud = CurTime(), pos + DEATH_LIFT, {}
	local turn = math.Rand(0, math.pi * 2)
	for i = 1, DEATH_SPOKES do
		local a = turn + i / DEATH_SPOKES * math.pi * 2
		local dir = Vector(math.cos(a), math.sin(a), 0)
		local tr = util.TraceLine({ start = center, endpos = center + dir * DEATH_REACH, mask = MASK_SOLID_BRUSHONLY })
		local trail = { owner = owner, death = true, cloud = cloud }
		for k = math.floor(tr.Fraction * DEATH_REACH / DEATH_STEP), 0, -1 do
			local node = {
				pos = center + dir * (k * DEATH_STEP), time = now, trail = trail, prev = trail.last, npc = false, fear = false,
				strength = strength / (1 + k * DEATH_STEP / DEATH_REACH),
			}
			if trail.last then trail.last.next = node else trail.first = node end
			trail.last = node
			Insert(node)
		end
		Scent.trails[trail] = true
		cloud[#cloud + 1] = trail
	end
	if owner then Scent.reeks[owner] = cloud end
end

function Scent.Intensity(node, now)
	return node.strength * 0.5 ^ ((now - node.time) / HALF_LIFE)
end

local function Afraid(ent)
	return Evil.Afraid(ent)
end

function Scent.Frighten(pos, radius, duration)
	Evil.Frighten(pos, radius, duration)
end

local function Strength(ply, now)
	local s = 1
	if Creature(ply) then
		s = Lerp(math.Clamp(((ply.EvilCrawlerSpeed or 0) - NPC_SLOW) / (NPC_FAST - NPC_SLOW), 0, 1), 0.6, 1.6)
		if ply:IsNPC() and ply:GetNPCState() == NPC_STATE_COMBAT then s = s + FIGHTING end
		if Afraid(ply, now) then s = s + FEAR end
	elseif ply:Crouching() then
		s = 0.35
	elseif ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > ply:GetWalkSpeed() then
		s = 1.6
	elseif ply:KeyDown(IN_WALK) then
		s = 0.6
	end
	if now - (ply.EvilCrawlerHurt or -math.huge) < BLEED_TIME then
		s = s + 1.5
	end
	return s
end

local ai_ignoreplayers = GetConVar("ai_ignoreplayers")

local function LeavesScent(ent)
	if ent:IsFlagSet(FL_NOTARGET) then return false end
	if Creature(ent) then
		return EvilCrawler.Living(ent) and not ent.EvilCrawlerVictim and (ent:IsNextBot() or ent:GetMoveType() == MOVETYPE_STEP)
	end
	local ply = ent
	return ply:Alive()
		and not (ai_ignoreplayers and ai_ignoreplayers:GetBool())
		and not EvilCrawler.Noclipping(ply)
		and ply:GetObserverMode() == OBS_MODE_NONE
end

local function Drop(ply, now)
	local pos = EvilCrawler.Proxy(ply):GetPos()
	local trail = Scent.active[ply]
	local last = trail and trail.last

	if last then
		local moved = pos:Distance(last.pos)
		if moved > TELEPORT then
			trail = nil
		elseif moved < DROP_SPACING and now - last.time < LINGER_REFRESH then
			return
		end
	end

	if not trail then
		trail = { owner = ply }
		Scent.active[ply] = trail
		Scent.trails[trail] = true
	end

	local node = {
		pos = pos, time = now, strength = Strength(ply, now), trail = trail, prev = trail.last,
		npc = Creature(ply), fear = Afraid(ply, now),
	}
	if trail.last then trail.last.next = node else trail.first = node end
	trail.last = node
	Insert(node)
end

local function Prune(now)
	for trail in pairs(Scent.trails) do
		local node = trail.first
		while node and now - node.time > MAX_AGE do
			Remove(node)
			node = node.next
		end
		if node then
			node.prev = nil
			trail.first = node
		else
			Scent.trails[trail] = nil
			if Scent.active[trail.owner] == trail then Scent.active[trail.owner] = nil end
		end
	end
end

function Scent.Strongest(pos, radius, now, weigh, reach)
	local best, bestIntensity = nil, 0
	local r2 = radius * radius
	local x0, y0, z0 = CellOf(pos - Vector(radius, radius, radius))
	local x1, y1, z1 = CellOf(pos + Vector(radius, radius, radius))
	for ix = x0, x1 do
		for iy = y0, y1 do
			for iz = z0, z1 do
				local cell = Scent.cells[Key(ix, iy, iz)]
				if cell then
					for node in pairs(cell) do
						if node.pos:DistToSqr(pos) <= r2 then
							local i = weigh and weigh(node, now) or Scent.Intensity(node, now)
							if i > bestIntensity and (not reach or reach(node)) then best, bestIntensity = node, i end
						end
					end
				end
			end
		end
	end
	return best, bestIntensity
end

local function DrawDebug(now)
	for trail in pairs(Scent.trails) do
		local node = trail.first
		while node do
			local i = math.min(1, Scent.Intensity(node, now))
			local c = node.fear and Color(60, 255 * i, 60) or Color(255 * i, 60, 255 * (1 - i))
			debugoverlay.Cross(node.pos, 4, DROP_INTERVAL + 0.05, c, true)
			if node.next then debugoverlay.Line(node.pos, node.next.pos, DROP_INTERVAL + 0.05, c, true) end
			node = node.next
		end
	end
end

timer.Create("EvilCrawlerScent", DROP_INTERVAL, 0, function()
	local now = CurTime()
	local function visit(ent)
		if Creature(ent) then
			local pos = ent:GetPos()
			ent.EvilCrawlerSpeed = ent.EvilCrawlerLastPos and pos:Distance(ent.EvilCrawlerLastPos) / DROP_INTERVAL or 0
			ent.EvilCrawlerLastPos = pos
		end
		if LeavesScent(ent) then
			Drop(ent, now)
		else
			Scent.active[ent] = nil
		end
	end
	for _, ply in ipairs(player.GetAll()) do visit(ply) end
	for npc in pairs(Scent.npcs) do
		if IsValid(npc) then visit(npc) else Scent.npcs[npc] = nil end
	end
	Prune(now)
	if cv_debug:GetBool() then DrawDebug(now) end
end)

local SHOW_INTERVAL = 0.5
local SHOW_RANGE = 2500
local SHOW_MAX = 600
local GROUND = Vector(0, 0, 72)

util.AddNetworkString("EvilCrawlerScent")

local function Ground(node)
	if node.ground then return end
	local tr = util.TraceLine({ start = node.pos + Vector(0, 0, 8), endpos = node.pos - GROUND, mask = MASK_SOLID_BRUSHONLY })
	node.ground = tr.Hit and tr.HitPos or node.pos
	node.normal = tr.Hit and tr.HitNormal or vector_up
end

local function ShowScent()
	if EvilCrawler.Setting("show_scent") == 0 then return end
	local now = CurTime()
	local heads, followed = {}, {}
	for _, crawler in ipairs(ents.FindByClass("evil_crawler")) do
		local node = crawler.Trail
		if node and not node.dead then
			heads[node] = true
			followed[node.trail] = true
		end
	end

	local r2 = SHOW_RANGE * SHOW_RANGE
	for _, ply in ipairs(player.GetHumans()) do
		local eye = ply:EyePos()
		local budget = SHOW_MAX
		net.Start("EvilCrawlerScent")
		for trail in pairs(Scent.trails) do
			local near, last = {}, nil
			local node = trail.first
			while node and budget > 0 do
				if not node.dead and node.pos:DistToSqr(eye) < r2 then
					Ground(node)
					near[#near + 1] = { node = node, linked = last ~= nil and node.prev == last }
					last = node
					budget = budget - 1
				end
				node = node.next
			end
			if #near > 0 then
				net.WriteBool(true)
				net.WriteBool(near[1].node.npc)
				net.WriteBool(followed[trail] or false)
				net.WriteUInt(#near, 12)
				for _, n in ipairs(near) do
					net.WriteVector(n.node.ground)
					net.WriteNormal(n.node.normal)
					net.WriteUInt(math.Clamp(math.floor(Scent.Intensity(n.node, now) * 255), 0, 255), 8)
					net.WriteBool(n.node.fear)
					net.WriteBool(heads[n.node] or false)
					net.WriteBool(n.linked)
				end
			end
		end
		net.WriteBool(false)
		net.Send(ply)
	end
end
timer.Create("EvilCrawlerShowScent", SHOW_INTERVAL, 0, ShowScent)

hook.Add("EntityTakeDamage", "EvilCrawlerScent", function(ent)
	if ent:IsPlayer() or Creature(ent) then ent.EvilCrawlerHurt = CurTime() end
end)

hook.Add("OnEntityCreated", "EvilCrawlerScent", function(ent)
	if not Creature(ent) then return end
	timer.Simple(0, function()
		if IsValid(ent) and Creature(ent) then Scent.npcs[ent] = true end
	end)
end)

hook.Add("EntityRemoved", "EvilCrawlerScent", function(ent)
	Scent.npcs[ent] = nil
	Scent.active[ent] = nil
	if Scent.reeks[ent] then
		Air(Scent.reeks[ent])
		Scent.reeks[ent] = nil
	end
end)

local ai_serverragdolls = GetConVar("ai_serverragdolls")

local function Crawler(ent)
	return IsValid(ent) and ent:GetClass() == "evil_crawler"
end

hook.Add("OnNPCKilled", "EvilCrawlerScent", function(npc, attacker)
	if npc.EvilCrawlerVictim or Crawler(attacker) or ai_serverragdolls and ai_serverragdolls:GetBool() then return end
	Scent.Reek(npc:GetPos(), nil, FRESH)
end)

hook.Add("EvilClaimed", "EvilCrawlerHeld", function(ent)
	ent.EvilCrawlerClaimed = CurTime()
end)

hook.Add("PostPlayerDeath", "EvilCrawlerHeld", function(ply)
	ply.EvilCrawlerDied = CurTime()
end)

hook.Add("PlayerDeath", "EvilCrawlerScent", function(ply, _, attacker)
	if Crawler(attacker) or ply.EvilCrawlerSlain then return end
	Scent.Reek(EvilCrawler.Proxy(ply):GetPos(), nil, FRESH)
end)

for _, ent in ipairs(ents.GetAll()) do
	if Creature(ent) then Scent.npcs[ent] = true end
end
