-- Safety.lua
-- 1) safeFireClient solo a Players  2) Limpieza salir/morir  3) Clamp de stats
-- NO sobrescribe RemoteEvent.FireClient (rompe el motor: "FireClient is not a valid member")
return function(ctx)
	local Players = ctx.Players
	local RunService = ctx.RunService
	local ancladoA = ctx.ancladoA
	local ancladosEn = ctx.ancladosEn
	local expulsionSessions = ctx.expulsionSessions
	local duelosPendientes = ctx.duelosPendientes
	local duelosActivos = ctx.duelosActivos
	local antiAnclajeHasta = ctx.antiAnclajeHasta
	local cooldownReanclar = ctx.cooldownReanclar
	local playerMetrics = ctx.playerMetrics
	local dailyData = ctx.dailyData
	local promoTiers = ctx.promoTiers
	local ultimoTick = ctx.ultimoTick
	local ultimaRecomendacion = ctx.ultimaRecomendacion
	local walkSpeedOriginal = ctx.walkSpeedOriginal
	local animTracks = ctx.animTracks
	local anclajeWelds = ctx.anclajeWelds
	local NotificarCliente = ctx.NotificarCliente
	local ExpulsionUpdate = ctx.ExpulsionUpdate

	local function isPlayer(x)
		return typeof(x) == "Instance" and x:IsA("Player") and x.Parent ~= nil
	end

	local function safeFire(remote, plr, payload)
		if not remote or not isPlayer(plr) then return end
		pcall(function()
			remote:FireClient(plr, payload)
		end)
	end
	ctx.safeFireClient = safeFire

	-- (3) Clamp stats
	local oldSet = ctx.setStat
	function ctx.setStat(player, name, value)
		if typeof(value) == "number" then
			if name == "Monedas" or name == "XP" or name == "Rebirths"
				or name == "ClicksPorClick" or name == "VelocidadAnclaje"
				or name == "VelocidadMovimiento" then
				value = math.max(0, math.floor(value))
			elseif name == "Nivel" or name == "MaxXP" then
				value = math.max(1, math.floor(value))
			elseif name == "MultiXP" or name == "MultiClicks" then
				value = math.max(0.01, value)
			end
		end
		if oldSet then
			oldSet(player, name, value)
		end
	end

	local rateBucket = {}
	function ctx.rateLimit(player, key, interval)
		if not player then return false end
		interval = interval or 0.4
		local t = tick()
		rateBucket[player] = rateBucket[player] or {}
		local last = rateBucket[player][key] or 0
		if t - last < interval then return false end
		rateBucket[player][key] = t
		return true
	end

	local function cleanupPlayer(player)
		if ancladoA[player] then
			pcall(function()
				ctx.desanclar(player)
			end)
		end
		if ancladosEn[player] then
			local lista = {}
			for anc in pairs(ancladosEn[player]) do
				table.insert(lista, anc)
			end
			for _, anc in ipairs(lista) do
				pcall(function()
					ctx.desanclar(anc)
				end)
			end
			ancladosEn[player] = nil
		end
		local ses = expulsionSessions[player]
		if ses then
			local anc = ses.anclado
			expulsionSessions[player] = nil
			safeFire(ExpulsionUpdate, anc, { activo = false })
		end
		for obj, ses2 in pairs(expulsionSessions) do
			if ses2 and ses2.anclado == player then
				expulsionSessions[obj] = nil
				if isPlayer(obj) then
					safeFire(ExpulsionUpdate, obj, { activo = false })
				end
			end
		end
		duelosPendientes[player] = nil
		duelosActivos[player] = nil
		-- No llamamos ctx.guardarDatos aquí: Mod2.PlayerRemoving ya guarda
		-- antes de que cleanupPlayer ejecute. Una segunda llamada sobreescribiría
		-- PromoTiers con {} (ya limpiado por Mod2) → pérdida de datos.
		antiAnclajeHasta[player] = nil
		playerMetrics[player] = nil
		dailyData[player] = nil
		promoTiers[player] = nil
		ultimoTick[player] = nil
		ultimaRecomendacion[player] = nil
		walkSpeedOriginal[player] = nil
		animTracks[player] = nil
		anclajeWelds[player] = nil
		rateBucket[player] = nil
		for _, map in pairs(cooldownReanclar) do
			if typeof(map) == "table" then
				map[player] = nil
			end
		end
	end

	Players.PlayerRemoving:Connect(cleanupPlayer)

	local function hookChar(player)
		player.CharacterRemoving:Connect(function()
			if ancladoA[player] then
				pcall(function()
					ctx.desanclar(player)
				end)
			end
			if ancladosEn[player] then
				local lista = {}
				for anc in pairs(ancladosEn[player]) do
					table.insert(lista, anc)
				end
				for _, anc in ipairs(lista) do
					pcall(function()
						ctx.desanclar(anc)
					end)
				end
				ancladosEn[player] = nil
			end
		end)
	end
	Players.PlayerAdded:Connect(hookChar)
	for _, p in ipairs(Players:GetPlayers()) do
		hookChar(p)
	end

	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1.5 then return end
		acc = 0
		for anclado, objetivo in pairs(ancladoA) do
			if not anclado or not anclado.Parent then
				ancladoA[anclado] = nil
				if objetivo and ancladosEn[objetivo] then
					ancladosEn[objetivo][anclado] = nil
				end
			elseif not objetivo or not objetivo.Parent then
				pcall(function()
					ctx.desanclar(anclado)
				end)
			end
		end
	end)

	print("[Safety] OK")
end
