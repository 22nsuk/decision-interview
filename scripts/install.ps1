# Run with & or -File; do not dot-source this installer.
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string] $Destination = (Join-Path $HOME ".agents/skills/decision-interview")
)

$ErrorActionPreference = "Stop"
$installSource = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../skills/decision-interview"))
$installRequiredFiles = @("SKILL.md", "agents/openai.yaml")
foreach ($relativePath in $installRequiredFiles) {
    if (-not (Test-Path -LiteralPath (Join-Path $installSource $relativePath) -PathType Leaf)) {
        throw "Missing required source file: $relativePath"
    }
}

$installProvider = $null
$installDrive = $null
$installTarget = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(
    $Destination, [ref] $installProvider, [ref] $installDrive
)
if ($installProvider.Name -ne "FileSystem") {
    throw "Destination must be a filesystem path."
}
# GetAttributes sees directory entries, including dangling symbolic links.
$installExists = $false
try {
    [void] [System.IO.File]::GetAttributes($installTarget)
    $installExists = $true
}
catch [System.IO.FileNotFoundException] {}
catch [System.IO.DirectoryNotFoundException] {}
if ($installExists) { throw "Already exists: $installTarget" }
$installTarget = $installTarget.TrimEnd([char[]] "\/")

$installParent = Split-Path -Parent $installTarget
[void] [System.IO.Directory]::CreateDirectory($installParent)
$installStage = Join-Path $installParent (".decision-interview-install-" + [guid]::NewGuid())
$installOwnsStage = $false
try {
    New-Item -ItemType Directory -Path $installStage -ErrorAction Stop | Out-Null
    $installOwnsStage = $true
    $installPayload = Join-Path $installStage "payload"
    [void] [System.IO.Directory]::CreateDirectory($installPayload)
    Get-ChildItem -LiteralPath $installSource -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $installPayload -Recurse -Force -ErrorAction Stop
    }
    foreach ($relativePath in $installRequiredFiles) {
        $copiedPath = Join-Path $installPayload $relativePath
        if (-not (Test-Path -LiteralPath $copiedPath -PathType Leaf)) {
            throw "Copy did not produce required file: $relativePath"
        }
        $sourceHash = (Get-FileHash -LiteralPath (Join-Path $installSource $relativePath) -Algorithm SHA256).Hash
        if ((Get-FileHash -LiteralPath $copiedPath -Algorithm SHA256).Hash -cne $sourceHash) {
            throw "Copied file differs from source: $relativePath"
        }
    }
    # Same-parent move publishes the complete copy and refuses an existing destination,
    # including one created after the earlier check. Never clean up the destination.
    [System.IO.Directory]::Move($installPayload, $installTarget)
}
finally {
    if ($installOwnsStage) {
        Remove-Item -LiteralPath $installStage -Recurse -Force -ErrorAction Stop
    }
}
Write-Output "Installed: $installTarget"
