# Changelog — Triki Traka Simulator

Formato: entradas nuevas **arriba**.

---

## 2026-10-04 — Tutorial guiado + Estadísticas

### Tutorial
- Bienvenida centrada en el bucle de juego.
- Panel más compacto (altura automática, centrado inferior).
- Tienda: pestañas Poder (clicks) y Movimiento (velocidad Triki Traka / intervalo XP).
- Diario: exige reclamar; al completar → 60 s de protección (`POST_PROTECTION_S`).
- Acciones reales: abrir menús, retar bot nv1, Triki Traka, ver XP.

### Estadísticas
- Nuevo botón lateral y panel `MenuStats`.
- Icono configurable: `Config.ICONS.stats` (placeholder `rbxassetid://0` hasta subir asset).

### Config
- Corregidas inyecciones rotas de `Config.TUTORIAL` en helpers.
- `Config.TUTORIAL.POST_PROTECTION_S = 60`.

---


## 2026-10-04 — Tutorial: retar bots nv1 + guía visual

### Cambiado
- Durante el tutorial, el menú **Retar** lista solo **bots de batalla nivel 1** (no jugadores). Tras completar/omitir, solo **jugadores reales**.
- Paso de acción: retar a un bot nv1 y jugar el minijuego de clics.
- Rebirth sigue siendo **solo explicación** (no hay que hacerlo).
- Marca visual **«Pulsa aquí»** + borde dorado en botones del objetivo (Tienda, Diario, Retar, filas de bot).

### Servidor
- `ctx.iniciarDueloBot` unifica el inicio de duelo vs bot.
- `SolicitarDueloDirecto` acepta nombre de bot (string) solo si el jugador está en tutorial y el bot es nivel 1.

---


## 2026-10-04 — Tutorial interactivo (aprender jugando)

### Cambiado
- El tutorial deja de ser solo texto: **pasos de acción** (abrir Tienda, Diario, Retar, realizar Triki Traka, observar subida de XP) y pasos informativos con destaque visual del HUD.
- No se avanza en pasos de acción con «Siguiente»; solo al **completar el objetivo**.
- **Omitir** sigue disponible y quita restricciones/protección.
- Panel del tutorial anclado abajo (no tapa todo el HUD) para ver consecuencias en vivo.

### Protección (servidor)
- Mientras el tutorial está activo: otros no pueden anclarse al jugador; anti-anclaje temporal; duelos hacia/desde el jugador en tutorial bloqueados.
- Al completar u omitir se limpia `tutorialActive` y la protección larga de tutorial.

### Archivos
- `src/client/init.client.lua` — máquina de pasos interactiva
- `src/server/Mod1.lua` — bloqueo anclar a jugador en tutorial
- `src/server/Mod2.lua` — `started` / `complete` / `skip` + protección
- `src/server/Economy.lua`, `Mod3.lua` — bloqueo duelos en tutorial
- `src/server/Context.lua` — `tutorialActive`

### Limitaciones
- La expulsión se explica en UI sin forzar el minijuego (evitar estados raros).
- No hay playtest en Studio en este entorno.

---

## 2026-10-04 — Tutorial primer jugador + iconos UI

### Añadido
- **Tutorial omitible** para jugadores nuevos (primera sesión).
  - 12 pasos que explican: Triki Traka, XP/niveles, expulsión y defensa, cooldowns, Retar/duelos, bots de batalla vs ambulantes, tienda, escudos/velocidad, diario, Rebirth y Nivel conseguido, rankings y HUD.
  - Botones **Siguiente** / **Omitir**; no bloquea el juego de forma permanente.
  - Persistencia `TutorialDone` en el DataStore del jugador (`AuraData_v1`).
  - Remotes `TutorialSync` (servidor→cliente) y `TutorialAction` (cliente→servidor: `complete` | `skip`).
  - Jugadores con progreso previo (nivel > 1, rebirths, monedas o victorias) **no** reciben el tutorial automáticamente (migración segura).

### Cambiado (UI)
- Sustitución de emojis usados como iconografía visual por **texto** o iconos existentes del proyecto (`Config.ICONS` / `ICONS` cliente):
  - Panel de expulsión: eliminados ⚡ y 💰 en títulos/placeholders.
  - Promos / rebirth UI: eliminados 💎 y ♻️ en títulos y botón «HACER REBIRTH» (el botón de notificación de rebirth ya usaba `ICONS.rebirths`).
  - Mensajes de notificación del servidor: «💰» sustituido por la palabra «monedas» para coherencia en la UI.
- El tutorial usa iconos del set Triki Traka (`estrella`, `anclar`, `multixp`, `desanclar`, `clicks`, `retar`, `bot`, `tienda`, `escudo`, `daily`, `rebirths`, `poder`).

### Archivos modificados
- `src/shared/Config.lua` — `Config.TUTORIAL`
- `src/server/Context.lua` — remotes + `tutorialDone`
- `src/server/Mod1.lua` — guardado `TutorialDone`
- `src/server/Mod2.lua` — sync al unirse + handler complete/skip
- `src/server/Mod3.lua`, `Mod4.lua`, `Economy.lua` — textos de notificación sin emoji de moneda/rebirth donde aplicaba
- `src/client/init.client.lua` — UI tutorial + limpieza de emojis en UI
- `README.md`, `PROJECT_MAP.md`

### Archivos creados
- `CHANGELOG.md` (changelog permanente del juego)

### Compatibilidad
- No se revierten fixes previos de prompts Custom, animaciones, leaderboards OrderedDataStore ni DataStore de progreso.
- El esquema DataStore solo **añade** la clave opcional `TutorialDone`; el resto de campos se preserva vía `UpdateAsync`.
- Si falla DataStore al guardar el tutorial, el cliente igual cierra la UI; el servidor reintentará en autosave/salida.

### Limitaciones
- No se pudo ejecutar playtest en Roblox Studio desde este entorno; validación estática del cableado client/server.
- Los logs de depuración del servidor pueden seguir usando símbolos en `print` de recomendaciones (no son UI).

---
