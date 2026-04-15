# ====================
# uv-based project environment management
# ====================

$env:UV_DEFAULT_PYVER = if ($env:UV_DEFAULT_PYVER) { $env:UV_DEFAULT_PYVER } else { "3.11" }

function Get-UvExecutable {
    if ($env:UV_EXE -and (Test-Path $env:UV_EXE)) {
        return $env:UV_EXE
    }

    $candidates = @(
        "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe",
        "$HOME\.local\bin\uv.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if ($uvCmd -and $uvCmd.CommandType -eq "Application" -and (Test-Path $uvCmd.Source)) {
        return $uvCmd.Source
    }

    return $null
}

function Invoke-Uv {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    $uvExe = Get-UvExecutable
    if (-not $uvExe) {
        Write-Host "[ERROR] usable uv.exe not found. Install winget package: astral-sh.uv"
        return 127
    }

    & $uvExe @Args
    return $LASTEXITCODE
}

function Test-UvProject {
    Test-Path ".\pyproject.toml"
}

function Get-UvProjectName {
    Split-Path (Get-Location) -Leaf
}

function uvproj_init {
    param(
        [string]$PythonVersion
    )

    $uvExe = Get-UvExecutable
    if (-not $uvExe) {
        Write-Host "[ERROR] usable uv.exe not found. Please install winget package: astral-sh.uv"
        return
    }

    Write-Host "[INFO] Using uv executable: $uvExe"

    $pyver = $null
    if ($PythonVersion) {
        $pyver = $PythonVersion
        Write-Host "[INFO] Using Python version from argument: $pyver"
    } elseif ($env:UV_DEFAULT_PYVER) {
        $pyver = $env:UV_DEFAULT_PYVER
        Write-Host "[INFO] Using default Python version: $pyver"
    }

    $oldUvDownloads = $env:UV_PYTHON_DOWNLOADS
    $oldUvPreference = $env:UV_PYTHON_PREFERENCE
    $env:UV_PYTHON_DOWNLOADS = "never"
    $env:UV_PYTHON_PREFERENCE = "only-system"

    if (-not (Test-UvProject)) {
        Write-Host "[INFO] No pyproject.toml found. Initializing this directory as a uv project."

        if ($pyver) {
            Write-Host "[INFO] Running: uv init --python $pyver"
            $exit = Invoke-Uv init --python $pyver
        } else {
            Write-Host "[INFO] Running: uv init"
            $exit = Invoke-Uv init
        }

        if ($exit -ne 0) {
            Write-Host "[ERROR] uv init failed."
            $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
            $env:UV_PYTHON_PREFERENCE = $oldUvPreference
            return
        }
    }

    $proj = Get-UvProjectName
    $envDir = ".\.venv"

    Write-Host "[INFO] Running uv sync: project=$proj env=$envDir"
    if ($pyver) {
        $env:UV_PYTHON = $pyver
        $syncExit = Invoke-Uv sync
        Remove-Item Env:UV_PYTHON -ErrorAction SilentlyContinue
        if ($syncExit -ne 0) {
            $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
            $env:UV_PYTHON_PREFERENCE = $oldUvPreference
            return
        }
    } else {
        $syncExit = Invoke-Uv sync
        if ($syncExit -ne 0) {
            $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
            $env:UV_PYTHON_PREFERENCE = $oldUvPreference
            return
        }
    }

    $py = ".\.venv\Scripts\python.exe"
    if (-not (Test-Path $py)) {
        Write-Host "[ERROR] $py not found. .venv may not have been created correctly."
        return
    }

    $hasIpykernel = $true
    $oldProbeErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        & $py -c "import ipykernel" 2>$null
        $hasIpykernel = ($LASTEXITCODE -eq 0)
    } finally {
        $ErrorActionPreference = $oldProbeErrorAction
    }

    if (-not $hasIpykernel) {
        Write-Host "[INFO] Installing ipykernel into .venv via uv..."
        $pipExit = Invoke-Uv pip install --python $py ipykernel
        if ($pipExit -ne 0) {
            Write-Host "[ERROR] Failed to install ipykernel."
            $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
            $env:UV_PYTHON_PREFERENCE = $oldUvPreference
            return
        }
    }

    & $py -m ipykernel install --user --name $proj --display-name "Python ($proj)"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to register ipykernel."
        $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
        $env:UV_PYTHON_PREFERENCE = $oldUvPreference
        return
    }

    $env:UV_PYTHON_DOWNLOADS = $oldUvDownloads
    $env:UV_PYTHON_PREFERENCE = $oldUvPreference

    Write-Host "[OK] uvproj_init completed: .venv / kernel='$proj'"
    Write-Host "[INFO] To activate it, run: sour"
}

function uvproj_use {
    if (-not (Test-UvProject)) {
        Write-Host "[ERROR] pyproject.toml not found. This directory does not look like a uv project."
        return
    }

    $activate = ".\.venv\Scripts\Activate.ps1"
    if (-not (Test-Path $activate)) {
        Write-Host "[INFO] .venv not found. Run uvproj_init first."
        return
    }

    . $activate
    Write-Host "[OK] Activated uv project: $(Get-UvProjectName) (env=.venv)"
}

function sour {
    $activate = ".\.venv\Scripts\Activate.ps1"
    if (-not (Test-Path $activate)) {
        Write-Host "[INFO] .venv not found. Run uvproj_init first."
        return
    }

    . $activate
    Write-Host "[OK] Activated: .venv (project: $(Get-UvProjectName))"
}

function rsta {
    if ($env:VIRTUAL_ENV -and (Get-Command deactivate -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] Deactivating: $(Split-Path $env:VIRTUAL_ENV -Leaf)"
        deactivate
    }

    Write-Host "[INFO] Reloading PowerShell profile..."
    . $PROFILE.CurrentUserAllHosts
    Write-Host "[OK] PowerShell profile reloaded."
}