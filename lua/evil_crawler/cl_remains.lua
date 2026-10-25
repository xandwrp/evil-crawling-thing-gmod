EvilCrawler = EvilCrawler or {}
local Flesh = EvilCrawler.Flesh
local PARTS = EvilCrawler.PARTS
local EATEN_VAR, WHOLE_VAR = EvilCrawler.EATEN_VAR, EvilCrawler.WHOLE_VAR

local SCAN_INTERVAL = 0.5
local DRIP_TIME = 25
local DRAW_DISTANCE = 2500
local STRANDS = 5
local SLURP_TIME = EvilCrawler.SLURP_TIME

local MEAT = Color(70, 6, 9)
local SINEW = Color(120, 22, 24)
local MARROW = Color(205, 190, 170)
local HIDE = Color(44, 34, 40)
local GRAFT = Color(62, 46, 54)

local remains = {}

local function Shape(size)
	local strands = {}
	for i = 1, STRANDS do
		strands[i] = { x = math.Rand(-0.9, 0.9), y = math.Rand(-0.9, 0.9), len = size * math.Rand(1, 2.4), droop = math.Rand(0.3, 1) }
	end
	return { bone = { x = math.Rand(-0.25, 0.25), y = math.Rand(-0.25, 0.25), len = size * math.Rand(1.2, 2) }, strands = strands }
end

local function Has(mask, part)
	return bit.band(mask, bit.lshift(1, part - 1)) ~= 0
end

local function StumpAt(rag, stump)
	local b, below = rag:LookupBone(stump[1]), rag:LookupBone(stump[2])
	return b and rag:GetBonePosition(b), below and rag:GetBonePosition(below)
end

local function Smooth(t)
	return t * t * (3 - 2 * t)
end

local function Mouth(rag)
	local eater = rag.EvilCrawlerEater
	if not IsValid(eater) or eater:GetVictim() ~= rag then return end
	local p = eater:GetPos()
	if EvilCrawler.Setting("abdomen") > 0 then p = p - eater:GetUp() * (eater.BodyHeight * EvilCrawler.BELLY.tall) end
	return p
end

local held = {}

local function Slurp(rag, bones, into, t)
	local far = 1
	for k, b in ipairs(bones) do
		local m = rag:GetBoneMatrix(b)
		held[k] = m
		if m then far = math.max(far, m:GetTranslation():Distance(into)) end
	end
	for k, b in ipairs(bones) do
		local m = held[k]
		if m then
			local at = m:GetTranslation()
			local p = Smooth(math.Clamp((t - at:Distance(into) / far * 0.5) / 0.5, 0, 1))
			local s = (1 - p) * (1 + 1.2 * math.sin(math.pi * p))
			m:SetTranslation(LerpVector(p, at, into))
			m:Scale(Vector(s, s, s))
			rag:SetBoneMatrix(b, m)
		end
		held[k] = nil
	end
end

local function Fold(rag)
	local mask = rag.EvilCrawlerMask
	if not mask or mask == 0 then return end

	local into
	local current = EvilCrawler.CurrentPart(rag)
	local grip = current and rag:LookupBone(PARTS[current].grip[1])
	local m = grip and rag:GetBoneMatrix(grip)
	if m then into = m:GetTranslation() end
	local whole = rag:GetNW2Bool(WHOLE_VAR)
	local mouth = whole and Mouth(rag)
	local now = CurTime()

	for i in ipairs(PARTS) do
		if Has(mask, i) then
			local bones = EvilCrawler.PartBones(rag, i)
			local p = into
			if not p then
				local own = bones[1] and rag:GetBoneMatrix(bones[1])
				p = own and own:GetTranslation()
			end
			local age = whole and rag.EvilCrawlerSlurp and now - (rag.EvilCrawlerSlurp[i] or 0)
			if age and age < SLURP_TIME then
				Slurp(rag, bones, mouth or p or rag:GetPos(), age / SLURP_TIME)
			elseif p then
				local point = Matrix({ { 0, 0, 0, p.x }, { 0, 0, 0, p.y }, { 0, 0, 0, p.z }, { 0, 0, 0, 1 } })
				for _, b in ipairs(bones) do rag:SetBoneMatrix(b, point) end
			end
		end
	end
end

local function Track(rag, mask, live)
	if live then
		local had = rag.EvilCrawlerMask or 0
		rag.EvilCrawlerSlurp = rag.EvilCrawlerSlurp or {}
		for i in ipairs(PARTS) do
			if Has(mask, i) and not Has(had, i) then rag.EvilCrawlerSlurp[i] = CurTime() end
		end
		for _, crawler in ipairs(ents.FindByClass("evil_crawler")) do
			-- entities arriving in the same snapshot can exist before SetupDataTables has run on them
			if crawler.GetVictim and crawler:GetVictim() == rag then rag.EvilCrawlerEater = crawler end
		end
	end
	rag.EvilCrawlerMask = mask
	if not rag.EvilCrawlerFolding then
		rag.EvilCrawlerFolding = true
		rag:AddCallback("BuildBonePositions", Fold)
	end

	local last
	for i in ipairs(PARTS) do
		if Has(mask, i) then last = i end
	end
	local r = remains[rag]
	if last and (not r or r.part ~= last) then
		local shapes = {}
		for i in ipairs(PARTS[last].stumps) do shapes[i] = Shape(PARTS[last].size) end
		remains[rag] = { at = CurTime(), part = last, shapes = shapes }
	end
end

hook.Add("EntityNetworkedVarChanged", "EvilCrawlerRemains", function(ent, name, _, mask)
	if name == EATEN_VAR and mask and mask ~= 0 then Track(ent, mask, true) end
end)

timer.Create("EvilCrawlerRemains", SCAN_INTERVAL, 0, function()
	for _, rag in ipairs(ents.FindByClass("prop_ragdoll")) do
		local mask = rag:GetNW2Int(EATEN_VAR, 0)
		if mask ~= 0 and mask ~= rag.EvilCrawlerMask then Track(rag, mask) end
	end

	local now = CurTime()
	for rag, r in pairs(remains) do
		if not IsValid(rag) then
			remains[rag] = nil
		elseif not rag:IsDormant() and not rag:GetNW2Bool(WHOLE_VAR) then
			local age = now - r.at
			for _, stump in ipairs(PARTS[r.part].stumps) do
				if age < DRIP_TIME and math.random() < 0.8 * (1 - age / DRIP_TIME) then
					local p = StumpAt(rag, stump)
					if p then
						local fx = EffectData()
						fx:SetOrigin(p)
						fx:SetNormal(-vector_up)
						util.Effect("BloodImpact", fx)
						if math.random() < 0.35 then util.Decal("Blood", p, p - vector_up * 256, rag) end
					end
				end
			end
		end
	end
end)

local function Taper(f, size) return size * (1 - 0.8 * f) end
local function Cap(f, size) return size * (1.15 - 0.55 * f * f) end
local function Splinter(f, size) return size * 0.32 * (1 - 0.6 * f) end

local function Solid(c)
	return function() return c.r, c.g, c.b end
end
local MeatColor, SinewColor = Solid(MEAT), Solid(SINEW)
local GraftColor, HideColor = Solid(GRAFT), Solid(HIDE)
local function BoneColor(f)
	local k = math.Clamp(f * 1.6, 0, 1)
	return Lerp(k, MEAT.r, MARROW.r), Lerp(k, MEAT.g, MARROW.g), Lerp(k, MEAT.b, MARROW.b)
end

local pts2, pts3 = {}, {}

local function DrawStump(rag, stump, size, shape, whole)
	local p, pp = StumpAt(rag, stump)
	if not p or not pp then return end

	local d = p - pp
	if d:LengthSqr() < 1e-4 then d = vector_up end
	d:Normalize()
	local ang = d:Angle()
	local u, v = ang:Right(), ang:Up()

	Flesh.SampleLight(p)

	pts2[1], pts2[2] = p - d * size * 0.9, p + d * size * 0.35
	Flesh.Tube(pts2, 7, 2, Cap, whole and GraftColor or MeatColor, size)

	local bone = shape.bone
	if not whole then
		pts2[1] = p - d * size * 0.3
		pts2[2] = p + (d + u * bone.x + v * bone.y):GetNormalized() * bone.len
		Flesh.Tube(pts2, 5, 2, Splinter, BoneColor, size)
	end

	for _, s in ipairs(shape.strands) do
		local dir = (d + u * s.x + v * s.y):GetNormalized()
		local tip = p + dir * s.len - vector_up * (s.len * 0.4 * s.droop)
		pts3[1] = p + (u * s.x + v * s.y) * size * 0.5
		pts3[2] = p + dir * (s.len * 0.5) - vector_up * (s.len * 0.1 * s.droop)
		pts3[3] = tip
		Flesh.Tube(pts3, 4, 2, Taper, whole and HideColor or SinewColor, size * 0.22)
	end
end

hook.Add("PostDrawOpaqueRenderables", "EvilCrawlerRemains", function(depth, sky)
	if depth or sky or not next(remains) then return end
	local eye = EyePos()
	render.SetMaterial(Flesh.Material)
	for rag, r in pairs(remains) do
		if IsValid(rag) and not rag:IsDormant() and rag:GetPos():DistToSqr(eye) < DRAW_DISTANCE * DRAW_DISTANCE then
			local part = PARTS[r.part]
			local whole = rag:GetNW2Bool(WHOLE_VAR)
			for i, shape in ipairs(r.shapes) do DrawStump(rag, part.stumps[i], part.size, shape, whole) end
		end
	end
end)
