# ============================================================
#  MusicBox (Free) v3.6 - Apple Music 风格 · 响应式布局 · 中英双语
#  右上角按钮可切换 中文 / English, 选择会被记住
#  设计: 左侧边栏 | 白色卡片 | 品牌红 #FA243C | 浅灰底 #F5F5F7
#  响应式: 窗口任意缩放, 小窗/最大化/全屏(F11)自动重排;
#          「完整听」页列表:视频 = 4:6 (视频更大), 其他页 6:4
#  功能: 全网搜索试听(Deezer) | 免费完整播放(YouTube) | 本地音乐
#       收藏/歌单/历史 | 睡眠定时 | 拖拽导入 | 快捷键 | 搜索历史
#       播完自动下一首 | 记住上次播放 | 开机自启动
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 程序所在目录 (便携化: 数据目录跟随程序位置, 不再依赖固定盘符)
# 优先用脚本目录(直接运行 .ps1 时), 否则用可执行文件目录(编译成 exe 时)
$appBase = $PSScriptRoot
if (-not $appBase -or $appBase -eq "") {
    try { $appBase = [System.IO.Path]::GetDirectoryName([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) } catch { $appBase = "" }
}
if (-not $appBase -or $appBase -eq "") { $appBase = (Get-Location).Path }

# 加载 WebView2 (Edge 内核); 缺失则功能降级不影响其他模块
$script:hasYt = $false
$ytBase = $appBase
$ytCore = Join-Path $ytBase "Microsoft.Web.WebView2.Core.dll"
$ytWin = Join-Path $ytBase "Microsoft.Web.WebView2.WinForms.dll"
try {
    if ((Test-Path -LiteralPath $ytCore) -and (Test-Path -LiteralPath $ytWin)) {
        Add-Type -Path $ytWin
        Add-Type -Path $ytCore
        $script:hasYt = $true
    }
} catch { $script:hasYt = $false }

$ErrorActionPreference = "SilentlyContinue"

# ---------- Apple Music 调色板 ----------
$cBg        = [System.Drawing.Color]::FromArgb(245, 245, 247)
$cCard      = [System.Drawing.Color]::FromArgb(255, 255, 255)
$cSidebarBg = [System.Drawing.Color]::FromArgb(245, 245, 247)
$cAccent    = [System.Drawing.Color]::FromArgb(250, 36, 60)
$cAccentDk  = [System.Drawing.Color]::FromArgb(224, 26, 48)
$cText      = [System.Drawing.Color]::FromArgb(29, 29, 31)
$cSub       = [System.Drawing.Color]::FromArgb(134, 134, 139)
$cHair      = [System.Drawing.Color]::FromArgb(210, 210, 215)
$cHover     = [System.Drawing.Color]::FromArgb(232, 232, 237)
$cFill      = [System.Drawing.Color]::FromArgb(232, 232, 237)
$cPillBg    = [System.Drawing.Color]::FromArgb(255, 230, 233)
$cWhite     = [System.Drawing.Color]::FromArgb(255, 255, 255)
$cSuccess   = [System.Drawing.Color]::FromArgb(52, 199, 89)
$cWarn      = [System.Drawing.Color]::FromArgb(255, 149, 0)
$cInputBg   = [System.Drawing.Color]::FromArgb(232, 232, 237)

# ---------- 字体 ----------
$fUI = "Microsoft YaHei UI"

# ============================================================
#  多语言 (中文 / English) —— 右上角按钮切换, 选择会记住
# ============================================================
$script:lang = "zh"
$script:L = @{
    'app.title'          = @{ zh = "MusicBox（免费）"; en = "MusicBox (Free)" }
    'brand.sub'          = @{ zh = "免费音乐盒"; en = "Free Music Player" }
    'autostart'          = @{ zh = "开机自动启动"; en = "Start with Windows" }

    'nav.free'           = @{ zh = "完整听"; en = "Listen" }
    'nav.search'         = @{ zh = "搜索"; en = "Search" }
    'nav.local'          = @{ zh = "本地音乐"; en = "Local Music" }
    'nav.fav'            = @{ zh = "我的收藏"; en = "Favorites" }
    'nav.playlist'       = @{ zh = "歌单"; en = "Playlists" }
    'nav.spot'           = @{ zh = "Spotify 榜单"; en = "Spotify Charts" }

    'page.free.t'        = @{ zh = "完整听"; en = "Listen Now" }
    'page.free.s'        = @{ zh = "YouTube 完整歌曲 · 免费在线播放"; en = "Full songs on YouTube · free streaming" }
    'page.search.t'      = @{ zh = "搜索"; en = "Search" }
    'page.search.s'      = @{ zh = "全网曲库 · 版权歌曲官方 30 秒试听"; en = "Global catalog · official 30s previews" }
    'page.local.t'       = @{ zh = "本地音乐"; en = "Local Music" }
    'page.local.s'       = @{ zh = "播放你电脑里的音乐文件"; en = "Play music files on your PC" }
    'page.fav.t'         = @{ zh = "我的收藏"; en = "Favorites" }
    'page.fav.s'         = @{ zh = "收藏的歌曲 · 双击即可播放"; en = "Saved songs · double-click to play" }
    'page.playlist.t'    = @{ zh = "歌单"; en = "Playlists" }
    'page.playlist.s'    = @{ zh = "自建歌单 · 管理你的音乐收藏"; en = "Build playlists from your library" }
    'page.spot.t'        = @{ zh = "Spotify 榜单"; en = "Spotify Charts" }
    'page.spot.s'        = @{ zh = "官方播放列表 · 无需登录"; en = "Official playlists · no sign-in needed" }

    'search.tip'         = @{ zh = "版权歌曲官方 30 秒试听 · 双击歌曲在线试听"; en = "Official 30-second previews · double-click a song to listen" }
    'search.btn'         = @{ zh = "搜索"; en = "Search" }
    'search.hist'        = @{ zh = "历史记录"; en = "History" }
    'search.histitem'    = @{ zh = "── 搜索历史 ──"; en = "── Search History ──" }
    'search.playsel'     = @{ zh = "▶  播放试听"; en = "▶  Play Preview" }
    'search.info'        = @{ zh = "版权 30s 试听 · 完整听去「完整听」页"; en = "30s previews · use the Listen page for full songs" }

    'free.btn'           = @{ zh = "搜索"; en = "Search" }
    'free.daily'         = @{ zh = "🎵  每日精选"; en = "🎵  Daily Picks" }
    'free.tip'           = @{ zh = "YouTube 完整歌曲 · 双击直接听 · 例如 weezer / 周杰伦 / lofi"; en = "Full songs on YouTube · double-click to play · e.g. weezer / lofi" }
    'free.full'          = @{ zh = "♾  完整播放"; en = "♾  Play Full" }
    'free.browser'       = @{ zh = "↗  浏览器打开"; en = "↗  Open in Browser" }
    'free.info'          = @{ zh = "双击或点「完整播放」→ 右侧播放器直接看"; en = "Double-click or press Play Full — it opens in the player" }

    'local.open'         = @{ zh = "📂  打开音乐文件夹"; en = "📂  Open Music Folder" }
    'local.tip'          = @{ zh = "支持 MP3 / FLAC / WAV / M4A · 也可把文件拖到窗口"; en = "Supports MP3 / FLAC / WAV / M4A · or drag files into the window" }
    'local.play'         = @{ zh = "▶  播放"; en = "▶  Play" }
    'local.choose'       = @{ zh = "选择音乐文件夹"; en = "Choose a music folder" }
    'local.found'        = @{ zh = "找到 {0} 首音乐文件"; en = "Found {0} music files" }
    'local.dropped'      = @{ zh = "已拖入 {0} 首音乐文件 · 双击播放"; en = "Added {0} files · double-click to play" }

    'spot.title'         = @{ zh = "Spotify 官方榜单 · 点类型按钮切换流派"; en = "Spotify official charts · pick a genre" }
    'spot.hint'          = @{ zh = "数据来源: Spotify 官方播放列表 embed · 无需登录 · 可点歌曲试听"; en = "Source: official Spotify playlist embeds · no sign-in needed" }
    'spot.all'           = @{ zh = "全部"; en = "All" }

    'fav.playall'        = @{ zh = "▶  全部播放"; en = "▶  Play All" }
    'fav.clear'          = @{ zh = "🗑  清空收藏"; en = "🗑  Clear Favorites" }
    'fav.title'          = @{ zh = "共 {0} 首歌曲 · 双击播放 · 右键取消收藏"; en = "{0} songs · double-click to play · right-click to remove" }
    'fav.confirm'        = @{ zh = "确定清空全部 {0} 首收藏吗？"; en = "Remove all {0} favorites?" }

    'pl.empty'           = @{ zh = "还没有歌单 · 输入名字点「新建歌单」开始"; en = "No playlists yet · type a name and click New Playlist" }
    'pl.new'             = @{ zh = "➕  新建歌单"; en = "➕  New Playlist" }
    'pl.addcur'          = @{ zh = "＋ 加入当前歌曲"; en = "＋ Add Current Song" }
    'pl.delete'          = @{ zh = "🗑 删除歌单"; en = "🗑 Delete Playlist" }
    'pl.title'           = @{ zh = "{0} 首歌曲 · 双击播放 · 右键移除"; en = "{0} songs · double-click to play · right-click to remove" }
    'pl.enter'           = @{ zh = "请输入歌单名"; en = "Please enter a playlist name" }
    'pl.exists'          = @{ zh = "歌单已存在"; en = "Playlist already exists" }
    'pl.select'          = @{ zh = "请先选择或新建歌单"; en = "Select or create a playlist first" }
    'pl.confirmdel'      = @{ zh = "确定删除歌单「{0}」吗？"; en = "Delete playlist ""{0}""?" }

    'player.notplaying'  = @{ zh = "未播放"; en = "Not Playing" }
    'player.ytalbum'     = @{ zh = "YouTube 完整版"; en = "YouTube Full" }
    'player.mode.yt'     = @{ zh = "内置播放器播放中"; en = "Playing in built-in player" }
    'player.mode.ytbg'   = @{ zh = "已后台打开 YouTube 播放"; en = "Opened YouTube in background" }
    'player.mode.full'   = @{ zh = "完整播放"; en = "Full Playback" }
    'player.mode.preview'= @{ zh = "官方试听 30s"; en = "30s Preview" }
    'player.mode.local'  = @{ zh = "本地播放"; en = "Local Playback" }
    'player.fail'        = @{ zh = "播放失败"; en = "Playback failed" }
    'player.lastplay'    = @{ zh = "上次播放 · 点 ▶ 继续"; en = "Last played · press ▶ to resume" }
    'player.fav'         = @{ zh = "♡  收藏"; en = "♡  Favorite" }
    'player.faved'       = @{ zh = "♥  已收藏"; en = "♥  Favorited" }
    'player.vol'         = @{ zh = "音量"; en = "Volume" }
    'player.state.ready' = @{ zh = "●  就绪"; en = "●  Ready" }
    'player.state.playing'= @{ zh = "♫  播放中"; en = "♫  Playing" }
    'player.state.paused'= @{ zh = "⏸  已暂停"; en = "⏸  Paused" }
    'player.elsewhere'   = @{ zh = "在其他平台收听"; en = "Listen Elsewhere" }
    'player.srchint'     = @{ zh = "点击跳转对应平台搜索当前歌曲"; en = "Open this song on another platform" }
    'player.sleep'       = @{ zh = "睡眠定时"; en = "Sleep Timer" }
    'sleep.15'           = @{ zh = "15分"; en = "15m" }
    'sleep.30'           = @{ zh = "30分"; en = "30m" }
    'sleep.60'           = @{ zh = "60分"; en = "60m" }
    'sleep.off'          = @{ zh = "取消"; en = "Cancel" }
    'sleep.stopped'      = @{ zh = "已定时停止播放"; en = "Stopped by sleep timer" }
    'sleep.left'         = @{ zh = "{0} 分钟后停止"; en = "Stops in {0} min" }

    'st.enterkw'         = @{ zh = "请输入搜索关键词"; en = "Please enter a search keyword" }
    'st.deezersearch'    = @{ zh = "正在搜索全球曲库..."; en = "Searching the global catalog..." }
    'st.found'           = @{ zh = "找到 {0} 首歌曲 · 双击在线试听"; en = "Found {0} songs · double-click to preview" }
    'st.notfound'        = @{ zh = "没有找到结果，换个关键词试试"; en = "No results — try another keyword" }
    'st.fail'            = @{ zh = "搜索失败: {0}"; en = "Search failed: {0}" }
    'st.ytsearch'        = @{ zh = "正在搜索 YouTube 完整歌曲..."; en = "Searching YouTube..." }
    'st.ytfound'         = @{ zh = "找到 {0} 个 YouTube 完整视频 · 双击直接播放"; en = "Found {0} videos · double-click to play" }
    'st.ytnotfound'      = @{ zh = "没有找到结果，试试 weezer / 周杰伦 / lofi"; en = "No results — try weezer / lofi" }
    'st.loading'         = @{ zh = "正在加载「{0}」..."; en = "Loading ""{0}""..." }
    'st.fetching'        = @{ zh = "「{0}」: 正在抓取「{1}」..."; en = "{0}: fetching ""{1}""..." }
    'st.picksdone'       = @{ zh = "{0} · 共 {1} 首 · 双击直接播放"; en = "{0} · {1} songs · double-click to play" }
    'st.picksfail'       = @{ zh = "暂时获取失败，请手动搜索"; en = "Could not load — please search manually" }
    'st.enterkwshort'    = @{ zh = "请输入关键词"; en = "Please enter a keyword" }
    'unknown.song'       = @{ zh = "未知歌曲"; en = "Unknown Title" }
    'unknown.artist'     = @{ zh = "未知歌手"; en = "Unknown Artist" }
    'picks.suffix'       = @{ zh = "「{0}」精选"; en = "{0} Picks" }

    'col.song'           = @{ zh = "歌曲"; en = "Song" }
    'col.artist'         = @{ zh = "歌手"; en = "Artist" }
    'col.album'          = @{ zh = "专辑"; en = "Album" }
    'col.duration'       = @{ zh = "时长"; en = "Time" }
    'col.songvideo'      = @{ zh = "歌曲 / 视频"; en = "Song / Video" }
    'col.channel'        = @{ zh = "频道"; en = "Channel" }
    'col.format'         = @{ zh = "格式"; en = "Format" }
    'col.size'           = @{ zh = "大小"; en = "Size" }
    'col.source'         = @{ zh = "歌手/来源"; en = "Artist / Source" }
    'col.type'           = @{ zh = "类型"; en = "Type" }
    'col.action'         = @{ zh = "操作"; en = "Action" }

    'item.preview'       = @{ zh = "30s 试听"; en = "30s Preview" }
    'item.full'          = @{ zh = "完整版"; en = "Full" }
    'item.local'         = @{ zh = "本地"; en = "Local" }
    'item.rightremove'   = @{ zh = "右键移除"; en = "right-click to remove" }

    'msg.needplay'       = @{ zh = "请先播放一首歌曲"; en = "Please play a song first" }
    'msg.needplay.plat'  = @{ zh = "请先播放一首歌曲，再查看其它平台的资源"; en = "Please play a song first, then try other platforms" }
    'msg.selectsong'     = @{ zh = "请先选中一首歌曲"; en = "Please select a song first" }
    'msg.novideourl'     = @{ zh = "该条目无视频地址"; en = "This item has no video URL" }
    'msg.tip'            = @{ zh = "提示"; en = "Notice" }
    'msg.confirm'        = @{ zh = "确认"; en = "Confirm" }
}
function T {
    param($key)
    $e = $script:L[$key]
    if ($null -eq $e) { return $key }
    if ($script:lang -eq "en") { return $e.en }
    return $e.zh
}
# 首页推荐分类的中英对照
$script:catLabelsEn = @{
    "🎵 每日精选" = "🎵 Daily Picks"
    "华语金曲"   = "Mandarin Hits"
    "Lofi 助眠"  = "Lofi & Sleep"
    "欧美流行"   = "Western Pop"
    "说唱嘻哈"   = "Hip-Hop"
    "电音派对"   = "EDM Party"
    "经典摇滚"   = "Classic Rock"
    "治愈系"     = "Healing & Chill"
}
function CatLabel {
    param($zh)
    if ($script:lang -eq "en" -and $script:catLabelsEn.ContainsKey($zh)) { return $script:catLabelsEn[$zh] }
    return $zh
}
# 把界面上的静态文字全部按当前语言重设一遍
function Apply-Language {
    $form.Text = T 'app.title'
    $lblBrandSub.Text = T 'brand.sub'
    $script:chkAutoStart.Text = T 'autostart'
    # 侧栏导航
    $navIcons = @{ "free"="♾"; "search"="♫"; "local"="▤"; "fav"="♥"; "playlist"="☰"; "spot"="◉" }
    foreach ($k in $script:navButtons.Keys) {
        $script:navButtons[$k].Text = "$($navIcons[$k])   $(T "nav.$k")"
    }
    # 搜索页
    $script:lblSearchStatus.Text = T 'search.tip'
    $script:btnSearch.Text = T 'search.btn'
    $script:lblHistHint.Text = T 'search.hist'
    $script:btnPlaySel.Text = T 'search.playsel'
    $script:lblSearchInfo.Text = T 'search.info'
    $script:lvSearch.Columns[0].Text = T 'col.song'
    $script:lvSearch.Columns[1].Text = T 'col.artist'
    $script:lvSearch.Columns[2].Text = T 'col.album'
    $script:lvSearch.Columns[3].Text = T 'col.duration'
    # 完整听页
    $script:btnFreeSearch.Text = T 'free.btn'
    $script:btnDailyPicks.Text = T 'free.daily'
    $script:lblFreeStatus.Text = T 'free.tip'
    $script:btnFreePlay.Text = T 'free.full'
    $script:btnFreeDownload.Text = T 'free.browser'
    $script:lblFreeInfo.Text = T 'free.info'
    $script:lvFree.Columns[0].Text = T 'col.songvideo'
    $script:lvFree.Columns[1].Text = T 'col.channel'
    $script:lvFree.Columns[2].Text = T 'col.duration'
    # 本地页
    $script:btnOpenFolder.Text = T 'local.open'
    $script:lblLocalStatus.Text = T 'local.tip'
    $script:btnLocalPlay.Text = T 'local.play'
    $script:lvLocal.Columns[0].Text = T 'col.song'
    $script:lvLocal.Columns[1].Text = T 'col.format'
    $script:lvLocal.Columns[2].Text = T 'col.size'
    # Spotify 页
    $script:lblSpotTitle.Text = T 'spot.title'
    $script:lblSpotHint.Text = T 'spot.hint'
    if ($null -ne $script:spotCat["all"]) { $script:spotCat["all"].Text = T 'spot.all' }
    # 收藏页
    $script:btnFavPlayAll.Text = T 'fav.playall'
    $script:btnFavClear.Text = T 'fav.clear'
    $script:lvFav.Columns[0].Text = T 'col.song'
    $script:lvFav.Columns[1].Text = T 'col.source'
    $script:lvFav.Columns[2].Text = T 'col.type'
    # 歌单页
    $script:btnPlCreate.Text = T 'pl.new'
    $script:btnPlAddCur.Text = T 'pl.addcur'
    $script:btnPlDelete.Text = T 'pl.delete'
    $script:lvPlaylist.Columns[0].Text = T 'col.song'
    $script:lvPlaylist.Columns[1].Text = T 'col.source'
    $script:lvPlaylist.Columns[2].Text = T 'col.action'
    # 播放面板
    $script:lblVol.Text = T 'player.vol'
    $script:lblSrcTitle.Text = T 'player.elsewhere'
    $script:lblSrcHint.Text = T 'player.srchint'
    $script:lblSleepTitle.Text = T 'player.sleep'
    $script:btnSleep15.Text = T 'sleep.15'
    $script:btnSleep30.Text = T 'sleep.30'
    $script:btnSleep60.Text = T 'sleep.60'
    $script:btnSleepOff.Text = T 'sleep.off'
    $script:lblState.Text = T 'player.state.ready'
    if (-not $script:currentTitle -or $script:currentTitle -eq "未播放" -or $script:currentTitle -eq "Not Playing") {
        $script:lblSongTitle.Text = T 'player.notplaying'
    }
    # 语言切换按钮显示"目标语言"
    $script:btnLang.Text = $(if ($script:lang -eq "zh") { "English" } else { "中文" })
    # 依赖状态的动态文本
    Refresh-SearchHistoryCombo
    Refresh-FavList
    Refresh-PlaylistItems
    Update-FavButton
    Switch-Page $script:currentPage
}

# ---------- 状态 ----------
$script:player = $null
$script:currentUrl = ""
$script:currentTitle = ""
$script:currentArtist = ""
$script:currentAlbum = ""
$script:currentCover = ""
$script:searchResults = @()
$script:freeResults = @()
$script:localFiles = @()
$script:localIndex = -1
$script:currentPage = "free"
$script:playMode = "preview"
$script:ytPlaying = $false
$script:ytDur = 0
$script:ytLoadedUrl = ""   # 已在内置播放器载入的视频 (yt:<id>), 判断是否需要重新加载
$script:cssCount = 0
$script:ytMaximized = $false
$script:cacheDir = Join-Path $appBase "cover_cache"
$script:dataDir = Join-Path $appBase "userdata"
$script:favorites = @()
$script:history = @()
$script:searchHistory = @()
$script:playlists = @{}
$script:playlistNames = @()
$script:sleepTimer = $null
$script:sleepDeadline = $null
$script:lastVolume = 80
$script:autoStart = $false
$script:exePath = $null
$script:trackKey = ""
$script:autoNextBusy = $false
$script:cboHistReady = $false
$script:navButtons = @{}
$script:fullscreen = $false
$script:prevBorderStyle = $null
$script:prevBounds = $null
$script:videoRect = New-Object System.Drawing.Rectangle(0, 0, 392, 392)  # 视频/封面区, Apply-Layout 会更新

# ---------- 工具 ----------
function Format-Duration {
    param($sec)
    if ($null -eq $sec -or $sec -eq "") { return "--:--" }
    $s = [int]$sec
    $m = [math]::Floor($s / 60)
    $ss = $s % 60
    return ("{0}:{1:00}" -f $m, $ss)
}

function New-Label {
    param($text, $x, $y, $w, $h, $size, $color, $bold)
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text
    $l.SetBounds($x, $y, $w, $h)
    $l.Font = New-Object System.Drawing.Font($fUI, $size, $(if($bold){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}))
    $l.ForeColor = $color
    $l.BackColor = [System.Drawing.Color]::Transparent
    return $l
}

function New-Btn {
    param($text, $x, $y, $w, $h, $bg, $fg, $size = 10, $bold = $false)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.SetBounds($x, $y, $w, $h)
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.FlatAppearance.BorderSize = 0
    $b.BackColor = $bg
    $b.ForeColor = $fg
    $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $b.Font = New-Object System.Drawing.Font($fUI, $size, $(if($bold){[System.Drawing.FontStyle]::Bold}else{[System.Drawing.FontStyle]::Regular}))
    $b.UseVisualStyleBackColor = $false
    $b.TabStop = $false
    $hover = if ($fg -eq $cWhite) { $cAccentDk } else { $cHover }
    $b.FlatAppearance.MouseOverBackColor = $hover
    $b.FlatAppearance.MouseDownBackColor = $hover
    return $b
}

function New-PrimaryBtn {
    param($text, $x, $y, $w, $h, $size = 10)
    return (New-Btn $text $x $y $w $h $cAccent $cWhite $size $false)
}

function New-SecondaryBtn {
    param($text, $x, $y, $w, $h, $size = 10)
    return (New-Btn $text $x $y $w $h $cFill $cText $size $false)
}

function New-ListView {
    param($x, $y, $w, $h, $columns)
    $lv = New-Object System.Windows.Forms.ListView
    $lv.SetBounds($x, $y, $w, $h)
    $lv.View = [System.Windows.Forms.View]::Details
    $lv.FullRowSelect = $true
    $lv.GridLines = $false
    $lv.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $lv.BackColor = $cCard
    $lv.ForeColor = $cText
    $lv.Font = New-Object System.Drawing.Font($fUI, 10)
    $lv.MultiSelect = $false
    $lv.HideSelection = $false
    $imgList = New-Object System.Windows.Forms.ImageList
    $imgList.ImageSize = New-Object System.Drawing.Size(1, 38)
    $imgList.ColorDepth = [System.Windows.Forms.ColorDepth]::Depth32Bit
    $lv.SmallImageList = $imgList
    foreach ($c in $columns) {
        $lv.Columns.Add($c.Name, $c.Width) | Out-Null
    }
    return $lv
}

function New-TextBox {
    param($x, $y, $w, $h, $size = 10.5)
    $t = New-Object System.Windows.Forms.TextBox
    $t.SetBounds($x, $y, $w, $h)
    $t.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $t.Font = New-Object System.Drawing.Font($fUI, $size)
    $t.BackColor = $cInputBg
    $t.ForeColor = $cText
    return $t
}

function New-Hairline {
    param($x, $y, $w)
    $p = New-Object System.Windows.Forms.Panel
    $p.SetBounds($x, $y, $w, 1)
    $p.BackColor = $cHair
    return $p
}

# ---------- 播放器 ----------
function Init-Player {
    if ($null -eq $script:player) {
        $script:player = New-Object -ComObject WMPlayer.OCX
        $script:player.settings.volume = $script:lastVolume
        $script:player.settings.autoStart = $false
    }
}

function Get-CoverPath {
    param($url)
    if (-not $url -or $url -eq "") { return "" }
    if (-not (Test-Path $script:cacheDir)) { New-Item -ItemType Directory -Path $script:cacheDir -Force | Out-Null }
    $hash = ([System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($url)))).Replace("-","").Substring(0,16)
    $path = Join-Path $script:cacheDir ($hash + ".jpg")
    if (Test-Path $path) { return $path }
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        $wc.DownloadFile($url, $path)
        return $path
    } catch { return "" }
}

function Show-Cover {
    param($url)
    $script:lblCoverEmpty.Visible = $false
    if ($url -and $url -ne "") {
        $local = Get-CoverPath $url
        if ($local -and (Test-Path $local)) {
            try {
                $img = [System.Drawing.Image]::FromFile($local)
                $script:picCover.Image = $img
                $script:picCover.Visible = $true
                return
            } catch { }
        }
    }
    $script:picCover.Image = $null
    $script:picCover.Visible = $false
    $script:lblCoverEmpty.Visible = $true
}

function Open-Platform {
    param($platform)
    if ($script:currentTitle -eq "" -or $script:currentTitle -eq "未播放" -or $script:currentTitle -eq "Not Playing") {
        [System.Windows.Forms.MessageBox]::Show((T 'msg.needplay.plat'), (T 'msg.tip'), "OK", "Information") | Out-Null
        return
    }
    $q = "$($script:currentTitle) $($script:currentArtist)"
    $enc = [uri]::EscapeDataString($q)
    switch ($platform) {
        "apple"   { $url = "https://music.apple.com/cn/search?term=$enc" }
        "spotify" { $url = "https://open.spotify.com/search/$enc" }
        "netease" { $url = "https://music.163.com/#/search/m/?s=$enc" }
        "sound"   { $url = "https://soundcloud.com/search?q=$enc" }
        "qq"      { $url = "https://y.qq.com/n/ryqq/search?w=$enc" }
    }
    try { Start-Process $url } catch { }
}

# ---------- YouTube ----------
function Show-YoutubeEmbed {
    param($videoId)
    if (-not $script:hasYt -or $null -eq $script:wbYT) { return $false }
    try {
        if ($null -eq $script:wbYT.CoreWebView2) {
            $script:wbYT.EnsureCoreWebView2Async($null) | Out-Null
            $deadline = (Get-Date).AddSeconds(20)
            while ($null -eq $script:wbYT.CoreWebView2 -and (Get-Date) -lt $deadline) {
                [System.Windows.Forms.Application]::DoEvents()
                Start-Sleep -Milliseconds 100
            }
        }
        if ($null -eq $script:wbYT.CoreWebView2) { return $false }
        try { $script:wbYT.CoreWebView2.Settings.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" } catch { }
        $script:wbYT.Visible = $true
        if ($script:picCover) { $script:picCover.Visible = $false }
        if ($script:lblCoverEmpty) { $script:lblCoverEmpty.Visible = $false }
        $script:wbYT.Source = [uri]("https://www.youtube.com/watch?v=" + $videoId + "&autoplay=1")
        $script:ytLoadedUrl = "yt:$videoId"
        if ($null -ne $script:cssTimer) { $script:cssCount = 0; $script:cssTimer.Stop(); $script:cssTimer.Start() }
        return $true
    } catch { return $false }
}
function Yt-Play {
    if (-not $script:hasYt -or $null -eq $script:wbYT -or $null -eq $script:wbYT.CoreWebView2) { return }
    try { $null = $script:wbYT.CoreWebView2.ExecuteScriptAsync("(function(){var v=document.querySelector('#movie_player video')||document.querySelector('video');if(v){v.play();}})();") } catch { }
}
function Yt-Pause {
    if (-not $script:hasYt -or $null -eq $script:wbYT -or $null -eq $script:wbYT.CoreWebView2) { return }
    try { $null = $script:wbYT.CoreWebView2.ExecuteScriptAsync("(function(){var v=document.querySelector('#movie_player video')||document.querySelector('video');if(v){v.pause();}})();") } catch { }
}
function Yt-Seek {
    param($pos)
    if (-not $script:hasYt -or $null -eq $script:wbYT -or $null -eq $script:wbYT.CoreWebView2) { return }
    try { $null = $script:wbYT.CoreWebView2.ExecuteScriptAsync("(function(){var v=document.querySelector('#movie_player video')||document.querySelector('video');if(v){v.currentTime=$pos;}})();") } catch { }
}
function Yt-State {
    if (-not $script:hasYt -or $null -eq $script:wbYT -or $null -eq $script:wbYT.CoreWebView2) { return $null }
    try {
        $js = "(function(){var v=document.querySelector('#movie_player video')||document.querySelector('video');if(!v){return 'none';}return (v.currentTime||0)+'|'+(v.duration||0)+'|'+(!v.paused);})();"
        $r = $script:wbYT.CoreWebView2.ExecuteScriptAsync($js).Result
        if ($null -eq $r) { return $null }
        $parts = $r -split '\|'
        if ($parts.Count -ge 3) {
            return @{ Pos = [double]$parts[0]; Dur = [double]$parts[1]; Playing = ($parts[2] -eq 'True') }
        }
        return $null
    } catch { return $null }
}

# ---------- 数据层 ----------
function Get-TrackKey {
    param($t)
    if ($null -eq $t) { return "" }
    if ($t.videoId) { return "yt:$($t.videoId)" }
    if ($t.url) { return "url:$($t.url)" }
    return "t:$($t.title)|$($t.artist)"
}
function Add-ToFavorites {
    param($track)
    if ($null -eq $track) { return $false }
    $key = Get-TrackKey $track
    foreach ($f in $script:favorites) { if ((Get-TrackKey $f) -eq $key) { return $false } }
    $obj = [pscustomobject]@{ title=[string]$track.title; artist=[string]$track.artist; album=[string]$track.album; cover=[string]$track.cover; mode=[string]$track.mode; url=[string]$track.url; videoId=[string]$track.videoId }
    $script:favorites += $obj
    Save-UserData
    return $true
}
function Remove-FromFavorites {
    param($key)
    $script:favorites = @($script:favorites | Where-Object { (Get-TrackKey $_) -ne $key })
    Save-UserData
}
function Test-InFavorites {
    param($key)
    foreach ($f in $script:favorites) { if ((Get-TrackKey $f) -eq $key) { return $true } }
    return $false
}
function Add-ToHistory {
    param($track)
    if ($null -eq $track) { return }
    $key = Get-TrackKey $track
    $script:history = @($script:history | Where-Object { (Get-TrackKey $_) -ne $key })
    $obj = [pscustomobject]@{ title=[string]$track.title; artist=[string]$track.artist; album=[string]$track.album; cover=[string]$track.cover; mode=[string]$track.mode; url=[string]$track.url; videoId=[string]$track.videoId }
    $script:history = @($obj) + $script:history
    if ($script:history.Count -gt 200) { $script:history = $script:history[0..199] }
    Save-UserData
}
function Add-SearchHistory {
    param($q)
    if (-not $q -or $q.Trim() -eq "") { return }
    $q = $q.Trim()
    $script:searchHistory = @($script:searchHistory | Where-Object { $_ -ne $q })
    $script:searchHistory = @($q) + $script:searchHistory
    if ($script:searchHistory.Count -gt 20) { $script:searchHistory = $script:searchHistory[0..19] }
    Save-UserData
}
function Save-UserData {
    try {
        if (-not (Test-Path $script:dataDir)) { New-Item -ItemType Directory -Path $script:dataDir -Force | Out-Null }
        $fav = @($script:favorites | ForEach-Object { @{ title=$_.title; artist=$_.artist; album=$_.album; cover=$_.cover; mode=$_.mode; url=$_.url; videoId=$_.videoId } })
        $his = @($script:history | ForEach-Object { @{ title=$_.title; artist=$_.artist; album=$_.album; cover=$_.cover; mode=$_.mode; url=$_.url; videoId=$_.videoId } })
        $pl = @{}
        foreach ($k in $script:playlists.Keys) {
            $pl[$k] = @($script:playlists[$k].items | ForEach-Object { @{ title=$_.title; artist=$_.artist; album=$_.album; cover=$_.cover; mode=$_.mode; url=$_.url; videoId=$_.videoId } })
        }
        $obj = @{
            version = 2
            favorites = $fav
            history = $his
            searchHistory = @($script:searchHistory)
            playlists = $pl
            playlistNames = @($script:playlistNames)
            settings = @{ lastVolume = $script:lastVolume; autoStart = $script:autoStart; lang = $script:lang }
            lastPlay = @{ title=$script:currentTitle; artist=$script:currentArtist; album=$script:currentAlbum; cover=$script:currentCover; mode=$script:playMode; url=$script:currentUrl; videoId=$(if($script:currentUrl -like "yt:*"){$script:currentUrl.Substring(3)}else{""}) }
        }
        $json = $obj | ConvertTo-Json -Depth 6
        [System.IO.File]::WriteAllText((Join-Path $script:dataDir "userdata.json"), $json, (New-Object System.Text.UTF8Encoding($false)))
    } catch { }
}
function Load-UserData {
    $path = Join-Path $script:dataDir "userdata.json"
    if (-not (Test-Path $path)) { return }
    try {
        $obj = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($null -eq $obj) { return }
        $script:favorites = @()
        foreach ($f in @($obj.favorites)) { $script:favorites += [pscustomobject]@{ title=[string]$f.title; artist=[string]$f.artist; album=[string]$f.album; cover=[string]$f.cover; mode=[string]$f.mode; url=[string]$f.url; videoId=[string]$f.videoId } }
        $script:history = @()
        foreach ($h in @($obj.history)) { $script:history += [pscustomobject]@{ title=[string]$h.title; artist=[string]$h.artist; album=[string]$h.album; cover=[string]$h.cover; mode=[string]$h.mode; url=[string]$h.url; videoId=[string]$h.videoId } }
        $script:searchHistory = @()
        foreach ($s in @($obj.searchHistory)) { $script:searchHistory += [string]$s }
        $script:playlists = @{}
        $script:playlistNames = @()
        foreach ($n in @($obj.playlistNames)) { $script:playlistNames += [string]$n }
        foreach ($n in $script:playlistNames) {
            $items = @()
            foreach ($it in @($obj.playlists.$n)) { $items += [pscustomobject]@{ title=[string]$it.title; artist=[string]$it.artist; album=[string]$it.album; cover=[string]$it.cover; mode=[string]$it.mode; url=[string]$it.url; videoId=[string]$it.videoId } }
            $script:playlists[$n] = @{ name = $n; items = $items }
        }
        if ($obj.settings) {
            if ($null -ne $obj.settings.lastVolume) { $script:lastVolume = [int]$obj.settings.lastVolume }
            if ($null -ne $obj.settings.autoStart) { $script:autoStart = [bool]$obj.settings.autoStart }
            if ($null -ne $obj.settings.lang -and ([string]$obj.settings.lang) -in @("zh","en")) { $script:lang = [string]$obj.settings.lang }
        }
        $lp = $obj.lastPlay
        if ($lp -and $lp.title) {
            $script:currentTitle = [string]$lp.title; $script:currentArtist = [string]$lp.artist; $script:currentAlbum = [string]$lp.album; $script:currentCover = [string]$lp.cover; $script:currentUrl = [string]$lp.url; $script:playMode = [string]$lp.mode
        }
    } catch {
        try { Copy-Item -LiteralPath $path -Destination "$path.corrupt-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force } catch { }
    }
}
function Get-CurrentTrack {
    if ($script:currentTitle -eq "" -or $script:currentTitle -eq "未播放" -or $script:currentTitle -eq "Not Playing") { return $null }
    $vid = ""
    if ($script:currentUrl -like "yt:*") { $vid = $script:currentUrl.Substring(3) }
    return [pscustomobject]@{ title=$script:currentTitle; artist=$script:currentArtist; album=$script:currentAlbum; cover=$script:currentCover; mode=$script:playMode; url=$script:currentUrl; videoId=$vid }
}
function Update-TrackKey {
    $t = Get-CurrentTrack
    if ($null -eq $t) { $script:trackKey = "" } else { $script:trackKey = Get-TrackKey $t }
}
function Set-AutoStart {
    param($enable)
    try {
        $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        $name = "MusicBox"
        if ($enable) {
            $exe = $null
            if ($null -ne $script:exePath -and $script:exePath -ne "") { $exe = $script:exePath }
            else { try { $exe = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch { } }
            if (-not $exe -or $exe -eq "") { $exe = Join-Path $appBase "MusicBox.exe" }
            Set-ItemProperty -Path $runKey -Name $name -Value "`"$exe`"" -Force -ErrorAction Stop
        } else {
            Remove-ItemProperty -Path $runKey -Name $name -Force -ErrorAction SilentlyContinue
        }
        $script:autoStart = $enable
        Save-UserData
        return $true
    } catch { return $false }
}
function Start-SleepTimer {
    param($minutes)
    Stop-SleepTimer
    if ($minutes -le 0) { return }
    $script:sleepDeadline = (Get-Date).AddMinutes($minutes)
    $script:sleepTimer = New-Object System.Windows.Forms.Timer
    $script:sleepTimer.Interval = 5000
    $script:sleepTimer.Add_Tick({
        $remain = ($script:sleepDeadline - (Get-Date)).TotalMinutes
        if ($remain -le 0) {
            Stop-SleepTimer; Stop-Play
            try { $script:lblSleepInfo.Text = (T 'sleep.stopped') } catch { }
            return
        }
        try { $script:lblSleepInfo.Text = ((T 'sleep.left') -f [int]($remain+0.5)) } catch { }
    })
    $script:sleepTimer.Start()
    try { $script:lblSleepInfo.Text = ((T 'sleep.left') -f $minutes) } catch { }
}
function Stop-SleepTimer {
    if ($null -ne $script:sleepTimer) {
        try { $script:sleepTimer.Stop() } catch { }
        try { $script:sleepTimer.Dispose() } catch { }
        $script:sleepTimer = $null
    }
    $script:sleepDeadline = $null
    try { $script:lblSleepInfo.Text = "" } catch { }
}
function Remove-AtIndex {
    param($arr, $idx)
    $list = New-Object System.Collections.ArrayList
    foreach ($x in $arr) { $null = $list.Add($x) }
    if ($idx -ge 0 -and $idx -lt $list.Count) { $list.RemoveAt($idx) }
    return @($list.ToArray())
}

# ---------- 播放核心 ----------
function Play-FreeWithYoutube {
    param($videoId, $title, $artist)
    if (-not $videoId) { return }
    if ($null -ne $script:player) { try { $script:player.controls.stop() } catch { } }
    $script:currentUrl = "yt:$videoId"
    $script:currentTitle = $title
    $script:currentArtist = $artist
    $script:currentAlbum = "YouTube"
    $script:currentCover = ""
    $script:playMode = "full"
    $script:ytPlaying = $false
    $script:ytDur = 0
    $script:btnPlay.Text = "▶"
    $script:lblSongTitle.Text = $title
    $script:lblSongArtist.Text = $artist
    $script:lblSongAlbum.Text = (T 'player.ytalbum')
    Show-Cover ""
    Update-TrackKey
    Update-FavButton
    Add-ToHistory (Get-CurrentTrack)
    $ok = Show-YoutubeEmbed $videoId
    if ($ok) {
        Set-YtMaxLayout
        $script:lblModeTag.Text = (T 'player.mode.yt')
        $script:lblModeTag.ForeColor = $cAccent
    } else {
        Restore-NormalLayout
        try { Start-Process ("https://www.youtube.com/watch?v=" + $videoId) -WindowStyle Minimized } catch { }
        $script:lblModeTag.Text = (T 'player.mode.ytbg')
        $script:lblModeTag.ForeColor = $cSuccess
    }
}
function Play-TrackObject {
    param($t)
    if ($null -eq $t) { return }
    if ($t.mode -eq "local" -and $t.url) { Play-Url $t.url $t.title $t.artist $t.album $t.cover "local"; return }
    if ($t.videoId) { Play-FreeWithYoutube $t.videoId $t.title $t.artist; return }
    if ($t.url) { Play-Url $t.url $t.title $t.artist $t.album $t.cover $t.mode }
}
function Play-Url {
    param($url, $title, $artist, $album, $cover, $mode)
    Init-Player
    if ($null -ne $script:wbYT -and $script:wbYT.Visible) { Restore-NormalLayout; $script:wbYT.Visible = $false }
    $script:currentUrl = $url
    $script:currentTitle = $title
    $script:currentArtist = $artist
    $script:currentAlbum = $album
    $script:currentCover = $cover
    $script:playMode = $mode
    try {
        $script:player.URL = $url
        $script:player.controls.play()
        $script:btnPlay.Text = "❚❚"
        $script:lblSongTitle.Text = $title
        $script:lblSongArtist.Text = $artist
        $script:lblSongAlbum.Text = $album
        Show-Cover $cover
        if ($mode -eq "full") { $script:lblModeTag.Text = (T 'player.mode.full'); $script:lblModeTag.ForeColor = $cSuccess }
        elseif ($mode -eq "preview") { $script:lblModeTag.Text = (T 'player.mode.preview'); $script:lblModeTag.ForeColor = $cWarn }
        else { $script:lblModeTag.Text = (T 'player.mode.local'); $script:lblModeTag.ForeColor = $cAccent }
        Update-TrackKey
        Update-FavButton
        Add-ToHistory (Get-CurrentTrack)
        return $true
    } catch {
        $script:lblSongTitle.Text = (T 'player.fail')
        return $false
    }
}
function Stop-Play {
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*" -and $null -ne $script:wbYT -and $null -ne $script:wbYT.CoreWebView2) {
        try { $script:wbYT.Source = [uri]"about:blank" } catch { }
        $script:wbYT.Visible = $false
        $script:ytLoadedUrl = ""
        Restore-NormalLayout
        $script:ytPlaying = $false
        $script:ytDur = 0
        $script:lblModeTag.Text = ""
        $script:btnPlay.Text = "▶"
        $script:tbProgress.Value = 0
        $script:lblTime.Text = "0:00 / 0:00"
        return
    }
    if ($null -ne $script:player) { try { $script:player.controls.stop() } catch { } }
    $script:btnPlay.Text = "▶"
}
function Set-YtMaxLayout {
    # 播放视频: 视频铺满播放器面板 (16:9 按宽度拉伸), 下方保留精简控制条
    if ($null -eq $script:wbYT) { return }
    $script:ytMaximized = $true
    Apply-Layout
}
function Restore-NormalLayout {
    $script:ytMaximized = $false
    Apply-Layout
}

# ---------- 搜索函数 ----------
function Search-Deezer {
    $q = $script:txtSearch.Text.Trim()
    if ($q -eq "") { $script:lblSearchStatus.Text = (T 'st.enterkw'); return }
    Add-SearchHistory $q
    Refresh-SearchHistoryCombo
    $script:btnSearch.Enabled = $false
    $script:lblSearchStatus.Text = (T 'st.deezersearch')
    [System.Windows.Forms.Application]::DoEvents()
    $headers = @{ "User-Agent" = "Mozilla/5.0" }
    try {
        $enc = [uri]::EscapeDataString($q)
        $url = "https://api.deezer.com/search?q=$enc&limit=60"
        $r = Invoke-RestMethod $url -Headers $headers -TimeoutSec 20
        $script:searchResults = @()
        $script:lvSearch.Items.Clear()
        if ($r.data -and $r.data.Count -gt 0) {
            foreach ($t in $r.data) {
                $ti = if ($t.title) { [string]$t.title } else { (T 'unknown.song') }
                $ar = if ($t.artist.name) { [string]$t.artist.name } else { (T 'unknown.artist') }
                $al = if ($t.album.title) { [string]$t.album.title } else { "" }
                if ($ti.Length -gt 80) { $ti = $ti.Substring(0, 80) }
                if ($ar.Length -gt 60) { $ar = $ar.Substring(0, 60) }
                $obj = [pscustomobject]@{ title=$ti; artist=$ar; album=$al; duration=$t.duration; preview=$t.preview; cover=$t.album.cover_big }
                $script:searchResults += $obj
                $li = New-Object System.Windows.Forms.ListViewItem([string]$obj.title)
                $li.SubItems.Add([string]$obj.artist) | Out-Null
                $li.SubItems.Add([string]$obj.album) | Out-Null
                $li.SubItems.Add((Format-Duration $obj.duration)) | Out-Null
                $script:lvSearch.Items.Add($li) | Out-Null
            }
            $script:lblSearchStatus.Text = ((T 'st.found') -f $r.data.Count)
        } else {
            $script:lblSearchStatus.Text = (T 'st.notfound')
        }
    } catch {
        $script:lblSearchStatus.Text = ((T 'st.fail') -f $_.Exception.Message)
    }
    $script:btnSearch.Enabled = $true
}
function Refresh-SearchHistoryCombo {
    $script:cboHistReady = $false
    try { $script:cboSearchHistory.Items.Clear() } catch { }
    try {
        if ($script:searchHistory.Count -gt 0) {
            $script:cboSearchHistory.Items.Add((T 'search.histitem')) | Out-Null
            foreach ($h in $script:searchHistory) { $script:cboSearchHistory.Items.Add($h) | Out-Null }
        }
    } catch { }
    $script:cboHistReady = $true
}
function Get-YoutubeResults {
    param($query, $max = 30)
    $out = @()
    try {
        $enc = [uri]::EscapeDataString($query)
        $url = "https://www.youtube.com/results?search_query=$enc"
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 20 -UseBasicParsing -Headers @{"User-Agent"="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"; "Accept-Language"="en-US,en;q=0.9"} -ErrorAction Stop
        $html = $resp.Content
        $m = [regex]::Match($html, 'var ytInitialData = (\{.*?\});</script>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($m.Success) {
            $data = $m.Groups[1].Value | ConvertFrom-Json
            $items = $data.contents.twoColumnSearchResultsRenderer.primaryContents.sectionListRenderer.contents[0].itemSectionRenderer.contents
            foreach ($it in $items) {
                if ($null -eq $it.videoRenderer) { continue }
                $vr = $it.videoRenderer
                $vid = [string]$vr.videoId
                if ($vid -eq "") { continue }
                $ti = if ($vr.title.runs) { $vr.title.runs[0].text } else { $vr.title.simpleText }
                $ch = if ($vr.ownerText.runs) { $vr.ownerText.runs[0].text } else { "" }
                $le = if ($vr.lengthText) { $vr.lengthText.simpleText } else { "" }
                if ($ti.Length -gt 90) { $ti = $ti.Substring(0, 90) }
                if ($ch.Length -gt 50) { $ch = $ch.Substring(0, 50) }
                $out += [pscustomobject]@{ title=[string]$ti; creator=[string]$ch; duration=[string]$le; videoId=$vid; stream="https://www.youtube.com/embed/$vid" }
                if ($out.Count -ge $max) { break }
            }
        }
    } catch { }
    return $out
}
$script:dailyQueries = @(
    @{ theme="华语金曲"; queries=@("周杰伦 热门歌曲","林俊杰 最火歌曲","邓紫棋 热门歌曲","薛之谦 经典歌曲") },
    @{ theme="Lofi 助眠"; queries=@("lofi hip hop mix","chill beats to study","lofi sleep music","jazz lofi cafe") },
    @{ theme="欧美流行"; queries=@("top pop hits 2026","billboard top songs","Taylor Swift popular","Ed Sheeran best songs") },
    @{ theme="说唱嘻哈"; queries=@("best hip hop songs","J Cole top songs","Kendrick Lamar popular","rap playlist") },
    @{ theme="电音派对"; queries=@("EDM mix","party music 2026","electronic dance music mix","house music playlist") },
    @{ theme="经典摇滚"; queries=@("classic rock songs","queen best hits","linkin park top songs","punk rock playlist") },
    @{ theme="治愈系"; queries=@("acoustic covers 2026","relaxing piano music","治愈 轻音乐","sad songs playlist") }
)
function Load-PicksByTheme {
    param($theme, $queries, $label)
    $script:freeResults = @()
    $script:lvFree.Items.Clear()
    $script:btnDailyPicks.Enabled = $false
    $script:btnFreeSearch.Enabled = $false
    $script:lblFreeStatus.Text = ((T 'st.loading') -f $label)
    [System.Windows.Forms.Application]::DoEvents()
    $merged = @()
    foreach ($q in $queries) {
        $script:lblFreeStatus.Text = ((T 'st.fetching') -f $label, $q)
        [System.Windows.Forms.Application]::DoEvents()
        $res = Get-YoutubeResults $q 8
        foreach ($r in $res) {
            $dup = $false
            foreach ($e in $merged) { if ($e.videoId -eq $r.videoId) { $dup = $true; break } }
            if (-not $dup) { $merged += $r }
        }
    }
    $rnd = New-Object System.Random
    $merged = $merged | Sort-Object { $rnd.Next() }
    $count = 0
    foreach ($obj in $merged) {
        if ($count -ge 40) { break }
        $script:freeResults += $obj
        $li = New-Object System.Windows.Forms.ListViewItem([string]$obj.title)
        $li.SubItems.Add([string]$obj.creator) | Out-Null
        $li.SubItems.Add([string]$obj.duration) | Out-Null
        $script:lvFree.Items.Add($li) | Out-Null
        $count++
    }
    if ($count -gt 0) { $script:lblFreeStatus.Text = ((T 'st.picksdone') -f $label, $count) }
    else { $script:lblFreeStatus.Text = (T 'st.picksfail') }
    $script:btnDailyPicks.Enabled = $true
    $script:btnFreeSearch.Enabled = $true
}
function Load-DailyPicks {
    $dow = [int](Get-Date).DayOfWeek
    if ($dow -eq 0) { $dow = 7 }
    $idx = $dow - 1
    $th = $script:dailyQueries[$idx]
    Load-PicksByTheme $th.theme $th.queries ((T 'free.daily').Trim() + " (" + (CatLabel $th.theme) + ")")
}
function Search-Free {
    $q = $script:txtFree.Text.Trim()
    if ($q -eq "") { $script:lblFreeStatus.Text = (T 'st.enterkwshort'); return }
    $script:btnFreeSearch.Enabled = $false
    $script:lblFreeStatus.Text = (T 'st.ytsearch')
    [System.Windows.Forms.Application]::DoEvents()
    try {
        $script:freeResults = @()
        $script:lvFree.Items.Clear()
        $count = 0
        foreach ($obj in (Get-YoutubeResults $q 30)) {
            $script:freeResults += $obj
            $li = New-Object System.Windows.Forms.ListViewItem([string]$obj.title)
            $li.SubItems.Add([string]$obj.creator) | Out-Null
            $li.SubItems.Add([string]$obj.duration) | Out-Null
            $script:lvFree.Items.Add($li) | Out-Null
            $count++
        }
        if ($count -gt 0) { $script:lblFreeStatus.Text = ((T 'st.ytfound') -f $count) }
        else { $script:lblFreeStatus.Text = (T 'st.ytnotfound') }
    } catch {
        $script:lblFreeStatus.Text = ((T 'st.fail') -f $_.Exception.Message)
    }
    $script:btnFreeSearch.Enabled = $true
}
function Open-YoutubePage {
    if ($script:lvFree.SelectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show((T 'msg.selectsong'), (T 'msg.tip'), "OK", "Information") | Out-Null
        return
    }
    $idx = $script:lvFree.SelectedItems[0].Index
    $item = $script:freeResults[$idx]
    if (-not $item.videoId) { [System.Windows.Forms.MessageBox]::Show((T 'msg.novideourl'), (T 'msg.tip'), "OK", "Warning") | Out-Null; return }
    try { Start-Process ("https://www.youtube.com/watch?v=" + $item.videoId) } catch { }
}
function Navigate-Spotify {
    param($cat)
    $u = $script:spotUrls[$cat]
    if (-not $u) { return }
    if ($null -ne $script:wbSpot -and $null -ne $script:wbSpot.CoreWebView2) {
        try { $script:wbSpot.CoreWebView2.Navigate($u) } catch { }
    }
}
function Set-SpotCatActive {
    param($btn)
    foreach ($k in $script:spotCat.Keys) {
        $b = $script:spotCat[$k]
        $isActive = ($b -eq $btn)
        $b.BackColor = $(if($isActive){$cAccent}else{$cFill})
        $b.ForeColor = $(if($isActive){$cWhite}else{$cText})
    }
}
function Open-Folder {
    $dlDir = Join-Path ([Environment]::GetFolderPath("MyMusic")) "MusicBox"
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description = (T 'local.choose')
    $fbd.SelectedPath = $dlDir
    if ($fbd.ShowDialog() -eq "OK") { Load-LocalDir $fbd.SelectedPath }
}
function Load-LocalDir {
    param($dir)
    $script:localFiles = @()
    $script:lvLocal.Items.Clear()
    $files = @(Get-ChildItem $dir -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '\.(mp3|flac|wav|m4a|ogg)$' })
    foreach ($f in $files) {
        $script:localFiles += $f.FullName
        $li = New-Object System.Windows.Forms.ListViewItem($f.BaseName)
        $li.SubItems.Add($f.Extension.TrimStart('.').ToUpper()) | Out-Null
        $li.SubItems.Add(("{0:N1} MB" -f ($f.Length/1MB))) | Out-Null
        $script:lvLocal.Items.Add($li) | Out-Null
    }
    $script:localIndex = -1
    $script:lblLocalStatus.Text = ((T 'local.found') -f $files.Count)
}
function Play-LocalIndex {
    if ($script:localIndex -lt 0 -or $script:localIndex -ge $script:localFiles.Count) { return }
    $path = $script:localFiles[$script:localIndex]
    $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
    Play-Url $path $name "" "" "" "local"
}
function Refresh-FavList {
    $script:lvFav.Items.Clear()
    foreach ($f in $script:favorites) {
        $li = New-Object System.Windows.Forms.ListViewItem([string]$f.title)
        $src = if ($f.artist) { $f.artist } else { "YouTube" }
        $li.SubItems.Add([string]$src) | Out-Null
        $typeName = switch ($f.mode) { "preview" { (T 'item.preview') } "local" { (T 'item.local') } default { (T 'item.full') } }
        $li.SubItems.Add($typeName) | Out-Null
        $script:lvFav.Items.Add($li) | Out-Null
    }
    $script:lblFavTitle.Text = ((T 'fav.title') -f $script:favorites.Count)
    Update-FavButton
}
function Refresh-PlaylistCombo {
    $script:cboPlaylists.Items.Clear()
    foreach ($n in $script:playlistNames) { $script:cboPlaylists.Items.Add($n) | Out-Null }
    if ($script:cboPlaylists.Items.Count -gt 0) { $script:cboPlaylists.SelectedIndex = 0 }
}
function Refresh-PlaylistItems {
    $script:lvPlaylist.Items.Clear()
    $n = [string]$script:cboPlaylists.SelectedItem
    if (-not $n -or -not $script:playlists.ContainsKey($n)) {
        $script:lblPlTitle.Text = (T 'pl.empty')
        return
    }
    $items = @($script:playlists[$n].items)
    foreach ($it in $items) {
        $li = New-Object System.Windows.Forms.ListViewItem([string]$it.title)
        $src = if ($it.artist) { $it.artist } else { "YouTube" }
        $li.SubItems.Add([string]$src) | Out-Null
        $li.SubItems.Add((T 'item.rightremove')) | Out-Null
        $script:lvPlaylist.Items.Add($li) | Out-Null
    }
    $script:lblPlTitle.Text = ((T 'pl.title') -f $items.Count)
}
function Update-FavButton {
    try {
        $t = Get-CurrentTrack
        if ($null -eq $t) {
            $script:btnFavCur.Text = (T 'player.fav')
            $script:btnFavCur.BackColor = $cFill
            $script:btnFavCur.ForeColor = $cAccent
            return
        }
        if (Test-InFavorites (Get-TrackKey $t)) {
            $script:btnFavCur.Text = (T 'player.faved')
            $script:btnFavCur.BackColor = $cAccent
            $script:btnFavCur.ForeColor = $cWhite
        } else {
            $script:btnFavCur.Text = (T 'player.fav')
            $script:btnFavCur.BackColor = $cFill
            $script:btnFavCur.ForeColor = $cAccent
        }
    } catch { }
}
function Auto-NextTrack {
    if ($script:autoNextBusy) { return }
    $script:autoNextBusy = $true
    try {
        if ($script:currentPage -eq "free" -and $script:freeResults.Count -gt 0) {
            $curIdx = -1
            for ($i=0; $i -lt $script:freeResults.Count; $i++) { if ($script:freeResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
            if ($curIdx -ge 0 -and $curIdx -lt $script:freeResults.Count - 1) { $it = $script:freeResults[$curIdx+1]; if ($it.videoId) { Play-FreeWithYoutube $it.videoId $it.title $it.creator } }
        }
        elseif ($script:currentPage -eq "local" -and $script:localFiles.Count -gt 0 -and $script:localIndex -lt $script:localFiles.Count - 1) { $script:localIndex++; Play-LocalIndex }
        elseif ($script:currentPage -eq "fav" -and $script:favorites.Count -gt 0) {
            $curIdx = -1
            for ($i=0; $i -lt $script:favorites.Count; $i++) { if ((Get-TrackKey $script:favorites[$i]) -eq $script:trackKey) { $curIdx = $i; break } }
            if ($curIdx -ge 0 -and $curIdx -lt $script:favorites.Count - 1) { Play-TrackObject $script:favorites[$curIdx+1] }
        }
        elseif ($script:currentPage -eq "search" -and $script:searchResults.Count -gt 0) {
            $curIdx = -1
            for ($i=0; $i -lt $script:searchResults.Count; $i++) { if ($script:searchResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
            if ($curIdx -ge 0 -and $curIdx -lt $script:searchResults.Count - 1) { $it = $script:searchResults[$curIdx+1]; if ($it.preview) { Play-Url $it.preview $it.title $it.artist $it.album $it.cover "preview" } }
        }
    } catch { }
    $script:autoNextBusy = $false
}
function Seek-BySeconds {
    param($delta)
    try {
        if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*") {
            $st = Yt-State
            if ($null -ne $st) { Yt-Seek ([math]::Max(0, $st.Pos + $delta)) }
            return
        }
        if ($null -ne $script:player -and $script:currentUrl -ne "") {
            $cur = $script:player.controls.currentPosition
            $dur = $script:player.currentMedia.duration
            $np = [math]::Max(0, [math]::Min($dur, $cur + $delta))
            $script:player.controls.currentPosition = $np
        }
    } catch { }
}

# ============================================================
#  界面构建 (所有控件先建好, 位置由 Apply-Layout 统一计算)
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "MusicBox"
$form.Size = New-Object System.Drawing.Size(1460, 1000)
$form.StartPosition = "CenterScreen"
$form.BackColor = $cBg
$form.MinimumSize = New-Object System.Drawing.Size(960, 640)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.AllowDrop = $true
$form.Font = New-Object System.Drawing.Font($fUI, 9.5)
$form.add_DragEnter({
    param($s, $e)
    if ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy }
})
$form.add_DragDrop({
    param($s, $e)
    try {
        $files = @($e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop))
        $audio = @($files | Where-Object { $_ -match '\.(mp3|flac|wav|m4a|ogg)$' })
        if ($audio.Count -gt 0) {
            $script:localFiles = @()
            $script:lvLocal.Items.Clear()
            foreach ($p in $audio) {
                $fi = Get-Item -LiteralPath $p -ErrorAction SilentlyContinue
                if ($null -eq $fi) { continue }
                $script:localFiles += $fi.FullName
                $li = New-Object System.Windows.Forms.ListViewItem($fi.BaseName)
                $li.SubItems.Add($fi.Extension.TrimStart('.').ToUpper()) | Out-Null
                $li.SubItems.Add(("{0:N1} MB" -f ($fi.Length/1MB))) | Out-Null
                $script:lvLocal.Items.Add($li) | Out-Null
            }
            $script:localIndex = 0
            $script:lblLocalStatus.Text = ((T 'local.dropped') -f $audio.Count)
            Switch-Page "local"
            Play-LocalIndex
        } elseif ($files.Count -gt 0) {
            $dirs = @($files | Where-Object { Test-Path -LiteralPath $_ -PathType Container })
            if ($dirs.Count -gt 0) { Load-LocalDir $dirs[0]; Switch-Page "local" }
        }
    } catch { }
})

# ---------- 左侧边栏 ----------
$pnlSidebar = New-Object System.Windows.Forms.Panel
$pnlSidebar.BackColor = $cSidebarBg
$form.Controls.Add($pnlSidebar)

$lblBrand = New-Label "♪  MusicBox" 0 0 176 34 17 $cText $true
$pnlSidebar.Controls.Add($lblBrand)
$lblBrandSub = New-Label "免费音乐盒" 0 0 176 20 8.5 $cSub $false
$pnlSidebar.Controls.Add($lblBrandSub)
$sepBrand = New-Hairline 0 0 176
$pnlSidebar.Controls.Add($sepBrand)

$navDefs = @(
    @{ key="free";     icon="♾"; label="完整听" },
    @{ key="search";   icon="♫"; label="搜索" },
    @{ key="local";    icon="▤"; label="本地音乐" },
    @{ key="fav";      icon="♥"; label="我的收藏" },
    @{ key="playlist"; icon="☰"; label="歌单" },
    @{ key="spot";     icon="◉"; label="Spotify 榜单" }
)
$script:navButtons = @{}
foreach ($nd in $navDefs) {
    $sb = New-Object System.Windows.Forms.Button
    $sb.Text = "$($nd.icon)   $($nd.label)"
    $sb.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $sb.Padding = New-Object System.Windows.Forms.Padding(14, 0, 0, 0)
    $sb.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $sb.FlatAppearance.BorderSize = 0
    $sb.BackColor = $cSidebarBg
    $sb.ForeColor = $cText
    $sb.Cursor = [System.Windows.Forms.Cursors]::Hand
    $sb.Font = New-Object System.Drawing.Font($fUI, 11)
    $sb.UseVisualStyleBackColor = $false
    $sb.TabStop = $false
    $sb.Tag = $nd.key
    $sb.Add_MouseEnter({ if ($this.Tag -ne $script:currentPage) { $this.BackColor = $cHover } })
    $sb.Add_MouseLeave({ if ($this.Tag -ne $script:currentPage) { $this.BackColor = $cSidebarBg } })
    $sb.Add_Click({ Switch-Page $this.Tag })
    $pnlSidebar.Controls.Add($sb)
    $script:navButtons[$nd.key] = $sb
}

$script:chkAutoStart = New-Object System.Windows.Forms.CheckBox
$script:chkAutoStart.Text = "开机自动启动"
$script:chkAutoStart.Font = New-Object System.Drawing.Font($fUI, 8.5)
$script:chkAutoStart.ForeColor = $cSub
$script:chkAutoStart.BackColor = $cSidebarBg
$script:chkAutoStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:chkAutoStart.Checked = $script:autoStart
$pnlSidebar.Controls.Add($script:chkAutoStart)
$script:chkAutoStart.Add_CheckedChanged({ $null = Set-AutoStart $script:chkAutoStart.Checked })

$lblVer = New-Label "v3.6" 0 0 176 16 8 $cSub $false
$pnlSidebar.Controls.Add($lblVer)

# ---------- 主内容区 ----------
$pnlMain = New-Object System.Windows.Forms.Panel
$pnlMain.BackColor = $cBg
$form.Controls.Add($pnlMain)

$script:lblPageTitle = New-Label "完整听" 0 0 500 36 24 $cText $true
$pnlMain.Controls.Add($script:lblPageTitle)
$script:lblPageSub = New-Label "YouTube 完整歌曲 · 免费在线播放" 0 0 600 20 9.5 $cSub $false
$pnlMain.Controls.Add($script:lblPageSub)

$pnlCard = New-Object System.Windows.Forms.Panel
$pnlCard.BackColor = $cCard
$pnlMain.Controls.Add($pnlCard)

# ============ 页面1: 搜索 ============
$script:pnlSearchPage = New-Object System.Windows.Forms.Panel
$script:pnlSearchPage.BackColor = $cCard
$script:pnlSearchPage.Visible = $false
$pnlCard.Controls.Add($script:pnlSearchPage)

$script:lblSearchStatus = New-Label "版权歌曲官方 30 秒试听 · 双击歌曲在线试听" 0 0 440 20 9 $cSub $false
$script:pnlSearchPage.Controls.Add($script:lblSearchStatus)
$script:txtSearch = New-TextBox 0 0 330 34
$script:pnlSearchPage.Controls.Add($script:txtSearch)
$script:txtSearch.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { Search-Deezer } })
$script:btnSearch = New-PrimaryBtn "搜索" 0 0 90 34
$script:pnlSearchPage.Controls.Add($script:btnSearch)
$script:btnSearch.Add_Click({ Search-Deezer })
$script:cboSearchHistory = New-Object System.Windows.Forms.ComboBox
$script:cboSearchHistory.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:cboSearchHistory.Font = New-Object System.Drawing.Font($fUI, 9.5)
$script:cboSearchHistory.BackColor = $cInputBg
$script:cboSearchHistory.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:pnlSearchPage.Controls.Add($script:cboSearchHistory)
$script:cboSearchHistory.Add_SelectedIndexChanged({
    if (-not $script:cboHistReady) { return }
    if ($null -eq $script:cboSearchHistory.SelectedItem) { return }
    if ($script:cboSearchHistory.SelectedItem -eq (T 'search.histitem')) { return }
    $script:txtSearch.Text = [string]$script:cboSearchHistory.SelectedItem
    Search-Deezer
})
$script:lblHistHint = New-Label "历史记录" 0 0 100 20 8.5 $cSub $false
$script:pnlSearchPage.Controls.Add($script:lblHistHint)
$script:lvSearch = New-ListView 0 0 640 680 @(
    @{Name="歌曲"; Width=250}, @{Name="歌手"; Width=180}, @{Name="专辑"; Width=130}, @{Name="时长"; Width=80}
)
$script:pnlSearchPage.Controls.Add($script:lvSearch)
$script:lvSearch.Add_DoubleClick({
    if ($script:lvSearch.SelectedItems.Count -gt 0) {
        $idx = $script:lvSearch.SelectedItems[0].Index
        $item = $script:searchResults[$idx]
        if ($item.preview) { Play-Url $item.preview $item.title $item.artist $item.album $item.cover "preview" }
    }
})
$script:btnPlaySel = New-PrimaryBtn "▶  播放试听" 0 0 130 34
$script:pnlSearchPage.Controls.Add($script:btnPlaySel)
$script:btnPlaySel.Add_Click({
    if ($script:lvSearch.SelectedItems.Count -gt 0) {
        $idx = $script:lvSearch.SelectedItems[0].Index
        $item = $script:searchResults[$idx]
        if ($item.preview) { Play-Url $item.preview $item.title $item.artist $item.album $item.cover "preview" }
    }
})
$script:lblSearchInfo = New-Label "版权 30s 试听 · 完整听去「完整听」页" 0 0 400 20 8.5 $cSub $false
$script:pnlSearchPage.Controls.Add($script:lblSearchInfo)

# ============ 页面2: 完整听 ============
$script:pnlFreePage = New-Object System.Windows.Forms.Panel
$script:pnlFreePage.BackColor = $cCard
$script:pnlFreePage.Visible = $true
$pnlCard.Controls.Add($script:pnlFreePage)

$script:txtFree = New-TextBox 0 0 350 34
$script:pnlFreePage.Controls.Add($script:txtFree)
$script:txtFree.Add_KeyDown({ if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) { Search-Free } })
$script:btnFreeSearch = New-PrimaryBtn "搜索" 0 0 90 34
$script:pnlFreePage.Controls.Add($script:btnFreeSearch)
$script:btnFreeSearch.Add_Click({ Search-Free })
$script:btnDailyPicks = New-PrimaryBtn "🎵  每日精选" 0 0 176 34
$script:pnlFreePage.Controls.Add($script:btnDailyPicks)
$script:btnDailyPicks.Add_Click({ Load-DailyPicks })
$script:lblFreeStatus = New-Label "YouTube 完整歌曲 · 双击直接听 · 例如 weezer / 周杰伦 / lofi" 0 0 640 20 9 $cSub $false
$script:pnlFreePage.Controls.Add($script:lblFreeStatus)
$script:lvFree = New-ListView 0 0 640 700 @(
    @{Name="歌曲 / 视频"; Width=360}, @{Name="频道"; Width=210}, @{Name="时长"; Width=70}
)
$script:pnlFreePage.Controls.Add($script:lvFree)
$script:lvFree.Add_DoubleClick({
    if ($script:lvFree.SelectedItems.Count -gt 0) {
        $idx = $script:lvFree.SelectedItems[0].Index
        $item = $script:freeResults[$idx]
        if ($item.videoId) { Play-FreeWithYoutube $item.videoId $item.title $item.creator }
    }
})
$script:btnFreePlay = New-PrimaryBtn "♾  完整播放" 0 0 140 40 11
$script:pnlFreePage.Controls.Add($script:btnFreePlay)
$script:btnFreePlay.Add_Click({
    if ($script:lvFree.SelectedItems.Count -gt 0) {
        $idx = $script:lvFree.SelectedItems[0].Index
        $item = $script:freeResults[$idx]
        if ($item.videoId) { Play-FreeWithYoutube $item.videoId $item.title $item.creator }
    }
})
$script:btnFreeDownload = New-SecondaryBtn "↗  浏览器打开" 0 0 120 40
$script:pnlFreePage.Controls.Add($script:btnFreeDownload)
$script:btnFreeDownload.Add_Click({ Open-YoutubePage })
$script:lblFreeInfo = New-Label "双击或点「完整播放」→ 右侧播放器直接看" 0 0 360 24 8.5 $cSub $false
$script:pnlFreePage.Controls.Add($script:lblFreeInfo)

# ============ 页面3: 本地音乐 ============
$script:pnlLocalPage = New-Object System.Windows.Forms.Panel
$script:pnlLocalPage.BackColor = $cCard
$script:pnlLocalPage.Visible = $false
$pnlCard.Controls.Add($script:pnlLocalPage)

$script:btnOpenFolder = New-PrimaryBtn "📂  打开音乐文件夹" 0 0 200 36
$script:pnlLocalPage.Controls.Add($script:btnOpenFolder)
$script:btnOpenFolder.Add_Click({ Open-Folder })
$script:lblLocalStatus = New-Label "支持 MP3 / FLAC / WAV / M4A · 也可把文件拖到窗口" 0 0 420 22 9 $cSub $false
$script:pnlLocalPage.Controls.Add($script:lblLocalStatus)
$script:lvLocal = New-ListView 0 0 640 720 @(
    @{Name="歌曲"; Width=360}, @{Name="格式"; Width=100}, @{Name="大小"; Width=140}
)
$script:pnlLocalPage.Controls.Add($script:lvLocal)
$script:lvLocal.Add_DoubleClick({
    if ($script:lvLocal.SelectedItems.Count -gt 0) {
        $script:localIndex = $script:lvLocal.SelectedItems[0].Index
        Play-LocalIndex
    }
})
$script:btnLocalPlay = New-PrimaryBtn "▶  播放" 0 0 110 40
$script:pnlLocalPage.Controls.Add($script:btnLocalPlay)
$script:btnLocalPlay.Add_Click({
    if ($script:lvLocal.SelectedItems.Count -gt 0) { $script:localIndex = $script:lvLocal.SelectedItems[0].Index; Play-LocalIndex }
})
$script:btnLocalPrev = New-SecondaryBtn "⏮" 0 0 70 40
$script:pnlLocalPage.Controls.Add($script:btnLocalPrev)
$script:btnLocalPrev.Add_Click({ if ($script:localIndex -gt 0) { $script:localIndex--; Play-LocalIndex } })
$script:btnLocalNext = New-SecondaryBtn "⏭" 0 0 70 40
$script:pnlLocalPage.Controls.Add($script:btnLocalNext)
$script:btnLocalNext.Add_Click({ if ($script:localIndex -lt $script:localFiles.Count - 1) { $script:localIndex++; Play-LocalIndex } })

# ============ 页面4: Spotify 榜单 ============
$script:spotUrls = @{
    "all"    = "https://open.spotify.com/embed/playlist/37i9dQZF1DXcBWIGoYBM5M"
    "pop"    = "https://open.spotify.com/embed/playlist/37i9dQZF1DXcBWIGoYBM5M"
    "hiphop" = "https://open.spotify.com/embed/playlist/37i9dQZF1DX0XUsuxWHRQd"
    "rock"   = "https://open.spotify.com/embed/playlist/37i9dQZF1DXcF6B6QPhFDv"
    "edm"    = "https://open.spotify.com/embed/playlist/37i9dQZF1DX4dyzvuaRJ0n"
    "rb"     = "https://open.spotify.com/embed/playlist/37i9dQZF1DX4SBhb3fqCJd"
    "jazz"   = "https://open.spotify.com/embed/playlist/37i9dQZF1DX0SM0LYsmbMT"
    "latin"  = "https://open.spotify.com/embed/playlist/37i9dQZF1DX10zKzsJ2jva"
}
$script:pnlSpotPage = New-Object System.Windows.Forms.Panel
$script:pnlSpotPage.BackColor = $cCard
$script:pnlSpotPage.Visible = $false
$pnlCard.Controls.Add($script:pnlSpotPage)

$script:lblSpotTitle = New-Label "Spotify 官方榜单 · 点类型按钮切换流派" 0 0 500 26 14 $cText $true
$script:pnlSpotPage.Controls.Add($script:lblSpotTitle)
$script:spotCat = @{}
$catRow = @(@{k="all"; t="全部"}, @{k="pop"; t="Pop"}, @{k="hiphop"; t="HipHop"}, @{k="rock"; t="Rock"}, @{k="edm"; t="EDM"}, @{k="rb"; t="R&B"}, @{k="jazz"; t="Jazz"}, @{k="latin"; t="Latin"})
foreach ($c in $catRow) {
    $b = New-SecondaryBtn $c.t 0 0 76 32 9
    $b.Tag = $c.k
    $script:pnlSpotPage.Controls.Add($b)
    $b.Add_Click({ Navigate-Spotify $this.Tag; Set-SpotCatActive $this })
    $script:spotCat[$c.k] = $b
}
$script:lblSpotHint = New-Label "数据来源: Spotify 官方播放列表 embed · 无需登录 · 可点歌曲试听" 0 0 640 20 8.5 $cSub $false
$script:pnlSpotPage.Controls.Add($script:lblSpotHint)

if ($script:hasYt) {
    try {
        $script:wbSpot = New-Object Microsoft.Web.WebView2.WinForms.WebView2
        $script:wbSpot.DefaultBackgroundColor = $cCard
        $script:pnlSpotPage.Controls.Add($script:wbSpot)
        $null = $script:wbSpot.EnsureCoreWebView2Async($null)
        $script:spotRetry = 0
        $script:spotInit = New-Object System.Windows.Forms.Timer
        $script:spotInit.Interval = 300
        $script:spotInit.Add_Tick({
            $script:spotRetry++
            if ($script:spotRetry -ge 20) { $script:spotInit.Stop(); return }
            if ($null -eq $script:wbSpot -or $null -eq $script:wbSpot.CoreWebView2) { return }
            $script:spotInit.Stop()
            try {
                $script:wbSpot.CoreWebView2.Settings.AreDefaultContextMenusEnabled = $false
                $script:wbSpot.CoreWebView2.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
                $script:spotCssJs = "(function(){var css=['html,body{background:#ffffff!important}','header,.Root__nav-bar,#global-header,footer{display:none!important}'].join('');var st=document.getElementById('mb-spot-css');if(!st){st=document.createElement('style');st.id='mb-spot-css';document.documentElement.appendChild(st);}st.textContent=css;})();"
                $null = $script:wbSpot.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync($script:spotCssJs)
                $script:wbSpot.Add_NavigationCompleted({
                    param($s, $e)
                    if (-not $e.IsSuccess -or $null -eq $s.CoreWebView2) { return }
                    try {
                        $t = $s.CoreWebView2.DocumentTitle
                        if ($t -match 'not found|not available|couldn') { $s.CoreWebView2.Navigate($script:spotUrls["all"]); return }
                        $null = $s.CoreWebView2.ExecuteScriptAsync($script:spotCssJs)
                    } catch { }
                })
                Navigate-Spotify "all"
            } catch { }
        })
        $script:spotInit.Start()
    } catch { }
}

# ============ 页面5: 我的收藏 ============
$script:pnlFavPage = New-Object System.Windows.Forms.Panel
$script:pnlFavPage.BackColor = $cCard
$script:pnlFavPage.Visible = $false
$pnlCard.Controls.Add($script:pnlFavPage)

$script:lblFavTitle = New-Label "共 0 首歌曲 · 双击播放 · 右键取消收藏" 0 0 500 22 11 $cSub $false
$script:pnlFavPage.Controls.Add($script:lblFavTitle)
$script:btnFavPlayAll = New-PrimaryBtn "▶  全部播放" 0 0 130 34
$script:pnlFavPage.Controls.Add($script:btnFavPlayAll)
$script:btnFavPlayAll.Add_Click({ if ($script:favorites.Count -gt 0) { Play-TrackObject $script:favorites[0] } })
$script:btnFavClear = New-SecondaryBtn "🗑  清空收藏" 0 0 120 34
$script:pnlFavPage.Controls.Add($script:btnFavClear)
$script:btnFavClear.Add_Click({
    if ($script:favorites.Count -eq 0) { return }
    $r = [System.Windows.Forms.MessageBox]::Show(((T 'fav.confirm') -f $script:favorites.Count), (T 'msg.confirm'), "YesNo", "Question")
    if ($r -eq "Yes") { $script:favorites = @(); Save-UserData; Refresh-FavList }
})
$script:lvFav = New-ListView 0 0 640 740 @(
    @{Name="歌曲"; Width=290}, @{Name="歌手/来源"; Width=200}, @{Name="类型"; Width=150}
)
$script:pnlFavPage.Controls.Add($script:lvFav)
$script:lvFav.Add_DoubleClick({
    if ($script:lvFav.SelectedItems.Count -gt 0) { $idx = $script:lvFav.SelectedItems[0].Index; Play-TrackObject $script:favorites[$idx] }
})
$script:lvFav.Add_MouseClick({
    param($s, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $hit = $script:lvFav.HitTest($e.X, $e.Y)
        if ($null -ne $hit.Item) {
            $idx = $hit.Item.Index
            Remove-FromFavorites (Get-TrackKey $script:favorites[$idx])
            Refresh-FavList
        }
    }
})

# ============ 页面6: 歌单 ============
$script:pnlPlaylistPage = New-Object System.Windows.Forms.Panel
$script:pnlPlaylistPage.BackColor = $cCard
$script:pnlPlaylistPage.Visible = $false
$pnlCard.Controls.Add($script:pnlPlaylistPage)

$script:lblPlTitle = New-Label "还没有歌单 · 输入名字点「新建歌单」开始" 0 0 500 22 11 $cSub $false
$script:pnlPlaylistPage.Controls.Add($script:lblPlTitle)
$script:cboPlaylists = New-Object System.Windows.Forms.ComboBox
$script:cboPlaylists.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$script:cboPlaylists.Font = New-Object System.Drawing.Font($fUI, 9.5)
$script:cboPlaylists.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$script:pnlPlaylistPage.Controls.Add($script:cboPlaylists)
$script:cboPlaylists.Add_SelectedIndexChanged({ Refresh-PlaylistItems })
$script:txtPlaylistName = New-TextBox 0 0 150 26 9.5
$script:pnlPlaylistPage.Controls.Add($script:txtPlaylistName)
$script:btnPlCreate = New-PrimaryBtn "➕  新建歌单" 0 0 110 30 9
$script:pnlPlaylistPage.Controls.Add($script:btnPlCreate)
$script:btnPlCreate.Add_Click({
    $n = $script:txtPlaylistName.Text.Trim()
    if ($n -eq "") { [System.Windows.Forms.MessageBox]::Show((T 'pl.enter'), (T 'msg.tip'), "OK", "Information") | Out-Null; return }
    if ($script:playlists.ContainsKey($n)) { [System.Windows.Forms.MessageBox]::Show((T 'pl.exists'), (T 'msg.tip'), "OK", "Information") | Out-Null; return }
    $script:playlists[$n] = @{ name = $n; items = @() }
    $script:playlistNames += $n
    $script:txtPlaylistName.Text = ""
    Refresh-PlaylistCombo
    Save-UserData
    Refresh-PlaylistItems
})
$script:btnPlAddCur = New-SecondaryBtn "＋ 加入当前歌曲" 0 0 130 30 9
$script:pnlPlaylistPage.Controls.Add($script:btnPlAddCur)
$script:btnPlAddCur.Add_Click({
    $n = [string]$script:cboPlaylists.SelectedItem
    if (-not $n -or -not $script:playlists.ContainsKey($n)) { [System.Windows.Forms.MessageBox]::Show((T 'pl.select'), (T 'msg.tip'), "OK", "Information") | Out-Null; return }
    $t = Get-CurrentTrack
    if ($null -eq $t) { [System.Windows.Forms.MessageBox]::Show((T 'msg.needplay'), (T 'msg.tip'), "OK", "Information") | Out-Null; return }
    $script:playlists[$n].items += $t
    Save-UserData
    Refresh-PlaylistItems
})
$script:btnPlDelete = New-SecondaryBtn "🗑 删除歌单" 0 0 110 28 9
$script:pnlPlaylistPage.Controls.Add($script:btnPlDelete)
$script:btnPlDelete.Add_Click({
    $n = [string]$script:cboPlaylists.SelectedItem
    if (-not $n -or -not $script:playlists.ContainsKey($n)) { return }
    $r = [System.Windows.Forms.MessageBox]::Show(((T 'pl.confirmdel') -f $n), (T 'msg.confirm'), "YesNo", "Question")
    if ($r -ne "Yes") { return }
    $script:playlists.Remove($n)
    $script:playlistNames = @($script:playlistNames | Where-Object { $_ -ne $n })
    Save-UserData
    Refresh-PlaylistCombo
    Refresh-PlaylistItems
})
$script:lvPlaylist = New-ListView 0 0 640 710 @(
    @{Name="歌曲"; Width=290}, @{Name="歌手/来源"; Width=200}, @{Name="操作"; Width=150}
)
$script:pnlPlaylistPage.Controls.Add($script:lvPlaylist)
$script:lvPlaylist.Add_DoubleClick({
    if ($script:lvPlaylist.SelectedItems.Count -gt 0) {
        $n = [string]$script:cboPlaylists.SelectedItem
        if (-not $n -or -not $script:playlists.ContainsKey($n)) { return }
        $idx = $script:lvPlaylist.SelectedItems[0].Index
        Play-TrackObject $script:playlists[$n].items[$idx]
    }
})
$script:lvPlaylist.Add_MouseClick({
    param($s, $e)
    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Right) { return }
    $hit = $script:lvPlaylist.HitTest($e.X, $e.Y)
    if ($null -eq $hit.Item) { return }
    $n = [string]$script:cboPlaylists.SelectedItem
    if (-not $n -or -not $script:playlists.ContainsKey($n)) { return }
    $idx = $hit.Item.Index
    $items = @($script:playlists[$n].items)
    if ($idx -ge 0 -and $idx -lt $items.Count) {
        $script:playlists[$n].items = @(Remove-AtIndex $items $idx)
        Save-UserData
        Refresh-PlaylistItems
    }
})

# ---------- 右侧播放面板 ----------
$pnlPlayer = New-Object System.Windows.Forms.Panel
$pnlPlayer.BackColor = $cCard
$form.Controls.Add($pnlPlayer)
$sepPlayer = New-Object System.Windows.Forms.Panel
$sepPlayer.BackColor = $cHair
$pnlPlayer.Controls.Add($sepPlayer)

# 右上角: 中英文切换
$script:btnLang = New-SecondaryBtn "English" 0 0 82 26 9
$pnlPlayer.Controls.Add($script:btnLang)
$script:btnLang.Add_Click({
    if ($script:lang -eq "zh") { $script:lang = "en" } else { $script:lang = "zh" }
    Save-UserData
    Apply-Language
})

# WebView2 (视频区)
if ($script:hasYt) {
    try {
        $script:wbYT = New-Object Microsoft.Web.WebView2.WinForms.WebView2
        $script:wbYT.Visible = $false
        $pnlPlayer.Controls.Add($script:wbYT)
        $script:ytCssJs = "(function(){var css=['html,body{height:100%!important;margin:0!important;padding:0!important;background:#000000!important;overflow:hidden!important}','ytd-app{background:#000000!important}','ytd-masthead,#masthead-container,#masthead,#topbar{display:none!important}','#guide,ytd-guide-renderer,ytd-mini-guide-renderer{display:none!important}','#related,#secondary,ytd-comments,#comments,ytd-engagement-panel-section-renderer{display:none!important}','ytd-watch-flexy[flexy]{--ytd-watch-flexy-max-player-width:100%!important;--ytd-watch-flexy-max-height:100%!important}','ytd-watch-flexy[flexy] #primary{width:100%!important;max-width:none!important}','ytd-watch-flexy[flexy] #columns{flex-direction:column!important;width:100%!important}','ytd-watch-flexy[flexy] #player-container{width:100%!important;max-width:none!important;height:100%!important}','#movie_player,.html5-video-player{width:100%!important;height:100%!important}','ytd-watch-metadata,#above-the-fold,#info-container,#title,ytd-video-primary-info-renderer,ytd-video-secondary-info-renderer{display:none!important}'].join('');var st=document.getElementById('mb-hide-css');if(!st){st=document.createElement('style');st.id='mb-hide-css';document.documentElement.appendChild(st);}st.textContent=css;document.body.style.margin='0';})();"
        $script:wbYT.Add_NavigationCompleted({
            param($s, $e)
            if (-not $e.IsSuccess -or $null -eq $s.CoreWebView2) { return }
            try { $null = $s.CoreWebView2.ExecuteScriptAsync($script:ytCssJs) } catch { }
        })
        $script:cssCount = 0
        $script:cssTimer = New-Object System.Windows.Forms.Timer
        $script:cssTimer.Interval = 2500
        $script:cssTimer.Add_Tick({
            $script:cssCount++
            if ($null -ne $script:wbYT -and $null -ne $script:wbYT.CoreWebView2) { try { $null = $script:wbYT.CoreWebView2.ExecuteScriptAsync($script:ytCssJs) } catch { } }
            if ($script:cssCount -ge 3) { $script:cssTimer.Stop() }
        })
    } catch {
        try { Add-Content (Join-Path $appBase "diag.txt") ("wbYT create fail: " + $_.Exception.Message) -Encoding UTF8 } catch { }
        $script:hasYt = $false
        $script:wbYT = $null
    }
}
try { Add-Content (Join-Path $appBase "diag.txt") ("start hasYt=" + $script:hasYt + " wbYT=" + ($null -ne $script:wbYT) + " " + (Get-Date -Format "HH:mm:ss")) -Encoding UTF8 } catch { }

# 封面
$script:picCover = New-Object System.Windows.Forms.PictureBox
$script:picCover.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$script:picCover.BackColor = $cFill
$script:picCover.Visible = $false
$pnlPlayer.Controls.Add($script:picCover)

$script:lblCoverEmpty = New-Label "♪" 0 0 392 232 96 $cSub $true
$script:lblCoverEmpty.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$script:lblCoverEmpty.Font = New-Object System.Drawing.Font("Segoe UI Symbol", 96)
$pnlPlayer.Controls.Add($script:lblCoverEmpty)

# 歌曲信息
$script:lblSongTitle = New-Label "未播放" 0 0 392 34 18 $cText $true
$pnlPlayer.Controls.Add($script:lblSongTitle)
$script:lblSongArtist = New-Label "" 0 0 392 22 11 $cSub $false
$pnlPlayer.Controls.Add($script:lblSongArtist)
$script:lblSongAlbum = New-Label "" 0 0 392 20 9.5 $cSub $false
$pnlPlayer.Controls.Add($script:lblSongAlbum)
$script:lblModeTag = New-Label "" 0 0 392 20 8.5 $cSub $false
$pnlPlayer.Controls.Add($script:lblModeTag)

# 进度条
$script:tbProgress = New-Object System.Windows.Forms.TrackBar
$script:tbProgress.Minimum = 0
$script:tbProgress.Maximum = 1000
$script:tbProgress.TickStyle = [System.Windows.Forms.TickStyle]::None
$script:tbProgress.BackColor = $cCard
$pnlPlayer.Controls.Add($script:tbProgress)
$script:tbProgress.Add_Scroll({
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*") { if ($script:ytDur -gt 0) { Yt-Seek ($script:tbProgress.Value / 1000 * $script:ytDur) }; return }
    if ($null -ne $script:player -and $script:currentUrl -ne "") { try { $dur = $script:player.currentMedia.duration; if ($dur -gt 0) { $script:player.controls.currentPosition = ($script:tbProgress.Value / 1000 * $dur) } } catch { } }
})
$script:tbProgress.Add_MouseDown({
    param($s, $e)
    if ($e.Button -ne [System.Windows.Forms.MouseButtons]::Left) { return }
    try {
        $rect = $s.ClientRectangle
        $x = [math]::Max(0, [math]::Min($e.X, $rect.Width - 1))
        $pct = [double]$x / [double]$rect.Width
        $s.Value = [int][math]::Round($pct * 1000)
        if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*") { if ($script:ytDur -gt 0) { Yt-Seek ($s.Value / 1000 * $script:ytDur) } }
        elseif ($null -ne $script:player -and $script:currentUrl -ne "") { try { $dur = $script:player.currentMedia.duration; if ($dur -gt 0) { $script:player.controls.currentPosition = ($s.Value / 1000 * $dur) } } catch { } }
    } catch { }
})

$script:lblTime = New-Label "0:00 / 0:00" 0 0 392 20 9 $cSub $false
$script:lblTime.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$pnlPlayer.Controls.Add($script:lblTime)

# 播放控制行
$script:btnPrev = New-SecondaryBtn "⏮" 0 0 56 44 14
$pnlPlayer.Controls.Add($script:btnPrev)
$script:btnPrev.Add_Click({
    if ($script:currentPage -eq "fav" -and $script:favorites.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:favorites.Count; $i++) { if ((Get-TrackKey $script:favorites[$i]) -eq $script:trackKey) { $curIdx = $i; break } }
        if ($curIdx -lt 0) { $curIdx = 0 }
        $prev = if ($curIdx -gt 0) { $curIdx - 1 } else { $script:favorites.Count - 1 }
        Play-TrackObject $script:favorites[$prev]
        return
    }
    if ($script:currentPage -eq "search" -and $script:searchResults.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:searchResults.Count; $i++) { if ($script:searchResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
        if ($curIdx -gt 0) { $it = $script:searchResults[$curIdx-1]; if ($it.preview) { Play-Url $it.preview $it.title $it.artist $it.album $it.cover "preview" } }
    }
    elseif ($script:currentPage -eq "local" -and $script:localIndex -gt 0) { $script:localIndex--; Play-LocalIndex }
    elseif ($script:currentPage -eq "free" -and $script:freeResults.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:freeResults.Count; $i++) { if ($script:freeResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
        if ($curIdx -gt 0) { $it = $script:freeResults[$curIdx-1]; if ($it.videoId) { Play-FreeWithYoutube $it.videoId $it.title $it.creator } }
    }
})

$script:btnPlay = New-PrimaryBtn "▶" 0 0 72 56 14
$script:btnPlay.Font = New-Object System.Drawing.Font($fUI, 14, [System.Drawing.FontStyle]::Bold)
$pnlPlayer.Controls.Add($script:btnPlay)
$script:btnPlay.Add_Click({
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*") {
        # 恢复了「上次播放」但内置播放器尚未载入该视频 → 先加载再播放
        if ($script:ytLoadedUrl -ne $script:currentUrl) {
            $vid = $script:currentUrl.Substring(3)
            $ok = Show-YoutubeEmbed $vid
            if ($ok) {
                Set-YtMaxLayout
                $script:lblModeTag.Text = (T 'player.mode.yt')
                $script:lblModeTag.ForeColor = $cAccent
                $script:ytPlaying = $true
                $script:btnPlay.Text = "❚❚"
            } else {
                try { Start-Process ("https://www.youtube.com/watch?v=" + $vid) -WindowStyle Minimized } catch { }
                $script:lblModeTag.Text = (T 'player.mode.ytbg')
                $script:lblModeTag.ForeColor = $cSuccess
            }
            return
        }
        if ($script:ytPlaying) { Yt-Pause; $script:ytPlaying = $false; $script:btnPlay.Text = "▶" }
        else { Yt-Play; $script:ytPlaying = $true; $script:btnPlay.Text = "❚❚" }
        return
    }
    if ($script:currentUrl -ne "" -and $null -ne $script:player) {
        $st = $script:player.playState
        if ($st -eq 3) { $script:player.controls.pause(); $script:btnPlay.Text = "▶" }
        else { $script:player.controls.play(); $script:btnPlay.Text = "❚❚" }
    }
})

$script:btnPause = New-SecondaryBtn "⏸" 0 0 56 44 14
$pnlPlayer.Controls.Add($script:btnPause)
$script:btnPause.Add_Click({
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*") { Yt-Pause; $script:ytPlaying = $false; $script:btnPlay.Text = "▶"; return }
    if ($script:currentUrl -ne "" -and $null -ne $script:player) { $script:player.controls.pause(); $script:btnPlay.Text = "▶" }
})

$script:btnNext = New-SecondaryBtn "⏭" 0 0 56 44 14
$pnlPlayer.Controls.Add($script:btnNext)
$script:btnNext.Add_Click({
    if ($script:currentPage -eq "fav" -and $script:favorites.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:favorites.Count; $i++) { if ((Get-TrackKey $script:favorites[$i]) -eq $script:trackKey) { $curIdx = $i; break } }
        if ($curIdx -lt 0) { $curIdx = $script:favorites.Count - 1 }
        $next = if ($curIdx -lt $script:favorites.Count - 1) { $curIdx + 1 } else { 0 }
        Play-TrackObject $script:favorites[$next]
        return
    }
    if ($script:currentPage -eq "search" -and $script:searchResults.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:searchResults.Count; $i++) { if ($script:searchResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
        if ($curIdx -ge 0 -and $curIdx -lt $script:searchResults.Count - 1) { $it = $script:searchResults[$curIdx+1]; if ($it.preview) { Play-Url $it.preview $it.title $it.artist $it.album $it.cover "preview" } }
    }
    elseif ($script:currentPage -eq "local" -and $script:localIndex -lt $script:localFiles.Count - 1) { $script:localIndex++; Play-LocalIndex }
    elseif ($script:currentPage -eq "free" -and $script:freeResults.Count -gt 0) {
        $curIdx = -1
        for ($i=0; $i -lt $script:freeResults.Count; $i++) { if ($script:freeResults[$i].title -eq $script:currentTitle) { $curIdx = $i; break } }
        if ($curIdx -ge 0 -and $curIdx -lt $script:freeResults.Count - 1) { $it = $script:freeResults[$curIdx+1]; if ($it.videoId) { Play-FreeWithYoutube $it.videoId $it.title $it.creator } }
    }
})

$script:btnStop = New-SecondaryBtn "■" 0 0 56 44 14
$pnlPlayer.Controls.Add($script:btnStop)
$script:btnStop.Add_Click({ Stop-Play })

# 收藏 + 音量
$script:btnFavCur = New-SecondaryBtn "♡  收藏" 0 0 116 36
$pnlPlayer.Controls.Add($script:btnFavCur)
$script:btnFavCur.Add_Click({
    $t = Get-CurrentTrack
    if ($null -eq $t) { [System.Windows.Forms.MessageBox]::Show((T 'msg.needplay'), (T 'msg.tip'), "OK", "Information") | Out-Null; return }
    if (Test-InFavorites (Get-TrackKey $t)) { Remove-FromFavorites (Get-TrackKey $t) } else { $null = Add-ToFavorites $t }
    Update-FavButton
    Refresh-FavList
})

$script:lblVol = New-Label "音量" 0 0 44 20 9 $cSub $false
$pnlPlayer.Controls.Add($script:lblVol)
$script:tbVol = New-Object System.Windows.Forms.TrackBar
$script:tbVol.Minimum = 0
$script:tbVol.Maximum = 100
$script:tbVol.Value = $script:lastVolume
$script:tbVol.TickStyle = [System.Windows.Forms.TickStyle]::None
$script:tbVol.BackColor = $cCard
$pnlPlayer.Controls.Add($script:tbVol)
$script:tbVol.Add_ValueChanged({
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*" -and $null -ne $script:wbYT -and $null -ne $script:wbYT.CoreWebView2) {
        try { $vol = $script:tbVol.Value; $null = $script:wbYT.CoreWebView2.ExecuteScriptAsync("(function(){var v=document.querySelector('#movie_player video')||document.querySelector('video');if(v){v.volume=$($vol)/100;}})();") } catch { }
        return
    }
    if ($null -ne $script:player) { $script:player.settings.volume = $script:tbVol.Value }
    $script:lastVolume = $script:tbVol.Value
})

$script:lblState = New-Label "●  就绪" 0 0 392 20 9 $cSuccess $false
$pnlPlayer.Controls.Add($script:lblState)

$script:sepPlat = New-Hairline 0 0 392
$pnlPlayer.Controls.Add($script:sepPlat)

# 其他平台入口
$script:lblSrcTitle = New-Label "在其他平台收听" 0 0 200 20 9 $cSub $false
$pnlPlayer.Controls.Add($script:lblSrcTitle)
$script:btnApple = New-PrimaryBtn "Apple Music" 0 0 100 30 9
$pnlPlayer.Controls.Add($script:btnApple)
$script:btnApple.Add_Click({ Open-Platform "apple" })
$script:btnSpotify = New-SecondaryBtn "Spotify" 0 0 86 30 9
$pnlPlayer.Controls.Add($script:btnSpotify)
$script:btnSpotify.Add_Click({ Open-Platform "spotify" })
$script:btnNetEase = New-SecondaryBtn "网易云" 0 0 80 30 9
$pnlPlayer.Controls.Add($script:btnNetEase)
$script:btnNetEase.Add_Click({ Open-Platform "netease" })
$script:btnSound = New-SecondaryBtn "SoundCloud" 0 0 94 30 9
$pnlPlayer.Controls.Add($script:btnSound)
$script:btnSound.Add_Click({ Open-Platform "sound" })
$script:btnQQ = New-SecondaryBtn "QQ音乐" 0 0 82 30 9
$pnlPlayer.Controls.Add($script:btnQQ)
$script:btnQQ.Add_Click({ Open-Platform "qq" })
$script:lblSrcHint = New-Label "点击跳转对应平台搜索当前歌曲" 0 0 300 20 8 $cSub $false
$pnlPlayer.Controls.Add($script:lblSrcHint)

# 睡眠定时
$script:lblSleepTitle = New-Label "睡眠定时" 0 0 100 20 9 $cSub $false
$pnlPlayer.Controls.Add($script:lblSleepTitle)
$script:btnSleep15 = New-SecondaryBtn "15分" 0 0 62 26 9
$pnlPlayer.Controls.Add($script:btnSleep15)
$script:btnSleep15.Add_Click({ Start-SleepTimer 15 })
$script:btnSleep30 = New-SecondaryBtn "30分" 0 0 62 26 9
$pnlPlayer.Controls.Add($script:btnSleep30)
$script:btnSleep30.Add_Click({ Start-SleepTimer 30 })
$script:btnSleep60 = New-SecondaryBtn "60分" 0 0 62 26 9
$pnlPlayer.Controls.Add($script:btnSleep60)
$script:btnSleep60.Add_Click({ Start-SleepTimer 60 })
$script:btnSleepOff = New-SecondaryBtn "取消" 0 0 62 26 9
$pnlPlayer.Controls.Add($script:btnSleepOff)
$script:btnSleepOff.Add_Click({ Stop-SleepTimer })
$script:lblSleepInfo = New-Label "" 0 0 392 20 8.5 $cSub $false
$pnlPlayer.Controls.Add($script:lblSleepInfo)

# ============================================================
#  响应式布局引擎
# ============================================================
function Layout-Sidebar {
    $sw = $pnlSidebar.Width
    $sh = $pnlSidebar.Height
    $lblBrand.SetBounds(18, 22, $sw - 36, 32)
    $lblBrandSub.SetBounds(18, 54, $sw - 36, 18)
    $sepBrand.SetBounds(16, 82, $sw - 32, 1)
    $y = 94
    foreach ($nd in $navDefs) {
        $b = $script:navButtons[$nd.key]
        if ($null -ne $b) { $b.SetBounds(10, $y, $sw - 20, 40) }
        $y += 44
    }
    # 底部控件贴着底边, 小窗口不溢出
    if ($sh -ge 700) {
        $script:chkAutoStart.Visible = $true
        $lblVer.Visible = $true
        $script:chkAutoStart.SetBounds(16, $sh - 96, $sw - 32, 22)
        $lblVer.SetBounds(16, $sh - 66, $sw - 32, 16)
    } else {
        $script:chkAutoStart.Visible = $false
        $lblVer.Visible = $false
    }
}

function Layout-MainHeader {
    $mw = $pnlMain.Width
    $script:lblPageTitle.SetBounds(24, 20, $mw - 48, 34)
    $script:lblPageSub.SetBounds(24, 58, $mw - 48, 18)
    $pnlCard.SetBounds(24, 88, $mw - 48, $pnlMain.Height - 88 - 20)
}

function Layout-Pages {
    # 所有页面面板铺满卡片
    $cw = $pnlCard.Width
    $ch = $pnlCard.Height
    foreach ($pg in @($script:pnlSearchPage, $script:pnlFreePage, $script:pnlLocalPage, $script:pnlSpotPage, $script:pnlFavPage, $script:pnlPlaylistPage)) {
        if ($null -ne $pg) { $pg.SetBounds(0, 0, $cw, $ch) }
    }
    # ---- 搜索页 ----
    $script:lblSearchStatus.SetBounds(16, 12, $cw - 32, 18)
    $tw = [math]::Max(120, [math]::Min(330, $cw - 140))
    $script:txtSearch.SetBounds(16, 36, $tw, 30)
    $script:btnSearch.SetBounds(16 + $tw + 10, 34, $cw - $tw - 36, 32)
    $script:cboSearchHistory.SetBounds(16, 74, $tw, 26)
    $script:lblHistHint.SetBounds(16 + $tw + 12, 76, $cw - $tw - 28, 18)
    $script:lvSearch.SetBounds(16, 106, $cw - 32, $ch - 106 - 56)
    $script:btnPlaySel.SetBounds(16, $ch - 48, 120, 34)
    $script:lblSearchInfo.SetBounds(146, $ch - 42, $cw - 160, 18)
    # ---- 完整听页 ----
    if ($cw -ge 560) {
        $tw2 = [math]::Max(140, [math]::Min(350, $cw - 300))
        $script:txtFree.SetBounds(16, 14, $tw2, 30)
        $script:btnFreeSearch.SetBounds(16 + $tw2 + 10, 12, 80, 32)
        $script:btnDailyPicks.SetBounds(16 + $tw2 + 96, 12, $cw - $tw2 - 112, 32)
        $script:lblFreeStatus.SetBounds(16, 52, $cw - 32, 18)
        $listTop = 74
    } else {
        $script:txtFree.SetBounds(16, 14, $cw - 112, 30)
        $script:btnFreeSearch.SetBounds($cw - 88, 12, 72, 32)
        $script:btnDailyPicks.SetBounds(16, 52, $cw - 32, 28)
        $script:lblFreeStatus.SetBounds(16, 86, $cw - 32, 18)
        $listTop = 108
    }
    $script:lvFree.SetBounds(16, $listTop, $cw - 32, $ch - $listTop - 56)
    $script:btnFreePlay.SetBounds(16, $ch - 48, 120, 34)
    $script:btnFreeDownload.SetBounds(144, $ch - 48, 100, 34)
    $script:lblFreeInfo.SetBounds(252, $ch - 42, $cw - 268, 18)
    # ---- 本地页 ----
    $script:btnOpenFolder.SetBounds(16, 12, 170, 32)
    $script:lblLocalStatus.SetBounds(196, 16, $cw - 212, 18)
    $script:lvLocal.SetBounds(16, 52, $cw - 32, $ch - 52 - 56)
    $script:btnLocalPlay.SetBounds(16, $ch - 48, 100, 34)
    $script:btnLocalPrev.SetBounds(124, $ch - 48, 60, 34)
    $script:btnLocalNext.SetBounds(192, $ch - 48, 60, 34)
    # ---- Spotify 页 ----
    $script:lblSpotTitle.SetBounds(16, 12, $cw - 32, 24)
    # 流派按钮: 宽卡片一行8个, 窄卡片两行4个
    $keys = @("all","pop","hiphop","rock","edm","rb","jazz","latin")
    if ($cw -ge 620) {
        $bw = [math]::Min(76, [int](($cw - 32 - 7 * 8) / 8))
        for ($i = 0; $i -lt 8; $i++) {
            $b = $script:spotCat[$keys[$i]]
            if ($null -ne $b) { $b.SetBounds(16 + $i * ($bw + 8), 44, $bw, 30) }
        }
        $hintY = 82
        $browY = 108
    } else {
        $bw = [math]::Max(60, [int](($cw - 32 - 3 * 8) / 4))
        for ($i = 0; $i -lt 4; $i++) {
            $b = $script:spotCat[$keys[$i]]
            if ($null -ne $b) { $b.SetBounds(16 + $i * ($bw + 8), 44, $bw, 30) }
        }
        for ($i = 4; $i -lt 8; $i++) {
            $b = $script:spotCat[$keys[$i]]
            if ($null -ne $b) { $b.SetBounds(16 + ($i - 4) * ($bw + 8), 80, $bw, 30) }
        }
        $hintY = 116
        $browY = 142
    }
    $script:lblSpotHint.SetBounds(16, $hintY, $cw - 32, 16)
    if ($null -ne $script:wbSpot) { $script:wbSpot.SetBounds(16, $browY, $cw - 32, $ch - $browY - 12) }
    # ---- 收藏页 ----
    $script:lblFavTitle.SetBounds(16, 12, $cw - 32, 20)
    $script:btnFavPlayAll.SetBounds(16, 38, 116, 32)
    $script:btnFavClear.SetBounds(140, 38, 106, 32)
    $script:lvFav.SetBounds(16, 78, $cw - 32, $ch - 78 - 12)
    # ---- 歌单页 ----
    $script:lblPlTitle.SetBounds(16, 12, $cw - 32, 20)
    if ($cw -ge 640) {
        $script:cboPlaylists.SetBounds(16, 38, 180, 26)
        $script:txtPlaylistName.SetBounds(204, 38, 130, 26)
        $script:btnPlCreate.SetBounds(342, 36, 100, 30)
        $script:btnPlAddCur.SetBounds(450, 36, 120, 30)
        $script:btnPlDelete.SetBounds(16, 72, 96, 26)
        $listTop2 = 104
    } else {
        $script:cboPlaylists.SetBounds(16, 38, 140, 26)
        $script:txtPlaylistName.SetBounds(164, 38, 110, 26)
        $script:btnPlCreate.SetBounds(282, 36, 90, 30)
        $script:btnPlAddCur.SetBounds(16, 72, 120, 28)
        $script:btnPlDelete.SetBounds(144, 72, 90, 28)
        $listTop2 = 104
    }
    $script:lvPlaylist.SetBounds(16, $listTop2, $cw - 32, $ch - $listTop2 - 12)
}

function Layout-PlayerVideo {
    # 视频模式: 16:9 视频按面板宽度铺满, 整个区块垂直居中; 只保留标题/进度/控制按钮
    $pw = $pnlPlayer.Width
    $ph = $pnlPlayer.Height
    $sepPlayer.SetBounds(0, 0, 1, $ph)
    if ($null -ne $script:btnLang) { $script:btnLang.SetBounds($pw - 98, 14, 82, 26) }
    # 精简控制条高度 (标题 + 进度 + 时间 + 按钮行 + 状态)
    $stripH = 32 + 28 + 22 + 60 + 22
    $mx = 16
    $bw = $pw - 2 * $mx
    $bh = [int]($bw * 9 / 16)
    $maxBh = $ph - $stripH - 76
    if ($bh -gt $maxBh) {
        $bh = [math]::Max(120, $maxBh)
        $bw = [int]($bh * 16 / 9)
    }
    $bx = [int](($pw - $bw) / 2)
    # 整块 (视频 + 控制条) 垂直居中, 避免底部大片留白; 顶部留出语言按钮的位置
    $blockH = $bh + 12 + $stripH
    $by = [math]::Max(52, [int](($ph - $blockH) / 2))
    $script:videoRect = New-Object System.Drawing.Rectangle($bx, $by, $bw, $bh)
    if ($null -ne $script:wbYT) {
        $script:wbYT.SetBounds($bx, $by, $bw, $bh)
        $script:wbYT.Visible = $true
    }
    if ($script:picCover) { $script:picCover.Visible = $false }
    if ($script:lblCoverEmpty) { $script:lblCoverEmpty.Visible = $false }
    # 隐藏次要控件, 显示精简控制条
    foreach ($c in @($script:lblSongArtist,$script:lblSongAlbum,$script:lblModeTag,$script:btnFavCur,$script:lblVol,$script:tbVol,$script:sepPlat,$script:lblSrcTitle,$script:btnApple,$script:btnSpotify,$script:btnNetEase,$script:btnSound,$script:btnQQ,$script:lblSrcHint,$script:lblSleepTitle,$script:btnSleep15,$script:btnSleep30,$script:btnSleep60,$script:btnSleepOff,$script:lblSleepInfo)) {
        if ($null -ne $c) { $c.Visible = $false }
    }
    foreach ($c in @($script:lblSongTitle,$script:tbProgress,$script:lblTime,$script:btnPrev,$script:btnPlay,$script:btnPause,$script:btnNext,$script:btnStop,$script:lblState)) {
        if ($null -ne $c) { $c.Visible = $true }
    }
    $y = $by + $bh + 12
    $script:lblSongTitle.SetBounds(24, $y, $pw - 48, 28)
    $y += 32
    $script:tbProgress.SetBounds(24, $y, $pw - 48, 24)
    $y += 28
    $script:lblTime.SetBounds(24, $y, $pw - 48, 16)
    $y += 22
    $rowW = 56 + 8 + 72 + 8 + 56 + 8 + 56 + 8 + 56
    $cx = [int](($pw - $rowW) / 2)
    $script:btnPrev.SetBounds($cx, $y, 56, 44)
    $script:btnPlay.SetBounds($cx + 64, $y - 6, 72, 54)
    $script:btnPause.SetBounds($cx + 144, $y, 56, 44)
    $script:btnNext.SetBounds($cx + 208, $y, 56, 44)
    $script:btnStop.SetBounds($cx + 272, $y, 56, 44)
    $y += 56
    $script:lblState.SetBounds(24, $y, $pw - 48, 16)
}

function Layout-Player {
    $pw = $pnlPlayer.Width
    $ph = $pnlPlayer.Height
    $sepPlayer.SetBounds(0, 0, 1, $ph)
    if ($null -ne $script:btnLang) { $script:btnLang.SetBounds($pw - 98, 14, 82, 26) }
    # 从视频模式切回时, 恢复核心控件可见性
    foreach ($c in @($script:lblSongTitle,$script:lblSongArtist,$script:lblSongAlbum,$script:lblModeTag,$script:tbProgress,$script:lblTime,$script:btnPrev,$script:btnPlay,$script:btnPause,$script:btnNext,$script:btnStop,$script:btnFavCur,$script:lblVol,$script:tbVol,$script:lblState)) {
        if ($null -ne $c) { $c.Visible = $true }
    }
    # 紧凑模式: 高度不足时隐藏平台入口和睡眠定时
    $compact = ($ph -lt 780)
    $showPlatforms = (-not $compact)
    # 视频区: 宽度决定 (正方形), 高度不足时受高度限制; 顶部留出语言按钮位置
    $maxV = $pw - 56
    if ($showPlatforms) { $heightBudget = $ph - 530 } else { $heightBudget = $ph - 330 }
    $vSize = [math]::Max(120, [math]::Min($maxV, $heightBudget))
    $vx = [int](($pw - $vSize) / 2)
    $vy = 52
    $script:videoRect = New-Object System.Drawing.Rectangle($vx, $vy, $vSize, $vSize)
    $script:picCover.SetBounds($vx, $vy, $vSize, $vSize)
    $script:lblCoverEmpty.SetBounds($vx, $vy + [int]($vSize * 0.2), $vSize, [int]($vSize * 0.6))
    if ($null -ne $script:wbYT) { $script:wbYT.SetBounds($vx, $vy, $vSize, $vSize) }
    # 歌曲信息
    $y = $vy + $vSize + 12
    $script:lblSongTitle.SetBounds(24, $y, $pw - 48, 30)
    $y += 32
    $script:lblSongArtist.SetBounds(24, $y, $pw - 48, 20)
    $y += 22
    $script:lblSongAlbum.SetBounds(24, $y, $pw - 48, 18)
    $y += 20
    $script:lblModeTag.SetBounds(24, $y, $pw - 48, 16)
    $y += 22
    # 进度 + 时间
    $script:tbProgress.SetBounds(24, $y, $pw - 48, 24)
    $y += 28
    $script:lblTime.SetBounds(24, $y, $pw - 48, 16)
    $y += 22
    # 控制按钮行 (居中)
    $rowW = 56 + 8 + 72 + 8 + 56 + 8 + 56 + 8 + 56
    $cx = [int](($pw - $rowW) / 2)
    $script:btnPrev.SetBounds($cx, $y, 56, 44)
    $script:btnPlay.SetBounds($cx + 64, $y - 6, 72, 54)
    $script:btnPause.SetBounds($cx + 144, $y, 56, 44)
    $script:btnNext.SetBounds($cx + 208, $y, 56, 44)
    $script:btnStop.SetBounds($cx + 272, $y, 56, 44)
    $y += 54
    # 收藏 + 音量
    $script:btnFavCur.SetBounds(24, $y, 100, 32)
    $script:lblVol.SetBounds(132, $y + 6, 36, 18)
    $script:tbVol.SetBounds(170, $y + 2, $pw - 190, 26)
    $y += 40
    $script:lblState.SetBounds(24, $y, $pw - 48, 16)
    $y += 24
    # 平台入口 (紧凑模式隐藏)
    $script:sepPlat.Visible = $showPlatforms
    $script:lblSrcTitle.Visible = $showPlatforms
    $script:btnApple.Visible = $showPlatforms
    $script:btnSpotify.Visible = $showPlatforms
    $script:btnNetEase.Visible = $showPlatforms
    $script:btnSound.Visible = $showPlatforms
    $script:btnQQ.Visible = $showPlatforms
    $script:lblSrcHint.Visible = $showPlatforms
    $script:lblSleepTitle.Visible = $showPlatforms
    $script:btnSleep15.Visible = $showPlatforms
    $script:btnSleep30.Visible = $showPlatforms
    $script:btnSleep60.Visible = $showPlatforms
    $script:btnSleepOff.Visible = $showPlatforms
    $script:lblSleepInfo.Visible = $showPlatforms
    if ($showPlatforms) {
        $script:sepPlat.SetBounds(24, $y, $pw - 48, 1)
        $y += 12
        $script:lblSrcTitle.SetBounds(24, $y, 200, 16)
        $y += 20
        if ($pw -ge 500) {
            $bw2 = [math]::Min(100, [int](($pw - 48 - 4 * 8) / 5))
            $script:btnApple.SetBounds(24, $y, $bw2, 28)
            $script:btnSpotify.SetBounds(24 + ($bw2 + 8), $y, $bw2, 28)
            $script:btnNetEase.SetBounds(24 + 2 * ($bw2 + 8), $y, $bw2, 28)
            $script:btnSound.SetBounds(24 + 3 * ($bw2 + 8), $y, $bw2, 28)
            $script:btnQQ.SetBounds(24 + 4 * ($bw2 + 8), $y, $bw2, 28)
            $y += 34
        } else {
            $bw2 = [math]::Max(66, [int](($pw - 48 - 2 * 8) / 3))
            $script:btnApple.SetBounds(24, $y, $bw2, 28)
            $script:btnSpotify.SetBounds(24 + ($bw2 + 8), $y, $bw2, 28)
            $script:btnNetEase.SetBounds(24 + 2 * ($bw2 + 8), $y, $bw2, 28)
            $y += 32
            $script:btnSound.SetBounds(24, $y, $bw2, 28)
            $script:btnQQ.SetBounds(24 + ($bw2 + 8), $y, $bw2, 28)
            $y += 34
        }
        $script:lblSrcHint.SetBounds(24, $y, $pw - 48, 14)
        $y += 18
        $script:lblSleepTitle.SetBounds(24, $y, 100, 16)
        $y += 18
        $script:btnSleep15.SetBounds(24, $y, 56, 24)
        $script:btnSleep30.SetBounds(86, $y, 56, 24)
        $script:btnSleep60.SetBounds(148, $y, 56, 24)
        $script:btnSleepOff.SetBounds(210, $y, 56, 24)
        $y += 28
        $script:lblSleepInfo.SetBounds(24, $y, $pw - 48, 14)
    }
}

function Apply-Layout {
    $cw = $form.ClientSize.Width
    $ch = $form.ClientSize.Height
    if ($cw -lt 600 -or $ch -lt 400) { return }
    # 侧栏宽度: 大窗口 200, 小窗口 176
    $sbW = if ($cw -ge 1280) { 200 } else { 176 }
    $rest = $cw - $sbW
    # 比例: 完整听页 列表:视频=4:6 (视频优先); 视频播放中再放大到 32:68; 其他页 6:4
    if ($script:currentPage -eq "free") {
        $playerRatio = if ($script:ytMaximized) { 0.68 } else { 0.60 }
    } else {
        $playerRatio = 0.40
    }
    $playerW = [int]($rest * $playerRatio)
    $mainW = $rest - $playerW
    $pnlSidebar.SetBounds(0, 0, $sbW, $ch)
    $pnlMain.SetBounds($sbW, 0, $mainW, $ch)
    $pnlPlayer.SetBounds($sbW + $mainW, 0, $playerW, $ch)
    Layout-Sidebar
    Layout-MainHeader
    Layout-Pages
    if ($script:ytMaximized) { Layout-PlayerVideo } else { Layout-Player }
}

# ---------- 页面切换 ----------
function Switch-Page {
    param($page)
    $script:currentPage = $page
    $script:pnlSearchPage.Visible = ($page -eq "search")
    $script:pnlFreePage.Visible = ($page -eq "free")
    $script:pnlLocalPage.Visible = ($page -eq "local")
    $script:pnlSpotPage.Visible = ($page -eq "spot")
    $script:pnlFavPage.Visible = ($page -eq "fav")
    $script:pnlPlaylistPage.Visible = ($page -eq "playlist")
    foreach ($k in $script:navButtons.Keys) {
        $b = $script:navButtons[$k]
        if ($null -ne $b) {
            if ($k -eq $page) {
                $b.BackColor = $cPillBg
                $b.ForeColor = $cAccent
                $b.Font = New-Object System.Drawing.Font($fUI, 11, [System.Drawing.FontStyle]::Bold)
            } else {
                $b.BackColor = $cSidebarBg
                $b.ForeColor = $cText
                $b.Font = New-Object System.Drawing.Font($fUI, 11, [System.Drawing.FontStyle]::Regular)
            }
        }
    }
    $script:lblPageTitle.Text = (T "page.$page.t")
    $script:lblPageSub.Text = (T "page.$page.s")
    # 页面比例可能变化 (完整听页视频更大)
    Apply-Layout
}

# ---------- 全屏切换 (F11) ----------
function Toggle-Fullscreen {
    if (-not $script:fullscreen) {
        $script:fullscreen = $true
        $script:prevBorderStyle = $form.FormBorderStyle
        $script:prevBounds = $form.Bounds
        $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    } else {
        $script:fullscreen = $false
        $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        $form.FormBorderStyle = $script:prevBorderStyle
        if ($null -ne $script:prevBounds) { $form.Bounds = $script:prevBounds }
    }
}

# ---------- 进度定时器 ----------
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    # 注: 视频模式下保留了精简控制条 (标题/进度/时间/按钮), 因此仍需轮询更新
    if ($script:playMode -eq "full" -and $script:currentUrl -like "yt:*" -and $null -ne $script:wbYT -and $null -ne $script:wbYT.CoreWebView2) {
        $st2 = Yt-State
        if ($null -ne $st2 -and $st2.Dur -gt 0) {
            $script:ytDur = $st2.Dur
            $script:lblTime.Text = ("{0} / {1}" -f (Format-Duration $st2.Pos), (Format-Duration $st2.Dur))
            $pct = [math]::Round($st2.Pos / $st2.Dur * 1000)
            if ($script:tbProgress.Value -ne $pct) { $script:tbProgress.Value = $pct }
            if ($st2.Playing) { $script:btnPlay.Text = "❚❚"; $script:lblState.Text = (T 'player.state.playing'); $script:lblState.ForeColor = $cAccent; $script:ytPlaying = $true }
            else { $script:btnPlay.Text = "▶"; $script:lblState.Text = (T 'player.state.paused'); $script:lblState.ForeColor = $cWarn; $script:ytPlaying = $false }
            if ($st2.Pos -ge ($st2.Dur - 1) -and $st2.Dur -gt 5) { Auto-NextTrack }
        }
        return
    }
    if ($null -ne $script:player -and $script:currentUrl -ne "") {
        try {
            $dur = $script:player.currentMedia.duration
            $pos = $script:player.controls.currentPosition
            if ($dur -gt 0 -and $pos -ge 0) {
                $script:lblTime.Text = ("{0} / {1}" -f (Format-Duration $pos), (Format-Duration $dur))
                $pct = [math]::Round($pos / $dur * 1000)
                if ($script:tbProgress.Value -ne $pct) { $script:tbProgress.Value = $pct }
                $st = $script:player.playState
                if ($st -eq 1) { $script:btnPlay.Text = "▶"; $script:lblState.Text = (T 'player.state.ready'); $script:lblState.ForeColor = $cSuccess }
                elseif ($st -eq 2) { $script:btnPlay.Text = "▶"; $script:lblState.Text = (T 'player.state.paused'); $script:lblState.ForeColor = $cWarn }
                elseif ($st -eq 3) { $script:btnPlay.Text = "❚❚"; $script:lblState.Text = (T 'player.state.playing'); $script:lblState.ForeColor = $cAccent }
                elseif ($st -eq 10) { Auto-NextTrack }
            }
        } catch { }
    }
})
$timer.Start()

# ---------- 键盘快捷键 ----------
$form.KeyPreview = $true
$form.Add_KeyDown({
    param($s, $e)
    $ctrl = $e.Control
    switch ($true) {
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::F11 } { Toggle-Fullscreen; $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Escape -and $script:fullscreen } { Toggle-Fullscreen; $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Space } { $null = $script:btnPlay.PerformClick(); $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Left } { Seek-BySeconds -5; $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Right } { Seek-BySeconds 5; $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Up } { $script:tbVol.Value = [math]::Min(100, $script:tbVol.Value + 5); $e.Handled = $true }
        { $e.KeyCode -eq [System.Windows.Forms.Keys]::Down } { $script:tbVol.Value = [math]::Max(0, $script:tbVol.Value - 5); $e.Handled = $true }
        { $ctrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::L } { Switch-Page "local"; $e.Handled = $true }
        { $ctrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::F } { $null = $script:btnFavCur.PerformClick(); $e.Handled = $true }
        { $ctrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::S } { Switch-Page "search"; $script:txtSearch.Focus(); $e.Handled = $true }
        { $ctrl -and $e.KeyCode -eq [System.Windows.Forms.Keys]::D } { Switch-Page "free"; $null = $script:btnDailyPicks.PerformClick(); $e.Handled = $true }
    }
})

# 窗口大小变化 → 重排
$form.Add_Resize({ Apply-Layout })
$form.Add_MaximizedBoundsChanged({ Apply-Layout })

# ---------- 初始化 ----------
try { $script:exePath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName } catch { $script:exePath = $null }
if (-not (Test-Path $script:cacheDir)) { New-Item -ItemType Directory -Path $script:cacheDir -Force | Out-Null }
if (-not (Test-Path $script:dataDir)) { New-Item -ItemType Directory -Path $script:dataDir -Force | Out-Null }
Load-UserData
if ($null -ne $script:tbVol) { $script:tbVol.Value = $script:lastVolume }
if ($null -ne $script:chkAutoStart) { $script:chkAutoStart.Checked = $script:autoStart }
$defaultDir = Join-Path ([Environment]::GetFolderPath("MyMusic")) "MusicBox"
if (-not (Test-Path $defaultDir)) { New-Item -ItemType Directory -Path $defaultDir -Force | Out-Null }
Load-LocalDir $defaultDir
Refresh-FavList
Refresh-PlaylistCombo
Refresh-PlaylistItems
Refresh-SearchHistoryCombo
Save-UserData

# 记住上次播放
if ($script:currentTitle -and $script:currentTitle -ne "未播放") {
    $script:lblSongTitle.Text = $script:currentTitle
    $script:lblSongArtist.Text = $script:currentArtist
    $script:lblSongAlbum.Text = $script:currentAlbum
    if ($script:currentCover) { Show-Cover $script:currentCover } else { Show-Cover "" }
    $script:lblModeTag.Text = (T 'player.lastplay')
    $script:lblModeTag.ForeColor = $cSub
    $script:lblState.Text = "已就绪"
}

# Spotify 榜单初始加载
$initTimer = New-Object System.Windows.Forms.Timer
$initTimer.Interval = 800
$initTimer.Add_Tick({
    $initTimer.Stop()
    try { Navigate-Spotify "all"; Set-SpotCatActive $script:spotCat["all"] } catch { }
})
$initTimer.Start()

# 关闭时保存
$form.Add_FormClosing({
    param($s, $e)
    try {
        if ($null -ne $script:player -and $script:currentUrl -ne "") { try { $script:player.controls.stop() } catch { } }
        Save-UserData
    } catch { }
})

Apply-Language
Switch-Page "free"
$form.ShowDialog() | Out-Null
