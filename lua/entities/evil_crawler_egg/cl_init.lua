include("shared.lua")

-- The egg is the scaled watermelon model wearing a greyscale copy of the watermelon's own texture
-- (materials/evil_crawler/egg_shell.png, made once from HL2's fruit_objects01). Being greyscale, it
-- takes its colour from EvilCrawler.EggColor() through $color2, so the tint can be changed in code
-- without touching the image. It is a model material (VertexLitGeneric), so map
-- light and flashlights land on it on their own.
local HALF = EvilCrawler.EGG_HALF or Vector(15.4, 17.9, 15.7)
local FALLBACK = Color(180, 35, 30) -- used only if the settings are not there yet

local Shell = CreateMaterial("evil_crawler_egg_shell", "VertexLitGeneric", {
	["$basetexture"] = "models/props_junk/fruit_objects01",
	["$model"] = 1,
	["$halflambert"] = 1,
})
local grey = Material("evil_crawler/egg_shell.png", "smooth mips")
if not grey:IsError() then Shell:SetTexture("$basetexture", grey:GetTexture("$basetexture")) end

-- The tint goes on the material only when the setting actually changes, so it is the same every frame.
local tinted
local function Tint()
	local c = EvilCrawler.EggColor and EvilCrawler.EggColor() or FALLBACK
	local key = c.r * 65536 + c.g * 256 + c.b
	if key == tinted then return end
	tinted = key
	Shell:SetVector("$color2", Vector(c.r / 255, c.g / 255, c.b / 255))
end

function ENT:Initialize()
	self:SetRenderBounds(-HALF * 1.1, HALF * 1.1)
end

function ENT:Draw()
	Tint()
	render.MaterialOverride(Shell)
	self:DrawModel()
	render.MaterialOverride()
end
