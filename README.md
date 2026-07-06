# GlassPomodoro — GroovinApps//Pomodoro

Pomodoro para macOS con diseño glassmorphism, dial tech, fondo animado temático
(economía, ML, naturaleza) y presets basados en evidencia (25/45/90).

Vive en la barra de menú: cerrá la ventana y sigue corriendo arriba.

## Instalación

### Homebrew (recomendado)

```bash
brew install --cask AndresGM7/tap/glasspomodoro
```

### Manual

Bajá `GlassPomodoro.zip` del último [release](../../releases), descomprimí,
y movė `GlassPomodoro.app` a `/Applications`.

Primera vez: click derecho → Abrir (no está notarizada por Apple).

## Presets (basados en evidencia)

| Preset | Focus | Break | Base |
|--------|-------|-------|------|
| QUICK | 25′ | 5′ | Pomodoro clásico (Cirillo) — tareas con resistencia |
| FLOW | 45′ | 12′ | DeskTime top-10% — estudio y lectura técnica |
| DEEP | 90′ | 20′ | Ciclo ultradiano (Kleitman) — deep work serio |

## Build desde source

```bash
./build_app.sh
open build/GlassPomodoro.app
```

Requiere macOS 14+ y Swift 6 (Command Line Tools alcanza, no hace falta Xcode).

## Stack

Swift 6 + SwiftUI puro. Sin dependencias. `TimelineView` para animaciones a 30fps,
`Canvas` para el grid/partículas/curva de mercado, `MenuBarExtra` para el modo menu bar.
