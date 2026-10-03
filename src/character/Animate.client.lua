--[[
	Animate + anclaje sit
	StarterCharacterScripts → se clona en cada Character
]]
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")

-- PlayEmote requerido por Roblox
do
	local pe = script:FindFirstChild("PlayEmote")
	if not pe then
		pe = Instance.new("BindableFunction")
		pe.Name = "PlayEmote"
		pe.Parent = script
	end
	pe.OnInvoke = function()
		return false
	end
end

local animIds = {
	idle = "rbxassetid://507766388",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
	sit = "rbxassetid://81091084331411", -- la ia descubrio que estaba usando una animacion de r6, esta es la nueva
}

local tracks = {}
local current = nil
local pose = "Standing"
local anclado = false

local function getAnimator()
	local a = Humanoid:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = Humanoid
	end
	return a
end

local function loadTrack(name)
	if tracks[name] then return tracks[name] end
	local anim = Instance.new("Animation")
	anim.AnimationId = animIds[name]
	local ok, track = pcall(function()
		return getAnimator():LoadAnimation(anim)
	end)
	if not ok or not track then
		warn("[Animate] no cargó", name, track)
		return nil
	end
	track.Looped = (name ~= "jump")
	track.Priority = if name == "sit" then Enum.AnimationPriority.Action4 else Enum.AnimationPriority.Core
	tracks[name] = track
	-- Diagnóstico: Length se llena async; si queda en 0, el asset
	-- no cargó (permisos) o fue creado en otro rig (R6 vs R15)
	task.delay(3, function()
		if track.Length == 0 then
			warn("[Animate] ADVERTENCIA:", name, animIds[name], "Length=0 → sin permiso o rig incompatible")
		end
	end)
	return track
end

local function play(name, fade)
	if current == name and tracks[name] and tracks[name].IsPlaying then
		return
	end
	if current and tracks[current] then
		pcall(function() tracks[current]:Stop(fade or 0.15) end)
	end
	local t = loadTrack(name)
	if t then
		t:Play(fade or 0.15)
		current = name
	end
end

local function setAnclado(v)
	anclado = (v == true)
	if anclado then
		pose = "Seated"
		Humanoid.Sit = false
		play("sit", 0.1)
		print("[Animate] ANCLADO → sit")
	else
		if pose == "Seated" then
			pose = "Standing"
			play("idle", 0.2)
			print("[Animate] DESANCLADO → idle")
		end
	end
end

Character:GetAttributeChangedSignal("Anclado"):Connect(function()
	setAnclado(Character:GetAttribute("Anclado"))
end)
if Character:GetAttribute("Anclado") then
	setAnclado(true)
end

Humanoid.Running:Connect(function(speed)
	if anclado then
		play("sit", 0.1)
		return
	end
	if speed > 0.5 then
		pose = "Running"
		play("walk", 0.2)
		local t = tracks.walk
		if t then
			pcall(function() t:AdjustSpeed(math.clamp(speed / 16, 0.5, 2)) end)
		end
	else
		-- Sentado en asiento: Running(0) se dispara al sentarse,
		-- mantener sit en vez de pasar a idle
		if Humanoid.Sit or Humanoid.SeatPart then
			pose = "Seated"
			play("sit", 0.2)
			return
		end
		pose = "Standing"
		play("idle", 0.2)
	end
end)

Humanoid.Jumping:Connect(function()
	if anclado then return end
	pose = "Jumping"
	play("jump", 0.1)
end)

Humanoid.FreeFalling:Connect(function()
	if anclado then return end
	pose = "FreeFall"
	play("fall", 0.2)
end)

Humanoid.Seated:Connect(function(active)
	if anclado then
		play("sit", 0.1)
		return
	end
	if active then
		pose = "Seated"
		play("sit", 0.2)
	end
end)

task.spawn(function()
	print("[Animate] listo en", Character.Name, "rig=", Humanoid.RigType.Name)
	play("idle", 0.1)
	while Character.Parent do
		if anclado or Character:GetAttribute("Anclado") == true then
			anclado = true
			if not (tracks.sit and tracks.sit.IsPlaying) then
				play("sit", 0.05)
			end
		end
		task.wait(0.3)
	end
end)
