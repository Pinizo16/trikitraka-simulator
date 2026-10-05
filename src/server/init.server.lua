-- Bootstrap: Context + Game unificado
print("[GestionAura] Cargando...")

local ok, err = pcall(function()
	local ctx = require(script:WaitForChild("Context"))
	require(script:WaitForChild("Game"))(ctx)
end)

if ok then
	print("[GestionAura] Listo (servidor unificado).")
else
	warn("[GestionAura] ERROR:", err)
end
