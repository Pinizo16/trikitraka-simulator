-- Stick.lua (posición de anclaje)
-- Único Heartbeat de pegado detrás del objetivo + NetworkOwner
return function(ctx)
	local RunService = ctx.RunService
	local Config = ctx.Config
	local ancladoA = ctx.ancladoA
	local anclajeWelds = ctx.anclajeWelds
	local NotificarCliente = ctx.NotificarCliente

	ctx.UNIFIED_STICK = true

	local function getHRP(objetivo)
		if typeof(objetivo) ~= "Instance" then return nil end
		if objetivo:IsA("Player") then
			local c = objetivo.Character
			return c and c:FindFirstChild("HumanoidRootPart")
		elseif objetivo:IsA("Model") then
			return objetivo:FindFirstChild("HumanoidRootPart") or objetivo.PrimaryPart
		end
		return nil
	end

	function ctx.limpiarWeldAnclaje(player)
		local w = anclajeWelds[player]
		if w then
			pcall(function()
				w:Destroy()
			end)
			anclajeWelds[player] = nil
		end
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				for _, c in ipairs(hrp:GetChildren()) do
					if c:IsA("WeldConstraint") and c.Name == "AnclajeWeld" then
						c:Destroy()
					end
				end
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
		end
	end

	function ctx.crearWeldAnclaje(player, objetivo)
		ctx.limpiarWeldAnclaje(player)
		local charA = player.Character
		if not charA then return false end
		local hrpA = charA:FindFirstChild("HumanoidRootPart")
		local hrpO = getHRP(objetivo)
		if not (hrpA and hrpO) then return false end
		local dist = Config.DISTANCIA_ANCLAJE or 3.2
		hrpA.CFrame = hrpO.CFrame * CFrame.new(0, 0, dist)
		hrpA.AssemblyLinearVelocity = Vector3.zero
		hrpA.AssemblyAngularVelocity = Vector3.zero
		pcall(function()
			hrpA:SetNetworkOwner(nil)
		end)
		return true
	end

	function ctx.aplicarEstadoAnclado(player)
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit = false
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			pcall(function()
				hum.JumpHeight = 0
			end)
			pcall(function()
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			end)
		end
		char:SetAttribute("Anclado", true)
		if player.Parent and NotificarCliente then
			NotificarCliente:FireClient(player, { tipo = "forzar_sit", activo = true })
			-- "anclado" lo envía ctx.anclar una sola vez (evitar duplicados)
		end
	end

	local oldL = ctx.aplicarEstadoLibre
	function ctx.aplicarEstadoLibre(player)
		local char = player.Character
		if char then
			char:SetAttribute("Anclado", false)
		end
		ctx.limpiarWeldAnclaje(player)
		if player and player.Parent and NotificarCliente then
			NotificarCliente:FireClient(player, { tipo = "forzar_sit", activo = false })
			-- "desanclado" lo envía ctx.desanclar una sola vez
		end
		if oldL then
			pcall(oldL, player)
		end
	end

	RunService.Heartbeat:Connect(function()
		local dist = Config.DISTANCIA_ANCLAJE or 3.2
		for anclado, objetivo in pairs(ancladoA) do
			if not anclado.Parent then
				continue
			end
			local charA = anclado.Character
			if not charA then
				continue
			end
			local hrpA = charA:FindFirstChild("HumanoidRootPart")
			local hrpO = getHRP(objetivo)
			if not (hrpA and hrpO) then
				continue
			end
			hrpA.CFrame = hrpO.CFrame * CFrame.new(0, 0, dist)
			hrpA.AssemblyLinearVelocity = Vector3.zero
			hrpA.AssemblyAngularVelocity = Vector3.zero
		end
	end)

	print("[Stick] OK unified")
end
