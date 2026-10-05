# PROJECT_MAP — Triki Traka

**Actualizado:** 2026-10-03

## Shared

| Archivo | Rol |
|---------|-----|
| `src/shared/Config.lua` | Balance, tablas de nivel, productos, iconos, prompts |

## Servidor (`src/server/`)

| Archivo | Rol |
|---------|-----|
| `init.server.lua` | Bootstrap: carga módulos en orden |
| `Context.lua` | Estado compartido, remotes, tablas de sesión |
| `Mod1.lua` | DataStore, leaderstats, XP/nivel, anclar/desanclar base |
| `Mod2.lua` | Join, prompts Anclar/bots, expulsión, compras, rebirth |
| `Mod3.lua` | Duelos PvP, EnviarClicks, daily, recomendaciones smart |
| `Mod4.lua` | Bots ambulantes, XP reserva, expulsión bot |
| `Economy.lua` | Economía auxiliar / lógica duplicada de recomendaciones |
| `Stick.lua` | Heartbeat: CFrame pegado detrás del objetivo |
| `ModAnclajePosFix.lua` | Variante/parche de stick (si se carga) |
| `BotAnim.lua` | Anim walk/idle de NPCs (servidor) |
| `SitNoop.lua` | No-op sit (sit lo gestiona cliente) |
| `Diag.lua` | Diagnóstico Motor6D / anim |
| `Safety.lua` | Guards FireClient, cleanup al salir, clamps |
| `ModAuditFix.lua` | Parches de auditoría (cleanup duelos) |
| `Leaderboards.lua` | Rankings en Parts del mapa |

### Orden de carga típico

```
Context → Mod1 → Mod2 → Mod3 → Mod4
→ SitNoop → BotAnim → Stick → Diag → Safety → Leaderboards
```

## Cliente

| Archivo | Rol |
|---------|-----|
| `src/client/init.client.lua` | AuraUI: HUD, tienda, retos, prompts Custom, minijuego, daily, expulsión |
| `src/client_extra/AnimLOD.client.lua` | LOD animaciones (distancia PC/móvil) |
| `src/client_extra/AnclajeSit.client.lua` | Sync sit / atributo Anclado |
| `src/client_extra/AnclajeAnim.client.lua` | Anim de anclaje (si se usa) |

## Character / bots (manual en Studio o Rojo)

| Archivo | Rol |
|---------|-----|
| `src/character/Animate.client.lua` | Animate del personaje |
| `src/character/SitForce.client.lua` | Forzar pose sit |
| `src/bot/BotWalk.lua` | Script walk por modelo de bot |

## Sistemas principales

- **Anclar (Triki Traka):** Prompt Custom → anclar a espalda → XP/tick; 1 anclado por objetivo
- **Retar:** menú jugadores + bots mapa → duelo de clics → monedas
- **Expulsión:** dinero libre → % → defensa 3s clicks
- **Tienda:** pestañas Robux / Poder / Escudos / Movimiento / Rebirth
- **Daily / Rebirth / Promos Robux:** notificaciones + Config

## Rojo

`default.project.json` → Shared, Server, AuraUI, AnclajeSit, AnimLOD, etc.

## Tutorial

| Pieza | Ubicación |
|-------|-----------|
| Estado + remotes | `Context.tutorialDone`, `TutorialSync`, `TutorialAction` |
| Persistencia | `Mod1.guardarDatos` → `TutorialDone` |
| Gate al join | `Mod2` PlayerAdded |
| UI pasos | `client/init.client.lua` |
| Flag | `Config.TUTORIAL` |

Alguien no ha actualizado el proyect map ehh /