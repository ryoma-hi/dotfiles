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

# Normalize token env var names used by different tools/scripts.
function global:Resolve-HuggingFaceToken {
    if ($env:HF_TOKEN) {
        return $env:HF_TOKEN.Trim()
    }

    if ($env:HUGGINGFACE_TOKEN) {
        return $env:HUGGINGFACE_TOKEN.Trim()
    }

    if ($env:HUGGINGFACEHUB_API_TOKEN) {
        return $env:HUGGINGFACEHUB_API_TOKEN.Trim()
    }

    if ($env:HUGGING_FACE_HUB_TOKEN -and (Test-Path $env:HUGGING_FACE_HUB_TOKEN)) {
        $tokenFromFile = Get-Content -Path $env:HUGGING_FACE_HUB_TOKEN -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($tokenFromFile) {
            return $tokenFromFile.Trim()
        }
    }

    return $null
}

$resolvedToken = Resolve-HuggingFaceToken
if ($resolvedToken) {
    $env:HF_TOKEN = $resolvedToken
    $env:HUGGINGFACE_TOKEN = $resolvedToken
    $env:HUGGINGFACEHUB_API_TOKEN = $resolvedToken
    $env:HUGGING_FACE_HUB_TOKEN = $resolvedToken
}

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
# Choose one of the following and keep it as the single source of truth.
# $env:HF_TOKEN = "hf_xxx..."