-- AnclajeSit.client.lua
-- NO sustituye Animate del avatar. Solo reproduce sit al anclarse.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- La animación sit personalizada la reproduce Animate (StarterCharacterScripts).
-- Este script SOLO gestiona el atributo "Anclado"; ya no reproduce animaciones
-- para no mezclar tracks con la misma prioridad (Action4).
local function setAncladoAttr(char, v)
	if char and char:GetAttribute("Anclado") ~= v then
		char:SetAttribute("Anclado", v)
	end
end

-- Sin loop de animación: el servidor ya replica el atributo "Anclado"
-- (ModAncladoFlag) y Animate reacciona a él con la animación personalizada.

task.spawn(function()
	local rem = ReplicatedStorage:WaitForChild("NotificarCliente", 60)
	if not rem then
		warn("[AnclajeSit] sin NotificarCliente")
		return
	end
	rem.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		local char = player.Character
		if not char then return end
		if data.tipo == "forzar_sit" or data.tipo == "anclado" then
			setAncladoAttr(char, data.activo ~= false)
		elseif data.tipo == "desanclado" then
			setAncladoAttr(char, false)
		end
	end)
	print("[AnclajeSit] remote conectado")
end)

print("[AnclajeSit] activo: solo gestiona atributo Anclado (anim sit personalizada en Animate)")

-- Ok /