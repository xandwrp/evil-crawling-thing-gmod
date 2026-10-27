EvilCrawler = EvilCrawler or {}
local Victim = EvilCrawler.Victim or {}
EvilCrawler.Victim = Victim

local WEAR_OFF = 20
local GETUP_SEDATION = 0.35
local GETUP_TIME = 2
local SETTLED = 60
local THRASH_FORCE = 450
local WOUND = { 0.08, 0.13 }
local FADING = 0.3
local CRY_FEAR = { radius = 900, time = 30 }
local STRIKE_FEAR = { radius = 600, time = 20 }
local ESCAPE_FEAR = 90
local BLEED = 0.02
local TAKEN_SEDATION = 0.7
local YANK = { 450, 150 }
local SHRUG_MEMORY = 60
local SHRUG_TEST = 5

local NIP_SOUNDS = {
	"physics/flesh/flesh_impact_bullet2.wav",
	"physics/flesh/flesh_impact_bullet4.wav",
}

Victim.bodies = Victim.bodies or {}

local LIMBS = {
	"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_R_Foot",
	"ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_Head1",
}
local STANDING_OFFSETS = {
	Vector(0, 0, 0), Vector(24, 0, 0), Vector(-24, 0, 0), Vector(0, 24, 0), Vector(0, -24, 0), Vector(0, 0, 24),
}

local function Numbered(path, from, to)
	local t = {}
	for i = from, to do t[#t + 1] = string.format(path, i) end
	return t
end

local function Citizen(who)
	local vo = "vo/npc/" .. who .. "/"
	return {
		wake = { vo .. "startle01.wav", vo .. "startle02.wav", vo .. "ohno.wav" },
		help = { vo .. "help01.wav", vo .. "help01.wav", vo .. "no01.wav", vo .. "no02.wav", vo .. "gethellout.wav" },
		pain = Numbered(vo .. "pain%02d.wav", 1, 9),
		die = Numbered(vo .. "moan%02d.wav", 1, 5),
	}
end

local MALE, FEMALE = Citizen("male01"), Citizen("female01")

local ZOMBIE = {
	wake = Numbered("npc/zombie/zombie_alert%d.wav", 1, 3),
	help = Numbered("npc/zombie/zombie_pain%d.wav", 1, 6),
	pain = Numbered("npc/zombie/zombie_pain%d.wav", 1, 6),
	die = Numbered("npc/zombie/zombie_die%d.wav", 1, 3),
}

local VOICES = {
	npc_barney = {
		wake = { "vo/npc/barney/ba_ohshit03.wav" },
		help = { "vo/npc/barney/ba_no01.wav", "vo/npc/barney/ba_no02.wav" },
		pain = Numbered("vo/npc/barney/ba_pain%02d.wav", 1, 10),
		die = { "vo/npc/barney/ba_pain06.wav" },
	},
	npc_alyx = {
		wake = { "vo/npc/alyx/ohno_startle01.wav", "vo/npc/alyx/ohno_startle03.wav" },
		help = { "vo/npc/alyx/no01.wav", "vo/npc/alyx/no02.wav", "vo/npc/alyx/no03.wav" },
		pain = { "vo/npc/alyx/hurt04.wav", "vo/npc/alyx/hurt05.wav", "vo/npc/alyx/hurt06.wav", "vo/npc/alyx/hurt08.wav" },
		die = { "vo/npc/alyx/gasp02.wav", "vo/npc/alyx/gasp03.wav" },
	},
	npc_kleiner = {
		wake = { "vo/k_lab/kl_dearme.wav", "vo/k_lab/kl_ohdear.wav" },
		help = { "vo/k_lab/kl_ahhhh.wav", "vo/k_lab/kl_fiddlesticks.wav" },
		pain = { "vo/k_lab/kl_ahhhh.wav" },
		die = { "vo/k_lab/kl_ahhhh.wav" },
	},
	npc_monk = {
		wake = Numbered("vo/ravenholm/monk_helpme%02d.wav", 1, 5),
		help = Numbered("vo/ravenholm/monk_helpme%02d.wav", 1, 5),
		pain = Numbered("vo/ravenholm/monk_pain%02d.wav", 1, 12),
		die = { "vo/ravenholm/monk_pain12.wav" },
	},
	npc_metropolice = {
		wake = { "npc/metropolice/vo/officerneedsassistance.wav" },
		help = { "npc/metropolice/vo/officerneedshelp.wav", "npc/metropolice/vo/officerneedsassistance.wav", "npc/metropolice/vo/help.wav" },
		pain = Numbered("npc/metropolice/pain%d.wav", 1, 4),
		die = Numbered("npc/metropolice/die%d.wav", 1, 4),
	},
	npc_combine_s = {
		wake = { "npc/combine_soldier/vo/on1.wav", "npc/combine_soldier/vo/on2.wav" },
		help = Numbered("npc/combine_soldier/pain%d.wav", 1, 3),
		pain = Numbered("npc/combine_soldier/pain%d.wav", 1, 3),
		die = Numbered("npc/combine_soldier/die%d.wav", 1, 3),
	},
	npc_zombie = ZOMBIE,
	npc_zombie_torso = ZOMBIE,
	npc_poisonzombie = ZOMBIE,
	npc_zombine = {
		wake = Numbered("npc/zombine/zombine_alert%d.wav", 1, 7),
		help = Numbered("npc/zombine/zombine_pain%d.wav", 1, 4),
		pain = Numbered("npc/zombine/zombine_pain%d.wav", 1, 4),
		die = Numbered("npc/zombine/zombine_die%d.wav", 1, 2),
	},
	npc_fastzombie = {
		wake = { "npc/fast_zombie/wake1.wav" },
		help = { "npc/fast_zombie/fz_scream1.wav", "npc/fast_zombie/fz_frenzy1.wav" },
		pain = { "npc/fast_zombie/fz_scream1.wav" },
		die = { "npc/fast_zombie/fz_alert_close1.wav" },
	},
}

local function VoiceOf(npc, rag)
	local voice = VOICES[npc:GetClass()]
	if voice then return voice end
	if not rag:LookupBone("ValveBiped.Bip01_Head1") then return end
	local model = npc:GetModel():lower()
	if model:find("zombi") or model:find("vort") then return end
	for _, f in ipairs({ "female", "alyx", "mossman", "chell" }) do
		if model:find(f, 1, true) then return FEMALE end
	end
	return MALE
end

local function Godly(ent)
	return ent:IsPlayer() and ent:HasGodMode()
end

local function Say(rag, kind, level)
	local lines = rag.EvilCrawlerVoice and rag.EvilCrawlerVoice[kind]
	if not lines or EvilCrawler.Setting("victim_voices") == 0 then return end
	local line = lines[math.random(#lines)]
	rag:EmitSound(line, level or 90, rag.EvilCrawlerPitch, 1, CHAN_VOICE)
	EvilCrawler.Scent.Frighten(rag:GetPos(), CRY_FEAR.radius, CRY_FEAR.time)
	return line
end

local function PhysOf(rag, bone)
	local b = rag:LookupBone(bone)
	local index = b and rag:TranslateBoneToPhysBone(b) or -1
	if index < 0 then index = math.random(0, rag:GetPhysicsObjectCount() - 1) end
	local phys = rag:GetPhysicsObjectNum(index)
	return IsValid(phys) and phys
end

local function Gone(rag, bone)
	local b = rag:LookupBone(bone)
	return b and rag:GetManipulateBoneScale(b).x == 0
end

local function Thrash(rag, strength, kicks)
	for _ = 1, kicks do
		local limb = LIMBS[math.random(#LIMBS)]
		local phys = not Gone(rag, limb) and PhysOf(rag, limb)
		if phys then phys:ApplyForceCenter(VectorRand() * phys:GetMass() * THRASH_FORCE * strength) end
	end
end

local function Nip(rag)
	local phys = PhysOf(rag, LIMBS[math.random(#LIMBS)])
	if not phys then return end
	sound.Play(NIP_SOUNDS[math.random(#NIP_SOUNDS)], phys:GetPos(), 55, math.random(130, 160), 0.4)
end

function Victim.Opened(rag)
	if rag.EvilCrawlerOpened then return end
	rag.EvilCrawlerOpened = true
	rag:SetBloodColor(BLOOD_COLOR_RED)
end

local function Pose(rag, npc)
	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local phys = rag:GetPhysicsObjectNum(i)
		local m = npc:GetBoneMatrix(rag:TranslatePhysBoneToBone(i))
		if IsValid(phys) and m then
			phys:SetPos(m:GetTranslation())
			phys:SetAngles(m:GetAngles())
			phys:Wake()
		end
	end
end

local function Nothing() end

local function Hide(npc)
	npc.EvilCrawlerHadNoTarget = npc:IsFlagSet(FL_NOTARGET)
	npc:SetNoDraw(true)
	npc:DrawShadow(false)
	npc:SetNotSolid(true)
	npc.EvilCrawlerMoveType = npc:GetMoveType()
	npc:SetMoveType(MOVETYPE_NONE)
	npc:AddFlags(FL_NOTARGET)
	npc:AddEFlags(EFL_NO_THINK_FUNCTION)
	if npc:IsNPC() then
		npc:ClearSchedule()
		npc:SetEnemy(NULL)
	else
		npc.BehaveUpdate, npc.Think = Nothing, Nothing
	end
	if not isfunction(npc.PauseAttacks) then
		npc.EvilCrawlerPaused = npc.PauseAttacks
		npc.PauseAttacks = true
	end
end

local function Manips(rag, ent)
	if not ent:HasBoneManipulations() then return end
	for b = 0, ent:GetBoneCount() - 1 do
		local to = rag:LookupBone(ent:GetBoneName(b))
		if to then
			rag:ManipulateBonePosition(to, ent:GetManipulateBonePosition(b))
			rag:ManipulateBoneAngles(to, ent:GetManipulateBoneAngles(b))
			rag:ManipulateBoneScale(to, ent:GetManipulateBoneScale(b))
			rag:ManipulateBoneJiggle(to, ent:GetManipulateBoneJiggle(b))
		end
	end
end

local function Body(ent)
	local rag = ents.Create("prop_ragdoll")
	if not IsValid(rag) then return end
	rag:SetModel(ent:GetModel())
	rag:SetPos(ent:GetPos())
	rag:SetAngles(ent:GetAngles())
	rag:SetSkin(ent:GetSkin())
	rag:SetColor(ent:GetColor())
	rag:SetMaterial(ent:GetMaterial())
	for _, group in ipairs(ent:GetBodyGroups()) do
		rag:SetBodygroup(group.id, ent:GetBodygroup(group.id))
	end
	rag:Spawn()
	rag:Activate()
	Manips(rag, ent)

	local ok, err = pcall(Pose, rag, ent)
	if not ok or rag:GetPhysicsObjectCount() == 0 then
		if not ok then ErrorNoHalt("[evil_crawler] couldn't pose body: " .. tostring(err) .. "\n") end
		rag:Remove()
		return
	end
	rag:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	rag:SetBloodColor(DONT_BLEED)
	return rag
end
Victim.Body = Body

local function Hold(rag, ent, holder, sedation)
	ent.EvilCrawlerBody = rag
	rag.EvilCrawlerOwner = ent
	if ent:IsPlayer() then rag.EvilCrawlerPlayer = ent end
	rag.EvilCrawlerWho = rag.EvilCrawlerWho or Evil.Describe(ent)
	rag.EvilCrawlerHolder = holder
	rag.EvilCrawlerVoice = VoiceOf(ent, rag)
	rag.EvilCrawlerPitch = math.random(94, 106)
	rag.Sedation = sedation
	rag.NextCry = CurTime() + math.Rand(0.8, 1.4)
	Victim.bodies[rag] = true
	EvilCrawler.Scent.Frighten(rag:GetPos(), STRIKE_FEAR.radius, STRIKE_FEAR.time)
end

function Victim.Grab(npc, holder)
	local rag = Body(npc)
	if not rag then return end

	npc.EvilCrawlerVictim = true
	Hide(npc)
	Hold(rag, npc, holder, 0)

	Say(rag, "wake")
	Thrash(rag, 1.6, 6)
	return rag
end

function Victim.Fall(ply)
	if not (hg and hg.Fake) then return end
	if not EvilCrawler.Fake(ply) then hg.Fake(ply, nil, true, true) end
	return EvilCrawler.Fake(ply)
end

function Victim.Yank(ply, from)
	local rag = EvilCrawler.Fake(ply)
	if not rag then
		ply:ExitVehicle()
		return
	end
	local pull = (from - rag:GetPos()):GetNormalized() * YANK[1] + vector_up * YANK[2]
	local welds = EvilCrawler.Own(rag, "welds")
	rag.removingwelds = true
	if istable(welds) then
		for _, weld in pairs(welds) do SafeRemoveEntity(weld) end
	end
	rag.welds, rag.removingwelds = nil, nil
	rag:SetParent()
	for i = 0, rag:GetPhysicsObjectCount() - 1 do rag:GetPhysicsObjectNum(i):SetVelocity(pull) end
	timer.Simple(0, function()
		if IsValid(ply) and ply:InVehicle() then ply:ExitVehicle() end
	end)
end

function Victim.Slay(ply)
	ply.EvilCrawlerSlain = true
	ply:Kill()
	ply.EvilCrawlerSlain = nil
end

function Victim.Take(ply, holder)
	local rag = Victim.Fall(ply)
	if rag then
		Hold(rag, ply, holder, TAKEN_SEDATION)
		Say(rag, "pain", 80)
		Thrash(rag, 0.8, 4)
		return rag
	end
	rag = Body(ply)
	if not rag then return end

	local active = ply:GetActiveWeapon()
	local kit = { armor = ply:Armor(), ammo = ply:GetAmmo(), weapons = {}, active = IsValid(active) and active:GetClass() }
	for _, wep in ipairs(ply:GetWeapons()) do
		kit.weapons[#kit.weapons + 1] = { class = wep:GetClass(), clip1 = wep:Clip1(), clip2 = wep:Clip2() }
	end
	ply.EvilCrawlerKit = kit
	ply:StripWeapons()
	ply:Spectate(OBS_MODE_CHASE)
	ply:SpectateEntity(IsValid(holder) and holder or rag)

	rag:SetNW2Entity(EvilCrawler.OWNER_VAR, ply)
	rag:SetNW2Vector(EvilCrawler.COLOR_VAR, ply:GetPlayerColor())
	Hold(rag, ply, holder, TAKEN_SEDATION)

	Say(rag, "pain", 80)
	Thrash(rag, 0.8, 4)
	return rag
end

function Victim.Alive(rag)
	return IsValid(rag) and IsValid(rag.EvilCrawlerOwner)
end

function Victim.Fighting(rag)
	return Victim.Alive(rag) and rag.Sedation < 1
end

local function Lucid(rag)
	return 1 - rag.Sedation
end

local function Watched(rag)
	local holder = rag.EvilCrawlerHolder
	if IsValid(holder) and holder:GetVictim() == rag then return holder end
	return rag
end

function Victim.Kill(rag, attacker)
	local npc = rag.EvilCrawlerOwner
	if not IsValid(npc) or Godly(npc) then return end
	Victim.bodies[rag] = nil
	rag.EvilCrawlerOwner = nil

	if Lucid(rag) > 0.3 then Say(rag, "die", 75) end
	Thrash(rag, 1.5, 4)

	npc.EvilCrawlerBody = nil
	if EvilCrawler.Fake(npc) == rag then
		Victim.Slay(npc)
		return
	end
	if npc:IsPlayer() then
		npc:KillSilent()
		npc:AddDeaths(1)
		hook.Run("PlayerDeath", npc, attacker, attacker)
		npc:Spectate(OBS_MODE_CHASE)
		npc:SpectateEntity(Watched(rag))
		return
	end
	npc:SetHealth(0)
	hook.Run("OnNPCKilled", npc, attacker, attacker)
	npc:Remove()
end

function Victim.Hurt(rag, amount, attacker)
	local npc = rag.EvilCrawlerOwner
	if not IsValid(npc) or Godly(npc) then return end
	npc:SetHealth(npc:Health() - amount)
	if npc:Health() <= 0 then Victim.Kill(rag, attacker) end
end

function Victim.Wound(rag, attacker, at)
	local npc = rag.EvilCrawlerOwner
	if not IsValid(npc) or Godly(npc) then return end
	if EvilCrawler.Fake(npc) == rag then
		local dmg = DamageInfo()
		dmg:SetDamage(100 * math.Rand(WOUND[1], WOUND[2]))
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(attacker)
		dmg:SetDamagePosition(at + attacker.BodyUp * 16)
		dmg:SetDamageForce(attacker.BodyUp * -1000)
		rag:TakeDamageInfo(dmg)
		return
	end
	Victim.Hurt(rag, math.max(1, npc:GetMaxHealth()) * math.Rand(WOUND[1], WOUND[2]), attacker)
end

function Victim.Pierced(rag)
	Victim.Opened(rag)
	local npc = rag.EvilCrawlerOwner
	if not IsValid(npc) then return end
	local lucid = Lucid(rag)
	if lucid <= 0 then
		Thrash(rag, 0.4, 1)
		if math.random() < 0.15 then Say(rag, "die", 55) end
		return
	end
	if npc:Health() / math.max(1, npc:GetMaxHealth()) > FADING then
		Say(rag, "pain", 95)
	elseif math.random() < 0.5 then
		Say(rag, "die", 65)
	end
	Thrash(rag, 1.2 * lucid, 3)
end

function Victim.Maimed(rag, bone, attacker)
	if not Victim.Alive(rag) then return end
	if bone == "ValveBiped.Bip01_Head1" then
		rag.Sedation = 1
		Victim.Kill(rag, attacker)
		return
	end
	rag.Maimed = true
end

local function StandingSpot(npc, rag)
	local pos = rag:GetPos()
	local mins, maxs, mask = npc:OBBMins(), npc:OBBMaxs(), MASK_NPCSOLID
	if npc:IsPlayer() then
		mins, maxs = npc:GetHull()
		mask = MASK_PLAYERSOLID
	end
	for _, offset in ipairs(STANDING_OFFSETS) do
		local from = pos + offset + Vector(0, 0, 8)
		local tr = util.TraceHull({
			start = from, endpos = from - Vector(0, 0, 96),
			mins = mins, maxs = maxs, mask = mask, filter = { npc, rag },
		})
		if not tr.StartSolid then return tr.HitPos end
	end
	return pos
end

local function PlayerGetUp(rag, ply)
	Victim.bodies[rag] = nil
	rag.EvilCrawlerOwner = nil
	ply.EvilCrawlerBody = nil
	local spot, health, kit = StandingSpot(ply, rag), ply:Health(), ply.EvilCrawlerKit or {}
	local god = ply:HasGodMode()
	ply.EvilCrawlerKit = nil

	ply.EvilCrawlerGettingUp = true
	ply:UnSpectate()
	ply:Spawn()
	ply.EvilCrawlerGettingUp = nil
	if god then ply:GodEnable() end

	ply:SetPos(spot)
	ply:SetHealth(health)
	ply:SetArmor(kit.armor or 0)
	ply:StripWeapons()
	ply:RemoveAllAmmo()
	for _, w in ipairs(kit.weapons or {}) do
		local wep = ply:Give(w.class, true)
		if IsValid(wep) then
			wep:SetClip1(w.clip1)
			wep:SetClip2(w.clip2)
		end
	end
	for id, count in pairs(kit.ammo or {}) do ply:SetAmmo(count, id) end
	if kit.active then ply:SelectWeapon(kit.active) end
	Evil.Scare(ply, ESCAPE_FEAR)
end

local function GetUp(rag, npc)
	if EvilCrawler.Fake(npc) == rag then
		Victim.bodies[rag] = nil
		rag.EvilCrawlerOwner = nil
		npc.EvilCrawlerBody = nil
		Evil.Scare(npc, ESCAPE_FEAR)
		return
	end
	if npc:IsPlayer() then
		PlayerGetUp(rag, npc)
		rag:Remove()
		return
	end
	Victim.bodies[rag] = nil
	npc:SetPos(StandingSpot(npc, rag))
	npc:SetAngles(Angle(0, math.Rand(0, 360), 0))
	npc:SetColor(rag:GetColor())
	npc:RemoveEFlags(EFL_NO_THINK_FUNCTION)
	npc:SetMoveType(npc.EvilCrawlerMoveType or MOVETYPE_STEP)
	npc:SetNotSolid(false)
	npc:SetNoDraw(false)
	npc:DrawShadow(true)
	if not npc.EvilCrawlerHadNoTarget then npc:RemoveFlags(FL_NOTARGET) end
	if not isfunction(npc.PauseAttacks) then npc.PauseAttacks = npc.EvilCrawlerPaused end
	npc.EvilCrawlerVictim = nil
	npc.EvilCrawlerBody = nil
	Evil.Scare(npc, ESCAPE_FEAR)
	rag.EvilCrawlerOwner = nil
	rag:Remove()
	if npc:IsNPC() then
		npc:SetSchedule(SCHED_RUN_RANDOM)
	else
		npc.BehaveUpdate, npc.Think = nil, nil
	end
end

function Victim.Spare(rag)
	local holder = rag.EvilCrawlerHolder
	if IsValid(holder) and holder:GetVictim() == rag then holder:Release() end
	local owner = rag.EvilCrawlerOwner
	if IsValid(owner) then GetUp(rag, owner) end
end

function Victim.Shrug(npc)
	npc.EvilCrawlerShrugAt = CurTime()
end

function Victim.Shrugged(npc)
	return CurTime() - (npc.EvilCrawlerShrugAt or -math.huge) < SHRUG_MEMORY
end

function Victim.Shrugs(npc, attacker)
	if Victim.Shrugged(npc) then return true end
	local before = npc:Health()
	if npc:IsPlayer() or before <= 0 then return false end
	local dmg = DamageInfo()
	dmg:SetDamage(SHRUG_TEST)
	dmg:SetDamageType(DMG_SLASH)
	dmg:SetAttacker(attacker)
	dmg:SetInflictor(attacker)
	dmg:SetDamagePosition(npc:WorldSpaceCenter())
	npc:TakeDamageInfo(dmg)
	if not IsValid(npc) or not EvilCrawler.Living(npc) or npc:Health() < before then return false end
	Victim.Shrug(npc)
	return true
end

function Victim.Spared(rag)
	local owner = rag.EvilCrawlerOwner
	return IsValid(owner) and Godly(owner)
end

local function Update(rag, now)
	local npc = rag.EvilCrawlerOwner
	if not IsValid(npc) then
		Victim.bodies[rag] = nil
		return
	end
	if Godly(npc) then
		Victim.Spare(rag)
		return
	end
	local fake = EvilCrawler.Fake(npc) == rag
	if not fake then
		npc:SetPos(rag:GetPos())
		if npc:IsPlayer() then
			local watch = Watched(rag)
			if npc:GetObserverTarget() ~= watch then npc:SpectateEntity(watch) end
		end
	end

	local holder = rag.EvilCrawlerHolder
	local held = IsValid(holder) and holder:GetVictim() == rag
	local eaten = held and holder:GetAct() == EvilCrawler.ACT_FEED
	if held then rag.LetGoAt = nil else rag.LetGoAt = rag.LetGoAt or now end

	local dt = FrameTime()
	if held then
		rag.Sedation = math.min(1, rag.Sedation + dt * holder:Wits() / math.max(0.1, EvilCrawler.Setting("sedate_time")))
	else
		rag.Sedation = math.max(0, rag.Sedation - dt / WEAR_OFF)
	end
	local organism = fake and EvilCrawler.Own(npc, "organism")
	if istable(organism) and organism.otrub then rag.Sedation = 1 end
	local lucid = Lucid(rag)
	local bleeding = rag.Maimed and not fake

	if bleeding then
		rag.Bled = (rag.Bled or 0) + FrameTime()
		if rag.Bled >= 0.5 then
			Victim.Hurt(rag, npc:GetMaxHealth() * BLEED * rag.Bled, game.GetWorld())
			rag.Bled = 0
			if not Victim.Alive(rag) then return end
		end
	end

	if not held then
		if bleeding then
			if lucid < 0.15 then return end
			if now >= (rag.NextThrash or 0) then
				local life = math.Clamp(npc:Health() / math.max(1, npc:GetMaxHealth()), 0.1, 1)
				rag.NextThrash = now + math.Rand(0.5, 1.5) / (life * lucid)
				Thrash(rag, life * lucid * 0.6, 1)
			end
			if now >= rag.NextCry then
				rag.NextCry = now + math.Rand(2.5, 5)
				Say(rag, "die", 70)
			end
			return
		end
		local root = rag:GetPhysicsObject()
		local still = not IsValid(root) or root:GetVelocity():Length() < SETTLED
		if still and rag.Sedation < GETUP_SEDATION and now - rag.LetGoAt > GETUP_TIME then GetUp(rag, npc) end
		return
	end

	if lucid > 0 and now >= (rag.NextNip or 0) then
		rag.NextNip = now + math.Rand(0.5, 1.1)
		Nip(rag)
	end

	if lucid < 0.15 then return end
	local life = math.Clamp(npc:Health() / math.max(1, npc:GetMaxHealth()), 0.2, 1)
	if now >= (rag.NextThrash or 0) then
		rag.NextThrash = now + math.Rand(0.12, 0.4) / (life * lucid)
		Thrash(rag, life * lucid, math.random(1, 2))
	end
	if not eaten and now >= rag.NextCry then
		rag.NextCry = now + math.Rand(1.8, 3.4) * (1 + 1.5 * rag.Sedation)
		if lucid > 0.6 then
			Say(rag, "help")
		elseif lucid > 0.3 then
			Say(rag, "pain", 78)
		else
			Say(rag, "die", 62)
		end
	end
end

hook.Add("Think", "EvilCrawlerVictims", function()
	local now = CurTime()
	for rag in pairs(Victim.bodies) do
		if IsValid(rag) then Update(rag, now) else Victim.bodies[rag] = nil end
	end
end)

hook.Add("EntityTakeDamage", "EvilCrawlerVictims", function(ent, dmg)
	if ent.EvilCrawlerBody and ent.EvilCrawlerBody ~= EvilCrawler.Own(ent, "FakeRagdoll") then return true end
	if not Victim.Alive(ent) or EvilCrawler.Faker(ent) or dmg:IsDamageType(DMG_CRUSH) then return end
	local attacker = dmg:GetAttacker()
	if IsValid(attacker) and (attacker:IsPlayer() or EvilCrawler.Creature(attacker)) then
		Victim.Hurt(ent, dmg:GetDamage(), attacker)
	end
end)

hook.Add("EntityRemoved", "EvilCrawlerVictims", function(ent)
	local owner = ent.EvilCrawlerOwner
	Victim.bodies[ent] = nil
	if not IsValid(owner) then return end
	owner.EvilCrawlerBody = nil
	if not owner:IsPlayer() then
		owner:Remove()
	elseif owner:Alive() and EvilCrawler.Own(owner, "FakeRagdoll") ~= ent then
		if owner:HasGodMode() then PlayerGetUp(ent, owner) else owner:KillSilent() end
	end
end)

local function Disown(ply)
	local rag = ply.EvilCrawlerBody
	ply.EvilCrawlerBody = nil
	if IsValid(rag) then
		rag.EvilCrawlerOwner = nil
		Victim.bodies[rag] = nil
	end
end
hook.Add("PostPlayerDeath", "EvilCrawlerVictims", Disown)
hook.Add("PlayerSpawn", "EvilCrawlerVictims", function(ply)
	if ply.EvilCrawlerGettingUp then return end
	Disown(ply)
	for _, crawler in ipairs(ents.FindByClass("evil_crawler")) do
		if crawler:GetVictim() == ply then crawler:Release() end
	end
	ply.EvilCrawlerVictim = nil
end)

hook.Add("Should Fake Up", "EvilCrawlerVictims", function(ply)
	if EvilCrawler.Holder(ply) or ply.EvilCrawlerBody then return true end
end)

hook.Add("CanControlFake", "EvilCrawlerVictims", function(ply, rag)
	if EvilCrawler.Holder(ply) or Victim.bodies[rag] and rag.Sedation >= 1 then return true end
end)
