-- =====================================================
-- init.client.lua (LocalScript = StarterPlayerScripts.Client)
-- =====================================================
print("[AuraUI] Cliente iniciando...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Config (con timeout para no colgar la UI)
local Config
do
	local ok, shared = pcall(function()
		return ReplicatedStorage:WaitForChild("Shared", 10)
	end)
	if ok and shared then
		local ok2, conf = pcall(function()
			return require(shared:WaitForChild("Config", 10))
		end)
		if ok2 then
			Config = conf
			print("[AuraUI] Config OK")
		else
			warn("[AuraUI] require Config falló:", conf)
			Config = {}
		end
	else
		warn("[AuraUI] Shared no encontrado")
		Config = {}
	end
end

-- Defaults si Config incompleto
Config.EXPULSION = Config.EXPULSION or { DINERO_MINIMO = 10, DEFENSA_DURACION = 3, DEFENSA_REDUCCION_MAX = 0.35, PROB_MAX = 0.95 }

-- =====================================================
-- TRIKE ARCADE — tokens + iconos
-- =====================================================
local TEMA = {
	fondo = Color3.fromRGB(18, 20, 28),
	fondoOscuro = Color3.fromRGB(30, 33, 48),
	superficie = Color3.fromRGB(30, 33, 48),
	oro = Color3.fromRGB(245, 197, 66),
	amarillo = Color3.fromRGB(245, 197, 66), -- alias
	naranja = Color3.fromRGB(255, 138, 31),
	rojo = Color3.fromRGB(231, 76, 60),
	verde = Color3.fromRGB(46, 204, 113),
	morado = Color3.fromRGB(155, 89, 255),
	azul = Color3.fromRGB(61, 220, 255),
	cian = Color3.fromRGB(61, 220, 255),
	texto = Color3.fromRGB(244, 241, 232),
	textoSuave = Color3.fromRGB(200, 196, 180),
	muted = Color3.fromRGB(168, 164, 154),
	borde = Color3.fromRGB(245, 197, 66),
	bordeOscuro = Color3.fromRGB(20, 20, 20),
}

local ICONS = {
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

-- Decal (AssetType 13) no renderiza en ImageLabel; rbxthumb sí funciona con esos IDs
local function normalizeAsset(id)
	if not id or id == "" then return "" end
	local s = tostring(id)
	local num = tonumber(string.match(s, "%d+"))
	if not num then return s end
	-- Preferir thumb para Decals subidos por el usuario
	return string.format("rbxthumb://type=Asset&id=%d&w=150&h=150", num)
end

-- Icono como ImageLabel hijo (no captura clics)
local function iconImg(parent, asset, size, pos)
	local img = Instance.new("ImageLabel")
	img.Name = "Icon"
	img.BackgroundTransparency = 1
	img.BorderSizePixel = 0
	img.Image = normalizeAsset(asset)
	img.ImageColor3 = Color3.new(1, 1, 1)
	img.ImageTransparency = 0
	img.Size = size or UDim2.new(0, 28, 0, 28)
	img.Position = pos or UDim2.new(0.5, -14, 0.5, -14)
	img.AnchorPoint = Vector2.new(0, 0)
	img.ScaleType = Enum.ScaleType.Fit
	img.Active = false
	img.Selectable = false
	img.ZIndex = math.max((parent and parent.ZIndex or 1) + 1, 2)
	img.Parent = parent
	return img
end

-- Preferido en botones: la imagen va en el propio ImageButton
local function setButtonIcon(btn, asset, pad)
	pad = pad or 10
	btn.Image = normalizeAsset(asset)
	btn.ImageColor3 = Color3.new(1, 1, 1)
	btn.ImageTransparency = 0
	btn.ScaleType = Enum.ScaleType.Fit
	btn.BackgroundColor3 = btn.BackgroundColor3
	-- márgenes internos
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, pad)
	p.PaddingBottom = UDim.new(0, pad)
	p.PaddingLeft = UDim.new(0, pad)
	p.PaddingRight = UDim.new(0, pad)
	p.Parent = btn
end

local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function goldStroke(parent, thickness)
	local st = Instance.new("UIStroke")
	st.Color = TEMA.oro
	st.Thickness = thickness or 2
	st.Parent = parent
	return st
end

local function darkCard(parent, size, pos)
	local outer = Instance.new("Frame")
	outer.Size = size
	outer.Position = pos or UDim2.new(0, 0, 0, 0)
	outer.BackgroundColor3 = TEMA.oro
	outer.Parent = parent
	Instance.new("UICorner", outer).CornerRadius = UDim.new(0, 14)
	goldStroke(outer, 0) -- rim is fill color
	local inner = Instance.new("Frame")
	inner.Size = UDim2.new(1, -6, 1, -6)
	inner.Position = UDim2.new(0, 3, 0, 3)
	inner.BackgroundColor3 = TEMA.fondoOscuro
	inner.Parent = outer
	Instance.new("UICorner", inner).CornerRadius = UDim.new(0, 11)
	return outer, inner
end

local function waitRemote(name)
	local r = ReplicatedStorage:WaitForChild(name, 12)
	if not r then
		print("[AuraUI] Esperando remote:", name)
	end
	return r
end

print("[AuraUI] Esperando remotes...")
local SolicitarDueloDirecto = waitRemote("SolicitarDueloDirecto")
local ResponderDuelo       = waitRemote("ResponderDuelo")
local IniciarMinijuego     = waitRemote("IniciarMinijuego")
local EnviarClicks         = waitRemote("EnviarClicks")
local MostrarResultados    = waitRemote("MostrarResultados")
local DesanclarJugador     = waitRemote("DesanclarJugador")
local ExpulsarAnclado      = waitRemote("ExpulsarAnclado")
local NotificarCliente     = waitRemote("NotificarCliente")
local ComprarMejora        = waitRemote("ComprarMejora")
local HacerRebirth         = waitRemote("HacerRebirth")
local ExpulsionUpdate      = waitRemote("ExpulsionUpdate")
local ExpulsionAccion      = waitRemote("ExpulsionAccion")
local ExpulsionDefensa     = waitRemote("ExpulsionDefensa")
local ClaimDaily           = waitRemote("ClaimDaily")
local SyncDaily            = waitRemote("SyncDaily")
print("[AuraUI] Remotes listos")

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

-- =====================================================
-- SCREEN GUI (se crea aunque fallen remotes)
-- =====================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 100
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui
print("[AuraUI] ScreenGui creado en PlayerGui")


-- =====================================================
-- CONTENEDOR NOTIFICACIONES + helpers (requeridos)
-- =====================================================
local notifContainer = Instance.new("Frame")
notifContainer.Name = "NotifContainer"
notifContainer.Size = UDim2.new(0, 300, 0, 420)
notifContainer.Position = UDim2.new(1, -316, 0, 12)
notifContainer.BackgroundTransparency = 1
notifContainer.ZIndex = 80
notifContainer.Parent = screenGui
local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.Padding = UDim.new(0, 8)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = notifContainer

local function crearNotificacion(titulo, mensaje, botones, persistente, iconAsset)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = TEMA.fondoOscuro
	card.ZIndex = 81
	card.Parent = notifContainer
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local onlyStroke = Instance.new("UIStroke")
	onlyStroke.Color = TEMA.oro
	onlyStroke.Thickness = 2
	onlyStroke.Parent = card

	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = card

	local cardLayout = Instance.new("UIListLayout")
	cardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	cardLayout.Padding = UDim.new(0, 6)
	cardLayout.Parent = card

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 24)
	top.BackgroundTransparency = 1
	top.LayoutOrder = 1
	top.ZIndex = 82
	top.Parent = card

	local titleLeft = 0
	if iconAsset then
		local ic = iconImg(top, iconAsset, UDim2.new(0, 20, 0, 20), UDim2.new(0, 0, 0.5, -10))
		ic.ZIndex = 83
		titleLeft = 26
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -28 - titleLeft, 1, 0)
	title.Position = UDim2.new(0, titleLeft, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextColor3 = TEMA.oro or TEMA.naranja
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = tostring(titulo or "")
	title.ZIndex = 82
	title.Parent = top

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 24, 0, 24)
	close.Position = UDim2.new(1, -24, 0, 0)
	close.BackgroundColor3 = TEMA.rojo
	close.Text = "X"
	close.Font = Enum.Font.GothamBlack
	close.TextSize = 12
	close.TextColor3 = Color3.new(1, 1, 1)
	close.AutoButtonColor = true
	close.ZIndex = 90
	close.Parent = top
	Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
	close.MouseButton1Click:Connect(function()
		card:Destroy()
	end)

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextColor3 = TEMA.texto
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextWrapped = true
	body.Text = tostring(mensaje or "")
	body.ZIndex = 82
	body.LayoutOrder = 2
	body.Parent = card

	if type(botones) == "table" and #botones > 0 then
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 34)
		row.BackgroundTransparency = 1
		row.ZIndex = 82
		row.LayoutOrder = 3
		row.Parent = card
		local bl = Instance.new("UIListLayout")
		bl.FillDirection = Enum.FillDirection.Horizontal
		bl.Padding = UDim.new(0, 6)
		bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		bl.Parent = row
		for _, bdef in ipairs(botones) do
			local label = tostring(bdef.texto or bdef.text or "OK")
			local b = Instance.new("TextButton")
			-- ancho según texto (mín 120, máx full)
			local w = math.clamp(#label * 9 + 28, 120, 260)
			b.Size = UDim2.new(0, w, 0, 32)
			b.BackgroundColor3 = (bdef.color) or TEMA.verde
			b.Font = Enum.Font.GothamBold
			b.TextSize = 13
			b.TextColor3 = Color3.new(1, 1, 1)
			b.Text = label
			b.ZIndex = 83
			b.Parent = row
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			b.MouseButton1Click:Connect(function()
				if type(bdef.callback) == "function" then
					bdef.callback()
				end
				card:Destroy()
			end)
		end
	end

	if not persistente then
		task.delay(5, function()
			if card and card.Parent then card:Destroy() end
		end)
	end
	return card
end

-- Animación de anclaje (cliente)
local anclajeTrack = nil
local function stopAnclajeAnimLocal()
	if anclajeTrack then
		pcall(function() anclajeTrack:Stop(0.15) end)
		anclajeTrack = nil
	end
	local char = player.Character
	if char then
		local animate = char:FindFirstChild("Animate")
		if animate and animate:IsA("LocalScript") then
			animate.Disabled = false
		end
	end
end

local function playAnclajeAnimLocal(animId)
	stopAnclajeAnimLocal()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local animator = hum:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = hum
	end
	local id = animId or (Config and (Config.ANIMACION_ANCLAJE_ID or (Config.ANIMS and Config.ANIMS.SIT))) or "rbxassetid://2506281703"
	local num = tonumber(tostring(id):match("%d+")) or 2506281703
	local anim = Instance.new("Animation")
	anim.AnimationId = "rbxassetid://" .. tostring(num)
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = true
		track:Play(0.2)
		anclajeTrack = track
		local animate = char:FindFirstChild("Animate")
		if animate and animate:IsA("LocalScript") then
			-- no desactivar Animate si usamos sit nativo; solo si anim custom
		end
	end
end



-- Precarga iconos (si fallan, ver Output)
task.spawn(function()
	local holder = Instance.new("Folder")
	holder.Name = "_IconPreload"
	holder.Parent = screenGui
	local imgs = {}
	for name, id in pairs(ICONS) do
		local img = Instance.new("ImageLabel")
		img.Name = name
		img.Size = UDim2.new(0, 1, 0, 1)
		img.BackgroundTransparency = 1
		img.Image = normalizeAsset(id)
		img.Visible = false
		img.Parent = holder
		table.insert(imgs, img)
	end
	local ok, err = pcall(function()
		game:GetService("ContentProvider"):PreloadAsync(imgs)
	end)
	print("[AuraUI] Preload iconos:", ok and ("OK x" .. #imgs) or tostring(err))
	-- deja el folder: ayuda a cachear; oculta
end)

local menuAbierto = false
local dailyFrame = nil
local notifAncladoCard = nil
local dueloNotifCard = nil



-- =====================================================
-- HUD central + chips satélite
-- =====================================================
local hudOuter, hud = darkCard(screenGui, UDim2.new(0, 320, 0, 96), UDim2.new(0.5, -160, 0, 14))
hudOuter.Name = "HUD"
hudOuter.ZIndex = 20

local nivelLabel = Instance.new("TextLabel")
nivelLabel.Size = UDim2.new(0.55, 0, 0, 26)
nivelLabel.Position = UDim2.new(0, 12, 0, 6)
nivelLabel.BackgroundTransparency = 1
nivelLabel.Font = Enum.Font.GothamBlack
nivelLabel.TextSize = 20
nivelLabel.TextColor3 = TEMA.texto
nivelLabel.TextXAlignment = Enum.TextXAlignment.Left
nivelLabel.Text = "NV 1"
nivelLabel.Parent = hud

local monedasRow = Instance.new("Frame")
monedasRow.Name = "MonedasRow"
monedasRow.Size = UDim2.new(0, 140, 0, 28)
monedasRow.Position = UDim2.new(1, -148, 0, 5)
monedasRow.BackgroundTransparency = 1
monedasRow.Parent = hud
local monedasIcon = iconImg(monedasRow, ICONS.moneda, UDim2.new(0, 24, 0, 24), UDim2.new(0, 0, 0.5, -12))
local monedasLabel = Instance.new("TextLabel")
monedasLabel.Size = UDim2.new(1, -32, 1, 0)
monedasLabel.Position = UDim2.new(0, 30, 0, 0)
monedasLabel.BackgroundTransparency = 1
monedasLabel.Font = Enum.Font.GothamBold
monedasLabel.TextSize = 16
monedasLabel.TextColor3 = TEMA.oro
monedasLabel.TextXAlignment = Enum.TextXAlignment.Left
monedasLabel.Text = "0"
monedasLabel.Parent = monedasRow

local xpBg = Instance.new("Frame")
xpBg.Size = UDim2.new(1, -24, 0, 18)
xpBg.Position = UDim2.new(0, 12, 0, 40)
xpBg.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
xpBg.Parent = hud
Instance.new("UICorner", xpBg).CornerRadius = UDim.new(0, 9)

local xpFill = Instance.new("Frame")
xpFill.Size = UDim2.new(0, 0, 1, 0)
xpFill.BackgroundColor3 = TEMA.naranja
xpFill.Parent = xpBg
Instance.new("UICorner", xpFill).CornerRadius = UDim.new(0, 9)

local xpText = Instance.new("TextLabel")
xpText.Size = UDim2.new(1, 0, 1, 0)
xpText.BackgroundTransparency = 1
xpText.Font = Enum.Font.GothamBold
xpText.TextSize = 12
xpText.TextColor3 = TEMA.texto
xpText.Text = "0 / 100"
xpText.Parent = xpBg

-- Chips izquierda: Rebirths + Multi XP
local chipRebirth = Instance.new("Frame")
chipRebirth.Name = "ChipRebirths"
chipRebirth.Size = UDim2.new(0, 118, 0, 28)
chipRebirth.Position = UDim2.new(0.5, -286, 0, 18)
chipRebirth.BackgroundColor3 = TEMA.fondoOscuro
chipRebirth.Parent = screenGui
Instance.new("UICorner", chipRebirth).CornerRadius = UDim.new(0, 10)
goldStroke(chipRebirth, 1)
iconImg(chipRebirth, ICONS.rebirths, UDim2.new(0, 16, 0, 16), UDim2.new(0, 6, 0.5, -8))
local chipRebirthLbl = Instance.new("TextLabel")
chipRebirthLbl.Size = UDim2.new(1, -28, 1, 0)
chipRebirthLbl.Position = UDim2.new(0, 26, 0, 0)
chipRebirthLbl.BackgroundTransparency = 1
chipRebirthLbl.Font = Enum.Font.GothamBold
chipRebirthLbl.TextSize = 12
chipRebirthLbl.TextColor3 = TEMA.texto
chipRebirthLbl.TextXAlignment = Enum.TextXAlignment.Left
chipRebirthLbl.Text = "Rebirths: 0"
chipRebirthLbl.Parent = chipRebirth

local chipMulti = Instance.new("Frame")
chipMulti.Name = "ChipMultiXP"
chipMulti.Size = UDim2.new(0, 120, 0, 28)
chipMulti.Position = UDim2.new(0.5, -286, 0, 50)
chipMulti.BackgroundColor3 = TEMA.fondoOscuro
chipMulti.Parent = screenGui
Instance.new("UICorner", chipMulti).CornerRadius = UDim.new(0, 10)
goldStroke(chipMulti, 1)
iconImg(chipMulti, ICONS.multixp, UDim2.new(0, 16, 0, 16), UDim2.new(0, 6, 0.5, -8))
local chipMultiLbl = Instance.new("TextLabel")
chipMultiLbl.Size = UDim2.new(1, -28, 1, 0)
chipMultiLbl.Position = UDim2.new(0, 26, 0, 0)
chipMultiLbl.BackgroundTransparency = 1
chipMultiLbl.Font = Enum.Font.GothamBold
chipMultiLbl.TextSize = 12
chipMultiLbl.TextColor3 = TEMA.oro
chipMultiLbl.TextXAlignment = Enum.TextXAlignment.Left
chipMultiLbl.Text = "x1 XP"
chipMultiLbl.Parent = chipMulti


local function formatNum(n)
	n = tonumber(n) or 0
	local neg = n < 0
	n = math.abs(n)
	local function neat(val, suffix)
		-- redondeo a 1 decimal; si queda .0 se quita
		local r = math.floor(val * 10 + 0.5) / 10
		local s
		if r >= 100 then
			s = string.format("%.0f", r)
		elseif r == math.floor(r) then
			s = string.format("%.0f", r)
		else
			s = string.format("%.1f", r)
		end
		return s .. suffix
	end
	local out
	if n >= 1e12 then
		out = neat(n / 1e12, "T")
	elseif n >= 1e9 then
		out = neat(n / 1e9, "B")
	elseif n >= 1e6 then
		out = neat(n / 1e6, "M")
	elseif n >= 1e3 then
		out = neat(n / 1e3, "K")
	else
		out = tostring(math.floor(n + 0.5))
	end
	if neg then out = "-" .. out end
	return out
end

local function actualizarHUD()
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local nivel = ls:FindFirstChild("Nivel")
	local xp = ls:FindFirstChild("XP")
	local maxXp = ls:FindFirstChild("MaxXP")
	local monedas = ls:FindFirstChild("Monedas")
	local rebirths = ls:FindFirstChild("Rebirths")
	local multi = ls:FindFirstChild("MultiXP")
	if nivel then
		nivelLabel.Text = "NV " .. tostring(nivel.Value)
	end
	if monedas then
		monedasLabel.Text = formatNum(monedas.Value)
	end
	local xpV = xp and xp.Value or 0
	local maxV = maxXp and math.max(1, maxXp.Value) or 100
	xpFill.Size = UDim2.new(math.clamp(xpV / maxV, 0, 1), 0, 1, 0)
	xpText.Text = formatNum(xpV) .. " / " .. formatNum(maxV)
	if rebirths then
		chipRebirthLbl.Text = "Rebirths: " .. tostring(rebirths.Value)
	end
	if multi then
		chipMultiLbl.Text = "x" .. formatNum(multi.Value) .. " XP"
	elseif Config and Config.getMultiXP then
		local r = rebirths and rebirths.Value or 0
		local m = 1
		pcall(function() m = Config.getMultiXP(r) or 1 end)
		chipMultiLbl.Text = "x" .. formatNum(m) .. " XP"
	end
end

task.spawn(function()
	local ls = player:WaitForChild("leaderstats", 20)
	if not ls then return end
	actualizarHUD()
	for _, v in ipairs(ls:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			v.Changed:Connect(actualizarHUD)
		end
	end
	ls.ChildAdded:Connect(function(c)
		if c:IsA("IntValue") or c:IsA("NumberValue") then
			c.Changed:Connect(actualizarHUD)
			actualizarHUD()
		end
	end)
end)


-- Escudo / protección a la derecha del HUD
local protFrame = Instance.new("Frame")
protFrame.Name = "ProteccionTimer"
protFrame.Size = UDim2.new(0, 88, 0, 36)
protFrame.Position = UDim2.new(0.5, 172, 0, 22)
protFrame.BackgroundColor3 = Color3.fromRGB(20, 40, 50)
protFrame.Visible = false
protFrame.ZIndex = 50
protFrame.Parent = screenGui
Instance.new("UICorner", protFrame).CornerRadius = UDim.new(0, 10)
local protStroke = Instance.new("UIStroke")
protStroke.Color = TEMA.cian
protStroke.Thickness = 2
protStroke.Parent = protFrame
iconImg(protFrame, ICONS.escudo, UDim2.new(0, 18, 0, 18), UDim2.new(0, 8, 0.5, -9))
local protLabel = Instance.new("TextLabel")
protLabel.Size = UDim2.new(1, -32, 1, 0)
protLabel.Position = UDim2.new(0, 30, 0, 0)
protLabel.BackgroundTransparency = 1
protLabel.Font = Enum.Font.GothamBlack
protLabel.TextSize = 13
protLabel.TextColor3 = TEMA.cian
protLabel.TextXAlignment = Enum.TextXAlignment.Left
protLabel.Text = "0s"
protLabel.Parent = protFrame

local function formatProt(seg)
	seg = math.max(0, math.ceil(seg or 0))
	local m = math.floor(seg / 60)
	local s = seg % 60
	if m > 0 then
		return string.format("%d:%02d", m, s)
	end
	return string.format("%ds", s)
end

-- Estado anclado (abajo izquierda)
local ancladoPill = Instance.new("Frame")
ancladoPill.Name = "AncladoPill"
ancladoPill.Size = UDim2.new(0, 220, 0, 32)
ancladoPill.Position = UDim2.new(0, 16, 1, -48)
ancladoPill.BackgroundColor3 = Color3.fromRGB(20, 50, 55)
ancladoPill.Visible = false
ancladoPill.Parent = screenGui
Instance.new("UICorner", ancladoPill).CornerRadius = UDim.new(1, 0)
local ancladoStroke = Instance.new("UIStroke")
ancladoStroke.Color = TEMA.cian
ancladoStroke.Thickness = 1
ancladoStroke.Parent = ancladoPill
local ancladoLbl = Instance.new("TextLabel")
ancladoLbl.Size = UDim2.new(1, -12, 1, 0)
ancladoLbl.Position = UDim2.new(0, 8, 0, 0)
ancladoLbl.BackgroundTransparency = 1
ancladoLbl.Font = Enum.Font.GothamBold
ancladoLbl.TextSize = 13
ancladoLbl.TextColor3 = TEMA.cian
ancladoLbl.TextXAlignment = Enum.TextXAlignment.Left
ancladoLbl.Text = ""
ancladoLbl.Parent = ancladoPill

-- =====================================================
-- RAIL IZQUIERDO (solo iconos)
-- =====================================================
local sidePanel = Instance.new("Frame")
sidePanel.Name = "SideButtons"
sidePanel.Size = UDim2.new(0, 56, 0, 280)
sidePanel.Position = UDim2.new(0, 12, 0.5, -140)
sidePanel.BackgroundTransparency = 1
sidePanel.ZIndex = 15
sidePanel.Parent = screenGui

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 10)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidePanel

local function crearBotonIcono(iconAsset, order, accent)
	local b = Instance.new("ImageButton")
	b.Size = UDim2.new(0, 52, 0, 52)
	b.BackgroundColor3 = TEMA.fondoOscuro
	b.AutoButtonColor = false
	b.LayoutOrder = order or 0
	b.ZIndex = 16
	b.Parent = sidePanel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	goldStroke(b, 2)
	setButtonIcon(b, iconAsset, 11)
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = Color3.fromRGB(45, 50, 68)
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = TEMA.fondoOscuro
	end)
	return b
end

local btnRetar     = crearBotonIcono(ICONS.retar, 1)
local btnTienda    = crearBotonIcono(ICONS.tienda, 2)
local btnDaily     = crearBotonIcono(ICONS.daily, 3)
local btnDesanclar = crearBotonIcono(ICONS.desanclar, 4)
btnDesanclar.Visible = false

btnDesanclar.MouseButton1Click:Connect(function()
	if DesanclarJugador then DesanclarJugador:FireServer() end
	btnDesanclar.Visible = false
	ancladoPill.Visible = false
end)

local function cerrarMenusLaterales()
	menuRetos.Visible = false
	menuAbierto = false
	if dailyFrame then dailyFrame.Visible = false end
end


-- =====================================================
-- MENÚ RETAR PANEL (Trike Arcade)
-- =====================================================
local menuRetosOuter, menuRetosInner = darkCard(screenGui, UDim2.new(0, 280, 0, 360), UDim2.new(0, 76, 0.5, -180))
menuRetosOuter.Name = "MenuRetos"
menuRetosOuter.Visible = false
menuRetosOuter.ZIndex = 30
menuRetosInner.ZIndex = 31

local retosTitleRow = Instance.new("Frame")
retosTitleRow.Size = UDim2.new(1, -12, 0, 36)
retosTitleRow.Position = UDim2.new(0, 6, 0, 6)
retosTitleRow.BackgroundTransparency = 1
retosTitleRow.ZIndex = 32
retosTitleRow.Parent = menuRetosInner
iconImg(retosTitleRow, ICONS.retar, UDim2.new(0, 22, 0, 22), UDim2.new(0, 4, 0.5, -11))
local retosTitle = Instance.new("TextLabel")
retosTitle.Size = UDim2.new(1, -70, 1, 0)
retosTitle.Position = UDim2.new(0, 32, 0, 0)
retosTitle.BackgroundTransparency = 1
retosTitle.Font = Enum.Font.GothamBlack
retosTitle.TextSize = 18
retosTitle.TextColor3 = TEMA.texto
retosTitle.TextXAlignment = Enum.TextXAlignment.Left
retosTitle.Text = "RETAR"
retosTitle.ZIndex = 32
retosTitle.Parent = retosTitleRow
local retosCerrar = Instance.new("TextButton")
retosCerrar.Name = "Cerrar"
retosCerrar.Size = UDim2.new(0, 28, 0, 28)
retosCerrar.Position = UDim2.new(1, -32, 0.5, -14)
retosCerrar.BackgroundColor3 = TEMA.rojo
retosCerrar.Text = "X"
retosCerrar.Font = Enum.Font.GothamBlack
retosCerrar.TextSize = 16
retosCerrar.TextColor3 = Color3.new(1, 1, 1)
retosCerrar.AutoButtonColor = true
retosCerrar.Active = true
retosCerrar.Selectable = true
retosCerrar.ZIndex = 200
retosCerrar.Parent = retosTitleRow
Instance.new("UICorner", retosCerrar).CornerRadius = UDim.new(0, 8)
retosCerrar.MouseButton1Click:Connect(function()
	menuRetosOuter.Visible = false
	menuAbierto = false
end)

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -16, 1, -56)
scroll.Position = UDim2.new(0, 8, 0, 48)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = TEMA.oro
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.BorderSizePixel = 0
scroll.ZIndex = 32
scroll.Parent = menuRetosInner
do
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = scroll
end

local menuRetos = menuRetosOuter

-- =====================================================
-- TIENDA (Trike Arcade)
-- =====================================================
local menuTiendaOuter, menuTiendaInner = darkCard(screenGui, UDim2.new(0, 500, 0, 560), UDim2.new(0.5, -250, 0.5, -280))
menuTiendaOuter.Name = "MenuTienda"
menuTiendaOuter.Visible = false
menuTiendaOuter.ZIndex = 30
menuTiendaInner.ZIndex = 31

local header = Instance.new("Frame")
header.Size = UDim2.new(1, -12, 0, 48)
header.Position = UDim2.new(0, 6, 0, 6)
header.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
header.ZIndex = 100
header.Parent = menuTiendaInner
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)
-- sin borde dorado en título + X
iconImg(header, ICONS.tienda, UDim2.new(0, 24, 0, 24), UDim2.new(0, 12, 0.5, -12))
local tituloTienda = Instance.new("TextLabel")
tituloTienda.Size = UDim2.new(1, -90, 1, 0)
tituloTienda.Position = UDim2.new(0, 44, 0, 0)
tituloTienda.BackgroundTransparency = 1
tituloTienda.Font = Enum.Font.GothamBlack
tituloTienda.TextSize = 22
tituloTienda.TextColor3 = TEMA.texto
tituloTienda.TextXAlignment = Enum.TextXAlignment.Left
tituloTienda.Text = "TIENDA"
tituloTienda.ZIndex = 33
tituloTienda.Parent = header
local btnCerrarX = Instance.new("TextButton")
btnCerrarX.Name = "Cerrar"
btnCerrarX.Size = UDim2.new(0, 32, 0, 32)
btnCerrarX.Position = UDim2.new(1, -40, 0.5, -16)
btnCerrarX.BackgroundColor3 = TEMA.rojo
btnCerrarX.Text = "X"
btnCerrarX.Font = Enum.Font.GothamBlack
btnCerrarX.TextSize = 18
btnCerrarX.TextColor3 = Color3.new(1, 1, 1)
btnCerrarX.AutoButtonColor = true
btnCerrarX.Active = true
btnCerrarX.Selectable = true
btnCerrarX.ZIndex = 200
btnCerrarX.Parent = header
Instance.new("UICorner", btnCerrarX).CornerRadius = UDim.new(0, 8)
btnCerrarX.MouseButton1Click:Connect(function()
	menuTiendaOuter.Visible = false
end)

-- =====================================================
-- TIENDA: pestañas + páginas (sin reparenting frágil)
-- =====================================================
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -16, 0, 36)
tabBar.Position = UDim2.new(0, 8, 0, 56)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 40
tabBar.Parent = menuTiendaInner
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Parent = tabBar

local scrollTienda = Instance.new("ScrollingFrame")
scrollTienda.Name = "ScrollTienda"
scrollTienda.Size = UDim2.new(1, -16, 1, -110)
scrollTienda.Position = UDim2.new(0, 8, 0, 98)
scrollTienda.BackgroundTransparency = 1
scrollTienda.BorderSizePixel = 0
scrollTienda.ScrollBarThickness = 6
scrollTienda.ScrollBarImageColor3 = TEMA.oro
scrollTienda.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollTienda.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollTienda.ScrollingDirection = Enum.ScrollingDirection.Y
scrollTienda.ZIndex = 32
scrollTienda.ClipsDescendants = true
scrollTienda.Parent = menuTiendaInner

local menuTienda = menuTiendaOuter

local pageHolder = Instance.new("Folder")
pageHolder.Name = "TiendaPages"
pageHolder.Parent = menuTiendaInner

local TAB_NAMES = {"Robux", "Poder", "Escudos", "Movimiento", "Rebirth"}
local tiendaPages = {}
local tiendaTabBtns = {}
local tiendaTabActual = "Robux"
local actualizarPreciosTienda -- forward

for _, tabName in ipairs(TAB_NAMES) do
	local page = Instance.new("Frame")
	page.Name = "Page_" .. tabName
	page.Size = UDim2.new(1, -4, 0, 0)
	page.AutomaticSize = Enum.AutomaticSize.Y
	page.BackgroundTransparency = 1
	page.Visible = false
	page.ZIndex = 33
	page.Parent = pageHolder
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 10)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = page
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 2)
	pad.PaddingRight = UDim.new(0, 2)
	pad.Parent = page
	tiendaPages[tabName] = page
end

local function pageOf(tab)
	return tiendaPages[tab or "Robux"] or tiendaPages.Robux
end

local function tiendaMostrar(tab)
	tiendaTabActual = tab or "Robux"
	for name, page in pairs(tiendaPages) do
		if name == tiendaTabActual then
			page.Visible = true
			page.Parent = scrollTienda
		else
			page.Visible = false
			page.Parent = pageHolder
		end
	end
	for name, btn in pairs(tiendaTabBtns) do
		if name == tiendaTabActual then
			btn.BackgroundColor3 = TEMA.oro
			btn.TextColor3 = Color3.fromRGB(30, 30, 30)
		else
			btn.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
			btn.TextColor3 = TEMA.texto
		end
	end
	task.defer(function()
		if actualizarPreciosTienda then
			actualizarPreciosTienda()
		end
	end)
end

for _, tabName in ipairs(TAB_NAMES) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 88, 0, 32)
	b.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = TEMA.texto
	b.Text = tabName
	b.ZIndex = 41
	b.AutoButtonColor = true
	b.Parent = tabBar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	tiendaTabBtns[tabName] = b
	b.MouseButton1Click:Connect(function()
		tiendaMostrar(tabName)
	end)
end

local function crearSeccion(titulo, iconAsset, tab)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -8, 0, 34)
	f.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	f.ZIndex = 33
	f.Parent = pageOf(tab)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	goldStroke(f, 1)
	if iconAsset then
		iconImg(f, iconAsset, UDim2.new(0, 18, 0, 18), UDim2.new(0, 10, 0.5, -9))
	end
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -40, 1, 0)
	t.Position = UDim2.new(0, iconAsset and 34 or 12, 0, 0)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 14
	t.TextColor3 = TEMA.oro
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = titulo
	t.ZIndex = 34
	t.Parent = f
end

local function crearProductoRobux(iconAsset, nombre, desc, precioRobux, productId, badge, esGamePass, tab)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -8, 0, 88)
	f.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
	f.ZIndex = 33
	f.Parent = pageOf(tab or "Robux")
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	goldStroke(f, 1)
	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 48, 0, 48)
	iconBg.Position = UDim2.new(0, 12, 0.5, -24)
	iconBg.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
	iconBg.ZIndex = 34
	iconBg.Parent = f
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)
	iconImg(iconBg, iconAsset or ICONS.robux, UDim2.new(0, 30, 0, 30), UDim2.new(0.5, -15, 0.5, -15))
	if badge then
		local b = Instance.new("TextLabel")
		b.Size = UDim2.new(0, 54, 0, 18)
		b.Position = UDim2.new(0, 70, 0, 8)
		b.BackgroundColor3 = TEMA.rojo
		b.Font = Enum.Font.GothamBold
		b.TextSize = 11
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = badge
		b.ZIndex = 35
		b.Parent = f
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	end
	local nom = Instance.new("TextLabel")
	nom.Size = UDim2.new(0.48, 0, 0, 22)
	nom.Position = UDim2.new(0, 70, 0, badge and 28 or 14)
	nom.BackgroundTransparency = 1
	nom.Font = Enum.Font.GothamBold
	nom.TextSize = 15
	nom.TextColor3 = TEMA.texto
	nom.TextXAlignment = Enum.TextXAlignment.Left
	nom.Text = nombre
	nom.ZIndex = 34
	nom.Parent = f
	local des = Instance.new("TextLabel")
	des.Size = UDim2.new(0.48, 0, 0, 28)
	des.Position = UDim2.new(0, 70, 0, badge and 50 or 38)
	des.BackgroundTransparency = 1
	des.Font = Enum.Font.Gotham
	des.TextSize = 12
	des.TextColor3 = TEMA.textoSuave
	des.TextXAlignment = Enum.TextXAlignment.Left
	des.TextYAlignment = Enum.TextYAlignment.Top
	des.TextWrapped = true
	des.Text = desc or ""
	des.ZIndex = 34
	des.Parent = f
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 110, 0, 36)
	btn.Position = UDim2.new(1, -122, 0.5, -18)
	btn.BackgroundColor3 = TEMA.verde
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = "R$ " .. tostring(precioRobux or "?")
	btn.ZIndex = 35
	btn.Parent = f
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
	btn.MouseButton1Click:Connect(function()
		if not productId or productId == 0 then return end
		if esGamePass then
			MarketplaceService:PromptGamePassPurchase(player, productId)
		else
			MarketplaceService:PromptProductPurchase(player, productId)
		end
	end)
end

local botonesPrecio = {}

local function getStatsTienda()
	local ls = player:FindFirstChild("leaderstats")
	return {
		nivel = (ls and ls:FindFirstChild("Nivel") and ls.Nivel.Value) or 1,
		clicks = (ls and ls:FindFirstChild("ClicksPorClick") and ls.ClicksPorClick.Value) or 1,
		vel = (ls and ls:FindFirstChild("VelocidadAnclaje") and ls.VelocidadAnclaje.Value) or 0,
		walk = (ls and ls:FindFirstChild("VelocidadMovimiento") and ls.VelocidadMovimiento.Value) or 0,
		rebirths = (ls and ls:FindFirstChild("Rebirths") and ls.Rebirths.Value) or 0,
	}
end

local function calcularPrecioId(productId, stats)
	for _, a in ipairs(Config.ANTI_ANCLAJE or {}) do
		if a.id == productId then return Config.getPrecioAnti(a, stats.nivel, stats.rebirths) end
	end
	for _, pk in ipairs(Config.CLICKS_PACKS or {}) do
		if pk.id == productId then return Config.getPrecioClicks(pk, stats.nivel, stats.clicks, stats.rebirths) end
	end
	for _, v in ipairs(Config.VELOCIDAD_PACKS or {}) do
		if v.id == productId then return Config.getPrecioVelocidad(v, stats.nivel, stats.vel, stats.rebirths) end
	end
	for _, w in ipairs(Config.WALKSPEED_PACKS or {}) do
		if w.id == productId then return Config.getPrecioWalk(w, stats.nivel, stats.walk, stats.rebirths) end
	end
	return nil
end

local function puedeComprarMejora(productId, stats)
	local nivel = stats.nivel
	for _, pk in ipairs(Config.CLICKS_PACKS or {}) do
		if pk.id == productId then
			return stats.clicks + pk.cantidad <= Config.getMaxClicks(nivel), Config.getMaxClicks(nivel)
		end
	end
	for _, v in ipairs(Config.VELOCIDAD_PACKS or {}) do
		if v.id == productId then
			return stats.vel + v.niveles <= Config.getMaxVelAnclaje(nivel), Config.getMaxVelAnclaje(nivel)
		end
	end
	for _, w in ipairs(Config.WALKSPEED_PACKS or {}) do
		if w.id == productId then
			local maxW = math.min(Config.WALKSPEED_MAX_NIVELES or 99, Config.getMaxWalk(nivel))
			return stats.walk + w.niveles <= maxW, maxW
		end
	end
	return true, nil
end

function actualizarPreciosTienda()
	local stats = getStatsTienda()
	for _, entry in ipairs(botonesPrecio) do
		if entry.btn and entry.btn.Parent then
			local ok = puedeComprarMejora(entry.id, stats)
			local coste = calcularPrecioId(entry.id, stats)
			if not ok then
				entry.btn.Text = "Nivel insuficiente"
				entry.btn.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
				entry.btn:SetAttribute("Locked", true)
			elseif coste then
				entry.btn.Text = tostring(coste)
				entry.btn.BackgroundColor3 = TEMA.verde
				entry.btn:SetAttribute("Locked", false)
			end
		end
	end
end

local function crearProductoGrid(items, tab)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -8, 0, 130)
	row.BackgroundTransparency = 1
	row.ZIndex = 33
	row.Parent = pageOf(tab or "Poder")
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = row
	for _, item in ipairs(items) do
		local iconAsset, nombre, desc, productId = table.unpack(item)
		local card = Instance.new("Frame")
		card.Size = UDim2.new(0, 148, 1, 0)
		card.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
		card.ZIndex = 34
		card.Parent = row
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		goldStroke(card, 1)
		local iconBg = Instance.new("Frame")
		iconBg.Size = UDim2.new(0, 36, 0, 36)
		iconBg.Position = UDim2.new(0.5, -18, 0, 8)
		iconBg.BackgroundColor3 = Color3.fromRGB(20, 22, 32)
		iconBg.ZIndex = 35
		iconBg.Parent = card
		Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 8)
		iconImg(iconBg, iconAsset, UDim2.new(0, 24, 0, 24), UDim2.new(0.5, -12, 0.5, -12))
		local nm = Instance.new("TextLabel")
		nm.Size = UDim2.new(1, -8, 0, 18)
		nm.Position = UDim2.new(0, 4, 0, 48)
		nm.BackgroundTransparency = 1
		nm.Font = Enum.Font.GothamBold
		nm.TextSize = 12
		nm.TextColor3 = TEMA.texto
		nm.Text = nombre
		nm.ZIndex = 35
		nm.Parent = card
		local ds = Instance.new("TextLabel")
		ds.Size = UDim2.new(1, -8, 0, 16)
		ds.Position = UDim2.new(0, 4, 0, 66)
		ds.BackgroundTransparency = 1
		ds.Font = Enum.Font.Gotham
		ds.TextSize = 11
		ds.TextColor3 = TEMA.textoSuave
		ds.Text = desc
		ds.ZIndex = 35
		ds.Parent = card
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0.86, 0, 0, 26)
		btn.Position = UDim2.new(0.07, 0, 1, -32)
		btn.BackgroundColor3 = TEMA.verde
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 12
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Text = "..."
		btn.ZIndex = 36
		btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		table.insert(botonesPrecio, { btn = btn, id = productId })
		btn.MouseButton1Click:Connect(function()
			if btn:GetAttribute("Locked") then return end
			if ComprarMejora then ComprarMejora:FireServer(productId) end
			task.delay(0.3, actualizarPreciosTienda)
		end)
	end
end

do
	local r = Config.ROBUX or {}
	crearSeccion("ROBUX", ICONS.robux, "Robux")
	if r.ESCUDO_LEGENDARIO then
		crearProductoRobux(ICONS.escudo, r.ESCUDO_LEGENDARIO.nombre, r.ESCUDO_LEGENDARIO.descripcion, r.ESCUDO_LEGENDARIO.precioMostrado, r.ESCUDO_LEGENDARIO.productId, "TOP", nil, "Robux")
	end
	if r.CLICKS_50 then
		crearProductoRobux(ICONS.clicks, r.CLICKS_50.nombre, r.CLICKS_50.descripcion, r.CLICKS_50.precioMostrado, r.CLICKS_50.productId, "HOT", nil, "Robux")
	end
	if r.VELOCIDAD_ANCLAJE_15 then
		crearProductoRobux(ICONS.velAnclaje, r.VELOCIDAD_ANCLAJE_15.nombre, r.VELOCIDAD_ANCLAJE_15.descripcion, r.VELOCIDAD_ANCLAJE_15.precioMostrado, r.VELOCIDAD_ANCLAJE_15.productId, "PRO", nil, "Robux")
	end
	if r.VELOCIDAD_CORRER_10 then
		crearProductoRobux(ICONS.walk, r.VELOCIDAD_CORRER_10.nombre, r.VELOCIDAD_CORRER_10.descripcion, r.VELOCIDAD_CORRER_10.precioMostrado, r.VELOCIDAD_CORRER_10.productId, "RUN", nil, "Robux")
	end
	if Config.MONEDAS_ROBUX then
		for _, pack in ipairs(Config.MONEDAS_ROBUX) do
			crearProductoRobux(ICONS.monedasPack, pack.nombre or ("+" .. tostring(pack.monedas)), "+" .. tostring(pack.monedas) .. " monedas", pack.precioMostrado or 9, pack.productId, nil, nil, "Robux")
		end
	end
end

crearSeccion("CLICKS / CLICK", ICONS.clicks, "Poder")
crearProductoGrid({
	{ICONS.clicks, "+1 Click", "Básico", "click_1"},
	{ICONS.clicks, "+5 Clicks", "Intermedio", "click_5"},
	{ICONS.clicks, "+10 Clicks", "Potente", "click_10"},
}, "Poder")
crearSeccion("VELOCIDAD ANCLAJE", ICONS.velAnclaje, "Poder")
crearProductoGrid({
	{ICONS.velAnclaje, "-0.1s", "Más XP/s", "vel_1"},
	{ICONS.velAnclaje, "-0.5s", "Más XP/s", "vel_5"},
	{ICONS.velAnclaje, "-1.0s", "Más XP/s", "vel_10"},
}, "Poder")

crearSeccion("PROTECCIÓN", ICONS.escudo, "Escudos")
crearProductoGrid({
	{ICONS.escudo, "Escudo 1 min", "1 minuto", "anti_1min"},
	{ICONS.escudo, "Escudo 5 min", "5 minutos", "anti_5min"},
	{ICONS.escudo, "Escudo 15 min", "15 minutos", "anti_15min"},
}, "Escudos")

crearSeccion("VELOCIDAD MOVIMIENTO", ICONS.walk, "Movimiento")
crearProductoGrid({
	{ICONS.walk, "+1 Walk", "Correr", "walk_1"},
	{ICONS.walk, "+3 Walk", "Correr", "walk_3"},
	{ICONS.walk, "+5 Walk", "Correr", "walk_5"},
}, "Movimiento")

do
	local rebirthFrame = Instance.new("Frame")
	rebirthFrame.Size = UDim2.new(1, -8, 0, 90)
	rebirthFrame.BackgroundColor3 = Color3.fromRGB(40, 28, 55)
	rebirthFrame.ZIndex = 33
	rebirthFrame.Parent = pageOf("Rebirth")
	Instance.new("UICorner", rebirthFrame).CornerRadius = UDim.new(0, 12)
	goldStroke(rebirthFrame, 1)
	iconImg(rebirthFrame, ICONS.rebirths, UDim2.new(0, 28, 0, 28), UDim2.new(0, 14, 0.5, -14))
	local rt = Instance.new("TextLabel")
	rt.Size = UDim2.new(0.55, 0, 0, 40)
	rt.Position = UDim2.new(0, 52, 0, 12)
	rt.BackgroundTransparency = 1
	rt.Font = Enum.Font.GothamBold
	rt.TextSize = 13
	rt.TextColor3 = TEMA.texto
	rt.TextXAlignment = Enum.TextXAlignment.Left
	rt.TextWrapped = true
	rt.Text = "Reinicia nivel y mejoras.\nMulti XP y multi clicks permanentes."
	rt.ZIndex = 34
	rt.Parent = rebirthFrame
	local rbtn = Instance.new("TextButton")
	rbtn.Size = UDim2.new(0, 110, 0, 36)
	rbtn.Position = UDim2.new(1, -122, 0.5, -18)
	rbtn.BackgroundColor3 = TEMA.morado
	rbtn.Font = Enum.Font.GothamBlack
	rbtn.TextSize = 14
	rbtn.TextColor3 = Color3.new(1, 1, 1)
	rbtn.Text = "REBIRTH"
	rbtn.ZIndex = 35
	rbtn.Parent = rebirthFrame
	Instance.new("UICorner", rbtn).CornerRadius = UDim.new(0, 8)
	rbtn.MouseButton1Click:Connect(function()
		if HacerRebirth then HacerRebirth:FireServer() end
		task.delay(0.4, actualizarPreciosTienda)
	end)
end

-- Canvas automático por página (AutomaticCanvasSize en scrollTienda)
tiendaMostrar("Robux")

btnTienda.MouseButton1Click:Connect(function()
	local open = not menuTienda.Visible
	menuTienda.Visible = open
	menuRetos.Visible = false
	menuAbierto = false
	if dailyFrame then dailyFrame.Visible = false end
	if open then actualizarPreciosTienda() end
end)

-- =====================================================
-- MENÚ RETAR — lista de jugadores
-- =====================================================
menuAbierto = false
local retoCooldownHasta = 0
local function actualizarLista()
	for _, c in ipairs(scroll:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	local count = 0
	for _, pl in ipairs(Players:GetPlayers()) do
		if pl ~= player then
			count += 1
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -8, 0, 52)
			row.BackgroundColor3 = Color3.fromRGB(28, 30, 42)
			row.ZIndex = 33
			row.LayoutOrder = count
			row.Parent = scroll
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
			goldStroke(row, 1)
			iconImg(row, ICONS.retar, UDim2.new(0, 22, 0, 22), UDim2.new(0, 10, 0.5, -11))
			local nv = 1
			local ls = pl:FindFirstChild("leaderstats")
			if ls and ls:FindFirstChild("Nivel") then nv = ls.Nivel.Value end
			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(1, -100, 0, 22)
			name.Position = UDim2.new(0, 40, 0, 6)
			name.BackgroundTransparency = 1
			name.Font = Enum.Font.GothamBold
			name.TextSize = 14
			name.TextColor3 = TEMA.texto
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.TextTruncate = Enum.TextTruncate.AtEnd
			name.Text = pl.DisplayName or pl.Name
			name.ZIndex = 34
			name.Parent = row
			local sub = Instance.new("TextLabel")
			sub.Size = UDim2.new(1, -100, 0, 16)
			sub.Position = UDim2.new(0, 40, 0, 28)
			sub.BackgroundTransparency = 1
			sub.Font = Enum.Font.Gotham
			sub.TextSize = 12
			sub.TextColor3 = TEMA.muted or TEMA.textoSuave
			sub.TextXAlignment = Enum.TextXAlignment.Left
			sub.Text = "NV " .. tostring(nv)
			sub.ZIndex = 34
			sub.Parent = row
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(0, 52, 0, 32)
			btn.Position = UDim2.new(1, -60, 0.5, -16)
			btn.BackgroundColor3 = TEMA.rojo
			btn.Font = Enum.Font.GothamBlack
			btn.TextSize = 12
			btn.TextColor3 = Color3.new(1, 1, 1)
			btn.Text = "Retar"
			btn.ZIndex = 35
			btn.Parent = row
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
			local targetId = pl.UserId
			btn.MouseButton1Click:Connect(function()
				if tick() < retoCooldownHasta then return end
				retoCooldownHasta = tick() + 1.5
				if SolicitarDueloDirecto then
					SolicitarDueloDirecto:FireServer(targetId)
				end
				btn.Text = "..."
				btn.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
				task.delay(1.5, function()
					if btn and btn.Parent then
						btn.Text = "Retar"
						btn.BackgroundColor3 = TEMA.rojo
					end
				end)
			end)
		end
	end
	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -16, 0, 60)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.TextColor3 = TEMA.muted or TEMA.textoSuave
		empty.Text = "No hay jugadores.\nReta bots en el mapa."
		empty.TextWrapped = true
		empty.ZIndex = 34
		empty.Parent = scroll
	end
	local lay = scroll:FindFirstChildOfClass("UIListLayout")
	if lay then
		scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 12)
	end
end

btnRetar.MouseButton1Click:Connect(function()
	menuAbierto = not menuAbierto
	menuRetos.Visible = menuAbierto
	menuTienda.Visible = false
	if dailyFrame then dailyFrame.Visible = false end
	if menuAbierto then actualizarLista() end
end)

-- =====================================================
-- NOTIFICACIONES SERVIDOR
-- =====================================================
if NotificarCliente then
	NotificarCliente.OnClientEvent:Connect(function(data)
		if data.tipo == "anim_anclaje" then
			if data.activo then
				playAnclajeAnimLocal(data.animId or (Config and Config.ANIMACION_ANCLAJE_ID))
			else
				stopAnclajeAnimLocal()
				local char = player.Character
				if char then
					local animate = char:FindFirstChild("Animate")
					if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
						animate.Enabled = true
					end
				end
			end
		elseif data.tipo == "anclado" then
			btnDesanclar.Visible = true
			ancladoPill.Visible = true
			ancladoLbl.Text = data.mensaje or "Anclado · +XP/s"
			playAnclajeAnimLocal(Config and Config.ANIMACION_ANCLAJE_ID)
			if notifAncladoCard and notifAncladoCard.Parent then
				notifAncladoCard:Destroy()
			end
			notifAncladoCard = crearNotificacion(
				"Anclado",
				data.mensaje or "Estás anclado · ganas XP",
				{
					{
						texto = "Desanclarse",
						color = Color3.fromRGB(180, 80, 40),
						callback = function()
							if DesanclarJugador then DesanclarJugador:FireServer() end
						end,
					},
				},
				true,
				ICONS.anclar
			)
		elseif data.tipo == "desanclado" or data.tipo == "expulsado" then
			btnDesanclar.Visible = false
			ancladoPill.Visible = false
			if notifAncladoCard and notifAncladoCard.Parent then
				notifAncladoCard:Destroy()
				notifAncladoCard = nil
			end
			stopAnclajeAnimLocal()
			local char = player.Character
			if char then
				local animate = char:FindFirstChild("Animate")
				if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
					animate.Enabled = true
				end
			end
			-- Una sola notificación (antes salían 2 por Stick + desanclar)
			local msg = tostring(data.mensaje or "")
			if msg == "" or msg == "Libre" then
				msg = "Te has desanclado"
			end
			crearNotificacion("Desanclado", msg, nil, false, ICONS.desanclar)
		elseif data.tipo == "hide_own_prompt" then
			if player.Character then
				for _, d in ipairs(player.Character:GetDescendants()) do
					if d:IsA("ProximityPrompt") and d.Name == "PromptAnclar" then
						d.Enabled = false
					end
				end
			end
		elseif data.tipo == "te_anclaron" then
			-- UI de expulsión vía ExpulsionUpdate
		elseif data.tipo == "error" then
			-- menos ruido: solo avisos accionables / bloqueantes
			local msg = tostring(data.mensaje or "")
			local soft = {
				"nivel insuficiente", "no tienes", "cooldown", "ya reclamaste",
				"no disponible", "espera", "proteccion", "protección",
			}
			local lower = string.lower(msg)
			local isSoft = false
			for _, k in ipairs(soft) do
				if string.find(lower, k, 1, true) then isSoft = true break end
			end
			if msg ~= "" and not isSoft then
				crearNotificacion("Aviso", msg)
			end
			-- soft: silencioso (el botón de la tienda ya muestra estado)
		elseif data.tipo == "exito" then
			crearNotificacion("Listo", data.mensaje or "")
		elseif data.tipo == "alguien_desanclado" then
			-- silencioso
		elseif data.tipo == "duelo_expirado" then
			if dueloNotifCard and dueloNotifCard.Parent then
				dueloNotifCard:Destroy()
				dueloNotifCard = nil
			end
		end
	end)
end

-- =====================================================
-- DUELOS
-- =====================================================
if ResponderDuelo then
	ResponderDuelo.OnClientEvent:Connect(function(retadorUserId, retadorName)
		if dueloNotifCard and dueloNotifCard.Parent then
			dueloNotifCard:Destroy()
		end
		dueloNotifCard = crearNotificacion("Reto de Duelo", (retadorName or "?") .. " te ha retado!", {
			{
				texto = "Aceptar",
				color = TEMA.verde,
				callback = function()
					if ResponderDuelo then ResponderDuelo:FireServer(true, retadorUserId) end
				end
			},
			{
				texto = "Rechazar",
				color = TEMA.rojo,
				callback = function()
					if ResponderDuelo then ResponderDuelo:FireServer(false, retadorUserId) end
				end
			}
		}, true, ICONS.retar)
	end)
end

-- =====================================================
-- MINIJUEGO
-- =====================================================
local overlay = Instance.new("Frame")
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
overlay.BackgroundTransparency = 0.4
overlay.Visible = false
overlay.ZIndex = 90
overlay.Parent = screenGui

local duelCard = Instance.new("Frame")
duelCard.Size = UDim2.new(0, 340, 0, 220)
duelCard.Position = UDim2.new(0.5, -170, 0.5, -110)
duelCard.BackgroundColor3 = TEMA.fondoOscuro
duelCard.ZIndex = 91
duelCard.Parent = overlay
Instance.new("UICorner", duelCard).CornerRadius = UDim.new(0, 16)
goldStroke(duelCard, 2)

local centroTexto = Instance.new("TextLabel")
centroTexto.Size = UDim2.new(1, -24, 0, 90)
centroTexto.Position = UDim2.new(0, 12, 0, 36)
centroTexto.BackgroundTransparency = 1
centroTexto.Font = Enum.Font.GothamBlack
centroTexto.TextSize = 56
centroTexto.TextColor3 = TEMA.oro
centroTexto.ZIndex = 92
centroTexto.Parent = duelCard

local subTexto = Instance.new("TextLabel")
subTexto.Size = UDim2.new(1, -24, 0, 40)
subTexto.Position = UDim2.new(0, 12, 0, 140)
subTexto.BackgroundTransparency = 1
subTexto.Font = Enum.Font.GothamBold
subTexto.TextSize = 16
subTexto.TextColor3 = TEMA.textoSuave or TEMA.texto
subTexto.TextWrapped = true
subTexto.ZIndex = 92
subTexto.Parent = duelCard

local contandoClicks = false
local clicksActuales = 0
local conexionInput = nil

local function iniciarConteo(esBot, nivelBot, clicksMinimos)
	overlay.Visible = true
	centroTexto.TextColor3 = Color3.fromRGB(255, 160, 40)
	subTexto.Text = esBot and ("Bot Nv." .. nivelBot .. " • " .. clicksMinimos .. " clics") or "Duelo PvP"

	for i = 3, 1, -1 do
		centroTexto.Text = tostring(i)
		task.wait(1)
	end
	centroTexto.TextColor3 = Color3.fromRGB(60, 255, 100)
	centroTexto.Text = "¡YA!"
	task.wait(0.6)

	clicksActuales = 0
	contandoClicks = true
	centroTexto.Text = "0"
	subTexto.Text = "¡Haz clic lo más rápido posible!"

	if conexionInput then conexionInput:Disconnect() end
	conexionInput = UserInputService.InputBegan:Connect(function(input)
		if not contandoClicks then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			clicksActuales += 1
			centroTexto.Text = tostring(clicksActuales)
		end
	end)

	task.wait(5)
	contandoClicks = false
	if conexionInput then conexionInput:Disconnect() end
	if EnviarClicks then EnviarClicks:FireServer(clicksActuales) end
	centroTexto.Text = "Enviando..."
	subTexto.Text = ""
end

if IniciarMinijuego then
	IniciarMinijuego.OnClientEvent:Connect(iniciarConteo)
end

if MostrarResultados then
	MostrarResultados.OnClientEvent:Connect(function(data)
		overlay.Visible = true
		local r = data and data.resultado or ""
		if r == "Victoria" then
			centroTexto.TextColor3 = TEMA.verde
			centroTexto.Text = "¡Victoria!"
		elseif r == "Empate" then
			centroTexto.TextColor3 = TEMA.oro
			centroTexto.Text = "Empate"
		else
			centroTexto.TextColor3 = TEMA.rojo
			centroTexto.Text = "Derrota"
		end
		local extra = (data.recompensa and data.recompensa > 0) and ("\n+" .. data.recompensa .. " 💰") or ""
		subTexto.Text = string.format("Tú: %d  •  Rival: %d%s", data.misClicks, data.oponenteClicks, extra)
		task.wait(4)
		overlay.Visible = false
	end)
end

-- Ocultar SOLO tu propio prompt de anclaje (los de otros jugadores sí se ven)
local function ocultarMiPrompt(character)
	task.spawn(function()
		if not character then return end
		local hrp = character:WaitForChild("HumanoidRootPart", 10)
		if not hrp then return end
		local function disablePrompt(p)
			if p and (p.Name == "PromptAnclar") and p:IsA("ProximityPrompt") then
				p:SetAttribute("TrikiOwned", true)
				p.Enabled = false
			end
		end
		for _, d in ipairs(character:GetDescendants()) do
			disablePrompt(d)
		end
		character.DescendantAdded:Connect(disablePrompt)
	end)
end

if player.Character then ocultarMiPrompt(player.Character) end
player.CharacterAdded:Connect(ocultarMiPrompt)

-- ProximityPrompt custom (Trike Arcade) — activación fiable
local ProximityPromptService = game:GetService("ProximityPromptService")
local ContextActionService = game:GetService("ContextActionService")

local shownPrompts = {} -- [prompt] = true
local promptUI = {} -- [prompt] = { frame = BillboardGui }
local activePrompt = nil
local firing = {} -- debounce por prompt

local function estiloPrompt(p)
	if not p or not p:IsA("ProximityPrompt") then return end
	if p:GetAttribute("TrikiOwned") then
		p.Enabled = false
		return
	end
	p.Style = Enum.ProximityPromptStyle.Custom
	p.RequiresLineOfSight = false
	p.ClickablePrompt = true
	p.Enabled = true
	if (p.MaxActivationDistance or 0) < 8 then
		p.MaxActivationDistance = 14
	end
	-- HoldDuration 0 a veces no dispara Triggered; mínimo pequeño ayuda
	if (p.HoldDuration or 0) <= 0 then
		p.HoldDuration = 0.05
	end
	if not p:GetAttribute("PromptKind") then
		if p.Name == "PromptAnclar" then
			p:SetAttribute("PromptKind", "anclar")
		elseif string.find(string.lower(p.Name), "bot") or p.Name == "PromptBot" then
			p:SetAttribute("PromptKind", "bot")
		end
	end
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("ProximityPrompt") then
		task.defer(estiloPrompt, d)
	end
end)
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") then
		estiloPrompt(d)
	end
end

local function destroyPromptUI(prompt)
	local ui = promptUI[prompt]
	if ui then
		if ui.frame then
			ui.frame:Destroy()
		end
		promptUI[prompt] = nil
	end
end

local function getCharPos()
	local char = player.Character
	if not char then return nil end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position or nil
end

local function pickNearestShown()
	local pos = getCharPos()
	local best, bestDist = nil, math.huge
	for prompt in pairs(shownPrompts) do
		if prompt.Parent and prompt.Enabled then
			local part = prompt.Parent
			if not part:IsA("BasePart") then
				local model = prompt:FindFirstAncestorOfClass("Model")
				part = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
			end
			if part and part:IsA("BasePart") then
				local d = pos and (part.Position - pos).Magnitude or 0
				if d < bestDist then
					bestDist = d
					best = prompt
				end
			elseif not best then
				best = prompt
			end
		end
	end
	return best
end

local function firePrompt(prompt)
	if not prompt or not prompt.Parent or not prompt.Enabled then return end
	if prompt:GetAttribute("TrikiOwned") then return end
	if firing[prompt] then return end
	firing[prompt] = true
	estiloPrompt(prompt)
	local hold = math.max(tonumber(prompt.HoldDuration) or 0.05, 0.08)
	local okBegin = pcall(function()
		prompt:InputHoldBegin()
	end)
	task.delay(hold, function()
		pcall(function()
			if prompt.Parent then
				prompt:InputHoldEnd()
			end
		end)
		task.delay(0.15, function()
			firing[prompt] = nil
		end)
	end)
	if not okBegin then
		firing[prompt] = nil
	end
end

local function showPromptUI(prompt)
	if promptUI[prompt] then return end
	if not prompt.Parent or not prompt.Enabled then return end
	if prompt:GetAttribute("TrikiOwned") then return end

	local kind = prompt:GetAttribute("PromptKind") or "generic"
	local isAnclar = kind == "anclar"
	local isBot = kind == "bot"
	local iconAsset = isAnclar and ICONS.anclar or (isBot and ICONS.bot or ICONS.retar)
	local titleText = isAnclar and "Triki Traka" or (isBot and "Retar" or (prompt.ActionText or "Usar"))
	local subText = isAnclar and "por detrás" or (isBot and ("Nivel " .. tostring(prompt:GetAttribute("NivelBot") or "?")) or "")

	local adornee = prompt.Parent
	if not (adornee and adornee:IsA("BasePart")) then
		local model = prompt:FindFirstAncestorOfClass("Model")
		adornee = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
	end
	if not adornee then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TrikiPromptUI"
	billboard.Size = UDim2.new(0, 180, 0, 58)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 32
	billboard.Adornee = adornee
	billboard.Active = true
	billboard.Parent = playerGui

	local card = Instance.new("TextButton")
	card.Name = "Card"
	card.Size = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3 = TEMA.fondoOscuro
	card.Text = ""
	card.AutoButtonColor = true
	card.Active = true
	card.Selectable = true
	card.ZIndex = 10
	card.Parent = billboard
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke")
	st.Color = isAnclar and TEMA.oro or TEMA.rojo
	st.Thickness = 2
	st.Parent = card

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 34, 0, 34)
	iconBg.Position = UDim2.new(0, 8, 0.5, -17)
	iconBg.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	iconBg.Active = false
	iconBg.ZIndex = 11
	iconBg.Parent = card
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)
	local ic = iconImg(iconBg, iconAsset, UDim2.new(0, 22, 0, 22), UDim2.new(0.5, -11, 0.5, -11))
	ic.ZIndex = 12

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -90, 0, 20)
	title.Position = UDim2.new(0, 48, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextColor3 = TEMA.texto
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = titleText
	title.Active = false
	title.ZIndex = 11
	title.Parent = card

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -90, 0, 16)
	sub.Position = UDim2.new(0, 48, 0, 30)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextColor3 = TEMA.muted or TEMA.textoSuave
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = subText
	sub.Active = false
	sub.ZIndex = 11
	sub.Parent = card

	local key = Instance.new("Frame")
	key.Size = UDim2.new(0, 22, 0, 22)
	key.Position = UDim2.new(1, -30, 0.5, -11)
	key.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
	key.Active = false
	key.ZIndex = 11
	key.Parent = card
	Instance.new("UICorner", key).CornerRadius = UDim.new(0, 6)
	local keyLbl = Instance.new("TextLabel")
	keyLbl.Size = UDim2.new(1, 0, 1, 0)
	keyLbl.BackgroundTransparency = 1
	keyLbl.Font = Enum.Font.GothamBlack
	keyLbl.TextSize = 12
	keyLbl.TextColor3 = TEMA.texto
	keyLbl.Text = "E"
	keyLbl.ZIndex = 12
	keyLbl.Parent = key

	local function onActivate()
		firePrompt(prompt)
	end
	card.MouseButton1Click:Connect(onActivate)
	card.Activated:Connect(onActivate)
	card.TouchTap:Connect(onActivate)

	promptUI[prompt] = { frame = billboard }
	activePrompt = prompt
end

ProximityPromptService.PromptShown:Connect(function(prompt, _inputType)
	if prompt:GetAttribute("TrikiOwned") then return end
	estiloPrompt(prompt)
	shownPrompts[prompt] = true
	if prompt.Style == Enum.ProximityPromptStyle.Custom and prompt.Enabled then
		showPromptUI(prompt)
	end
	activePrompt = pickNearestShown() or prompt
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	shownPrompts[prompt] = nil
	destroyPromptUI(prompt)
	activePrompt = pickNearestShown()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	shownPrompts[prompt] = nil
	destroyPromptUI(prompt)
	activePrompt = pickNearestShown()
	firing[prompt] = nil
end)

-- E / gamepad con prioridad alta (no depende solo de InputBegan)
local ACTION = "TrikiPromptActivate"
ContextActionService:BindActionAtPriority(ACTION, function(_name, state, _input)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if UserInputService:GetFocusedTextBox() then
		return Enum.ContextActionResult.Pass
	end
	local p = pickNearestShown() or activePrompt
	if p and p.Parent and p.Enabled then
		firePrompt(p)
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, 3500, Enum.KeyCode.E, Enum.KeyCode.ButtonX)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed and UserInputService:GetFocusedTextBox() then return end
	if input.KeyCode ~= Enum.KeyCode.E and input.KeyCode ~= Enum.KeyCode.ButtonX then return end
	local p = pickNearestShown() or activePrompt
	if p and p.Parent and p.Enabled then
		firePrompt(p)
	end
end)

print("[AuraUI] Cliente cargado completamente")


-- =====================================================
-- UI EXPULSIÓN COMPACTA + BATALLA A PANTALLA COMPLETA
-- =====================================================
local expFrame = Instance.new("Frame")
expFrame.Size = UDim2.new(0, 340, 0, 120)
expFrame.BackgroundColor3 = TEMA.amarillo
expFrame.Visible = false
expFrame.ZIndex = 41
expFrame.LayoutOrder = -10 -- arriba del stack de notifs
expFrame.Parent = notifContainer
Instance.new("UICorner", expFrame).CornerRadius = UDim.new(0, 14)
local expStroke = Instance.new("UIStroke")
expStroke.Color = TEMA.borde
expStroke.Thickness = 3
expStroke.Parent = expFrame

local expInner = Instance.new("Frame")
expInner.Size = UDim2.new(1, -8, 1, -8)
expInner.Position = UDim2.new(0, 4, 0, 4)
expInner.BackgroundColor3 = TEMA.fondoOscuro
expInner.Parent = expFrame
Instance.new("UICorner", expInner).CornerRadius = UDim.new(0, 10)

local expTitle = Instance.new("TextLabel")
expTitle.Size = UDim2.new(1, -12, 0, 20)
expTitle.Position = UDim2.new(0, 6, 0, 4)
expTitle.BackgroundTransparency = 1
expTitle.Font = Enum.Font.GothamBlack
expTitle.TextSize = 14
expTitle.TextColor3 = TEMA.naranja
expTitle.TextXAlignment = Enum.TextXAlignment.Left
expTitle.Text = "⚡ Te han anclado"
expTitle.Parent = expInner

local expProbLabel = Instance.new("TextLabel")
expProbLabel.Size = UDim2.new(1, -12, 0, 16)
expProbLabel.Position = UDim2.new(0, 6, 0, 24)
expProbLabel.BackgroundTransparency = 1
expProbLabel.Font = Enum.Font.GothamBold
expProbLabel.TextSize = 12
expProbLabel.TextColor3 = TEMA.texto
expProbLabel.TextXAlignment = Enum.TextXAlignment.Left
expProbLabel.Text = "Prob: 0%"
expProbLabel.Parent = expInner

local expBarBg = Instance.new("Frame")
expBarBg.Size = UDim2.new(1, -12, 0, 10)
expBarBg.Position = UDim2.new(0, 6, 0, 42)
expBarBg.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
expBarBg.Parent = expInner
Instance.new("UICorner", expBarBg).CornerRadius = UDim.new(0, 5)

local expBarFill = Instance.new("Frame")
expBarFill.Size = UDim2.new(0, 0, 1, 0)
expBarFill.BackgroundColor3 = Color3.fromRGB(255, 90, 50)
expBarFill.Parent = expBarBg
Instance.new("UICorner", expBarFill).CornerRadius = UDim.new(0, 5)

local expSub = Instance.new("TextLabel")
expSub.Size = UDim2.new(1, -12, 0, 16)
expSub.Position = UDim2.new(0, 6, 0, 54)
expSub.BackgroundTransparency = 1
expSub.Font = Enum.Font.Gotham
expSub.TextSize = 11
expSub.TextColor3 = TEMA.textoSuave
expSub.TextXAlignment = Enum.TextXAlignment.Left
expSub.Text = ""
expSub.Parent = expInner

local expDineroBox = Instance.new("TextBox")
expDineroBox.Size = UDim2.new(0, 100, 0, 28)
expDineroBox.Position = UDim2.new(0, 6, 0, 78)
expDineroBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
expDineroBox.Font = Enum.Font.GothamBold
expDineroBox.TextSize = 14
expDineroBox.TextColor3 = TEMA.texto
expDineroBox.PlaceholderText = "💰 dinero"
expDineroBox.Text = tostring((Config.EXPULSION and Config.EXPULSION.DINERO_MINIMO) or 10)
expDineroBox.ClearTextOnFocus = false
expDineroBox.Parent = expInner
Instance.new("UICorner", expDineroBox).CornerRadius = UDim.new(0, 6)

local expBtnIntentar = Instance.new("TextButton")
expBtnIntentar.Size = UDim2.new(0, 140, 0, 28)
expBtnIntentar.Position = UDim2.new(0, 114, 0, 78)
expBtnIntentar.BackgroundColor3 = TEMA.rojo
expBtnIntentar.Font = Enum.Font.GothamBlack
expBtnIntentar.TextSize = 12
expBtnIntentar.TextColor3 = Color3.new(1, 1, 1)
expBtnIntentar.Text = "Intentar expulsar"
expBtnIntentar.Parent = expInner
Instance.new("UICorner", expBtnIntentar).CornerRadius = UDim.new(0, 6)

-- Overlay a pantalla completa para defensa (igual que duelo)
local defOverlay = Instance.new("TextButton")
defOverlay.Size = UDim2.new(1, 0, 1, 0)
defOverlay.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
defOverlay.BackgroundTransparency = 0.35
defOverlay.Text = ""
defOverlay.AutoButtonColor = false
defOverlay.Visible = false
defOverlay.ZIndex = 100
defOverlay.Active = true
defOverlay.Parent = screenGui

local defCentro = Instance.new("TextLabel")
defCentro.Size = UDim2.new(1, 0, 0, 120)
defCentro.Position = UDim2.new(0, 0, 0.35, 0)
defCentro.BackgroundTransparency = 1
defCentro.Font = Enum.Font.GothamBlack
defCentro.TextSize = 72
defCentro.TextColor3 = Color3.fromRGB(80, 255, 120)
defCentro.Text = "0"
defCentro.ZIndex = 51
defCentro.Parent = defOverlay

local defSub = Instance.new("TextLabel")
defSub.Size = UDim2.new(1, 0, 0, 40)
defSub.Position = UDim2.new(0, 0, 0.35, 120)
defSub.BackgroundTransparency = 1
defSub.Font = Enum.Font.GothamBold
defSub.TextSize = 22
defSub.TextColor3 = Color3.new(1, 1, 1)
defSub.Text = "¡CLICK EN CUALQUIER SITIO!"
defSub.ZIndex = 51
defSub.Parent = defOverlay

local defTimer = Instance.new("TextLabel")
defTimer.Size = UDim2.new(1, 0, 0, 36)
defTimer.Position = UDim2.new(0, 0, 0.35, 160)
defTimer.BackgroundTransparency = 1
defTimer.Font = Enum.Font.GothamBlack
defTimer.TextSize = 28
defTimer.TextColor3 = TEMA.naranja
defTimer.Text = "3.0s"
defTimer.ZIndex = 51
defTimer.Parent = defOverlay

local defProb = Instance.new("TextLabel")
defProb.Size = UDim2.new(1, 0, 0, 28)
defProb.Position = UDim2.new(0, 0, 0.35, 200)
defProb.BackgroundTransparency = 1
defProb.Font = Enum.Font.GothamBold
defProb.TextSize = 18
defProb.TextColor3 = Color3.fromRGB(255, 200, 100)
defProb.Text = ""
defProb.ZIndex = 51
defProb.Parent = defOverlay

local expFase = "preparacion"
local defensaActiva = false
local defensaClicksLocal = 0
local defensaInputConn = nil
local defensaTimerConn = nil
local defensaFinLocal = 0

local function enviarDinero()
	local n = tonumber(expDineroBox.Text)
	if n and ExpulsionAccion then
		ExpulsionAccion:FireServer("set_dinero", n)
	end
end

expDineroBox.FocusLost:Connect(enviarDinero)
expDineroBox:GetPropertyChangedSignal("Text"):Connect(function()
	task.defer(enviarDinero)
end)

expBtnIntentar.MouseButton1Click:Connect(function()
	enviarDinero()
	if ExpulsionAccion then ExpulsionAccion:FireServer("intentar") end
end)

local function stopDefensaInput()
	defensaActiva = false
	if defensaInputConn then
		defensaInputConn:Disconnect()
		defensaInputConn = nil
	end
	if defensaTimerConn then
		defensaTimerConn:Disconnect()
		defensaTimerConn = nil
	end
	defOverlay.Visible = false
end

local function registrarClickDefensa()
	if not defensaActiva then return end
	if tick() > defensaFinLocal then return end
	defensaClicksLocal += 1
	defCentro.Text = tostring(defensaClicksLocal)
	if ExpulsionDefensa then
		ExpulsionDefensa:FireServer()
	end
end

local function startDefensaInput(_duracionIgnorado)
	stopDefensaInput()
	defensaActiva = true
	defensaClicksLocal = 0
	-- Siempre la duración completa de Config (no el tiempoRestante retrasado de red)
	local dur = (Config.EXPULSION and Config.EXPULSION.DEFENSA_DURACION) or 3
	defensaFinLocal = tick() + dur
	defOverlay.Visible = true
	defCentro.Text = "0"
	defSub.Text = "¡CLICK EN CUALQUIER SITIO PARA DEFENDERTE!"

	-- Clicks a pantalla completa (NO filtrar gameProcessed)
	defensaInputConn = UserInputService.InputBegan:Connect(function(input, _gp)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			registrarClickDefensa()
		end
	end)

	defOverlay.MouseButton1Click:Connect(registrarClickDefensa)
	defOverlay.MouseButton1Down:Connect(registrarClickDefensa)

	defensaTimerConn = RunService.RenderStepped:Connect(function()
		if not defensaActiva then return end
		local resto = math.max(0, defensaFinLocal - tick())
		defTimer.Text = string.format("%.1fs", resto)
		if resto <= 0 then
			stopDefensaInput()
		end
	end)
end

if not RunService then
	-- safety
end

if ExpulsionUpdate then
	ExpulsionUpdate.OnClientEvent:Connect(function(data)
		if not data then return end
		if data.activo == false then
			expFrame.Visible = false
			stopDefensaInput()
			if data.resultado == "exito" then
				crearNotificacion("Expulsión", "¡Resultado: EXPULSADO!")
			elseif data.resultado == "fallo" then
				crearNotificacion("Expulsión", "¡Te salvaste de la expulsión!")
			end
			return
		end

		expFase = data.fase or "preparacion"
		local pct = data.prob and (math.floor(data.prob * 1000) / 10) or 0
		expProbLabel.Text = string.format("Prob: %.1f%%", pct)
		if data.prob and data.probMax then
			expBarFill.Size = UDim2.new(math.clamp(data.prob / data.probMax, 0, 1), 0, 1, 0)
		end

		if data.rol == "objetivo" then
			expFrame.Visible = true
			if expFase == "preparacion" then
				stopDefensaInput()
				expTitle.Text = "⚡ " .. (data.quien or "?") .. " anclado"
				expDineroBox.Visible = true
				expBtnIntentar.Visible = true
				expFrame.Size = UDim2.new(0, 340, 0, 120)
				local full = data.dineroParaFull or "?"
				expSub.Text = string.format("~%s 💰 = prob máx  |  defensa -%.0f%%", tostring(full), (data.reduccionMax or 0.35) * 100)
			elseif expFase == "batalla" then
				expTitle.Text = string.format("⚔️ BATALLA %.1fs", data.tiempoRestante or 0)
				expDineroBox.Visible = false
				expBtnIntentar.Visible = false
				expFrame.Size = UDim2.new(0, 340, 0, 90)
				expSub.Text = string.format("Defensa rival: -%.1f%% (%d clicks)", (data.reduccion or 0) * 100, data.defensaClicks or 0)
			end
		elseif data.rol == "anclado" then
			if expFase == "batalla" then
				expFrame.Visible = false -- usa overlay a pantalla completa
				if not defensaActiva then
					startDefensaInput() -- duración completa desde Config
				end
				defProb.Text = string.format("Prob: %.1f%%  |  Reducción: -%.1f%% / -%.0f%%",
					pct, (data.reduccion or 0) * 100, (data.reduccionMax or 0.35) * 100)
				-- Si el servidor manda clicks, no pisar el contador local si es mayor
				if data.defensaClicks and data.defensaClicks > defensaClicksLocal then
					defensaClicksLocal = data.defensaClicks
					defCentro.Text = tostring(defensaClicksLocal)
				end
				if data.tiempoRestante and data.tiempoRestante > 0 then
					defensaFinLocal = tick() + data.tiempoRestante
				end
			else
				expFrame.Visible = false
				stopDefensaInput()
			end
		end
	end)
end

-- =====================================================
-- DAILY REWARDS UI (Trike Arcade + iconos)
-- =====================================================
dailyFrame = nil
do
	local outer, inner = darkCard(screenGui, UDim2.new(0, 360, 0, 260), UDim2.new(0.5, -180, 0.5, -130))
	outer.Name = "DailyFrame"
	outer.Visible = false
	outer.ZIndex = 45
	dailyFrame = outer
	inner.ZIndex = 46

	-- header icon
	local headIcon = Instance.new("ImageLabel")
	headIcon.BackgroundTransparency = 1
	headIcon.Image = normalizeAsset(ICONS.daily)
	headIcon.Size = UDim2.new(0, 32, 0, 32)
	headIcon.Position = UDim2.new(0, 14, 0, 12)
	headIcon.ScaleType = Enum.ScaleType.Fit
	headIcon.Active = false
	headIcon.ZIndex = 48
	headIcon.Parent = inner

	local dTitle = Instance.new("TextLabel")
	dTitle.Size = UDim2.new(1, -100, 0, 28)
	dTitle.Position = UDim2.new(0, 54, 0, 14)
	dTitle.BackgroundTransparency = 1
	dTitle.Font = Enum.Font.GothamBlack
	dTitle.TextSize = 18
	dTitle.TextColor3 = TEMA.texto
	dTitle.TextXAlignment = Enum.TextXAlignment.Left
	dTitle.Text = "RACHA DIARIA"
	dTitle.ZIndex = 48
	dTitle.Parent = inner

	local dClose = Instance.new("TextButton")
	dClose.Name = "Cerrar"
	dClose.Size = UDim2.new(0, 30, 0, 30)
	dClose.Position = UDim2.new(1, -40, 0, 12)
	dClose.BackgroundColor3 = TEMA.rojo
	dClose.Text = "X"
	dClose.Font = Enum.Font.GothamBlack
	dClose.TextSize = 16
	dClose.TextColor3 = Color3.new(1, 1, 1)
	dClose.AutoButtonColor = true
	dClose.Active = true
	dClose.Selectable = true
	dClose.ZIndex = 200
	dClose.Parent = inner
	Instance.new("UICorner", dClose).CornerRadius = UDim.new(0, 8)
	dClose.MouseButton1Click:Connect(function()
		outer.Visible = false
		if dailyFrame then dailyFrame.Visible = false end
	end)

	local streakRow = Instance.new("Frame")
	streakRow.Name = "StreakRow"
	streakRow.Size = UDim2.new(1, -24, 0, 44)
	streakRow.Position = UDim2.new(0, 12, 0, 56)
	streakRow.BackgroundTransparency = 1
	streakRow.ZIndex = 47
	streakRow.Parent = inner
	local streakLayout = Instance.new("UIListLayout")
	streakLayout.FillDirection = Enum.FillDirection.Horizontal
	streakLayout.Padding = UDim.new(0, 6)
	streakLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	streakLayout.Parent = streakRow

	local dayDots = {}
	for i = 1, 7 do
		local d = Instance.new("Frame")
		d.Size = UDim2.new(0, 36, 0, 36)
		d.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
		d.ZIndex = 48
		d.Parent = streakRow
		Instance.new("UICorner", d).CornerRadius = UDim.new(0, 10)
		goldStroke(d, 1)

		local ic = Instance.new("ImageLabel")
		ic.Name = "DayIcon"
		ic.BackgroundTransparency = 1
		ic.Size = UDim2.new(0, 22, 0, 22)
		ic.Position = UDim2.new(0.5, -11, 0.5, -11)
		ic.ScaleType = Enum.ScaleType.Fit
		ic.Image = normalizeAsset(ICONS.candado)
		ic.ImageColor3 = Color3.new(1, 1, 1)
		ic.Active = false
		ic.ZIndex = 49
		ic.Parent = d

		dayDots[i] = { frame = d, icon = ic }
	end

	local dInfo = Instance.new("TextLabel")
	dInfo.Name = "DailyInfo"
	dInfo.Size = UDim2.new(1, -24, 0, 48)
	dInfo.Position = UDim2.new(0, 12, 0, 110)
	dInfo.BackgroundTransparency = 1
	dInfo.Font = Enum.Font.GothamBold
	dInfo.TextSize = 14
	dInfo.TextColor3 = TEMA.texto
	dInfo.TextWrapped = true
	dInfo.Text = "Cargando..."
	dInfo.ZIndex = 48
	dInfo.Parent = inner

	local dClaim = Instance.new("TextButton")
	dClaim.Name = "DailyClaim"
	dClaim.Size = UDim2.new(0, 170, 0, 42)
	dClaim.Position = UDim2.new(0.5, -85, 1, -58)
	dClaim.BackgroundColor3 = TEMA.verde
	dClaim.Font = Enum.Font.GothamBlack
	dClaim.TextSize = 15
	dClaim.TextColor3 = Color3.new(1, 1, 1)
	dClaim.Text = "RECLAMAR"
	dClaim.ZIndex = 50
	dClaim.Parent = inner
	Instance.new("UICorner", dClaim).CornerRadius = UDim.new(0, 10)

	local dailyCanClaim = false
	dClaim.MouseButton1Click:Connect(function()
		if dailyCanClaim and ClaimDaily then
			ClaimDaily:FireServer()
		end
	end)

	btnDaily.MouseButton1Click:Connect(function()
		local open = not outer.Visible
		outer.Visible = open
		if open then
			menuTienda.Visible = false
			menuRetos.Visible = false
			menuAbierto = false
		end
	end)

	local function paintStreak(streak, canClaim)
		streak = math.clamp(tonumber(streak) or 0, 0, 7)
		for i = 1, 7 do
			local dot = dayDots[i]
			if i <= streak then
				-- reclamado
				dot.frame.BackgroundColor3 = Color3.fromRGB(30, 70, 45)
				dot.icon.Image = normalizeAsset(ICONS.check)
				dot.icon.ImageColor3 = Color3.fromRGB(80, 255, 140)
			elseif i == streak + 1 and canClaim then
				-- día actual reclamable
				dot.frame.BackgroundColor3 = Color3.fromRGB(70, 55, 20)
				dot.icon.Image = normalizeAsset(ICONS.estrella)
				dot.icon.ImageColor3 = TEMA.oro
			else
				-- bloqueado
				dot.frame.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
				dot.icon.Image = normalizeAsset(ICONS.candado)
				dot.icon.ImageColor3 = TEMA.muted
			end
		end
	end

	if SyncDaily then
		SyncDaily.OnClientEvent:Connect(function(data)
			if not data then return end
			dailyCanClaim = data.canClaim and true or false
			paintStreak(data.streak or 0, dailyCanClaim)
			if data.canClaim then
				dInfo.Text = string.format("¡Recompensa disponible!\nRacha: %d días", data.streak or 0)
				dClaim.BackgroundColor3 = TEMA.verde
				dClaim.Text = "RECLAMAR"
			else
				local mins = math.floor((data.nextIn or 0) / 60)
				dInfo.Text = string.format("Ya reclamada hoy · Racha %d\nPróxima en ~%dh %dm", data.streak or 0, math.floor(mins/60), mins % 60)
				dClaim.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
				dClaim.Text = "ESPERA"
			end
			if data.claimed and data.reward then
				dInfo.Text = string.format("¡+%d monedas +%d XP!\nRacha día %d", data.reward.monedas, data.reward.xp, data.reward.streak)
				paintStreak(data.reward.streak or data.streak or 0, false)
			end
		end)
	end
end

print("[AuraUI] Daily + iconos listos")

-- =====================================================
-- PROMO ROBUX PERIÓDICA (pestaña cerrable)
-- =====================================================
local promoTiersLocal = {} -- [trackId] = tierIndex
local promoFrame = Instance.new("Frame")
promoFrame.Name = "RobuxPromo"
-- Mismo ancho que el resto de notificaciones (1,0 = 100% del notifContainer)
promoFrame.Size = UDim2.new(1, 0, 0, 130)
promoFrame.BackgroundColor3 = TEMA.fondoOscuro
promoFrame.Visible = false
promoFrame.ZIndex = 42
promoFrame.LayoutOrder = -5
promoFrame.Parent = notifContainer
Instance.new("UICorner", promoFrame).CornerRadius = UDim.new(0, 12)
local promoStroke = Instance.new("UIStroke")
promoStroke.Color = TEMA.oro
promoStroke.Thickness = 2 -- un solo borde
promoStroke.Parent = promoFrame

-- sin marco interior (evita doble borde)
local promoInner = promoFrame

local promoTitle = Instance.new("TextLabel")
promoTitle.Size = UDim2.new(1, -40, 0, 22)
promoTitle.Position = UDim2.new(0, 8, 0, 6)
promoTitle.BackgroundTransparency = 1
promoTitle.Font = Enum.Font.GothamBlack
promoTitle.TextSize = 14
promoTitle.TextColor3 = TEMA.naranja
promoTitle.TextXAlignment = Enum.TextXAlignment.Left
promoTitle.Text = "💎 Oferta especial"
promoTitle.Parent = promoInner

local promoClose = Instance.new("TextButton")
promoClose.Size = UDim2.new(0, 28, 0, 28)
promoClose.Position = UDim2.new(1, -32, 0, 4)
promoClose.BackgroundColor3 = TEMA.rojo
promoClose.Font = Enum.Font.GothamBlack
promoClose.TextSize = 14
promoClose.TextColor3 = Color3.new(1, 1, 1)
promoClose.Text = "X"
promoClose.Parent = promoInner
Instance.new("UICorner", promoClose).CornerRadius = UDim.new(0, 6)

local promoDesc = Instance.new("TextLabel")
promoDesc.Size = UDim2.new(1, -16, 0, 36)
promoDesc.Position = UDim2.new(0, 8, 0, 30)
promoDesc.BackgroundTransparency = 1
promoDesc.Font = Enum.Font.GothamBold
promoDesc.TextSize = 13
promoDesc.TextColor3 = TEMA.texto
promoDesc.TextXAlignment = Enum.TextXAlignment.Left
promoDesc.TextYAlignment = Enum.TextYAlignment.Top
promoDesc.TextWrapped = true
promoDesc.Text = ""
promoDesc.Parent = promoInner

local promoBuy = Instance.new("TextButton")
promoBuy.Size = UDim2.new(1, -16, 0, 36)
promoBuy.Position = UDim2.new(0, 8, 1, -44)
promoBuy.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
promoBuy.Font = Enum.Font.GothamBlack
promoBuy.TextSize = 14
promoBuy.TextColor3 = Color3.new(1, 1, 1)
promoBuy.Text = "Comprar R$ 9"
promoBuy.Parent = promoInner
Instance.new("UICorner", promoBuy).CornerRadius = UDim.new(0, 8)

local promoActual = nil -- { track, tier, tierIdx, productId }

promoClose.MouseButton1Click:Connect(function()
	promoFrame.Visible = false
end)

promoBuy.MouseButton1Click:Connect(function()
	if not promoActual then return end
	if promoActual.accion == "rebirth" then
		if HacerRebirth then
			HacerRebirth:FireServer()
			promoFrame.Visible = false
		end
		return
	end
	if not promoActual.productId or promoActual.productId == 0 then
		crearNotificacion("Robux", "Este producto aún no tiene productId configurado")
		return
	end
	MarketplaceService:PromptProductPurchase(player, promoActual.productId)
end)

local function mostrarPromoAleatoria()
	local tracks = Config.ROBUX_PROMO and Config.ROBUX_PROMO.TRACKS
	if not tracks or #tracks == 0 then return end

	-- Elegir track aleatorio que aún tenga tiers
	local candidatos = {}
	for _, track in ipairs(tracks) do
		local idx = promoTiersLocal[track.id] or 1
		if idx <= #track.tiers then
			table.insert(candidatos, track)
		end
	end
	if #candidatos == 0 then return end

	local track = candidatos[math.random(1, #candidatos)]
	local idx = promoTiersLocal[track.id] or 1
	local tier = track.tiers[idx]
	if not tier then return end

	promoActual = { track = track, tier = tier, tierIdx = idx, productId = tier.productId }
	promoTitle.Text = (track.emoji or "💎") .. " " .. (track.titulo or "Oferta")
	promoDesc.Text = (tier.label or "Mejora") .. "  ·  Tier " .. idx .. "/" .. #track.tiers
	promoBuy.Text = "Comprar  R$ " .. tostring(tier.precio or "…")
	promoFrame.Visible = true
	if tier.productId and tier.productId ~= 0 then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(tier.productId, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux and promoActual and promoActual.productId == tier.productId then
				promoBuy.Text = "Comprar  R$ " .. tostring(info.PriceInRobux)
			end
		end)
	end

	local dur = (Config.ROBUX_PROMO and Config.ROBUX_PROMO.DURACION_VISIBLE) or 0
	if dur > 0 then
		local token = promoActual
		task.delay(dur, function()
			if promoFrame.Visible and promoActual == token then
				promoFrame.Visible = false
			end
		end)
	end
end

-- Las promos inteligentes las envía el SERVIDOR (promo_smart).
-- Se mantiene mostrarPromoAleatoria como fallback manual si hace falta.


-- Sync tiers desde servidor
if NotificarCliente then
	-- ampliar handler existente es complicado; añadimos otra conexión
	NotificarCliente.OnClientEvent:Connect(function(data)
		if not data then return end
		if data.tipo == "promo_tiers" and typeof(data.tiers) == "table" then
			promoTiersLocal = data.tiers
		elseif data.tipo == "promo_tier" and data.trackId then
			promoTiersLocal[data.trackId] = data.tier or 1
			promoFrame.Visible = false
		elseif data.tipo == "anim_anclaje" then
			if data.activo then
				playAnclajeAnimLocal(data.animId)
			else
				stopAnclajeAnimLocal()
				local char = player.Character
				if char then
					local animate = char:FindFirstChild("Animate")
					if animate and (animate:IsA("LocalScript") or animate:IsA("Script")) then
						animate.Enabled = true
					end
				end
			end
		elseif data.tipo == "proteccion" then
			if protFrame and protLabel then
				if data.activo and (data.segundos or 0) > 0 then
					protFrame.Visible = true
					protLabel.Text = formatProt(data.segundos)
				else
					protFrame.Visible = false
				end
			end
		elseif data.tipo == "rebirth_disponible" then
			crearNotificacion("¡REBIRTH disponible!", data.mensaje or "Puedes reiniciar con ventajas permanentes", {
				{ texto = "HACER REBIRTH", color = Color3.fromRGB(180, 50, 230), callback = function()
					if HacerRebirth then HacerRebirth:FireServer() end
				end },
			}, true, ICONS.rebirths)
		elseif data.tipo == "promo_smart" then
			local esRebirth = data.accion == "rebirth"
			promoActual = {
				accion = data.accion or "product",
				track = { titulo = data.titulo, emoji = "" },
				tier = { label = data.label, precio = data.precioFallback, productId = data.productId },
				tierIdx = data.tierIdx or 1,
				productId = data.productId,
			}
			promoTitle.Text = data.titulo or (esRebirth and "♻️ REBIRTH" or "💎 Oferta")
			local razon = data.razon and (" · " .. data.razon) or ""
			if esRebirth then
				promoDesc.Text = (data.label or "Reinicia con ventajas") .. razon
				promoBuy.Text = "♻️ HACER REBIRTH"
				promoBuy.BackgroundColor3 = Color3.fromRGB(180, 50, 230)
			else
				promoDesc.Text = (data.label or "Mejora") .. "  ·  Tier " .. tostring(data.tierIdx or 1) .. "/" .. tostring(data.tiersTotal or "?") .. razon
				promoBuy.Text = "Comprar  R$ " .. tostring(data.precioFallback or "…")
				promoBuy.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
				if data.productId and data.productId ~= 0 then
					task.spawn(function()
						local ok, info = pcall(function()
							return MarketplaceService:GetProductInfo(data.productId, Enum.InfoType.Product)
						end)
						if ok and info and info.PriceInRobux and promoActual and promoActual.productId == data.productId then
							promoBuy.Text = "Comprar  R$ " .. tostring(info.PriceInRobux)
						end
					end)
				end
			end
			promoFrame.Visible = true
			local dur = (Config.RECOMENDACIONES and Config.RECOMENDACIONES.DURACION_VISIBLE)
				or (Config.ROBUX_PROMO and Config.ROBUX_PROMO.DURACION_VISIBLE)
				or 45
			if dur > 0 then
				local token = promoActual
				task.delay(dur, function()
					if promoFrame.Visible and promoActual == token then
						promoFrame.Visible = false
					end
				end)
			end
		end
	end)
end

print("[AuraUI] Promo Robux lista")


player.CharacterAdded:Connect(function()
	stopAnclajeAnimLocal()
end)
