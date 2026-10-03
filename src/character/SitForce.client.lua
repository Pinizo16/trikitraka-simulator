-- SitForce.client.lua (StarterCharacterScripts)
-- script.Parent = Character
local char = script.Parent
local hum = char:WaitForChild("Humanoid", 10)
if not hum then
	warn("[SitForce] sin Humanoid")
	return
end

local SIT_ID = "rbxassetid://2506281703"
local track = nil

local function getAnimator()
	local a = hum:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = hum
	end
	return a
end

local function stop()
	if track then
		pcall(function() track:Stop(0) end)
		track = nil
	end
end

local function play()
	if track and track.IsPlaying then return end
	stop()
	local anim = Instance.new("Animation")
	anim.AnimationId = SIT_ID
	local ok, t = pcall(function()
		return getAnimator():LoadAnimation(anim)
	end)
	if not ok or not t then
		warn("[SitForce] LoadAnimation falló:", t)
		return
	end
	t.Looped = true
	t.Priority = Enum.AnimationPriority.Action4
	t:Play(0.05)
	track = t
	print("[SitForce] PLAY len=", t.Length, "playing=", t.IsPlaying)
end

task.spawn(function()
	print("[SitForce] activo en", char.Name)
	while char.Parent do
		if char:GetAttribute("Anclado") == true then
			if hum.Sit then hum.Sit = false end
			play()
		else
			stop()
		end
		task.wait(0.35)
	end
	stop()
end)
