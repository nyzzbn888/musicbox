# ============================================================
#  hajimi客户端 安装包构建脚本
#  产物: dist\HajimiClient-Setup.exe   (单文件安装包, 程序已内嵌)
#
#  流程:
#   1) 先编译 Uninstall.exe
#   2) 把「主程序 + WebView2 DLL + 使用说明 + Uninstall.exe」压成一个 zip
#   3) zip 转 base64, 注入安装器模板
#   4) ps2exe 编译成单文件安装包
# ============================================================
[CmdletBinding()]
param(
    [string]$Version = "3.6.0.0",
    [string]$AppName = "hajimi客户端"
)

$ErrorActionPreference = "Stop"
$root    = $PSScriptRoot
$dist    = Join-Path $root "dist"
$build   = Join-Path $root "build"
$srcDir  = "D:\MusicBox"          # 主程序所在目录
$setupTpl = Join-Path $root "HajimiSetup.ps1"
$uninstSrc = Join-Path $root "Uninstall.ps1"
$iconPath = Join-Path $srcDir "cat_icon.ico"

foreach ($d in @($dist, $build)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null } }

Write-Host "== hajimi客户端 安装包构建 ==" -ForegroundColor Cyan
Write-Host "  版本: $Version"
Write-Host "  主程序目录: $srcDir"

# ---------- 0) 依赖检查 ----------
$mainExe = Join-Path $srcDir "MusicBox.exe"
$dlls = @("Microsoft.Web.WebView2.Core.dll","Microsoft.Web.WebView2.WinForms.dll","WebView2Loader.dll")
if (-not (Test-Path $mainExe)) { throw "找不到主程序: $mainExe" }
foreach ($d in $dlls) { if (-not (Test-Path (Join-Path $srcDir $d))) { throw "找不到依赖 DLL: $d" } }

if (-not (Get-Command Invoke-ps2exe -ErrorAction SilentlyContinue)) {
    Write-Host "  正在安装 ps2exe..." -ForegroundColor Yellow
    Install-Module ps2exe -Scope CurrentUser -Force -AllowClobber
}
Import-Module ps2exe -Force

function Test-Syntax($file) {
    $tk = $null; $er = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tk, [ref]$er)
    if ($er.Count -gt 0) {
        $er | Select-Object -First 5 | ForEach-Object { Write-Host ("  语法错误 L{0}: {1}" -f $_.Extent.StartLineNumber, $_.Message) -ForegroundColor Red }
        throw "语法检查失败: $file"
    }
}
Test-Syntax $setupTpl
Test-Syntax $uninstSrc

# ---------- 1) 编译卸载器 ----------
Write-Host "  [1/4] 编译 Uninstall.exe ..." -ForegroundColor Green
$uninstExe = Join-Path $build "Uninstall.exe"
Invoke-ps2exe -inputFile $uninstSrc -outputFile $uninstExe -noConsole -STA `
    -iconFile $iconPath -title "hajimi客户端 卸载程序" -product "hajimi客户端" -company "hajimi" -version $Version | Out-Null
if (-not (Test-Path $uninstExe)) { throw "卸载器编译失败" }
Write-Host ("        大小 {0:N0} 字节" -f (Get-Item $uninstExe).Length)

# ---------- 2) 打包负载 ----------
Write-Host "  [2/4] 打包程序文件 ..." -ForegroundColor Green
$readme = @"
hajimi客户端 · 免费音乐播放器

【怎么用】
双击本目录下的 MusicBox.exe 即可运行（桌面上也有快捷方式）。
无需安装任何东西，程序自带所需的运行库。

【功能】
· 完整听：YouTube 完整歌曲，内置播放器 16:9 大画面
· 搜索：全网曲库官方 30 秒试听
· 本地音乐：MP3 / FLAC / WAV / M4A，支持拖拽导入
· 收藏 / 歌单 / 播放历史 / 睡眠定时
· 右上角按钮可切换 中文 / English

【数据位置】
收藏、歌单、历史、封面缓存都保存在本目录下的 userdata 与 cover_cache 文件夹。
删除这两个文件夹即彻底清除个人数据，程序本身不受影响。

【系统要求】
Windows 10 / 11（64 位）
音频播放需要系统自带的 Windows Media Player 组件。

【卸载】
运行本目录下的 Uninstall.exe，或在「设置 → 应用」里找到 hajimi客户端 卸载。

【免责声明】
本软件仅供个人学习与技术演示，与 YouTube / Spotify / Deezer / Apple 无关联。
不下载、不存储、不分发任何受版权保护的内容，请勿用于商业用途。
"@
[System.IO.File]::WriteAllText((Join-Path $build "使用说明.txt"), $readme, (New-Object System.Text.UTF8Encoding($true)))

$payload = @()
$payload += @{ path = $mainExe;  name = "MusicBox.exe" }
foreach ($d in $dlls) { $payload += @{ path = (Join-Path $srcDir $d); name = $d } }
$payload += @{ path = $uninstExe; name = "Uninstall.exe" }
$payload += @{ path = (Join-Path $build "使用说明.txt"); name = "使用说明.txt" }

$zipPath = Join-Path $build "payload.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
foreach ($f in $payload) {
    $entry = $zip.CreateEntry($f.name, [System.IO.Compression.CompressionLevel]::Optimal)
    $es = $entry.Open()
    $bytes = [System.IO.File]::ReadAllBytes($f.path)
    $es.Write($bytes, 0, $bytes.Length)
    $es.Close()
    Write-Host ("        + {0,-38} {1,9:N0} 字节" -f $f.name, $bytes.Length)
}
$zip.Dispose()
$zipBytes = [System.IO.File]::ReadAllBytes($zipPath)
$zipSize = $zipBytes.Length
$b64 = [Convert]::ToBase64String($zipBytes)
Write-Host ("        压缩后 {0:N0} 字节 -> base64 {1:N0} 字符" -f $zipSize, $b64.Length)

# ---------- 3) 注入负载 ----------
Write-Host "  [3/4] 注入安装器模板 ..." -ForegroundColor Green
$tpl = [System.IO.File]::ReadAllText($setupTpl)
if (-not $tpl.Contains("@@PAYLOAD@@")) { throw "模板缺少 @@PAYLOAD@@ 占位符" }
$gen = $tpl.Replace("@@PAYLOAD@@", $b64).Replace("@@VERSION@@", $Version)
$genPath = Join-Path $build "HajimiSetup.gen.ps1"
[System.IO.File]::WriteAllText($genPath, $gen, (New-Object System.Text.UTF8Encoding($true)))
Test-Syntax $genPath
Write-Host ("        生成 {0:N0} 字节的安装器脚本" -f (Get-Item $genPath).Length)

# ---------- 4) 编译安装包 ----------
Write-Host "  [4/4] 编译安装包 ..." -ForegroundColor Green
$setupExe = Join-Path $dist "HajimiClient-Setup.exe"
Invoke-ps2exe -inputFile $genPath -outputFile $setupExe -noConsole -STA `
    -iconFile $iconPath -title "$AppName 安装程序" -description "$AppName - $Version 一键安装程序" `
    -product $AppName -company "hajimi" -version $Version | Out-Null

$fi = Get-Item $setupExe
Write-Host ""
Write-Host ("  完成: {0}" -f $setupExe) -ForegroundColor Green
Write-Host ("        大小 {0:N0} 字节 ({1:N1} MB)  v{2}" -f $fi.Length, ($fi.Length/1MB), $Version)
Write-Host ""
Write-Host "  分发方式: 把这个单文件发给别人, 双击即可一键安装。" -ForegroundColor DarkGray
Write-Host "  安装位置: %LOCALAPPDATA%\Programs\hajimi客户端  (免管理员权限)" -ForegroundColor DarkGray
