// stop.k — asks the running Krypton wallpaper to close cleanly.

import "../runtime/wallpaper_host_native.k"

just run {
    let hwnd = wpFindWallpaperWindow("KryptonWallpaperClass")
    if hwnd == "0" {
        print("Krypton wallpaper is not running")
        exit("1")
    }
    SendMessageA(hwnd, "16", "0", "0") // WM_CLOSE
    print("Krypton wallpaper stopped")
}
