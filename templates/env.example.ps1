# ===== research env template (Windows PowerShell) =====
# このファイルを $HOME\.config\research-secrets\env.ps1 にコピーして使う

# --------------------
# common
# --------------------
Remove-Item Env:GIT_ASKPASS -ErrorAction SilentlyContinue
$env:GIT_TERMINAL_PROMPT = "1"

$env:HF_HOME = "$HOME\.cache\huggingface"
$env:HF_TOKEN_PATH = "$HOME\.cache\huggingface\token"
$env:HUGGING_FACE_HUB_TOKEN = "$env:HF_HOME\token"

if (-not ($env:Path -split ';' | Where-Object { $_ -eq "$HOME\.local\bin" })) {
    $env:Path = "$HOME\.local\bin;$env:Path"
}

$env:VIRTUAL_ENV_DISABLE_PROMPT = "1"

# --------------------
# optional paths
# --------------------
$fontPath = "$HOME\fonts\NotoSansCJKjp-Regular.otf"
if (Test-Path $fontPath) {
    $env:LOGITLENS_JP_FONT = $fontPath
}

# --------------------
# secrets (set locally)
# --------------------
# $env:HUGGINGFACE_TOKEN = "your_token_here"