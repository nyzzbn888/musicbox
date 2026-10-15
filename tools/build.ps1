# ============================================================
#  MusicBox (Free) 一键编译脚本
#  用法: powershell -ExecutionPolicy Bypass -File tools\build.ps1
#  产物: dist\MusicBox.exe
# ============================================================
[CmdletBinding()]
param(
    [string]$Version = "3.6.0.0",
    [switch]$NoConsole
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$src  = Join-Path $root "src\MusicBox.ps1"
$out  = Join-Path $root "dist\MusicBox.exe"

if (-not (Test-Path -LiteralPath $src)) { throw "找不到源码: $src" }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $out))) { New-Item -ItemType Directory -Path (Split-Path -Parent $out) -Force | Out-Null }

Write-Host "== MusicBox (Free) build ==" -ForegroundColor Cyan
Write-Host "  源码: $src"
Write-Host "  输出: $out"

# 1) 语法检查
$tokens = $null; $errors = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($src, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) {
    $errors | Select-Object -First 10 | ForEach-Object { Write-Host ("  语法错误 L{0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) -ForegroundColor Red }
    throw "源码存在 $($errors.Count) 个语法错误，已中止"
}
Write-Host "  [1/3] 语法检查通过" -ForegroundColor Green

# 2) 确保 ps2exe 可用
if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue)) {
    Write-Host "  [2/3] 正在安装 ps2exe 模块..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe -Force
Write-Host "  [2/3] ps2exe 就绪" -ForegroundColor Green

# 3) 编译 (图标可选)
$icon = Join-Path $root "assets\cat_icon.ico"
$ps2exeArgs = @{
    inputFile   = $src
    outputFile  = $out
    STA         = $true
    noConsole   = $true
    title       = "MusicBox (Free)"
    description = "MusicBox (Free) - Apple Music style player, bilingual"
    product     = "MusicBox (Free)"
    company     = "MusicBox"
    version     = $Version
}
if (Test-Path -LiteralPath $icon) { $ps2exeArgs.iconFile = $icon; Write-Host "  使用图标: $icon" }

Invoke-ps2exe @ps2exeArgs | Out-Null

$fi = Get-Item -LiteralPath $out
Write-Host ("  [3/3] 编译完成: {0} ({1:N0} 字节, v{2})" -f $fi.Name, $fi.Length, $Version) -ForegroundColor Green
Write-Host ""
Write-Host "提示: 打包分享时请把 dist 下的三个 WebView2 DLL 与 exe 放在一起:" -ForegroundColor DarkGray
Write-Host "  Microsoft.Web.WebView2.Core.dll / Microsoft.Web.WebView2.WinForms.dll / WebView2Loader.dll" -ForegroundColor DarkGray
