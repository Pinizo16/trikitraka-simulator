-- init.server.lua  (Bootstrap)
print("[GestionAura] Cargando...")

local function loadMod(ctx, names)
	for _, name in ipairs(names) do
		local m = script:FindFirstChild(name)
		if m then
			require(m)(ctx)
			return name
		end
	end
	warn("[GestionAura] Falta módulo:", table.concat(names, " | "))
	return nil
end

local ok, err = pcall(function()
	local ctx = require(script:WaitForChild("Context"))
	-- Nombres nuevos con fallback a nombres antiguos
	loadMod(ctx, { "Progress", "Mod1" })
	loadMod(ctx, { "Session", "Mod2" })
	loadMod(ctx, { "Economy", "Mod3" })
	loadMod(ctx, { "Ambient", "Mod4" })
	loadMod(ctx, { "SitNoop", "ModSitFix" })
	loadMod(ctx, { "BotAnim", "ModBotAnimFix" })
	loadMod(ctx, { "Stick", "ModAnclajePosFix" })
	loadMod(ctx, { "Diag", "ModAnimDiag" })
	loadMod(ctx, { "Safety", "ModAuditFix" })
	loadMod(ctx, { "Leaderboards" })
end)

if ok then
	print("[GestionAura] Listo.")
else
	warn("[GestionAura] ERROR:", err)
end
