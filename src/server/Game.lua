-- Game.lua: servidor unificado Triki Traka
-- Bootstrap: init.server.lua → Context → Game
-- Secciones anidadas (límite de locals Luau por función).
return function(ctx)
	local Config = ctx.Config
	if not ctx.log then
		function ctx.log(system, ...)
			local d = Config and Config.DEBUG
			if not d or not d.Enabled then return end
			if system and d[system] == false then return end
			print("[Triki:" .. tostring(system or "?") .. "]", ...)
		end
	end

	-- =====================================================
	-- PROGRESIÓN · ANCLAJE · DATOS · XP
	-- =====================================================
	local function section_0()
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

	function ctx.pushMetricTime(list, maxKeep)
		table.insert(list, tick())
		while #list > (maxKeep or 30) do
			table.remove(list, 1)
		end
	end

	function ctx.countSince(list, seconds)
		local t0 = tick() - seconds
		local n = 0
		for _, t in ipairs(list or {}) do
			if t >= t0 then n = n + 1 end
		end
		return n
	end



	-- =====================================================
	-- DATASTORE
	-- =====================================================
	local DataStore = DataStoreService:GetDataStore(Config.DATASTORE_NOMBRE)

	function ctx.valOr(ls, name, default)
		local v = ls:FindFirstChild(name)
		if v then return v.Value end
		return default
	end

	function ctx.guardarDatos(player)
		if not player then return false end
		local ls = player:FindFirstChild("leaderstats")
		if not ls then return false end

		local dd = dailyData[player] or dailyByUserId[player.UserId]
		local data = {
			Nivel = ctx.valOr(ls, "Nivel", 1),
			XP = ctx.valOr(ls, "XP", 0),
			MaxXP = ctx.valOr(ls, "MaxXP", 100),
			Monedas = ctx.valOr(ls, "Monedas", 0),
			Rebirths = ctx.valOr(ls, "Rebirths", 0),
			Victorias = ctx.valOr(ls, "Victorias", 0),
			NivelConseguido = ctx.valOr(ls, "NivelConseguido", 1),
			XPTotal = ctx.valOr(ls, "XPTotal", 0),
			ClicksPorClick = ctx.valOr(ls, "ClicksPorClick", 1),
			MultiXP = ctx.valOr(ls, "MultiXP", 1),
			MultiClicks = ctx.valOr(ls, "MultiClicks", 1),
			VelocidadAnclaje = ctx.valOr(ls, "VelocidadAnclaje", 0),
			VelocidadMovimiento = ctx.valOr(ls, "VelocidadMovimiento", 0),
			VelocidadAnclajeRobux = ctx.valOr(ls, "VelocidadAnclajeRobux", 0),
			VelocidadMovimientoRobux = ctx.valOr(ls, "VelocidadMovimientoRobux", 0),
			ClicksRobux = ctx.valOr(ls, "ClicksRobux", 0),
			DailyLastDay = (dd and dd.lastDay) or 0,
			DailyStreak = (dd and dd.streak) or 0,
			PromoTiers = promoTiers[player] or {},
			TutorialDone = (ctx.tutorialDone and ctx.tutorialDone[player]) == true,
		}

		-- Cache por UserId (misma sesión de servidor)
		dailyByUserId[player.UserId] = {
			lastDay = data.DailyLastDay,
			streak = data.DailyStreak,
		}

		local ok, err = pcall(function()
			DataStore:UpdateAsync("Player_" .. player.UserId, function(old)
				old = (typeof(old) == "table") and old or {}
				for k, v in pairs(data) do
					old[k] = v
				end
				return old
			end)
		end)
		if not ok then
			warn("[DataStore] Error al guardar " .. player.Name .. ": " .. tostring(err))
			-- Fallback SetAsync
			pcall(function()
				DataStore:SetAsync("Player_" .. player.UserId, data)
			end)
		end
		return ok
	end

	function ctx.cargarDatos(player)
		local ok, data = pcall(function()
			return DataStore:GetAsync("Player_" .. player.UserId)
		end)
		if ok and typeof(data) == "table" then
			return data
		end
		return nil
	end

	-- =====================================================
	-- REMOTES
	-- =====================================================
	function ctx.getOrCreateRemote(name)
		local r = ReplicatedStorage:FindFirstChild(name)
		if not r then
			r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = ReplicatedStorage
		end
		return r
	end

	local SolicitarDueloDirecto = ctx.getOrCreateRemote("SolicitarDueloDirecto")
	local ResponderDuelo       = ctx.getOrCreateRemote("ResponderDuelo")
	local IniciarMinijuego     = ctx.getOrCreateRemote("IniciarMinijuego")
	local EnviarClicks         = ctx.getOrCreateRemote("EnviarClicks")
	local MostrarResultados    = ctx.getOrCreateRemote("MostrarResultados")
	local DesanclarJugador     = ctx.getOrCreateRemote("DesanclarJugador")
	local ExpulsarAnclado      = ctx.getOrCreateRemote("ExpulsarAnclado")
	local NotificarCliente     = ctx.getOrCreateRemote("NotificarCliente")
	local ComprarMejora        = ctx.getOrCreateRemote("ComprarMejora")
	local HacerRebirth         = ctx.getOrCreateRemote("HacerRebirth")
	local ExpulsionUpdate      = ctx.getOrCreateRemote("ExpulsionUpdate")
	local ExpulsionAccion      = ctx.getOrCreateRemote("ExpulsionAccion")
	local ExpulsionDefensa     = ctx.getOrCreateRemote("ExpulsionDefensa")
	local ClaimDaily           = ctx.getOrCreateRemote("ClaimDaily")
	local SyncDaily            = ctx.getOrCreateRemote("SyncDaily")

	-- =====================================================
	-- HELPERS STATS
	-- =====================================================
	function ctx.getMaxXP(nivel)
		return Config.getMaxXP(nivel)
	end

	function ctx.crearLeaderstats(player, datosGuardados)
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player

		local function addInt(name, value)
			local v = Instance.new("IntValue")
			v.Name = name
			v.Value = value
			v.Parent = ls
			return v
		end

		local function addNum(name, value)
			local v = Instance.new("NumberValue")
			v.Name = name
			v.Value = value
			v.Parent = ls
			return v
		end

		if datosGuardados then
			addInt("Nivel", datosGuardados.Nivel or 1)
			addInt("XP", datosGuardados.XP or Config.XP_INICIAL)
			addInt("MaxXP", datosGuardados.MaxXP or ctx.getMaxXP(datosGuardados.Nivel or 1))
			addInt("Monedas", datosGuardados.Monedas or 0)
			addInt("Rebirths", datosGuardados.Rebirths or 0)
			addInt("Victorias", datosGuardados.Victorias or 0)
			local ncInit = math.max(datosGuardados.NivelConseguido or 0, datosGuardados.Nivel or 1)
			addInt("NivelConseguido", ncInit)
			addInt("XPTotal", math.floor(datosGuardados.XPTotal or 0))
			addInt("ClicksPorClick", datosGuardados.ClicksPorClick or 1)
			addNum("MultiXP", datosGuardados.MultiXP or 1)
			addNum("MultiClicks", datosGuardados.MultiClicks or 1)
			addInt("VelocidadAnclaje", datosGuardados.VelocidadAnclaje or 0)
			addInt("VelocidadMovimiento", datosGuardados.VelocidadMovimiento or 0)
			addInt("VelocidadAnclajeRobux", datosGuardados.VelocidadAnclajeRobux or 0)
			addInt("VelocidadMovimientoRobux", datosGuardados.VelocidadMovimientoRobux or 0)
			addInt("ClicksRobux", datosGuardados.ClicksRobux or 0)
		else
			addInt("Nivel", 1)
			addInt("XP", Config.XP_INICIAL)
			addInt("MaxXP", ctx.getMaxXP(1))
			addInt("Monedas", 0)
			addInt("Rebirths", 0)
			addInt("Victorias", 0)
			addInt("NivelConseguido", 1)
			addInt("XPTotal", 0)
			addInt("ClicksPorClick", 1)
			addNum("MultiXP", 1)
			addNum("MultiClicks", 1)
			addInt("VelocidadAnclaje", 0)
			addInt("VelocidadMovimiento", 0)
			addInt("VelocidadAnclajeRobux", 0)
			addInt("VelocidadMovimientoRobux", 0)
			addInt("ClicksRobux", 0)
		end
	end

	function ctx.getStat(player, name)
		local ls = player:FindFirstChild("leaderstats")
		if ls and ls:FindFirstChild(name) then
			return ls[name].Value
		end
		return 0
	end


	function ctx.getVelAnclajeTotal(player)
		return ctx.getStat(player, "VelocidadAnclaje") + ctx.getStat(player, "VelocidadAnclajeRobux")
	end
	function ctx.getVelMovimientoTotal(player)
		return ctx.getStat(player, "VelocidadMovimiento") + ctx.getStat(player, "VelocidadMovimientoRobux")
	end
	function ctx.getClicksTotal(player)
		return ctx.getStat(player, "ClicksPorClick") + ctx.getStat(player, "ClicksRobux")
	end

	function ctx.setStat(player, name, value)
		local ls = player:FindFirstChild("leaderstats")
		if not ls then return end
		local v = ls:FindFirstChild(name)
		if not v then return end
		local old = v.Value
		v.Value = value
		-- Nivel sube → acumular NivelConseguido (rebirth baja Nivel y no toca este contador)
		if name == "Nivel" and typeof(value) == "number" and typeof(old) == "number" and value > old then
			local nc = ls:FindFirstChild("NivelConseguido")
			if nc then
				nc.Value = (nc.Value or 0) + (value - old)
				if ctx.leaderboardOnStatChanged then
					ctx.leaderboardOnStatChanged(player, "NivelConseguido", nc.Value)
				end
			end
		end
		if ctx.leaderboardOnStatChanged then
			ctx.leaderboardOnStatChanged(player, name, value)
		end
		if ctx.leaderboardMarkDirty then
			ctx.leaderboardMarkDirty()
		end
	end

	function ctx.agregarMonedas(player, cantidad)
		ctx.setStat(player, "Monedas", math.max(0, ctx.getStat(player, "Monedas") + cantidad))
	end


	function ctx.estabilizarEconomia(player, subio)
		if not Config.ECONOMIA then return end
		local nivel = ctx.getStat(player, "Nivel")
		local monedas = ctx.getStat(player, "Monedas")
		local factor = subio and Config.ECONOMIA.FACTOR_AJUSTE_SUBIDA or Config.ECONOMIA.FACTOR_AJUSTE_BAJADA
		local nuevo, cambio = Config.ajustarMonedasANivel(monedas, nivel, factor)
		if cambio then
			ctx.setStat(player, "Monedas", nuevo)
			print("[Economía] Ajuste", player.Name, "Nv", nivel, monedas, "→", nuevo)
		end
	end

	function ctx.agregarXP(player, cantidad)
		local multi = ctx.getStat(player, "MultiXP")
		local real = math.floor(cantidad * multi)
		if real <= 0 then return end

		local xp    = ctx.getStat(player, "XP") + real
		local nivel = ctx.getStat(player, "Nivel")
		local maxXP = ctx.getStat(player, "MaxXP")
		local nivelAntes = nivel

		while xp >= maxXP do
			xp = xp - maxXP
			nivel = nivel + 1
			maxXP = ctx.getMaxXP(nivel)
		end

		ctx.setStat(player, "XP", xp)
		ctx.setStat(player, "Nivel", nivel)
		ctx.setStat(player, "MaxXP", maxXP)
		ctx.setStat(player, "XPTotal", ctx.getStat(player, "XPTotal") + real)

		if nivel > nivelAntes then
			local m = playerMetrics[player]
			if m then
				m.lastLevelUp = tick()
				m.lastLevel = nivel
			end
			ctx.estabilizarEconomia(player, true)
			-- Aviso de Rebirth disponible
			local minR = Config.getNivelMinimoRebirth(ctx.getStat(player, "Rebirths")) or 10
			if nivel >= minR and nivelAntes < minR then
				local rebirths = ctx.getStat(player, "Rebirths")
				local multiXp = ctx.getStat(player, "MultiXP")
				local multiCk = ctx.getStat(player, "MultiClicks")
				local nextReb = (ctx.getStat(player, "Rebirths") or 0) + 1
				local nextXp = multiXp * Config.getMultiXPAlRebirth(nextReb)
				local nextCk = multiCk * Config.getMultiClicksAlRebirth(nextReb)
				NotificarCliente:FireClient(player, {
					tipo = "rebirth_disponible",
					mensaje = string.format(
						"¡Puedes hacer REBIRTH!\n• Multi XP: x%.2f → x%.2f\n• Multi Clicks: x%.2f → x%.2f\n• Se reinicia nivel y mejoras de clicks\n• Los precios de tienda bajan un poco",
						multiXp, nextXp, multiCk, nextCk
					),
					rebirths = rebirths,
					nextMultiXP = nextXp,
					nextMultiClicks = nextCk,
				})
			end
		end
	end

	function ctx.quitarXP(player, cantidad)
		local xp    = ctx.getStat(player, "XP") - cantidad
		local nivel = ctx.getStat(player, "Nivel")
		local nivelAntes = nivel

		while xp < 0 and nivel > 1 do
			nivel = nivel - 1
			local maxAnterior = ctx.getMaxXP(nivel)
			xp = xp + maxAnterior
			if xp >= 0 then
				xp = math.max(0, maxAnterior - 1)
			end
		end

		if nivel <= 1 then
			nivel = 1
			xp = math.max(0, xp)
		end

		ctx.setStat(player, "Nivel", nivel)
		ctx.setStat(player, "MaxXP", ctx.getMaxXP(nivel))
		ctx.setStat(player, "XP", math.max(0, xp))

		if nivel < nivelAntes then
			ctx.estabilizarEconomia(player, false)
		end
	end


	function ctx.syncProteccionCliente(player)
		local hasta = antiAnclajeHasta[player]
		local resto = 0
		if hasta and hasta > tick() then
			resto = hasta - tick()
		end
		NotificarCliente:FireClient(player, {
			tipo = "proteccion",
			segundos = resto,
			activo = resto > 0,
		})
	end

	-- =====================================================
	-- SISTEMA DE ANCLAJE
	-- =====================================================

	function ctx.getWalkSpeedJugador(player)
		return Config.getWalkSpeed(ctx.getVelMovimientoTotal(player))
	end

	function ctx.stopAnimAnclaje(player)
		local track = animTracks[player]
		if track then
			pcall(function() track:Stop(0.15) end)
			animTracks[player] = nil
		end
	end

	function ctx.limpiarWeldAnclaje(player)
		local w = anclajeWelds[player]
		if w then
			pcall(function() w:Destroy() end)
			anclajeWelds[player] = nil
		end
		local a = anclajeAtts[player]
		if a then
			pcall(function() a:Destroy() end)
			anclajeAtts[player] = nil
		end
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				local att = hrp:FindFirstChild("AnclajeAttSelf")
				if att then pcall(function() att:Destroy() end) end
			end
		end
	end

	function ctx.aplicarEstadoLibre(player)
		ctx.stopAnimAnclaje(player)
		ctx.limpiarWeldAnclaje(player)
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		hum.Sit = false
		hum.WalkSpeed = ctx.getWalkSpeedJugador(player)
		hum.JumpPower = 50
		pcall(function() hum.JumpHeight = 7.2 end)
		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end)
	end

	function ctx.animLog(...)
		if Config.DEBUG_ANIM then
			print("[Anim]", ...)
		end
	end

	-- Espera a que el track tenga Length real (LoadAnimation es async)
	function ctx.waitTrackReady(track, timeout)
		-- Espera a que Length deje de ser exactamente 0 (aún no cargado).
		-- Animaciones reales pueden ser muy cortas (p.ej. 0.03s): eso es VÁLIDO.
		timeout = timeout or 3
		local t0 = tick()
		while track and track.Length == 0 and (tick() - t0) < timeout do
			task.wait(0.05)
		end
		return track ~= nil
	end

	function ctx.loadAndPlay(animator, animId, priority, looped)
		if not animator or typeof(animId) ~= "string" or #animId < 10 then
			return nil, "args"
		end
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		pcall(function()
			ContentProvider:PreloadAsync({ anim })
		end)
		local ok, track = pcall(function()
			return animator:LoadAnimation(anim)
		end)
		if not ok or not track then
			return nil, "load:" .. tostring(track)
		end
		track.Looped = looped ~= false
		track.Priority = priority or Enum.AnimationPriority.Action
		ctx.waitTrackReady(track, 3)
		-- NUNCA rechazar por Length corta: 0.03s es una anim legítima (pose/loop rápido)
		ctx.animLog("Load", animId, "Length=", track.Length, "(corta OK si >0)")
		if track.Length == 0 then
			ctx.animLog("WARN Length sigue 0: asset no cargó o sin permiso; Play de todos modos")
		end
		-- Fade corto si la anim es muy breve (si no, 0.2s se come casi todo el clip)
		local fade = (track.Length > 0 and track.Length < 0.2) and 0.02 or 0.15
		track:Play(fade, 1, 1)
		ctx.animLog("Play", animId, "IsPlaying=", track.IsPlaying, "fade=", fade, "Len=", track.Length)
		return track, nil
	end

	function ctx.playAnimAnclaje(player)
		-- Sit + Animate nativo
	end


	function ctx.crearWeldAnclaje(player, objetivo)
		ctx.limpiarWeldAnclaje(player)
		local charA = player.Character
		if not charA then return false end
		local hrpA = charA:FindFirstChild("HumanoidRootPart")
		if not hrpA then return false end
		local hrpO = nil
		if objetivo:IsA("Player") then
			local charO = objetivo.Character
			if charO then hrpO = charO:FindFirstChild("HumanoidRootPart") end
		elseif objetivo:IsA("Model") then
			hrpO = objetivo:FindFirstChild("HumanoidRootPart") or objetivo.PrimaryPart
		end
		if not hrpO then return false end
		local dist = Config.DISTANCIA_ANCLAJE or 3.2
		hrpA.CFrame = hrpO.CFrame * CFrame.new(0, 0, dist)
		local weld = Instance.new("WeldConstraint")
		weld.Name = "AnclajeWeld"
		weld.Part0 = hrpO
		weld.Part1 = hrpA
		weld.Parent = hrpA
		anclajeWelds[player] = weld
		return true
	end

	function ctx.aplicarEstadoAnclado(player)
		local char = player.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		hum.WalkSpeed = 0
		hum.JumpPower = 0
		pcall(function() hum.JumpHeight = 0 end)
		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end)
		hum.Sit = true
	end

	function ctx.desanclar(player)
		local objetivo = ancladoA[player]
		if not objetivo then return end

		ancladoA[player] = nil
		if ancladosEn[objetivo] then
			ancladosEn[objetivo][player] = nil
		end

		local char = player.Character
		if char then
			ctx.aplicarEstadoLibre(player)
		end

		NotificarCliente:FireClient(player, { tipo = "desanclado", mensaje = "Te has desanclado" })
		if objetivo and objetivo.Parent and objetivo:IsA("Player") then
			if typeof(objetivo) == "Instance" and objetivo:IsA("Player") then
				NotificarCliente:FireClient(objetivo, { tipo = "alguien_desanclado", mensaje = player.Name .. " se ha desanclado" })
			end
			-- Si el objetivo tenía sesión de expulsión contra este anclado, cerrarla
			local ses = expulsionSessions[objetivo]
			if ses and ses.anclado == player then
				expulsionSessions[objetivo] = nil
				ExpulsionUpdate:FireClient(objetivo, { activo = false })
				ExpulsionUpdate:FireClient(player, { activo = false })
			end
		end
		-- Si quien se desancla era el objetivo en una sesión
		if expulsionSessions[player] then
			local ses = expulsionSessions[player]
			local anc = ses.anclado
			expulsionSessions[player] = nil
			ExpulsionUpdate:FireClient(player, { activo = false })
			if anc and anc.Parent then
				ExpulsionUpdate:FireClient(anc, { activo = false })
			end
		end
	end

	function ctx.cooldownKeyFor(objetivo)
		if typeof(objetivo) == "Instance" and objetivo:IsA("Player") then
			return objetivo
		end
		if typeof(objetivo) == "Instance" and objetivo:IsA("Model") then
			local id = objetivo:GetAttribute("BotAmbId")
			if typeof(id) == "string" and id ~= "" then return id end
			local d = botsAmbulantes[objetivo]
			if d and d.id then return d.id end
		end
		return objetivo
	end


	function ctx.formatTiempoRestante(segundos)
		local s = math.max(0, math.ceil(tonumber(segundos) or 0))
		if s >= 3600 then
			local h = math.floor(s / 3600)
			local m = math.floor((s % 3600) / 60)
			if m > 0 then return h .. " h " .. m .. " min" end
			return h .. " h"
		elseif s >= 60 then
			local m = math.floor(s / 60)
			local r = s % 60
			if r > 0 then return m .. " min " .. r .. " s" end
			return m .. " min"
		end
		return s .. " s"
	end

	function ctx.anclar(player, objetivo)
		if player == objetivo then return end
		if ctx.log then ctx.log("Anclaje", "request", player.Name, typeof(objetivo)=="Instance" and objetivo.Name or "?") end
		if ancladoA[player] then return end
		if not objetivo or not objetivo.Parent then return end
		-- tutorial protect: nadie se ancla al jugador en tutorial
		if typeof(objetivo) == "Instance" and objetivo:IsA("Player") and ctx.tutorialActive and ctx.tutorialActive[objetivo] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Ese jugador está en el tutorial" })
			return
		end

		if ancladoA[objetivo] == player then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "No puedes anclarte a alguien que ya está anclado a ti" })
			return
		end

		-- Solo 1 jugador anclado por objetivo
		if ancladosEn[objetivo] then
			for otro in pairs(ancladosEn[objetivo]) do
				if otro and otro.Parent then
					NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Este jugador ya tiene a alguien anclado" })
					return
				end
			end
		end

		if antiAnclajeHasta[objetivo] and tick() < antiAnclajeHasta[objetivo] then
			local resto = antiAnclajeHasta[objetivo] - tick()
			local t = ctx.formatTiempoRestante(resto)
			local quien = (typeof(objetivo) == "Instance" and objetivo:IsA("Player")) and "Este jugador" or "Este bot"
			NotificarCliente:FireClient(player, {
				tipo = "error",
				mensaje = quien .. " tiene protección · quedan " .. t,
			})
			return
		end

		do
			local ck = ctx.cooldownKeyFor(objetivo)
			if cooldownReanclar[ck] and cooldownReanclar[ck][player] and tick() < cooldownReanclar[ck][player] then
				local resto = cooldownReanclar[ck][player] - tick()
				local t = ctx.formatTiempoRestante(resto)
				NotificarCliente:FireClient(player, {
					tipo = "error",
					mensaje = "Te expulsaron · no puedes anclarte aquí · quedan " .. t,
				})
				return
			end
		end

		ctx.desanclar(player)

		ancladoA[player] = objetivo
		do
			local m = playerMetrics[player]
			if m then
				m.anchors = (m.anchors or 0) + 1
				m.anchorsRecent = (m.anchorsRecent or 0) + 1
				m.lastProgress = tick()
				m.anchorTimes = m.anchorTimes or {}
				ctx.pushMetricTime(m.anchorTimes, 40)
			end
		end
		ancladosEn[objetivo] = ancladosEn[objetivo] or {}
		ancladosEn[objetivo][player] = true

		local char = player.Character
		if char then
			ctx.crearWeldAnclaje(player, objetivo)
			ctx.aplicarEstadoAnclado(player)
		end

		NotificarCliente:FireClient(player, {
			tipo = "anclado",
			objetivo = objetivo.Name,
			mensaje = "Anclado a " .. objetivo.Name
		})

		if typeof(objetivo) == "Instance" and objetivo:IsA("Player") then
			NotificarCliente:FireClient(objetivo, {
				tipo = "te_anclaron",
				quien = player.Name,
				userId = player.UserId,
				mensaje = player.Name .. " se ha anclado a ti"
			})
		end

		-- Sesión de expulsión (solo el objetivo ve la UI hasta que intente)
		-- Expulsión UI solo si el objetivo es un jugador real
		if typeof(objetivo) == "Instance" and objetivo:IsA("Player") then
			expulsionSessions[objetivo] = {
				anclado = player,
				dinero = Config.EXPULSION.DINERO_MINIMO,
				defensaClicks = 0,
				fase = "preparacion",
			}
			local info = Config.calcExpulsion(Config.EXPULSION.DINERO_MINIMO, 0, ctx.getStat(player, "Nivel"))
			ExpulsionUpdate:FireClient(objetivo, {
				activo = true,
				rol = "objetivo",
				fase = "preparacion",
				quien = player.Name,
				userId = player.UserId,
				dinero = info.dinero,
				dineroParaFull = info.dineroParaFull,
				prob = info.probabilidad,
				probInicial = info.probInicial,
				probMax = info.probMax,
				reduccion = 0,
				reduccionMax = info.reduccionMax,
			})
		end
	end

	RunService.Heartbeat:Connect(function()
		for anclado, objetivo in pairs(ancladoA) do
			if not anclado.Parent or not objetivo.Parent then
				ctx.desanclar(anclado)
				continue
			end

			if typeof(objetivo) == "Instance" and objetivo:IsA("Model") and botsAmbulantes[objetivo] then
				continue -- bot stick en otro loop
			end
			local charA = anclado.Character
			local charO = objetivo:IsA("Player") and objetivo.Character or nil
			if not (charA and charO) then continue end

			local humA = charA:FindFirstChildOfClass("Humanoid")
			if humA then
				humA.WalkSpeed = 0
				humA.JumpPower = 0
				pcall(function() humA.JumpHeight = 0 end)
			end
			-- Si el weld se rompió (respawn, etc.), recrear
			-- Stick usa CFrame positioning en su propio Heartbeat, no welds
			if not ctx.UNIFIED_STICK then
				local weld = anclajeWelds[anclado]
				if not weld or not weld.Parent then
					ctx.crearWeldAnclaje(anclado, objetivo)
				end
			end
		end
	end)

	-- Tick de XP con intervalo personalizado por jugador
	-- ultimoTick on ctx

	RunService.Heartbeat:Connect(function()
		local ahora = tick()
		for anclado, objetivo in pairs(ancladoA) do
			if not (anclado.Parent and objetivo.Parent) then continue end

			local nivelesVel = ctx.getStat(anclado, "VelocidadAnclaje")
			local intervalo = Config.getIntervaloAnclaje(nivelesVel)

			local last = ultimoTick[anclado] or 0
			if ahora - last < intervalo then continue end
			ultimoTick[anclado] = ahora

			if proteccionFalloHasta[anclado] and tick() < proteccionFalloHasta[anclado] then
				continue
			end

			-- Solo jugadores reales aquí; bots tienen su propio loop
			if typeof(objetivo) ~= "Instance" or not objetivo:IsA("Player") then
				continue
			end
			local nivelObj = ctx.getStat(objetivo, "Nivel")
			local xpObj    = ctx.getStat(objetivo, "XP")
			if nivelObj <= 1 and xpObj <= 0 then continue end

			ctx.agregarXP(anclado, Config.XP_ANCLAJE_GANA)
			ctx.quitarXP(objetivo, Config.XP_ANCLAJE_PIERDE)
		end
	end)

	-- =====================================================
	-- PROXIMITY PROMPTS
	-- =====================================================
	end
	section_0()

	-- =====================================================
	-- ANCLAJE PEGADO (Heartbeat)
	-- =====================================================
	local function section_1()
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
	section_1()

	-- =====================================================
	-- SESIÓN · REMOTES · REBIRTH · TUTORIAL
	-- =====================================================
	local function section_2()
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

		-- Tutorial first-time
		do
			local done = false
			if datos and datos.TutorialDone == true then
				done = true
			elseif datos and datos.TutorialDone == false then
				done = false
			elseif datos then
				local n = datos.Nivel or 1
				local r = datos.Rebirths or 0
				local m = datos.Monedas or 0
				local v = datos.Victorias or 0
				if n > 1 or r > 0 or m > 50 or v > 0 then
					done = true
				end
			end
			ctx.tutorialDone[player] = done
			task.defer(function()
				task.wait(1.5)
				if not player.Parent then return end
				if ctx.TutorialSync then
					ctx.TutorialSync:FireClient(player, { show = not done })
				end
			end)
		end


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
		ctx.tutorialActive[player] = nil
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
		if ctx.rateLimit and not ctx.rateLimit(player, "desanclar", 0.4) then return end
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
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Mínimo " .. Config.EXPULSION.DINERO_MINIMO .. " monedas" })
				return
			end
			if ctx.getStat(player, "Monedas") < dinero then
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. dinero .. " monedas" })
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
					NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "¡EXPULSIÓN EXITOSA! (-" .. ses.dineroGastado .. " monedas)" })
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
		if ctx.rateLimit and not ctx.rateLimit(player, "compra", 0.35) then return end
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
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " monedas" })
				return
			end
			ctx.agregarMonedas(player, -coste)
			local ahora = tick()
			local actual = antiAnclajeHasta[player] or 0
			if actual > ahora then
				antiAnclajeHasta[player] = actual + anti.segundos
				ctx.syncProteccionCliente(player)
			else
				antiAnclajeHasta[player] = ahora + anti.segundos
				ctx.syncProteccionCliente(player)
			end
			local mins = math.floor(anti.segundos / 60)
			NotificarCliente:FireClient(player, {
				tipo = "exito",
				mensaje = "¡" .. anti.nombre .. "! +" .. mins .. " min (-" .. coste .. " monedas)"
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
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " monedas" })
				return
			end
			ctx.agregarMonedas(player, -coste)
			ctx.setStat(player, "ClicksPorClick", actualClicks + pack.cantidad)
			NotificarCliente:FireClient(player, {
				tipo = "exito",
				mensaje = "¡" .. pack.nombre .. "! Ahora " .. (actualClicks + pack.cantidad) .. " (-" .. coste .. " monedas)"
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
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " monedas" })
				return
			end
			ctx.agregarMonedas(player, -coste)
			local nuevo = actualVel + vel.niveles
			ctx.setStat(player, "VelocidadAnclaje", nuevo)
			local intervalo = Config.getIntervaloAnclaje(nuevo)
			NotificarCliente:FireClient(player, {
				tipo = "exito",
				mensaje = "¡" .. vel.nombre .. "! Intervalo " .. string.format("%.2f", intervalo) .. "s (-" .. coste .. " monedas)"
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
				NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas " .. coste .. " monedas" })
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
				mensaje = "¡" .. walk.nombre .. "! WalkSpeed " .. string.format("%.1f", Config.getWalkSpeed(nuevo)) .. " (-" .. coste .. " monedas)"
			})
			return
		end
	end)

	HacerRebirth.OnServerEvent:Connect(function(player)
		if ctx.rateLimit and not ctx.rateLimit(player, "rebirth", 1.0) then return end
		local nivel = ctx.getStat(player, "Nivel")
		local minNivel = Config.getNivelMinimoRebirth(ctx.getStat(player, "Rebirths"))
		if nivel < minNivel then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Necesitas nivel " .. minNivel })
			return
		end

		ctx.setStat(player, "Nivel", 1)
		ctx.setStat(player, "XP", Config.XP_INICIAL)
		ctx.setStat(player, "MaxXP", ctx.getMaxXP(1))
		-- Solo se reinician mejoras compradas con monedas (no Robux)
		ctx.setStat(player, "ClicksPorClick", 1)
		ctx.setStat(player, "VelocidadAnclaje", 0)
		ctx.setStat(player, "VelocidadMovimiento", 0)
		-- ClicksRobux / VelocidadAnclajeRobux / VelocidadMovimientoRobux se conservan
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


	function ctx.iniciarDueloBot(player, modelo)
		if not player or not modelo then return false end
		if duelosActivos[player] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "Ya estás en un duelo" })
			return false
		end
		if ancladoA[player] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "No puedes retar mientras estás anclado" })
			return false
		end
		local nivelBot = ctx.extraerNivelBot(modelo.Name)
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
		return true
	end


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
			ctx.iniciarDueloBot(player, modelo)
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

	-- Tutorial complete / skip / started
	if ctx.TutorialAction then
		ctx.TutorialAction.OnServerEvent:Connect(function(player, action)
			if typeof(action) ~= "string" then return end
			if action == "complete" or action == "skip" then
				ctx.tutorialDone[player] = true
				ctx.tutorialActive[player] = nil
				local ahora = tick()
				local longProtect = antiAnclajeHasta[player] and antiAnclajeHasta[player] > ahora + 1000
				local claimedDaily = ctx.tutorialDailyClaimed and ctx.tutorialDailyClaimed[player]
				if ctx.tutorialDailyClaimed then
					ctx.tutorialDailyClaimed[player] = nil
				end
				if action == "complete" and claimedDaily then
					local secs = (Config.TUTORIAL and Config.TUTORIAL.POST_PROTECTION_S) or 60
					antiAnclajeHasta[player] = ahora + secs
				elseif longProtect then
					antiAnclajeHasta[player] = nil
				end
				if ctx.syncProteccionCliente then
					pcall(function() ctx.syncProteccionCliente(player) end)
				end
				ctx.guardarDatos(player)
				if ctx.TutorialSync then
					ctx.TutorialSync:FireClient(player, { show = false, ended = true })
				end
				return
			end
			if action == "started" then
				ctx.tutorialActive[player] = true
				antiAnclajeHasta[player] = tick() + 86400
				if ctx.syncProteccionCliente then
					pcall(function() ctx.syncProteccionCliente(player) end)
				end
				return
			end
			if action == "step" then
				return
			end
		end)
	end


	-- Stats extra (ranks) + reinicio de progreso
	do
		local PedirStatsExtra = ctx.PedirStatsExtra
		local StatsExtra = ctx.StatsExtra
		local ReiniciarProgreso = ctx.ReiniciarProgreso
		local NotificarCliente = ctx.NotificarCliente
		local antiAnclajeHasta = ctx.antiAnclajeHasta

		if PedirStatsExtra and StatsExtra then
			PedirStatsExtra.OnServerEvent:Connect(function(player)
		if ctx.rateLimit and not ctx.rateLimit(player, "stats_extra", 1.5) then return end
				if not player or not player.Parent then return end
				local protLeft = 0
				if antiAnclajeHasta[player] then
					protLeft = math.max(0, antiAnclajeHasta[player] - tick())
				end
				StatsExtra:FireClient(player, {
					proteccionRestante = protLeft,
				})
			end)
		end

		if ReiniciarProgreso then
			ReiniciarProgreso.OnServerEvent:Connect(function(player)
		if ctx.rateLimit and not ctx.rateLimit(player, "reset", 3.0) then return end
				if not player or not player.Parent then return end
				-- Desanclar si aplica
				if ctx.desanclar then
					pcall(function() ctx.desanclar(player) end)
				end
				ctx.setStat(player, "Nivel", 1)
				ctx.setStat(player, "XP", Config.XP_INICIAL or 50)
				ctx.setStat(player, "MaxXP", ctx.getMaxXP(1))
				ctx.setStat(player, "Monedas", 0)
				ctx.setStat(player, "Rebirths", 0)
				ctx.setStat(player, "Victorias", 0)
				ctx.setStat(player, "NivelConseguido", 1)
				ctx.setStat(player, "XPTotal", 0)
				ctx.setStat(player, "ClicksPorClick", 1)
				ctx.setStat(player, "ClicksRobux", 0)
				ctx.setStat(player, "VelocidadAnclaje", 0)
				ctx.setStat(player, "VelocidadAnclajeRobux", 0)
				ctx.setStat(player, "VelocidadMovimiento", 0)
				ctx.setStat(player, "VelocidadMovimientoRobux", 0)
				ctx.setStat(player, "MultiXP", 1)
				ctx.setStat(player, "MultiClicks", 1)
				antiAnclajeHasta[player] = nil
				if ctx.syncProteccionCliente then
					ctx.syncProteccionCliente(player)
				end
				if ctx.aplicarEstadoLibre then
					ctx.aplicarEstadoLibre(player)
				end
				if ctx.guardarDatos then
					pcall(function() ctx.guardarDatos(player) end)
				end
				NotificarCliente:FireClient(player, { tipo = "exito", mensaje = "Progreso reiniciado" })
				if StatsExtra then
					StatsExtra:FireClient(player, { ranks = {}, proteccionRestante = 0, reset = true })
				end
			end)
		end
	end
	end
	section_2()

	-- =====================================================
	-- DUELOS · DAILY · ROBUX · PROMOS
	-- =====================================================
	local function section_3()
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
		if duelosActivos[player] or duelosActivos[target] then return end
		if duelosPendientes[target] then return end

		-- No permitir duelos si alguno está anclado
		if ancladoA[player] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = "No puedes dueler mientras estás anclado" })
			return
		end
		if ancladoA[target] then
			NotificarCliente:FireClient(player, { tipo = "error", mensaje = target.Name .. " está anclado y no puede dueler" })
			return
		end

		duelosPendientes[target] = { retador = player, tiempo = tick() }
		ResponderDuelo:FireClient(target, player.UserId, player.Name)
	end)

	ResponderDuelo.OnServerEvent:Connect(function(player, acepto, retadorUserId)
		local data = duelosPendientes[player]
		if not data then return end
		local retador = data.retador
		duelosPendientes[player] = nil
		if not acepto or not retador or not retador.Parent then
			if retador and retador.Parent then
				NotificarCliente:FireClient(retador, { tipo = "info", mensaje = player.Name .. " rechazó el duelo" })
			end
			return
		end
		if retador.UserId ~= retadorUserId then return end
		if duelosActivos[player] or duelosActivos[retador] then return end

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
				if now - data.tiempo > 8 then
					duelosPendientes[p] = nil
					local retador = data.retador
					if retador and retador.Parent then
						NotificarCliente:FireClient(retador, { tipo = "info", mensaje = "El duelo con " .. p.Name .. " expiró sin respuesta" })
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

				-- Actualizar stat Victorias en leaderstats (para leaderboards)
				ctx.setStat(ganador, "Victorias", ctx.getStat(ganador, "Victorias") + 1)
				if ctx.leaderboardOnStatChanged then
					ctx.leaderboardOnStatChanged(ganador, "Victorias", ctx.getStat(ganador, "Victorias"))
				end
				do
					local function markWin(p)
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
	section_3()

	-- =====================================================
	-- BOTS · RECOMENDACIONES
	-- =====================================================
	local function section_4()
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
	section_4()

	-- =====================================================
	-- SIT STUB
	-- =====================================================
	local function section_5()
		print("[SitNoop] omitido")
	end
	section_5()

	-- =====================================================
	-- BOT ANIM STUB
	-- =====================================================
	local function section_6()
		print("[BotAnim] desactivado (LOD cliente)")
	end
	section_6()

	-- =====================================================
	-- DIAGNÓSTICO
	-- =====================================================
	local function section_7()
		local botsAmbulantes = ctx.botsAmbulantes
		task.delay(5, function()
			for model, data in pairs(botsAmbulantes) do
				local n = 0
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("Motor6D") then
						n += 1
					end
				end
				print("[Diag]", model.Name, "Motor6D=", n)
			end
		end)
	end
	section_7()

	-- =====================================================
	-- SEGURIDAD · CLEANUP · CLAMP · RATE LIMIT
	-- =====================================================
	local function section_8()
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
				if name == "Monedas" or name == "XP" or name == "XPTotal"
					or name == "Rebirths" or name == "Victorias"
					or name == "ClicksPorClick" or name == "ClicksRobux"
					or name == "VelocidadAnclaje" or name == "VelocidadAnclajeRobux"
					or name == "VelocidadMovimiento" or name == "VelocidadMovimientoRobux"
					or name == "NivelConseguido" then
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
	section_8()

	-- =====================================================
	-- LEADERBOARDS GLOBALES
	-- =====================================================
	local function section_9()
		local Players = ctx.Players
		local Workspace = ctx.Workspace
		local DataStoreService = ctx.DataStoreService
		local Config = ctx.Config

		local cfg = Config.LEADERBOARDS
		if not cfg or not cfg.Enabled then
			print("[Leaderboards] Desactivado")
			return
		end

		local maxEntries = math.clamp(tonumber(cfg.MaxEntries) or 10, 1, 25)
		local refreshInterval = math.max(8, tonumber(cfg.RefreshInterval) or 20)
		local writeDebounce = math.max(2, tonumber(cfg.WriteDebounce) or 5)
		local boardsCfg = cfg.Boards or {}

		local FACE_MAP = {
			Front = Enum.NormalId.Front,
			Back = Enum.NormalId.Back,
			Left = Enum.NormalId.Left,
			Right = Enum.NormalId.Right,
			Top = Enum.NormalId.Top,
			Bottom = Enum.NormalId.Bottom,
		}
		local defaultFace = FACE_MAP[cfg.Face or "Back"] or Enum.NormalId.Back

		local TRACKED = {
			XPTotal = true,
			Monedas = true,
			Rebirths = true,
			Victorias = true,
		}
		local IMMEDIATE = {
			XPTotal = true,
			Rebirths = true,
			Victorias = true,
		}
		
		-- esto deberia estar en config /
		local TEMA = {
			fondo = Color3.fromRGB(18, 20, 28),
			oro = Color3.fromRGB(255, 200, 60),
			texto = Color3.fromRGB(240, 240, 255),
			muted = Color3.fromRGB(160, 165, 185),
			rank1 = Color3.fromRGB(255, 210, 70),
			rank2 = Color3.fromRGB(200, 210, 230),
			rank3 = Color3.fromRGB(220, 160, 90),
		}

		local orderedStores = {}
		local boards = {}
		local pending = {} -- userId -> { stat -> value }
		local lastWrite = {} -- "userId_stat" -> tick
		local nameCache = {}
		local cachedRanks = {}
		local lastRefresh = 0

		local namesStore
		do
			local ok, s = pcall(function()
				return DataStoreService:GetDataStore("AuraLB_Names_v1")
			end)
			if ok then
				namesStore = s
			end
		end

		for _, def in ipairs(boardsCfg) do
			local storeName = def.orderedStore
			if typeof(storeName) == "string" and storeName ~= "" then
				local ok, store = pcall(function()
					return DataStoreService:GetOrderedDataStore(storeName)
				end)
				if ok and store then
					orderedStores[def.stat] = store
					print("[Leaderboards] ODS OK:", storeName, "stat=", def.stat)
				else
					warn("[Leaderboards] ODS error:", storeName, store)
				end
			end
		end
		do
			local keys = {}
			for k in pairs(orderedStores) do table.insert(keys, k) end
			print("[Leaderboards] Stats con ODS:", table.concat(keys, ", "))
		end


		local function formatNum(n)
			n = math.floor(tonumber(n) or 0)
			local a = math.abs(n)
			if a >= 1e12 then
				return string.format("%.1fT", n / 1e12)
			elseif a >= 1e9 then
				return string.format("%.1fB", n / 1e9)
			elseif a >= 1e6 then
				return string.format("%.1fM", n / 1e6)
			elseif a >= 1e3 then
				return string.format("%.1fK", n / 1e3)
			end
			return tostring(n)
		end

		local function findPart(name, altNames)
			local function try(n)
				if typeof(n) ~= "string" or n == "" then return nil end
				local p = Workspace:FindFirstChild(n, true)
				if p and p:IsA("BasePart") then return p end
				return nil
			end
			local p = try(name)
			if p then return p end
			if typeof(altNames) == "table" then
				for _, n in ipairs(altNames) do
					p = try(n)
					if p then return p end
				end
			end
			return nil
		end

		local function resolveFace(def)
			if def and def.face and FACE_MAP[def.face] then
				return FACE_MAP[def.face]
			end
			return defaultFace
		end

		local function rememberName(userId, name)
			if not userId or not name then
				return
			end
			nameCache[userId] = name
			if namesStore then
				task.spawn(function()
					pcall(function()
						namesStore:SetAsync(tostring(userId), name)
					end)
				end)
			end
		end

		local function resolveName(userId)
			if nameCache[userId] then
				return nameCache[userId]
			end
			local pl = Players:GetPlayerByUserId(userId)
			if pl then
				local n = pl.DisplayName or pl.Name
				nameCache[userId] = n
				return n
			end
			if namesStore then
				local ok, n = pcall(function()
					return namesStore:GetAsync(tostring(userId))
				end)
				if ok and typeof(n) == "string" and n ~= "" then
					nameCache[userId] = n
					return n
				end
			end
			local ok2, n2 = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if ok2 and n2 then
				nameCache[userId] = n2
				return n2
			end
			return "User " .. tostring(userId)
		end

		local function writeStat(userId, stat, value, force)
			local store = orderedStores[stat]
			if not store then
				return false
			end
			value = math.max(0, math.floor(tonumber(value) or 0))
			local key = tostring(userId)
			local stamp = key .. "_" .. stat
			local now = tick()
			if not force and not IMMEDIATE[stat] then
				if lastWrite[stamp] and (now - lastWrite[stamp]) < writeDebounce then
					pending[userId] = pending[userId] or {}
					pending[userId][stat] = value
					return false
				end
			end
			local ok, err = pcall(function()
				local prev = store:GetAsync(key)
				prev = tonumber(prev) or 0
				-- Solo subir (o forzar en victorias/rebirths/nivel)
				if force or value >= prev then
					store:SetAsync(key, value)
				end
			end)
			if ok then
				lastWrite[stamp] = now
				if pending[userId] then
					pending[userId][stat] = nil
					if next(pending[userId]) == nil then
						pending[userId] = nil
					end
				end
				return true
			end
			warn("[Leaderboards] write fail", stat, userId, err)
			pending[userId] = pending[userId] or {}
			pending[userId][stat] = value
			return false
		end

		local function queueFromPlayer(player, force)
			if not player or not player.Parent then
				return
			end
			local ls = player:FindFirstChild("leaderstats")
			if not ls then
				return
			end
			rememberName(player.UserId, player.DisplayName or player.Name)
			for stat in pairs(TRACKED) do
				local v = ls:FindFirstChild(stat)
				if v then
					writeStat(player.UserId, stat, v.Value, force or IMMEDIATE[stat])
				end
			end
		end

		function ctx.leaderboardOnStatChanged(player, name, value)
			if not player or not TRACKED[name] then
				return
			end
			rememberName(player.UserId, player.DisplayName or player.Name)
			writeStat(player.UserId, name, value, IMMEDIATE[name] == true)
		end

		function ctx.leaderboardMarkDirty()
			-- solo fuerza refresco visual en el próximo ciclo
			lastRefresh = 0
		end

		local function flushPending(force)
			for userId, bag in pairs(pending) do
				for stat, value in pairs(bag) do
					writeStat(userId, stat, value, force)
				end
			end
		end

		-- SOLO OrderedDataStore global (nunca Players:GetPlayers para el ranking)
		local function fetchTop(stat)
			local store = orderedStores[stat]
			if not store then
				return {}
			end
			local ok, pagesOrErr = pcall(function()
				return store:GetSortedAsync(false, maxEntries)
			end)
			if not ok or not pagesOrErr then
				warn("[Leaderboards] GetSortedAsync falló:", stat, pagesOrErr)
				return cachedRanks[stat] or {}
			end
			local pages = pagesOrErr
			local ok2, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if not ok2 or typeof(page) ~= "table" then
				warn("[Leaderboards] GetCurrentPage falló:", stat, page)
				return cachedRanks[stat] or {}
			end
			local items = {}
			for _, entry in ipairs(page) do
				local uid = tonumber(entry.key)
				local val = tonumber(entry.value) or 0
				if uid then
					table.insert(items, {
						userId = uid,
						name = resolveName(uid),
						value = val,
					})
				end
			end
			cachedRanks[stat] = items
			return items
		end

		local function ensureBoard(def)
			local id = def.id or def.partName
			local existing = boards[id]
			local part = findPart(def.partName, def.altPartNames)
			if not part then
				boards[id] = nil
				return nil
			end
			local face = resolveFace(def)
			if existing and existing.part == part and existing.surface and existing.surface.Parent then
				if existing.surface.Face ~= face then
					existing.surface.Face = face
				end
				return existing
			end
			for _, c in ipairs(part:GetChildren()) do
				if c:IsA("SurfaceGui") and c:GetAttribute("TrikiLeaderboard") then
					c:Destroy()
				end
			end

			local sg = Instance.new("SurfaceGui")
			sg.Name = "TrikiLeaderboard"
			sg:SetAttribute("TrikiLeaderboard", true)
			sg.Face = face
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 50
			sg.CanvasSize = Vector2.new(400, 520)
			sg.Adornee = part
			sg.Parent = part

			local root = Instance.new("Frame")
			root.Size = UDim2.fromScale(1, 1)
			root.BackgroundColor3 = TEMA.fondo
			root.BorderSizePixel = 0
			root.Parent = sg
			Instance.new("UICorner", root).CornerRadius = UDim.new(0, 12)
			local stroke = Instance.new("UIStroke")
			stroke.Color = TEMA.oro
			stroke.Thickness = 3
			stroke.Parent = root

			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, -20, 0, 44)
			title.Position = UDim2.new(0, 10, 0, 8)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.GothamBlack
			title.TextSize = 24
			title.TextColor3 = TEMA.oro
			title.TextXAlignment = Enum.TextXAlignment.Center
			title.Text = def.titulo or def.id or "TOP"
			title.Parent = root

			local list = Instance.new("Frame")
			list.Size = UDim2.new(1, -20, 1, -64)
			list.Position = UDim2.new(0, 10, 0, 56)
			list.BackgroundTransparency = 1
			list.Parent = root
			local lay = Instance.new("UIListLayout")
			lay.SortOrder = Enum.SortOrder.LayoutOrder
			lay.Padding = UDim.new(0, 4)
			lay.Parent = list

			local rows = {}
			for i = 1, maxEntries do
				local row = Instance.new("Frame")
				row.Size = UDim2.new(1, 0, 0, 36)
				row.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
				row.LayoutOrder = i
				row.Parent = list
				Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

				local rank = Instance.new("TextLabel")
				rank.Size = UDim2.new(0, 36, 1, 0)
				rank.BackgroundTransparency = 1
				rank.Font = Enum.Font.GothamBlack
				rank.TextSize = 18
				rank.TextColor3 = TEMA.oro
				rank.Text = tostring(i)
				rank.Parent = row

				local nameLbl = Instance.new("TextLabel")
				nameLbl.Size = UDim2.new(1, -130, 1, 0)
				nameLbl.Position = UDim2.new(0, 40, 0, 0)
				nameLbl.BackgroundTransparency = 1
				nameLbl.Font = Enum.Font.GothamBold
				nameLbl.TextSize = 16
				nameLbl.TextColor3 = TEMA.texto
				nameLbl.TextXAlignment = Enum.TextXAlignment.Left
				nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
				nameLbl.Text = "—"
				nameLbl.Parent = row

				local valLbl = Instance.new("TextLabel")
				valLbl.Size = UDim2.new(0, 80, 1, 0)
				valLbl.Position = UDim2.new(1, -86, 0, 0)
				valLbl.BackgroundTransparency = 1
				valLbl.Font = Enum.Font.GothamBlack
				valLbl.TextSize = 16
				valLbl.TextColor3 = TEMA.oro
				valLbl.TextXAlignment = Enum.TextXAlignment.Right
				valLbl.Text = "-"
				valLbl.Parent = row

				rows[i] = { rank = rank, name = nameLbl, value = valLbl }
			end

			local board = { def = def, part = part, surface = sg, rows = rows }
			boards[id] = board
			return board
		end

		local function paint(board, ranked)
			if not board or not board.surface or not board.surface.Parent then
				return
			end
			for i = 1, maxEntries do
				local row = board.rows[i]
				local e = ranked[i]
				if e then
					row.name.Text = e.name
					row.value.Text = formatNum(e.value)
					row.rank.TextColor3 = (i == 1 and TEMA.rank1) or (i == 2 and TEMA.rank2) or (i == 3 and TEMA.rank3) or TEMA.oro
				else
					row.name.Text = "—"
					row.value.Text = "-"
					row.rank.TextColor3 = TEMA.muted
				end
				row.rank.Text = tostring(i)
			end
		end

		local function refreshAll()
			for _, def in ipairs(boardsCfg) do
				local board = ensureBoard(def)
				local ranked = fetchTop(def.stat)
				if board then
					paint(board, ranked)
				end
			end
			lastRefresh = tick()
		end

		Players.PlayerAdded:Connect(function(player)
			task.delay(1.5, function()
				if player.Parent then
					queueFromPlayer(player, true)
				end
			end)
		end)

		Players.PlayerRemoving:Connect(function(player)
			queueFromPlayer(player, true)
		end)

		game:BindToClose(function()
			for _, pl in ipairs(Players:GetPlayers()) do
				queueFromPlayer(pl, true)
			end
			flushPending(true)
		end)

		Workspace.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				for _, def in ipairs(boardsCfg) do
					if d.Name == def.partName then
						task.defer(refreshAll)
						break
					end
				end
			end
		end)

		task.spawn(function()
			task.wait(2)
			for _, pl in ipairs(Players:GetPlayers()) do
				queueFromPlayer(pl, true)
			end
			refreshAll()
			while true do
				task.wait(5)
				flushPending(false)
				if (tick() - lastRefresh) >= refreshInterval then
					pcall(refreshAll)
				end
			end
		end)

		print("[Leaderboards] Global ODS — face=", cfg.Face or "Back", "boards=", #boardsCfg)

		


	end
	section_9()

end

-- tengo poca idea de backend asique no he opinado acerca de nada /