# Exercise the actual README examples in a disposable destination, without changing HOME.
$decisionSavedPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"
$decisionRepoRoot = Split-Path -Parent $PSScriptRoot
$decisionTemporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("decision-install-" + [guid]::NewGuid())

function Get-InstallExample([string] $Document) {
    $exampleMatches = [regex]::Matches(
        (Get-Content -LiteralPath $Document -Raw -Encoding UTF8),
        '(?ms)^```powershell\r?\n(?<code>.*?)^```\r?$'
    )
    if ($exampleMatches.Count -ne 1) { throw "Expected one PowerShell example in $Document" }
    return $exampleMatches[0].Groups['code'].Value.Replace("`r`n", "`n").Trim()
}

function Get-InstallManifest([string] $Directory) {
    return (Get-ChildItem -LiteralPath $Directory -File -Recurse -Force |
        Sort-Object FullName | ForEach-Object {
            $_.FullName.Substring($Directory.Length + 1) + ':' +
                (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }) -join "`n"
}

function Assert-CallerState {
    if ($ErrorActionPreference -ne "Continue" -or
        $skillSource -ne "caller-source" -or $skillTarget -ne "caller-target") {
        throw "The installation example changed caller settings or variables."
    }
}

function Set-TestDestination([string] $Code, [string] $Destination) {
    $assignment = '$skillTarget = Join-Path $HOME ".agents/skills/decision-interview"'
    if ([regex]::Matches($Code, [regex]::Escape($assignment)).Count -ne 1) {
        throw "Expected exactly one documented destination assignment."
    }
    return $Code.Replace($assignment, ('$skillTarget = ' + "'" + $Destination.Replace("'", "''") + "'"))
}

Push-Location $decisionRepoRoot
try {
    $decisionExample = Get-InstallExample (Join-Path $decisionRepoRoot "README.md")
    if ($decisionExample -cne (Get-InstallExample (Join-Path $decisionRepoRoot "README.en.md"))) {
        throw "The Korean and English installation commands differ."
    }
    $decisionSource = Join-Path $decisionRepoRoot "skills/decision-interview"
    $decisionDestination = Join-Path $decisionTemporaryRoot "installed/decision-interview"
    $decisionCode = Set-TestDestination $decisionExample $decisionDestination

    $skillSource = "caller-source"
    $skillTarget = "caller-target"
    $ErrorActionPreference = "Continue"
    # Invoke-Expression uses this scope. An extra & wrapper here would hide the old leak.
    Invoke-Expression $decisionCode
    Assert-CallerState
    $ErrorActionPreference = "Stop"
    if ((Get-InstallManifest $decisionSource) -cne (Get-InstallManifest $decisionDestination)) {
        throw "Installed files differ from the source or are nested incorrectly."
    }
    Write-Output "PASS: fresh install contents and caller scope"

    Set-Content -LiteralPath (Join-Path $decisionDestination "SKILL.md") -Value "user-edited skill" -Encoding UTF8
    Set-Content -LiteralPath (Join-Path $decisionDestination "keep.txt") -Value "user file" -Encoding UTF8
    $decisionBefore = Get-InstallManifest $decisionDestination
    $decisionFailure = $null
    $ErrorActionPreference = "Continue"
    try { Invoke-Expression $decisionCode } catch { $decisionFailure = $_ }
    Assert-CallerState
    $ErrorActionPreference = "Stop"
    if ($null -eq $decisionFailure -or $decisionFailure.Exception.Message -notlike "Already exists:*") {
        throw "An existing installation was not refused as expected."
    }
    if ($decisionBefore -cne (Get-InstallManifest $decisionDestination)) {
        throw "The refused installation changed existing files."
    }
    Write-Output "PASS: existing installation refusal, contents, and caller scope"

    $decisionEmptyDirectory = Join-Path $decisionTemporaryRoot "empty-source"
    New-Item -ItemType Directory -Path $decisionEmptyDirectory | Out-Null
    Set-Location $decisionEmptyDirectory
    $decisionMissingDestination = Join-Path $decisionTemporaryRoot "must-not-exist/decision-interview"
    $decisionCode = Set-TestDestination $decisionExample $decisionMissingDestination
    $decisionFailure = $null
    $ErrorActionPreference = "Continue"
    try { Invoke-Expression $decisionCode } catch { $decisionFailure = $_ }
    Assert-CallerState
    $ErrorActionPreference = "Stop"
    if ($null -eq $decisionFailure -or $decisionFailure.Exception.Message -ne "Run this from the repository root.") {
        throw "Missing source was not refused as expected."
    }
    if (Test-Path -LiteralPath (Split-Path -Parent $decisionMissingDestination)) {
        throw "The missing-source attempt created a destination directory."
    }
    Write-Output "PASS: missing-source refusal, no destination, and caller scope"
}
finally {
    Pop-Location
    if (Test-Path -LiteralPath $decisionTemporaryRoot) {
        Remove-Item -LiteralPath $decisionTemporaryRoot -Recurse -Force -ErrorAction Stop
    }
    $ErrorActionPreference = $decisionSavedPreference
}
