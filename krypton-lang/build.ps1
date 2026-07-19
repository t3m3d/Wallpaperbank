param(
    [string]$KryptonRoot = "C:\krypton"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BuildRoot = Join-Path $ProjectRoot "build"
$DistRoot = Join-Path $ProjectRoot "dist"
$Frontend = Join-Path $KryptonRoot "kcc-bin.exe"
$Optimizer = Join-Path $KryptonRoot "compiler\windows_x86\optimize_host.exe"
$Backend = Join-Path $KryptonRoot "compiler\windows_x86\x64_host.exe"
$Runtime = Join-Path $KryptonRoot "krypton_rt.dll"

foreach ($Required in @($Frontend, $Optimizer, $Backend, $Runtime)) {
    if (-not (Test-Path -LiteralPath $Required)) {
        throw "Required Krypton component not found: $Required"
    }
}

New-Item -ItemType Directory -Force -Path $BuildRoot, $DistRoot | Out-Null
$env:KRYPTON_ROOT = $KryptonRoot

function Invoke-KryptonIr {
    param([string]$Source, [string]$Output)
    & $Frontend --ir $Source | Set-Content -LiteralPath $Output -Encoding utf8NoBOM
    if ($LASTEXITCODE -ne 0) { throw "Krypton IR emission failed: $Source" }
}

function Invoke-KryptonOptimize {
    param([string]$InputPath, [string]$OutputPath)
    & $Optimizer $InputPath | Set-Content -LiteralPath $OutputPath -Encoding utf8NoBOM
    if ($LASTEXITCODE -ne 0) { throw "Krypton optimizer failed: $InputPath" }
}

function Patch-AsciiImport {
    param([byte[]]$Bytes, [string]$From, [string]$To)
    if ($To.Length -gt $From.Length) {
        throw "Replacement import '$To' is longer than '$From'"
    }
    $Needle = [Text.Encoding]::ASCII.GetBytes($From)
    $Replacement = [Text.Encoding]::ASCII.GetBytes($To)
    $Matches = 0
    for ($Index = 0; $Index -lt $Bytes.Length - $Needle.Length; $Index++) {
        $Equal = $true
        for ($Offset = 0; $Offset -lt $Needle.Length; $Offset++) {
            if ($Bytes[$Index + $Offset] -ne $Needle[$Offset]) {
                $Equal = $false
                break
            }
        }
        if ($Equal -and $Bytes[$Index + $Needle.Length] -ne 0) {
            $Equal = $false
        }
        if (-not $Equal) { continue }
        for ($Offset = 0; $Offset -lt $Needle.Length; $Offset++) {
            if ($Offset -lt $Replacement.Length) {
                $Bytes[$Index + $Offset] = $Replacement[$Offset]
            } else {
                $Bytes[$Index + $Offset] = 0
            }
        }
        $Matches++
        $Index += $Needle.Length - 1
    }
    if ($Matches -eq 0) { throw "Import slot not found in PE: $From" }
    return $Bytes
}

function Set-WallpaperImports {
    param([string]$Executable)
    [byte[]]$Bytes = [IO.File]::ReadAllBytes($Executable)
    $Aliases = [ordered]@{
        "MessageBoxA" = "FindWindowA"
        "CreatePopupMenu" = "FindWindowExA"
        "SetForegroundWindow" = "SetWindowLongPtrA"
        "GetWindowTextA" = "BeginPaint"
        "SetWindowTextA" = "EndPaint"
        "GetWindow" = "SetParent"
        "UpdateWindow" = "GetCursorPos"
        "SetClassLongPtrA" = "ScreenToClient"
        "GetSystemMetrics" = "GetAsyncKeyState"
        "GetTextExtentPoint32A" = "TextOutA"
        "CreateFontIndirectA" = "CreatePen"
        "SetBkColor" = "MoveToEx"
        "DeleteObject" = "LineTo"
        "SetProcessDpiAwarenessContext" = "SetLayeredWindowAttributes"
    }
    foreach ($Alias in $Aliases.GetEnumerator()) {
        $Bytes = Patch-AsciiImport -Bytes $Bytes -From $Alias.Key -To $Alias.Value
    }
    [IO.File]::WriteAllBytes($Executable, $Bytes)
}

function Set-WindowsGuiSubsystem {
    param([string]$Executable)
    [byte[]]$Bytes = [IO.File]::ReadAllBytes($Executable)
    $PeOffset = [BitConverter]::ToInt32($Bytes, 60)
    $OptionalHeader = $PeOffset + 24
    $Magic = [BitConverter]::ToUInt16($Bytes, $OptionalHeader)
    if ($Magic -ne 0x20B) { throw "Expected a PE32+ executable: $Executable" }
    $Subsystem = $OptionalHeader + 68
    $Bytes[$Subsystem] = 2
    $Bytes[$Subsystem + 1] = 0
    [IO.File]::WriteAllBytes($Executable, $Bytes)
}
function Build-KryptonProgram {
    param([string]$Source, [string]$Name)
    $Ir = Join-Path $BuildRoot "$Name.kir"
    $OptimizedIr = Join-Path $BuildRoot "${Name}_opt.kir"
    $Exe = Join-Path $DistRoot "$Name.exe"
    Invoke-KryptonIr -Source $Source -Output $Ir
    Invoke-KryptonOptimize -InputPath $Ir -OutputPath $OptimizedIr
    & $Backend $OptimizedIr $Exe
    if ($LASTEXITCODE -ne 0) { throw "Krypton PE backend failed: $Source" }
    Set-WallpaperImports -Executable $Exe
    if ($Name -eq "krypton-wallpaper") { Set-WindowsGuiSubsystem -Executable $Exe }
}

Write-Host "Building the Krypton wallpaper runtime..."
Build-KryptonProgram -Source (Join-Path $ProjectRoot "src\wallpaper.k") -Name "krypton-wallpaper"
Build-KryptonProgram -Source (Join-Path $ProjectRoot "src\stop.k") -Name "krypton-wallpaper-stop"
Copy-Item -LiteralPath $Runtime -Destination (Join-Path $DistRoot "krypton_rt.dll") -Force
Write-Host "Build complete: $DistRoot"
