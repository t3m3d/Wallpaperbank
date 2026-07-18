// stop.k — asks the running Krypton wallpaper to close cleanly.

jxt {
    func FindWindowA(className, windowName)
    func SendMessageA(hwnd, message, wParam, lParam)
}

just run {
    let hwnd = FindWindowA("KryptonWallpaperClass", "0")
    if hwnd != "0" {
        SendMessageA(hwnd, "16", "0", "0") // WM_CLOSE
    }
}

