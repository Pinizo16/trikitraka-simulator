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

function ctx.evaluarRecomendaciones(player)
	local cfg = Config.RECOMENDACIONES
	if not cfg then return nil end
	local m = playerMetrics[player]
	if not m then return nil end
	local ahora = tick()
	if (ahora - (m.sessionStart or ahora)) < (cfg.MIN_SESSION or 40) then
		if cfg.DEBUG then
			if cfg.DEBUG then print(string.format("[Rec][%s] skip: sesión %.0fs < MIN_SESSION", player.Name, ahora - (m.sessionStart or ahora))) end
		end
		return nil
	end
	local last = ultimaRecomendacion[player] or 0
	if (ahora - last) < (cfg.COOLDOWN_SEGUNDOS or 180) then
		if cfg.DEBUG then
			if cfg.DEBUG then print(string.format("[Rec][%s] skip: cooldown (%.0fs restantes)", player.Name, (cfg.COOLDOWN_SEGUNDOS or 180) - (ahora - last))) end
		end
		return nil
	end

	if (ahora - (m.windowStart or 0)) > 300 then
		m.anchorsRecent = 0
		m.expulsionsRecent = 0
		m.windowStart = ahora
	end

	local snap = ctx.buildPlayerSnapshot(player)
	if cfg.DEBUG then
		print(string.format(
			"[Rec][%s] SNAP nv=%d XP=%.0f%% monedas=%d (rango %d-%d) MultiXP=x%.2f clicks=%d walk=%d vel=%d | anclajes1m=%d anclajes5m=%d exp5m=%d | W/L=%d/%d rachaPerd=%d | sinNivel=%.0fs sesión=%.0fs",
			player.Name, snap.nivel, snap.xpFrac*100, snap.monedas, snap.minR, snap.maxR, snap.multiXP, snap.clicks, snap.walk, snap.vel,
			snap.anchors1m or 0, snap.anchors5m or 0, snap.expulsions5m or 0, snap.wins, snap.losses, snap.streakLosses or 0,
			snap.sinNivel, snap.session
		))
	end

	local candidatos = {}
	local gens = ctx.candidateGenerators or candidateGenerators or {}
	for _, gen in ipairs(gens) do
		local ok, res = pcall(gen, snap, player)
		if ok and typeof(res) == "table" then
			for _, c in ipairs(res) do
				table.insert(candidatos, c)
			end
		elseif not ok and cfg.DEBUG then
			warn("[Rec] generador error:", res)
		end
	end

	if #candidatos == 0 then
		if cfg.DEBUG then print(string.format("[Rec][%s] sin candidatos con score>0", player.Name)) end
		return nil
	end
	table.sort(candidatos, function(a, b) return (a.score or 0) > (b.score or 0) end)

	if cfg.DEBUG then
		if cfg.DEBUG then print(string.format("[Rec][%s] === ranking (%d) ===", player.Name, #candidatos)) end
		for i, c in ipairs(candidatos) do
			local tag = c.kind == "rebirth" and "REBIRTH" or (c.trackId or c.kind or "?")
			if cfg.DEBUG then print(string.format("  #%d  score=%.1f  [%s]  %s", i, c.score or 0, tag, c.razon or "")) end
			for _, f in ipairs(c.factores or {}) do
				local sign = (f.pts or 0) >= 0 and "+" or ""
				if cfg.DEBUG then print(string.format("       %s%.1f  →  %s", sign, f.pts or 0, f.texto or "")) end
			end
		end
	end

	local best = candidatos[1]
	local umbral = cfg.SCORE_MINIMO or 45
	if (best.score or 0) < umbral then
		if cfg.DEBUG then
			if cfg.DEBUG then print(string.format("[Rec][%s] mejor %.1f < umbral %d → no mostrar", player.Name, best.score or 0, umbral)) end
		end
		return nil
	end
	if cfg.DEBUG then
		local tag = best.kind == "rebirth" and "REBIRTH" or (best.trackId or "?")
		if cfg.DEBUG then print(string.format("[Rec][%s] ★ ELEGIDA: %s (%.1f) — %s", player.Name, tag, best.score or 0, best.razon or "")) end
	end
	return best
end


function ctx.enviarRecomendacion(player)
	local rec = ctx.evaluarRecomendaciones(player)
	if not rec then return false end
	ultimaRecomendacion[player] = tick()

	if rec.kind == "rebirth" then
		NotificarCliente:FireClient(player, {
			tipo = "promo_smart",
			accion = "rebirth",
			titulo = rec.titulo or "REBIRTH",
			label = rec.label or "Reinicia con ventajas permanentes",
			razon = rec.razon,
			score = rec.score,
		})
	else
		NotificarCliente:FireClient(player, {
			tipo = "promo_smart",
			accion = "product",
			trackId = rec.trackId,
			tierIdx = rec.tierIdx,
			productId = rec.productId,
			precioFallback = rec.tier and rec.tier.precio,
			label = rec.tier and rec.tier.label,
			titulo = (rec.track and rec.track.titulo or "Oferta"),
			razon = rec.razon,
			tiersTotal = rec.track and #rec.track.tiers or 1,
			score = rec.score,
		})
	end
	return true
end

task.spawn(function()
	task.wait((Config.RECOMENDACIONES and Config.RECOMENDACIONES.PRIMERA_ESPERA) or 60)
	while true do
		for _, plr in ipairs(Players:GetPlayers()) do
			-- BUGFIX: antes se llamaba enviarRecomendacion (nil) → nunca salían promos
			local ok, err = pcall(function()
				ctx.enviarRecomendacion(plr)
			end)
			if not ok and Config.RECOMENDACIONES and Config.RECOMENDACIONES.DEBUG then
				warn("[Rec] error enviar:", err)
			end
		end
		task.wait((Config.RECOMENDACIONES and Config.RECOMENDACIONES.COOLDOWN_SEGUNDOS) or 180)
	end
end)

-- =====================================================
-- BOTS AMBULANTES
-- =====================================================
function ctx.getHRP(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

function ctx.setupBotAnimate(model)
	if model:GetAttribute("BotAnimateOK") then return end
	-- Animaciones de bots van en el cliente (AnimLOD). Servidor solo mueve.
	local cfg0 = Config.BOTS_AMBULANTES or {}
	if cfg0.SERVER_PLAY_ANIM == false then
		model:SetAttribute("BotAnimateOK", true)
		model:SetAttribute("EsBotAmbulante", model:GetAttribute("EsBotAmbulante") or true)
		return
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local cfg = Config.BOTS_AMBULANTES or {}
	local function loadTrack(id)
		local a = Instance.new("Animation")
		a.AnimationId = id
		local track = animator:LoadAnimation(a)
		track.Priority = Enum.AnimationPriority.Core
		track.Looped = true
		return track
	end
	local walkTrack = loadTrack(cfg.WALK_ANIM_ID or "rbxassetid://507777826")
	local idleTrack = loadTrack("rbxassetid://507766388")
	local sitTrack = loadTrack("rbxassetid://2506281703")
	local current = nil
	local function play(track)
		if current == track then return end
		if current then pcall(function() current:Stop(0.15) end) end
		current = track
		pcall(function() track:Play(0.15) end)
	end
	play(idleTrack)
	hum.Running:Connect(function(speed)
		if hum.Sit then play(sitTrack) return end
		if speed > 0.5 then
			play(walkTrack)
			pcall(function() walkTrack:AdjustSpeed(math.clamp(speed / 16, 0.5, 2)) end)
		else play(idleTrack) end
	end)
	hum.Seated:Connect(function(isSeated)
		if isSeated then play(sitTrack) else play(idleTrack) end
	end)
	task.spawn(function()
		local hrp = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if not hrp then return end
		local last = hrp.Position
		while model.Parent do
			task.wait(0.2)
			if not hum.Parent then break end
			if hum.Sit then play(sitTrack)
			else
				local pos = hrp.Position
				local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(last.X, 0, last.Z)).Magnitude
				last = pos
				if dist > 0.15 then play(walkTrack)
				elseif current == walkTrack then play(idleTrack) end
			end
		end
	end)
	model:SetAttribute("BotAnimateOK", true)
end

local anclarABot
local setupBotAmbulante
function setupBotAmbulante(model)
	if not model or not model:IsA("Model") then return end
	if botsAmbulantes[model] then return end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local hrp = ctx.getHRP(model)
	if not hum or not hrp then
		warn("[BotsAmb] Falta Humanoid/HRP en", model:GetFullName())
		return
	end
	model:SetAttribute("EsBotAmbulante", true)
	ctx.setupBotAnimate(model)
	local cfg = Config.BOTS_AMBULANTES
	local speed = cfg.WALK_SPEED_MIN + math.random() * (cfg.WALK_SPEED_MAX - cfg.WALK_SPEED_MIN)
	hum.WalkSpeed = speed
	hum.MaxHealth = 1e9
	hum.Health = hum.MaxHealth
	pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)

	local botId = model:GetAttribute("BotAmbId")
	if typeof(botId) ~= "string" or botId == "" then
		botId = "bot_" .. tostring(math.floor(tick() * 1000) % 100000000) .. "_" .. tostring(math.random(1000, 9999))
		model:SetAttribute("BotAmbId", botId) -- interno, no se muestra
	end
	local data = {
		id = botId,
		xp = cfg.XP_RESERVA_INICIAL or 40,
		speed = speed,
		lastXpGen = tick(),
		lastExpulsionCheck = tick(),
		origin = hrp.Position,
	}
	botsAmbulantes[model] = data

	-- Solo física/movimiento en servidor. Animaciones = cliente (AnimLOD + distancia).
	do
		if hrp.Anchored then
			hrp.Anchored = false
		end
		-- Asegurar Animator vacío (sin tracks del servidor)
		local animator = hum:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = hum
		else
			for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
				pcall(function() tr:Stop(0) end)
			end
		end
		data.walkTrack = nil
	end

	-- Prompt anclar (mismas props que jugadores / bots de batalla)
	local viejo = hrp:FindFirstChild("PromptAnclar")
	if viejo then viejo:Destroy() end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PromptAnclar"
	prompt.ActionText = "Triki Traka"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.05
	prompt.MaxActivationDistance = cfg.PROMPT_DISTANCIA or 12
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ClickablePrompt = true
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	prompt:SetAttribute("PromptKind", "anclar")
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = true
	prompt.Parent = hrp
	prompt.Triggered:Connect(function(player)
		anclarABot(player, model)
	end)

	-- Movimiento autónomo
	task.spawn(function()
		while model.Parent and botsAmbulantes[model] do
			local waitT = cfg.MOVE_WAIT_MIN + math.random() * (cfg.MOVE_WAIT_MAX - cfg.MOVE_WAIT_MIN)
			task.wait(waitT)
			if not model.Parent or not botsAmbulantes[model] then break end
			local h = model:FindFirstChildOfClass("Humanoid")
			local root = ctx.getHRP(model)
			if not (h and root) then break end
			-- No moverse si alguien está anclado a este bot
			local ocupado = false
			for anclado, obj in pairs(ancladoA) do
				if obj == model then ocupado = true break end
			end
			if not ocupado then
				local radio = cfg.RADIO_PATRULLA or 100
				local ang = math.random() * math.pi * 2
				local dist = math.random() * radio
				local dest = data.origin + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
				h.WalkSpeed = data.speed
				-- Animación caminar
				-- Walk anim: solo cliente (AnimLOD)
				h:MoveTo(dest)
				-- Esperar llegada o timeout y parar anim
				local t0 = tick()
				while model.Parent and botsAmbulantes[model] and tick() - t0 < 12 do
					if (ctx.getHRP(model).Position - dest).Magnitude < 4 then break end
					-- Si alguien se ancla, salir
					local busy = false
					for a, o in pairs(ancladoA) do
						if o == model then busy = true break end
					end
					if busy then break end
					task.wait(0.2)
				end
				if data.walkTrack then
					pcall(function() data.walkTrack:Stop(0.25) end)
				end
			else
				if data.walkTrack then
					pcall(function() data.walkTrack:Stop(0.2) end)
				end
			end
		end
	end)

	print("[BotsAmb] OK:", model:GetFullName(), "speed", string.format("%.1f", speed))
end

anclarABot = function(player, model)
	if not player or not model or not botsAmbulantes[model] then return end
	if ancladoA[player] then return end
	do
		local ck = ctx.cooldownKeyFor(model)
		if cooldownReanclar[ck] and cooldownReanclar[ck][player] and tick() < cooldownReanclar[ck][player] then
			local resto = math.ceil(cooldownReanclar[ck][player] - tick())
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Debes esperar " .. resto .. "s para volver a anclarte a este bot" })
			return
		end
	end
	if ancladosEn[model] and next(ancladosEn[model]) then
		NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Alguien ya está anclado a este bot" })
		return
	end
	local char = player.Character
	local charB = model
	if not (char and charB) then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hrpB = ctx.getHRP(model)
	if not (hrp and hrpB) then return end

	ancladoA[player] = model
	ancladosEn[model] = ancladosEn[model] or {}
	ancladosEn[model][player] = true
	local m = playerMetrics[player]
	if m then
		m.anchors = (m.anchors or 0) + 1
		m.anchorsRecent = (m.anchorsRecent or 0) + 1
		m.anchorTimes = m.anchorTimes or {}
		ctx.pushMetricTime(m.anchorTimes, 40)
	end
	ctx.crearWeldAnclaje(player, model)
	ctx.aplicarEstadoAnclado(player)
	NotificarCliente:FireClient(player, { tipo = "anclado", mensaje = "Anclado a bot " .. model.Name })
end

-- Generación XP + expulsión aleatoria bots
task.spawn(function()
	local cfg = Config.BOTS_AMBULANTES
	if not cfg then return end
	while true do
		task.wait(0.25)
		local ahora = tick()
		for model, data in pairs(botsAmbulantes) do
			if not model.Parent then
				botsAmbulantes[model] = nil
				continue
			end
			if ahora - data.lastXpGen >= (cfg.XP_GEN_INTERVALO or 0.5) then
				data.lastXpGen = ahora
				data.xp = math.min(cfg.XP_RESERVA_MAX or 400, data.xp + (cfg.XP_GEN_CANTIDAD or 1))
			end
			if ahora - data.lastExpulsionCheck >= (cfg.EXPULSION_CHECK_S or 15) then
				data.lastExpulsionCheck = ahora
				if math.random() < (cfg.EXPULSION_CHANCE or 0.12) then
					local lista = {}
					for a in pairs(ancladosEn[model] or {}) do
						table.insert(lista, a)
					end
					if #lista > 0 then
						local victima = lista[math.random(1, #lista)]
						ctx.desanclar(victima)
						local ck = (data and data.id) or ctx.cooldownKeyFor(model)
						cooldownReanclar[ck] = cooldownReanclar[ck] or {}
						cooldownReanclar[ck][victima] = tick() + (Config.COOLDOWN_REANCLAR or 45)
						NotificarCliente:FireClient(victima, {
							tipo = "error",
							mensaje = model.Name .. " te ha expulsado. Espera " .. tostring(Config.COOLDOWN_REANCLAR or 45) .. "s",
						})
						local m = playerMetrics[victima]
						if m then
							m.expulsions = (m.expulsions or 0) + 1
							m.expulsionsRecent = (m.expulsionsRecent or 0) + 1
							m.expulsionTimes = m.expulsionTimes or {}
							ctx.pushMetricTime(m.expulsionTimes, 30)
						end
					end
				end
			end
		end
	end
end)

-- Modificar tick XP: si objetivo es bot, gastar reserva
-- (el Heartbeat existente asume Player - parcheamos con pre-check vía wrapper)

RunService.Heartbeat:Connect(function()
	local ahora = tick()
	local cfg = Config.BOTS_AMBULANTES
	for anclado, objetivo in pairs(ancladoA) do
		if typeof(objetivo) == "Instance" and objetivo:IsA("Model") and botsAmbulantes[objetivo] then
			if not (anclado.Parent and objetivo.Parent) then
				ctx.desanclar(anclado)
				continue
			end
			local nivelesVel = ctx.getStat(anclado, "VelocidadAnclaje")
			local intervalo = Config.getIntervaloAnclaje(nivelesVel)
			local last = ultimoTick[anclado] or 0
			if ahora - last < intervalo then continue end
			ultimoTick[anclado] = ahora
			local data = botsAmbulantes[objetivo]
			if not data or data.xp <= 0 then continue end
			local gain = cfg and cfg.XP_POR_TICK_JUGADOR or Config.XP_ANCLAJE_GANA
			local take = math.min(data.xp, Config.XP_ANCLAJE_PIERDE or gain)
			data.xp = data.xp - take
			ctx.agregarXP(anclado, gain)
		end
	end
end)

-- REMOVED: Redundant Heartbeat — Stick module handles CFrame positioning via
-- ctx.crearWeldAnclaje override, and ctx.aplicarEstadoAnclado handles WalkSpeed/Jump.
-- The first Heartbeat above already validates targets and calls desanclar.

-- Init bots from folder
task.spawn(function()
	task.wait(2)
	local cfg = Config.BOTS_AMBULANTES
	if not cfg then return end
	local folder = Workspace:FindFirstChild(cfg.CARPETA or "BotsAmbulantes")
	if not folder then
		print("[BotsAmb] Crea la carpeta Workspace." .. (cfg.CARPETA or "BotsAmbulantes") .. " y mete modelos con Humanoid")
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			setupBotAmbulante(child)
		end
	end
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.wait(0.5)
			setupBotAmbulante(child)
		end
	end)
	print("[BotsAmb] Inicializados:", #folder:GetChildren())
end)


print("[GestionAura] Sistema + Tienda Dopamínica + DataStore + Robux cargado.")


-- Actualiza HUD de protección cada segundo
task.spawn(function()
	while true do
		task.wait(1)
		for _, plr in ipairs(Players:GetPlayers()) do
			local hasta = antiAnclajeHasta[plr]
			if hasta and hasta > tick() then
				NotificarCliente:FireClient(plr, {
					tipo = "proteccion",
					segundos = hasta - tick(),
					activo = true,
				})
			elseif hasta then
				antiAnclajeHasta[plr] = nil
				NotificarCliente:FireClient(plr, { tipo = "proteccion", segundos = 0, activo = false })
			end
		end
	end
end)

end
 