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
system and graphics boundary. The custom Krypton PE backend in `toolchain/`
adds the small API surface needed by the wallpaper.

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

The build is self-hosted: the installed Krypton compiler compiles the modified
Krypton PE backend, then that backend compiles the wallpaper and stop utility.

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

## Current scope

This first native layer uses GDI so it can be compiled and verified against
Krypton's current Windows backend. Its host, lifecycle, pointer interaction,
and scene engine are reusable. The next rendering backend can replace GDI with
OpenGL while keeping the wallpaper host and scene API in Krypton.

