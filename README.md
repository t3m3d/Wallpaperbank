# Cerebral Desktop

Cerebral Desktop is a set of independent Windows desktop components that work
together as one environment. Each component owns one clear layer and can be
developed in its own repository without coupling the whole desktop to a single
process.

## Repository map

- `Wallpaperbank/krypton-lang/` contains the current Krypton visual component:
  source, pure-Krypton Win32 host, build pipeline, branded background asset,
  live overlay executable, and clean stop utility.
- `Parietal/` will be a separate repository for the global menu and status
  AppBar.

Keeping these as separate repositories lets Cerebral Desktop replace or
restart one layer without destabilizing the others.

## Components

### Krypton visual layer

The visual foundation currently has two parts:

- `krypton-lang/assets/krypton-lang-by-kryptonbytes-2560x1440.png` is the
  static **Krypton-Lang by KryptonBytes** background.
- `krypton-lang/dist/krypton-wallpaper.exe` is the live Krypton-authored
  overlay. It renders the compiler source view, reactor, native pipeline, and
  pointer-reactive particles.

The live window is layered, non-activating, and click-through. It does not own
menus, the clock, the system tray, or application input. Its empty background
is color-key transparent so the static KryptonBytes artwork remains visible.

The current test target is the horizontal secondary display at 2560x1440. The
overlay uses its 2560x1392 work area, excluding the 48-pixel bottom taskbar.
Those coordinates are temporary implementation settings and will be replaced
by dynamic monitor and work-area discovery.

### Parietal

**Parietal** is the planned global status and menu bar. The name reflects the
parietal lobe's role in spatial integration and awareness.

Parietal will provide:

- a global application menu
- active-application and workspace status
- a clock
- system-tray access
- future Cerebral Desktop indicators and controls

Parietal should be an interactive, topmost Windows AppBar that reserves a strip
at the top of its selected monitor. It must remain a separate process from the
wallpaper so a bar restart cannot take down the visual layer.

## Desktop layering contract

From back to front, the intended order is:

1. Windows static wallpaper
2. Krypton interactive wallpaper overlay
3. normal application windows
4. Parietal AppBar

The Krypton overlay is click-through and must never cover reserved system UI.
Parietal is interactive and owns only its reserved top strip. The Windows
taskbar continues to own its existing reserved edge unless a future Cerebral
Desktop component deliberately replaces it.

## Work-area integration

Parietal and the Krypton layer will coordinate through the Windows work area:

1. Parietal registers an AppBar and reserves its configured height.
2. Windows publishes the reduced monitor work area.
3. Krypton reads the selected monitor's bounds and current work area.
4. Krypton positions and scales its scene inside that remaining rectangle.
5. Display, DPI, taskbar, orientation, and AppBar changes trigger a fresh
   layout calculation.

This removes hard-coded offsets and lets Parietal change height or move between
monitors without overlapping the wallpaper composition.

## Shared conventions

The components should share only small, stable contracts:

- monitor identity and work-area geometry come from Windows
- theme tokens use the Krypton palette: near-black, deep navy, electric cyan,
  restrained magenta, and cool white
- optional cross-component state should use a local named pipe or a small
  versioned configuration file
- every window declares its z-order, input, activation, and reserved-area
  behavior explicitly
- each component remains independently startable, stoppable, and recoverable

## Current status

- The branded 2560x1440 KryptonBytes background is generated and installed on
  the secondary display only.
- The live Krypton scene is centered on the secondary display, the full-screen
  grid has been removed, and the overlay stops above the bottom taskbar.
- Parietal is the next component and should begin as a top AppBar with a global
  menu, status area, clock, and tray.
- Dynamic monitor/work-area discovery is the next integration change needed in
  the Krypton runtime before Parietal is considered fully integrated.

The `Wallpaperbank/krypton-lang/` component's build and run instructions are
in [`krypton-lang/README.md`](krypton-lang/README.md).
