-- ===================================================
-- Config.lua  (ModuleScript → ReplicatedStorage.Shared)
-- ÚNICO archivo para equilibrar el juego
-- =====================================================

local Config = {}

-- =====================================================
-- ICONOS UI (rbxassetid) — glifos sin fondo
-- =====================================================
Config.ICONS = {
	retar = "rbxassetid://83110458830804",
	tienda = "rbxassetid://76296796961930",
	daily = "rbxassetid://72026764082673",
	desanclar = "rbxassetid://123062413236676",
	rebirths = "rbxassetid://113672674287478",
	multixp = "rbxassetid://110501070079990",
	escudo = "rbxassetid://118637266651214",
	moneda = "rbxassetid://107603336117213",
	anclar = "rbxassetid://82600871217538",
	bot = "rbxassetid://93008045120285",
	cerrar = "rbxassetid://137563504571740",
	robux = "rbxassetid://126269559326665",
	poder = "rbxassetid://107797704612734",
	clicks = "rbxassetid://87727658692121",
	walk = "rbxassetid://131735636843512",
	velAnclaje = "rbxassetid://122816742959105",
	monedasPack = "rbxassetid://103764369792951",
	candado = "rbxassetid://96207977416905",
	check = "rbxassetid://128258429125931",
	error = "rbxassetid://71459806238689",
	estrella = "rbxassetid://126056857452190",
}

-- Textos de ProximityPrompt
Config.PROMPT_ANCLAR_ACTION = "Triki Traka"
Config.PROMPT_ANCLAR_OBJECT = "por detrás"
Config.PROMPT_BOT_ACTION = "Retar"

-- =====================================================
-- PROGRESIÓN Y XP
-- =====================================================
Config.XP_INICIAL = 50
Config.XP_ANCLAJE_GANA = 20
Config.XP_ANCLAJE_PIERDE = 10
Config.MAX_XP_BASE = 100
Config.MAX_XP_MULTIPLICADOR = 1.38

-- =====================================================
-- ANCLAJE
-- =====================================================
Config.DISTANCIA_ANCLAJE = 1.65
Config.COOLDOWN_REANCLAR = 45
Config.COSTE_EXPULSAR_MULTIPLICADOR = 30

Config.INTERVALO_BASE = 1.0
Config.INTERVALO_MINIMO = 0.03
Config.REDUCCION_POR_NIVEL_VEL = 0.1

-- =====================================================
-- DUELOS / BOTS
-- =====================================================
Config.MONEDAS_BOT_POR_NIVEL = 35
Config.MONEDAS_PVP_BASE = 70
Config.MONEDAS_PVP_POR_NIVEL = 18

Config.BOT_CLICKS_BASE = 0
Config.BOT_CLICKS_POR_NIVEL = 15
Config.BOT_CLICKS_CUADRATICO = 1.8

Config.BOT_NOMBRE_PATRONES = { "bot", "nivel" }

Config.BOTS = {
	-- { nombre = "Bot_Nivel1", nivel = 1, posicion = Vector3.new(20, 5, 0) },
}

Config.BOT_COLOR = Color3.fromRGB(180, 40, 40)
Config.BOT_TAMANO = Vector3.new(2, 5, 1)

-- =====================================================
-- REBIRTH
-- =====================================================
Config.NIVEL_PARA_REBIRTH = { 7, 8, 10, 13, 17, 22, 28, 35, 43, 52, 62, 73, 85, 98, 112 }
Config.MULTI_XP_AL_REBIRTH = { 1.75, 1.70, 1.65, 1.60, 1.55, 1.50, 1.45, 1.40, 1.35, 1.30, 1.28, 1.25, 1.22, 1.20, 1.18 }
Config.MULTI_CLICKS_AL_REBIRTH = { 1.50, 1.45, 1.40, 1.35, 1.30, 1.25, 1.22, 1.20, 1.18, 1.15, 1.14, 1.12, 1.11, 1.10, 1.08 }
Config.NIVEL_MINIMO_REBIRTH = 7 -- compat: primer valor de NIVEL_PARA_REBIRTH
Config.MULTI_XP_POR_REBIRTH = 1.75
Config.MULTI_CLICKS_POR_REBIRTH = 1.5

-- =====================================================
-- PRECIOS DE TIENDA
-- =====================================================
Config.PRECIO_MULTI_POR_NIVEL = 0.02
Config.PRECIO_DESCUENTO_POR_REBIRTH = 0.1
Config.PRECIO_DESCUENTO_MAX = 0.8
Config.PRECIO_MULTI_POR_CLICKS_OWNED = 0.1
Config.PRECIO_MULTI_POR_VEL_OWNED = 0.08

Config.ANTI_ANCLAJE = {
	{ id = "anti_1min",  nombre = "Escudo Rápido",     segundos = 60,   coste = 80  },
	{ id = "anti_5min",  nombre = "Escudo Fuerte",     segundos = 300,  coste = 200 },
	{ id = "anti_15min", nombre = "Escudo Épico",      segundos = 900,  coste = 400 },
	{ id = "anti_1h",    nombre = "Escudo Legendario", segundos = 3600, coste = 800 },
}

Config.CLICKS_PACKS = {
	{ id = "click_1",  nombre = "+1 Click/Click",   cantidad = 1,  costeBase = 100  },
	{ id = "click_5",  nombre = "+5 Clicks/Click",  cantidad = 5,  costeBase = 420  },
	{ id = "click_10", nombre = "+10 Clicks/Click", cantidad = 10, costeBase = 750  },
	{ id = "click_25", nombre = "+25 Clicks/Click", cantidad = 25, costeBase = 1600 },
}

Config.VELOCIDAD_PACKS = {
	-- "niveles" internos: cada uno resta REDUCCION_POR_NIVEL_VEL segundos al intervalo
	{ id = "vel_1",  nombre = "Anclaje -0.1s",  niveles = 1,  costeBase = 150  },
	{ id = "vel_3",  nombre = "Anclaje -0.3s",  niveles = 3,  costeBase = 400  },
	{ id = "vel_5",  nombre = "Anclaje -0.5s",  niveles = 5,  costeBase = 600  },
	{ id = "vel_10", nombre = "Anclaje -1.0s",  niveles = 10, costeBase = 1000 },
}

Config.WALKSPEED_BASE = 16
Config.WALKSPEED_POR_NIVEL = 1.5
Config.WALKSPEED_MAX_NIVELES = 50
Config.PRECIO_MULTI_POR_WALK_OWNED = 0.10

Config.WALKSPEED_PACKS = {
	{ id = "walk_1",  nombre = "Correr +1",  niveles = 1,  costeBase = 120  },
	{ id = "walk_3",  nombre = "Correr +3",  niveles = 3,  costeBase = 320  },
	{ id = "walk_5",  nombre = "Correr +5",  niveles = 5,  costeBase = 500  },
	{ id = "walk_10", nombre = "Correr +10", niveles = 10, costeBase = 900  },
}


-- Packs de monedas comprables con Robux (Developer Products)
-- Añade filas aquí; productId del Dashboard.
Config.MONEDAS_ROBUX = {
	{ id = "coins_r_1", productId = 3715114258, monedas = 1000,  nombre = "+1.000 Monedas",  precioMostrado = 19  },
	{ id = "coins_r_2", productId = 3715114447, monedas = 5000,  nombre = "+5.000 Monedas",  precioMostrado = 49 },
	{ id = "coins_r_3", productId = 3715114513, monedas = 15000, nombre = "+15.000 Monedas", precioMostrado = 79 },
}

-- =====================================================
-- PRODUCTOS ROBUX (Developer Products)
-- Crea cada producto en Creator Dashboard → Monetization → Developer Products
-- y pega el productId aquí. productId = 0 → se ignora en ProcessReceipt.
-- =====================================================
Config.ROBUX = {
	ESCUDO_LEGENDARIO = {
		productId = 3714896163,
		nombre = "Escudo Legendario",
		descripcion = "2 HORAS de protección total",
		precioMostrado = 25,
		segundosAnti = 7200,
	},
	CLICKS_50 = {
		productId = 3714896226,
		nombre = "+50 Clicks/Click",
		descripcion = "Mega pack de poder extremo",
		precioMostrado = 79,
		clicksExtra = 50,
	},
	VELOCIDAD_ANCLAJE_15 = {
		productId = 3714896297,
		nombre = "Anclaje -1.5s",
		descripcion = "Reduce 1.5s el intervalo de XP al estar anclado",
		precioMostrado = 49,
		nivelesVel = 15,
	},
	VELOCIDAD_CORRER_10 = {
		productId = 3714914314,
		nombre = "Correr +10",
		descripcion = "+10 niveles de velocidad de movimiento",
		precioMostrado = 39,
		nivelesWalk = 10,
	},
}

-- =====================================================
-- PROMO ROBUX PERIÓDICA (notificación esquina)
-- Cada INTERVALO_SEGUNDOS aparece una oferta.
-- Tras comprarla, ese track sube de tier (9 → 19 → 29 → ...)
-- =====================================================
Config.ROBUX_PROMO = {
	INTERVALO_SEGUNDOS = 60,       -- cada cuánto aparece la pestaña
	PRIMERA_ESPERA = 35,           -- segundos tras unirse antes de la 1ª
	DURACION_VISIBLE = 30,         -- se auto-oculta a los N s (0 = no auto)

	-- Cada track tiene tiers crecientes
	TRACKS = {
		{
			id = "multi_xp",
			emoji = "✨",
			titulo = "Multiplicador XP",
			tiers = {
				{ productId = 3714914690, precio = 9,  multiAdd = 0.25, label = "+0.25 Multi XP" },
				{ productId = 3714914809, precio = 19, multiAdd = 0.35, label = "+0.35 Multi XP" },
				{ productId = 3714914874, precio = 29, multiAdd = 0.50, label = "+0.50 Multi XP" },
				{ productId = 3714914918, precio = 49, multiAdd = 0.75, label = "+0.75 Multi XP" },
				{ productId = 3714914969, precio = 79, multiAdd = 1.00, label = "+1.00 Multi XP" },
			},
		},
		{
			id = "nivel",
			emoji = "⬆️",
			titulo = "Subir de nivel",
			tiers = {
				{ productId = 3714915060, precio = 9,  niveles = 1, label = "+1 Nivel" },
				{ productId = 3714915103, precio = 19, niveles = 2, label = "+2 Niveles" },
				{ productId = 3714915169, precio = 29, niveles = 3, label = "+3 Niveles" },
				{ productId = 3714915194, precio = 49, niveles = 5, label = "+5 Niveles" },
			},
		},
		{
			id = "clicks",
			emoji = "🖱️",
			titulo = "Clicks por Click",
			tiers = {
				{ productId = 3714915313, precio = 9,  clicks = 2,  label = "+2 Clicks/Click" },
				{ productId = 3714915353, precio = 19, clicks = 5,  label = "+5 Clicks/Click" },
				{ productId = 3714915405, precio = 29, clicks = 10, label = "+10 Clicks/Click" },
				{ productId = 3714915479, precio = 49, clicks = 25, label = "+20 Clicks/Click" },
			},
		},
		{
			id = "vel_anclaje",
			emoji = "⚡",
			titulo = "Anclaje más rápido",
			tiers = {
				{ productId = 3714915651, precio = 9,  niveles = 1,  label = "Anclaje -0.1s" },
				{ productId = 3714915682, precio = 19, niveles = 3,  label = "Anclaje -0.3s" },
				{ productId = 3714915762, precio = 29, niveles = 5, label = "Anclaje -0.5s" },
			},
		},
		{
			id = "correr",
			emoji = "🏃",
			titulo = "Velocidad de carrera",
			tiers = {
				{ productId = 3714915929, precio = 9,  niveles = 2,  label = "+2 Correr" },
				{ productId = 3714915962, precio = 19, niveles = 5,  label = "+5 Correr" },
				{ productId = 3714916019, precio = 29, niveles = 10, label = "+10 Correr" },
			},
		},
		{
			id = "monedas",
			emoji = "💰",
			titulo = "Pack de monedas",
			tiers = {
				{ productId = 3714916199, precio = 9,  monedas = 500,  label = "+500 Monedas" },
				{ productId = 3714916239, precio = 19, monedas = 1250, label = "+1250 Monedas" },
				{ productId = 3714916311, precio = 29, monedas = 2500, label = "+2500 Monedas" },
				{ productId = 3714916363, precio = 49, monedas = 6000, label = "+6000 Monedas" },
			},
		},
	},
}

-- Índice de todos los productId → definición (para ProcessReceipt)
function Config.getRobuxProductoPorId(productId)
	if not productId or productId == 0 then return nil end
	for key, def in pairs(Config.ROBUX) do
		if def.productId == productId then
			return { source = "ROBUX", key = key, def = def }
		end
	end
	if Config.MONEDAS_ROBUX then
		for _, pack in ipairs(Config.MONEDAS_ROBUX) do
			if pack.productId == productId then
				return { source = "MONEDAS_ROBUX", pack = pack }
			end
		end
	end
	for _, track in ipairs(Config.ROBUX_PROMO.TRACKS) do
		for tierIdx, tier in ipairs(track.tiers) do
			if tier.productId == productId then
				return { source = "PROMO", trackId = track.id, track = track, tierIdx = tierIdx, tier = tier }
			end
		end
	end
	return nil
end

function Config.getPromoTier(trackId, tierIndex)
	for _, track in ipairs(Config.ROBUX_PROMO.TRACKS) do
		if track.id == trackId then
			local idx = math.clamp(tierIndex or 1, 1, #track.tiers)
			return track, track.tiers[idx], idx
		end
	end
	return nil, nil, 1
end

-- =====================================================
-- TABLAS FIJAS (edita valor a valor)
-- Índice = nivel / día de racha / nº de rebirth / niveles de mejora
-- Si el índice > tamaño de la tabla:
--   LOOKUP_EXTRAPOLAR=true  → continúa la tendencia del último salto
--   LOOKUP_EXTRAPOLAR=false → repite el último valor
-- =====================================================
Config.LOOKUP_EXTRAPOLAR = true

-- MaxXP por nivel del jugador
Config.MAX_XP_POR_NIVEL = {
	100, 138, 190, 262, 362, 500, 690, 953, 1315, 1815,
	2504, 3456, 4770, 6583, 9084, 12536, 17300, 23875, 32947, 45467,
	62745, 86588, 119492, 164899, 227561, 314034, 433367, 598047, 825304, 1138920,
	1571710, 2168960, 2993165, 4130568, 5700184, 7866255, 10855431, 14980496, 20673084, 28528856
}

-- Bots de batalla: clicks necesarios (índice = nivel bot)
Config.BOT_CLICKS = {
	16, 37, 61, 88, 120, 154, 193, 235, 280, 330,
	382, 439, 499, 562, 630, 700, 775, 853, 934, 1020,
	1108, 1201, 1297, 1396, 1500, 1606, 1717, 1831, 1948, 2070
}

-- Bots de batalla: monedas al ganar (índice = nivel bot)
Config.BOT_MONEDAS = {
	35, 94, 178, 287, 420, 577, 759, 965, 1197, 1452,
	1732, 2036, 2365, 2719, 3097, 3500, 3927, 4378, 4854, 5355,
	5880, 6429, 7003, 7601, 8224, 8872, 9544, 10241, 10961, 11707
}

-- PvP: monedas al ganar (índice = nivel del ganador)
Config.PVP_MONEDAS = {
	88, 106, 124, 142, 160, 178, 196, 214, 232, 250,
	268, 286, 304, 322, 340, 358, 376, 394, 412, 430,
	448, 466, 484, 502, 520, 538, 556, 574, 592, 610,
	628, 646, 664, 682, 700, 718, 736, 754, 772, 790
}

-- Tope de mejoras según nivel del jugador
Config.MAX_CLICKS_POR_NIVEL_TABLA = {
	2, 4, 6, 8, 10, 12, 14, 16, 18, 20,
	22, 24, 26, 28, 30, 32, 34, 36, 38, 40,
	42, 44, 46, 48, 50, 52, 54, 56, 58, 60,
	62, 64, 66, 68, 70, 72, 74, 76, 78, 80
}
Config.MAX_VEL_ANCLAJE_POR_NIVEL_TABLA = {
	2, 4, 6, 8, 10, 12, 14, 16, 18, 20,
	22, 24, 26, 28, 30, 32, 34, 36, 38, 40,
	42, 44, 46, 48, 50, 52, 54, 56, 58, 60,
	62, 64, 66, 68, 70, 72, 74, 76, 78, 80
}
Config.MAX_WALK_POR_NIVEL_TABLA = {
	2, 4, 6, 8, 10, 12, 14, 16, 18, 20,
	22, 24, 26, 28, 30, 32, 34, 36, 38, 40,
	42, 44, 46, 48, 50, 52, 54, 56, 58, 60,
	62, 64, 66, 68, 70, 72, 74, 76, 78, 80
}
Config.MAX_CLICKS_BASE = 0
Config.MAX_CLICKS_POR_NIVEL = 2
Config.MAX_VEL_ANCLAJE_BASE = 0
Config.MAX_VEL_ANCLAJE_POR_NIVEL = 2
Config.MAX_WALK_BASE = 0
Config.MAX_WALK_POR_NIVEL = 2

-- Intervalo XP anclaje en segundos (índice = VelocidadAnclaje+1; vel 0 → índice 1)
Config.INTERVALO_ANCLAJE_POR_VEL = {
	1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.3, 0.2, 0.1,
	0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03, 0.03,
	0.03
}

-- WalkSpeed (índice = niveles walk + 1)
Config.WALKSPEED_POR_NIVELES = {
	16, 18, 20, 22, 24, 26, 28, 30, 32, 34,
	36, 38, 40, 42, 44, 46, 48, 50, 52, 54,
	56
}
Config.WALKSPEED_BASE = 16
Config.WALKSPEED_POR_NIVEL = 2
Config.WALKSPEED_MAX_NIVELES = 20

-- Rango de monedas por nivel (economía)
Config.ECONOMIA_MIN_POR_NIVEL = {
	100, 135, 182, 246, 332, 448, 605, 817, 1103, 1489,
	2010, 2714, 3664, 4946, 6678, 9015, 12171, 16431, 22182, 29946,
	40427, 54576, 73678, 99466, 134279, 181277, 244724, 330378, 446010, 602114,
	812854, 1097354, 1481428, 1999927, 2699902, 3644868, 4920572, 6642773, 8967744, 12106454
}
Config.ECONOMIA_MAX_POR_NIVEL = {
	200, 270, 364, 492, 664, 896, 1210, 1634, 2206, 2978,
	4021, 5428, 7328, 9893, 13356, 18031, 24342, 32862, 44364, 59892,
	80854, 109153, 147357, 198932, 268559, 362555, 489449, 660756, 892021, 1204229,
	1625709, 2194708, 2962856, 3999855, 5399805, 7289737, 9841145, 13285546, 17935488, 24212908
}
Config.ECONOMIA = {
	MONEDAS_N1_MIN = 100,
	MONEDAS_N1_MAX = 200,
	CRECIMIENTO = 1.35,
}

-- Multi precio tienda por nivel / descuento por rebirths (índice rebirths+1)
Config.PRECIO_MULTI_POR_NIVEL_TABLA = {
	1.0, 1.02, 1.04, 1.06, 1.08, 1.1, 1.12, 1.14, 1.16, 1.18,
	1.2, 1.22, 1.24, 1.26, 1.28, 1.3, 1.32, 1.34, 1.36, 1.38,
	1.4, 1.42, 1.44, 1.46, 1.48, 1.5, 1.52, 1.54, 1.56, 1.58,
	1.6, 1.62, 1.64, 1.66, 1.68, 1.7, 1.72, 1.74, 1.76, 1.78
}
Config.PRECIO_DESCUENTO_POR_REBIRTH_TABLA = {
	1.0, 0.9, 0.81, 0.729, 0.6561, 0.5905, 0.5314, 0.4783, 0.4305, 0.3874,
	0.3487, 0.3138, 0.2824, 0.2542, 0.2288, 0.2059
}
Config.PRECIO_MULTI_POR_NIVEL = 0.02
Config.PRECIO_DESCUENTO_POR_REBIRTH = 0.1
Config.PRECIO_DESCUENTO_MAX = 0.8
Config.PRECIO_MULTI_POR_CLICKS_OWNED = 0.1
Config.PRECIO_MULTI_POR_VEL_OWNED = 0.08
Config.PRECIO_MULTI_POR_WALK_OWNED = 0.10

-- Expulsión
Config.EXPULSION_DINERO_FULL_POR_NIVEL = {
	75, 100, 125, 150, 175, 200, 225, 250, 275, 300,
	325, 350, 375, 400, 425, 450, 475, 500, 525, 550,
	575, 600, 625, 650, 675, 700, 725, 750, 775, 800,
	825, 850, 875, 900, 925, 950, 975, 1000, 1025, 1050
}
Config.EXPULSION_CLICKS_DEFENSA_POR_NIVEL = {
	10, 12, 14, 16, 18, 20, 22, 24, 26, 28,
	30, 32, 34, 36, 38, 40, 42, 44, 46, 48,
	50, 52, 54, 56, 58, 60, 62, 64, 66, 68,
	70, 72, 74, 76, 78, 80, 82, 84, 86, 88
}
Config.EXPULSION = {
	PROB_MAX = 0.95,
	PROB_MIN = 0.05,
	REDUCCION_DEFENSA_MAX = 0.35,
	DURACION_DEFENSA = 3,
	DINERO_BASE = 50,
	DINERO_POR_NIVEL = 25,
	CLICKS_BASE = 8,
	CLICKS_POR_NIVEL = 2,
}

-- Daily por día de racha (índice = streak)
Config.DAILY_POR_RACHA = {
	{ monedas = 175, xp = 50, antiSegundos = 0 },
	{ monedas = 220, xp = 60, antiSegundos = 0 },
	{ monedas = 280, xp = 75, antiSegundos = 60 },
	{ monedas = 350, xp = 90, antiSegundos = 60 },
	{ monedas = 450, xp = 110, antiSegundos = 120 },
	{ monedas = 550, xp = 130, antiSegundos = 120 },
	{ monedas = 700, xp = 160, antiSegundos = 180 },
	{ monedas = 850, xp = 190, antiSegundos = 180 },
	{ monedas = 1000, xp = 220, antiSegundos = 300 },
	{ monedas = 1200, xp = 260, antiSegundos = 300 },
	{ monedas = 1450, xp = 300, antiSegundos = 300 },
	{ monedas = 1700, xp = 350, antiSegundos = 600 },
	{ monedas = 2000, xp = 400, antiSegundos = 600 },
	{ monedas = 2400, xp = 480, antiSegundos = 900 },
}
Config.DAILY = {
	MONEDAS_BASE = 175,
	XP_BASE = 50,
	MULTI_POR_DIA = 0.25,
}

Config.DEBUG_ANIM = false

-- =====================================================
-- RECOMENDACIONES INTELIGENTES (promos contextuales)
-- =====================================================
Config.RECOMENDACIONES = {
	COOLDOWN_SEGUNDOS = 60,
	PRIMERA_ESPERA = 35,
	DURACION_VISIBLE = 40,
	MIN_SESSION = 30,            -- no recomendar antes de X s de sesión
	ESTANCAMIENTO_NIVEL_S = 90, -- sin subir de nivel
	ESTANCAMIENTO_DINERO_S = 60,
	POCO_DINERO_RATIO = 0.2,     -- por debajo del 40% del min del rango
	MUCHOS_ANCHORS_SIN_NIVEL = 2,
	MUCHAS_EXPULSIONES = 1,
	SCORE_MINIMO = 30,          -- umbral para mostrar recomendación
	DEBUG = false,              -- true = prints ranking recomendaciones en Output
}

-- =====================================================
-- BOTS AMBULANTES
-- Carpeta en Workspace: BotsAmbulantes (Model hijos)
-- =====================================================
Config.BOTS_AMBULANTES = {
	CARPETA = "BotsAmbulantes",
	XP_GEN_INTERVALO = 1,
	XP_GEN_CANTIDAD = 1,
	XP_RESERVA_INICIAL = 30,
	XP_RESERVA_MAX = 250,
	XP_POR_TICK_JUGADOR = nil, -- nil = usa Config.XP_ANCLAJE_GANA
	EXPULSION_CHECK_S = 5,
	EXPULSION_CHANCE = 0.2,
	-- Movimiento reducido (menos lag)
	MOVE_WAIT_MIN = 10,
	MOVE_WAIT_MAX = 25,
	WALK_SPEED_MIN = 10,
	WALK_SPEED_MAX = 20,
	RADIO_PATRULLA = 45,
	PROMPT_DISTANCIA = 12,
	-- Animación en CLIENTE (AnimLOD); servidor no carga tracks
	WALK_ANIM_ID = "rbxassetid://507777826",
	IDLE_ANIM_ID = "rbxassetid://507766388",
	SERVER_PLAY_ANIM = false,
}

-- LOD animaciones cliente (bots + anclados ajenos)
Config.ANIM_LOD = {
	DIST_PC = 180,
	DIST_MOBILE = 90,
	DIST_TABLET = 120,
	TICK = 0.35,
	WALK = "rbxassetid://507777826",
	IDLE = "rbxassetid://507766388",
	SIT = "rbxassetid://81091084331411",
	SIT_FALLBACK = "rbxassetid://2506281703",
}

Config.DATASTORE_NOMBRE = "AuraData_v1"
Config.AUTOSAVE_INTERVALO = 60

-- =====================================================
-- HELPERS (leen las tablas de arriba)
-- =====================================================
function Config.lookup(lista, indice, extrapolar)
	indice = math.max(1, math.floor(tonumber(indice) or 1))
	if typeof(lista) ~= "table" or #lista == 0 then
		return 0
	end
	if indice <= #lista then
		return lista[indice]
	end
	local last = lista[#lista]
	local usar = extrapolar
	if usar == nil then usar = Config.LOOKUP_EXTRAPOLAR end
	if usar and #lista >= 2 then
		local delta = lista[#lista] - lista[#lista - 1]
		return last + delta * (indice - #lista)
	end
	return last
end

function Config.getNivelMinimoRebirth(rebirthsActuales)
	local idx = math.max(0, math.floor(tonumber(rebirthsActuales) or 0)) + 1
	return math.floor(Config.lookup(Config.NIVEL_PARA_REBIRTH, idx, true))
end

function Config.getMultiXPAlRebirth(numeroRebirth)
	return Config.lookup(Config.MULTI_XP_AL_REBIRTH, math.max(1, numeroRebirth or 1), false)
end

function Config.getMultiClicksAlRebirth(numeroRebirth)
	return Config.lookup(Config.MULTI_CLICKS_AL_REBIRTH, math.max(1, numeroRebirth or 1), false)
end

function Config.getMaxXP(nivel)
	nivel = math.max(1, math.floor(tonumber(nivel) or 1))
	return math.floor(Config.lookup(Config.MAX_XP_POR_NIVEL, nivel, true))
end

function Config.calcularClicksBot(nivelBot, _)
	nivelBot = math.max(1, math.floor(tonumber(nivelBot) or 1))
	return math.floor(Config.lookup(Config.BOT_CLICKS, nivelBot, true))
end

function Config.getMonedasBot(nivelBot)
	nivelBot = math.max(1, math.floor(tonumber(nivelBot) or 1))
	return math.floor(Config.lookup(Config.BOT_MONEDAS, nivelBot, true))
end

function Config.getMonedasPvP(nivelGanador)
	nivelGanador = math.max(1, math.floor(tonumber(nivelGanador) or 1))
	return math.floor(Config.lookup(Config.PVP_MONEDAS, nivelGanador, true))
end

function Config.getMaxClicks(nivel)
	return math.floor(Config.lookup(Config.MAX_CLICKS_POR_NIVEL_TABLA, math.max(1, nivel or 1), true))
end
function Config.getMaxVelAnclaje(nivel)
	return math.floor(Config.lookup(Config.MAX_VEL_ANCLAJE_POR_NIVEL_TABLA, math.max(1, nivel or 1), true))
end
function Config.getMaxWalk(nivel)
	return math.floor(Config.lookup(Config.MAX_WALK_POR_NIVEL_TABLA, math.max(1, nivel or 1), true))
end

function Config.getIntervaloAnclaje(nivelesVelocidad)
	local idx = math.max(0, math.floor(tonumber(nivelesVelocidad) or 0)) + 1
	return Config.lookup(Config.INTERVALO_ANCLAJE_POR_VEL, idx, false)
end

function Config.getSegundosReducidos(nivelesVelocidad)
	return math.max(0, (Config.INTERVALO_BASE or 1) - Config.getIntervaloAnclaje(nivelesVelocidad))
end

function Config.formatSegundosAnclaje(nivelesVelocidad)
	return string.format("%.2fs", Config.getIntervaloAnclaje(nivelesVelocidad))
end

function Config.formatDeltaSegundos(niveles)
	return string.format("-%.1fs", (tonumber(niveles) or 0) * (Config.REDUCCION_POR_NIVEL_VEL or 0.1))
end

function Config.getWalkSpeed(nivelesWalk)
	local idx = math.max(0, math.floor(tonumber(nivelesWalk) or 0)) + 1
	return Config.lookup(Config.WALKSPEED_POR_NIVELES, idx, false)
end

function Config.getRangoMonedas(nivel)
	nivel = math.max(1, math.floor(tonumber(nivel) or 1))
	return math.floor(Config.lookup(Config.ECONOMIA_MIN_POR_NIVEL, nivel, true)),
		math.floor(Config.lookup(Config.ECONOMIA_MAX_POR_NIVEL, nivel, true))
end

function Config.ajustarMonedasANivel(monedas, nivel, factor)
	local minV, maxV = Config.getRangoMonedas(nivel)
	factor = factor or 1
	return math.clamp(math.floor((tonumber(monedas) or 0) * factor), math.floor(minV * 0.1), maxV * 5)
end

function Config.getDailyReward(streak)
	streak = math.max(1, math.floor(tonumber(streak) or 1))
	local row = Config.DAILY_POR_RACHA[math.min(streak, #Config.DAILY_POR_RACHA)]
	return {
		streak = streak,
		monedas = row.monedas,
		xp = row.xp,
		antiSegundos = row.antiSegundos or 0,
	}
end

function Config.getDineroParaProbFull(nivelAnclado)
	return math.floor(Config.lookup(Config.EXPULSION_DINERO_FULL_POR_NIVEL, math.max(1, nivelAnclado or 1), true))
end

function Config.getClicksParaDefensaMax(nivelAnclado)
	return math.floor(Config.lookup(Config.EXPULSION_CLICKS_DEFENSA_POR_NIVEL, math.max(1, nivelAnclado or 1), true))
end

function Config.probDesdeDinero(dinero, nivelAnclado)
	local E = Config.EXPULSION
	local full = Config.getDineroParaProbFull(nivelAnclado)
	if full <= 0 then return E.PROB_MAX or 0.95 end
	return math.clamp((tonumber(dinero) or 0) / full, E.PROB_MIN or 0.05, E.PROB_MAX or 0.95)
end

function Config.calcExpulsion(dinero, defensaClicks, nivelAnclado)
	local E = Config.EXPULSION
	local base = Config.probDesdeDinero(dinero, nivelAnclado)
	local need = Config.getClicksParaDefensaMax(nivelAnclado)
	local redMax = E.REDUCCION_DEFENSA_MAX or 0.35
	local red = 0
	if need > 0 then
		red = math.min(redMax, (tonumber(defensaClicks) or 0) / need * redMax)
	end
	return math.clamp(base - red, E.PROB_MIN or 0.05, E.PROB_MAX or 0.95), red
end

function Config.getMultiPrecioNivel(nivel)
	return Config.lookup(Config.PRECIO_MULTI_POR_NIVEL_TABLA, math.max(1, nivel or 1), true)
end

function Config.getMultiDescuentoRebirth(rebirths)
	local idx = math.max(0, math.floor(tonumber(rebirths) or 0)) + 1
	return Config.lookup(Config.PRECIO_DESCUENTO_POR_REBIRTH_TABLA, idx, false)
end

function Config.getPrecioFinal(precioBase, nivelJugador, rebirths)
	local minR, maxR = Config.getRangoMonedas(nivelJugador)
	local centro = (minR + maxR) / 2
	local centroN1 = (Config.ECONOMIA.MONEDAS_N1_MIN + Config.ECONOMIA.MONEDAS_N1_MAX) / 2
	local factorEconomia = centro / math.max(1, centroN1)
	local p = precioBase * factorEconomia * Config.getMultiPrecioNivel(nivelJugador) * Config.getMultiDescuentoRebirth(rebirths)
	return math.max(1, math.floor(p))
end
function Config.getPrecioAnti(item, nivelJugador, rebirths)
	return Config.getPrecioFinal(item.coste, nivelJugador, rebirths)
end
function Config.getPrecioClicks(pack, nivelJugador, clicksPorClickActual, rebirths)
	local actual = math.max(1, clicksPorClickActual or 1)
	local base = pack.costeBase * (1 + (actual - 1) * Config.PRECIO_MULTI_POR_CLICKS_OWNED)
	return Config.getPrecioFinal(base, nivelJugador, rebirths)
end
function Config.getPrecioVelocidad(pack, nivelJugador, velocidadActual, rebirths)
	local actual = math.max(0, velocidadActual or 0)
	local base = pack.costeBase * (1 + actual * Config.PRECIO_MULTI_POR_VEL_OWNED)
	return Config.getPrecioFinal(base, nivelJugador, rebirths)
end
function Config.getPrecioWalk(pack, nivelJugador, walkOwned, rebirths)
	local actual = math.max(0, walkOwned or 0)
	local base = pack.costeBase * (1 + actual * (Config.PRECIO_MULTI_POR_WALK_OWNED or 0.10))
	return Config.getPrecioFinal(base, nivelJugador, rebirths)
end

-- =====================================================
-- LEADERBOARDS GLOBALES (OrderedDataStore + Parts)
-- =====================================================
-- Coloca Parts en Workspace con partName (o cambia los nombres aquí).
-- NivelConseguido = niveles alcanzados en toda la vida (NO se resetea con rebirth).
Config.LEADERBOARDS = {
	Enabled = true,
	MaxEntries = 10,
	RefreshInterval = 20,
	WriteDebounce = 5,
	-- Cara del SurfaceGui: Front | Back | Left | Right | Top | Bottom
	Face = "Back",
	Boards = {
		{
			id = "nivel_conseguido",
			titulo = "NIVEL CONSEGUIDO",
			stat = "NivelConseguido",
			partName = "LB_NivelConseguido",
			orderedStore = "AuraLB_NivelConseguido_v1",
		},
		{
			id = "monedas",
			titulo = "MONEDAS",
			stat = "Monedas",
			partName = "LB_Monedas",
			orderedStore = "AuraLB_Monedas_v1",
		},
		{
			id = "rebirths",
			titulo = "REBIRTHS",
			stat = "Rebirths",
			partName = "LB_Rebirths",
			orderedStore = "AuraLB_Rebirths_v1",
		},
		{
			id = "victorias_pvp",
			titulo = "VICTORIAS PVP",
			stat = "Victorias",
			partName = "LB_VictoriasPvP",
			orderedStore = "AuraLB_VictoriasPvP_v1",
		},
	},
}

function Config.esNombreBot(nombre)
	if typeof(nombre) ~= "string" then return false end
	local n = string.lower(nombre)
	if string.sub(n, 1, 3) == "bot" then return true end
	if string.find(n, "bot_", 1, true) or string.find(n, "_bot", 1, true) then return true end
	return false
end
function Config.extraerNivelBot(nombre)
	local num = string.match(nombre, "%d+")
	return num and tonumber(num) or 5
end

return Config
