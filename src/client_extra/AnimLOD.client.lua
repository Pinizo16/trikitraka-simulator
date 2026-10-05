-- AnimLOD.client.lua
-- Animaciones de bots / anclados ajenos SOLO si están cerca (Config.ANIM_LOD).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local Config
do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
	end)
	Config = ok and mod or {}
end

local lod = Config.ANIM_LOD or {}
local TICK = lod.TICK or 0.35
local WALK_ID = lod.WALK or "rbxassetid://507777826"
local IDLE_ID = lod.IDLE or "rbxassetid://507766388"
local SIT_ID = lod.SIT or "rbxassetid://81091084331411"
local SIT_FB = lod.SIT_FALLBACK or "rbxassetid://2506281703"
local folderName = (Config.BOTS_AMBULANTES and Config.BOTS_AMBULANTES.CARPETA) or "BotsAmbulantes"

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function isTablet()
	if not UserInputService.TouchEnabled then return false end
	local cam = Workspace.CurrentCamera
	if not cam then return false end
	return math.min(cam.ViewportSize.X, cam.ViewportSize.Y) >= 700
end

local function maxDist()
	if isTablet() then
		return tonumber(lod.DIST_TABLET) or 60
	elseif isMobile() then
		return tonumber(lod.DIST_MOBILE) or 45
	end
	return tonumber(lod.DIST_PC) or 90
end

local tracks = {} -- [model] = { walk, idle, sit, mode }

local function getHRP(model)
	if not model then return nil end
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function getAnimator(hum)
	local a = hum:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = hum
	end
	return a
end

local function loadTrack(animator, id, priority)
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not track then return nil end
	track.Looped = true
	track.Priority = priority or Enum.AnimationPriority.Movement
	return track
end

local function stopEverythingOn(model)
	local hum = model and model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
			pcall(function() tr:Stop(0) end)
		end
	end
	local t = tracks[model]
	if t then
		if t.walk then pcall(function() t.walk:Stop(0) end) end
		if t.idle then pcall(function() t.idle:Stop(0) end) end
		if t.sit then pcall(function() t.sit:Stop(0) end) end
		t.mode = "none"
	end
end

local function ensureBotTracks(model)
	local t = tracks[model]
	if t and t.walk then return t end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local animator = getAnimator(hum)
	local walk = loadTrack(animator, WALK_ID, Enum.AnimationPriority.Movement)
		or loadTrack(animator, "rbxassetid://180426354", Enum.AnimationPriority.Movement)
	local idle = loadTrack(animator, IDLE_ID, Enum.AnimationPriority.Idle)
	t = tracks[model] or {}
	t.walk, t.idle = walk, idle
	t.mode = t.mode or "none"
	tracks[model] = t
	return t
end

local function ensureSitTracks(model)
	local t = tracks[model]
	if t and t.sit then return t end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return nil end
	local animator = getAnimator(hum)
	local sit = loadTrack(animator, SIT_ID, Enum.AnimationPriority.Action4)
		or loadTrack(animator, SIT_FB, Enum.AnimationPriority.Action4)
	t = tracks[model] or {}
	t.sit = sit
	t.mode = t.mode or "none"
	tracks[model] = t
	return t
end

local function playBot(model, moving)
	local t = ensureBotTracks(model)
	if not t then return end
	if moving then
		if t.idle and t.idle.IsPlaying then pcall(function() t.idle:Stop(0.1) end) end
		if t.walk and not t.walk.IsPlaying then pcall(function() t.walk:Play(0.1) end) end
		t.mode = "walk"
	else
		if t.walk and t.walk.IsPlaying then pcall(function() t.walk:Stop(0.1) end) end
		if t.idle and not t.idle.IsPlaying then pcall(function() t.idle:Play(0.1) end) end
		t.mode = "idle"
	end
end

local function playSit(model)
	local t = ensureSitTracks(model)
	if not t or not t.sit then return end
	if t.walk then pcall(function() t.walk:Stop(0.08) end) end
	if t.idle then pcall(function() t.idle:Stop(0.08) end) end
	if not t.sit.IsPlaying then pcall(function() t.sit:Play(0.1) end) end
	t.mode = "sit"
end

local function isBotModel(model)
	if not model or not model:IsA("Model") then return false end
	if model:GetAttribute("EsBotAmbulante") then return true end
	local n = string.lower(model.Name)
	return string.sub(n, 1, 3) == "bot" or string.find(n, "bot_", 1, true) ~= nil
end

local function collectBots()
	local list = {}
	for _, ch in ipairs(Workspace:GetChildren()) do
		if isBotModel(ch) then
			table.insert(list, ch)
		elseif ch.Name == folderName and (ch:IsA("Folder") or ch:IsA("Model")) then
			for _, m in ipairs(ch:GetChildren()) do
				if m:IsA("Model") then
					table.insert(list, m)
				end
			end
		end
	end
	return list
end

local function localRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

print(string.format(
	"[AnimLOD] dist PC=%.0f móvil=%.0f tablet=%.0f | plataforma efectiva dist=%.0f",
	lod.DIST_PC or 90, lod.DIST_MOBILE or 45, lod.DIST_TABLET or 60, maxDist()
))

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < TICK then return end
	acc = 0

	local root = localRoot()
	if not root then return end
	local origin = root.Position
	local distMax = maxDist()
	local distMaxSq = distMax * distMax

	for _, model in ipairs(collectBots()) do
		local hrp = getHRP(model)
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			local d = hrp.Position - origin
			local distSq = d.X * d.X + d.Y * d.Y + d.Z * d.Z
			if distSq > distMaxSq then
				-- Fuera de rango: cortar TODAS las tracks (incl. residuales)
				stopEverythingOn(model)
			else
				local vel = hrp.AssemblyLinearVelocity
				local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
				local moving = speed > 0.7 or hum.MoveDirection.Magnitude > 0.05
				playBot(model, moving)
			end
		end
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = hrp.Position - origin
				local distSq = d.X * d.X + d.Y * d.Y + d.Z * d.Z
				local anclado = char:GetAttribute("Anclado") == true
				if anclado and distSq <= distMaxSq then
					playSit(char)
				elseif tracks[char] and tracks[char].mode == "sit" then
					stopEverythingOn(char)
				elseif distSq > distMaxSq and anclado then
					stopEverythingOn(char)
				end
			end
		end
	end
end)

Workspace.ChildRemoved:Connect(function(obj)
	if tracks[obj] then
		stopEverythingOn(obj)
		tracks[obj] = nil
	end
end)

print("[AnimLOD] culling activo — si DIST_PC=0 no deberías ver anim de bots lejos")

-- Ok /