; ============================================================
;  hajimi客户端 安装包 (Inno Setup)
;  为什么换掉原来的 PS2EXE 自解压安装器:
;   1) PS2EXE 打包的 exe + 内嵌 base64 负载, 极易被杀软/SmartScreen 当作
;      "打包型投放器" 误报 (用户反馈报恶意软件)
;   2) Inno Setup 是业界标准安装器, 白名单覆盖好得多
;   3) 自带正规卸载程序与「应用和功能」入口, 不用手写注册表
;
;  特点: 免管理员权限 (装到用户目录), 免 UAC
;  编译: "C:\Users\<你>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" HajimiSetup.iss
; ============================================================

#define MyAppName "hajimi客户端"
#define MyAppVersion "3.9"
#define MyAppPublisher "hajimi"
#define MyAppExeName "MusicBox.exe"

[Setup]
AppId={{A3F1C8E2-7D45-4B9A-8E31-2F6B9C4D5A70}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={localappdata}\Programs\hajimi客户端
DisableDirPage=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir=dist
OutputBaseFilename=HajimiClient-Setup
SetupIconFile=..\cat_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
AllowNoIcons=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

; 关键提示改中文 (不依赖外部语言包, 更稳)
[Messages]
SetupAppTitle=安装程序
SetupWindowTitle=安装 - %1
WelcomeLabel1=欢迎安装 [name]
WelcomeLabel2=即将在你的电脑上安装 [name/ver]。%n%n点击「Next」继续。
SelectDirLabel3=安装程序将把 [name] 安装到下面的文件夹。
SelectTasksLabel2=请选择安装程序要执行的附加任务，然后点击「Next」。
ReadyLabel1=安装程序已准备好，可以开始安装 [name]。
InstallingLabel=正在安装 [name]，请稍候...
FinishedHeadingLabel=安装完成
FinishedLabel=安装完成！[name] 已经可以使用了。%n%n程序目录：%n%1
ButtonNext=下一步(&N) >
ButtonBack=< 上一步(&B)
ButtonInstall=安装(&I)
ButtonFinish=完成(&F)
ButtonCancel=取消

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务："

[Files]
Source: "..\MusicBox.exe";                            DestDir: "{app}"; Flags: ignoreversion
Source: "..\Microsoft.Web.WebView2.Core.dll";         DestDir: "{app}"; Flags: ignoreversion
Source: "..\Microsoft.Web.WebView2.WinForms.dll";     DestDir: "{app}"; Flags: ignoreversion
Source: "..\WebView2Loader.dll";                      DestDir: "{app}"; Flags: ignoreversion
Source: "使用说明.txt";                                DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{autodesktop}\{#MyAppName}";  Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "运行 {#MyAppName}"; Flags: nowait postinstall skipifsilent

; 卸载时清掉运行时生成的缓存与日志
; userdata / cover_cache 故意保留 —— 收藏、歌单、播放历史不会因为卸载而丢失
[UninstallDelete]
Type: files; Name: "{app}\diag.txt"
Type: filesandordirs; Name: "{app}\MusicBox.exe.WebView2"
Type: dirifempty; Name: "{app}"
