# ===============================
# 設定
# ===============================
#********************************************************
$watchPath = "Z:\powershell\検証用"
#********************************************************
$logFile   = Join-Path $watchPath "rename.log"

# ★ 切替フラグ（ここだけ触る）
#********************************************************
$UseExifDate = $true   # true=撮影日 / false=CreationTime
#********************************************************

# exiftool
$ExifTool = "C:\Tools\exiftool.exe"

# 対象拡張子
#********************************************************
$extPattern = '^(jpg|jpeg|png|mov|mp4|webm|jxr|arw|tif|dng|m4v|webp|gif)$'
#********************************************************

# 変換済み除外
$donePattern = '^\d{8}_\d{3}_\d{4}'

# 連番管理
$global:seqMap = @{}

# UTF-8 BOM
$Utf8Bom = New-Object System.Text.UTF8Encoding($true)

# ===============================
# ログ出力
# ===============================
function Write-Log {
    param([string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $Message"
    Write-Host $line
    $sw = New-Object System.IO.StreamWriter($logFile, $true, $Utf8Bom)
    $sw.WriteLine($line)
    $sw.Close()
}

# ===============================
# コピー完了待ち
# ===============================
function Wait-FileComplete {
    param([string]$Path)
    $last = -1
    while ($true) {
        Start-Sleep -Milliseconds 800
        try {
            $f = Get-Item $Path -ErrorAction Stop
            if ($f.Length -eq $last) { return $true }
            $last = $f.Length
        } catch { return $false }
    }
}

# ===============================
# ★ 基準日時取得（完全版）
# ===============================

function Get-BaseDateTime {
    param($File)

    if ($UseExifDate) {
        try {
            # 写真
            if ($File.Extension -match '\.(jpg|jpeg|png|tif|dng|arw)$') {
                $dt = & $ExifTool -s -s -s -DateTimeOriginal $File.FullName 2>$null
                if ($dt) {
                    return @{
                        Date   = [datetime]::ParseExact($dt.Substring(0,19),'yyyy:MM:dd HH:mm:ss',$null)
                        Source = 'DateTimeOriginal'
                    }
                }
            }
            # 動画
            elseif ($File.Extension -match '\.(mov|mp4|m4v|webm)$') {
                $dt = & $ExifTool -s -s -s -CreateDate $File.FullName 2>$null
                if ($dt) {
                    return @{
                        Date   = [datetime]::ParseExact($dt.Substring(0,19),'yyyy:MM:dd HH:mm:ss',$null)
                        Source = 'CreateDate'
                    }
                }
            }
        } catch {}
    }

    # フォールバック順
    if ($File.LastWriteTime) {
        return @{ Date = $File.LastWriteTime; Source = 'LastWriteTime' }
    }
    if ($File.CreationTime) {
        return @{ Date = $File.CreationTime; Source = 'CreationTime' }
    }

    return $null
}


# ===============================
# 単体処理
# ===============================
function Process-File {
    param($File)

    $ext = $File.Extension.TrimStart('.').ToLower()
    if ($ext -notmatch $extPattern) { return }
    if ($File.Name -match $donePattern) { return }
    if (-not (Wait-FileComplete $File.FullName)) { return }

    $File = Get-Item $File.FullName -ErrorAction SilentlyContinue
    if (-not $File) { return }

    # ★ 正しい取得方法（ここが最重要）
    $info = Get-BaseDateTime $File
    if (-not $info) { return }

    $dt     = $info.Date
    $source = $info.Source

    $date = $dt.ToString("yyyyMMdd")
    $time = $dt.ToString("HHmm")

    $key = "$date.$ext"
    if (-not $global:seqMap.ContainsKey($key)) {
        $global:seqMap[$key] = 1
    }
#-------
#    $seq = "{0:D3}" -f $global:seqMap[$key]
#    $newName = "${date}_${seq}_${time}.$ext"
#    $newPath = Join-Path $watchPath $newName
#-------

#+++++++
$seq = "{0:D3}" -f $global:seqMap[$key]

# 追加テキスト
#********************************************************
$suffix = "_検証用"
#********************************************************
if (-not [string]::IsNullOrWhiteSpace($AddText)) {
    $suffix = "_$AddText"
}

$newName = "${date}_${seq}_${time}${suffix}.$ext"

# ★ ここが重要：元フォルダを維持
$dir     = $File.DirectoryName
$newPath = Join-Path $dir $newName

if (Test-Path $newPath) { return }

try {
    Rename-Item $File.FullName $newPath -ErrorAction Stop
    $global:seqMap[$key]++
    Write-Log "Renamed: $($File.Name) → $newName (Source=$source)"
} catch {}
}

# ===============================
# 初回処理
# ===============================
Write-Log "Initial scan started"

Get-ChildItem $watchPath -File -Recurse |
Sort-Object CreationTime |
ForEach-Object { Process-File -File $_ }

Write-Log "Initial scan finished"
Write-Log "Polling watch started: $watchPath"

# ===============================
# 監視ループ
# ===============================
while ($true) {
    Get-ChildItem $watchPath -File -Recurse |
    Sort-Object CreationTime |
    ForEach-Object { Process-File -File $_ }

    Start-Sleep -Seconds 2
}

