param([switch]$Editor, [switch]$PrepareOnly, [string]$GodotPath = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineVersion = '4.6.1-stable'
$runtimeDir = Join-Path $projectRoot '.tools\godot'
$cachedEngine = Join-Path $runtimeDir "Godot_v${engineVersion}_win64.exe"

function Get-CompatibleVersion([string]$Executable) {
    try {
        $versionText = (& $Executable --headless --version 2>$null | Out-String).Trim()
        if ($versionText -match '^(\d+)\.(\d+)\.(\d+)') {
            $version = [version]::new([int]$Matches[1], [int]$Matches[2], [int]$Matches[3])
            if ($version.Major -eq 4 -and $version -ge [version]'4.6.1') { return $version }
        }
    } catch { }
    return $null
}

function Find-Engine {
    if ($GodotPath) {
        if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) { throw 'The supplied Godot path does not exist.' }
        if (-not (Get-CompatibleVersion $GodotPath)) { throw 'The supplied runtime must be standard Godot 4.6.1 or newer within Godot 4.' }
        return $GodotPath
    }
    if ((Test-Path -LiteralPath $cachedEngine -PathType Leaf) -and (Get-CompatibleVersion $cachedEngine)) { return $cachedEngine }
    foreach ($candidateName in @('godot', 'godot4', 'Godot_v4.6.1-stable_win64')) {
        $engineCommand = Get-Command $candidateName -CommandType Application -ErrorAction SilentlyContinue
        if ($engineCommand -and (Get-CompatibleVersion $engineCommand.Source)) { return $engineCommand.Source }
    }
    return $null
}

try {
    $engine = Find-Engine
    if (-not $engine) {
        Write-Host 'First launch: preparing the official portable Godot runtime. This happens once.'
        New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
        $archiveName = "Godot_v${engineVersion}_win64.exe.zip"
        $archivePath = Join-Path $runtimeDir $archiveName
        $releaseUrl = "https://github.com/godotengine/godot/releases/download/$engineVersion"
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "$releaseUrl/$archiveName" -OutFile $archivePath -UseBasicParsing
        $checksumPath = Join-Path $runtimeDir 'SHA512-SUMS.txt'
        Invoke-WebRequest -Uri "$releaseUrl/SHA512-SUMS.txt" -OutFile $checksumPath -UseBasicParsing
        $checksumLine = Get-Content -LiteralPath $checksumPath | Where-Object { $_ -match ([regex]::Escape($archiveName) + '$') } | Select-Object -First 1
        if (-not $checksumLine) { throw 'The official release did not include a checksum for this runtime.' }
        $expectedHash = ($checksumLine -split '\s+')[0].ToUpperInvariant()
        $actualHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA512).Hash
        if ($actualHash -ne $expectedHash) { throw 'Runtime checksum mismatch. Please retry the download.' }
        Expand-Archive -LiteralPath $archivePath -DestinationPath $runtimeDir -Force
        Remove-Item -LiteralPath $archivePath
        $engine = $cachedEngine
    }
    if (-not (Get-CompatibleVersion $engine)) { throw 'The prepared runtime is incompatible. Godot 4.6.1 or newer within Godot 4 is required.' }
    $importLog = Join-Path $runtimeDir 'import.log'
    $importStamp = Join-Path $runtimeDir 'import.stamp'
    New-Item -ItemType Directory -Path $runtimeDir -Force | Out-Null
    $fingerprintEntries = foreach ($sourceDirectory in @('src','scenes','assets','data')) {
        Get-ChildItem -LiteralPath (Join-Path $projectRoot $sourceDirectory) -Recurse -File |
            Where-Object { $_.Extension -notin @('.import','.uid') } |
            Sort-Object FullName |
            ForEach-Object { '{0}|{1}|{2}' -f $_.FullName.Substring($projectRoot.Length),$_.Length,$_.LastWriteTimeUtc.Ticks }
    }
    $projectFile = Get-Item -LiteralPath (Join-Path $projectRoot 'project.godot')
    $fingerprintEntries += '{0}|{1}' -f $projectFile.Length,$projectFile.LastWriteTimeUtc.Ticks
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        $fingerprint = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes(($fingerprintEntries -join "`n")))).Replace('-','')
    } finally { $hasher.Dispose() }
    $previousFingerprint = if (Test-Path -LiteralPath $importStamp) { (Get-Content -LiteralPath $importStamp -Raw).Trim() } else { '' }
    if ($previousFingerprint -ne $fingerprint -or -not (Test-Path -LiteralPath (Join-Path $projectRoot '.godot\imported'))) {
        Write-Host 'Preparing StackCorp assets...'
        & $engine --headless --path $projectRoot --editor --import --log-file $importLog 2>&1 | Out-Null
        $engineExit = $LASTEXITCODE
        $importText = if (Test-Path -LiteralPath $importLog) { Get-Content -LiteralPath $importLog -Raw } else { '' }
        if ($engineExit -ne 0 -or $importText -match '(SCRIPT ERROR|Parse Error|Failed to load script)') {
            throw "Godot could not prepare the project. Details: $importLog"
        }
        [IO.File]::WriteAllText($importStamp,$fingerprint,[Text.UTF8Encoding]::new($false))
    }
    if ($PrepareOnly) { Write-Host 'StackCorp is ready.'; exit 0 }
    $launchArgs = @('--path', ('"' + $projectRoot + '"'))
    if ($Editor) { $launchArgs += '--editor' }
    Start-Process -FilePath $engine -ArgumentList $launchArgs -WorkingDirectory $projectRoot
} catch {
    Write-Host "StackCorp could not start: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'You can also open project.godot in Godot 4.6.1 or newer and press F5.'
    exit 1
}

