# ===== research env template (Linux) =====
# このファイルを ~/.config/research-secrets/env.sh にコピーして使う

# --------------------
# common
# --------------------
export HOMEBREW_ARCH="sandybridge"

unset GIT_ASKPASS
export GIT_TERMINAL_PROMPT=1

export HF_HOME="${HOME}/.cache/huggingface"
export HF_TOKEN_PATH="${HOME}/.cache/huggingface/token"
export HUGGING_FACE_HUB_TOKEN="${HF_HOME}/token"

# shared cache on university machines
export HUGGINGFACE_HUB_CACHE="/cl/home2/share/huggingface/hub"
export HUGGINGFACE_ASSETS_CACHE="/cl/home2/share/huggingface/assets"

export PATH="${HOME}/.local/bin:${PATH}"
export VIRTUAL_ENV_DISABLE_PROMPT=1

# --------------------
# optional paths
# --------------------
# Linuxbrew がある場合だけ有効化
if [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
  eval "$($HOME/.linuxbrew/bin/brew shellenv)"
  export LD_LIBRARY_PATH="$HOME/.linuxbrew/lib:${LD_LIBRARY_PATH}"
fi

# フォントがある場合だけ設定
if [[ -f "$HOME/.fonts/NotoSansCJKjp-Regular.otf" ]]; then
  export LOGITLENS_JP_FONT="$HOME/.fonts/NotoSansCJKjp-Regular.otf"
fi

# --------------------
# secrets (set locally)
# --------------------
# export HUGGINGFACE_TOKEN="your_token_here"