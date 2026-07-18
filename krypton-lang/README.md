# Krypton Compiler Core Wallpaper

A native interactive Windows wallpaper authored in Krypton. It attaches its
own Win32 window behind the Explorer desktop icons and renders the scene with
GDI. It does not require Lively, Wallpaper Engine, HTML, JavaScript, or a web
runtime.

## What it does

- Animates a Krypton compiler reactor, source view, and native compilation
  pipeline.
- Reacts to the pointer without intercepting desktop icon input.
- Converts desktop clicks into visible compile-energy shockwaves.
- Spans the Windows virtual desktop and responds to display changes.
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

Set it as the wallpaper:

```powershell
.\dist\krypton-wallpaper.exe
```

Stop it cleanly:

```powershell
.\dist\krypton-wallpaper-stop.exe
```

Starting another copy also closes and replaces the running copy.

## Recovery

If Explorer restarts, run `krypton-wallpaper.exe` again so the window can
attach to Explorer's new WorkerW. If the stop utility cannot find the window,
end `krypton-wallpaper.exe` from Task Manager.

## Planned settings

The runtime currently centers a maximum 1920-pixel scene stage inside the full
desktop host. A later settings layer should expose:

- target display (`primary`, a selected display, or the full virtual desktop)
- horizontal and vertical scene offsets
- scene width and UI scale
- frame rate and animation speed
- particle density, parallax strength, and click-energy strength
- color palette and reduced-motion mode
## Current scope

This first native layer uses GDI so it can be compiled and verified against
Krypton's current Windows backend. Its host, lifecycle, pointer interaction,
and scene engine are reusable. The next rendering backend can replace GDI with
OpenGL while keeping the wallpaper host and scene API in Krypton.

