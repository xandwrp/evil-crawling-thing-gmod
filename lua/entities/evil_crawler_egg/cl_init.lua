include("shared.lua")

-- The egg is the spawn-menu PHX cannonball (models/props_phx/cannonball.mdl), drawn with a plain
-- shell material tinted by EvilCrawler.EggColor(). Nothing is copied out of the game and shipped with
-- the addon: the base is vgui/white, which every install has, and the relief comes from the game's
-- own cannon bump map. It is a model material (VertexLitGeneric), so map light and flashlights land
-- on it on their own.
--
-- The cannonball's origin sits at the base of the ball, so the render bounds run up from it, matching
-- the physics hull built in the same model space in init.lua.
local HALF = EvilCrawler.EGG_HALF or Vector(16, 16, 16)
local FALLBACK = Color(180, 35, 30) -- used only if the settings are not there yet

-- A new name, so a map that already built an older material does not hand that one back.
local Shell = CreateMaterial("evil_crawler_egg_shell_tinted", "VertexLitGeneric", {
	["$basetexture"] = "vgui/white",
	["$bumpmap"] = "phoenix_storms/cannon_bump",
	["$model"] = 1,
	["$halflambert"] = 1,
})

-- The tint goes on the material only when the colour actually changes, so it is the same every frame.
local tinted
local function Tint()
	local c = EvilCrawler.EggColor and EvilCrawler.EggColor() or FALLBACK
	local key = c.r * 65536 + c.g * 256 + c.b
	if key == tinted then return end
	tinted = key
	Shell:SetVector("$color2", Vector(c.r / 255, c.g / 255, c.b / 255))
end

function ENT:Initialize()
	self:SetRenderBounds(
		Vector(-HALF.x * 1.1, -HALF.y * 1.1, -2),
		Vector(HALF.x * 1.1, HALF.y * 1.1, HALF.z * 2.2)
	)
end

function ENT:Draw()
	Tint()
	render.MaterialOverride(Shell)
	self:DrawModel()
	render.MaterialOverride()
end
