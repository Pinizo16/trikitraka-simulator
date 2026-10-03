return function(ctx)
	local Players = ctx.Players
	local ReplicatedStorage = ctx.ReplicatedStorage
	local RunService = ctx.RunService
	local ContentProvider = ctx.ContentProvider
	local Workspace = ctx.Workspace
	local DataStoreService = ctx.DataStoreService
	local MarketplaceService = ctx.MarketplaceService
	local Config = ctx.Config
	local DataStore = ctx.DataStore

	local duelosPendientes = ctx.duelosPendientes
	local duelosActivos = ctx.duelosActivos
	local ancladoA = ctx.ancladoA
	local ancladosEn = ctx.ancladosEn
	local cooldownReanclar = ctx.cooldownReanclar
	local antiAnclajeHasta = ctx.antiAnclajeHasta
	local walkSpeedOriginal = ctx.walkSpeedOriginal
	local expulsionSessions = ctx.expulsionSessions
	local proteccionFalloHasta = ctx.proteccionFalloHasta
	local animTracks = ctx.animTracks
	local anclajeWelds = ctx.anclajeWelds
	local anclajeAtts = ctx.anclajeAtts
	local dailyData = ctx.dailyData
	local dailyByUserId = ctx.dailyByUserId
	local promoTiers = ctx.promoTiers
	local playerMetrics = ctx.playerMetrics
	local botsAmbulantes = ctx.botsAmbulantes
	local ultimaRecomendacion = ctx.ultimaRecomendacion
	local botsConfigurados = ctx.botsConfigurados

	local SolicitarDueloDirecto = ctx.SolicitarDueloDirecto
	local ResponderDuelo = ctx.ResponderDuelo
	local IniciarMinijuego = ctx.IniciarMinijuego
	local EnviarClicks = ctx.EnviarClicks
	local MostrarResultados = ctx.MostrarResultados
	local DesanclarJugador = ctx.DesanclarJugador
	local ExpulsarAnclado = ctx.ExpulsarAnclado
	local NotificarCliente = ctx.NotificarCliente
	local ComprarMejora = ctx.ComprarMejora
	local HacerRebirth = ctx.HacerRebirth
	local ExpulsionUpdate = ctx.ExpulsionUpdate
	local ExpulsionAccion = ctx.ExpulsionAccion
	local ExpulsionDefensa = ctx.ExpulsionDefensa
	local ClaimDaily = ctx.ClaimDaily
	local SyncDaily = ctx.SyncDaily
	local ultimoTick = ctx.ultimoTick
	local candidateGenerators = ctx.candidateGenerators

function ctx.crearPromptAnclar(character, player)
	local hrp = character:WaitForChild("HumanoidRootPart", 5)
	if not hrp then return end

	local viejo = hrp:FindFirstChild("PromptAnclar")
	if viejo then viejo:Destroy() end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptAnclar"
	prompt.ActionText = "Triki Traka"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.05
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ClickablePrompt = true
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt:SetAttribute("PromptKind", "anclar")
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = hrp
	NotificarCliente:FireClient(player, { tipo = "hide_own_prompt" })

	local lastTrigger = {}
	prompt.Triggered:Connect(function(quien)
		if quien == player then return end
		if not quien or not quien.Parent then return end
		local t0 = tick()
		if lastTrigger[quien] and t0 - lastTrigger[quien] < 1.2 then return end
		lastTrigger[quien] = t0
		ctx.anclar(quien, player)
	end)
end

function ctx.onCharacterAdded(player, character)
	task.wait(0.3)
	ctx.crearPromptAnclar(character, player)
	if ancladoA[player] then
		ctx.aplicarEstadoAnclado(player)
	else
		ctx.aplicarEstadoLibre(player)
	end
end

-- =====================================================
-- JUGADORES + DATASTORE
-- =====================================================
Players.PlayerAdded:Connect(function(player)
	local datos = ctx.cargarDatos(player)
	ctx.crearLeaderstats(player, datos)
	playerMetrics[player] = {
		sessionStart = tick(),
		wins = 0,
		losses = 0,
		anchors = 0,
		expulsions = 0,
		lastLevelUp = tick(),
		lastLevel = ctx.getStat(player, "Nivel"),
		lastProgress = tick(),
		anchorsRecent = 0,
		expulsionsRecent = 0,
		windowStart = tick(),
		anchorTimes = {},       -- timestamps de anclajes
		expulsionTimes = {},
		duelResults = {},       -- true=win false=loss timestamps
		streakLosses = 0,
		streakWins = 0,
	}
	do
		local cached = dailyByUserId[player.UserId]
		local lastDay = 0
		local streak = 0
		if datos and typeof(datos.DailyLastDay) == "number" then
			lastDay = datos.DailyLastDay
			streak = (typeof(datos.DailyStreak) == "number") and datos.DailyStreak or 0
		end
		-- Si en esta sesión ya reclamó (cache) y es más reciente, priorizar cache
		if cached and typeof(cached.lastDay) == "number" and cached.lastDay >= lastDay then
			lastDay = cached.lastDay
			streak = cached.streak or streak
		end
		dailyData[player] = { lastDay = lastDay, streak = streak }
		dailyByUserId[player.UserId] = { lastDay = lastDay, streak = streak }
		promoTiers[player] = (datos and typeof(datos.PromoTiers) == "table") and datos.PromoTiers or {}
		print("[Daily] Load", player.Name, "lastDay=", lastDay, "streak=", streak, "today=", math.floor(os.time() / 86400))
	end
	task.defer(function()
		task.wait(1)
		local st = dailyData[player]
		if not st then return end
		local today = math.floor(os.time() / 86400)
		local can = st.lastDay ~= today
		SyncDaily:FireClient(player, {
			canClaim = can,
			streak = st.streak,
			nextIn = can and 0 or (86400 - (os.time() % 86400)),
		})
		NotificarCliente:FireClient(player, {
			tipo = "promo_tiers",
			tiers = promoTiers[player] or {},
		})
	end)

	player.CharacterAdded:Connect(function(char)
		ctx.onCharacterAdded(player, char)
	end)
	if player.Character then
		ctx.onCharacterAdded(player, player.Character)
	end
end)

for _, p in ipairs(Players:GetPlayers()) do
	if not p:FindFirstChild("leaderstats") then
		local datos = ctx.cargarDatos(p)
		ctx.crearLeaderstats(p, datos)
	end
	if p.Character then ctx.onCharacterAdded(p, p.Character) end
	p.CharacterAdded:Connect(function(char) ctx.onCharacterAdded(p, char) end)
end

Players.PlayerRemoving:Connect(function(player)
	ctx.guardarDatos(player)
	ctx.desanclar(player)
	if ancladosEn[player] then
		for a in pairs(ancladosEn[player]) do ctx.desanclar(a) end
		ancladosEn[player] = nil
	end
	duelosPendientes[player] = nil
	duelosActivos[player] = nil
	antiAnclajeHasta[player] = nil
	walkSpeedOriginal[player] = nil
	ctx.stopAnimAnclaje(player)
	expulsionSessions[player] = nil
	proteccionFalloHasta[player] = nil
	-- dailyByUserId se mantiene para la sesión del servidor
	if dailyData[player] then
		dailyByUserId[player.UserId] = {
			lastDay = dailyData[player].lastDay,
			streak = dailyData[player].streak,
		}
	end
	dailyData[player] = nil
	promoTiers[player] = nil
	playerMetrics[player] = nil
	ultimaRecomendacion[player] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		ctx.guardarDatos(player)
	end
	task.wait(2)
end)

task.spawn(function()
	while true do
		task.wait(Config.AUTOSAVE_INTERVALO)
		for _, player in ipairs(Players:GetPlayers()) do
			ctx.guardarDatos(player)
		end
	end
end)

DesanclarJugador.OnServerEvent:Connect(function(player)
	ctx.desanclar(player)
end)

function ctx.syncExpulsion(objetivo)
	local ses = expulsionSessions[objetivo]
	if not ses then return end
	local anclado = ses.anclado
	if not anclado or not anclado.Parent or ancladoA[anclado] ~= objetivo then
		expulsionSessions[objetivo] = nil
		ExpulsionUpdate:FireClient(objetivo, { activo = false })
		return
	end
	local info = Config.calcExpulsion(ses.dinero, ses.defensaClicks, ctx.getStat(anclado, "Nivel"))
	local payloadBase = {
		activo = true,
		quien = anclado.Name,
		userId = anclado.UserId,
		dinero = ses.dinero,
		dineroParaFull = info.dineroParaFull,
		prob = info.probabilidad,
		probInicial = info.probInicial,
		probMax = info.probMax,
		reduccion = info.reduccion,
		reduccionMax = info.reduccionMax,
		defensaClicks = ses.defensaClicks,
		clicksParaMax = info.clicksParaMax,
		fase = ses.fase,
	}
	ExpulsionUpdate:FireClient(objetivo, {
		activo = true, rol = "objetivo",
		quien = payloadBase.quien, userId = payloadBase.userId,
		dinero = payloadBase.dinero, dineroParaFull = payloadBase.dineroParaFull,
		prob = payloadBase.prob, probInicial = payloadBase.probInicial,
		probMax = payloadBase.probMax, reduccion = payloadBase.reduccion, reduccionMax = payloadBase.reduccionMax,
		defensaClicks = payloadBase.defensaClicks, clicksParaMax = payloadBase.clicksParaMax, fase = payloadBase.fase,
		tiempoRestante = ses.tiempoFin and math.max(0, ses.tiempoFin - tick()) or nil,
	})
	if ses.fase == "batalla" then
		ExpulsionUpdate:FireClient(anclado, {
			activo = true, rol = "anclado",
			quien = objetivo.Name,
			prob = payloadBase.prob, probInicial = payloadBase.probInicial,
			reduccion = payloadBase.reduccion, reduccionMax = payloadBase.reduccionMax,
			defensaClicks = payloadBase.defensaClicks, clicksParaMax = payloadBase.clicksParaMax,
			fase = "batalla",
			tiempoRestante = ses.tiempoFin and math.max(0, ses.tiempoFin - tick()) or nil,
		})
	end
end

-- set_dinero | intentar
ExpulsionAccion.OnServerEvent:Connect(function(player, accion, valor)
	if typeof(accion) ~= "string" then return end
	local ses = expulsionSessions[player]
	if not ses then return end
	local anclado = ses.anclado
	if not anclado or ancladoA[anclado] ~= player then
		expulsionSessions[player] = nil
		return
	end

	if accion == "set_dinero" then
		if ses.fase ~= "preparacion" then return end
		local dinero = tonumber(valor)
		if not dinero then return end
		dinero = math.floor(math.clamp(dinero, Config.EXPULSION.DINERO_MINIMO, 1000000))
		ses.dinero = dinero
		ctx.syncExpulsion(player)
		return
	end

	if accion == "intentar" then
		if ses.fase ~= "preparacion" then return end
		if proteccionFalloHasta[anclado] and tick() < proteccionFalloHasta[anclado] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "El anclado está protegido tras un fallo" })
			return
		end
		local dinero = ses.dinero or Config.EXPULSION.DINERO_MINIMO
		if dinero < Config.EXPULSION.DINERO_MINIMO then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Mínimo " .. Config.EXPULSION.DINERO_MINIMO .. " 💰" })
			return
		end
		if ctx.getStat(player, "Monedas") < dinero then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. dinero .. " 💰" })
			return
		end

		-- Cobrar y empezar batalla
		ctx.agregarMonedas(player, -dinero)
		ses.fase = "batalla"
		ses.defensaClicks = 0
		local dur = Config.EXPULSION.DEFENSA_DURACION or 3
		ses.tiempoFin = tick() + dur
		ses.dineroGastado = dinero
		ctx.syncExpulsion(player)

		task.spawn(function()
			local fin = ses.tiempoFin
			-- Actualizar UI mientras dura
			while expulsionSessions[player] == ses and ses.fase == "batalla" do
				local resto = fin - tick()
				if resto <= 0 then break end
				ctx.syncExpulsion(player)
				task.wait(0.1)
			end

			if expulsionSessions[player] ~= ses then return end
			if ancladoA[anclado] ~= player then
				expulsionSessions[player] = nil
				ExpulsionUpdate:FireClient(player, { activo = false })
				if anclado.Parent then
					ExpulsionUpdate:FireClient(anclado, { activo = false })
				end
				return
			end

			local info = Config.calcExpulsion(ses.dineroGastado, ses.defensaClicks, ctx.getStat(anclado, "Nivel"))
			local roll = math.random()
			local exito = roll <= info.probabilidad

			if exito then
				ctx.desanclar(anclado)
				do
					local ck = ctx.cooldownKeyFor(player)
					cooldownReanclar[ck] = cooldownReanclar[ck] or {}
					cooldownReanclar[ck][anclado] = tick() + Config.COOLDOWN_REANCLAR
				end
				expulsionSessions[player] = nil
				NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡EXPULSIÓN EXITOSA! (-" .. ses.dineroGastado .. " 💰)" })
				NotificarCliente:FireClient(anclado, { tipo = "expulsado", mensaje = player.Name .. " te expulsó" })
				ExpulsionUpdate:FireClient(player, { activo = false, resultado = "exito", prob = info.probabilidad })
				ExpulsionUpdate:FireClient(anclado, { activo = false, resultado = "exito" })
				do
					local m = playerMetrics[anclado]
					if m then
						m.expulsions = (m.expulsions or 0) + 1
						m.expulsionsRecent = (m.expulsionsRecent or 0) + 1
						m.expulsionTimes = m.expulsionTimes or {}
						ctx.pushMetricTime(m.expulsionTimes, 30)
					end
				end
			else
				proteccionFalloHasta[anclado] = tick() + Config.EXPULSION.PROTECCION_FALLO_SEGUNDOS
				ses.fase = "preparacion"
				ses.defensaClicks = 0
				ses.tiempoFin = nil
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Expulsión FALLIDA. Protección 3s para el anclado." })
				NotificarCliente:FireClient(anclado, { tipo = "exito", mensaje = "¡Te salvaste! 3s de protección" })
				ExpulsionUpdate:FireClient(anclado, { activo = false, resultado = "fallo" })
				ctx.syncExpulsion(player)
			end
		end)
	end
end)

ExpulsionDefensa.OnServerEvent:Connect(function(player)
	local objetivo = ancladoA[player]
	if not objetivo then return end
	local ses = expulsionSessions[objetivo]
	if not ses or ses.anclado ~= player then return end
	if ses.fase ~= "batalla" then return end
	if proteccionFalloHasta[player] and tick() < proteccionFalloHasta[player] then return end
	if ses.tiempoFin and tick() > ses.tiempoFin then return end

	ses.defensaClicks = ses.defensaClicks + 1
	-- sync lo hace el loop de batalla; opcional sync inmediato
	local info = Config.calcExpulsion(ses.dineroGastado or ses.dinero, ses.defensaClicks, ctx.getStat(player, "Nivel"))
	ExpulsionUpdate:FireClient(player, {
		activo = true, rol = "anclado", fase = "batalla",
		quien = objetivo.Name,
		prob = info.probabilidad, probInicial = info.probInicial,
		reduccion = info.reduccion, reduccionMax = info.reduccionMax,
		defensaClicks = ses.defensaClicks, clicksParaMax = info.clicksParaMax,
		tiempoRestante = math.max(0, (ses.tiempoFin or tick()) - tick()),
	})
	ExpulsionUpdate:FireClient(objetivo, {
		activo = true, rol = "objetivo", fase = "batalla",
		quien = player.Name, userId = player.UserId,
		dinero = ses.dineroGastado, prob = info.probabilidad, probInicial = info.probInicial,
		reduccion = info.reduccion, reduccionMax = info.reduccionMax,
		defensaClicks = ses.defensaClicks, clicksParaMax = info.clicksParaMax,
		tiempoRestante = math.max(0, (ses.tiempoFin or tick()) - tick()),
	})
end)

ExpulsarAnclado.OnServerEvent:Connect(function()
	-- legacy no-op: todo va por ExpulsionAccion
end)

ComprarMejora.OnServerEvent:Connect(function(player, productId)
	if typeof(productId) ~= "string" then return end

	local nivel = ctx.getStat(player, "Nivel")
	local rebirths = ctx.getStat(player, "Rebirths")

	local function encontrarProducto(lista, id)
		for _, p in ipairs(lista) do
			if p.id == id then return p end
		end
		return nil
	end

	-- Anti-Anclaje
	local anti = encontrarProducto(Config.ANTI_ANCLAJE, productId)
	if anti then
		local coste = Config.getPrecioAnti(anti, nivel, rebirths)
		if ctx.getStat(player, "Monedas") < coste then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " 💰" })
			return
		end
		ctx.agregarMonedas(player, -coste)
		local ahora = tick()
		local actual = antiAnclajeHasta[player] or 0
		if actual > ahora then
			antiAnclajeHasta[player] = actual + anti.segundos
			ctx.syncProteccionCliente(player)
		ctx.syncProteccionCliente(player)
		else
			antiAnclajeHasta[player] = ahora + anti.segundos
			ctx.syncProteccionCliente(player)
		ctx.syncProteccionCliente(player)
		end
		local mins = math.floor(anti.segundos / 60)
		NotificarCliente:FireClient(player, {
			tipo = "exito",
			mensaje = "¡" .. anti.nombre .. "! +" .. mins .. " min (-" .. coste .. " 💰)"
		})
		return
	end

	-- Clicks packs
	local pack = encontrarProducto(Config.CLICKS_PACKS, productId)
	if pack then
		local actualClicks = ctx.getStat(player, "ClicksPorClick")
		local maxC = Config.getMaxClicks(nivel)
		if actualClicks + pack.cantidad > maxC then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Nivel insuficiente (máx " .. maxC .. " Clicks/Click)" })
			return
		end
		local coste = Config.getPrecioClicks(pack, nivel, actualClicks, rebirths)
		if ctx.getStat(player, "Monedas") < coste then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " 💰" })
			return
		end
		ctx.agregarMonedas(player, -coste)
		ctx.setStat(player, "ClicksPorClick", actualClicks + pack.cantidad)
		NotificarCliente:FireClient(player, {
			tipo = "exito",
			mensaje = "¡" .. pack.nombre .. "! Ahora " .. (actualClicks + pack.cantidad) .. " (-" .. coste .. " 💰)"
		})
		return
	end

	-- Velocidad
	local vel = encontrarProducto(Config.VELOCIDAD_PACKS, productId)
	if vel then
		local actualVel = ctx.getStat(player, "VelocidadAnclaje")
		local maxV = Config.getMaxVelAnclaje(nivel)
		if actualVel + vel.niveles > maxV then
			local maxSeg = Config.formatSegundosAnclaje and Config.formatSegundosAnclaje(maxV) or (maxV * 0.1 .. "s")
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Nivel insuficiente (máx " .. maxSeg .. ")" })
			return
		end
		local coste = Config.getPrecioVelocidad(vel, nivel, actualVel, rebirths)
		if ctx.getStat(player, "Monedas") < coste then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " 💰" })
			return
		end
		ctx.agregarMonedas(player, -coste)
		local nuevo = actualVel + vel.niveles
		ctx.setStat(player, "VelocidadAnclaje", nuevo)
		local intervalo = Config.getIntervaloAnclaje(nuevo)
		NotificarCliente:FireClient(player, {
			tipo = "exito",
			mensaje = "¡" .. vel.nombre .. "! Intervalo " .. string.format("%.2f", intervalo) .. "s (-" .. coste .. " 💰)"
		})
		return
	end

	-- Velocidad de movimiento (correr)
	local walk = encontrarProducto(Config.WALKSPEED_PACKS, productId)
	if walk then
		local actualWalk = ctx.getStat(player, "VelocidadMovimiento")
		local maxW = math.min(Config.WALKSPEED_MAX_NIVELES, Config.getMaxWalk(nivel))
		if actualWalk + walk.niveles > maxW then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Nivel insuficiente (máx " .. maxW .. " Run)" })
			return
		end
		local coste = Config.getPrecioWalk(walk, nivel, actualWalk, rebirths)
		if ctx.getStat(player, "Monedas") < coste then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " 💰" })
			return
		end
		ctx.agregarMonedas(player, -coste)
		local nuevo = math.min(maxW, actualWalk + walk.niveles)
		ctx.setStat(player, "VelocidadMovimiento", nuevo)
		if not ancladoA[player] then
			ctx.aplicarEstadoLibre(player)
		end
		NotificarCliente:FireClient(player, {
			tipo = "exito",
			mensaje = "¡" .. walk.nombre .. "! WalkSpeed " .. string.format("%.1f", Config.getWalkSpeed(nuevo)) .. " (-" .. coste .. " 💰)"
		})
		return
	end
end)

HacerRebirth.OnServerEvent:Connect(function(player)
	local nivel = ctx.getStat(player, "Nivel")
	local minNivel = Config.getNivelMinimoRebirth(ctx.getStat(player, "Rebirths"))
	if nivel < minNivel then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas nivel " .. minNivel })
		return
	end

	ctx.setStat(player, "Nivel", 1)
	ctx.setStat(player, "XP", Config.XP_INICIAL)
	ctx.setStat(player, "MaxXP", ctx.getMaxXP(1))
	ctx.setStat(player, "ClicksPorClick", 1)
	ctx.setStat(player, "VelocidadAnclaje", 0)
	ctx.setStat(player, "VelocidadMovimiento", 0)
	ctx.aplicarEstadoLibre(player)

	local rebirths = ctx.getStat(player, "Rebirths") + 1
	ctx.setStat(player, "Rebirths", rebirths)
	ctx.setStat(player, "MultiXP", ctx.getStat(player, "MultiXP") * Config.getMultiXPAlRebirth(rebirths))
	ctx.setStat(player, "MultiClicks", ctx.getStat(player, "MultiClicks") * Config.getMultiClicksAlRebirth(rebirths))

	ctx.desanclar(player)
	ctx.guardarDatos(player)

	NotificarCliente:FireClient(player, {
		tipo = "exito",
		mensaje = string.format("¡REBIRTH #%d! Multi XP x%.2f | Multi Clicks x%.2f", rebirths, ctx.getStat(player, "MultiXP"), ctx.getStat(player, "MultiClicks")),
		refrescarTienda = true,
	})
end)

-- =====================================================
-- BOTS
-- =====================================================
function ctx.extraerNivelBot(nombre)
	local num = string.match(nombre, "%d+")
	return num and tonumber(num) or 5
end

function ctx.esNombreBot(nombre)
	if typeof(nombre) ~= "string" then return false end
	local n = string.lower(nombre)
	-- Solo nombres de bot reales: empiezan por "bot" o contienen "bot_"
	-- (evita falsos positivos como "BottomLeaves")
	if string.sub(n, 1, 3) == "bot" then return true end
	if string.find(n, "bot_", 1, true) then return true end
	if string.find(n, "_bot", 1, true) then return true end
	return false
end

function ctx.esBotInstancia(obj)
	if not obj or not obj.Parent then return false end
	-- Solo Models en Workspace (no Parts sueltas del mapa)
	if obj:IsA("Model") and ctx.esNombreBot(obj.Name) then
		-- Preferir hijos directos de Workspace
		if obj.Parent == Workspace or (obj.Parent and obj.Parent:IsA("Folder") and obj.Parent.Parent == Workspace) then
			return true
		end
		-- También si el modelo tiene Humanoid (NPC)
		if obj:FindFirstChildOfClass("Humanoid") then
			return true
		end
	end
	return false
end

function ctx.obtenerPartePrompt(modelo)
	if modelo:IsA("BasePart") then return modelo end
	local hrp = modelo:FindFirstChild("HumanoidRootPart")
	if hrp and hrp:IsA("BasePart") then return hrp end
	if modelo:IsA("Model") and modelo.PrimaryPart then return modelo.PrimaryPart end
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") then
			local ln = string.lower(p.Name)
			if ln == "humanoidrootpart" or ln == "torso" or ln == "uppertorso" or ln == "root" then
				return p
			end
		end
	end
	for _, p in ipairs(modelo:GetDescendants()) do
		if p:IsA("BasePart") then return p end
	end
	return nil
end

function ctx.calcularClicksBot(nivelBot, _player)
	-- Los clicks necesarios NO escalan con el poder del jugador (solo el dinero de recompensa)
	return Config.calcularClicksBot(nivelBot, 1)
end

local botsConfigurados = {} -- [modelo] = true

function ctx.configurarBot(modelo)
	if not modelo or not modelo.Parent then return false end
	if not ctx.esBotInstancia(modelo) then return false end
	if botsConfigurados[modelo] then return true end
	if modelo:FindFirstChild("PromptBot", true) then
		botsConfigurados[modelo] = true
		return true
	end

	local parte = ctx.obtenerPartePrompt(modelo)
	if not parte then
		warn("[Bots] Sin BasePart en:", modelo:GetFullName())
		return false
	end

	local nivelBot = ctx.extraerNivelBot(modelo.Name)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptBot"
	prompt.ActionText = "Retar"
	prompt.ObjectText = ""
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ClickablePrompt = true
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt:SetAttribute("PromptKind", "bot")
	prompt:SetAttribute("NivelBot", nivelBot)
	prompt.HoldDuration = 0.05
	prompt.MaxActivationDistance = 20
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Parent = parte

	-- Ocultar nombre encima de la cabeza
	local humBot = modelo:FindFirstChildOfClass("Humanoid")
	if humBot then
		humBot.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humBot.NameDisplayDistance = 0
		humBot.HealthDisplayDistance = 0
		pcall(function()
			humBot.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
		end)
	end
	for _, d in ipairs(modelo:GetDescendants()) do
		if d:IsA("BillboardGui") then
			local n = string.lower(d.Name)
			if n:find("name") or n:find("tag") or n:find("over") or n:find("title") then
				d:Destroy()
			else
				-- si solo tiene un TextLabel con el nombre del modelo, quitarlo
				local tl = d:FindFirstChildWhichIsA("TextLabel", true)
				if tl and (tl.Text == modelo.Name or string.find(tl.Text, "bot", 1, true) or string.find(tl.Text, "Bot", 1, true) or string.find(tl.Text, "Nivel")) then
					d:Destroy()
				end
			end
		end
	end

	prompt.Triggered:Connect(function(player)
		if not player or not player:IsA("Player") then return end
		if duelosActivos[player] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Ya estás en un duelo" })
			return
		end

		local clicksMinimos = ctx.calcularClicksBot(nivelBot, player)
		duelosActivos[player] = {
			oponente = nil,
			esBot = true,
			nivelBot = nivelBot,
			clicksMinimos = clicksMinimos,
			clicks = 0,
			listo = false,
		}
		IniciarMinijuego:FireClient(player, true, nivelBot, clicksMinimos)
	end)

	botsConfigurados[modelo] = true
	print("[Bots] OK:", modelo:GetFullName(), "| Nivel", nivelBot, "| Prompt en", parte.Name)
	return true
end

function ctx.escanearBots()
	local count = 0
	-- 1) Hijos directos de Workspace (tus bot_Nivel1, etc.)
	for _, obj in ipairs(Workspace:GetChildren()) do
		if ctx.esBotInstancia(obj) then
			if ctx.configurarBot(obj) then count += 1 end
		end
	end
	-- 2) Cualquier descendiente por si están en carpetas
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if ctx.esBotInstancia(obj) then
			if ctx.configurarBot(obj) then count += 1 end
		end
	end
	print("[Bots] Escaneo terminado. Configurados en esta pasada / total tags:", count)
end


end
