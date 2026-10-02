param(
    [string]$Repository = "https://github.com/jonhys947/mars-agent-skills.git",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$work = Join-Path $env:TEMP "mars-agent-skills-sync-$stamp"

Write-Host "Cloning $Repository ..."
git clone --branch $Branch $Repository $work
if ($LASTEXITCODE -ne 0) { throw "git clone failed" }

# Keep the sync self-contained. If this Windows Git installation has no
# author identity configured, reuse the author identity already present in
# the repository history instead of requiring a global Git configuration.
$gitName = git -C $work config --get user.name 2>$null
$gitEmail = git -C $work config --get user.email 2>$null

if ([string]::IsNullOrWhiteSpace($gitName)) {
    $gitName = git -C $work log -1 --format=%an
    if ([string]::IsNullOrWhiteSpace($gitName)) {
        throw "Unable to determine Git author name from local config or repository history."
    }
    git -C $work config user.name $gitName
}

if ([string]::IsNullOrWhiteSpace($gitEmail)) {
    $gitEmail = git -C $work log -1 --format=%ae
    if ([string]::IsNullOrWhiteSpace($gitEmail)) {
        throw "Unable to determine Git author email from local config or repository history."
    }
    git -C $work config user.email $gitEmail
}

$dest = Join-Path $work "skills"
if (Test-Path $dest) {
    Remove-Item $dest -Recurse -Force
}
New-Item -ItemType Directory -Force $dest | Out-Null

function Copy-SkillRoot {
    param(
        [Parameter(Mandatory=$true)][string]$SourceRoot,
        [string[]]$Exclude = @()
    )

    if (-not (Test-Path $SourceRoot)) {
        Write-Warning "Source root not found: $SourceRoot"
        return
    }

    Get-ChildItem $SourceRoot -Directory | ForEach-Object {
        if ($Exclude -contains $_.Name) { return }

        $skillFileUpper = Join-Path $_.FullName "SKILL.md"
        $skillFileLower = Join-Path $_.FullName "skill.md"
        if (-not (Test-Path $skillFileUpper) -and -not (Test-Path $skillFileLower)) {
            Write-Warning "Skipping $($_.Name): no SKILL.md"
            return
        }

        $target = Join-Path $dest $_.Name
        if (Test-Path $target) {
            Write-Host "Replacing duplicate: $($_.Name)"
            Remove-Item $target -Recurse -Force
        }
        Copy-Item $_.FullName $target -Recurse -Force

        $lower = Join-Path $target "skill.md"
        $upper = Join-Path $target "SKILL.md"
        if ((Test-Path $lower) -and -not (Test-Path $upper)) {
            Rename-Item $lower "SKILL.md"
        }

        Write-Host "Copied: $($_.Name)"
    }
}

# Generic/global Agent Skills installed via npx skills.
Copy-SkillRoot -SourceRoot (Join-Path $HOME ".agents\skills") -Exclude @(".vibeskills")

# Codex-specific user skills. Built-in .system skills are intentionally excluded.
Copy-SkillRoot -SourceRoot (Join-Path $HOME ".codex\skills") -Exclude @(".system")

# Validate every mirrored directory.
$invalid = @()
Get-ChildItem $dest -Directory | ForEach-Object {
    $skill = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path $skill)) {
        $invalid += $_.Name
    }
}
if ($invalid.Count -gt 0) {
    throw "Invalid mirrored skills (missing SKILL.md): $($invalid -join ', ')"
}

# Refresh a deterministic catalog file.
$names = Get-ChildItem $dest -Directory | Select-Object -ExpandProperty Name | Sort-Object
Set-Content -Path (Join-Path $work "SKILLS.txt") -Value $names -Encoding utf8

Push-Location $work
try {
    git add skills SKILLS.txt
    $pending = git status --porcelain
    if (-not $pending) {
        Write-Host "No skill changes to publish."
        exit 0
    }

    git commit -m "chore: sync locally installed agent skills"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed" }

    git push origin $Branch
    if ($LASTEXITCODE -ne 0) { throw "git push failed" }

    Write-Host "Published $($names.Count) skills to $Repository ($Branch)."
}
finally {
    Pop-Location
}
