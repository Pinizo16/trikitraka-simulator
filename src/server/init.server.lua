-- Bootstrap: Context + Game unificado
local ok, err = pcall(function()
	local ctx = require(script:WaitForChild("Context"))
	require(script:WaitForChild("Game"))(ctx)
end)

if ok then
	print("[GestionAura] Listo (servidor unificado).")
else
	warn("[GestionAura] ERROR:", err)
end

-- no entiendo el objetivo de este script /