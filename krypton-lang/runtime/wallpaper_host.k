// wallpaper_host.k — pure-Krypton Win32 wallpaper host and GDI drawing layer.
//
// Runtime dependencies are Windows system DLLs only. The matching PE backend
// in toolchain/x64_wallpaper.k wires these entry points into the import table.

module wallpaper_host

jxt {
    // kernel32.dll
    func GetModuleHandleA(name)
    func GetProcessHeap()
    func HeapAlloc(heap, flags, bytes)
    func GetEnvironmentVariableA(name, buffer, size)
    func SetEnvironmentVariableA(name, value)

    // user32.dll
    func GetSystemMetrics(index)
    func MessageBoxA(hwnd, text, caption, type)
    func FindWindowA(className, windowName)
    func FindWindowExA(parent, childAfter, className, windowName)
    func GetDesktopWindow()
    func GetWindow(hwnd, command)
    func SetParent(child, parent)
    func SendMessageA(hwnd, message, wParam, lParam)
    func SetWindowPos(hwnd, insertAfter, x, y, width, height, flags)
    func RegisterClassExA(windowClass)
    func CreateWindowExA(exStyle, className, title, style, x, y, width, height, parent, menu, instance, param)
    func DefWindowProcA(hwnd, message, wParam, lParam)
    func DestroyWindow(hwnd)
    func PostQuitMessage(exitCode)
    func ShowWindow(hwnd, command)
    func UpdateWindow(hwnd)
    func SetTimer(hwnd, id, intervalMs, callback)
    func KillTimer(hwnd, id)
    func InvalidateRect(hwnd, rect, erase)
    func GetClientRect(hwnd, rect)
    func BeginPaint(hwnd, paintStruct)
    func EndPaint(hwnd, paintStruct)
    func GetMessageA(message, hwnd, filterMin, filterMax)
    func TranslateMessage(message)
    func DispatchMessageA(message)
    func LoadCursorA(instance, cursorName)
    func FillRect(hdc, rect, brush)
    func GetCursorPos(point)
    func ScreenToClient(hwnd, point)
    func GetAsyncKeyState(key)

    // gdi32.dll
    func GetStockObject(index)
    func CreateSolidBrush(color)
    func CreatePen(style, width, color)
    func CreateFontIndirectA(logFont)
    func SelectObject(hdc, object)
    func DeleteObject(object)
    func SetTextColor(hdc, color)
    func SetBkMode(hdc, mode)
    func TextOutA(hdc, x, y, text, count)
    func MoveToEx(hdc, x, y, previousPoint)
    func LineTo(hdc, x, y)
    func Rectangle(hdc, left, top, right, bottom)
    func Ellipse(hdc, left, top, right, bottom)
}

// Raw process-lifetime state. The environment variable stores the decimal
// pointer because mutable module globals are deliberately avoided in the
// native backend. HEAP_ZERO_MEMORY keeps every field deterministic.
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
    if found != "0" {
        emit intToPtr(wpBufferToString(pointerText, 64))
    }
    let state = HeapAlloc(GetProcessHeap(), "8", "1024")
    SetEnvironmentVariableA("KRYPTON_WALLPAPER_STATE", ptrToInt(state))
    emit state
}

func wpGet(state, offset) {
    emit bufGetQwordAt(state, offset + "")
}

func wpSet(state, offset, value) {
    bufSetQwordAt(state, offset + "", value + "")
    emit value
}

func wpRgb(red, green, blue) {
    emit red + green * 256 + blue * 65536
}

func wpRectPtr(state) { emit ptrAdd(state, "256") }
func wpPointPtr(state) { emit ptrAdd(state, "288") }
func wpPaintPtr(state) { emit ptrAdd(state, "320") }

func wpSetRect(state, left, top, right, bottom) {
    let rect = wpRectPtr(state)
    bufSetDwordAt(rect, "0", left + "")
    bufSetDwordAt(rect, "4", top + "")
    bufSetDwordAt(rect, "8", right + "")
    bufSetDwordAt(rect, "12", bottom + "")
    emit rect
}

func wpFill(hdc, state, x, y, width, height, brush) {
    FillRect(hdc, wpSetRect(state, x, y, x + width, y + height), brush)
    emit "1"
}

func wpLine(hdc, pen, x1, y1, x2, y2) {
    SelectObject(hdc, pen)
    MoveToEx(hdc, x1 + "", y1 + "", "0")
    LineTo(hdc, x2 + "", y2 + "")
    emit "1"
}

func wpBox(hdc, pen, brush, x, y, width, height) {
    SelectObject(hdc, pen)
    SelectObject(hdc, brush)
    Rectangle(hdc, x + "", y + "", (x + width) + "", (y + height) + "")
    emit "1"
}

func wpRing(hdc, pen, hollowBrush, centerX, centerY, radius) {
    SelectObject(hdc, pen)
    SelectObject(hdc, hollowBrush)
    Ellipse(hdc, (centerX - radius) + "", (centerY - radius) + "",
            (centerX + radius) + "", (centerY + radius) + "")
    emit "1"
}

func wpText(hdc, font, color, x, y, text) {
    SelectObject(hdc, font)
    SetBkMode(hdc, "1")
    SetTextColor(hdc, color + "")
    TextOutA(hdc, x + "", y + "", text, len(text) + "")
    emit "1"
}

func wpCreateFont(face, height, weight) {
    let font = bufNew("92")
    let i = 0
    while i < 92 {
        bufSetByte(font, i + "", "0")
        i += 1
    }
    // LOGFONT height is signed LONG. Write the two's-complement DWORD.
    let encodedHeight = height
    if height < 0 { encodedHeight = 4294967296 + height }
    bufSetDwordAt(font, "0", encodedHeight + "")
    bufSetDwordAt(font, "16", weight + "")
    bufSetByte(font, "27", "5") // CLEARTYPE_QUALITY
    let j = 0
    while j < len(face) && j < 31 {
        bufSetByte(font, (28 + j) + "", charCode(face[j]) + "")
        j += 1
    }
    emit CreateFontIndirectA(font)
}

func wpRegisterClass(className, windowProc) {
    setWindowProc(windowProc)
    let instance = GetModuleHandleA("0")
    let wc = bufNew("80")
    let i = 0
    while i < 80 {
        bufSetByte(wc, i + "", "0")
        i += 1
    }
    bufSetDwordAt(wc, "0", "80")
    bufSetDwordAt(wc, "4", "3") // CS_HREDRAW | CS_VREDRAW
    bufSetQwordAt(wc, "8", windowProcAddr())
    bufSetQwordAt(wc, "24", instance)
    bufSetQwordAt(wc, "40", LoadCursorA("0", "32512"))
    bufSetQwordAt(wc, "48", GetStockObject("4")) // BLACK_BRUSH
    bufSetQwordAt(wc, "64", ptrToInt(className))
    emit RegisterClassExA(wc)
}

// Ask Explorer to create its wallpaper WorkerW, then find the top-level
// window that sits immediately behind SHELLDLL_DefView (desktop icons).
func wpFindDesktopHost() {
    let progman = FindWindowA("Progman", "0")
    if progman != "0" {
        SendMessageA(progman, "1324", "0", "0") // undocumented 0x052C
    }

    let desktop = GetDesktopWindow()
    let top = GetWindow(desktop, "5") // GW_CHILD
    let guard = 0
    while top != "0" && guard < 512 {
        let defView = FindWindowExA(top, "0", "SHELLDLL_DefView", "0")
        if defView != "0" {
            let worker = FindWindowExA("0", top, "WorkerW", "0")
            if worker != "0" { emit worker }
            emit top
        }
        top = GetWindow(top, "2") // GW_HWNDNEXT
        guard += 1
    }
    emit progman
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
    SetParent(hwnd, host)
    let width = GetSystemMetrics("78")
    let height = GetSystemMetrics("79")
    if width == "0" { width = GetSystemMetrics("0") }
    if height == "0" { height = GetSystemMetrics("1") }
    SetWindowPos(hwnd, "1", "0", "0", width, height, "80")
    wpSet(state, 16, width)
    wpSet(state, 24, height)
    emit "1"
}

func wpCreateWindow(className, title, preview) {
    let state = wpState()
    let instance = GetModuleHandleA("0")
    let exStyle = "134217856" // WS_EX_NOACTIVATE | WS_EX_TOOLWINDOW
    let style = "2147483648"  // WS_POPUP
    let x = "0"
    let y = "0"
    let width = GetSystemMetrics("78")
    let height = GetSystemMetrics("79")
    if preview == "1" {
        exStyle = "0"
        style = "13565952" // WS_OVERLAPPEDWINDOW
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
    UpdateWindow(hwnd)
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

