-- Leaderboards globales: OrderedDataStore (todos los jugadores) + SurfaceGui
return function(ctx)
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
		NivelConseguido = true,
		Monedas = true,
		Rebirths = true,
		Victorias = true,
	}
	-- Sin debounce (escritura inmediata)
	local IMMEDIATE = {
		NivelConseguido = true,
		Rebirths = true,
		Victorias = true,
	}

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
				print("[Leaderboards] ODS OK:", storeName)
			else
				warn("[Leaderboards] ODS error:", storeName, store)
			end
		end
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

	local function findPart(name)
		if typeof(name) ~= "string" or name == "" then
			return nil
		end
		local p = Workspace:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then
			return p
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
			local old = store:GetAsync(key)
			old = tonumber(old) or 0
			if value >= old then
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
		local part = findPart(def.partName)
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
