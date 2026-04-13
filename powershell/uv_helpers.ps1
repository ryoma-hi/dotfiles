# ====================
# uv-based project environment management
# ====================

$env:UV_DEFAULT_PYVER = if ($env:UV_DEFAULT_PYVER) { $env:UV_DEFAULT_PYVER } else { "3.11" }

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

    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uvCmd) {
        Write-Host "[ERROR] uv not found. Please install uv first."
        return
    }

    $pyver = $null
    if ($PythonVersion) {
        $pyver = $PythonVersion
        Write-Host "[INFO] Using Python version from argument: $pyver"
    } elseif ($env:UV_DEFAULT_PYVER) {
        $pyver = $env:UV_DEFAULT_PYVER
        Write-Host "[INFO] Using default Python version: $pyver"
    }

    if (-not (Test-UvProject)) {
        Write-Host "[INFO] No pyproject.toml found. Initializing this directory as a uv project."

        if ($pyver) {
            Write-Host "[INFO] Running: uv init --python $pyver"
            uv init --python $pyver
        } else {
            Write-Host "[INFO] Running: uv init"
            uv init
        }

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] uv init failed."
            return
        }
    }

    $proj = Get-UvProjectName
    $envDir = ".\.venv"

    Write-Host "[INFO] Running uv sync: project=$proj env=$envDir"
    if ($pyver) {
        $env:UV_PYTHON = $pyver
        uv sync
        $syncExit = $LASTEXITCODE
        Remove-Item Env:UV_PYTHON -ErrorAction SilentlyContinue
        if ($syncExit -ne 0) { return }
    } else {
        uv sync
        if ($LASTEXITCODE -ne 0) { return }
    }

    $py = ".\.venv\Scripts\python.exe"
    if (-not (Test-Path $py)) {
        Write-Host "[ERROR] $py not found. .venv may not have been created correctly."
        return
    }

    & $py -c "import ipykernel" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[INFO] Installing ipykernel into .venv via uv..."
        uv pip install --python $py ipykernel
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to install ipykernel."
            return
        }
    }

    & $py -m ipykernel install --user --name $proj --display-name "Python ($proj)"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to register ipykernel."
        return
    }

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