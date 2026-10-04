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
	local NotificarCliente = ctx.NotificarCliente
	local ancladoA = ctx.ancladoA
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

function ctx.crearModeloBot(def)
	local existente = Workspace:FindFirstChild(def.nombre)
	if existente then return existente end

	local model = Instance.new("Model")
	model.Name = def.nombre

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Config.BOT_TAMANO or Vector3.new(2, 5, 1)
	hrp.Position = def.posicion or Vector3.new(0, 5, 0)
	hrp.Anchored = true
	hrp.CanCollide = true
	hrp.Color = Config.BOT_COLOR or Color3.fromRGB(180, 40, 40)
	hrp.Material = Enum.Material.SmoothPlastic
	hrp.Parent = model

	local hum = Instance.new("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = hrp
	model.Parent = Workspace
	return model
end

function ctx.spawnearBotsDesdeConfig()
	if not Config.BOTS or #Config.BOTS == 0 then
		print("[Bots] Config.BOTS vacío → solo se usan modelos del Workspace")
		return
	end
	for _, def in ipairs(Config.BOTS) do
		ctx.configurarBot(ctx.crearModeloBot(def))
	end
end

-- Arranque (con retrasos por si el mapa tarda en cargar)
task.spawn(function()
	ctx.spawnearBotsDesdeConfig()
	ctx.escanearBots()           -- pasada 1 (inmediata)
	task.wait(2)
	ctx.escanearBots()           -- pasada 2 (mapa ya cargado)
	task.wait(3)
	ctx.escanearBots()           -- pasada 3 (por si acaso)
	-- Fin. No más escaneos periódicos.
end)

Workspace.ChildAdded:Connect(function(obj)
	task.defer(function()
		task.wait(0.2)
		if ctx.esBotInstancia(obj) then
			ctx.configurarBot(obj)
		end
	end)
end)

-- Sin bucle de re-escaneo: 3 pasadas al arranque + ChildAdded bastan

-- =====================================================
-- DUELOS
-- =====================================================
-- Cooldown anti-spam de retos
local ultimoReto = {} -- [player] = tick

SolicitarDueloDirecto.OnServerEvent:Connect(function(player, targetUserId)
	-- Tutorial: retar bot por nombre (solo nivel 1)
	if typeof(targetUserId) == "string" then
		if not (ctx.tutorialActive and ctx.tutorialActive[player]) then return end
		local nombre = targetUserId
		local modelo = nil
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("Model") and inst.Name == nombre and inst:FindFirstChild("PromptBot", true) then
				modelo = inst
				break
			end
		end
		if not modelo then
			for _, inst in ipairs(Workspace:GetChildren()) do
				if inst:IsA("Model") and inst.Name == nombre then
					modelo = inst
					break
				end
			end
		end
		if not modelo then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Bot no encontrado" })
			return
		end
		local nv = ctx.extraerNivelBot and ctx.extraerNivelBot(modelo.Name) or 1
		if nv ~= 1 then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "En el tutorial solo bots nivel 1" })
			return
		end
		if ctx.iniciarDueloBot then
			ctx.iniciarDueloBot(player, modelo)
		end
		return
	end
	if typeof(targetUserId) ~= "number" then return end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == player then return end
	if ctx.tutorialActive and (ctx.tutorialActive[player] or ctx.tutorialActive[target]) then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "No disponible durante el tutorial" })
		return
	end
	if duelosActivos[player] or duelosActivos[target] then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Alguien ya está en duelo" })
		return
	end
	if duelosPendientes[target] then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Ese jugador ya tiene un reto pendiente" })
		return
	end
	-- no retar si estás anclado
	if ancladoA and ancladoA[player] then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Desanclate antes de retar" })
		return
	end
	local ahora = tick()
	if ultimoReto[player] and ahora - ultimoReto[player] < 2 then return end
	ultimoReto[player] = ahora

	duelosPendientes[target] = { retador = player, tiempo = ahora }
	ResponderDuelo:FireClient(target, player.UserId, player.Name)
	NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "Reto enviado a " .. target.Name })
end)

ResponderDuelo.OnServerEvent:Connect(function(player, acepto, retadorUserId)
	local data = duelosPendientes[player]
	if not data then return end
	local retador = data.retador
	duelosPendientes[player] = nil
	if not retador or not retador.Parent then return end
	if typeof(retadorUserId) == "number" and retador.UserId ~= retadorUserId then return end

	if not acepto then
		NotificarCliente:FireClient(retador, { tipo = "error", mensaje = player.Name .. " rechazó el duelo" })
		return
	end
	if duelosActivos[player] or duelosActivos[retador] then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Duelo no disponible" })
		NotificarCliente:FireClient(retador, { tipo = "error", mensaje = "Duelo no disponible" })
		return
	end

	duelosActivos[player]  = { oponente = retador, esBot = false, clicks = 0, listo = false }
	duelosActivos[retador] = { oponente = player,  esBot = false, clicks = 0, listo = false }
	IniciarMinijuego:FireClient(player, false, 0, 0)
	IniciarMinijuego:FireClient(retador, false, 0, 0)
end)

task.spawn(function()
	while true do
		task.wait(1)
		local now = tick()
		for p, data in pairs(duelosPendientes) do
			if now - data.tiempo > 12 then
				duelosPendientes[p] = nil
				if data.retador and data.retador.Parent then
					NotificarCliente:FireClient(data.retador, { tipo = "error", mensaje = "El reto expiró" })
				end
				if p and p.Parent then
					NotificarCliente:FireClient(p, { tipo = "duelo_expirado" })
				end
			end
		end
	end
end)

EnviarClicks.OnServerEvent:Connect(function(player, cantidadClicks)
	if typeof(cantidadClicks) ~= "number" then return end

	local multi = ctx.getClicksTotal(player) * ctx.getStat(player, "MultiClicks")
	cantidadClicks = math.clamp(math.floor(cantidadClicks * multi), 0, 2000)

	local data = duelosActivos[player]
	if not data or data.listo then return end
	data.clicks = cantidadClicks
	data.listo = true

	if data.esBot then
		local gano = cantidadClicks >= data.clicksMinimos
		local recompensa = 0
		if gano then
			ctx.setStat(player, "Victorias", ctx.getStat(player, "Victorias") + 1)
			local miNivel = ctx.getStat(player, "Nivel")
			local nivelBot = data.nivelBot
			-- Recompensa base por nivel del bot
			recompensa = Config.getMonedasBot(nivelBot)
			-- Si el bot es más débil que tú, menos dinero (mínimo 25%)
			if nivelBot < miNivel then
				local factor = math.max(0.25, nivelBot / miNivel)
				recompensa = math.floor(recompensa * factor)
			end
			ctx.agregarMonedas(player, recompensa)
		end
		MostrarResultados:FireClient(player, {
			resultado = gano and "Victoria" or "Derrota",
			misClicks = cantidadClicks,
			oponenteClicks = data.clicksMinimos,
			esBot = true,
			recompensa = recompensa
		})
		duelosActivos[player] = nil
	else
		local oponente = data.oponente
		if not oponente or not oponente.Parent then
			duelosActivos[player] = nil
			return
		end
		local dataOpo = duelosActivos[oponente]
		if dataOpo and dataOpo.listo then
			local clicksA = data.clicks
			local clicksB = dataOpo.clicks
			local ganador = (clicksA > clicksB) and player
				or (clicksB > clicksA) and oponente
				or (ctx.getStat(player, "Nivel") >= ctx.getStat(oponente, "Nivel") and player or oponente)

			local monedas = Config.getMonedasPvP(ctx.getStat(ganador, "Nivel"))
			ctx.agregarMonedas(ganador, monedas)
			do
				local function markWin(p)
					ctx.setStat(p, "Victorias", ctx.getStat(p, "Victorias") + 1)
					if ctx.leaderboardOnStatChanged then
						ctx.leaderboardOnStatChanged(p, "Victorias", ctx.getStat(p, "Victorias"))
					end
					local mg = playerMetrics[p]
					if not mg then return end
					mg.wins = (mg.wins or 0) + 1
					mg.lastProgress = tick()
					mg.streakWins = (mg.streakWins or 0) + 1
					mg.streakLosses = 0
					mg.duelResults = mg.duelResults or {}
					table.insert(mg.duelResults, { t = tick(), win = true })
					while #mg.duelResults > 20 do table.remove(mg.duelResults, 1) end
				end
				local function markLoss(p)
					local mg = playerMetrics[p]
					if not mg then return end
					mg.losses = (mg.losses or 0) + 1
					mg.streakLosses = (mg.streakLosses or 0) + 1
					mg.streakWins = 0
					mg.duelResults = mg.duelResults or {}
					table.insert(mg.duelResults, { t = tick(), win = false })
					while #mg.duelResults > 20 do table.remove(mg.duelResults, 1) end
				end
				if typeof(ganador) == "Instance" then markWin(ganador) end
				local perdedor = (ganador == player) and oponente or player
				if typeof(perdedor) == "Instance" and perdedor ~= ganador then markLoss(perdedor) end
			end

			MostrarResultados:FireClient(player, {
				resultado = (player == ganador) and "Victoria" or "Derrota",
				misClicks = clicksA, oponenteClicks = clicksB, esBot = false,
				recompensa = (player == ganador) and monedas or 0
			})
			MostrarResultados:FireClient(oponente, {
				resultado = (oponente == ganador) and "Victoria" or "Derrota",
				misClicks = clicksB, oponenteClicks = clicksA, esBot = false,
				recompensa = (oponente == ganador) and monedas or 0
			})
			duelosActivos[player] = nil
			duelosActivos[oponente] = nil
		end
	end
end)

-- =====================================================
-- PROCESAR COMPRAS ROBUX
-- =====================================================

-- =====================================================
-- RECOMPENSAS DIARIAS
-- =====================================================
function ctx.dayKey()
	return math.floor(os.time() / 86400)
end

function ctx.getDailyState(player)
	if not dailyData[player] then
		local cached = dailyByUserId[player.UserId]
		if cached then
			dailyData[player] = { lastDay = cached.lastDay or 0, streak = cached.streak or 0 }
		else
			dailyData[player] = { lastDay = 0, streak = 0 }
		end
	end
	return dailyData[player]
end

ClaimDaily.OnServerEvent:Connect(function(player)
	if not player or not player.Parent then return end
	local st = ctx.getDailyState(player)
	local today = ctx.dayKey()

	-- Anti-exploit: también mirar cache por UserId
	local cached = dailyByUserId[player.UserId]
	if cached and cached.lastDay == today then
		st.lastDay = today
		st.streak = cached.streak or st.streak
	end

	if st.lastDay == today then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Ya reclamaste la recompensa de hoy" })
		SyncDaily:FireClient(player, { canClaim = false, streak = st.streak, nextIn = 86400 - (os.time() % 86400) })
		return
	end

	if st.lastDay == today - 1 then
		st.streak = math.max(1, (st.streak or 0) + 1)
	else
		st.streak = 1
	end
	st.lastDay = today

	-- Persistir YA en cache (antes de dar recompensa)
	dailyByUserId[player.UserId] = { lastDay = st.lastDay, streak = st.streak }
	dailyData[player] = st

	local reward = Config.getDailyReward(st.streak)
	ctx.agregarMonedas(player, reward.monedas)
	ctx.agregarXP(player, reward.xp)
	if reward.antiSegundos and reward.antiSegundos > 0 then
		local ahora = tick()
		local actual = antiAnclajeHasta[player] or 0
		antiAnclajeHasta[player] = math.max(actual, ahora) + reward.antiSegundos
		ctx.syncProteccionCliente(player)
	end
	if ctx.tutorialActive and ctx.tutorialActive[player] then
		ctx.tutorialDailyClaimed[player] = true
	end

	-- Guardado forzado inmediato
	local saved = ctx.guardarDatos(player)
	print("[Daily] Claim", player.Name, "day", today, "streak", st.streak, "saved=", saved)

	NotificarCliente:FireClient(player, {
		tipo = "exito",
		mensaje = string.format("Daily día %d: +%d monedas +%d XP", reward.streak, reward.monedas, reward.xp)
	})
	SyncDaily:FireClient(player, {
		canClaim = false,
		streak = st.streak,
		nextIn = 86400 - (os.time() % 86400),
		claimed = true,
		reward = reward,
	})
end)

-- Load daily from datastore on join - hook after cargarDatos in PlayerAdded
-- We'll patch PlayerAdded



MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local pid = receiptInfo.ProductId
	local info = Config.getRobuxProductoPorId(pid)
	if not info then
		warn("[Robux] ProductId desconocido:", pid)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if info.source == "MONEDAS_ROBUX" then
		local pack = info.pack
		local amount = pack and pack.monedas or 0
		if amount > 0 then
			ctx.agregarMonedas(player, amount)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡+" .. amount .. " Monedas!" })
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	elseif info.source == "ROBUX" then
		local def = info.def
		local key = info.key
		if key == "ESCUDO_LEGENDARIO" or def.segundosAnti then
			local ahora = tick()
			local actual = antiAnclajeHasta[player] or 0
			local secs = def.segundosAnti or 7200
			antiAnclajeHasta[player] = math.max(actual, ahora) + secs
			ctx.syncProteccionCliente(player)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (def.nombre or "Escudo") .. " activado!" })
		elseif def.clicksExtra then
			local actual = ctx.getStat(player, "ClicksRobux")
			ctx.setStat(player, "ClicksRobux", actual + def.clicksExtra)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡+" .. def.clicksExtra .. " Clicks/Click!" })
		elseif def.nivelesVel then
			local actual = ctx.getStat(player, "VelocidadAnclajeRobux")
			ctx.setStat(player, "VelocidadAnclajeRobux", actual + def.nivelesVel)
			local delta = Config.formatDeltaSegundos and Config.formatDeltaSegundos(def.nivelesVel) or ("-" .. (def.nivelesVel * 0.1) .. "s")
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡Anclaje más rápido " .. delta .. "!" })
		elseif def.nivelesWalk then
			local actual = ctx.getStat(player, "VelocidadMovimientoRobux")
			ctx.setStat(player, "VelocidadMovimientoRobux", actual + def.nivelesWalk)
			ctx.aplicarEstadoLibre(player)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡+" .. def.nivelesWalk .. " Correr!" })
		else
			warn("[Robux] ROBUX key sin handler:", key)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	elseif info.source == "PROMO" then
		local tier = info.tier
		local trackId = info.trackId
		promoTiers[player] = promoTiers[player] or {}
		local cur = promoTiers[player][trackId] or 1
		-- Solo avanzar si compran el tier actual o superior
		if info.tierIdx >= cur then
			promoTiers[player][trackId] = math.min(info.tierIdx + 1, #info.track.tiers)
		end

		if tier.multiAdd then
			local actual = ctx.getStat(player, "MultiXP")
			-- MultiXP puede ser NumberValue
			local ls = player:FindFirstChild("leaderstats")
			local mv = ls and ls:FindFirstChild("MultiXP")
			if mv then
				mv.Value = (tonumber(mv.Value) or 1) + tier.multiAdd
			end
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or "Multi XP") .. "!" })
		elseif tier.niveles and info.trackId == "nivel" then
			for _ = 1, tier.niveles do
				local nivel = ctx.getStat(player, "Nivel")
				ctx.setStat(player, "Nivel", nivel + 1)
				ctx.setStat(player, "MaxXP", ctx.getMaxXP(nivel + 1))
				ctx.setStat(player, "XP", 0)
			end
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or "Nivel") .. "!" })
		elseif tier.clicks then
			ctx.setStat(player, "ClicksRobux", ctx.getStat(player, "ClicksRobux") + tier.clicks)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or "Clicks") .. "!" })
		elseif tier.niveles and info.trackId == "vel_anclaje" then
			ctx.setStat(player, "VelocidadAnclajeRobux", ctx.getStat(player, "VelocidadAnclajeRobux") + tier.niveles)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or Config.formatDeltaSegundos(tier.niveles) or "Anclaje") .. "!" })
		elseif tier.niveles and info.trackId == "correr" then
			ctx.setStat(player, "VelocidadMovimientoRobux", ctx.getStat(player, "VelocidadMovimientoRobux") + tier.niveles)
			ctx.aplicarEstadoLibre(player)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or "Correr") .. "!" })
		elseif tier.monedas then
			ctx.agregarMonedas(player, tier.monedas)
			NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡" .. (tier.label or "Monedas") .. "!" })
		else
			warn("[Robux] PROMO sin handler", trackId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Avisar cliente del nuevo tier para la promo
		NotificarCliente:FireClient(player, {
			tipo = "promo_tier",
			trackId = trackId,
			tier = promoTiers[player][trackId] or 1,
		})
	end

	ctx.guardarDatos(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local anclarABot



-- =====================================================
-- RECOMENDACIONES INTELIGENTES
-- =====================================================

-- =====================================================
-- RECOMENDACIONES INTELIGENTES (scoring competitivo)
-- =====================================================
-- Arquitectura extensible:
-- 1) ctx.buildPlayerSnapshot(player) → estado completo
-- 2) collectCandidates(snapshot) → lista {kind, score, ...}
-- 3) Se elige el de mayor score si supera umbral mínimo
-- Añadir productos: registrar en Config.ROBUX_PROMO.TRACKS (auto-detectado)
-- Añadir acciones (rebirth): añadir generador en collectCandidates

function ctx.getPromoTierIdx(player, trackId)
	local t = promoTiers[player]
	return (t and t[trackId]) or 1
end

function ctx.pickPromoProduct(player, trackId)
	local track, tier, idx = Config.getPromoTier(trackId, ctx.getPromoTierIdx(player, trackId))
	if not track or not tier then return nil end
	if not tier.productId or tier.productId == 0 then return nil end
	return {
		kind = "product",
		trackId = trackId,
		track = track,
		tier = tier,
		tierIdx = idx,
		productId = tier.productId,
		score = 0,
		razon = "",
	}
end

function ctx.buildPlayerSnapshot(player)
	local m = playerMetrics[player] or {}
	local ahora = tick()
	local nivel = ctx.getStat(player, "Nivel")
	local monedas = ctx.getStat(player, "Monedas")
	local xp = ctx.getStat(player, "XP")
	local maxXP = math.max(1, ctx.getStat(player, "MaxXP"))
	local minR, maxR = Config.getRangoMonedas(nivel)
	local centroR = (minR + maxR) / 2
	local session = math.max(1, ahora - (m.sessionStart or ahora))
	local sinNivel = ahora - (m.lastLevelUp or m.sessionStart or ahora)
	local sinProgreso = ahora - (m.lastProgress or m.sessionStart or ahora)
	local minRebirth = Config.getNivelMinimoRebirth(ctx.getStat(player, "Rebirths"))
	local rebirths = ctx.getStat(player, "Rebirths")
	local multiXP = ctx.getStat(player, "MultiXP")
	local multiCk = ctx.getStat(player, "MultiClicks")
	local clicks = ctx.getStat(player, "ClicksPorClick")
	local vel = ctx.getStat(player, "VelocidadAnclaje")
	local walk = ctx.getStat(player, "VelocidadMovimiento")
	local maxClicks = Config.getMaxClicks(nivel)
	local maxVel = Config.getMaxVelAnclaje(nivel)
	local maxWalk = Config.getMaxWalk(nivel)
	local xpFrac = xp / maxXP
	local moneyRatio = monedas / math.max(1, minR)
	local anchors = m.anchors or 0
	local anchorsR = m.anchorsRecent or 0
	local expR = m.expulsionsRecent or 0
	local wins = m.wins or 0
	local losses = m.losses or 0
	local duelTotal = wins + losses
	local lossRate = duelTotal > 0 and (losses / duelTotal) or 0
	local ancladoAhora = ancladoA[player] ~= nil
	local intervalo = Config.getIntervaloAnclaje(vel)

	return {
		player = player,
		ahora = ahora,
		session = session,
		nivel = nivel,
		monedas = monedas,
		xp = xp,
		maxXP = maxXP,
		xpFrac = xpFrac,
		minR = minR,
		maxR = maxR,
		centroR = centroR,
		moneyRatio = moneyRatio,
		sinNivel = sinNivel,
		sinProgreso = sinProgreso,
		minRebirth = minRebirth,
		rebirths = rebirths,
		multiXP = multiXP,
		multiCk = multiCk,
		clicks = clicks,
		vel = vel,
		walk = walk,
		maxClicks = maxClicks,
		maxVel = maxVel,
		maxWalk = maxWalk,
		anchors = anchors,
		anchorsR = anchorsR,
		expR = expR,
		wins = wins,
		losses = losses,
		lossRate = lossRate,
		ancladoAhora = ancladoAhora,
		intervalo = intervalo,
		puedeRebirth = nivel >= minRebirth,
		cercaRebirth = nivel >= minRebirth - 2 and nivel < minRebirth,
		estancadoNivel = sinNivel > ((Config.RECOMENDACIONES and Config.RECOMENDACIONES.ESTANCAMIENTO_NIVEL_S) or 180),
		pobre = monedas < minR * ((Config.RECOMENDACIONES and Config.RECOMENDACIONES.POCO_DINERO_RATIO) or 0.4),
		streakLosses = m.streakLosses or 0,
		streakWins = m.streakWins or 0,
		anchors1m = ctx.countSince(m.anchorTimes, 60),
		anchors5m = ctx.countSince(m.anchorTimes, 300),
		expulsions5m = ctx.countSince(m.expulsionTimes, 300),
		_raw = m,
	}
end


-- Generadores: cada factor aporta puntos y se registra en `factores` para DEBUG
ctx.candidateGenerators = ctx.candidateGenerators or {}
candidateGenerators = ctx.candidateGenerators

function ctx.addFactor(factores, pts, texto)
	if pts and pts ~= 0 then
		table.insert(factores, { pts = pts, texto = texto })
	end
	return pts or 0
end

table.insert(candidateGenerators, function(s, player)
	if not s.puedeRebirth then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 40, "base: ya puede hacer Rebirth (nv>=" .. s.minRebirth .. ")")
	local extraNiv = math.min(40, (s.nivel - s.minRebirth) * 8)
	score = score + ctx.addFactor(factores, extraNiv, string.format("nivel %d sobre mínimo (+%d)", s.nivel, extraNiv))
	if s.estancadoNivel then
		score = score + ctx.addFactor(factores, 25, string.format("estancado sin subir nivel (%.0fs)", s.sinNivel))
	end
	if s.sinProgreso > 120 then
		score = score + ctx.addFactor(factores, 15, string.format("sin progreso general (%.0fs)", s.sinProgreso))
	end
	if s.xpFrac < 0.15 then
		score = score + ctx.addFactor(factores, 20, string.format("XP baja en nivel actual (%.0f%%)", s.xpFrac * 100))
	end
	local nextMulti = s.multiXP * Config.getMultiXPAlRebirth((s.rebirths or 0) + 1)
	local multiPts = math.min(20, (nextMulti - s.multiXP) * 10)
	score = score + ctx.addFactor(factores, multiPts, string.format("salto MultiXP x%.2f→x%.2f", s.multiXP, nextMulti))
	return {{
		kind = "rebirth", score = score, factores = factores,
		razon = string.format("Multi XP x%.2f → x%.2f", s.multiXP, nextMulti),
		titulo = "Hacer REBIRTH",
		label = string.format("Multi XP x%.2f → x%.2f | Clicks x%.2f → x%.2f",
			s.multiXP, nextMulti, s.multiCk, s.multiCk * Config.getMultiClicksAlRebirth((s.rebirths or 0) + 1)),
	}}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "monedas")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: %d💰 | rango nv%d = %d-%d | ratio=%.2f", s.monedas, s.nivel, s.minR, s.maxR, s.moneyRatio))
	if s.pobre then
		score = score + ctx.addFactor(factores, 70, string.format("muy pobre (<%.0f%% del mínimo)", (Config.RECOMENDACIONES.POCO_DINERO_RATIO or 0.4)*100))
	end
	if s.moneyRatio < 1 then
		local pts = (1 - s.moneyRatio) * 40
		score = score + ctx.addFactor(factores, pts, string.format("por debajo del mínimo del rango (ratio %.2f)", s.moneyRatio))
	end
	if s.moneyRatio < 0.2 then
		score = score + ctx.addFactor(factores, 25, "ratio < 0.2 (crisis de dinero)")
	end
	if s.sinProgreso > 90 and s.monedas < s.centroR then
		score = score + ctx.addFactor(factores, 20, string.format("sin progreso %.0fs y bajo el centro del rango", s.sinProgreso))
	end
	p.score = score
	p.factores = factores
	p.razon = s.pobre and "Muy poco dinero para tu nivel" or "Refuerza tu economía"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "nivel")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: nv%d XP %.0f%% | sin subir %.0fs | anclajes 1m=%d 5m=%d", s.nivel, s.xpFrac*100, s.sinNivel, s.anchors1m or 0, s.anchors5m or 0))
	if s.cercaRebirth then
		score = score + ctx.addFactor(factores, 80, string.format("cerca de Rebirth (nv%d / %d)", s.nivel, s.minRebirth))
	end
	if s.estancadoNivel then
		score = score + ctx.addFactor(factores, 55, string.format("estancado de nivel (%.0fs sin subir)", s.sinNivel))
	end
	if s.xpFrac >= 0.65 then
		local pts = 35 + s.xpFrac * 20
		score = score + ctx.addFactor(factores, pts, string.format("barra XP al %.0f%% (casi sube)", s.xpFrac*100))
	end
	if s.sinNivel > 240 then
		score = score + ctx.addFactor(factores, 30, "más de 4 min sin subir nivel")
	end
	if (s.anchors5m or 0) >= 6 and s.estancadoNivel then
		score = score + ctx.addFactor(factores, 25, string.format("%d anclajes en 5 min sin subir nivel", s.anchors5m))
	end
	p.score = score
	p.factores = factores
	p.razon = s.cercaRebirth and "Casi listo para Rebirth" or "Acelera subidas de nivel"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "multi_xp")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: MultiXP x%.2f | anclajes 1m=%d 5m=%d | anclado_ahora=%s", s.multiXP, s.anchors1m or 0, s.anchors5m or 0, tostring(s.ancladoAhora)))
	if s.estancadoNivel then
		score = score + ctx.addFactor(factores, 45, string.format("estancado nivel (%.0fs)", s.sinNivel))
	end
	if (s.anchors1m or 0) >= 3 then
		score = score + ctx.addFactor(factores, 40, string.format("%d anclajes en el último minuto", s.anchors1m))
	elseif (s.anchors5m or 0) >= 5 then
		score = score + ctx.addFactor(factores, 30, string.format("%d anclajes en 5 min", s.anchors5m))
	end
	if s.ancladoAhora then
		score = score + ctx.addFactor(factores, 15, "está anclado ahora → MultiXP rinde al momento")
	end
	if s.sinNivel > 120 then
		score = score + ctx.addFactor(factores, 25, "sin subir nivel > 2 min")
	end
	p.score = score
	p.factores = factores
	p.razon = "Más XP por cada tick de anclaje"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "clicks")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: clicks=%d | W/L=%d/%d | racha_derrotas=%d | lossRate=%.0f%%", s.clicks, s.wins, s.losses, s.streakLosses or 0, s.lossRate*100))
	if (s.streakLosses or 0) >= 3 then
		score = score + ctx.addFactor(factores, 90, string.format("%d derrotas SEGUIDAS en duelos", s.streakLosses))
	elseif (s.streakLosses or 0) >= 2 then
		score = score + ctx.addFactor(factores, 55, string.format("%d derrotas seguidas", s.streakLosses))
	end
	if s.lossRate >= 0.6 and (s.wins + s.losses) >= 3 then
		score = score + ctx.addFactor(factores, 50, string.format("%.0f%% de derrotas en %d duelos", s.lossRate*100, s.wins+s.losses))
	end
	if s.losses >= 2 and (s.streakLosses or 0) < 2 then
		score = score + ctx.addFactor(factores, 25, string.format("%d derrotas totales (sesión)", s.losses))
	end
	local expected = math.max(1, math.floor(s.nivel / 2))
	if s.clicks < expected then
		score = score + ctx.addFactor(factores, 40, string.format("clicks %d < esperado ~%d para nv%d", s.clicks, expected, s.nivel))
	end
	if s.clicks < s.maxClicks * 0.3 then
		score = score + ctx.addFactor(factores, 25, string.format("clicks muy bajo vs tope de nivel (%d/%d)", s.clicks, s.maxClicks))
	end
	p.score = score
	p.factores = factores
	p.razon = ((s.streakLosses or 0) >= 2) and "Racha de derrotas en duelos" or "Más poder por click"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "vel_anclaje")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: intervalo=%.2fs | vel=%d | anclajes1m=%d | expulsiones5m=%d", s.intervalo, s.vel, s.anchors1m or 0, s.expulsions5m or 0))
	if (s.anchors5m or 0) >= 5 and s.estancadoNivel then
		score = score + ctx.addFactor(factores, 60, string.format("%d anclajes/5min + estancado de nivel", s.anchors5m))
	end
	if (s.expulsions5m or 0) >= 2 then
		score = score + ctx.addFactor(factores, 55, string.format("%d expulsiones en 5 min → saca XP más rápido", s.expulsions5m))
	elseif (s.expulsions5m or 0) >= 1 then
		score = score + ctx.addFactor(factores, 30, "expulsado recientemente")
	end
	if s.intervalo > 0.6 then
		score = score + ctx.addFactor(factores, 30, string.format("intervalo lento %.2fs (>0.6s)", s.intervalo))
	end
	if s.ancladoAhora and s.intervalo >= 0.8 then
		score = score + ctx.addFactor(factores, 20, "anclado ahora con intervalo lento")
	end
	p.score = score
	p.factores = factores
	p.razon = "Gana XP más a menudo al anclarte"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local p = ctx.pickPromoProduct(player, "correr")
	if not p then return {} end
	local factores = {}
	local score = 0
	score = score + ctx.addFactor(factores, 0, string.format("datos: walk=%d | anclajes_sesión=%d | sesión=%.0fs", s.walk, s.anchors, s.session))
	if s.walk < 3 and s.nivel >= 3 then
		score = score + ctx.addFactor(factores, 30, string.format("walk bajo (%d) con nivel %d", s.walk, s.nivel))
	end
	if s.anchors < 2 and s.session > 90 then
		score = score + ctx.addFactor(factores, 25, string.format("solo %d anclajes en %.0fs de sesión (¿no llega a objetivos?)", s.anchors, s.session))
	end
	if s.walk < s.maxWalk * 0.2 then
		score = score + ctx.addFactor(factores, 15, string.format("walk %d << tope %d", s.walk, s.maxWalk))
	end
	p.score = score
	p.factores = factores
	p.razon = "Muévete más rápido por el mapa"
	return score > 0 and {p} or {}
end)

table.insert(candidateGenerators, function(s, player)
	local out = {}
	local known = { monedas = true, nivel = true, multi_xp = true, clicks = true, vel_anclaje = true, correr = true }
	for _, track in ipairs(Config.ROBUX_PROMO and Config.ROBUX_PROMO.TRACKS or {}) do
		if not known[track.id] then
			local p = ctx.pickPromoProduct(player, track.id)
			if p then
				local factores = {}
				local score = 10
				ctx.addFactor(factores, 10, "track nuevo genérico")
				if s.estancadoNivel then score = score + ctx.addFactor(factores, 20, "estancado nivel") end
				p.score = score
				p.factores = factores
				p.razon = "Puede ayudarte ahora"
				table.insert(out, p)
			end
		end
	end
	return out
end)


end
