<!--
  Triki Traka Simulator
  README — basado en el estado real del repositorio
-->

<div align="center">

# ⚡ TRIKI TRAKA SIMULATOR

### Roblox multiplayer simulator — progresión, anclaje, duelos y economía

![Roblox](https://img.shields.io/badge/ROBLOX-000000?style=for-the-badge&logo=roblox&logoColor=white)
![Luau](https://img.shields.io/badge/LUAU-00A2FF?style=for-the-badge&logo=lua&logoColor=white)
![Rojo](https://img.shields.io/badge/ROJO-7.7.0-B7410E?style=for-the-badge)
![GitHub](https://img.shields.io/badge/GITHUB-181717?style=for-the-badge&logo=github&logoColor=white)

**Triki Traka Simulator** es un juego multijugador de Roblox construido en Luau y organizado con Rojo.

[Repositorio](https://github.com/Pinizo16/trikitraka-simulator) · [Reportar un problema](https://github.com/Pinizo16/trikitraka-simulator/issues)

</div>

---

## 📖 Índice

- [🎮 ¿Qué es Triki Traka Simulator?](#-qué-es-triki-traka-simulator)
- [⚡ Cómo se juega](#-cómo-se-juega)
- [🪢 Anclaje](#-anclaje)
- [⚔️ Duelos](#️-duelos)
- [💥 Expulsión](#-expulsión)
- [🤖 Bots](#-bots)
- [📈 Progresión y Rebirth](#-progresión-y-rebirth)
- [🛒 Tienda](#-tienda)
- [🎁 Racha diaria](#-racha-diaria)
- [🏆 Leaderboards globales](#-leaderboards-globales)
- [💾 Datos y persistencia](#-datos-y-persistencia)
- [🖥️ Interfaz](#️-interfaz)
- [🧩 Arquitectura](#-arquitectura)
- [🛠️ Desarrollo](#️-desarrollo)
- [📸 Gameplay y capturas](#-gameplay-y-capturas)
- [🚧 Estado](#-estado)

---

## 🎮 ¿Qué es Triki Traka Simulator?

Triki Traka Simulator mezcla un simulador de progresión con interacción directa entre jugadores.

El núcleo de la experiencia gira alrededor de:

- **Anclar jugadores** para generar XP.
- **Expulsar** a quien te haya anclado.
- **Retar** a otros jugadores o a bots.
- **Ganar monedas** mediante duelos y progresión.
- **Comprar mejoras** de poder, protección y movimiento.
- **Hacer Rebirths** para obtener multiplicadores permanentes.
- Mantener un progreso histórico mediante **Nivel Conseguido**.
- Competir en **rankings globales**, compartidos entre servidores.

> El README describe el código y la configuración presentes actualmente en el repositorio; las mecánicas pueden cambiar durante el desarrollo.

---

## ⚡ Cómo se juega

### 1. Sube de nivel

La XP permite subir de nivel. La cantidad necesaria para el siguiente nivel crece según la tabla de progresión configurada.

La XP obtenida mediante anclaje se ve afectada por el **Multi XP** del jugador.

### 2. Mejora tu personaje

Las monedas permiten comprar mejoras de:

- **Poder** → más Clicks/Click y anclaje más rápido.
- **Escudos** → protección contra el anclaje.
- **Movimiento** → mayor velocidad de carrera.
- **Rebirth** → reinicio con ventajas permanentes.

### 3. Compite

Puedes retar a jugadores desde el menú **RETAR** o enfrentarte a bots del mapa.

---

## 🪢 Anclaje

La mecánica principal del juego es **Triki Traka**.

El jugador utiliza un prompt personalizado en la espalda de otro jugador:

> **Triki Traka** · **por detrás**

Al anclarte:

- Quedas colocado detrás del objetivo.
- Tu velocidad de movimiento queda bloqueada mientras estás anclado.
- Solo puede haber **un jugador anclado por objetivo**.
- El jugador anclado recibe XP periódicamente.
- El objetivo pierde XP periódicamente.
- No puedes iniciar un duelo mientras estás anclado.
- El objetivo puede intentar expulsarte.
- Tras ciertas expulsiones existe un tiempo de espera antes de volver a anclar al mismo objetivo.

### XP del anclaje

Con la configuración actual:

| Acción | Cantidad base |
|---|---:|
| XP del jugador anclado | +20 |
| XP perdida por el objetivo | -10 |
| Intervalo base | 1 s |
| Cooldown tras expulsión | 45 s |

El **Multi XP** puede aumentar la XP obtenida por el jugador.

La pérdida de XP puede hacer que el objetivo baje de nivel. El sistema conserva el nivel mínimo en **1**.

---

## 💥 Expulsión

El objetivo de un anclaje puede intentar expulsar al jugador que tiene detrás.

La expulsión utiliza dos recursos:

**💰 Monedas**  
El objetivo decide cuánto dinero arriesga. Gastar más aumenta la probabilidad de expulsión.

**🖱️ Defensa**  
Cuando comienza la batalla, el jugador anclado tiene una ventana de **3 segundos** para hacer clic y reducir la probabilidad de expulsión.

El sistema calcula la probabilidad según el dinero invertido, la defensa y el nivel del jugador anclado.

### Resultado

**Expulsión exitosa**
- El anclado queda liberado.
- Se aplica el cooldown correspondiente.
- El dinero utilizado se descuenta.

**Expulsión fallida**
- El anclado permanece en su sitio.
- Recibe protección temporal de **3 segundos** contra otro intento.

---

## ⚔️ Duelos

Los duelos están disponibles contra jugadores y bots.

### PvP

Desde **RETAR** puedes seleccionar a otro jugador.

Flujo:

`Reto → Aceptar/Rechazar → Cuenta atrás → Duelo → Resultado`

La solicitud expira tras **12 segundos**.

La batalla incluye:

- Cuenta atrás **3 → 2 → 1**
- **¡YA!**
- **5 segundos** para hacer clic lo más rápido posible
- Resultado final
- Recompensa en monedas para el ganador

El jugador ganador obtiene también una **Victoria PvP** persistente.

En caso de igualdad de clics, el sistema utiliza el **nivel** como desempate.

### Bots de batalla

Los bots del mapa muestran:

> **Retar** · **Nivel N**

Cada nivel de bot tiene una cantidad de clics necesaria definida en la configuración.

Al ganar:

- Obtienes monedas.
- Obtienes una victoria.
- La recompensa depende del nivel del bot.
- Si el bot es considerablemente más débil que el jugador, su recompensa se reduce, con un mínimo configurado del 25% del valor base.

---

## 🤖 Bots

El juego dispone de **BotsAmbulantes** independientes de los bots de batalla.

Se cargan desde:

`Workspace/BotsAmbulantes`

Estos bots:

- Caminan por el mapa.
- Usan velocidades aleatorias dentro del rango configurado.
- Generan una reserva de XP.
- Pueden ser anclados por jugadores.
- Pueden expulsar aleatoriamente a un jugador anclado.
- Utilizan identificadores internos para distinguir cada instancia.
- Reproducen animaciones mediante el sistema **AnimLOD** del cliente.

### Reserva de XP

Configuración actual:

| Parámetro | Valor |
|---|---:|
| Generación | 1 XP/s |
| Reserva inicial | 30 XP |
| Reserva máxima | 250 XP |
| Comprobación de expulsión | cada 5 s |
| Probabilidad configurada | 20% |

Cuando un jugador se ancla a un bot ambulante, la XP se consume de la reserva del bot.

---

## 📈 Progresión y Rebirth

El perfil del jugador guarda, entre otros, estos valores:

`Nivel` · `XP` · `MaxXP` · `Monedas` · `Rebirths` · `Victorias`

Además existen:

`NivelConseguido` · `ClicksPorClick` · `MultiXP` · `MultiClicks` · `VelocidadAnclaje` · `VelocidadMovimiento`

### Rebirth

El primer Rebirth requiere **nivel 7**.

Los siguientes requisitos actuales son:

`7 → 8 → 10 → 13 → 17 → 22 → 28 → 35 → 43 → 52 → 62 → 73 → 85 → 98 → 112`

Al hacer Rebirth:

- El nivel vuelve a **1**.
- La XP vuelve a su valor inicial.
- `ClicksPorClick` vuelve a 1.
- La mejora de velocidad de anclaje se reinicia.
- La mejora de movimiento se reinicia.
- El contador de Rebirths aumenta.
- **Multi XP** aumenta permanentemente.
- **Multi Clicks** aumenta permanentemente.
- **Nivel Conseguido no se reinicia**.
- Las monedas no se reinician por el Rebirth.

Los multiplicadores obtenidos dependen del número de Rebirth realizado.

---

## 🛒 Tienda

La interfaz tiene cinco pestañas:

| Pestaña | Contenido |
|---|---|
| 💎 **Robux** | Productos de monetización |
| ⚡ **Poder** | Clicks/Click + velocidad de anclaje |
| 🛡️ **Escudos** | Protección anti-anclaje |
| 🏃 **Movimiento** | Velocidad de carrera |
| ♻️ **Rebirth** | Reinicio con ventajas permanentes |

### Poder

Incluye mejoras de:

- +1 Click/Click
- +5 Clicks/Click
- +10 Clicks/Click
- Anclaje -0.1 s
- Anclaje -0.5 s
- Anclaje -1.0 s

### Escudos

La tienda muestra:

- Escudo 1 minuto
- Escudo 5 minutos
- Escudo 15 minutos

La configuración también contempla un **Escudo Legendario de 1 hora**.

### Movimiento

La tienda muestra:

- +1 Walk
- +3 Walk
- +5 Walk

La velocidad de movimiento parte de **16 WalkSpeed**.

### Precios dinámicos

Los precios de las mejoras dependen de factores como:

- Nivel del jugador.
- Mejoras que ya posee.
- Número de Rebirths.

Los Rebirths aplican descuentos progresivos en los precios.

---

## 🎁 Racha diaria

El juego incorpora una recompensa diaria persistente.

El sistema:

- Permite una reclamación por día.
- Mantiene una racha si reclamas en días consecutivos.
- Reinicia la racha cuando se rompe la continuidad.
- Guarda la información de la racha.

Las recompensas aumentan conforme avanza la racha e incluyen:

- 💰 Monedas
- ⭐ XP
- 🛡️ Tiempo de protección anti-anclaje en determinados días

La tabla configurada contiene recompensas hasta el **día 14**.

---

## 🏆 Leaderboards globales

Los rankings utilizan **OrderedDataStore**, por lo que no están limitados a los jugadores del servidor actual.

Hay **4 leaderboards globales**:

| Ranking | Qué mide |
|---|---|
| 🥇 **NIVEL CONSEGUIDO** | Niveles alcanzados a lo largo de toda la vida |
| 💰 **MONEDAS** | Monedas actuales |
| ♻️ **REBIRTHS** | Rebirths acumulados |
| ⚔️ **VICTORIAS PVP** | Victorias de duelo acumuladas |

Cada tablero muestra hasta **10 posiciones**.

### Nivel Conseguido

Este valor es diferente del nivel actual.

Cada vez que el jugador sube de nivel, aumenta:

`NivelConseguido += niveles ganados`

Cuando se realiza un Rebirth, el nivel vuelve a 1 pero **NivelConseguido permanece intacto**.

Esto permite medir la progresión total conseguida por un jugador aunque haya realizado múltiples Rebirths.

---

## 💎 Monetización

El juego utiliza **Developer Products** de Roblox.

Actualmente existen productos para:

- Packs de monedas.
- Escudo Legendario.
- +50 Clicks/Click.
- Velocidad adicional de anclaje.
- Velocidad adicional de movimiento.

También existe un sistema de **promociones contextuales**.

Las promociones pueden recomendar diferentes productos según el comportamiento de la sesión, por ejemplo:

- Estancamiento de nivel.
- Falta de monedas.
- Bajo poder por click.
- Pérdidas en duelos.
- Uso frecuente del anclaje.
- Mejoras de movimiento bajas.
- Rebirth disponible.

Las promociones utilizan **tiers** y pueden avanzar al siguiente nivel después de una compra.

---

## 💾 Datos y persistencia

Los datos de jugador se guardan mediante:

`DataStoreService`

DataStore principal:

`AuraData_v1`

El sistema persiste estadísticas de progresión, mejoras y datos de racha diaria.

El guardado automático está configurado cada:

**60 segundos**

También existen guardados forzados en acciones importantes, como la recompensa diaria y el Rebirth.

---

## 🖥️ Interfaz

El cliente utiliza un sistema de UI propio llamado **Trike Arcade**.

### Identidad visual

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

La interfaz utiliza **Gotham / GothamBlack**, tarjetas oscuras, bordes dorados, iconos y paneles personalizados.

### HUD

El HUD principal muestra:

- Nivel.
- Monedas.
- Barra de XP.
- Rebirths.
- Multi XP.
- Protección activa.
- Botones de Retar, Tienda, Daily y acciones relacionadas con el anclaje.

Los prompts de interacción también se renderizan con una interfaz personalizada.

---

## 🧩 Arquitectura

El proyecto está organizado con **Rojo 7.7.0**.

```text
trikitraka/
│
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
├── default.project.json
├── aftman.toml
├── PROJECT_MAP.md
└── README.md
```

### Flujo del servidor

```text
Context
   ↓
Mod1
   ↓
Mod2
   ↓
Mod3
   ↓
Mod4
   ↓
Sistemas auxiliares
   ↓
Leaderboards
```

### Responsabilidades

**Config.lua**  
Balance, tablas de progresión, precios, productos, iconos, prompts y configuración de sistemas.

**Mod1.lua**  
Datos, leaderstats, XP, niveles, Rebirth, anclaje base y estados del jugador.

**Mod2.lua**  
Entrada/salida de jugadores, prompts, expulsión, compras y Rebirth.

**Mod3.lua**  
Duelos PvP/bots, recompensas, daily y monetización.

**Mod4.lua**  
Recomendaciones contextuales y bots ambulantes.

**Leaderboards.lua**  
Rankings globales mediante OrderedDataStore y SurfaceGui.

**init.client.lua**  
HUD, tienda, retos, minijuego, daily, prompts personalizados y UI de expulsión.

---

## 📸 Gameplay y capturas

El repositorio actualmente no contiene todavía capturas ni un GIF de gameplay públicos, por lo que esta sección queda preparada para añadirlos sin enlazar recursos inexistentes.

### 🎬 Gameplay

```text
assets/gameplay.gif
```

### 🖼️ Capturas recomendadas

```text
assets/screenshots/
├── lobby.png
├── gameplay.png
├── shop.png
├── duel.png
├── anchoring.png
└── leaderboards.png
```

Cuando se añadan esos archivos al repositorio, pueden mostrarse directamente aquí:

```html
<div align="center">

<img src="assets/gameplay.gif" width="90%" alt="Gameplay">

</div>
```

---

## 🛠️ Desarrollo

### Requisitos

- Roblox Studio
- Git
- Aftman
- Rojo **7.7.0**

### Clonar

```bash
git clone https://github.com/Pinizo16/trikitraka-simulator.git
cd trikitraka-simulator
```

### Rojo

El proyecto utiliza Aftman para fijar la versión de Rojo.

```bash
aftman install
rojo serve
```

Después conecta Roblox Studio mediante el plugin de Rojo.

### Configuración

La mayoría del balance se controla desde:

`src/shared/Config.lua`

Esto incluye:

- XP.
- Tablas de nivel.
- Rebirth.
- Economía.
- Expulsión.
- Daily.
- Bots.
- Mejoras.
- Productos Robux.
- Promociones.
- Leaderboards.

---

## 🚧 Estado

<div align="center">

![Status](https://img.shields.io/badge/STATUS-IN%20DEVELOPMENT-F5C542?style=for-the-badge)

**Triki Traka Simulator está en desarrollo activo.**

Las mecánicas, el balance y la interfaz pueden cambiar durante el desarrollo.

</div>

---

## 👤 Autor

<div align="center">

### Pinizo

Desarrollado para **Roblox** con **Luau + Rojo**.

[GitHub @Pinizo16](https://github.com/Pinizo16)

</div>

---

<div align="center">

### ⚡ TRIKI TRAKA SIMULATOR

*Ancla. Compite. Progresa. Haz Rebirth.*

</div>
