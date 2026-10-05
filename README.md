# Triki Traka Simulator

Juego Roblox multijugador: anclaje (Triki Traka), XP, duelos clicker, tienda, rebirths, bots y leaderboards.

## Arquitectura del servidor

Tras la consolidación, el servidor queda en **3 archivos**:

| Archivo | Rol |
|---------|-----|
| `src/server/init.server.lua` | Bootstrap: carga Context + Game |
| `src/server/Context.lua` | Servicios, estado compartido, RemoteEvents, DataStore |
| `src/server/Game.lua` | **Toda la lógica de juego** unificada |

### Secciones internas de `Game.lua`

Cada sección es una **función anidada** (límite de locals de Luau) ejecutada en orden:

0. **Progresión / anclaje / datos / XP** — leaderstats, guardar/cargar, anclar, expulsión base, XP
1. **Anclaje pegado** — Heartbeat de posición detrás del objetivo, NetworkOwner, estados anclado/libre
2. **Sesión** — remotes de sesión, rebirth, tutorial hooks, stats extra (protección)
3. **Duelos / Daily / Robux / Promos** — PvP y bots de batalla, recompensas diarias, ProcessReceipt, recomendaciones de compra
4. **Bots / recomendaciones** — bots ambulantes, setup prompts, motor de recomendaciones
5. **Seguridad** — clamp de stats, cleanup al salir/morir, rate limit, safeFireClient
6. **Leaderboards** — OrderedDataStore + SurfaceGui en Parts del Workspace

### Archivos eliminados (fusionados)

`Mod1`–`Mod4`, `Economy`, `Stick`, `Safety`, `ModAuditFix`, `Leaderboards`, `SitNoop`, `BotAnim`, `Diag`.

Duplicados resueltos: **Economy vs Mod3** → queda lógica tipo Mod3; **Safety vs ModAuditFix** → queda Safety (sin segundo guardado en PlayerRemoving que corrompía PromoTiers).

## Cliente

| Ruta | Rol |
|------|-----|
| `src/client/init.client.lua` | UI principal (AuraUI): tienda, retar, stats, tutorial, expulsión, daily, promos |
| `src/client_extra/AnclajeSit.client.lua` | Animación de sit al anclarse |
| `src/client_extra/AnimLOD.client.lua` | Animaciones de bots con LOD por distancia |
| `src/character/Animate.client.lua` | Animate de personaje (StarterCharacterScripts) |

El cliente organiza UI en funciones `setup*` (retar, tienda, notifs, stats, tutorial, etc.).

**Iconos:** solo `Config.ICONS` (sin tabla duplicada en cliente).

## Shared

`src/shared/Config.lua` — progresión, precios, packs, Robux, leaderboards, tutorial, `Config.DEBUG` para `ctx.log`.

## Remotes principales

SolicitarDueloDirecto, ResponderDuelo, IniciarMinijuego, EnviarClicks, MostrarResultados, DesanclarJugador, ExpulsarAnclado, NotificarCliente, ComprarMejora, HacerRebirth, ExpulsionUpdate/Accion/Defensa, ClaimDaily, SyncDaily, TutorialSync, TutorialAction, PedirStatsExtra, StatsExtra, ReiniciarProgreso.

## Leaderboards (mapa)

Parts en Workspace: `LB_XPTotal` (o `LB_NivelConseguido`), `LB_Monedas`, `LB_Rebirths`, `LB_VictoriasPvP`. Requiere API Services en Studio.

## Debugging

- `Config.DEBUG = true` activa `ctx.log(area, msg, ...)`.
- Secciones de Game.lua numeradas para localizar sistemas al añadir prints.

## Rojo

`default.project.json` mapea `src/server` → ServerScriptService.Server, `src/client` → AuraUI, Shared, Character scripts.


---

## Architecture (unified server)

### Server (3 files)

| File | Role |
|------|------|
| `init.server.lua` | Bootstrap only |
| `Context.lua` | Services, shared state tables, RemoteEvents |
| `Game.lua` | **All gameplay server logic** in ordered sections |

`Game.lua` sections (nested functions for Luau local limits):

0. Progression, Triki Traka, DataStore helpers, XP  
1. Stick (Heartbeat positioning)  
2. Session remotes, Rebirth, tutorial hooks  
3. Duels, Daily, Robux, promos  
4. Bots + recommendations  
5–7. Stubs / diagnostics  
8. Safety (clamp, cleanup, rateLimit) — **must run after core**  
9. Global leaderboards  

### Client

| Path | Role |
|------|------|
| `src/client/init.client.lua` | AuraUI (HUD, shop, stats, tutorial, notifications) |
| `src/client_extra/AnclajeSit.client.lua` | Sit while anchored |
| `src/client_extra/AnimLOD.client.lua` | Bot walk + distance culling |
| `src/character/Animate.client.lua` | Character animate |

### Shared

`Config.lua` — balance, icons, products, `Config.DEBUG`.

### Diagnostics

```lua
Config.DEBUG.Enabled = true
Config.DEBUG.Anclaje = true
```

