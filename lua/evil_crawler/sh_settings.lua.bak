EvilCrawler = EvilCrawler or {}

EvilCrawler.SETTINGS = {
	{ name = "attack_players", default = 1, min = 0, max = 1, label = "Goes for players",
		help = "Crawlers go for players too. At 0 they leave players alone entirely" },
	{ name = "attack_npcs", default = 1, min = 0, max = 1, label = "Goes for NPCs",
		help = "Crawlers hunt and eat NPCs and nextbots. At 0 they only go for ones that hurt them" },
	{ name = "npcs_fight", default = 1, min = 0, max = 1, label = "NPCs fight back",
		help = "NPCs treat crawlers as enemies and shoot at them" },
	{ name = "open_doors", default = 1, min = 0, max = 1, label = "Opens doors",
		help = "Crawlers force doors open, locked or not" },
	{ name = "squeeze", default = 1, min = 0, max = 1, label = "Squeezes through gaps",
		help = "Crawlers shrink down to follow through vents, crawlspaces and low holes" },
	{ name = "tear", default = 1, min = 0, max = 1, label = "Tears through things",
		help = "Crawlers chasing someone rip through props, welds and elevators in their way" },
	{ name = "throw", default = 1, min = 0, max = 1, label = "Throws props",
		help = "Raging crawlers, and ones being run off, fling loose props at whoever's after them" },
	{ name = "eat_corpses", default = 1, min = 0, max = 1, label = "Eats corpses",
		help = "Hungry crawlers drag off and eat ragdolls they find, and come back for ones they dropped" },
	{ name = "victim_voices", default = 1, min = 0, max = 1, label = "Victims cry out",
		help = "Grabbed NPCs and players scream for help and cry out while it has them" },
	{ name = "struggle_time", default = 3.5, min = 0.5, max = 15, decimals = 1, label = "Struggle time",
		help = "Seconds a grabbed player has to fight free before going under" },
	{ name = "sedate_time", default = 10, min = 0.1, max = 60, decimals = 1, label = "Sedate time",
		help = "Seconds a held NPC takes to go under" },
	{ name = "digest_time", default = 10, min = 0, max = 120, decimals = 0, label = "Digest time",
		help = "Seconds a crawler leaves players alone after a meal, unless they've hurt it" },
	{ name = "reroute_time", default = 0.6, min = 0.1, max = 5, decimals = 1, label = "Reroute time",
		help = "Seconds a crawler stays over someone it can't reach before going round another way" },
	{ name = "sated_time", default = 90, min = 0, max = 600, decimals = 0, label = "Sated time",
		help = "Seconds a meal keeps a crawler from going after NPCs. Anger shortens it" },
	{ name = "hide_time", default = 40, min = 0, max = 180, decimals = 0, label = "Hide time",
		help = "Seconds, give or take a third, a crawler has to stay unseen after it's hurt before coming back" },
	{ name = "flee", default = 1, min = 0, max = 1, label = "Runs when hurt",
		help = "Crawlers run off to hide when they're hurt. At 0 they stand their ground" },
	{ name = "flee_hits", default = 1, min = 1, max = 50, decimals = 0, label = "Flee hits",
		help = "Hits inside 30 seconds before a crawler runs off to hide" },
	{ name = "nerve", default = 0, min = 0, max = 10, decimals = 1, label = "Nerve",
		help = "Extra hits it takes to scare a crawler off for each time it's already run" },
	{ name = "rage_hits", default = 6, min = 1, max = 50, decimals = 0, label = "Rage hits",
		help = "Hits inside 30 seconds that send a crawler into a rage" },
	{ name = "rage_time", default = 10, min = 0, max = 60, decimals = 0, label = "Rage time",
		help = "Seconds a rage lasts. At 0 it never rages" },
	{ name = "npc_hits", default = 0.1, min = 0, max = 1, decimals = 2, label = "NPC hit weight",
		help = "How much an NPC's hit counts toward fleeing, rage and knockouts, next to a player's" },
	{ name = "knockout_hits", default = 6, min = 0, max = 50, decimals = 0, label = "Knockout hits",
		help = "Hits while it's raging that knock it out cold. At 0 it never goes down" },
	{ name = "knockout_anytime", default = 0, min = 0, max = 1, label = "Knock out anytime",
		help = "Knockout hits count when it isn't raging too, inside 30 seconds" },
	{ name = "knockout_time", default = 25, min = 1, max = 120, decimals = 0, label = "Knockout time",
		help = "Seconds, give or take a fifth, it stays down" },
	{ name = "tired_time", default = 20, min = 0, max = 120, decimals = 0, label = "Tired time",
		help = "Seconds of chasing it takes to get its full speed back after a knockout. At 0 it wakes up fresh" },
	{ name = "killable", default = 1, min = 0, max = 1, label = "Killable",
		help = "Enough hits from players while it's knocked out kills it" },
	{ name = "kill_hits", default = 6, min = 1, max = 50, decimals = 0, label = "Finishing hits",
		help = "Hits from players it takes to kill a knocked out crawler" },
	{ name = "escape_tighten", default = 0.5, min = 0, max = 3, decimals = 2, label = "Coil tightening",
		help = "How much harder the coil is to fight out of for each time that player got away lately" },
	{ name = "size", default = 1, min = 0.25, max = 4, decimals = 2, label = "Spawn size",
		help = "Size of crawlers spawned from now on. Small ones go down in fewer hits, big ones take more" },
	{ name = "grow", default = 0, min = 0, max = 3, decimals = 2, label = "Growth",
		help = "How much bigger a crawler gets for each body it eats, legs swelling with what it's swallowed. "
			.. "It keeps it until it dies. At 0 it never grows" },
	{ name = "grow_max", default = 5, min = 1, max = 10, decimals = 1, label = "Biggest size",
		help = "Most a crawler can grow, times its starting size" },
	{ name = "abdomen", default = 0, min = 0, max = 1, label = "Stomach",
		help = "Gives crawlers a stomach where the legs meet, with a mouth underneath that it feeds through" },
	{ name = "integrate", default = 0, min = 0, max = 1, label = "Integration mode",
		help = "Crawlers take bodies in whole instead of tearing them apart, and keep them. "
			.. "Everyone it's eaten makes it a bit bigger, sharper and quicker to take the next one" },
	{ name = "pilot", default = 0, min = 0, max = 1, label = "Eaten players take over (integration)",
		help = "In integration mode, the first player a crawler finishes eating ends up driving it. "
			.. "Move, sprint, jump to leap, attack to strike, hold use to let go and respawn" },
	{ name = "flesh_color", default = 5908524, min = 0, max = 16777215, color = true, label = "Flesh colour",
		help = "Colour of its flesh. The colour tool paints single crawlers over this" },
	{ name = "burst", default = 1100, min = 100, max = 3000, decimals = 0, label = "Dart speed",
		help = "Top speed of a dart" },
	{ name = "hunter", default = 0, min = 0, max = 5, decimals = 1, label = "Hunter",
		help = "How often a hungry crawler gets a hunch where a player is and goes to look. Higher is more often and closer. At 0 it only finds you on its own" },
	{ name = "sight_range", default = 4000, min = 0, max = 10000, decimals = 0, label = "Sight range",
		help = "How far crawlers can see" },
	{ name = "hearing", default = 1, min = 0, max = 5, decimals = 1, label = "Hearing",
		help = "How far crawlers hear gunfire, explosions, running and other loud sounds. At 0 they're deaf" },
	{ name = "show_scent", default = 0, min = 0, max = 1, label = "Show scent trails",
		help = "Marks scent trails on the ground for everyone: players amber, NPCs green, fear magenta, "
			.. "a trail a crawler is following cyan, and the spot it's heading for ringed" },
}

EvilCrawler.Settings = Evil.Settings({
	id = "evil_crawler", title = "Evil Crawling Thing", rows = EvilCrawler.SETTINGS,
	top = function(panel)
		panel:CheckBox("Show the mash prompt", "evil_crawler_struggle_prompt")
	end,
})

function EvilCrawler.Setting(name)
	return EvilCrawler.Settings:Get(name)
end

function EvilCrawler.FleshColor()
	return Color(EvilCrawler.Settings:Color("flesh_color"))
end
