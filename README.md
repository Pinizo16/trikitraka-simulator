<div align="center">

# TRIKI TRAKA SIMULATOR

### Roblox multiplayer simulator built with Luau and Rojo

[![Roblox](https://img.shields.io/badge/ROBLOX-000000?style=for-the-badge&logo=roblox&logoColor=white)](https://www.roblox.com/es/games/76410005427046/)
[![Luau](https://img.shields.io/badge/LUAU-00A2FF?style=for-the-badge&logo=lua&logoColor=white)](https://luau.org/)
[![Rojo](https://img.shields.io/badge/ROJO-7.7.0-B7410E?style=for-the-badge)](https://rojo.space/)
[![GitHub](https://img.shields.io/badge/GITHUB-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/Pinizo16/trikitraka-simulator)

[Play Triki Traka Simulator](https://www.roblox.com/es/games/76410005427046/)

</div>

---

## Languages

**English** | [Español](#español)

# English

## Overview

**Triki Traka Simulator** is a Roblox multiplayer game focused on player interaction, progression, click-based competition and an in-game economy.

The central interaction is **Present Yourself**. A player can get behind another player, gain XP over time and put the target in a position where they can spend coins to attempt an expulsion.

The current codebase also contains PvP duels, battle bots, roaming bots, daily rewards, upgrades, Rebirths, Robux products, contextual recommendations and global leaderboards.

> This README documents the current repository state and configuration.

## How the Game Works

The main progression loop is:

```text
Earn XP
  |
  v
Level up
  |
  +----> Buy upgrades
  |
  +----> Challenge players or bots
  |
  +----> Use Present Yourself
  |
  +----> Reach the Rebirth requirement
                |
                v
             Rebirth
                |
                v
      Permanent multipliers
```

## Present Yourself

The English in-game terminology for the core interaction is:

> **Present Yourself**

A custom proximity prompt is placed on another player's back. Activating it places the player behind the target and starts the XP interaction.

While using Present Yourself:

- The attached player is positioned behind the target.
- The attached player's movement is locked.
- The attached player gains XP periodically.
- The target loses XP periodically.
- Each target can have only one attached player.
- A player cannot challenge another player while attached.
- The target can attempt an expulsion.
- After an expulsion, a cooldown can prevent immediate re-attachment.

### Base values

| System | Current value |
|---|---:|
| XP gained by attached player | +20 |
| XP lost by target | -10 |
| Base XP interval | 1 second |
| Re-attachment cooldown after expulsion | 45 seconds |

Multi XP affects XP gained by the attached player.

XP loss can reduce the target's level, but the level cannot fall below 1.

## Expulsion

The target can try to remove the player currently behind them.

The expulsion system uses:

**Coins**  
The target selects how many coins to spend. More money increases the expulsion probability.

**Defense**  
Once the attempt starts, the attached player gets a **3-second** defense window and can click anywhere on the screen to reduce the expulsion probability.

### Outcomes

**Successful**

- The attached player is released.
- The selected amount of coins is spent.
- The attached player receives the configured re-attachment cooldown.

**Failed**

- The attached player remains.
- The attached player receives **3 seconds of protection** against another expulsion attempt.

## Duels

The game contains player-versus-player and player-versus-bot duels.

### PvP Duels

Players can challenge another player from the **Retar** menu.

```text
Challenge
   |
   v
Accept / Reject
   |
   v
3...2...1
   |
   v
5-second click phase
   |
   v
Result
   |
   v
Coin reward
```

Challenges expire after **12 seconds** if unanswered.

The winner receives:

- The duel win.
- Coins.
- A persistent PvP victory.

Dueling does not award XP.

When both players submit the same number of clicks, the current implementation uses level as the tie-breaker.

### Battle Bots

Battle bots are challengeable directly from the map.

Their custom prompt shows **Retar** and their bot level.

Each bot level has a configured click requirement and coin reward.

Winning a bot duel:

- Gives coins.
- Adds a persistent victory.
- Uses the reward configured for that bot level.
- Can reduce the reward when the bot is below the player's level, subject to the configured minimum reward factor.

## Roaming Bots

Roaming bots are separate from battle bots and are loaded from:

`Workspace/BotsAmbulantes`

They:

- Move around the map autonomously.
- Use randomized movement speeds within the configured range.
- Generate and store a reserve of XP.
- Can be used with Present Yourself.
- Can randomly expel an attached player.
- Have internal bot identifiers.
- Use client-side animation LOD for distant bots.

### Current configuration

| Parameter | Value |
|---|---:|
| XP generated | 1 XP/s |
| Starting XP reserve | 30 |
| Maximum XP reserve | 250 |
| Expulsion check | every 5 seconds |
| Configured expulsion chance | 20% |
| Movement speed range | 10–20 |

When a player uses Present Yourself on a roaming bot, XP is taken from that bot's reserve.

## Progression

The saved profile contains:

`Nivel`, `XP`, `MaxXP`, `Monedas`, `Rebirths`, `Victorias`

and progression values including:

`NivelConseguido`, `ClicksPorClick`, `MultiXP`, `MultiClicks`, `VelocidadAnclaje`, `VelocidadMovimiento`

## Rebirth

The first Rebirth requires **level 7**.

The configured requirements are:

```text
7 → 8 → 10 → 13 → 17 → 22 → 28 → 35 → 43
→ 52 → 62 → 73 → 85 → 98 → 112
```

When a Rebirth is performed:

- Level returns to 1.
- XP returns to its initial value.
- Clicks per click returns to 1.
- Present Yourself speed upgrades reset.
- Movement upgrades reset.
- Rebirth count increases.
- Multi XP increases permanently.
- Multi Clicks increases permanently.
- Coins are not reset.
- **NivelConseguido is not reset.**

## NivelConseguido

**NivelConseguido** is the lifetime level counter, not the current level.

Whenever the current level increases, the increase is added to NivelConseguido.

A Rebirth resets the current level to 1 without reducing this lifetime counter.

```text
Reach a higher level
       |
       v
NivelConseguido increases
       |
       v
     Rebirth
       |
       v
Current level = 1
Lifetime counter remains
```

This value is used by the global **NIVEL CONSEGUIDO** leaderboard.

## Shop

The Shop has five tabs:

| Tab | Contents |
|---|---|
| **Robux** | Developer products |
| **Poder** | Clicks per click and Present Yourself speed |
| **Escudos** | Anti-Present-Yourself protection |
| **Movimiento** | Movement speed |
| **Rebirth** | Rebirth information and action |

### Power

The configured coin upgrades include:

- +1 Click/Click
- +5 Clicks/Click
- +10 Clicks/Click
- Present Yourself -0.1s
- Present Yourself -0.5s
- Present Yourself -1.0s

### Shields

The Shop currently displays:

- 1-minute shield
- 5-minute shield
- 15-minute shield

The configuration also contains a 1-hour Legendary Shield.

### Movement

The configured movement upgrades include:

- +1 Walk
- +3 Walk
- +5 Walk
- +10 Walk

The configured starting WalkSpeed is **16**.

### Dynamic Pricing

Upgrade prices are calculated from player state, including:

- Current level.
- Owned upgrades.
- Rebirth count.

Rebirths provide progressive price reductions.

## Daily Streak

The game has a persistent Daily Streak reward system.

A player can claim one reward per day and continue a streak by claiming on consecutive days.

Rewards can include:

- Coins.
- XP.
- Anti-Present-Yourself protection time on selected streak days.

The current reward table contains entries through **day 14**.

## Global Leaderboards

The project has four global leaderboards using **OrderedDataStore**.

They are shared across servers.

| Leaderboard | Measures |
|---|---|
| **NIVEL CONSEGUIDO** | Lifetime levels accumulated |
| **MONEDAS** | Current coins |
| **REBIRTHS** | Total Rebirths |
| **VICTORIAS PVP** | Persistent PvP victories |

Each board displays up to **10 entries** and is rendered on map Parts with SurfaceGui.

## Robux Products and Recommendations

The game uses Roblox Developer Products for additional progression.

Configured product groups include:

- Coin packs.
- Legendary Shield.
- +50 Clicks/Click.
- Additional Present Yourself speed.
- Additional movement speed.

The game also has contextual recommendations based on session data such as:

- Level stagnation.
- Coin balance.
- Upgrade state.
- Recent Present Yourself activity.
- Recent expulsions.
- Duel results.
- Proximity to a Rebirth requirement.

A recommendation can present a Rebirth action or a selected Robux product. Promotional products use tiers that can progress after purchases.

## Data Persistence

Player data uses Roblox **DataStoreService**.

The main player DataStore is:

`AuraData_v1`

Saved data includes progression, upgrades and Daily Streak state.

Automatic saving is configured every **60 seconds**, with forced saves on important actions such as Daily claims and Rebirths.

## Interface

The client interface is built as **Trike Arcade**.

| Visual token | Value |
|---|---|
| Main background | `#12141C` |
| Surface | `#1E2130` |
| Gold | `#F5C542` |
| Orange | `#FF8A1F` |
| Red | `#E74C3C` |
| Green | `#2ECC71` |
| Purple | `#9B59FF` |
| Cyan | `#3DDCFF` |

The UI uses Gotham/GothamBlack, dark cards, gold strokes, custom icons and custom interaction prompts.

The HUD currently shows level, coins, XP, Rebirths, Multi XP, protection state and the main interaction buttons.

## Screenshots

The repository contains an asset guide in [assets/screenshots/README.md](assets/screenshots/README.md).

The planned gallery is:

| File | Subject |
|---|---|
| `01-overview.png` | Main gameplay and HUD |
| `02-triki-traka-prompt.png` | Present Yourself prompt |
| `03-triki-traka-active.png` | Active Present Yourself interaction |
| `04-expulsion-defense.png` | Expulsion defense screen |
| `05-pvp-duel.png` | PvP duel |
| `06-bot-duel.png` | Battle bot duel |
| `07-shop.png` | Shop |
| `08-daily-reward.png` | Daily Streak |
| `09-rebirth.png` | Rebirth |
| `10-global-leaderboards.png` | Global leaderboards |
| `11-roaming-bots.png` | Roaming bots |

## Gameplay Video

The planned project asset is:

`assets/video/gameplay.mp4`

GitHub supports MP4 uploads. For an inline player in a README, a GitHub-hosted video attachment URL is the reliable option. See [GitHub's documentation](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files) for supported video formats.

## Architecture

The project uses **Rojo 7.7.0** with Aftman.

```text
trikitraka/
|
├── src/
│   ├── shared/
│   │   └── Config.lua
│   │
│   ├── server/
│   │   ├── init.server.lua
│   │   ├── Context.lua
│   │   ├── Mod1.lua
│   │   ├── Mod2.lua
│   │   ├── Mod3.lua
│   │   ├── Mod4.lua
│   │   ├── Economy.lua
│   │   ├── Leaderboards.lua
│   │   ├── Stick.lua
│   │   ├── Safety.lua
│   │   └── ...
│   │
│   ├── client/
│   │   └── init.client.lua
│   │
│   ├── client_extra/
│   │   ├── AnclajeAnim.client.lua
│   │   ├── AnclajeSit.client.lua
│   │   └── AnimLOD.client.lua
│   │
│   ├── character/
│   │   ├── Animate.client.lua
│   │   └── SitForce.client.lua
│   │
│   └── bot/
│       └── BotWalk.lua
│
├── assets/
│   ├── screenshots/
│   │   └── README.md
│   └── video/
│       └── README.md
│
├── default.project.json
├── aftman.toml
├── PROJECT_MAP.md
└── README.md
```

### Server modules

| Module | Main responsibility |
|---|---|
| `Config.lua` | Balance, progression, prices, products, prompts and configuration |
| `Context.lua` | Shared server state and RemoteEvents |
| `Mod1.lua` | Player data, leaderstats, XP, levels, Rebirth and core Present Yourself state |
| `Mod2.lua` | Player lifecycle, prompts, expulsion, purchases and Rebirth |
| `Mod3.lua` | PvP/bot duels, rewards, Daily and product receipts |
| `Mod4.lua` | Contextual recommendations and roaming bots |
| `Leaderboards.lua` | Global OrderedDataStore leaderboards |
| `Safety.lua` | Cleanup, guards and safety checks |

## Development

### Requirements

- Roblox Studio
- Git
- Aftman
- Rojo 7.7.0

### Clone

```bash
git clone https://github.com/Pinizo16/trikitraka-simulator.git
cd trikitraka-simulator
```

### Install Tools

```bash
aftman install
```

### Start Rojo

```bash
rojo serve
```

Then connect the project from Roblox Studio with the Rojo plugin.

## Status

**In active development.**

The codebase, balance and interface are still being iterated.

## Links

- [Play the game](https://www.roblox.com/es/games/76410005427046/)
- [GitHub repository](https://github.com/Pinizo16/trikitraka-simulator)
- [Project map](PROJECT_MAP.md)
- [Screenshot guide](assets/screenshots/README.md)
- [Gameplay video guide](assets/video/README.md)

---

# Español

## Descripción

**Triki Traka Simulator** es un juego multijugador de Roblox centrado en la interacción entre jugadores, la progresión, la competición mediante clics y la economía del juego.

La mecánica central es **Triki Traka por detrás**. Un jugador puede colocarse detrás de otro, ganar XP con el tiempo y poner al objetivo en una situación en la que puede gastar monedas para intentar expulsarlo.

El código actual también incluye duelos PvP, bots de batalla, bots ambulantes, recompensas diarias, mejoras, Rebirths, productos de Robux, recomendaciones contextuales y leaderboards globales.

> Este README documenta el estado actual del repositorio y su configuración.

## Cómo funciona

El ciclo principal de progresión es:

```text
Ganar XP
  |
  v
Subir de nivel
  |
  +----> Comprar mejoras
  |
  +----> Retar jugadores o bots
  |
  +----> Usar Triki Traka por detrás
  |
  +----> Alcanzar el requisito de Rebirth
                |
                v
             Rebirth
                |
                v
      Multiplicadores permanentes
```

## Triki Traka por detrás

La terminología actual en español para la interacción principal es:

> **Triki Traka** — **por detrás**

Un ProximityPrompt personalizado aparece en la espalda de otro jugador. Al activarlo, el jugador se coloca detrás del objetivo y comienza la interacción de XP.

Mientras utiliza Triki Traka por detrás:

- El jugador queda colocado detrás del objetivo.
- Su movimiento queda bloqueado.
- El jugador detrás gana XP periódicamente.
- El objetivo pierde XP periódicamente.
- Cada objetivo solo puede tener un jugador detrás.
- No se puede retar mientras se está detrás de otro jugador.
- El objetivo puede intentar una expulsión.
- Tras una expulsión puede existir un cooldown antes de volver a hacerlo sobre el mismo objetivo.

### Valores base

| Sistema | Valor actual |
|---|---:|
| XP ganada por el jugador detrás | +20 |
| XP perdida por el objetivo | -10 |
| Intervalo base de XP | 1 segundo |
| Cooldown tras una expulsión | 45 segundos |

La Multi XP afecta a la XP ganada.

La pérdida de XP puede reducir el nivel del objetivo, pero no puede bajar de 1.

## Expulsión

El objetivo puede intentar quitarse al jugador que está detrás.

El sistema utiliza:

**Monedas**  
El objetivo decide cuántas monedas gastar. Una cantidad mayor aumenta la probabilidad de expulsión.

**Defensa**  
Cuando empieza el intento, el jugador detrás tiene una ventana de **3 segundos** en la que puede hacer clic en cualquier parte de la pantalla para reducir la probabilidad de expulsión.

### Resultados

**Expulsión exitosa**

- El jugador detrás queda libre.
- Se gastan las monedas seleccionadas.
- Se aplica el cooldown configurado.

**Expulsión fallida**

- El jugador detrás permanece.
- Recibe **3 segundos de protección** contra otro intento.

## Duelos

El juego tiene duelos PvP y duelos contra bots.

### Duelos PvP

Los jugadores pueden retar a otro jugador desde el menú **Retar**.

```text
Retar
  |
  v
Aceptar / Rechazar
  |
  v
3...2...1
  |
  v
5 segundos de clics
  |
  v
Resultado
  |
  v
Recompensa en monedas
```

Los retos caducan tras **12 segundos** si no se responden.

El ganador recibe:

- La victoria del duelo.
- Monedas.
- Una Victoria PvP persistente.

Los duelos no dan XP.

Cuando ambos jugadores hacen la misma cantidad de clics, el nivel se utiliza como desempate.

### Bots de batalla

Los bots de batalla pueden ser retados directamente desde el mapa.

Su prompt personalizado muestra **Retar** y el nivel del bot.

Cada nivel tiene una cantidad de clics necesaria y una recompensa configuradas.

Ganar contra un bot:

- Da monedas.
- Añade una victoria persistente.
- Utiliza la recompensa configurada para ese nivel.
- Puede reducir la recompensa cuando el bot está por debajo del nivel del jugador, según el factor mínimo configurado.

## Bots ambulantes

Los bots ambulantes son independientes de los bots de batalla y se cargan desde:

`Workspace/BotsAmbulantes`

Estos bots:

- Se desplazan automáticamente por el mapa.
- Utilizan velocidades aleatorias dentro del rango configurado.
- Generan y almacenan una reserva de XP.
- Pueden recibir Triki Traka por detrás.
- Pueden expulsar aleatoriamente al jugador que tengan detrás.
- Tienen identificadores internos.
- Utilizan LOD de animaciones en cliente para los bots lejanos.

### Configuración actual

| Parámetro | Valor |
|---|---:|
| XP generada | 1 XP/s |
| Reserva inicial | 30 |
| Reserva máxima | 250 |
| Comprobación de expulsión | cada 5 s |
| Probabilidad configurada | 20% |
| Velocidad de movimiento | 10–20 |

Cuando un jugador usa Triki Traka sobre un bot ambulante, la XP se consume de la reserva de ese bot.

## Progresión

El perfil guardado contiene:

`Nivel`, `XP`, `MaxXP`, `Monedas`, `Rebirths`, `Victorias`

y valores como:

`NivelConseguido`, `ClicksPorClick`, `MultiXP`, `MultiClicks`, `VelocidadAnclaje`, `VelocidadMovimiento`

## Rebirth

El primer Rebirth requiere **nivel 7**.

Los requisitos configurados son:

```text
7 → 8 → 10 → 13 → 17 → 22 → 28 → 35 → 43
→ 52 → 62 → 73 → 85 → 98 → 112
```

Al hacer Rebirth:

- El nivel vuelve a 1.
- La XP vuelve a su valor inicial.
- Clicks por Click vuelve a 1.
- Las mejoras de velocidad de Triki Traka se reinician.
- Las mejoras de movimiento se reinician.
- Aumenta el número de Rebirths.
- Multi XP aumenta permanentemente.
- Multi Clicks aumenta permanentemente.
- Las monedas no se reinician.
- **NivelConseguido no se reinicia.**

## Nivel Conseguido

**Nivel Conseguido** es el contador de niveles acumulados durante toda la vida del jugador, no el nivel actual.

Cada vez que sube el nivel actual, se suma ese aumento a NivelConseguido.

Un Rebirth devuelve el nivel actual a 1 sin reducir este contador.

Este valor se utiliza en el leaderboard global **NIVEL CONSEGUIDO**.

## Tienda

La tienda tiene cinco pestañas:

| Pestaña | Contenido |
|---|---|
| **Robux** | Developer Products |
| **Poder** | Clicks por click y velocidad de Triki Traka |
| **Escudos** | Protección anti-Triki Traka |
| **Movimiento** | Velocidad de movimiento |
| **Rebirth** | Información y acción de Rebirth |

### Poder

Las mejoras de monedas configuradas incluyen:

- +1 Click/Click
- +5 Clicks/Click
- +10 Clicks/Click
- Triki Traka -0.1 s
- Triki Traka -0.5 s
- Triki Traka -1.0 s

### Escudos

La tienda muestra actualmente:

- Escudo 1 minuto
- Escudo 5 minutos
- Escudo 15 minutos

La configuración también contiene un Escudo Legendario de 1 hora.

### Movimiento

Las mejoras configuradas incluyen:

- +1 Walk
- +3 Walk
- +5 Walk
- +10 Walk

La WalkSpeed inicial configurada es **16**.

### Precios dinámicos

El precio de las mejoras depende del estado del jugador, incluyendo:

- Nivel actual.
- Mejoras adquiridas.
- Número de Rebirths.

Los Rebirths proporcionan descuentos progresivos.

## Racha diaria

El juego cuenta con un sistema persistente de **Racha Diaria**.

Se puede reclamar una recompensa al día y mantener la racha reclamando en días consecutivos.

Las recompensas pueden incluir:

- Monedas.
- XP.
- Tiempo de protección anti-Triki Traka en determinados días.

La tabla actual contiene recompensas hasta el **día 14**.

## Leaderboards globales

El proyecto dispone de cuatro leaderboards globales mediante **OrderedDataStore**.

Se comparten entre servidores.

| Leaderboard | Qué mide |
|---|---|
| **NIVEL CONSEGUIDO** | Niveles acumulados durante toda la vida |
| **MONEDAS** | Monedas actuales |
| **REBIRTHS** | Rebirths totales |
| **VICTORIAS PVP** | Victorias PvP persistentes |

Cada tablero muestra hasta **10 posiciones** y se representa sobre Parts del mapa mediante SurfaceGui.

## Productos Robux y recomendaciones

El juego utiliza Developer Products de Roblox.

Los grupos configurados incluyen:

- Packs de monedas.
- Escudo Legendario.
- +50 Clicks/Click.
- Velocidad adicional de Triki Traka.
- Velocidad adicional de movimiento.

También existe un sistema de recomendaciones contextuales basado en datos de sesión como:

- Estancamiento de nivel.
- Dinero disponible.
- Estado de mejoras.
- Actividad reciente de Triki Traka.
- Expulsiones recientes.
- Resultados de duelos.
- Cercanía al requisito de Rebirth.

Una recomendación puede mostrar una acción de Rebirth o un producto Robux seleccionado. Los productos promocionales utilizan tiers.

## Persistencia de datos

Los datos utilizan **DataStoreService** de Roblox.

El DataStore principal es:

`AuraData_v1`

Se guardan datos de progresión, mejoras y estado de la racha diaria.

El guardado automático está configurado cada **60 segundos**, con guardados forzados en acciones importantes como reclamar el Daily y hacer Rebirth.

## Interfaz

La interfaz cliente utiliza **Trike Arcade**.

| Elemento | Valor |
|---|---|
| Fondo principal | `#12141C` |
| Superficie | `#1E2130` |
| Oro | `#F5C542` |
| Naranja | `#FF8A1F` |
| Rojo | `#E74C3C` |
| Verde | `#2ECC71` |
| Morado | `#9B59FF` |
| Cian | `#3DDCFF` |

Utiliza Gotham/GothamBlack, tarjetas oscuras, bordes dorados, iconos personalizados y prompts personalizados.

El HUD muestra nivel, monedas, XP, Rebirths, Multi XP, protección y los botones principales.

## Capturas

El repositorio contiene la guía de assets en [assets/screenshots/README.md](assets/screenshots/README.md).

Archivos exactos:

| Archivo | Contenido |
|---|---|
| `01-overview.png` | Vista general del gameplay y HUD |
| `02-triki-traka-prompt.png` | Prompt de Triki Traka |
| `03-triki-traka-active.png` | Triki Traka por detrás activo |
| `04-expulsion-defense.png` | Defensa de expulsión |
| `05-pvp-duel.png` | Duelo PvP |
| `06-bot-duel.png` | Duelo contra bot |
| `07-shop.png` | Tienda |
| `08-daily-reward.png` | Racha diaria |
| `09-rebirth.png` | Rebirth |
| `10-global-leaderboards.png` | Leaderboards globales |
| `11-roaming-bots.png` | Bots ambulantes |

## Vídeo de gameplay

El asset previsto es:

`assets/video/gameplay.mp4`

GitHub admite vídeos MP4. Para mostrar un reproductor integrado en un README, la opción fiable es utilizar una URL de vídeo alojada por GitHub. Consulta la [documentación de GitHub](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files) sobre formatos de vídeo compatibles.

## Arquitectura

El proyecto utiliza **Rojo 7.7.0** y Aftman.

```text
trikitraka/
|
├── src/
│   ├── shared/
│   │   └── Config.lua
│   │
│   ├── server/
│   │   ├── init.server.lua
│   │   ├── Context.lua
│   │   ├── Mod1.lua
│   │   ├── Mod2.lua
│   │   ├── Mod3.lua
│   │   ├── Mod4.lua
│   │   ├── Economy.lua
│   │   ├── Leaderboards.lua
│   │   ├── Stick.lua
│   │   ├── Safety.lua
│   │   └── ...
│   │
│   ├── client/
│   │   └── init.client.lua
│   │
│   ├── client_extra/
│   │   ├── AnclajeAnim.client.lua
│   │   ├── AnclajeSit.client.lua
│   │   └── AnimLOD.client.lua
│   │
│   ├── character/
│   │   ├── Animate.client.lua
│   │   └── SitForce.client.lua
│   │
│   └── bot/
│       └── BotWalk.lua
│
├── assets/
│   ├── screenshots/
│   │   └── README.md
│   └── video/
│       └── README.md
│
├── default.project.json
├── aftman.toml
├── PROJECT_MAP.md
└── README.md
```

### Módulos del servidor

| Módulo | Responsabilidad principal |
|---|---|
| `Config.lua` | Balance, progresión, precios, productos, prompts y configuración |
| `Context.lua` | Estado compartido y RemoteEvents |
| `Mod1.lua` | Datos, leaderstats, XP, niveles, Rebirth y estado principal de Triki Traka |
| `Mod2.lua` | Ciclo del jugador, prompts, expulsión, compras y Rebirth |
| `Mod3.lua` | Duelos PvP/bots, recompensas, Daily y compras |
| `Mod4.lua` | Recomendaciones contextuales y bots ambulantes |
| `Leaderboards.lua` | Leaderboards globales mediante OrderedDataStore |
| `Safety.lua` | Limpieza, guards y comprobaciones de seguridad |

## Desarrollo

### Requisitos

- Roblox Studio
- Git
- Aftman
- Rojo 7.7.0

### Clonar

```bash
git clone https://github.com/Pinizo16/trikitraka-simulator.git
cd trikitraka-simulator
```

### Instalar herramientas

```bash
aftman install
```

### Iniciar Rojo

```bash
rojo serve
```

Después conecta el proyecto desde Roblox Studio mediante el plugin de Rojo.

## Estado

**En desarrollo activo.**

El código, el balance y la interfaz siguen evolucionando.

## Enlaces

- [Jugar al juego](https://www.roblox.com/es/games/76410005427046/)
- [Repositorio de GitHub](https://github.com/Pinizo16/trikitraka-simulator)
- [Mapa del proyecto](PROJECT_MAP.md)
- [Guía de capturas](assets/screenshots/README.md)
- [Guía del vídeo](assets/video/README.md)

---

<div align="center">

**TRIKI TRAKA SIMULATOR**

Roblox · Luau · Rojo

</div>

## Tutorial (primer jugador)

- **Interactivo**: el jugador abre Tienda, ve pestañas Poder/Movimiento, reclama Diario, reta bot nv1, hace Triki Traka y ve subir la XP.
- **Bienvenida**: explica el bucle de juego (no el tutorial).
- **Omitir**: siempre visible; quita restricciones y protección larga.
- **Protección**: mientras dura, otros no pueden anclarse ni retar al jugador.
- **Diario**: hay que reclamar; al **completar** el tutorial se aplica `Config.TUTORIAL.POST_PROTECTION_S` (60 s) si se reclamó en el tutorial.
- **Retar en tutorial**: solo bots nivel 1; después solo jugadores.
- UI centrada abajo, altura automática (`AutomaticSize`).

Archivos: `init.client.lua` (UI), `Mod2` (estado/protección), `Context` (remotes), `Config.TUTORIAL`.

## Estadísticas

- Botón lateral (icono `Config.ICONS.stats`, sustituible).
- Panel con nivel, XP, monedas, XP/tick e intervalo Triki Traka, clicks, multis, Rebirth, niveles hasta Rebirth, **Nivel conseguido** (histórico), victorias.
- No forma parte del tutorial.
- Actualización periódica mientras el panel está abierto.

