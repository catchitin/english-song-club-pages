$ErrorActionPreference = 'Stop'
$testRoot = Join-Path 'G:\My Coding\english-song-club-local\pages-watchdog-tests' ([guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$source = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\scripts\watch-mirror.ps1') -Raw
function Invoke-FakeGh {
    $global:LASTEXITCODE = 0
    $joined = $args -join ' '
    if ($joined -match '/enable') { $global:watchdogTest_enabled = $true; return '' }
    if ($joined -match '^workflow run') { $global:watchdogTest_dispatches++; return '' }
    if ($joined -match '/runs\?') {
        $runs = @(@{conclusion='success';status='completed'})
        if ($global:watchdogTest_busy) { $runs += @{conclusion=$null;status='in_progress'} }
        return (@{workflow_runs=$runs} | ConvertTo-Json -Depth 5 -Compress)
    }
    return (@{state=$(if ($global:watchdogTest_enabled) {'active'} else {'disabled_inactivity'})} | ConvertTo-Json -Compress)
}
function Invoke-RestMethod {
    if ($global:watchdogTest_missing) { throw 'marker unavailable' }
    return @{published_at=[DateTimeOffset]::UtcNow.AddHours(-$global:watchdogTest_age).ToString('o');run_id='fixture'}
}
function Invoke-WebRequest { return @{StatusCode=200;Content='<!doctype html><html>fixture</html>'} }
$cases = @(
    @{name='healthy';enabled=$true;age=0;busy=$false;missing=$false;dispatches=0;exit=0},
    @{name='disabled';enabled=$false;age=0;busy=$false;missing=$false;dispatches=1;exit=0},
    @{name='stale';enabled=$true;age=5;busy=$false;missing=$false;dispatches=1;exit=1},
    @{name='busy';enabled=$true;age=5;busy=$true;missing=$false;dispatches=0;exit=1},
    @{name='missing';enabled=$true;age=0;busy=$false;missing=$true;dispatches=1;exit=1}
)
foreach ($case in $cases) {
    $global:watchdogTest_enabled=$case.enabled; $global:watchdogTest_age=$case.age; $global:watchdogTest_busy=$case.busy; $global:watchdogTest_missing=$case.missing; $global:watchdogTest_dispatches=0
    $caseRuntime = Join-Path $testRoot $case.name
    $testSource = $source.Replace("'C:\Program Files\GitHub CLI\gh.exe'", "'Invoke-FakeGh'").Replace("'G:\My Coding\english-song-club-local\pages-watchdog'", "'$caseRuntime'")
    $testScript = Join-Path $testRoot ($case.name + '.ps1')
    [IO.File]::WriteAllText($testScript, $testSource, [Text.UTF8Encoding]::new($true))
    & $testScript -NoNotify
    if ($LASTEXITCODE -ne $case.exit -or $global:watchdogTest_dispatches -ne $case.dispatches -or !$global:watchdogTest_enabled) { throw "Failed watchdog case: $($case.name)" }
    Write-Output "PASS $($case.name)"
}
