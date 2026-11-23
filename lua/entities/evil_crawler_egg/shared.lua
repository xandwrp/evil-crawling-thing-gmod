EvilCrawler = EvilCrawler or {}
-- The HL2 watermelon at twice its size: about 31 x 36 x 31. sv_eggs.lua keeps its own copy of these
-- for the nest checks.
EvilCrawler.EGG_MODEL = "models/props_junk/watermelon01.mdl"
EvilCrawler.EGG_SCALE = 2
EvilCrawler.EGG_HALF = Vector(7.70, 8.96, 7.83) * EvilCrawler.EGG_SCALE -- the model's hull, scaled
EvilCrawler.EGG_THICK = 32

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Evil Crawler Egg"
ENT.Category = "Syhgma's Evil Entities"
ENT.Spawnable = Evil ~= nil
ENT.RenderGroup = RENDERGROUP_OPAQUE
-- Stops the spawn menu handing out a second one while the button is held. This is a table field the
-- spawn menu reads; setting ent.NoDuplicate on the instance afterwards does nothing.
ENT.DoNotDuplicate = true
