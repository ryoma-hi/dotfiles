# ===== dotfiles PowerShell entrypoint =====

# helper scripts
. "$HOME\dotfiles\powershell\git_helpers.ps1"
. "$HOME\dotfiles\powershell\uv_helpers.ps1"

# local secrets
if (Test-Path "$HOME\.config\research-secrets\env.ps1") {
    . "$HOME\.config\research-secrets\env.ps1"
}

# prompt: show venv/project name simply
function global:prompt {
    $venvLabel = ""
    if ($env:VIRTUAL_ENV) {
        $base = Split-Path $env:VIRTUAL_ENV -Leaf
        if ($base -eq ".venv") {
            $venvLabel = Split-Path (Split-Path $env:VIRTUAL_ENV -Parent) -Leaf
        } else {
            $venvLabel = $base
        }
    }

    if ($venvLabel -ne "") {
        "[$venvLabel] PS $($executionContext.SessionState.Path.CurrentLocation)> "
    } else {
        "PS $($executionContext.SessionState.Path.CurrentLocation)> "
    }
}