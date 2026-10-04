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
