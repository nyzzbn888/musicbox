# ============================================================
#  hajimi客户端 卸载程序 (安装时随程序一起装入安装目录)
#  由 build-hajimi.ps1 编译成 Uninstall.exe 打进安装包
# ============================================================
#requires -Version 5.1
$ErrorActionPreference = "SilentlyContinue"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$APP_NAME = "hajimi客户端"
$EXE_NAME = "MusicBox.exe"
$REG_KEY  = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HajimiClient"

# 自身所在目录 = 安装目录 (兼容 exe 与直接跑 ps1)
$dir = $PSScriptRoot
if (-not $dir -or $dir -eq "") {
    try { $dir = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { $dir = "" }
}
if (-not $dir -or $dir -eq "") { $dir = (Get-Location).Path }

$silent = $false
try { if ($args -contains "/S" -or $args -contains "-silent") { $silent = $true } } catch { }

if (-not $silent) {
    # 静默参数直接过, 否则弹窗确认
}
$msg = "确定要卸载 $APP_NAME 吗？`n`n安装目录：$dir`n`n个人数据（收藏 / 歌单 / 历史）会保留，除非你在下一步选择一并删除。"
if (-not $silent) {
    $r = [System.Windows.Forms.MessageBox]::Show($msg, "$APP_NAME 卸载", "YesNo", "Question")
    if ($r -ne "Yes") { exit 0 }
}

# 1) 关掉正在运行的程序
$procName = [System.IO.Path]::GetFileNameWithoutExtension($EXE_NAME)
Get-Process -Name $procName -ErrorAction SilentlyContinue | ForEach-Object {
    try { $_.CloseMainWindow() | Out-Null } catch { }
    Start-Sleep -Milliseconds 600
    if (-not $_.HasExited) { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }
}
Start-Sleep -Milliseconds 500

# 2) 询问是否删除个人数据 (静默模式默认保留)
$removeData = $false
if (-not $silent) {
    $r2 = [System.Windows.Forms.MessageBox]::Show("是否同时删除个人数据？`n`n包括：收藏、歌单、播放历史、封面缓存（userdata / cover_cache 文件夹）`n`n选「否」则保留，重装后还能用。", "$APP_NAME 卸载", "YesNo", "Question")
    $removeData = ($r2 -eq "Yes")
}

# 3) 删除快捷方式
try {
    $desktop = [Environment]::GetFolderPath("Desktop")
    $lnk1 = Join-Path $desktop "$APP_NAME.lnk"
    if (Test-Path -LiteralPath $lnk1) { Remove-Item -LiteralPath $lnk1 -Force }
    $lnk2 = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\$APP_NAME.lnk"
    if (Test-Path -LiteralPath $lnk2) { Remove-Item -LiteralPath $lnk2 -Force }
} catch { }

# 4) 删除注册表卸载项
try { if (Test-Path $REG_KEY) { Remove-Item -Path $REG_KEY -Recurse -Force } } catch { }

# 5) 删除个人数据 (按选择)
if ($removeData) {
    foreach ($sub in @("userdata","cover_cache")) {
        $p = Join-Path $dir $sub
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# 6) 删除程序文件 (除自身以外), 然后延迟删除整个目录
try {
    Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue | Where-Object {
        $_.Name -ne "Uninstall.exe" -and
        ($removeData -or ($_.Name -ne "userdata" -and $_.Name -ne "cover_cache"))
    } | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue }
} catch { }

if (-not $silent) {
    [System.Windows.Forms.MessageBox]::Show("卸载完成。`n`n程序目录会被自动清理。", "$APP_NAME 卸载", "OK", "Information") | Out-Null
}

# 7) 自身无法运行时删除自己 -> 交给一个延迟的 cmd 处理
try {
    $cmd = "timeout /t 2 /nobreak >nul & rmdir /s /q `"$dir`""
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", $cmd -WindowStyle Hidden
} catch { }
