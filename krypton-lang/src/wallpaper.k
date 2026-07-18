// wallpaper.k — Krypton Compiler Core interactive desktop wallpaper.
// Build with ../build.ps1, then run dist/krypton-wallpaper.exe.

import "../runtime/wallpaper_host_native.k"

let WALLPAPER_CLASS = "KryptonWallpaperClass"

func sceneCodeLine(index) {
    if index == 0 { emit "jxt" }
    if index == 1 { emit "inc \"stdlib/math_utils.k\"" }
    if index == 2 { emit "" }
    if index == 3 { emit "func compile(source) {" }
    if index == 4 { emit "    let ir = tokenize(source)" }
    if index == 5 { emit "    emit optimize(ir)" }
    if index == 6 { emit "}" }
    if index == 7 { emit "" }
    if index == 8 { emit "just run {" }
    if index == 9 { emit "    kp(compile(\"Krypton\"))" }
    emit "}"
}

func sceneInit(state) {
    if wpGet(state, 104) == "1" { emit "1" }

    // Brushes: bg, bg-band, panel, panel-active, cyan, magenta, white.
    wpSet(state, 112, CreateSolidBrush(wpRgb(2, 7, 13) + ""))
    wpSet(state, 120, CreateSolidBrush(wpRgb(4, 14, 23) + ""))
    wpSet(state, 128, CreateSolidBrush(wpRgb(6, 22, 32) + ""))
    wpSet(state, 136, CreateSolidBrush(wpRgb(10, 45, 57) + ""))
    wpSet(state, 144, CreateSolidBrush(wpRgb(0, 228, 255) + ""))
    wpSet(state, 152, CreateSolidBrush(wpRgb(255, 34, 116) + ""))
    wpSet(state, 160, CreateSolidBrush(wpRgb(222, 248, 255) + ""))

    // Pens: grid, cyan thin, cyan thick, magenta, dim.
    wpSet(state, 168, CreatePen("0", "1", wpRgb(8, 37, 48) + ""))
    wpSet(state, 176, CreatePen("0", "1", wpRgb(0, 175, 206) + ""))
    wpSet(state, 184, CreatePen("0", "5", wpRgb(0, 228, 255) + ""))
    wpSet(state, 192, CreatePen("0", "2", wpRgb(255, 34, 116) + ""))
    wpSet(state, 200, CreatePen("0", "1", wpRgb(38, 83, 96) + ""))

    // Fonts: title, heading, code, micro.
    wpSet(state, 208, wpCreateFont("Consolas", -34, 700))
    wpSet(state, 216, wpCreateFont("Consolas", -19, 700))
    wpSet(state, 224, wpCreateFont("Consolas", -16, 400))
    wpSet(state, 232, wpCreateFont("Consolas", -13, 400))
    wpSet(state, 240, GetStockObject("5")) // NULL_BRUSH
    wpSet(state, 104, "1")
    emit "1"
}

func sceneNode(hdc, state, x, y, width, label, active) {
    let brush = wpGet(state, 128)
    let pen = wpGet(state, 200)
    let color = wpRgb(92, 149, 162)
    if active == "1" {
        brush = wpGet(state, 136)
        pen = wpGet(state, 176)
        color = wpRgb(0, 228, 255)
    }
    wpBox(hdc, pen, brush, x, y, width, 44)
    wpText(hdc, wpGet(state, 224), color, x + 14, y + 13, label)
    emit "1"
}

func sceneRender(hdc, state) {
    sceneInit(state)
    wpRefreshSize(wpGet(state, 0), state)
    let width = toInt(wpGet(state, 16))
    let height = toInt(wpGet(state, 24))
    let tick = toInt(wpGet(state, 8))
    let mouseX = toInt(wpGet(state, 32))
    let mouseY = toInt(wpGet(state, 40))
    let energy = toInt(wpGet(state, 96))

    // Keep the UI composition centered on very wide and multi-monitor
    // desktops. The animated background still fills the complete host.
    let stageWidth = width
    if stageWidth > 1920 { stageWidth = 1920 }
    let stageX = (width - stageWidth) / 2
    let stageCenterX = stageX + stageWidth / 2

    let bg = wpGet(state, 112)
    let band = wpGet(state, 120)
    let cyan = wpGet(state, 144)
    let magenta = wpGet(state, 152)
    let white = wpGet(state, 160)
    let gridPen = wpGet(state, 168)
    let cyanPen = wpGet(state, 176)
    let corePen = wpGet(state, 184)
    let magentaPen = wpGet(state, 192)
    let dimPen = wpGet(state, 200)
    let hollow = wpGet(state, 240)

    wpFill(hdc, state, 0, 0, width, height, bg)
    wpFill(hdc, state, 0, height * 2 / 3, width, height / 3 + 1, band)

    // Scrolling perspective-neutral grid.
    let gridOffsetX = (tick / 2) - ((tick / 2) / 64) * 64
    let gx = 0 - 64 + gridOffsetX
    while gx < width + 64 {
        wpLine(hdc, gridPen, gx, 0, gx, height)
        gx += 64
    }
    let gridOffsetY = tick - (tick / 64) * 64
    let gy = 0 - 64 + gridOffsetY
    while gy < height + 64 {
        wpLine(hdc, gridPen, 0, gy, width, gy)
        gy += 64
    }

    // Pointer-reactive data particles. Every point is deterministic, so the
    // scene has no mutable particle array and stays friendly to the GC.
    let p = 0
    while p < 52 {
        let speed = 1 + (p - (p / 4) * 4)
        let px = (p * 173 + tick * speed) - ((p * 173 + tick * speed) / width) * width
        let rawY = p * p * 31 + tick * (1 + (p - (p / 3) * 3))
        let py = rawY - (rawY / height) * height
        let nearX = mouseX - px
        let nearY = mouseY - py
        if nearX > -180 && nearX < 180 && nearY > -180 && nearY < 180 {
            px += nearX / 7
            py += nearY / 7
        }
        let size = 2 + (p - (p / 3) * 3)
        let particleBrush = cyan
        if p - (p / 7) * 7 == 0 { particleBrush = magenta }
        wpFill(hdc, state, px, py, size, size, particleBrush)
        p += 1
    }

    // Header and real Krypton source excerpt.
    wpText(hdc, wpGet(state, 208), wpRgb(222, 248, 255), stageX + 54, 42, "KRYPTON // COMPILER CORE")
    wpText(hdc, wpGet(state, 232), wpRgb(48, 126, 145), stageX + 57, 85,
           "SELF-HOSTING  ·  NATIVE PE/ELF/MACH-O  ·  NO C IN THE LOOP")

    let codeX = stageX + 58
    let codeY = 150
    wpBox(hdc, dimPen, wpGet(state, 128), codeX - 20, codeY - 28, 430, 310)
    wpText(hdc, wpGet(state, 216), wpRgb(255, 34, 116), codeX, codeY - 14, "SOURCE.K")
    let line = 0
    while line < 11 {
        let lineColor = wpRgb(94, 164, 176)
        if line == ((tick / 18) - ((tick / 18) / 11) * 11) {
            lineColor = wpRgb(0, 228, 255)
            wpFill(hdc, state, codeX - 8, codeY + line * 23 - 1, 390, 21, wpGet(state, 136))
        }
        let number = line + 1 + ""
        if line < 9 { number = "0" + number }
        wpText(hdc, wpGet(state, 232), wpRgb(38, 94, 108), codeX, codeY + line * 23, number)
        wpText(hdc, wpGet(state, 224), lineColor, codeX + 38, codeY + line * 23, sceneCodeLine(line))
        line += 1
    }

    // The compiler reactor follows the pointer with a restrained parallax.
    let coreX = stageCenterX + (mouseX - stageCenterX) / 30
    let coreY = height * 47 / 100 + (mouseY - height / 2) / 26
    let phase = tick - (tick / 120) * 120
    let wave = phase
    if phase > 60 { wave = 120 - phase }
    wpRing(hdc, dimPen, hollow, coreX, coreY, 104 + wave / 2)
    wpRing(hdc, cyanPen, hollow, coreX, coreY, 78 + wave / 4)
    wpRing(hdc, magentaPen, hollow, coreX, coreY, 54 + energy / 5)
    wpFill(hdc, state, coreX - 30, coreY - 56, 9, 112, cyan)
    wpLine(hdc, corePen, coreX - 18, coreY, coreX + 42, coreY - 55)
    wpLine(hdc, corePen, coreX - 18, coreY, coreX + 45, coreY + 57)
    wpText(hdc, wpGet(state, 216), wpRgb(222, 248, 255), coreX - 54, coreY + 142, "K-CORE ONLINE")
    wpText(hdc, wpGet(state, 232), wpRgb(50, 132, 148), coreX - 65, coreY + 168,
           "CLICK TO INJECT ENERGY")

    // Live compilation pipeline.
    let pipeX = stageX + stageWidth - 330
    let pipeY = 150
    wpText(hdc, wpGet(state, 216), wpRgb(255, 34, 116), pipeX, pipeY - 48, "NATIVE PIPELINE")
    let active = (tick / 24) - ((tick / 24) / 5) * 5
    sceneNode(hdc, state, pipeX, pipeY, 235, "SOURCE .K", (active == 0) + "")
    wpLine(hdc, cyanPen, pipeX + 117, pipeY + 44, pipeX + 117, pipeY + 72)
    sceneNode(hdc, state, pipeX, pipeY + 72, 235, "TOKENIZE", (active == 1) + "")
    wpLine(hdc, cyanPen, pipeX + 117, pipeY + 116, pipeX + 117, pipeY + 144)
    sceneNode(hdc, state, pipeX, pipeY + 144, 235, "KRYPTON IR", (active == 2) + "")
    wpLine(hdc, cyanPen, pipeX + 117, pipeY + 188, pipeX + 117, pipeY + 216)
    sceneNode(hdc, state, pipeX, pipeY + 216, 235, "OPTIMIZE ×6", (active == 3) + "")
    wpLine(hdc, cyanPen, pipeX + 117, pipeY + 260, pipeX + 117, pipeY + 288)
    sceneNode(hdc, state, pipeX, pipeY + 288, 235, "PE64 / NATIVE", (active == 4) + "")

    // A desktop click becomes a visible compile-energy shockwave without
    // intercepting the click from Explorer or desktop icons.
    let clickAge = toInt(wpGet(state, 56))
    if clickAge > 0 {
        let clickX = toInt(wpGet(state, 64))
        let clickY = toInt(wpGet(state, 72))
        wpRing(hdc, magentaPen, hollow, clickX, clickY, 8 + clickAge * 7)
        wpRing(hdc, cyanPen, hollow, clickX, clickY, 2 + clickAge * 4)
    }

    wpText(hdc, wpGet(state, 232), wpRgb(37, 103, 118), stageX + 55, height - 48,
           "KRYPTON WALLPAPER RUNTIME  //  PURE .K  //  WIN32 + GDI")
    wpText(hdc, wpGet(state, 232), wpRgb(37, 103, 118), stageX + stageWidth - 245, height - 48,
           "FRAME " + tick + "  ENERGY " + energy)
    emit "1"
}

func sceneTick(hwnd, state) {
    wpSet(state, 8, toInt(wpGet(state, 8)) + 1)
    wpPollPointer(hwnd, state)

    let clickAge = toInt(wpGet(state, 56))
    if clickAge > 0 {
        clickAge += 1
        if clickAge > 34 { clickAge = 0 }
        wpSet(state, 56, clickAge)
    }
    let energy = toInt(wpGet(state, 96))
    if energy > 0 { wpSet(state, 96, energy - 2) }
    InvalidateRect(hwnd, "0", "0")
    emit "1"
}

func kryptonWallpaperProc(hwnd, message, wParam, lParam) {
    let state = wpState()
    let msg = toInt(message)
    if msg == 15 { // WM_PAINT
        let paint = wpPaintPtr(state)
        let hdc = BeginPaint(hwnd, paint)
        sceneRender(hdc, state)
        EndPaint(hwnd, paint)
        emit "0"
    }
    if msg == 20 { emit "1" } // WM_ERASEBKGND: full scene paint owns bg.
    if msg == 275 { // WM_TIMER
        sceneTick(hwnd, state)
        emit "0"
    }
    if msg == 126 { // WM_DISPLAYCHANGE
        if wpGet(state, 80) != "1" { wpAttachToDesktop(hwnd, state) }
        InvalidateRect(hwnd, "0", "0")
        emit "0"
    }
    if msg == 16 { // WM_CLOSE
        KillTimer(hwnd, "1")
        DestroyWindow(hwnd)
        emit "0"
    }
    if msg == 2 { // WM_DESTROY
        PostQuitMessage("0")
        emit "0"
    }
    emit DefWindowProcA(hwnd, message, wParam, lParam)
}

just run {
    let preview = "0"
    if argCount() > 0 {
        if arg(0) == "--preview" { preview = "1" }
    }

    // Starting a second copy replaces the first cleanly.
    let existing = wpFindWallpaperWindow(WALLPAPER_CLASS)
    if existing != "0" {
        SendMessageA(existing, "16", "0", "0")
    }

    wpRegisterClass(WALLPAPER_CLASS, funcptr(kryptonWallpaperProc))
    let hwnd = wpCreateWindow(WALLPAPER_CLASS, "Krypton Compiler Core", preview)
    if hwnd == "0" {
        print("Krypton wallpaper: native window creation failed")
        exit("1")
    }
    sceneInit(wpState())
    print("Krypton wallpaper started: preview=" + preview + " hwnd=" + hwnd +
          " size=" + wpGet(wpState(), 16) + "x" + wpGet(wpState(), 24))
    SetTimer(hwnd, "1", "33", "0")
    wpRunLoop()
}

