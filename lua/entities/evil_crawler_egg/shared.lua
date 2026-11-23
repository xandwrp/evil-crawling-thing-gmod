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
-- Keeps the egg out of duplicator dupes and saves. The duplicator skips any entity that sets this,
-- so a save or a dupe that includes an egg is refused rather than restoring one;
-- setting ent.NoDuplicate on the instance does nothing at all.
ENT.DoNotDuplicate = true
