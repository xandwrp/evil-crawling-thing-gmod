EvilCrawler = EvilCrawler or {}

local function Rng(seed)
	local s = seed % 2147483646 + 1
	return function(a, b)
		s = s * 16807 % 2147483647
		local f = (s - 1) / 2147483646
		return a and a + f * (b - a) or f
	end
end

EvilCrawler.Rng = Rng

local function Int(rand, a, b)
	return math.floor(rand(a, b + 1))
end

local function OnSphere(rand, r, minZ, maxZ)
	local yaw = math.rad(rand(0, 360))
	local z = rand(minZ, maxZ)
	local flat = math.sqrt(1 - z * z)
	return Vector(math.cos(yaw) * flat * r, math.sin(yaw) * flat * r, z * r)
end

local function Segments(rand, count, total)
	local lengths, sum = {}, 0
	for i = 1, count do
		lengths[i] = rand(0.6, 1.4)
		sum = sum + lengths[i]
	end
	for i = 1, count do
		lengths[i] = lengths[i] / sum * total
	end
	return lengths
end

-- Share of the usual legs a runt (the stillborn crawler from a broken egg) grows.
EvilCrawler.RUNT_LEGS = 0.25

-- legShare scales how many legs it grows (1 or nil for a normal crawler), never below two.
function EvilCrawler.Grow(seed, legShare)
	local rand = Rng(seed)
	local creature = {
		legs = {},
		churn = rand(-30, 30),
		phase = rand(0, 100),
	}

	local count = Int(rand, 8, 12)
	if legShare and legShare < 1 then count = math.max(2, math.Round(count * legShare)) end
	local reach = 0
	for i = 1, count do
		local segments = Int(rand, 3, 5)
		local length = rand(150, 230)
		reach = reach + length
		creature.legs[i] = {
			root = OnSphere(rand, rand(3, 7), -0.5, 1),
			angle = (i - 1) / count * 360 + rand(-14, 14),
			spread = rand(0.45, 0.65),
			segments = segments,
			lengths = Segments(rand, segments, length),
			length = length,
			width = rand(2.5, 4.5),
			stepDistance = rand(35, 65),
			stepTime = rand(0.2, 0.34),
			stepHeight = rand(20, 45),
			pitch = Int(rand, 55, 120),
			phase = rand(0, 100),
			freq = rand(0.6, 2.4),
			shade = rand(0.75, 1.2),
		}
		local leg = creature.legs[i]
		leg.base = {
			length = leg.length, lengths = { unpack(leg.lengths) }, root = leg.root, width = leg.width,
			stepDistance = leg.stepDistance, stepHeight = leg.stepHeight,
		}
	end
	creature.height = reach / count * 0.36
	creature.baseHeight = creature.height
	creature.size = 1

	local gap = 360 / count * 1.6
	for _, leg in ipairs(creature.legs) do
		leg.neighbours = {}
		for _, other in ipairs(creature.legs) do
			if other ~= leg and math.abs(math.AngleDifference(leg.angle, other.angle)) < gap then
				leg.neighbours[#leg.neighbours + 1] = other
			end
		end
	end

	return creature
end

function EvilCrawler.Swell(creature, size)
	creature.size = size
	local girth = size ^ 1.5
	for _, leg in ipairs(creature.legs) do
		local base = leg.base
		leg.length = base.length * size
		for i, l in ipairs(base.lengths) do leg.lengths[i] = l * size end
		leg.root = base.root * size
		leg.width = base.width * girth
		leg.stepDistance = base.stepDistance * size
		leg.stepHeight = base.stepHeight * size
	end
	creature.height = creature.baseHeight * size
end
