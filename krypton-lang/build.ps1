param(
    [string]$KryptonRoot = "C:\krypton"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BuildRoot = Join-Path $ProjectRoot "build"
$DistRoot = Join-Path $ProjectRoot "dist"
$Frontend = Join-Path $KryptonRoot "kcc-bin.exe"
$Optimizer = Join-Path $KryptonRoot "compiler\windows_x86\optimize_host.exe"
$BootstrapBackend = Join-Path $KryptonRoot "compiler\windows_x86\x64_host.exe"
$Runtime = Join-Path $KryptonRoot "krypton_rt.dll"
$BackendSource = Join-Path $ProjectRoot "toolchain\x64_wallpaper.k"
$BackendExe = Join-Path $BuildRoot "x64_wallpaper_host.exe"

foreach ($Required in @($Frontend, $Optimizer, $BootstrapBackend, $Runtime, $BackendSource)) {
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
    param([string]$Input, [string]$Output)
    & $Optimizer $Input | Set-Content -LiteralPath $Output -Encoding utf8NoBOM
    if ($LASTEXITCODE -ne 0) { throw "Krypton optimizer failed: $Input" }
}

function Invoke-KryptonPe {
    param([string]$Backend, [string]$Input, [string]$Output)
    & $Backend $Input $Output
    if ($LASTEXITCODE -ne 0) { throw "Krypton PE backend failed: $Input" }
}

function Build-KryptonProgram {
    param([string]$Source, [string]$Name, [string]$Backend)
    $Ir = Join-Path $BuildRoot "$Name.kir"
    $OptimizedIr = Join-Path $BuildRoot "${Name}_opt.kir"
    $Exe = Join-Path $DistRoot "$Name.exe"
    Invoke-KryptonIr -Source $Source -Output $Ir
    Invoke-KryptonOptimize -Input $Ir -Output $OptimizedIr
    Invoke-KryptonPe -Backend $Backend -Input $OptimizedIr -Output $Exe
}

Write-Host "Building the wallpaper-aware Krypton PE backend..."
$BackendIr = Join-Path $BuildRoot "x64_wallpaper.kir"
$BackendOptimizedIr = Join-Path $BuildRoot "x64_wallpaper_opt.kir"
Invoke-KryptonIr -Source $BackendSource -Output $BackendIr
Invoke-KryptonOptimize -Input $BackendIr -Output $BackendOptimizedIr
Invoke-KryptonPe -Backend $BootstrapBackend -Input $BackendOptimizedIr -Output $BackendExe

Write-Host "Building the Krypton wallpaper runtime..."
Build-KryptonProgram -Source (Join-Path $ProjectRoot "src\wallpaper.k") `
    -Name "krypton-wallpaper" -Backend $BackendExe
Build-KryptonProgram -Source (Join-Path $ProjectRoot "src\stop.k") `
    -Name "krypton-wallpaper-stop" -Backend $BackendExe

Copy-Item -LiteralPath $Runtime -Destination (Join-Path $DistRoot "krypton_rt.dll") -Force
Write-Host "Build complete: $DistRoot"

