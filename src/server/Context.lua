-- Context.lua: estado y servicios compartidos
local Context = {}

Context.Players = game:GetService("Players")
Context.ReplicatedStorage = game:GetService("ReplicatedStorage")
Context.RunService = game:GetService("RunService")
Context.ContentProvider = game:GetService("ContentProvider")
Context.Workspace = game:GetService("Workspace")
Context.DataStoreService = game:GetService("DataStoreService")
Context.MarketplaceService = game:GetService("MarketplaceService")

Context.Config = require(Context.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

Context.duelosPendientes = {}
Context.duelosActivos = {}
Context.ancladoA = {}
Context.ancladosEn = {}
Context.cooldownReanclar = {}
Context.antiAnclajeHasta = {}
Context.walkSpeedOriginal = {}
Context.expulsionSessions = {}
Context.proteccionFalloHasta = {}
Context.animTracks = {}
Context.anclajeWelds = {}
Context.anclajeAtts = {}
Context.dailyData = {}
Context.dailyByUserId = {}
Context.promoTiers = {}
Context.playerMetrics = {}
Context.botsAmbulantes = {}
Context.ultimaRecomendacion = {}
Context.botsConfigurados = {}
Context.tutorialDone = {}
Context.tutorialActive = {}
Context.tutorialDailyClaimed = {}
Context.ultimoTick = {}
Context.candidateGenerators = nil

Context.DataStore = Context.DataStoreService:GetDataStore(Context.Config.DATASTORE_NOMBRE)

local function getOrCreateRemote(name)
	local r = Context.ReplicatedStorage:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = Context.ReplicatedStorage
	end
	return r
end

Context.SolicitarDueloDirecto = getOrCreateRemote("SolicitarDueloDirecto")
Context.ResponderDuelo = getOrCreateRemote("ResponderDuelo")
Context.IniciarMinijuego = getOrCreateRemote("IniciarMinijuego")
Context.EnviarClicks = getOrCreateRemote("EnviarClicks")
Context.MostrarResultados = getOrCreateRemote("MostrarResultados")
Context.DesanclarJugador = getOrCreateRemote("DesanclarJugador")
Context.ExpulsarAnclado = getOrCreateRemote("ExpulsarAnclado")
Context.NotificarCliente = getOrCreateRemote("NotificarCliente")
Context.ComprarMejora = getOrCreateRemote("ComprarMejora")
Context.HacerRebirth = getOrCreateRemote("HacerRebirth")
Context.ExpulsionUpdate = getOrCreateRemote("ExpulsionUpdate")
Context.ExpulsionAccion = getOrCreateRemote("ExpulsionAccion")
Context.ExpulsionDefensa = getOrCreateRemote("ExpulsionDefensa")
Context.ClaimDaily = getOrCreateRemote("ClaimDaily")
Context.SyncDaily = getOrCreateRemote("SyncDaily")
Context.TutorialSync = getOrCreateRemote("TutorialSync")
Context.TutorialAction = getOrCreateRemote("TutorialAction")
Context.ReiniciarProgreso = getOrCreateRemote("ReiniciarProgreso")
Context.PedirStatsExtra = getOrCreateRemote("PedirStatsExtra")
Context.StatsExtra = getOrCreateRemote("StatsExtra")


-- Diagnóstico centralizado (respeta Config.DEBUG)
function Context.log(system, ...)
	local d = Context.Config and Context.Config.DEBUG
	if not d or not d.Enabled then
		return
	end
	if system and d[system] == false then
		return
	end
	print("[Triki:" .. tostring(system or "?") .. "]", ...)
end

function Context.warnLog(system, ...)
	warn("[Triki:" .. tostring(system or "?") .. "]", ...)
end

return Context

-- no entiendo el objetivo de este script /