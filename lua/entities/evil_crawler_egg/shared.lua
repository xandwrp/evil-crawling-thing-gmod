EvilCrawler = EvilCrawler or {}
-- The Garry's Mod PHX cannonball from spawnlist Builder > Misc, scaled down to about 32 across. Its
-- origin sits at the base, so cl_init.lua draws the shell centred on the physics hull. sv_eggs.lua
-- keeps its own copy of these for the nest checks.
EvilCrawler.EGG_MODEL = "models/props_phx/cannonball.mdl"
EvilCrawler.EGG_SCALE = 0.714
EvilCrawler.EGG_HALF = Vector(22.4, 22.4, 22.4) * EvilCrawler.EGG_SCALE -- the model's visual half-size, scaled
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
