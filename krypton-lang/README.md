# Krypton Compiler Core Wallpaper

A native interactive Windows wallpaper authored in Krypton. It renders a
click-through layered Win32 surface over a static KryptonBytes background with
GDI. It does not require Lively, Wallpaper Engine, HTML, JavaScript, or a web
runtime.

## Cerebral Desktop role

`Wallpaperbank/krypton-lang/` is the visual component of Cerebral Desktop. It
owns only the desktop artwork and ambient interaction layer. It deliberately
does not own application menus, status indicators, the clock, or the system
tray; those belong to the planned **Parietal** AppBar.

The intended layer order is static Windows wallpaper, Krypton overlay, normal
applications, then Parietal. The overlay is non-activating and click-through,
while Parietal will be interactive and reserve a top work-area strip. See the
[Cerebral Desktop README](../README.md) for the complete integration contract.

## What it does

- Animates a Krypton compiler reactor, source view, and native compilation
  pipeline.
- Reacts to the pointer without intercepting desktop icon input.
- Converts desktop clicks into visible compile-energy shockwaves.
- Targets the horizontal secondary display for the current prototype.
- Uses that display's work area so rendering stops above the taskbar.
- Leaves its empty canvas transparent over the KryptonBytes background.
- Runs its window procedure, state management, animation, and drawing logic in
  Krypton.

Windows system DLLs (`kernel32`, `user32`, and `gdi32`) provide the operating
system and graphics boundary. There is no third-party wallpaper engine or C
shim. At build time, the project gives reserved imports in Krypton's stock PE
output the Win32/GDI names needed by the wallpaper.

## Build

Requirements:

- Windows x64
- Krypton 2.4.5 installed at `C:\krypton`, or pass another root

From PowerShell:

```powershell
.\build.ps1
```

For a different installation:

```powershell
.\build.ps1 -KryptonRoot "D:\Krypton"
```

The installed Krypton frontend, optimizer, and native PE backend compile both
programs. `build.ps1` then renames the reserved API imports and marks the main
wallpaper executable as a no-console Windows GUI application. All runtime
behavior, scene logic, interaction, and Win32 hosting remain Krypton-authored.

## Run

Preview in a normal resizable window first:

```powershell
.\dist\krypton-wallpaper.exe --preview
```

Start the live overlay:

```powershell
.\dist\krypton-wallpaper.exe
```

Stop it cleanly:

```powershell
.\dist\krypton-wallpaper-stop.exe
```

Starting another copy also closes and replaces the running copy.

## Recovery

If Explorer or the graphics driver restarts, run `krypton-wallpaper.exe` again.
If the stop utility cannot find the window, end `krypton-wallpaper.exe` from
Task Manager.

## Planned settings

The runtime currently centers a maximum 1920-pixel scene stage inside the
selected secondary display's work area. A later settings layer should expose:

- target display (`primary`, a selected display, or the full virtual desktop)
- dynamic monitor and work-area discovery for Parietal AppBar integration
- horizontal and vertical scene offsets
- scene width and UI scale
- overlay opacity and static-background mode
- frame rate and animation speed
- particle density, parallax strength, and click-energy strength
- color palette and reduced-motion mode

## Current scope

This first native layer uses GDI so it can be compiled and verified against
Krypton's current Windows backend. Its host, lifecycle, pointer interaction,
and scene engine are reusable. The next rendering backend can replace GDI with
OpenGL while keeping the wallpaper host and scene API in Krypton.

