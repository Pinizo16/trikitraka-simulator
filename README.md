# Triki Traka

Juego multijugador Roblox (Luau): anclaje de auras, duelos de clics y progresión RPG.

## Estructura (Rojo)

- `src/shared/Config.lua` — balance, tablas de nivel, iconos, productos
- `src/server/init.server.lua` — arranque y carga de módulos
- `src/server/Mod1.lua` — datos, anclar/desanclar, leaderstats
- `src/server/Mod2.lua` — prompts Anclar/Retar bots, jugadores, expulsión
- `src/server/Mod3.lua` — duelos PvP, EnviarClicks, recompensas
- `src/server/Mod4.lua` — bots ambulantes
- `src/server/Stick.lua` — posición pegada al anclar
- `src/client/init.client.lua` — HUD, tienda, retos, prompts custom, minijuego

## Anclar (Triki Traka)

- ProximityPrompt **Custom** en la espalda del objetivo (`PromptAnclar`)
- UI cliente: icono + "Triki Traka" / "por detrás" + tecla E
- Activación: `InputHoldBegin`/`InputHoldEnd` (Style Custom no dispara solo)
- El dueño no ve su propio prompt (`TrikiOwned`)
- 1 anclado por objetivo; cooldown tras expulsión; notificación con botón Desanclarse

## Retar

- Menú lateral (icono espadas): lista de jugadores con NV y botón Retar
- Bots de batalla: prompt "Retar" + Nivel N en el mapa
- PvP: solicitud → aceptar/rechazar (12 s) → minijuego 3…2…1 + 5 s de clics
- Feedback: reto enviado, rechazado, expirado
- Resultados: Victoria / Derrota / Empate + monedas (sin XP de duelo)

## UI

Estilo Trike Arcade: fondo oscuro, borde dorado, Gotham, iconos rbxthumb.


## Leaderboards (mapa)

Sistema servidor en `src/server/Leaderboards.lua`.

Configura en `Config.LEADERBOARDS` el nombre de cada **Part** del Workspace:

| partName (default) | Stat |
|--------------------|------|
| `LB_Nivel` | Nivel |
| `LB_XP` | XP actual del ciclo |
| `LB_Monedas` | Monedas |
| `LB_Rebirths` | Rebirths |
| `LB_Victorias` | Victorias de duelo (persistente) |

Coloca Parts con esos nombres en el mapa (la cara **Front** muestra el SurfaceGui).  
No hay leaderboard de “clicks de duelo”: ese valor no se guarda de forma persistente.

## Leaderboards globales

Cuatro rankings compartidos entre **todos los servidores** (OrderedDataStore):

| Tablero | Stat | Part (Workspace) | Qué mide |
|---------|------|------------------|----------|
| Nivel conseguido | `NivelConseguido` | `LB_NivelConseguido` | Niveles alcanzados en toda la vida (no se resetea con rebirth) |
| Monedas | `Monedas` | `LB_Monedas` | Monedas actuales del jugador |
| Rebirths | `Rebirths` | `LB_Rebirths` | Total de rebirths |
| Victorias PvP | `Victorias` | `LB_VictoriasPvP` | Victorias de duelo (servidor) |

Config: `Config.LEADERBOARDS` en `src/shared/Config.lua` (`partName`, `orderedStore`, intervalos).

Módulo: `src/server/Leaderboards.lua` (cargado al final del bootstrap).

**Nivel conseguido:** al subir de nivel (`setStat("Nivel", nuevo)` con valor mayor) se suma la diferencia a `NivelConseguido`. El rebirth pone `Nivel = 1` sin reducir este contador. Jugadores antiguos: `max(guardado, Nivel actual)`.
