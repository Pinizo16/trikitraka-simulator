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

-- Iconos solo desde Config (fuente única)
local ICONS = (Config and Config.ICONS) or {}

local function dlog(...)
	local d = Config and Config.DEBUG
	if d and d.Enabled and d.Client then
		print("[AuraUI]", ...)
	end
end


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
local TutorialSync         = waitRemote("TutorialSync")
local TutorialAction       = waitRemote("TutorialAction")
local PedirStatsExtra       = waitRemote("PedirStatsExtra")
local StatsExtra            = waitRemote("StatsExtra")
local ReiniciarProgreso     = waitRemote("ReiniciarProgreso")
print("[AuraUI] Remotes listos")

-- Flag tutorial (debe existir antes de actualizarLista)
local tutorialActive = false

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
sidePanel.Size = UDim2.new(0, 56, 0, 340)
sidePanel.Position = UDim2.new(0, 12, 0.5, -170)
sidePanel.BackgroundTransparency = 1
sidePanel.ZIndex = 15
sidePanel.Parent = screenGui

local sideLayout = Instance.new("UIListLayout")
sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
sideLayout.Padding = UDim.new(0, 10)
sideLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
sideLayout.Parent = sidePanel

local function crearBotonIcono(iconAsset, order, borderColor)
	local b = Instance.new("ImageButton")
	b.Size = UDim2.new(0, 52, 0, 52)
	b.BackgroundColor3 = TEMA.fondoOscuro
	b.AutoButtonColor = false
	b.LayoutOrder = order or 0
	b.ZIndex = 16
	b.Parent = sidePanel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
	local st = Instance.new("UIStroke")
	st.Name = "Border"
	st.Color = borderColor or TEMA.oro
	st.Thickness = 2
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = b
	setButtonIcon(b, iconAsset, 11)
	local baseBg = TEMA.fondoOscuro
	b.MouseEnter:Connect(function()
		b.BackgroundColor3 = Color3.fromRGB(45, 50, 68)
		st.Thickness = 2.5
	end)
	b.MouseLeave:Connect(function()
		b.BackgroundColor3 = baseBg
		st.Thickness = 2
	end)
	return b
end

-- Bordes del color de cada icono
local COL_RETAR = Color3.fromRGB(220, 55, 55)
local COL_TIENDA = Color3.fromRGB(255, 150, 40)
local COL_DAILY = Color3.fromRGB(160, 80, 220)
local COL_STATS = Color3.fromRGB(70, 170, 255)
local COL_DESANCLAR = Color3.fromRGB(160, 110, 55)

local btnRetar     = crearBotonIcono(ICONS.retar, 1, COL_RETAR)
local btnTienda    = crearBotonIcono(ICONS.tienda, 2, COL_TIENDA)
local btnDaily     = crearBotonIcono(ICONS.daily, 3, COL_DAILY)
local btnStats     = crearBotonIcono(ICONS.stats, 4, COL_STATS)
btnStats.Name = "BtnStats"
btnStats.Visible = true
btnStats.Active = true
btnStats.MouseButton1Click:Connect(function()
	local so = screenGui:FindFirstChild("MenuStats")
	if not so then
		warn("[AuraUI] MenuStats no encontrado")
		return
	end
	local open = not so.Visible
	so.Visible = open
	if open then
		if menuTienda then menuTienda.Visible = false end
		if menuRetos then menuRetos.Visible = false end
		menuAbierto = false
		if dailyFrame then dailyFrame.Visible = false end
		so:SetAttribute("OpenTick", tick())
		if abrirStats then abrirStats(true) end
	end
end)
local btnDesanclar = crearBotonIcono(ICONS.desanclar, 5, COL_DESANCLAR)
btnDesanclar.Visible = false
print("[AuraUI] BtnStats listo (conexión temprana)")

btnDesanclar.MouseButton1Click:Connect(function()
	if DesanclarJugador then DesanclarJugador:FireServer() end
	btnDesanclar.Visible = false
	ancladoPill.Visible = false
end)

local function cerrarMenusLaterales()
	local so = screenGui:FindFirstChild("MenuStats")
	if so then so.Visible = false end
	if menuRetos then menuRetos.Visible = false end
	if menuTienda then menuTienda.Visible = false end
	menuAbierto = false
	if dailyFrame then dailyFrame.Visible = false end
end


-- UI compartida (hoisted para scopes de setup*)
local menuRetos
local menuTienda
local listaRetos
local scrollRetos
local actualizarLista
local tiendaMostrar
local abrirStats

local function setupMenuRetar()
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

local scrollRetos = Instance.new("ScrollingFrame")
scrollRetos.Size = UDim2.new(1, -16, 1, -56)
scrollRetos.Position = UDim2.new(0, 8, 0, 48)
scrollRetos.BackgroundTransparency = 1
scrollRetos.ScrollBarThickness = 4
scrollRetos.ScrollBarImageColor3 = TEMA.oro
scrollRetos.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollRetos.BorderSizePixel = 0
scrollRetos.ZIndex = 32
scrollRetos.Parent = menuRetosInner
do
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 6)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = scrollRetos
end

menuRetos = menuRetosOuter

end
setupMenuRetar()

local function setupTienda()
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

menuTienda = menuTiendaOuter

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

tiendaMostrar = function(tab)
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
	if not menuTienda then return end
	local open = not menuTienda.Visible
	menuTienda.Visible = open
	if menuRetos then menuRetos.Visible = false end
	menuAbierto = false
	if dailyFrame then dailyFrame.Visible = false end
	local so = screenGui:FindFirstChild("MenuStats")
	if so then so.Visible = false end
	if open then actualizarPreciosTienda() end
end)

end
setupTienda()

local function setupListaRetar()
-- =====================================================
-- MENÚ RETAR — lista de jugadores
-- =====================================================
menuAbierto = false
local retoCooldownHasta = 0
actualizarLista = function()
	if not scrollRetos then return end
	for _, c in ipairs(scrollRetos:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	local count = 0

	local function addRow(displayName, subText, iconAsset, onRetar, highlight)
		count = count + 1
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 52)
		row.BackgroundColor3 = highlight and Color3.fromRGB(40, 36, 28) or Color3.fromRGB(28, 30, 42)
		row.ZIndex = 33
		row.LayoutOrder = count
		row.Parent = scrollRetos
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)
		goldStroke(row, highlight and 2 or 1)
		iconImg(row, iconAsset or ICONS.retar, UDim2.new(0, 22, 0, 22), UDim2.new(0, 10, 0.5, -11))
		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -100, 0, 22)
		name.Position = UDim2.new(0, 40, 0, 6)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextSize = 14
		name.TextColor3 = TEMA.texto
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Text = displayName
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
		sub.Text = subText
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
		if highlight then
			local st = Instance.new("UIStroke")
			st.Color = TEMA.oro
			st.Thickness = 2
			st.Parent = btn
			local tip = Instance.new("TextLabel")
			tip.Size = UDim2.new(0, 70, 0, 16)
			tip.Position = UDim2.new(1, -70, 0, -14)
			tip.BackgroundTransparency = 1
			tip.Font = Enum.Font.GothamBlack
			tip.TextSize = 11
			tip.TextColor3 = TEMA.oro
			tip.Text = "Pulsa aquí"
			tip.ZIndex = 36
			tip.Parent = row
		end
		btn.MouseButton1Click:Connect(function()
			if tick() < retoCooldownHasta then return end
			retoCooldownHasta = tick() + 1.5
			onRetar(btn)
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

	if tutorialActive then
		-- Solo bots de batalla nivel 1 (aprender a retar)
		local seen = {}
		local function tryAddBot(inst)
			if not inst or not inst:IsA("Model") or seen[inst] then return end
			if not inst.Parent then return end
			local prompt = inst:FindFirstChild("PromptBot", true)
			local nameL = string.lower(inst.Name)
			local looksBot = prompt ~= nil or nameL:find("bot") ~= nil
			if not looksBot then return end
			local nv = tonumber(string.match(inst.Name, "%d+"))
			local attrNv = prompt and tonumber(prompt:GetAttribute("NivelBot"))
			local nivel = nv or attrNv or 0
			-- aceptar nivel 1; si no hay número pero tiene PromptBot y el nombre sugiere nivel 1
			if nivel ~= 1 then
				if nameL:find("nivel1") or nameL:find("level1") or nameL:find("_1") or nameL:find("nv1") then
					nivel = 1
				else
					return
				end
			end
			seen[inst] = true
			local botName = inst.Name
			addRow(botName, "BOT · NV 1 · tutorial", ICONS.bot or ICONS.retar, function()
				if SolicitarDueloDirecto then
					SolicitarDueloDirecto:FireServer(botName)
				end
			end, true)
		end
		for _, inst in ipairs(workspace:GetChildren()) do
			tryAddBot(inst)
		end
		for _, inst in ipairs(workspace:GetDescendants()) do
			tryAddBot(inst)
		end
	else
		-- Solo jugadores reales
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				local nv = 1
				local ls = pl:FindFirstChild("leaderstats")
				if ls and ls:FindFirstChild("Nivel") then nv = ls.Nivel.Value end
				local uid = pl.UserId
				addRow(pl.DisplayName or pl.Name, "NV " .. tostring(nv), ICONS.retar, function()
					if SolicitarDueloDirecto then
						SolicitarDueloDirecto:FireServer(uid)
					end
				end, false)
			end
		end
	end

	if count == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, -8, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 13
		empty.TextColor3 = TEMA.muted or TEMA.textoSuave
		empty.TextWrapped = true
		empty.ZIndex = 34
		empty.Text = tutorialActive and "No hay bots nivel 1 en el mapa (coloca bot_Nivel1)" or "No hay jugadores"
		empty.Parent = scrollRetos
	end
	local lay = scrollRetos:FindFirstChildOfClass("UIListLayout")
	if lay then
		scrollRetos.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 12)
	end
end

btnRetar.MouseButton1Click:Connect(function()
	menuAbierto = not menuAbierto
	menuRetos.Visible = menuAbierto
	menuTienda.Visible = false
	if dailyFrame then dailyFrame.Visible = false end
	local so = screenGui:FindFirstChild("MenuStats")
	if so then so.Visible = false end
	if menuAbierto then actualizarLista() end
end)

end
setupListaRetar()

local function setupNotifHandlers()
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
			local msg = tostring(data.mensaje or "")
			-- Silenciar solo ruido de tienda; protección/cooldown SÍ se muestran
			local soft = {
				"nivel insuficiente", "no tienes suficiente", "ya reclamaste",
			}
			local lower = string.lower(msg)
			local isSoft = false
			for _, k in ipairs(soft) do
				if string.find(lower, k, 1, true) then isSoft = true break end
			end
			if msg ~= "" and not isSoft then
				crearNotificacion("Aviso", msg, nil, false, ICONS.error)
			end
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
		local extra = (data.recompensa and data.recompensa > 0) and ("\n+" .. data.recompensa .. " monedas") or ""
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


end
setupNotifHandlers()

-- =====================================================
-- =====================================================
-- ESTADÍSTICAS (fuera del tutorial)
local function setupEstadisticas()
-- ESTADÍSTICAS: tarjetas visuales centradas (estilo mockup)
local statsRanksCache = { proteccionRestante = 0 }

local statsOuter = Instance.new("Frame")
statsOuter.Name = "MenuStats"
statsOuter.Size = UDim2.new(0, 520, 0, 480)
statsOuter.Position = UDim2.new(0.5, -260, 0.5, -240)
statsOuter.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
statsOuter.Visible = false
statsOuter.ZIndex = 55
statsOuter.ClipsDescendants = false
statsOuter.Parent = screenGui
Instance.new("UICorner", statsOuter).CornerRadius = UDim.new(0, 18)
do
	local st = Instance.new("UIStroke")
	st.Color = TEMA.oro
	st.Thickness = 2.5
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = statsOuter
end

-- Header
local hdr = Instance.new("Frame")
hdr.Size = UDim2.new(1, -24, 0, 44)
hdr.Position = UDim2.new(0, 12, 0, 10)
hdr.BackgroundTransparency = 1
hdr.ZIndex = 56
hdr.Parent = statsOuter

local statsTitle = Instance.new("TextLabel")
statsTitle.Size = UDim2.new(1, -80, 1, 0)
statsTitle.BackgroundTransparency = 1
statsTitle.Font = Enum.Font.GothamBlack
statsTitle.TextSize = 24
statsTitle.TextColor3 = Color3.fromRGB(245, 245, 255)
statsTitle.TextXAlignment = Enum.TextXAlignment.Left
statsTitle.Text = "Estadísticas"
statsTitle.ZIndex = 57
statsTitle.Parent = hdr

local statsIconHdr = Instance.new("ImageLabel")
statsIconHdr.Size = UDim2.new(0, 28, 0, 28)
statsIconHdr.Position = UDim2.new(1, -72, 0.5, -14)
statsIconHdr.BackgroundTransparency = 1
statsIconHdr.Image = normalizeAsset(ICONS.stats or ICONS.estrella)
statsIconHdr.ZIndex = 57
statsIconHdr.Parent = hdr

local statsClose = Instance.new("ImageButton")
statsClose.Size = UDim2.new(0, 34, 0, 34)
statsClose.Position = UDim2.new(1, -34, 0.5, -17)
statsClose.BackgroundColor3 = Color3.fromRGB(42, 32, 32)
statsClose.Image = normalizeAsset(ICONS.cerrar)
statsClose.ScaleType = Enum.ScaleType.Fit
statsClose.ZIndex = 58
statsClose.Parent = hdr
Instance.new("UICorner", statsClose).CornerRadius = UDim.new(0, 10)

local statsScroll = Instance.new("ScrollingFrame")
statsScroll.Size = UDim2.new(1, -20, 1, -64)
statsScroll.Position = UDim2.new(0, 10, 0, 56)
statsScroll.BackgroundTransparency = 1
statsScroll.BorderSizePixel = 0
statsScroll.ScrollBarThickness = 5
statsScroll.ScrollBarImageColor3 = TEMA.oro
statsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
statsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
statsScroll.ClipsDescendants = true
statsScroll.ZIndex = 56
statsScroll.Parent = statsOuter

local statsPad = Instance.new("UIPadding")
statsPad.PaddingTop = UDim.new(0, 4)
statsPad.PaddingBottom = UDim.new(0, 12)
statsPad.PaddingLeft = UDim.new(0, 4)
statsPad.PaddingRight = UDim.new(0, 8)
statsPad.Parent = statsScroll

local statsList = Instance.new("UIListLayout")
statsList.SortOrder = Enum.SortOrder.LayoutOrder
statsList.Padding = UDim.new(0, 12)
statsList.Parent = statsScroll

local function strokeGold(parent, thick)
	local st = Instance.new("UIStroke")
	st.Color = TEMA.oro
	st.Thickness = thick or 2
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.LineJoinMode = Enum.LineJoinMode.Round
	st.Parent = parent
	return st
end

local function sectionLabel(order, text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -8, 0, 20)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = 13
	l.TextColor3 = TEMA.oro
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Text = text
	l.LayoutOrder = order
	l.ZIndex = 57
	l.Parent = statsScroll
	return l
end

-- Tarjeta visual individual (icono + título + valor grande)
local function metricCard(parent, order, iconAsset, title, accent)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0.5, -8, 0, 92)
	f.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	f.LayoutOrder = order
	f.ZIndex = 57
	f.ClipsDescendants = false
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	strokeGold(f, 1.8)

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 36, 0, 36)
	iconBg.Position = UDim2.new(0, 10, 0, 10)
	iconBg.BackgroundColor3 = Color3.fromRGB(32, 36, 50)
	iconBg.ZIndex = 58
	iconBg.Parent = f
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)

	local ic = Instance.new("ImageLabel")
	ic.Size = UDim2.new(1, -8, 1, -8)
	ic.Position = UDim2.new(0, 4, 0, 4)
	ic.BackgroundTransparency = 1
	ic.Image = normalizeAsset(iconAsset)
	ic.ScaleType = Enum.ScaleType.Fit
	ic.ZIndex = 59
	ic.Parent = iconBg

	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, -54, 0, 16)
	t.Position = UDim2.new(0, 52, 0, 12)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextSize = 11
	t.TextColor3 = Color3.fromRGB(160, 165, 185)
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = title
	t.ZIndex = 58
	t.Parent = f

	local val = Instance.new("TextLabel")
	val.Name = "Val"
	val.Size = UDim2.new(1, -20, 0, 28)
	val.Position = UDim2.new(0, 12, 0, 48)
	val.BackgroundTransparency = 1
	val.Font = Enum.Font.GothamBlack
	val.TextSize = 22
	val.TextColor3 = accent or Color3.fromRGB(255, 220, 100)
	val.TextXAlignment = Enum.TextXAlignment.Left
	val.Text = "—"
	val.ZIndex = 58
	val.Parent = f

	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.Size = UDim2.new(1, -20, 0, 14)
	sub.Position = UDim2.new(0, 12, 0, 74)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 11
	sub.TextColor3 = Color3.fromRGB(140, 145, 165)
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.Text = ""
	sub.ZIndex = 58
	sub.Parent = f
	return f, val, sub
end

local function rowGrid(order, height)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -4, 0, height or 92)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.ZIndex = 56
	row.Parent = statsScroll
	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.Padding = UDim.new(0, 10)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = row
	return row
end

local function wideCard(order, height)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, -4, 0, height or 72)
	f.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	f.LayoutOrder = order
	f.ZIndex = 57
	f.ClipsDescendants = false
	f.Parent = statsScroll
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	strokeGold(f, 1.8)
	return f
end

local function barIn(parent, y)
	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, -24, 0, 12)
	bg.Position = UDim2.new(0, 12, 0, y)
	bg.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
	bg.ZIndex = 58
	bg.Parent = parent
	Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.BackgroundColor3 = TEMA.oro
	fill.ZIndex = 59
	fill.Parent = bg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
	return fill
end

-- PROGRESIÓN
sectionLabel(1, "PROGRESIÓN")
local cardProg = wideCard(2, 100)
local lblNivel = Instance.new("TextLabel")
lblNivel.Size = UDim2.new(0.5, -16, 0, 22)
lblNivel.Position = UDim2.new(0, 12, 0, 10)
lblNivel.BackgroundTransparency = 1
lblNivel.Font = Enum.Font.GothamBlack
lblNivel.TextSize = 18
lblNivel.TextColor3 = Color3.fromRGB(100, 210, 255)
lblNivel.TextXAlignment = Enum.TextXAlignment.Left
lblNivel.Text = "Nivel 1"
lblNivel.ZIndex = 58
lblNivel.Parent = cardProg
local lblXpTxt = Instance.new("TextLabel")
lblXpTxt.Size = UDim2.new(0.5, -16, 0, 18)
lblXpTxt.Position = UDim2.new(0.5, 0, 0, 12)
lblXpTxt.BackgroundTransparency = 1
lblXpTxt.Font = Enum.Font.GothamBold
lblXpTxt.TextSize = 13
lblXpTxt.TextColor3 = Color3.fromRGB(180, 185, 200)
lblXpTxt.TextXAlignment = Enum.TextXAlignment.Right
lblXpTxt.Text = "0 / 100 XP"
lblXpTxt.ZIndex = 58
lblXpTxt.Parent = cardProg
local fillXp = barIn(cardProg, 36)
fillXp.BackgroundColor3 = Color3.fromRGB(255, 180, 50)

local lblReb = Instance.new("TextLabel")
lblReb.Size = UDim2.new(0.5, -16, 0, 18)
lblReb.Position = UDim2.new(0, 12, 0, 52)
lblReb.BackgroundTransparency = 1
lblReb.Font = Enum.Font.GothamBold
lblReb.TextSize = 14
lblReb.TextColor3 = Color3.fromRGB(230, 230, 245)
lblReb.TextXAlignment = Enum.TextXAlignment.Left
lblReb.Text = "Rebirths: 0"
lblReb.ZIndex = 58
lblReb.Parent = cardProg
local lblRebNeed = Instance.new("TextLabel")
lblRebNeed.Size = UDim2.new(0.5, -16, 0, 18)
lblRebNeed.Position = UDim2.new(0.5, 0, 0, 52)
lblRebNeed.BackgroundTransparency = 1
lblRebNeed.Font = Enum.Font.Gotham
lblRebNeed.TextSize = 12
lblRebNeed.TextColor3 = Color3.fromRGB(160, 165, 185)
lblRebNeed.TextXAlignment = Enum.TextXAlignment.Right
lblRebNeed.Text = "0 / 10"
lblRebNeed.ZIndex = 58
lblRebNeed.Parent = cardProg
local fillReb = barIn(cardProg, 74)
fillReb.BackgroundColor3 = Color3.fromRGB(100, 180, 255)

local lblShield = Instance.new("TextLabel")
lblShield.Size = UDim2.new(1, -24, 0, 0)
lblShield.Position = UDim2.new(0, 12, 0, 88)
lblShield.BackgroundTransparency = 1
lblShield.Font = Enum.Font.GothamBold
lblShield.TextSize = 12
lblShield.TextColor3 = Color3.fromRGB(100, 200, 255)
lblShield.TextXAlignment = Enum.TextXAlignment.Left
lblShield.Text = ""
lblShield.ZIndex = 58
lblShield.Parent = cardProg
lblShield.Visible = false

-- ECONOMÍA
sectionLabel(3, "ECONOMÍA Y COMBATE")
local rowEco = rowGrid(4, 92)
local _, valMonedas, subMonedas = metricCard(rowEco, 1, ICONS.moneda or ICONS.estrella, "MONEDAS", Color3.fromRGB(255, 220, 80))
local _, valVict, subVict = metricCard(rowEco, 2, ICONS.poder or ICONS.estrella, "VICTORIAS PvP", Color3.fromRGB(255, 140, 100))
local cardXpTot = wideCard(5, 70)
local icXp = Instance.new("ImageLabel")
icXp.Size = UDim2.new(0, 32, 0, 32)
icXp.Position = UDim2.new(0, 14, 0.5, -16)
icXp.BackgroundTransparency = 1
icXp.Image = normalizeAsset(ICONS.multixp or ICONS.estrella)
icXp.ZIndex = 58
icXp.Parent = cardXpTot
local lblXpTotTitle = Instance.new("TextLabel")
lblXpTotTitle.Size = UDim2.new(1, -60, 0, 16)
lblXpTotTitle.Position = UDim2.new(0, 54, 0, 14)
lblXpTotTitle.BackgroundTransparency = 1
lblXpTotTitle.Font = Enum.Font.GothamBold
lblXpTotTitle.TextSize = 11
lblXpTotTitle.TextColor3 = Color3.fromRGB(160, 165, 185)
lblXpTotTitle.TextXAlignment = Enum.TextXAlignment.Left
lblXpTotTitle.Text = "XP TOTAL CONSEGUIDO"
lblXpTotTitle.ZIndex = 58
lblXpTotTitle.Parent = cardXpTot
local valXpTot = Instance.new("TextLabel")
valXpTot.Size = UDim2.new(1, -60, 0, 28)
valXpTot.Position = UDim2.new(0, 54, 0, 32)
valXpTot.BackgroundTransparency = 1
valXpTot.Font = Enum.Font.GothamBlack
valXpTot.TextSize = 22
valXpTot.TextColor3 = Color3.fromRGB(120, 200, 255)
valXpTot.TextXAlignment = Enum.TextXAlignment.Left
valXpTot.Text = "0"
valXpTot.ZIndex = 58
valXpTot.Parent = cardXpTot

-- MEJORAS
sectionLabel(6, "MEJORAS")
local rowUp1 = rowGrid(7, 92)
local _, valClicks, subClicks = metricCard(rowUp1, 1, ICONS.clicks or ICONS.poder, "CLICKS / CLICK", Color3.fromRGB(255, 200, 80))
local _, valIntervalo, subIntervalo = metricCard(rowUp1, 2, ICONS.velAnclaje or ICONS.anclar, "INTERVALO TT", Color3.fromRGB(100, 220, 255))
local rowUp2 = rowGrid(8, 92)
local _, valXpTick, subXpTick = metricCard(rowUp2, 1, ICONS.multixp or ICONS.estrella, "XP POR INTERVALO", Color3.fromRGB(140, 255, 160))
local _, valWalk, subWalk = metricCard(rowUp2, 2, ICONS.walk or ICONS.estrella, "VELOCIDAD", Color3.fromRGB(200, 180, 255))
local cardMulti = wideCard(9, 48)
local lblMulti = Instance.new("TextLabel")
lblMulti.Size = UDim2.new(1, -24, 1, 0)
lblMulti.Position = UDim2.new(0, 12, 0, 0)
lblMulti.BackgroundTransparency = 1
lblMulti.Font = Enum.Font.GothamBold
lblMulti.TextSize = 14
lblMulti.TextColor3 = Color3.fromRGB(200, 205, 220)
lblMulti.TextXAlignment = Enum.TextXAlignment.Center
lblMulti.Text = "Multi XP x1 · Multi Clicks x1"
lblMulti.ZIndex = 58
lblMulti.Parent = cardMulti

-- RESET
sectionLabel(10, "ZONA DE PELIGRO")
local cardReset = wideCard(11, 56)
local btnReset = Instance.new("TextButton")
btnReset.Size = UDim2.new(1, -24, 0, 36)
btnReset.Position = UDim2.new(0, 12, 0, 10)
btnReset.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
btnReset.Font = Enum.Font.GothamBlack
btnReset.TextSize = 14
btnReset.TextColor3 = Color3.new(1, 1, 1)
btnReset.Text = "Reiniciar progreso"
btnReset.ZIndex = 58
btnReset.Parent = cardReset
Instance.new("UICorner", btnReset).CornerRadius = UDim.new(0, 10)
strokeGold(btnReset, 1.2).Color = Color3.fromRGB(200, 80, 70)

local function fmtNum(n)
	n = math.floor(tonumber(n) or 0)
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 1e3 then return string.format("%.1fK", n / 1e3) end
	return tostring(n)
end

local function fmtTiempo(seg)
	seg = math.max(0, math.ceil(tonumber(seg) or 0))
	if seg <= 0 then return nil end
	if seg >= 3600 then
		local h = math.floor(seg / 3600)
		local m = math.floor((seg % 3600) / 60)
		return h .. "h " .. m .. "m"
	end
	if seg >= 60 then
		return math.floor(seg / 60) .. "m " .. (seg % 60) .. "s"
	end
	return seg .. "s"
end

local function actualizarStats()
	local ls = player:FindFirstChild("leaderstats")
	if not ls then return end
	local function gv(n, d)
		local v = ls:FindFirstChild(n)
		return v and v.Value or d
	end
	local nivel = gv("Nivel", 1)
	local xp = gv("XP", 0)
	local maxXp = math.max(1, gv("MaxXP", 100))
	local rebirths = gv("Rebirths", 0)
	local monedas = gv("Monedas", 0)
	local vict = gv("Victorias", 0)
	local xpTot = gv("XPTotal", 0)
	local cpc = gv("ClicksPorClick", 1) + gv("ClicksRobux", 0)
	local multiXp = gv("MultiXP", 1)
	local multiCk = gv("MultiClicks", 1)
	local velA = gv("VelocidadAnclaje", 0) + gv("VelocidadAnclajeRobux", 0)
	local velM = gv("VelocidadMovimiento", 0) + gv("VelocidadMovimientoRobux", 0)
	local intervalo = (Config.getIntervaloAnclaje and Config.getIntervaloAnclaje(velA)) or math.max(0.03, 1 - velA * 0.1)
	local xpTick = math.floor((Config.XP_ANCLAJE_GANA or 20) * (tonumber(multiXp) or 1))
	local walk = (Config.getWalkSpeed and Config.getWalkSpeed(velM)) or (16 + velM * 2)
	local minReb = (Config.getNivelMinimoRebirth and Config.getNivelMinimoRebirth(rebirths)) or 10

	lblNivel.Text = "Nivel " .. tostring(nivel)
	lblXpTxt.Text = fmtNum(xp) .. " / " .. fmtNum(maxXp) .. " XP"
	fillXp.Size = UDim2.new(math.clamp(xp / maxXp, 0, 1), 0, 1, 0)
	lblReb.Text = "Rebirths: " .. tostring(rebirths)
	lblRebNeed.Text = tostring(nivel) .. " / " .. tostring(minReb) .. " nivel"
	fillReb.Size = UDim2.new(math.clamp(nivel / math.max(1, minReb), 0, 1), 0, 1, 0)

	local prot = statsRanksCache.proteccionRestante or 0
	local tProt = fmtTiempo(prot)
	if tProt then
		lblShield.Text = "Escudo activo · " .. tProt
		lblShield.Visible = true
		lblShield.Size = UDim2.new(1, -24, 0, 16)
		cardProg.Size = UDim2.new(1, -4, 0, 112)
	else
		lblShield.Text = ""
		lblShield.Visible = false
		cardProg.Size = UDim2.new(1, -4, 0, 100)
	end

	valMonedas.Text = fmtNum(monedas)
	subMonedas.Text = "Saldo actual"
	valVict.Text = fmtNum(vict)
	subVict.Text = "Batallas ganadas"
	valXpTot.Text = fmtNum(xpTot)

	valClicks.Text = fmtNum(cpc)
	subClicks.Text = "Poder de click"
	valIntervalo.Text = string.format("%.2fs", intervalo)
	subIntervalo.Text = "Entre ticks de XP"
	valXpTick.Text = fmtNum(xpTick)
	subXpTick.Text = "Por tick anclado"
	valWalk.Text = tostring(math.floor(walk))
	subWalk.Text = "WalkSpeed"
	lblMulti.Text = string.format("Multi XP x%.2f  ·  Multi Clicks x%.2f", multiXp, multiCk)


end

abrirStats = function(open)
	if open == nil then open = not statsOuter.Visible end
	statsOuter.Visible = open
	if open then
		if menuTienda then menuTienda.Visible = false end
		if menuRetos then menuRetos.Visible = false end
		menuAbierto = false
		if dailyFrame then dailyFrame.Visible = false end
		actualizarStats()
		-- Solo pedir tiempo de protección (sin ranks)
		local ev = PedirStatsExtra or ReplicatedStorage:FindFirstChild("PedirStatsExtra")
		if ev then
			ev:FireServer()
		end
	end
end

local function bindStatsExtra(ev)
	if not ev or ev:GetAttribute("BoundStats") then return end
	ev:SetAttribute("BoundStats", true)
	ev.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		statsRanksCache.proteccionRestante = data.proteccionRestante or 0
		if statsOuter.Visible then
			actualizarStats()
		end
	end)
end
bindStatsExtra(StatsExtra or ReplicatedStorage:FindFirstChild("StatsExtra"))
task.spawn(function()
	bindStatsExtra(StatsExtra or ReplicatedStorage:WaitForChild("StatsExtra", 20))
end)

statsClose.MouseButton1Click:Connect(function()
	statsOuter.Visible = false
end)

btnReset.MouseButton1Click:Connect(function()
	if not ReiniciarProgreso then return end
	if btnReset:GetAttribute("Confirm") then
		ReiniciarProgreso:FireServer()
		btnReset:SetAttribute("Confirm", false)
		btnReset.Text = "Reiniciar progreso"
		btnReset.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
	else
		btnReset:SetAttribute("Confirm", true)
		btnReset.Text = "¿Seguro? Pulsa otra vez"
		btnReset.BackgroundColor3 = Color3.fromRGB(180, 60, 40)
		task.delay(4, function()
			if btnReset and btnReset.Parent then
				btnReset:SetAttribute("Confirm", false)
				btnReset.Text = "Reiniciar progreso"
				btnReset.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
			end
		end)
	end
end)

do
	local side = screenGui:FindFirstChild("SideButtons")
	local b = side and side:FindFirstChild("BtnStats")
	if b then
		b.MouseButton1Click:Connect(function()
			abrirStats()
		end)
	end
end

task.spawn(function()
	while statsOuter.Parent do
		if statsOuter.Visible then
			pcall(actualizarStats)
		end
		task.wait(1.5)
	end
end)

end

setupEstadisticas()

local function setupTutorial()
-- =====================================================
-- TUTORIAL interactivo
-- =====================================================
local TUTORIAL_STEPS = {
	{
		id = "welcome",
		kind = "info",
		icon = "estrella",
		titulo = "Triki Traka",
		texto = "Ganas XP al hacer Triki Traka por detrás de otros. Subes de nivel, consigues monedas en duelos y mejoras tu poder en la tienda. El Rebirth da multiplicadores permanentes.",
	},
	{
		id = "hud",
		kind = "info",
		icon = "multixp",
		titulo = "Tu progreso",
		texto = "Nivel, XP y monedas están arriba. La barra de XP llena al subir de nivel.",
		highlight = "hud",
	},
	{
		id = "open_tienda",
		kind = "action",
		icon = "tienda",
		titulo = "Abre la Tienda",
		texto = "Pulsa Tienda para ver las mejoras.",
		action = "open_tienda",
		hint = "Pulsa Tienda",
	},
	{
		id = "shop_poder",
		kind = "info",
		icon = "clicks",
		titulo = "Clicks por click",
		texto = "En Poder, cada mejora suma clicks por cada clic en duelos. Clicks efectivos = Clicks por click × Multi clicks.",
		highlight = "tienda_poder",
	},
	{
		id = "shop_vel",
		kind = "info",
		icon = "velAnclaje",
		titulo = "Velocidad Triki Traka",
		texto = "En Movimiento, esta mejora reduce el tiempo entre ticks de XP mientras haces Triki Traka. Más niveles = XP más a menudo.",
		highlight = "tienda_mov",
	},
	{
		id = "open_daily",
		kind = "action",
		icon = "daily",
		titulo = "Recompensa diaria",
		texto = "Abre el Diario y reclama la recompensa de hoy.",
		action = "open_daily",
		hint = "Pulsa Diario",
	},
	{
		id = "claim_daily",
		kind = "action",
		icon = "daily",
		titulo = "Reclama el Diario",
		texto = "Pulsa RECLAMAR. Al terminar el tutorial tendrás 1 minuto de protección.",
		action = "claim_daily",
		hint = "Pulsa RECLAMAR",
	},
	{
		id = "open_retar",
		kind = "action",
		icon = "retar",
		titulo = "Abre Retar",
		texto = "Pulsa Retar. Aquí practicarás con un bot de nivel 1.",
		action = "open_retar",
		hint = "Pulsa Retar",
	},
	{
		id = "do_retar",
		kind = "action",
		icon = "bot",
		titulo = "Reta un bot nivel 1",
		texto = "Pulsa Retar en un bot NV 1 y haz el minijuego de clics.",
		action = "retar_bot",
		hint = "Retar bot nivel 1",
	},
	{
		id = "do_anclar",
		kind = "action",
		icon = "anclar",
		titulo = "Haz Triki Traka",
		texto = "Acércate a un bot ambulante o jugador y usa el prompt Triki Traka (E).",
		action = "anclar",
		hint = "Haz Triki Traka",
	},
	{
		id = "see_xp",
		kind = "action",
		icon = "multixp",
		titulo = "Tu XP sube",
		texto = "Quédate anclado y mira cómo sube la XP arriba.",
		action = "xp_gain",
		hint = "Espera a que suba la XP",
	},
	{
		id = "expulsion_demo",
		kind = "info",
		icon = "desanclar",
		titulo = "Expulsión",
		texto = "Si te hacen Triki Traka, puedes gastar monedas para expulsar. El otro se defiende a clics unos segundos.",
	},
	{
		id = "rebirth_info",
		kind = "info",
		icon = "rebirths",
		titulo = "Rebirth",
		texto = "Reinicia nivel y algunas mejoras a cambio de multiplicadores permanentes. Nivel conseguido no se resetea.",
	},
	{
		id = "done",
		kind = "info",
		icon = "check",
		titulo = "Listo",
		texto = "Triki Traka → XP → nivel → duelos → tienda → Rebirth cuando toque.",
	},
}

tutorialActive = false
local tutorialStep = 1
local tutorialRoot = nil
local tutorialPulse = nil
local tutorialWaiting = false
local tutorialXpStart = nil
local tutorialHighlight = nil
local tutorialDailyOk = false

local function clearTutorialHighlight()
	if tutorialHighlight then
		local p = tutorialHighlight.Parent
		if p then
			local badge = p:FindFirstChild("PulsaAqui")
			if badge then badge:Destroy() end
		end
		tutorialHighlight:Destroy()
		tutorialHighlight = nil
	end
	if screenGui then
		for _, d in ipairs(screenGui:GetDescendants()) do
			if d.Name == "PulsaAqui" then d:Destroy() end
			if d:IsA("UIStroke") and d:GetAttribute("IsTutorial") then d:Destroy() end
		end
	end
end

local function highlightGui(obj, showPulsa)
	clearTutorialHighlight()
	if not obj or not obj.Parent then return end
	local stroke = Instance.new("UIStroke")
	stroke.Name = "TutorialHighlight"
	stroke.Color = TEMA.oro or Color3.fromRGB(245, 197, 66)
	stroke.Thickness = 3
	stroke.Parent = obj
	stroke:SetAttribute("IsTutorial", true)
	tutorialHighlight = stroke
	if showPulsa then
		local badge = Instance.new("TextLabel")
		badge.Name = "PulsaAqui"
		badge.Size = UDim2.new(0, 88, 0, 22)
		badge.Position = UDim2.new(0.5, -44, 0, -26)
		badge.BackgroundColor3 = TEMA.oro or Color3.fromRGB(245, 197, 66)
		badge.Font = Enum.Font.GothamBlack
		badge.TextSize = 12
		badge.TextColor3 = Color3.fromRGB(20, 20, 20)
		badge.Text = "Pulsa aquí"
		badge.ZIndex = (obj.ZIndex or 1) + 20
		badge.Parent = obj
		Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 6)
	end
	task.spawn(function()
		while stroke.Parent do
			stroke.Transparency = 0.05
			task.wait(0.35)
			if not stroke.Parent then break end
			stroke.Transparency = 0.55
			task.wait(0.35)
		end
	end)
end

local function destroyTutorial()
	tutorialActive = false
	tutorialWaiting = false
	tutorialXpStart = nil
	clearTutorialHighlight()
	if tutorialPulse then
		task.cancel(tutorialPulse)
		tutorialPulse = nil
	end
	if tutorialRoot then
		tutorialRoot:Destroy()
		tutorialRoot = nil
	end
end

local function finishTutorial(action)
	destroyTutorial()
	if TutorialAction then
		pcall(function()
			TutorialAction:FireServer(action or "complete")
		end)
	end
end

local function getStep()
	return TUTORIAL_STEPS[tutorialStep]
end

local function updateTutorialCard()
	if not tutorialRoot then return end
	local step = getStep()
	if not step then
		finishTutorial("complete")
		return
	end
	local title = tutorialRoot:FindFirstChild("Title", true)
	local body = tutorialRoot:FindFirstChild("Body", true)
	local progress = tutorialRoot:FindFirstChild("Progress", true)
	local hint = tutorialRoot:FindFirstChild("Hint", true)
	local nextBtn = tutorialRoot:FindFirstChild("NextBtn", true)
	local icon = tutorialRoot:FindFirstChild("StepIcon", true)
	if title then title.Text = step.titulo end
	if body then body.Text = step.texto end
	if progress then progress.Text = string.format("%d / %d", tutorialStep, #TUTORIAL_STEPS) end
	if icon and ICONS[step.icon] then
		icon.Image = normalizeAsset(ICONS[step.icon])
	end
	if hint then
		hint.Text = (step.kind == "action" and (step.hint or "")) or ""
		hint.TextColor3 = TEMA.oro
	end
	if nextBtn then
		if step.kind == "action" then
			nextBtn.Visible = false
			tutorialWaiting = true
		else
			nextBtn.Visible = true
			nextBtn.Text = (tutorialStep >= #TUTORIAL_STEPS) and "¡Jugar!" or "Siguiente"
			tutorialWaiting = false
		end
	end
	clearTutorialHighlight()
	if step.highlight == "hud" or step.action == "xp_gain" then
		local hud = screenGui:FindFirstChild("HUD")
		if hud then highlightGui(hud, false) end
	elseif step.highlight == "tienda_poder" then
		if menuTienda then
			menuTienda.Visible = true
			pcall(function() tiendaMostrar("Poder") end)
			highlightGui(menuTienda, false)
		end
	elseif step.highlight == "tienda_mov" then
		if menuTienda then
			menuTienda.Visible = true
			pcall(function() tiendaMostrar("Movimiento") end)
			highlightGui(menuTienda, false)
		end
	elseif step.action == "open_tienda" then
		if btnTienda then highlightGui(btnTienda, true) end
	elseif step.action == "open_daily" or step.action == "claim_daily" then
		if btnDaily then highlightGui(btnDaily, true) end
		if step.action == "claim_daily" and dailyFrame and dailyFrame.Visible then
			for _, c in ipairs(dailyFrame:GetDescendants()) do
				if c:IsA("TextButton") and string.upper(c.Text or ""):find("RECLAMAR") then
					highlightGui(c, true)
					break
				end
			end
		end
	elseif step.action == "open_retar" then
		if btnRetar then highlightGui(btnRetar, true) end
	elseif step.action == "retar_bot" then
		if menuRetos and menuRetos.Visible then
			pcall(function() actualizarLista() end)
			for _, c in ipairs(menuRetos:GetDescendants()) do
				if c:IsA("TextButton") and c.Text == "Retar" then
					highlightGui(c, true)
					break
				end
			end
		elseif btnRetar then
			highlightGui(btnRetar, true)
		end
	end
end

local function advanceTutorial()
	if tutorialStep >= #TUTORIAL_STEPS then
		finishTutorial("complete")
		return
	end
	tutorialStep = tutorialStep + 1
	tutorialXpStart = nil
	updateTutorialCard()
	local step = getStep()
	if step and step.action == "xp_gain" then
		local ls = player:FindFirstChild("leaderstats")
		local xpv = ls and ls:FindFirstChild("XP")
		tutorialXpStart = xpv and xpv.Value or 0
	end
	if step and step.action == "claim_daily" then
		-- si ya no puede reclamar hoy, avanzar
		task.defer(function()
			task.wait(0.2)
			if tutorialDailyOk then
				tryCompleteAction("claim_daily")
			end
		end)
	end
	if step and step.action == "retar_bot" then
		if menuRetos and menuRetos.Visible then
			pcall(function() actualizarLista() end)
		end
	end
	if TutorialAction then
		pcall(function() TutorialAction:FireServer("step") end)
	end
end

local function tryCompleteAction(actionId)
	if not tutorialActive or not tutorialWaiting then return end
	local step = getStep()
	if not step or step.kind ~= "action" or step.action ~= actionId then return end
	tutorialWaiting = false
	task.delay(0.3, function()
		if tutorialActive then advanceTutorial() end
	end)
end

local function pollTutorialActions()
	if not tutorialActive then return end
	local step = getStep()
	if not step or step.kind ~= "action" then return end
	if step.action == "open_tienda" then
		if menuTienda and menuTienda.Visible then tryCompleteAction("open_tienda") end
	elseif step.action == "open_daily" then
		if dailyFrame and dailyFrame.Visible then tryCompleteAction("open_daily") end
	elseif step.action == "claim_daily" then
		if tutorialDailyOk then
			tryCompleteAction("claim_daily")
		end
	elseif step.action == "open_retar" then
		if menuRetos and menuRetos.Visible then
			pcall(function() actualizarLista() end)
			tryCompleteAction("open_retar")
		end
	elseif step.action == "retar_bot" then
		if menuRetos and menuRetos.Visible then
			pcall(function() actualizarLista() end)
		end
	elseif step.action == "xp_gain" then
		local ls = player:FindFirstChild("leaderstats")
		local xpv = ls and ls:FindFirstChild("XP")
		if xpv and tutorialXpStart ~= nil and xpv.Value > tutorialXpStart then
			tryCompleteAction("xp_gain")
		end
	end
end

local function openTutorial()
	if tutorialActive then return end
	if Config.TUTORIAL and Config.TUTORIAL.Enabled == false then return end
	tutorialActive = true
	tutorialStep = 1
	tutorialWaiting = false
	tutorialDailyOk = false
	if TutorialAction then
		pcall(function() TutorialAction:FireServer("started") end)
	end

	local overlay = Instance.new("Frame")
	overlay.Name = "TutorialOverlay"
	overlay.Size = UDim2.new(0, 380, 0, 0)
	overlay.AutomaticSize = Enum.AutomaticSize.Y
	overlay.Position = UDim2.new(0.5, -190, 0.72, 0)
	overlay.AnchorPoint = Vector2.new(0, 0)
	overlay.BackgroundColor3 = TEMA.fondoOscuro
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 200
	overlay.Parent = screenGui
	tutorialRoot = overlay
	Instance.new("UICorner", overlay).CornerRadius = UDim.new(0, 12)
	local stroke = Instance.new("UIStroke")
	stroke.Color = TEMA.oro
	stroke.Thickness = 2
	stroke.Parent = overlay
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 12)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.Parent = overlay

	local uiscale = Instance.new("UIScale")
	uiscale.Parent = overlay
	local function fit()
		local cam = workspace.CurrentCamera
		local vs = cam and cam.ViewportSize or Vector2.new(1280, 720)
		uiscale.Scale = math.clamp(math.min(vs.X / 400, vs.Y / 500), 0.75, 1.1)
		overlay.Position = UDim2.new(0.5, -190 * uiscale.Scale, 0.70, 0)
	end
	fit()
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 40)
	top.BackgroundTransparency = 1
	top.ZIndex = 201
	top.Parent = overlay

	local iconBg = Instance.new("Frame")
	iconBg.Size = UDim2.new(0, 36, 0, 36)
	iconBg.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	iconBg.ZIndex = 201
	iconBg.Parent = top
	Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)
	local stepIcon = Instance.new("ImageLabel")
	stepIcon.Name = "StepIcon"
	stepIcon.Size = UDim2.new(0, 24, 0, 24)
	stepIcon.Position = UDim2.new(0.5, -12, 0.5, -12)
	stepIcon.BackgroundTransparency = 1
	stepIcon.ScaleType = Enum.ScaleType.Fit
	stepIcon.ZIndex = 202
	stepIcon.Parent = iconBg

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -100, 1, 0)
	title.Position = UDim2.new(0, 44, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 15
	title.TextColor3 = TEMA.oro
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextWrapped = true
	title.ZIndex = 201
	title.Parent = top

	local progress = Instance.new("TextLabel")
	progress.Name = "Progress"
	progress.Size = UDim2.new(0, 50, 0, 18)
	progress.Position = UDim2.new(1, -50, 0, 4)
	progress.BackgroundTransparency = 1
	progress.Font = Enum.Font.GothamBold
	progress.TextSize = 11
	progress.TextColor3 = TEMA.muted
	progress.ZIndex = 201
	progress.Parent = top

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Position = UDim2.new(0, 0, 0, 44)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextColor3 = TEMA.texto
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.ZIndex = 201
	body.Parent = overlay

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, 0, 0, 16)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 12
	hint.TextColor3 = TEMA.oro
	hint.ZIndex = 201
	hint.Parent = overlay

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.Size = UDim2.new(1, 0, 0, 34)
	buttons.BackgroundTransparency = 1
	buttons.ZIndex = 201
	buttons.Parent = overlay
	local blay = Instance.new("UIListLayout")
	blay.FillDirection = Enum.FillDirection.Horizontal
	blay.HorizontalAlignment = Enum.HorizontalAlignment.Right
	blay.Padding = UDim.new(0, 8)
	blay.Parent = buttons

	-- order: body, hint, buttons using list on overlay
	local olay = Instance.new("UIListLayout")
	olay.Padding = UDim.new(0, 8)
	olay.SortOrder = Enum.SortOrder.LayoutOrder
	olay.Parent = overlay
	top.LayoutOrder = 1
	body.LayoutOrder = 2
	hint.LayoutOrder = 3
	buttons.LayoutOrder = 4
	body.Position = UDim2.new(0, 0, 0, 0)
	hint.Size = UDim2.new(1, 0, 0, 16)

	local skipBtn = Instance.new("TextButton")
	skipBtn.Name = "SkipBtn"
	skipBtn.Size = UDim2.new(0, 90, 0, 32)
	skipBtn.BackgroundColor3 = Color3.fromRGB(50, 52, 64)
	skipBtn.Font = Enum.Font.GothamBold
	skipBtn.TextSize = 13
	skipBtn.TextColor3 = TEMA.texto
	skipBtn.Text = "Omitir"
	skipBtn.ZIndex = 202
	skipBtn.LayoutOrder = 1
	skipBtn.Parent = buttons
	Instance.new("UICorner", skipBtn).CornerRadius = UDim.new(0, 8)
	skipBtn.MouseButton1Click:Connect(function()
		finishTutorial("skip")
	end)

	local nextBtn = Instance.new("TextButton")
	nextBtn.Name = "NextBtn"
	nextBtn.Size = UDim2.new(0, 110, 0, 32)
	nextBtn.BackgroundColor3 = TEMA.oro
	nextBtn.Font = Enum.Font.GothamBlack
	nextBtn.TextSize = 13
	nextBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
	nextBtn.Text = "Siguiente"
	nextBtn.ZIndex = 202
	nextBtn.LayoutOrder = 2
	nextBtn.Parent = buttons
	Instance.new("UICorner", nextBtn).CornerRadius = UDim.new(0, 8)
	nextBtn.MouseButton1Click:Connect(function()
		local step = getStep()
		if step and step.kind == "action" then return end
		advanceTutorial()
	end)

	updateTutorialCard()
	tutorialPulse = task.spawn(function()
		while tutorialActive do
			pollTutorialActions()
			task.wait(0.35)
		end
	end)
end

if NotificarCliente then
	NotificarCliente.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		if data.tipo == "anclado" then
			tryCompleteAction("anclar")
			if tutorialActive then
				local step = getStep()
				if step and step.action == "xp_gain" then
					local ls = player:FindFirstChild("leaderstats")
					local xpv = ls and ls:FindFirstChild("XP")
					tutorialXpStart = xpv and xpv.Value or 0
				end
			end
		elseif data.tipo == "exito" and data.mensaje and string.find(data.mensaje, "Daily") then
			tutorialDailyOk = true
			tryCompleteAction("claim_daily")
		end
	end)
end

if SyncDaily then
	SyncDaily.OnClientEvent:Connect(function(data)
		if typeof(data) == "table" and data.canClaim == false and tutorialActive then
			-- ya reclamado hoy: permitir pasar claim
			tutorialDailyOk = true
		end
	end)
end

if IniciarMinijuego then
	IniciarMinijuego.OnClientEvent:Connect(function()
		tryCompleteAction("retar_bot")
	end)
end

if TutorialSync then
	TutorialSync.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" then return end
		if data.show == true then
			task.defer(openTutorial)
		else
			destroyTutorial()
		end
	end)
end



-- Garantizar botón Estadísticas visible
do
	local side = screenGui:FindFirstChild("SideButtons")
	local existing = side and side:FindFirstChild("BtnStats")
	if side and not existing then
		local b = Instance.new("ImageButton")
		b.Name = "BtnStats"
		b.Size = UDim2.new(0, 52, 0, 52)
		b.BackgroundColor3 = Color3.fromRGB(22, 36, 42)
		b.LayoutOrder = 4
		b.ZIndex = 16
		b.Image = normalizeAsset(ICONS.stats or ICONS.estrella)
		b.ScaleType = Enum.ScaleType.Fit
		b.Parent = side
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(80, 200, 220)
		st.Thickness = 2.5
		st.Parent = b
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 11)
		pad.PaddingBottom = UDim.new(0, 11)
		pad.PaddingLeft = UDim.new(0, 11)
		pad.PaddingRight = UDim.new(0, 11)
		pad.Parent = b
		existing = b
		print("[AuraUI] BtnStats creado en fallback")
	end
	if existing and not existing:GetAttribute("StatsBound") then
		existing:SetAttribute("StatsBound", true)
		existing.MouseButton1Click:Connect(function()
			local so = screenGui:FindFirstChild("MenuStats")
			if so then
				so.Visible = not so.Visible
				if so.Visible then
					menuTienda.Visible = false
					menuRetos.Visible = false
					if dailyFrame then dailyFrame.Visible = false end
					pcall(function()
						if actualizarStats then actualizarStats() end
					end)
				end
			else
				warn("[AuraUI] MenuStats no existe aún")
			end
		end)
		print("[AuraUI] BtnStats conectado")
	end
end

print("[AuraUI] Cliente cargado completamente")


end
setupTutorial()

local function setupExpulsionUI()
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
expTitle.Text = "Te han anclado"
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
expDineroBox.PlaceholderText = "Cantidad de monedas"
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
local defensaOverlayClickConn = nil
local defensaOverlayDownConn = nil
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
	if defensaOverlayClickConn then
		defensaOverlayClickConn:Disconnect()
		defensaOverlayClickConn = nil
	end
	if defensaOverlayDownConn then
		defensaOverlayDownConn:Disconnect()
		defensaOverlayDownConn = nil
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

	defensaOverlayClickConn = defOverlay.MouseButton1Click:Connect(registrarClickDefensa)
	defensaOverlayDownConn = defOverlay.MouseButton1Down:Connect(registrarClickDefensa)

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
				expTitle.Text = (data.quien or "?") .. " anclado"
				expDineroBox.Visible = true
				expBtnIntentar.Visible = true
				expFrame.Size = UDim2.new(0, 340, 0, 120)
				local full = data.dineroParaFull or "?"
				expSub.Text = string.format("~%s monedas = prob máx  |  defensa -%.0f%%", tostring(full), (data.reduccionMax or 0.35) * 100)
			elseif expFase == "batalla" then
				expTitle.Text = string.format("BATALLA %.1fs", data.tiempoRestante or 0)
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

end
setupExpulsionUI()

local function setupDailyUI()
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
			local so = screenGui:FindFirstChild("MenuStats")
			if so then so.Visible = false end
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

end
setupDailyUI()

local function setupPromoUI()
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
promoTitle.Text = "Oferta especial"
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
	promoTitle.Text = (track.titulo or "Oferta")
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
			promoTitle.Text = data.titulo or (esRebirth and "REBIRTH" or "Oferta")
			local razon = data.razon and (" · " .. data.razon) or ""
			if esRebirth then
				promoDesc.Text = (data.label or "Reinicia con ventajas") .. razon
				promoBuy.Text = "HACER REBIRTH"
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
end
setupPromoUI()

