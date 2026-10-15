include("evil_crawler/sh_ik.lua")
include("evil_crawler/sh_morph.lua")
include("evil_crawler/sh_struggle.lua")

EvilCrawler.ACT_NONE = 0
EvilCrawler.ACT_STRIKE = 1
EvilCrawler.ACT_DRAG = 2
EvilCrawler.ACT_FEED = 3
EvilCrawler.ACT_GRAPPLE = 4
EvilCrawler.ACT_STUN = 5
EvilCrawler.ACT_SEAR = 6
EvilCrawler.ACT_OUT = 7
EvilCrawler.ACT_DEAD = 8
EvilCrawler.CORPSE_TIME = 60
EvilCrawler.ROT_TIME = 4
EvilCrawler.STUN_TIME = 3
EvilCrawler.STRIKE_WINDUP = 0.4
EvilCrawler.STRIKE_LUNGE = 0.08
EvilCrawler.WRAP_TIME = 0.15
EvilCrawler.PULL_TIME = 2
EvilCrawler.SEAR_TIME = 0.3
EvilCrawler.GRAVITY = 600

EvilCrawler.FEEDERS = 4
EvilCrawler.BITE_JAB = 0.5
EvilCrawler.BITE_IN = 0.56
EvilCrawler.BITE_RIP = 0.82
EvilCrawler.LUMP_TIME = 1.2
EvilCrawler.STROKE_PUSH = 0.3

function EvilCrawler.Stroke(seed, t)
	local x = t / (0.7 + seed % 7 * 0.05) + seed % 11 / 11
	local n = math.floor(x)
	return n, x - n
end

local B = "ValveBiped.Bip01_"
EvilCrawler.PARTS = {
	{
		grip = { B .. "Head1" }, roots = { B .. "Head1" }, bones = { B .. "Neck1" }, rips = 6,
		stumps = { { B .. "Spine4", B .. "Spine2" } }, size = 3.4,
	},
	{
		grip = { B .. "Spine2" }, roots = { B .. "L_Clavicle", B .. "R_Clavicle" }, bones = { B .. "Spine4" }, rips = 8,
		stumps = { { B .. "Spine2", B .. "Spine1" } }, size = 4.6,
	},
	{
		grip = { B .. "Spine2" }, bones = { B .. "Spine2", B .. "Spine1" }, rips = 8,
		stumps = { { B .. "Spine", B .. "Pelvis" } }, size = 4.6,
	},
	{
		grip = { B .. "Pelvis" }, bones = { B .. "Spine", B .. "Pelvis" }, rips = 8,
		stumps = { { B .. "L_Thigh", B .. "L_Calf" }, { B .. "R_Thigh", B .. "R_Calf" } }, size = 3.8,
	},
	{
		grip = { B .. "L_Thigh", B .. "R_Thigh" }, bones = { B .. "L_Thigh", B .. "R_Thigh" }, rips = 6,
		stumps = { { B .. "L_Calf", B .. "L_Foot" }, { B .. "R_Calf", B .. "R_Foot" } }, size = 3,
	},
	{
		grip = { B .. "L_Calf", B .. "R_Calf" }, roots = { B .. "L_Calf", B .. "R_Calf" }, rips = 5,
		stumps = {}, size = 2.5,
	},
}
for _, part in ipairs(EvilCrawler.PARTS) do
	part.bites = {}
	for _, b in ipairs(part.grip) do part.bites[#part.bites + 1] = b end
	for _, b in ipairs(part.bones or {}) do
		if not table.HasValue(part.bites, b) then part.bites[#part.bites + 1] = b end
	end
end
EvilCrawler.TORSO_BITES = { B .. "Spine2", B .. "Spine1", B .. "Spine", B .. "Pelvis" }
EvilCrawler.EATEN_VAR = "EvilCrawlerEaten"

function EvilCrawler.Eaten(corpse, part)
	return bit.band(corpse:GetNW2Int(EvilCrawler.EATEN_VAR, 0), bit.lshift(1, part - 1)) ~= 0
end

function EvilCrawler.CurrentPart(corpse)
	for part, p in ipairs(EvilCrawler.PARTS) do
		if not EvilCrawler.Eaten(corpse, part) then
			return corpse:LookupBone(p.grip[1]) and part or nil
		end
	end
end

function EvilCrawler.PartBones(ent, part)
	ent.EvilCrawlerPartBones = ent.EvilCrawlerPartBones or {}
	local bones = ent.EvilCrawlerPartBones[part]
	if bones then return bones end
	bones = {}
	local function subtree(b)
		bones[#bones + 1] = b
		for _, child in ipairs(ent:GetChildBones(b)) do subtree(child) end
	end
	local p = EvilCrawler.PARTS[part]
	for _, name in ipairs(p.roots or {}) do
		local b = ent:LookupBone(name)
		if b then subtree(b) end
	end
	for _, name in ipairs(p.bones or {}) do
		local b = ent:LookupBone(name)
		if b and not table.HasValue(bones, b) then bones[#bones + 1] = b end
	end
	ent.EvilCrawlerPartBones[part] = bones
	return bones
end

function EvilCrawler.BiteCycle(k, t)
	local x = t / (1.3 + k * 0.29) - k * 0.37
	local n = math.floor(x)
	return n, x - n
end

function EvilCrawler.BiteBone(seed, k, n, part)
	local bones = part and EvilCrawler.PARTS[part].bites or EvilCrawler.TORSO_BITES
	return bones[(seed + k * 7 + n * 5) % #bones + 1]
end

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Evil Crawler"
ENT.Category = "Evil Crawling Thing"
ENT.Spawnable = true
ENT.RenderGroup = RENDERGROUP_OPAQUE

ENT.BodyHeight = 64

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Seed")
	self:NetworkVar("Int", 1, "Mood")
	self:NetworkVar("Entity", 0, "Prey")
	self:NetworkVar("Int", 2, "Act")
	self:NetworkVar("Float", 0, "ActStart")
	self:NetworkVar("Float", 1, "RageUntil")
	self:NetworkVar("Float", 2, "Squeeze")
	self:NetworkVar("Entity", 1, "Victim")
	self:NetworkVar("Bool", 0, "Swimming")
end

local entMeta = FindMetaTable("Entity")

local isNpcEnt
local isNextbotEnt
local isNextbotOrNpcEnt
local isPlayer

-- 2x as fast as :IsNPC(), which isnt really much faster but hey. credit to zaurzo for the method
do
	local npcMeta = FindMetaTable("NPC")
	local nextbotMeta = FindMetaTable("NextBot")
	local plyMeta = FindMetaTable("Player")
	local getmetatable = getmetatable

	isNpcEnt = function(ent)
		return getmetatable(ent) == npcMeta
	end
	isNextbotEnt = function(ent)
		return getmetatable(ent) == nextbotMeta
	end

	isNextbotOrNpcEnt = function(ent)
		return isNpcEnt(ent) or isNextbotEnt(ent)
	end
	function ENT:IsNextbotOrNpcEnt(ent)
		return isNextbotOrNpcEnt(ent)
	end

	isPlayer = function(ent)
		return getmetatable(ent) == plyMeta
	end
	function ENT:IsPlyNoIndex(ent)
		return isPlayer(ent)
	end
end

local traceTbl = {}
local traceOwner
local COLLISION_GROUP_DEBRIS = COLLISION_GROUP_DEBRIS

ENT.DefaultTraceFilter = function(e)
	if e == traceOwner then return end
	if isPlayer(e) or isNpcEnt(e) or isNextbotEnt(e) then return end
	if entMeta.IsRagdoll(e) then return end
	if entMeta.GetCollisionGroup(e) == COLLISION_GROUP_DEBRIS then return end
	return true
end

function ENT:Trace(from, to, mask)
	local myTbl = entMeta.GetTable(self)
	mask = mask or MASK_SOLID

	local traceFilter = myTbl.TraceFilter or myTbl.DefaultTraceFilter

	traceTbl.start = from
	traceTbl.endpos = to
	traceTbl.filter = traceFilter
	traceTbl.mask = mask

	traceOwner = self
	local result = util.TraceLine(traceTbl)
	traceOwner = nil

	return result
end

function ENT:TraceMyTbl(myTbl, from, to, mask)
	mask = mask or MASK_SOLID

	local traceFilter = myTbl.TraceFilter or myTbl.DefaultTraceFilter

	traceTbl.start = from
	traceTbl.endpos = to
	traceTbl.filter = traceFilter
	traceTbl.mask = mask

	traceOwner = self
	local result = util.TraceLine(traceTbl)
	traceOwner = nil

	return result
end
