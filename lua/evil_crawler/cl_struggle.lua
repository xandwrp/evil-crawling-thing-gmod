EvilCrawler = EvilCrawler or {}

local ACT_GRAPPLE = EvilCrawler.ACT_GRAPPLE
local View = Evil and Evil.View or function(name, _, calc) hook.Add("CalcView", name, calc) end

local KEY_SIZE = { 150, 44 }
local KEY_Y = 0.7
local BAR_SIZE = { 220, 6 }
local BAR_GAP = 14
local PULSE_TIME = 0.12
local VIGNETTE_STEPS = 24
local VIGNETTE_DEPTH = 0.45
local WATCHING = 0.55
local PILOTING = 0.2
local EXIT_Y = 0.88
local EXIT_SIZE = { 64, 34 }
local ORBIT_DISTANCE = 3.6
local ORBIT_DRIFT = 7
local ORBIT_PITCH = { 5, 75 }
local ORBIT_TILT = 25
local FOCUS_RATE = 6
local UP_RATE = 3
local PILOT_BACK = 3.4
local PILOT_RISE = 1.3
local PILOT_FOCUS = 14
local PILOT_UP = 4
local PILOT_PITCH = 80
local CAM_HULL = Vector(4, 4, 4)

local BONE = Color(170, 160, 145)
local KEY_BG = Color(10, 8, 9, 200)
local BAR_BG = Color(255, 255, 255, 25)

local cv_prompt = CreateClientConVar("evil_crawler_struggle_prompt", "1", true, false, "Show the key to mash when a crawler grabs you")

surface.CreateFont("EvilCrawlerKey", { font = "Roboto", size = 26, weight = 800 })

local shownFree = 0

function EvilCrawler.Devoured(ply)
	if ply:GetObserverMode() == OBS_MODE_NONE then return end
	local target = ply:GetObserverTarget()
	if not IsValid(target) then return end
	if target:GetClass() == "evil_crawler" or target:GetNW2Entity(EvilCrawler.OWNER_VAR) == ply then return target end
end

local function Piloting(ply, target)
	return target:GetClass() == "evil_crawler" and target:GetPilot() == ply
end

local function Pressure()
	local ply = LocalPlayer()
	if not IsValid(ply) then return 0 end

	local holder = EvilCrawler.Holder(ply)
	if holder then
		if holder:GetAct() ~= ACT_GRAPPLE then return 0, holder end
		return math.Clamp((CurTime() - holder:GetActStart()) / EvilCrawler.StruggleTime(), 0, 1), holder
	end

	local target = EvilCrawler.Devoured(ply)
	if target then return Piloting(ply, target) and PILOTING or WATCHING end
	return 0
end

local function Vignette(k)
	local w, h = ScrW(), ScrH()
	local step = h * VIGNETTE_DEPTH * k / VIGNETTE_STEPS
	if step < 0.5 then return end
	for i = 0, VIGNETTE_STEPS - 1 do
		local a = 235 * k * (1 - i / VIGNETTE_STEPS) ^ 1.5
		surface.SetDrawColor(0, 0, 0, a)
		local inset = i * step
		surface.DrawRect(inset, inset, w - inset * 2, step)
		surface.DrawRect(inset, h - inset - step, w - inset * 2, step)
		surface.DrawRect(inset, inset + step, step, h - inset * 2 - step * 2)
		surface.DrawRect(w - inset - step, inset + step, step, h - inset * 2 - step * 2)
	end
end

local letGoSince, letGoSent

local function LetGoHeld()
	local key = input.LookupBinding("+use") or "e"
	local code = input.GetKeyCode(key)
	if not (code and code > 0 and input.IsButtonDown(code) and not vgui.CursorVisible()) then
		letGoSince, letGoSent = nil, nil
		return 0, key
	end
	letGoSince = letGoSince or RealTime()
	local held = math.Clamp((RealTime() - letGoSince) / EvilCrawler.LET_GO_TIME, 0, 1)
	if held >= 1 and not letGoSent then
		letGoSent = true
		net.Start("EvilCrawlerLetGo")
		net.SendToServer()
	end
	return held, key
end

local function LetGoPrompt()
	local ply = LocalPlayer()
	if not IsValid(ply) or not EvilCrawler.Inside(ply) then
		letGoSince, letGoSent = nil, nil
		return
	end
	local held, key = LetGoHeld()
	if not cv_prompt:GetBool() then return end
	local kw, kh = EXIT_SIZE[1], EXIT_SIZE[2]
	local cx, cy = ScrW() * 0.5, ScrH() * EXIT_Y
	local x, y = cx - kw * 0.5, cy - kh * 0.5
	draw.RoundedBox(6, x, y, kw, kh, KEY_BG)
	surface.SetDrawColor(BAR_BG)
	surface.DrawRect(x + 2, y + 2, kw - 4, kh - 4)
	surface.SetDrawColor(BONE.r, BONE.g, BONE.b, 90)
	surface.DrawRect(x + 2, y + 2, (kw - 4) * held, kh - 4)
	surface.SetDrawColor(BONE)
	surface.DrawOutlinedRect(x, y, kw, kh, 2)
	draw.SimpleText(key:upper(), "EvilCrawlerKey", cx, cy, BONE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "EvilCrawlerStruggle", function()
	local k, holder = Pressure()
	if k > 0 then Vignette(k) end
	LetGoPrompt()
	if not holder then
		shownFree = 0
		return
	end
	if not cv_prompt:GetBool() then return end

	local ply = LocalPlayer()
	local free = ply:GetNW2Float(EvilCrawler.FREE_VAR, 0)
	shownFree = Lerp(math.min(1, FrameTime() * 15), shownFree, free)
	local pulse = math.Clamp(1 - (RealTime() - (ply.EvilCrawlerPressed or 0)) / PULSE_TIME, 0, 1)
	local shake = 1 + 3 * k

	local cx = ScrW() * 0.5 + math.Rand(-shake, shake)
	local cy = ScrH() * KEY_Y + math.Rand(-shake, shake) + 3 * pulse
	local kw, kh = KEY_SIZE[1], KEY_SIZE[2]
	local x, y = cx - kw * 0.5, cy - kh * 0.5

	draw.RoundedBox(6, x, y, kw, kh, KEY_BG)
	local lit = Lerp(pulse, 0, 85)
	local c = Color(math.min(255, BONE.r + lit), math.min(255, BONE.g + lit), math.min(255, BONE.b + lit))
	surface.SetDrawColor(c)
	surface.DrawOutlinedRect(x, y, kw, kh, 2)
	local key = input.LookupBinding("+jump") or "space"
	draw.SimpleText(key:upper(), "EvilCrawlerKey", cx, cy, c, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	local bw, bh = BAR_SIZE[1], BAR_SIZE[2]
	local bx, by = cx - bw * 0.5, y + kh + BAR_GAP
	surface.SetDrawColor(BAR_BG)
	surface.DrawRect(bx, by, bw, bh)
	surface.SetDrawColor(BONE)
	surface.DrawRect(bx, by, bw * math.Clamp(shownFree, 0, 1), bh)
end)

hook.Add("RenderScreenspaceEffects", "EvilCrawlerStruggle", function()
	local k = Pressure()
	if k <= 0 then return end
	DrawColorModify({
		["$pp_colour_addr"] = 0.06 * k,
		["$pp_colour_addg"] = 0,
		["$pp_colour_addb"] = 0,
		["$pp_colour_brightness"] = -0.12 * k,
		["$pp_colour_contrast"] = 1 + 0.1 * k,
		["$pp_colour_colour"] = 1 - 0.7 * k,
		["$pp_colour_mulr"] = 0,
		["$pp_colour_mulg"] = 0,
		["$pp_colour_mulb"] = 0,
	})
	DrawMotionBlur(0.15, 0.5 * k, 0.01)
end)

hook.Add("HUDShouldDraw", "EvilCrawlerStruggle", function(name)
	if name == "CHudCrosshair" and IsValid(LocalPlayer()) and EvilCrawler.Holder(LocalPlayer()) then return false end
end)

hook.Add("EntityNetworkedVarChanged", "EvilCrawlerStruggle", function(ent, name, _, value)
	if name ~= EvilCrawler.COLOR_VAR then return end
	ent.GetPlayerColor = function() return value end
end)

local pilotAng, pilotFocus, pilotUp

local function Driving()
	local ply = LocalPlayer()
	local target = IsValid(ply) and EvilCrawler.Devoured(ply)
	if target and Piloting(ply, target) then return target end
	pilotAng, pilotFocus, pilotUp = nil, nil, nil
end

hook.Add("InputMouseApply", "EvilCrawlerPilot", function(cmd, x, y)
	local crawler = Driving()
	if not crawler then return end
	pilotAng = pilotAng or Angle(15, crawler:GetAngles().y, 0)
	pilotAng.p = math.Clamp(pilotAng.p + y * GetConVar("m_pitch"):GetFloat(), -PILOT_PITCH, PILOT_PITCH)
	pilotAng.y = math.NormalizeAngle(pilotAng.y - x * GetConVar("m_yaw"):GetFloat())
	cmd:SetViewAngles(pilotAng)
	return true
end)

hook.Add("CreateMove", "EvilCrawlerPilot", function(cmd)
	if pilotAng and Driving() then cmd:SetViewAngles(pilotAng) end
end)

local function PilotView(crawler, fov)
	pilotAng = pilotAng or Angle(15, crawler:GetAngles().y, 0)
	local dt = FrameTime()
	local want, wantUp = crawler:GetPos(), crawler:GetUp()
	pilotFocus = pilotFocus and LerpVector(math.min(1, dt * PILOT_FOCUS), pilotFocus, want) or want
	pilotUp = pilotUp and LerpVector(math.min(1, dt * PILOT_UP), pilotUp, wantUp):GetNormalized() or wantUp

	local h = crawler.BodyHeight or 40
	local from = pilotFocus + pilotUp * (h * 0.5)
	local tr = util.TraceHull({
		start = from, endpos = pilotFocus + pilotUp * (h * PILOT_RISE) - pilotAng:Forward() * (h * PILOT_BACK),
		mins = -CAM_HULL, maxs = CAM_HULL, mask = MASK_SOLID_BRUSHONLY,
	})
	return { origin = tr.HitPos, angles = Angle(pilotAng.p, pilotAng.y, 0), fov = fov, drawviewer = false }
end

hook.Add("HUDPaint", "EvilCrawlerPilot", function()
	if not Driving() then return end
	surface.SetDrawColor(BONE.r, BONE.g, BONE.b, 160)
	surface.DrawRect(ScrW() * 0.5 - 2, ScrH() * 0.5 - 2, 4, 4)
end)

local focus, orbitUp

local function Watching(ply)
	return EvilCrawler.Devoured(ply) ~= nil
end

local function Unwatch()
	focus, orbitUp = nil, nil
end

View("EvilCrawlerDevoured", Watching, function(ply, _, angles, fov)
	local target = EvilCrawler.Devoured(ply)
	if not target then
		focus, orbitUp = nil, nil
		return
	end
	local pilot = Driving()
	if pilot then return PilotView(pilot, fov) end

	local crawler = target:GetClass() == "evil_crawler"
	local want = crawler and target:GetPos() or target:WorldSpaceCenter()
	local wantUp = crawler and target:GetUp() or vector_up
	local dt = FrameTime()
	focus = focus and LerpVector(math.min(1, dt * FOCUS_RATE), focus, want) or want
	orbitUp = orbitUp and LerpVector(math.min(1, dt * UP_RATE), orbitUp, wantUp):GetNormalized() or wantUp

	local yaw = math.rad(angles.y + 180 + RealTime() * ORBIT_DRIFT)
	local around = Vector(math.cos(yaw), math.sin(yaw), 0)
	around = around - orbitUp * around:Dot(orbitUp)
	if around:LengthSqr() < 1e-4 then around = orbitUp:Angle():Right() end
	around:Normalize()
	local pitch = math.rad(math.Clamp(angles.p + ORBIT_TILT, ORBIT_PITCH[1], ORBIT_PITCH[2]))
	local out = around * math.cos(pitch) + orbitUp * math.sin(pitch)

	local reach = (crawler and target.BodyHeight or 40) * ORBIT_DISTANCE
	local tr = util.TraceLine({ start = focus, endpos = focus + out * reach, mask = MASK_SOLID_BRUSHONLY })
	local eye = tr.HitPos + tr.HitNormal * 6

	return { origin = eye, angles = (focus - eye):Angle(), fov = fov, drawviewer = false }
end, Unwatch)
