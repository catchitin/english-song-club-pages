param([switch]$NoNotify)
$ErrorActionPreference = 'Stop'
$repo = 'catchitin/english-song-club-pages'
$gh = 'C:\Program Files\GitHub CLI\gh.exe'
$runtime = 'G:\My Coding\english-song-club-local\pages-watchdog'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
$now = [DateTimeOffset]::UtcNow
function Invoke-Gh([string[]]$Arguments) {
    $result = & $gh @Arguments 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'GitHub API request failed; check GitHub CLI authentication/network.' }
    return ($result -join "`n")
}
function Show-MirrorAlert([string]$Message) {
    try {
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('EnglishSongClub.PagesWatchdog')
        if ([string]$notifier.get_Setting() -ne 'Enabled') { throw 'Windows notifications disabled' }
        $escaped = [Security.SecurityElement]::Escape($Message)
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>英文歌社團網站同步異常</text><text>$escaped</text></binding></visual></toast>")
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        $toast.Tag = 'mirror-error'
        $toast.Group = 'EnglishSongClub'
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddDays(7)
        $notifier.Show($toast) # Remains in Notification Center when the banner disappears.
    } catch {
        $shell = New-Object -ComObject WScript.Shell
        $shell.Popup("英文歌社團網站同步異常，請查看 GitHub Actions。`n$Message", 30, 'English Song Club mirror', 48) | Out-Null
    }
}
try {
    $workflow = Invoke-Gh @('api', "repos/$repo/actions/workflows/mirror.yml") | ConvertFrom-Json
    if ($workflow.state -ne 'active') {
        Invoke-Gh @('api', "repos/$repo/actions/workflows/mirror.yml/enable", '-X', 'PUT') | Out-Null
        Invoke-Gh @('workflow', 'run', 'mirror.yml', '-R', $repo) | Out-Null
        $verified = Invoke-Gh @('api', "repos/$repo/actions/workflows/mirror.yml") | ConvertFrom-Json
        if ($verified.state -ne 'active') { throw 'Mirror workflow could not be re-enabled.' }
        Add-Content -LiteralPath "$runtime/recovery.log" -Value "$now re-enabled and dispatched mirror"
    }
    $runs = Invoke-Gh @('api', "repos/$repo/actions/workflows/mirror.yml/runs?per_page=20") | ConvertFrom-Json
    $success = @($runs.workflow_runs | Where-Object conclusion -eq 'success' | Select-Object -First 1)
    $inFlight = @($runs.workflow_runs | Where-Object { $_.status -in @('queued','in_progress','waiting','pending','requested') })
    $age = [double]::PositiveInfinity
    $marker = $null
    try {
        $marker = Invoke-RestMethod -Uri "https://catchitin.github.io/english-song-club-pages/sync-status.json?t=$($now.ToUnixTimeSeconds())" -TimeoutSec 40
        $age = ($now - [DateTimeOffset]::Parse($marker.published_at)).TotalHours
    } catch { } # Missing/unreachable marker must still reach the recovery path.
    $repairFile = "$runtime/last-dispatch.txt"
    $repairDue = !(Test-Path -LiteralPath $repairFile)
    if (!$repairDue) { $repairDue = ($now - [DateTimeOffset]::Parse((Get-Content -LiteralPath $repairFile -Raw))).TotalHours -ge 1 }
    if (($age -gt 3 -or $success.Count -eq 0) -and $inFlight.Count -eq 0 -and $repairDue) {
        Invoke-Gh @('workflow', 'run', 'mirror.yml', '-R', $repo) | Out-Null
        Set-Content -LiteralPath $repairFile -Value $now.ToString('o')
        Add-Content -LiteralPath "$runtime/recovery.log" -Value "$now stale site; dispatched mirror"
    }
    if ($age -gt 4) { throw "Public mirror has not updated for $([Math]::Round($age,1)) hours; recovery requested." }
    if ($success.Count -eq 0) { throw 'No successful mirror workflow among recent runs.' }
    $homeResponse = Invoke-WebRequest -UseBasicParsing -Uri 'https://catchitin.github.io/english-song-club-pages/' -TimeoutSec 40
    if ($homeResponse.StatusCode -ne 200 -or $homeResponse.Content -notmatch '(?i)<!doctype html') { throw 'Public home page failed validation.' }
    @{ checked_at=$now.ToString('o'); status='ok'; age_hours=[Math]::Round($age,2); run_id=$marker.run_id; workflow_state='active' } | ConvertTo-Json | Set-Content -LiteralPath "$runtime/status.json"
    exit 0
} catch {
    $message = $_.Exception.Message
    @{ checked_at=$now.ToString('o'); status='error'; error=$message } | ConvertTo-Json | Set-Content -LiteralPath "$runtime/status.json"
    Add-Content -LiteralPath "$runtime/errors.log" -Value "$now $message"
    $alertFile = "$runtime/last-alert.txt"
    $alertDue = !(Test-Path -LiteralPath $alertFile)
    if (!$alertDue) { $alertDue = ($now - [DateTimeOffset]::Parse((Get-Content -LiteralPath $alertFile -Raw))).TotalHours -ge 6 }
    if (!$NoNotify -and $alertDue) {
        Show-MirrorAlert $message
        Set-Content -LiteralPath $alertFile -Value $now.ToString('o')
    }
    exit 1
}
