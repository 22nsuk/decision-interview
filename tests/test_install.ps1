# Run the real installer in disposable destinations; never change HOME.
$decisionSavedPreference = $ErrorActionPreference
$ErrorActionPreference = "Stop"
$decisionRepoRoot = Split-Path -Parent $PSScriptRoot
$decisionInstaller = Join-Path $decisionRepoRoot "scripts/install.ps1"
$decisionUtf8 = New-Object System.Text.UTF8Encoding($false)
# Keep this script ASCII so Windows PowerShell 5.1 can load it without a BOM.
$decisionKorean = [string] [char] 0xD55C + [char] 0xAE00
$decisionTemporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) (
    "decision-install " + $decisionKorean + " [test] " + [guid]::NewGuid()
)
$decisionLinks = @()
$decisionLinkReferent = $null

function Get-InstallManifest([string] $Directory) {
    return (Get-ChildItem -LiteralPath $Directory -Recurse -Force |
        Sort-Object FullName | ForEach-Object {
            $relative = $_.FullName.Substring($Directory.Length + 1)
            if ($_.PSIsContainer) { "D:$relative" }
            else { "F:$relative" + ':' + (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash }
        }) -join "`n"
}

function Invoke-TestInstall([string] $Installer, [string] $Target, [switch] $ExpectFailure) {
    $ErrorActionPreference = "Continue"
    $installSource = "caller-source"
    $installTarget = "caller-target"
    $beforeLocation = (Get-Location).Path
    $failure = $null
    try { & $Installer -Destination $Target | Out-Null } catch { $failure = $_ }
    if ($ErrorActionPreference -ne "Continue" -or $installSource -ne "caller-source" -or
        $installTarget -ne "caller-target" -or (Get-Location).Path -ne $beforeLocation) {
        throw "The installer changed caller settings, variables, or location."
    }
    if ($ExpectFailure -and $null -eq $failure) { throw "Installation unexpectedly succeeded: $Target" }
    if (-not $ExpectFailure -and $null -ne $failure) { throw $failure }
    return $failure
}

function Invoke-CopyFault([string] $Installer, [string] $Target, [string] $Mode) {
    # Substitute only copying; the installer still performs real staging, checks,
    # publication, and cleanup. No test hooks are added to the public installer.
    function Copy-Item {
        [CmdletBinding()]
        param([string] $LiteralPath, [string] $Destination, [switch] $Recurse, [switch] $Force)
        if ($Mode -eq "copy-error") {
            [System.IO.File]::WriteAllText((Join-Path $Destination "partial.txt"), "partial", $decisionUtf8)
            throw "Injected copy failure."
        }
        if ($Mode -eq "omit-files") { return }
        Microsoft.PowerShell.Management\Copy-Item @PSBoundParameters
        if ($Mode -eq "corrupt-required" -and (Split-Path -Leaf $LiteralPath) -eq "SKILL.md") {
            [System.IO.File]::WriteAllText((Join-Path $Destination "SKILL.md"), "truncated", $decisionUtf8)
        }
        if ($Mode -eq "destination-race") {
            # An empty competing destination must also be preserved by the real move.
            [void] [System.IO.Directory]::CreateDirectory($Target)
        }
    }
    return Invoke-TestInstall $Installer $Target -ExpectFailure
}

Push-Location $decisionRepoRoot
try {
    [void] [System.IO.Directory]::CreateDirectory($decisionTemporaryRoot)
    $decisionCallerDirectory = Join-Path $decisionTemporaryRoot "caller"
    [void] [System.IO.Directory]::CreateDirectory($decisionCallerDirectory)
    Set-Location -LiteralPath $decisionCallerDirectory

    # Directly invoke the repository file from an unrelated working directory.
    $decisionActualDestination = Join-Path $decisionCallerDirectory "actual [install]"
    Invoke-TestInstall $decisionInstaller "actual [install]/"
    $decisionSource = Join-Path $decisionRepoRoot "skills/decision-interview"
    if ((Get-InstallManifest $decisionSource) -cne (Get-InstallManifest $decisionActualDestination)) {
        throw "The installed repository package differs from its source."
    }
    Write-Output "PASS: real installer, relative destination, foreign cwd, and caller scope"

    # Use an exact installer copy to test package shapes and damaged distributions.
    $decisionPackage = Join-Path $decisionTemporaryRoot "package"
    $decisionPackageScripts = Join-Path $decisionPackage "scripts"
    [void] [System.IO.Directory]::CreateDirectory($decisionPackageScripts)
    Copy-Item -LiteralPath $decisionInstaller -Destination $decisionPackageScripts
    $decisionFixtureInstaller = Join-Path $decisionPackageScripts "install.ps1"
    $decisionFixture = Join-Path $decisionPackage "skills/decision-interview"
    [void] [System.IO.Directory]::CreateDirectory($decisionFixture)
    Get-ChildItem -LiteralPath $decisionSource -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $decisionFixture -Recurse -Force
    }
    $decisionNested = Join-Path $decisionFixture ".hidden/nested [files]"
    [void] [System.IO.Directory]::CreateDirectory($decisionNested)
    [void] [System.IO.Directory]::CreateDirectory((Join-Path $decisionFixture "empty"))
    $decisionHidden = Join-Path $decisionNested ($decisionKorean + ".txt")
    [System.IO.File]::WriteAllText($decisionHidden, "nested fixture", $decisionUtf8)
    [System.IO.File]::SetAttributes((Join-Path $decisionFixture ".hidden"), [System.IO.FileAttributes]::Hidden)
    [System.IO.File]::SetAttributes($decisionHidden, [System.IO.FileAttributes]::Hidden)
    $decisionFixtureDestination = Join-Path $decisionTemporaryRoot "nested [install]"
    Invoke-TestInstall $decisionFixtureInstaller $decisionFixtureDestination
    if ((Get-InstallManifest $decisionFixture) -cne (Get-InstallManifest $decisionFixtureDestination)) {
        throw "Nested, hidden, empty, or literal-path content was not preserved."
    }
    Write-Output "PASS: exact nested, hidden, empty, and non-ASCII package contents"

    [System.IO.File]::WriteAllText((Join-Path $decisionFixtureDestination "SKILL.md"), "user-edited", $decisionUtf8)
    [System.IO.File]::WriteAllText((Join-Path $decisionFixtureDestination "keep.txt"), "user file", $decisionUtf8)
    $decisionBefore = Get-InstallManifest $decisionFixtureDestination
    $null = Invoke-TestInstall $decisionFixtureInstaller $decisionFixtureDestination -ExpectFailure
    if ($decisionBefore -cne (Get-InstallManifest $decisionFixtureDestination)) {
        throw "Refusal changed an existing installation."
    }
    $decisionExistingFile = Join-Path $decisionTemporaryRoot "existing-file"
    [System.IO.File]::WriteAllText($decisionExistingFile, "preserve me", $decisionUtf8)
    $null = Invoke-TestInstall $decisionFixtureInstaller $decisionExistingFile -ExpectFailure
    if ([System.IO.File]::ReadAllText($decisionExistingFile, $decisionUtf8) -cne "preserve me") {
        throw "Refusal changed an existing file."
    }
    Write-Output "PASS: existing directory and file refusal without modification"

    foreach ($relativePath in @("SKILL.md", "agents/openai.yaml")) {
        $decisionRequiredPath = Join-Path $decisionFixture $relativePath
        $decisionRequiredBytes = [System.IO.File]::ReadAllBytes($decisionRequiredPath)
        [System.IO.File]::Delete($decisionRequiredPath)
        try {
            $decisionMissingDestination = Join-Path $decisionTemporaryRoot "missing-source-parent/skill"
            $null = Invoke-TestInstall $decisionFixtureInstaller $decisionMissingDestination -ExpectFailure
            if (Test-Path -LiteralPath (Split-Path -Parent $decisionMissingDestination)) {
                throw "Missing required source created a destination parent."
            }
        }
        finally { [System.IO.File]::WriteAllBytes($decisionRequiredPath, $decisionRequiredBytes) }
    }
    Write-Output "PASS: both required source files checked before destination changes"

    foreach ($decisionMode in @("copy-error", "omit-files", "corrupt-required", "destination-race")) {
        $decisionFaultParent = Join-Path $decisionTemporaryRoot $decisionMode
        [void] [System.IO.Directory]::CreateDirectory($decisionFaultParent)
        $decisionFaultTarget = Join-Path $decisionFaultParent "decision-interview"
        $decisionFailure = Invoke-CopyFault $decisionFixtureInstaller $decisionFaultTarget $decisionMode
        if ($decisionMode -eq "copy-error" -and $decisionFailure.Exception.Message -ne "Injected copy failure.") {
            throw "The injected copy error was not observed."
        }
        if ($decisionMode -eq "destination-race") {
            $decisionEntries = @(Get-ChildItem -LiteralPath $decisionFaultParent -Force)
            if ($decisionEntries.Count -ne 1 -or $decisionEntries[0].Name -ne "decision-interview" -or
                -not [System.IO.Directory]::Exists($decisionFaultTarget) -or
                @(Get-ChildItem -LiteralPath $decisionFaultTarget -Force).Count -ne 0) {
                throw "The race changed the competing directory or left staging content."
            }
        }
        else {
            if (@(Get-ChildItem -LiteralPath $decisionFaultParent -Force).Count -ne 0) {
                throw "A failed copy left a destination or staging directory."
            }
            Invoke-TestInstall $decisionFixtureInstaller $decisionFaultTarget
            if ((Get-InstallManifest $decisionFixture) -cne (Get-InstallManifest $decisionFaultTarget)) {
                throw "Retry after copy failure did not install the complete package."
            }
        }
    }
    Write-Output "PASS: injected copy error, omitted/corrupt output, cleanup, retry, and destination race"

    # Old New-Item versions treat brackets in -Value as wildcards. Keep this
    # fixture's referent plain; installer paths with literal brackets are tested above.
    $decisionLinkReferent = Join-Path ([System.IO.Path]::GetTempPath()) ("decision-link-" + [guid]::NewGuid())
    [void] [System.IO.Directory]::CreateDirectory($decisionLinkReferent)
    [System.IO.File]::WriteAllText((Join-Path $decisionLinkReferent "keep.txt"), "referent", $decisionUtf8)
    foreach ($decisionLinkKind in @("live", "dangling")) {
        $decisionLink = Join-Path $decisionTemporaryRoot ($decisionLinkKind + "-link")
        New-Item -ItemType SymbolicLink -Path $decisionLink -Value $decisionLinkReferent -ErrorAction Stop | Out-Null
        $decisionLinks += $decisionLink
        if ($decisionLinkKind -eq "dangling") {
            Remove-Item -LiteralPath $decisionLinkReferent -Recurse -Force
        }
        $null = Invoke-TestInstall $decisionFixtureInstaller $decisionLink -ExpectFailure
        if (([System.IO.File]::GetAttributes($decisionLink) -band [System.IO.FileAttributes]::ReparsePoint) -eq 0) {
            throw "Refusal removed or replaced a symbolic link."
        }
        if ($decisionLinkKind -eq "live" -and
            [System.IO.File]::ReadAllText((Join-Path $decisionLinkReferent "keep.txt"), $decisionUtf8) -cne "referent") {
            throw "Refusal changed a link's referent."
        }
    }
    Write-Output "PASS: live and dangling symbolic-link refusal"
}
finally {
    Pop-Location
    foreach ($decisionLink in $decisionLinks) {
        # Delete only the directory link, never recursively traverse its referent.
        [System.IO.Directory]::Delete($decisionLink)
    }
    if ($decisionLinkReferent -and [System.IO.Directory]::Exists($decisionLinkReferent)) {
        Remove-Item -LiteralPath $decisionLinkReferent -Recurse -Force -ErrorAction Stop
    }
    if (Test-Path -LiteralPath $decisionTemporaryRoot) {
        Remove-Item -LiteralPath $decisionTemporaryRoot -Recurse -Force -ErrorAction Stop
    }
    $ErrorActionPreference = $decisionSavedPreference
}
