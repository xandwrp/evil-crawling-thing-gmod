include("shared.lua")

-- The egg is the scaled watermelon model wearing the melon's own texture, washed out over white and
-- tinted with EvilCrawler.EggColor(). Nothing is copied out of the game and shipped with the addon:
-- the shell is built on the client from models/props_junk/fruit_objects01, which is already mounted.
--
-- It is a model material (VertexLitGeneric), so map light and flashlights land on it on their own.
local HALF = EvilCrawler.EGG_HALF or Vector(15.4, 17.9, 15.7)
local FALLBACK = Color(180, 35, 30) -- used only if the settings are not there yet

-- A new name, so a map that already built the old untinted material does not hand that one back.
local Shell = CreateMaterial("evil_crawler_egg_shell_tinted", "VertexLitGeneric", {
	["$basetexture"] = "models/props_junk/fruit_objects01",
	["$model"] = 1,
	["$halflambert"] = 1,
})

-- The game's own texture, drawn only to make the shell.
local SOURCE = CreateMaterial("evil_crawler_egg_source", "UnlitGeneric", {
	["$basetexture"] = "models/props_junk/fruit_objects01",
})
local built = false

-- Runs once, from a draw, so the render target is safe to push. Drawing it over white washes the
-- melon out to a pale shell that the tint shows through, which is what the old hand-made copy was.
local function BuildShell()
	if built then return end
	built = true
	local size = 256
	local rt = GetRenderTarget("evil_crawler_egg_shell", size, size)
	if not rt then return end
	render.PushRenderTarget(rt)
	render.Clear(255, 255, 255, 255, true, true)
	cam.Start2D()
	surface.SetDrawColor(255, 255, 255, 90)
	surface.SetMaterial(SOURCE)
	surface.DrawTexturedRect(0, 0, size, size)
	cam.End2D()
	render.PopRenderTarget()
	Shell:SetTexture("$basetexture", rt)
end

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
	self:SetRenderBounds(-HALF * 1.1, HALF * 1.1)
end

function ENT:Draw()
	BuildShell()
	Tint()
	render.MaterialOverride(Shell)
	self:DrawModel()
	render.MaterialOverride()
end
