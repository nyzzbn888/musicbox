# ============================================================
#  hajimi客户端 一键安装程序
#  像 QQ音乐 那样：双安装包 + 一键装完 + 桌面/开始菜单快捷方式 + 可卸载
#  特点: 免管理员权限 (装到用户目录), 免 .NET 安装, 单文件安装包
#  构建: 由 build-hajimi.ps1 把 @@PAYLOAD@@ 替换成内嵌的 base64 压缩包后编译
# ============================================================
#requires -Version 5.1
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.Windows.Forms.Application]::EnableVisualStyles()

$APP_NAME    = "hajimi客户端"
$APP_VER     = "@@VERSION@@"
$APP_PUB     = "hajimi"
$APP_DESC    = "免费音乐播放器 - Apple Music 风格 · 中英双语"
$EXE_NAME    = "MusicBox.exe"
$REG_KEY     = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\HajimiClient"
$PAYLOAD_B64 = "@@PAYLOAD@@"

# ---------- 配色 (与 hajimi 猫猫图标呼应的暖红渐变) ----------
$cBg      = [System.Drawing.Color]::FromArgb(250, 250, 252)
$cCard    = [System.Drawing.Color]::White
$cText    = [System.Drawing.Color]::FromArgb(29, 29, 31)
$cSub     = [System.Drawing.Color]::FromArgb(134, 134, 139)
$cAccent  = [System.Drawing.Color]::FromArgb(250, 36, 60)
$cAccent2 = [System.Drawing.Color]::FromArgb(255, 107, 129)
$cHair    = [System.Drawing.Color]::FromArgb(226, 226, 230)
$cInputBg = [System.Drawing.Color]::FromArgb(242, 242, 245)
$fUI      = "Microsoft YaHei UI"

$script:installed = $false
$script:installDir = Join-Path $env:LOCALAPPDATA "Programs\hajimi客户端"

# ---------- 界面 ----------
$form = New-Object System.Windows.Forms.Form
$form.Text = "$APP_NAME 安装程序"
$form.ClientSize = New-Object System.Drawing.Size(620, 452)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = $cBg
$form.Font = New-Object System.Drawing.Font($fUI, 9.5)

# 顶部渐变标题区
$header = New-Object System.Windows.Forms.Panel
$header.SetBounds(0, 0, 620, 132)
$form.Controls.Add($header)
$header.Add_Paint({
    param($s, $e)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $s.Width, $s.Height)
    $br = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $cAccent, $cAccent2, 20.0)
    $e.Graphics.FillRectangle($br, $rect)
    $br.Dispose()
})

# 猫猫图标
$picIcon = New-Object System.Windows.Forms.PictureBox
$picIcon.SetBounds(30, 26, 80, 80)
$picIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$picIcon.BackColor = [System.Drawing.Color]::Transparent
$header.Controls.Add($picIcon)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = $APP_NAME
$lblTitle.Font = New-Object System.Drawing.Font($fUI, 22, [System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.BackColor = [System.Drawing.Color]::Transparent
$lblTitle.SetBounds(126, 34, 460, 40)
$header.Controls.Add($lblTitle)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "$APP_DESC    ·    版本 $APP_VER"
$lblSub.Font = New-Object System.Drawing.Font($fUI, 9.5)
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(255, 235, 238)
$lblSub.BackColor = [System.Drawing.Color]::Transparent
$lblSub.SetBounds(128, 76, 460, 22)
$header.Controls.Add($lblSub)

# 安装位置
$lblDir = New-Object System.Windows.Forms.Label
$lblDir.Text = "安装位置"
$lblDir.Font = New-Object System.Drawing.Font($fUI, 9.5, [System.Drawing.FontStyle]::Bold)
$lblDir.ForeColor = $cText
$lblDir.SetBounds(30, 156, 200, 20)
$form.Controls.Add($lblDir)

$txtDir = New-Object System.Windows.Forms.TextBox
$txtDir.Text = $script:installDir
$txtDir.SetBounds(30, 180, 460, 30)
$txtDir.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtDir.BackColor = $cCard
$txtDir.ForeColor = $cText
$txtDir.Font = New-Object System.Drawing.Font($fUI, 9.5)
$form.Controls.Add($txtDir)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "浏览..."
$btnBrowse.SetBounds(500, 179, 90, 32)
$btnBrowse.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnBrowse.FlatAppearance.BorderSize = 1
$btnBrowse.FlatAppearance.BorderColor = $cHair
$btnBrowse.BackColor = $cCard
$btnBrowse.ForeColor = $cText
$btnBrowse.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnBrowse.UseVisualStyleBackColor = $false
$form.Controls.Add($btnBrowse)

$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "默认装到当前用户目录，无需管理员权限，不会弹出 UAC"
$lblHint.Font = New-Object System.Drawing.Font($fUI, 8.5)
$lblHint.ForeColor = $cSub
$lblHint.SetBounds(30, 214, 560, 18)
$form.Controls.Add($lblHint)

# 选项
$chkDesktop = New-Object System.Windows.Forms.CheckBox
$chkDesktop.Text = "创建桌面快捷方式"
$chkDesktop.Checked = $true
$chkDesktop.SetBounds(32, 246, 260, 24)
$chkDesktop.ForeColor = $cText
$form.Controls.Add($chkDesktop)

$chkStart = New-Object System.Windows.Forms.CheckBox
$chkStart.Text = "创建开始菜单快捷方式"
$chkStart.Checked = $true
$chkStart.SetBounds(32, 274, 260, 24)
$chkStart.ForeColor = $cText
$form.Controls.Add($chkStart)

$chkRun = New-Object System.Windows.Forms.CheckBox
$chkRun.Text = "安装完成后立即运行"
$chkRun.Checked = $true
$chkRun.SetBounds(320, 246, 260, 24)
$chkRun.ForeColor = $cText
$form.Controls.Add($chkRun)

$chkUninst = New-Object System.Windows.Forms.CheckBox
$chkUninst.Text = "在「应用和功能」中显示卸载入口"
$chkUninst.Checked = $true
$chkUninst.SetBounds(320, 274, 280, 24)
$chkUninst.ForeColor = $cText
$form.Controls.Add($chkUninst)

# 进度条 + 状态
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.SetBounds(30, 316, 560, 8)
$progress.Style = "Continuous"
$progress.Maximum = 100
$form.Controls.Add($progress)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "准备就绪，点击下方按钮开始安装"
$lblStatus.Font = New-Object System.Drawing.Font($fUI, 9)
$lblStatus.ForeColor = $cSub
$lblStatus.SetBounds(30, 330, 560, 20)
$form.Controls.Add($lblStatus)

# 主按钮
$btnMain = New-Object System.Windows.Forms.Button
$btnMain.Text = "一 键 安 装"
$btnMain.SetBounds(30, 366, 560, 54)
$btnMain.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnMain.FlatAppearance.BorderSize = 0
$btnMain.BackColor = $cAccent
$btnMain.ForeColor = [System.Drawing.Color]::White
$btnMain.Font = New-Object System.Drawing.Font($fUI, 14, [System.Drawing.FontStyle]::Bold)
$btnMain.Cursor = [System.Windows.Forms.Cursors]::Hand
$btnMain.UseVisualStyleBackColor = $false
$form.Controls.Add($btnMain)

# ---------- 辅助函数 ----------
function Set-Status($text) {
    $lblStatus.Text = $text
    [System.Windows.Forms.Application]::DoEvents()
}

# 用 Unicode 版 IShellLinkW 创建快捷方式
# (WScript.Shell 走 ANSI 接口, 安装路径或桌面路径含中文时会报 "Value does not fall within the expected range")
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

[ComImport, Guid("00021401-0000-0000-C000-000000000046")]
internal class ShellLinkCoClass { }

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("000214F9-0000-0000-C000-000000000046")]
internal interface IShellLinkW
{
    void GetPath([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszFile, int cch, IntPtr pfd, uint fFlags);
    void GetIDList(out IntPtr ppidl);
    void SetIDList(IntPtr pidl);
    void GetDescription([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszName, int cch);
    void SetDescription([MarshalAs(UnmanagedType.LPWStr)] string pszName);
    void GetWorkingDirectory([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszDir, int cch);
    void SetWorkingDirectory([MarshalAs(UnmanagedType.LPWStr)] string pszDir);
    void GetArguments([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszArgs, int cch);
    void SetArguments([MarshalAs(UnmanagedType.LPWStr)] string pszArgs);
    void GetHotkey(out short pwHotkey);
    void SetHotkey(short wHotkey);
    void GetShowCmd(out int piShowCmd);
    void SetShowCmd(int iShowCmd);
    void GetIconLocation([Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pszIconPath, int cch, out int piIcon);
    void SetIconLocation([MarshalAs(UnmanagedType.LPWStr)] string pszIconPath, int iIcon);
    void SetRelativePath([MarshalAs(UnmanagedType.LPWStr)] string pszPathRel, uint dwReserved);
    void Resolve(IntPtr hwnd, uint fFlags);
    void SetPath([MarshalAs(UnmanagedType.LPWStr)] string pszFile);
}

[ComImport, InterfaceType(ComInterfaceType.InterfaceIsIUnknown), Guid("0000010b-0000-0000-C000-000000000046")]
internal interface IPersistFile
{
    void GetClassID(out Guid pClassID);
    [PreserveSig] int IsDirty();
    void Load([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, uint dwMode);
    void Save([MarshalAs(UnmanagedType.LPWStr)] string pszFileName, [MarshalAs(UnmanagedType.Bool)] bool fRemember);
    void SaveCompleted([MarshalAs(UnmanagedType.LPWStr)] string pszFileName);
    void GetCurFile([MarshalAs(UnmanagedType.LPWStr)] out string ppszFileName);
}

public static class ShortcutHelper
{
    public static void Create(string lnkPath, string target, string workDir, string iconPath, int iconIndex, string description)
    {
        var link = (IShellLinkW)new ShellLinkCoClass();
        link.SetPath(target);
        if (!string.IsNullOrEmpty(workDir)) link.SetWorkingDirectory(workDir);
        if (!string.IsNullOrEmpty(iconPath)) link.SetIconLocation(iconPath, iconIndex);
        if (!string.IsNullOrEmpty(description)) link.SetDescription(description);
        ((IPersistFile)link).Save(lnkPath, false);
    }
}
'@

function New-Shortcut($lnkPath, $target, $workDir, $icon) {
    try {
        $parent = Split-Path -Parent $lnkPath
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        [ShortcutHelper]::Create($lnkPath, $target, $workDir, $icon, 0, $APP_NAME)
        return (Test-Path -LiteralPath $lnkPath)
    } catch {
        try { Add-Content -LiteralPath (Join-Path $env:TEMP "hajimi-setup-error.log") -Value "[$(Get-Date -Format 'HH:mm:ss')] shortcut fail: $($_.Exception.Message)" -Encoding UTF8 } catch { }
        return $false
    }
}

function Test-AppRunning {
    try { return [bool](Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($EXE_NAME)) -ErrorAction SilentlyContinue) } catch { return $false }
}

# ---------- 安装流程 ----------
function Start-Install {
    $dir = $txtDir.Text.Trim()
    if ($dir -eq "") { [System.Windows.Forms.MessageBox]::Show("请填写安装位置", $APP_NAME, "OK", "Warning") | Out-Null; return }
    if ($dir.Length -lt 4 -or $dir -match '^[A-Za-z]:\\?$') {
        [System.Windows.Forms.MessageBox]::Show("安装位置不能是磁盘根目录，请选一个文件夹", $APP_NAME, "OK", "Warning") | Out-Null; return
    }
    if (Test-AppRunning) {
        $r = [System.Windows.Forms.MessageBox]::Show("$APP_NAME 正在运行，需要先关闭才能覆盖安装。`n`n是否关闭并继续？", $APP_NAME, "YesNo", "Question")
        if ($r -ne "Yes") { return }
        Get-Process -Name ([System.IO.Path]::GetFileNameWithoutExtension($EXE_NAME)) -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Milliseconds 800
    }

    $btnMain.Enabled = $false
    $btnBrowse.Enabled = $false
    $txtDir.Enabled = $false
    $progress.Value = 5
    Set-Status "正在准备安装..."

    try {
        if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

        # 1) 解包 (内存中解压, 不落临时文件)
        Set-Status "正在解压程序文件..."
        $progress.Value = 20
        $bytes = [Convert]::FromBase64String($PAYLOAD_B64)
        $ms = New-Object System.IO.MemoryStream(, $bytes)
        $zip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
        $total = $zip.Entries.Count
        $i = 0
        foreach ($e in $zip.Entries) {
            $i++
            $target = Join-Path $dir $e.FullName
            $tdir = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $tdir)) { New-Item -ItemType Directory -Path $tdir -Force | Out-Null }
            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
            $progress.Value = 20 + [int](50 * $i / [Math]::Max(1, $total))
            Set-Status "正在释放文件  $i / $total"
        }
        $zip.Dispose(); $ms.Dispose()

        $exePath = Join-Path $dir $EXE_NAME

        # 2) 图标缓存 (给快捷方式用)
        $icoPath = Join-Path $dir "cat.ico"
        if (Test-Path -LiteralPath $icoPath) { }

        # 3) 快捷方式
        $progress.Value = 76
        Set-Status "正在创建快捷方式..."
        $desktop = [Environment]::GetFolderPath("Desktop")
        $startMenu = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
        if ($chkDesktop.Checked) { $null = New-Shortcut (Join-Path $desktop "$APP_NAME.lnk") $exePath $dir $exePath }
        if ($chkStart.Checked)   { $null = New-Shortcut (Join-Path $startMenu "$APP_NAME.lnk") $exePath $dir $exePath }

        # 4) 卸载信息 (写入 HKCU, 不需要管理员)
        $progress.Value = 86
        Set-Status "正在注册卸载信息..."
        if ($chkUninst.Checked) {
            if (-not (Test-Path $REG_KEY)) { New-Item -Path $REG_KEY -Force | Out-Null }
            $uninstExe = Join-Path $dir "Uninstall.exe"
            $sizeKb = 0
            try { $sizeKb = [int](((Get-ChildItem -LiteralPath $dir -Recurse -File | Measure-Object -Property Length -Sum).Sum) / 1KB) } catch { }
            $props = @{
                DisplayName     = $APP_NAME
                DisplayVersion  = $APP_VER
                Publisher       = $APP_PUB
                DisplayIcon     = $exePath
                InstallLocation = $dir
                UninstallString = "`"$uninstExe`""
                QuietUninstallString = "`"$uninstExe`" /S"
                NoModify        = 1
                NoRepair        = 1
                EstimatedSize   = $sizeKb
            }
            foreach ($k in $props.Keys) {
                try { New-ItemProperty -Path $REG_KEY -Name $k -Value $props[$k] -PropertyType $(if ($props[$k] -is [int]) { "DWord" } else { "String" }) -Force | Out-Null } catch { }
            }
        }

        # 5) 安装记录
        $progress.Value = 94
        Set-Status "正在写入安装记录..."
        $info = "hajimi客户端 安装记录`r`n安装时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`n版本: $APP_VER`r`n安装目录: $dir`r`n"
        [System.IO.File]::WriteAllText((Join-Path $dir "install-info.txt"), $info, (New-Object System.Text.UTF8Encoding($true)))

        $progress.Value = 100
        Set-Status "安装完成！"
        $script:installed = $true
        $script:installDir = $dir
        $btnMain.Text = "完  成"
        $btnMain.Enabled = $true

        if ($chkRun.Checked) {
            try { Start-Process -FilePath $exePath -WorkingDirectory $dir } catch { }
            Start-Sleep -Milliseconds 600
        }
        $form.Close()
    } catch {
        $btnMain.Enabled = $true
        $btnBrowse.Enabled = $true
        $txtDir.Enabled = $true
        $progress.Value = 0
        Set-Status "安装失败"
        [System.Windows.Forms.MessageBox]::Show("安装失败：`n`n$($_.Exception.Message)", $APP_NAME, "OK", "Error") | Out-Null
    }
}

$btnBrowse.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = "选择安装位置"
    if (Test-Path -LiteralPath $txtDir.Text) { $fbd.SelectedPath = $txtDir.Text }
    if ($fbd.ShowDialog() -eq "OK") { $txtDir.Text = $fbd.SelectedPath }
})
$btnMain.Add_Click({
    if ($script:installed) { $form.Close(); return }
    Start-Install
})
$form.Add_Shown({
    # 从自身提取图标显示 (用 exe 关联图标)
    try {
        $ico = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
        if ($ico) { $picIcon.Image = $ico.ToBitmap() }
    } catch { }
})

[void]$form.ShowDialog()
