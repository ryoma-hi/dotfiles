$env:UV_DEFAULT_PYVER = if ($env:UV_DEFAULT_PYVER) { $env:UV_DEFAULT_PYVER } else { "3.11" }

function Test-UvProject {
    Test-Path ".\pyproject.toml"
}

function Get-UvProjectName {
    Split-Path (Get-Location) -Leaf
}

function uvproj_init {
    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uvCmd) {
        Write-Host "[ERROR] uv not found. Please install uv first."
        return
    }

    if (-not (Test-UvProject)) {
        Write-Host "[INFO] No pyproject.toml found. Initializing this directory as a uv project."
        uv init --python $env:UV_DEFAULT_PYVER
        if ($LASTEXITCODE -ne 0) { return }
    }

    uv sync
    if ($LASTEXITCODE -ne 0) { return }

    $py = ".\.venv\Scripts\python.exe"
    if (-not (Test-Path $py)) {
        Write-Host "[ERROR] $py not found."
        return
    }

    & $py -c "import ipykernel" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[INFO] Installing ipykernel into .venv via uv..."
        uv pip install ipykernel
        if ($LASTEXITCODE -ne 0) { return }
    }

    $proj = Get-UvProjectName
    & $py -m ipykernel install --user --name $proj --display-name "Python ($proj)"
    if ($LASTEXITCODE -ne 0) { return }

    Write-Host "[OK] uvproj_init completed: .venv / kernel='$proj'"
}

function uvproj_use {
    $activate = ".\.venv\Scripts\Activate.ps1"
    if (-not (Test-Path $activate)) {
        Write-Host "[INFO] .venv not found. Run uvproj_init first."
        return
    }
    . $activate
    Write-Host "[OK] Activated uv project: $(Get-UvProjectName) (env=.venv)"
}