-- AnclajeAnim.client.lua
-- Fuerza sit en bucle mientras Anclado (Animate/Weld no pueden apagarlo)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local SIT_IDS = {
	"rbxassetid://2506281703",
	"http://www.roblox.com/asset/?id=2506281703",
}

local track = nil

local function stopSit()
	if track then
		pcall(function() track:Stop(0) end)
		track = nil
	end
end

local function playSit(char)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	if track and track.IsPlaying then
		return
	end
	stopSit()
	for _, id in ipairs(SIT_IDS) do
		local anim = Instance.new("Animation")
		anim.AnimationId = id
		local ok, t = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if ok and t then
			t.Looped = true
			t.Priority = Enum.AnimationPriority.Action4
			t:Play(0.05)
			task.wait()
			if t.IsPlaying then
				track = t
				print("[AnclajeAnim] SIT OK id=", id, "len=", t.Length, "playing=", t.IsPlaying)
				return
			end
		else
			warn("[AnclajeAnim] load fail", id, t)
		end
	end
	warn("[AnclajeAnim] NINGUNA anim sit cargó")
end

local function watch(char)
	task.spawn(function()
		while char.Parent and player.Character == char do
			local anclado = char:GetAttribute("Anclado") == true
			if anclado then
				if not (track and track.IsPlaying) then
					playSit(char)
				end
			else
				stopSit()
			end
			task.wait(0.4)
		end
		stopSit()
	end)
end

local function onChar(char)
	stopSit()
	watch(char)
	char:GetAttributeChangedSignal("Anclado"):Connect(function()
		if char:GetAttribute("Anclado") then
			playSit(char)
		else
			stopSit()
		end
	end)
end

if player.Character then onChar(player.Character) end
player.CharacterAdded:Connect(onChar)

task.spawn(function()
	local rem = ReplicatedStorage:WaitForChild("NotificarCliente", 60)
	if not rem then
		warn("[AnclajeAnim] No hay NotificarCliente — el server no cargó?")
		return
	end
	rem.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		if data.tipo == "forzar_sit" or data.tipo == "anclado" then
			local char = player.Character
			if char then
				char:SetAttribute("Anclado", true)
				playSit(char)
			end
		elseif data.tipo == "desanclado" or (data.tipo == "forzar_sit" and data.activo == false) then
			local char = player.Character
			if char then char:SetAttribute("Anclado", false) end
			stopSit()
		end
	end)
	print("[AnclajeAnim] remote OK")
end)

print("[AnclajeAnim] script arrancado")
