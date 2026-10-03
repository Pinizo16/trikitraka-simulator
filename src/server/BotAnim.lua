-- BotAnim.lua
-- Desactivado: las animaciones de bots se reproducen en el cliente (AnimLOD)
-- para poder hacer culling por distancia y ahorrar CPU en el servidor.
return function(ctx)
	print("[BotAnim] desactivado (LOD cliente)")
end
