# setup/windows.ps1
$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host "[setup] $Message"
}

$targetProfile = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path -Path $targetProfile -Parent

$dotfilesRoot = Join-Path $HOME "dotfiles"
$dotfilesProfile = Join-Path $dotfilesRoot "powershell\profile.ps1"

$secretDir = Join-Path $HOME ".config\research-secrets"
$envTemplate = Join-Path $dotfilesRoot "templates\env.example.ps1"
$envLocal = Join-Path $secretDir "env.ps1"

$entry = '. "$HOME\dotfiles\powershell\profile.ps1"'

Write-Step "Preparing directories"
New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
New-Item -ItemType Directory -Force -Path $secretDir | Out-Null

if (-not (Test-Path -LiteralPath $dotfilesProfile)) {
    Write-Host "ERROR: dotfiles profile not found: $dotfilesProfile"
    Write-Host "Place dotfiles under $HOME\dotfiles first."
    exit 1
}

if (-not (Test-Path -LiteralPath $targetProfile)) {
    Write-Step "Creating PowerShell profile: $targetProfile"
    New-Item -ItemType File -Force -Path $targetProfile | Out-Null
}

Write-Step "Ensuring dotfiles entry exists in profile"
$hasEntry = $false

if (Test-Path -LiteralPath $targetProfile) {
    $hasEntry = Select-String -Path $targetProfile -SimpleMatch $entry -Quiet -ErrorAction SilentlyContinue
}

if (-not $hasEntry) {
    Add-Content -Path $targetProfile -Value ""
    Add-Content -Path $targetProfile -Value "# dotfiles"
    Add-Content -Path $targetProfile -Value $entry
    Write-Step "Added dotfiles entry to profile: $targetProfile"
}
else {
    Write-Step "dotfiles entry already exists in profile: $targetProfile"
}

if (-not (Test-Path -LiteralPath $envLocal)) {
    if (Test-Path -LiteralPath $envTemplate) {
        Copy-Item -Path $envTemplate -Destination $envLocal
        Write-Step "Created local env file: $envLocal"
    }
    else {
        Write-Host "WARNING: env template not found: $envTemplate"
        Write-Host "env.ps1 was not created."
    }
}
else {
    Write-Step "Local env file already exists: $envLocal"
}

Write-Step "Loading dotfiles profile into current session"
. $dotfilesProfile

Write-Host ""
Write-Host "Windows setup done."
Write-Host "Next steps:"
Write-Host "  1. Edit $envLocal if needed"
Write-Host "  2. Restart PowerShell or VS Code"
Write-Host "  3. Future sessions will load dotfiles automatically"