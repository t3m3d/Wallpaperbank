// wallpaper_host_native.k — pure-Krypton Win32 wallpaper host.
//
// Krypton's stock Windows PE backend already owns stable user32/gdi32 import
// slots. The build renames a small set of those slots to the APIs below. These
// aliases keep the wallpaper runtime entirely in Krypton without compiling a
// second 620 KB backend or introducing a C bridge.

module wallpaper_host_native

jxt {
    // kernel32.dll
    func GetModuleHandleA(name)
    func GetProcessHeap()
    func HeapAlloc(heap, flags, bytes)
    func GetEnvironmentVariableA(name, buffer, size)
    func SetEnvironmentVariableA(name, value)

    // user32.dll stock slots; renamed in the generated PE by build.ps1.
    func MessageBoxA(a0, a1, a2, a3)                  // -> FindWindowA
    func CreatePopupMenu(a0, a1, a2, a3)             // -> FindWindowExA
    func GetForegroundWindow()
    func SetForegroundWindow(a0, a1, a2)             // -> SetWindowLongPtrA
    func GetWindow(a0, a1)                            // -> SetParent
    func GetWindowTextA(a0, a1, a2)                  // -> BeginPaint
    func SetWindowTextA(a0, a1)                      // -> EndPaint
    func UpdateWindow(a0)                             // -> GetCursorPos
    func SetClassLongPtrA(a0, a1, a2)                // -> ScreenToClient
    func GetSystemMetrics(a0)                         // -> GetAsyncKeyState
    func SetProcessDpiAwarenessContext(a0, a1, a2, a3) // -> SetLayeredWindowAttributes

    // Unchanged user32.dll slots.
    func SendMessageA(hwnd, message, wParam, lParam)
    func SetWindowPos(hwnd, insertAfter, x, y, width, height, flags)
    func RegisterClassExA(windowClass)
    func CreateWindowExA(exStyle, className, title, style, x, y, width, height, parent, menu, instance, param)
    func DefWindowProcA(hwnd, message, wParam, lParam)
    func DestroyWindow(hwnd)
    func PostQuitMessage(exitCode)
    func ShowWindow(hwnd, command)
    func SetTimer(hwnd, id, intervalMs, callback)
    func KillTimer(hwnd, id)
    func InvalidateRect(hwnd, rect, erase)
    func GetClientRect(hwnd, rect)
    func GetMessageA(message, hwnd, filterMin, filterMax)
    func TranslateMessage(message)
    func DispatchMessageA(message)
    func LoadCursorA(instance, cursorName)
    func FillRect(hdc, rect, brush)

    // gdi32.dll slots renamed by build.ps1.
    func CreateFontIndirectA(a0, a1, a2)              // -> CreatePen
    func SetBkColor(a0, a1, a2, a3)                  // -> MoveToEx
    func DeleteObject(a0, a1, a2)                    // -> LineTo

    // Unchanged gdi32.dll slots. GetTextExtentPoint32A becomes TextOutA.
    func GetStockObject(index)
    func CreateSolidBrush(color)
    func SelectObject(hdc, object)
    func SetTextColor(hdc, color)
    func SetBkMode(hdc, mode)
    func GetTextExtentPoint32A(a0, a1, a2, a3, a4)
}

// Descriptive wrappers over the renamed stock import slots.
func FindWindowA(className, windowName) {
    emit MessageBoxA(ptrToInt(className), intToPtr("0"), intToPtr("0"), "0")
}

func FindWindowExA(parent, childAfter, className, windowName) {
    emit CreatePopupMenu(intToPtr(parent), intToPtr(childAfter), className, intToPtr("0"))
}

func SetParent(child, parent) { emit GetWindow(child, parent) }
func SetWindowLongPtrA(hwnd, index, value) {
    emit SetForegroundWindow(hwnd, intToPtr(index + ""), intToPtr(value + ""))
}
func BeginPaint(hwnd, paint) { emit GetWindowTextA(hwnd, paint, "0") }
func EndPaint(hwnd, paint) { emit SetWindowTextA(hwnd, paint) }
func GetCursorPos(point) { emit UpdateWindow(ptrToInt(point)) }
func ScreenToClient(hwnd, point) { emit SetClassLongPtrA(hwnd, ptrToInt(point), "0") }
func GetAsyncKeyState(key) { emit GetSystemMetrics(key) }
func SetLayeredWindowAttributes(hwnd, colorKey, alpha, flags) {
    emit SetProcessDpiAwarenessContext(hwnd, intToPtr(colorKey + ""),
                                       intToPtr(alpha + ""), intToPtr(flags + ""))
}
func TextOutA(hdc, x, y, text, count) {
    emit GetTextExtentPoint32A(hdc, intToPtr(x + ""), y + "", text, intToPtr(count + ""))
}

func CreatePen(style, width, color) {
    emit CreateFontIndirectA(intToPtr(style + ""), intToPtr(width + ""), intToPtr(color + ""))
}
func MoveToEx(hdc, x, y) {
    emit SetBkColor(hdc, x + "", intToPtr(y + ""), intToPtr("0"))
}
func LineTo(hdc, x, y) {
    emit DeleteObject(hdc, intToPtr(x + ""), intToPtr(y + ""))
}

// Raw process-lifetime state. Mutable module globals are deliberately avoided.
//
//   0 hwnd              8 tick             16 width
//  24 height           32 mouse x          40 mouse y
//  48 previous button  56 click age        64 click x
//  72 click y          80 preview flag      88 desktop host
//  96 energy          104 assets-ready     112..248 GDI handles
// 256 RECT scratch    288 POINT scratch    320 PAINTSTRUCT scratch
func wpBufferToString(buffer, maxLen) {
    let out = sbNew()
    let i = 0
    while i < maxLen {
        let b = toInt(bufGetByte(buffer, i))
        if b == 0 { emit sbToString(out) }
        out = sbAppend(out, fromCharCode(b))
        i += 1
    }
    emit sbToString(out)
}

func wpState() {
    let pointerText = bufNew("64")
    let found = GetEnvironmentVariableA("KRYPTON_WALLPAPER_STATE", pointerText, "64")
    if found != "0" { emit intToPtr(wpBufferToString(pointerText, 64)) }
    let state = HeapAlloc(GetProcessHeap(), "8", "1024")
    SetEnvironmentVariableA("KRYPTON_WALLPAPER_STATE", ptrToInt(state))
    emit state
}

func wpGet(state, offset) { emit bufGetQwordAt(state, offset + "") }
func wpSet(state, offset, value) {
    bufSetQwordAt(state, offset + "", value + "")
    emit value
}

func wpRgb(red, green, blue) { emit red + green * 256 + blue * 65536 }
func wpRectPtr(state) { emit intToPtr(ptrAdd(ptrToInt(state), "256")) }
func wpPointPtr(state) { emit intToPtr(ptrAdd(ptrToInt(state), "288")) }
func wpPaintPtr(state) { emit intToPtr(ptrAdd(ptrToInt(state), "320")) }

func wpSetRect(state, left, top, right, bottom) {
    let rect = wpRectPtr(state)
    bufSetDwordAt(rect, "0", left + "")
    bufSetDwordAt(rect, "4", top + "")
    bufSetDwordAt(rect, "8", right + "")
    bufSetDwordAt(rect, "12", bottom + "")
    emit rect
}

func wpFill(hdc, state, x, y, width, height, brush) {
    if width <= 0 || height <= 0 { emit "0" }
    FillRect(hdc, wpSetRect(state, x, y, x + width, y + height), brush)
    emit "1"
}

func wpLine(hdc, pen, x1, y1, x2, y2) {
    SelectObject(hdc, pen)
    MoveToEx(hdc, x1, y1)
    LineTo(hdc, x2, y2)
    emit "1"
}
func wpBox(hdc, border, brush, x, y, width, height) {
    let state = wpState()
    wpFill(hdc, state, x, y, width, height, brush)
    wpFill(hdc, state, x, y, width, 2, border)
    wpFill(hdc, state, x, y + height - 2, width, 2, border)
    wpFill(hdc, state, x, y, 2, height, border)
    wpFill(hdc, state, x + width - 2, y, 2, height, border)
    emit "1"
}

func wpRing(hdc, brush, hollowBrush, centerX, centerY, radius) {
    wpLine(hdc, brush, centerX, centerY - radius, centerX + radius, centerY)
    wpLine(hdc, brush, centerX + radius, centerY, centerX, centerY + radius)
    wpLine(hdc, brush, centerX, centerY + radius, centerX - radius, centerY)
    wpLine(hdc, brush, centerX - radius, centerY, centerX, centerY - radius)
    emit "1"
}

func wpText(hdc, font, color, x, y, text) {
    SelectObject(hdc, font)
    SetBkMode(hdc, "1")
    SetTextColor(hdc, color + "")
    TextOutA(hdc, x, y, text, len(text))
    emit "1"
}

func wpCreateFont(face, height, weight) { emit GetStockObject("17") }

func wpRegisterClass(className, windowProc) {
    setWindowProc(windowProc)
    let instance = GetModuleHandleA("0")
    let wc = bufNew("80")
    let i = 0
    while i < 80 { bufSetByte(wc, i + "", "0")  i += 1 }
    bufSetDwordAt(wc, "0", "80")
    bufSetDwordAt(wc, "4", "3")
    bufSetQwordAt(wc, "8", windowProcAddr())
    bufSetQwordAt(wc, "24", instance)
    bufSetQwordAt(wc, "40", LoadCursorA("0", "32512"))
    bufSetQwordAt(wc, "48", "0") // Scene owns the background paint.
    bufSetQwordAt(wc, "64", ptrToInt(className))
    emit RegisterClassExA(wc)
}

func wpFindDesktopHost() {
    // SHELLDLL_DefView owns the desktop icon list. A bottom-most child of
    // DefView is above its painted background but below SysListView32 icons.
    let state = wpState()
    let rect = wpRectPtr(state)
    let best = "0"
    let bestArea = 0
    let progman = FindWindowA("Progman", "0")
    if progman != "0" {
        let icons = FindWindowExA(progman, "0", "SHELLDLL_DefView", "0")
        if icons != "0" {
            GetClientRect(icons, rect)
            bestArea = toInt(bufGetDwordAt(rect, "8")) * toInt(bufGetDwordAt(rect, "12"))
            best = icons
        }
    }

    let worker = "0"
    let guard = 0
    while guard < 24 {
        worker = FindWindowExA("0", worker, "WorkerW", "0")
        if worker == "0" { guard = 24 }
        if worker != "0" {
            let icons = FindWindowExA(worker, "0", "SHELLDLL_DefView", "0")
            if icons != "0" {
                GetClientRect(icons, rect)
                let area = toInt(bufGetDwordAt(rect, "8")) * toInt(bufGetDwordAt(rect, "12"))
                if area >= bestArea {
                    bestArea = area
                    best = icons
                }
            }
        }
        guard += 1
    }
    if best != "0" { emit best }
    if progman != "0" { emit progman }
    emit "0"
}

func wpFindWallpaperWindow(className) {
    let hwnd = FindWindowA(className, "0")
    if hwnd != "0" { emit hwnd }

    let progman = FindWindowA("Progman", "0")
    if progman != "0" {
        hwnd = FindWindowExA(progman, "0", className, "0")
        if hwnd != "0" { emit hwnd }
        let icons = FindWindowExA(progman, "0", "SHELLDLL_DefView", "0")
        if icons != "0" {
            hwnd = FindWindowExA(icons, "0", className, "0")
            if hwnd != "0" { emit hwnd }
        }
    }

    let worker = "0"
    let guard = 0
    while guard < 24 {
        worker = FindWindowExA("0", worker, "WorkerW", "0")
        if worker == "0" { guard = 24 }
        if worker != "0" {
            hwnd = FindWindowExA(worker, "0", className, "0")
            if hwnd != "0" { emit hwnd }
            let icons = FindWindowExA(worker, "0", "SHELLDLL_DefView", "0")
            if icons != "0" {
                hwnd = FindWindowExA(icons, "0", className, "0")
                if hwnd != "0" { emit hwnd }
            }
        }
        guard += 1
    }
    emit "0"
}
func wpRefreshSize(hwnd, state) {
    let rect = wpRectPtr(state)
    GetClientRect(hwnd, rect)
    let width = toInt(bufGetDwordAt(rect, "8")) - toInt(bufGetDwordAt(rect, "0"))
    let height = toInt(bufGetDwordAt(rect, "12")) - toInt(bufGetDwordAt(rect, "4"))
    wpSet(state, 16, width)
    wpSet(state, 24, height)
    emit "1"
}

func wpAttachToDesktop(hwnd, state) {
    let host = wpFindDesktopHost()
    if host == "0" { emit "0" }
    wpSet(state, 88, host)

    // This Explorer build composites its static wallpaper over embedded
    // children. Keep Krypton as a click-through layered popup instead. The
    // exact scene background color becomes transparent; neon UI remains.
    // Current target-display setting: the horizontal secondary 1440p panel.
    // These values become user-configurable once the settings layer lands.
    let targetX = -2560
    let targetY = -198
    let width = 2560
    // DISPLAY7 working area excludes its 48-pixel bottom taskbar.
    let height = 1392
    SetLayeredWindowAttributes(hwnd, wpRgb(2, 7, 13), 235, 3)
    let foreground = "0" // HWND_TOP; WS_EX_NOACTIVATE prevents focus theft.
    SetWindowPos(hwnd, foreground, targetX, targetY, width, height, "80")
    wpSet(state, 16, width)
    wpSet(state, 24, height)
    emit "1"
}
func wpCreateWindow(className, title, preview) {
    let state = wpState()
    let instance = GetModuleHandleA("0")
    let exStyle = "134742176"
    let style = "2147483648"
    let x = "0"
    let y = "0"
    let width = "1920"
    let height = "1080"
    if preview == "1" {
        exStyle = "0"
        style = "13565952"
        x = "100"
        y = "100"
        width = "1280"
        height = "720"
    }
    let hwnd = CreateWindowExA(exStyle, className, title, style, x, y,
                               width, height, "0", "0", instance, "0")
    wpSet(state, 0, hwnd)
    wpSet(state, 80, preview)
    if preview != "1" { wpAttachToDesktop(hwnd, state) }
    ShowWindow(hwnd, "5")
    wpRefreshSize(hwnd, state)
    emit hwnd
}

func wpPollPointer(hwnd, state) {
    let point = wpPointPtr(state)
    GetCursorPos(point)
    ScreenToClient(hwnd, point)
    let mouseX = toInt(bufGetDwordAt(point, "0"))
    let mouseY = toInt(bufGetDwordAt(point, "4"))
    wpSet(state, 32, mouseX)
    wpSet(state, 40, mouseY)
    let button = GetAsyncKeyState("1")
    let previous = wpGet(state, 48)
    if button != "0" && previous == "0" {
        wpSet(state, 56, "1")
        wpSet(state, 64, mouseX)
        wpSet(state, 72, mouseY)
        wpSet(state, 96, "100")
    }
    wpSet(state, 48, button)
    emit "1"
}

func wpRunLoop() {
    let message = bufNew("48")
    while toInt(GetMessageA(message, "0", "0", "0")) > 0 {
        TranslateMessage(message)
        DispatchMessageA(message)
    }
    emit "0"
}

