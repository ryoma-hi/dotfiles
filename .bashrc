# ===== dotfiles entrypoint =====

# 共通設定
[ -f "$HOME/dotfiles/bash/bashrc.shared" ] && source "$HOME/dotfiles/bash/bashrc.shared"

# ローカル専用の秘密情報
[ -f "$HOME/.config/research-secrets/env.sh" ] && source "$HOME/.config/research-secrets/env.sh"