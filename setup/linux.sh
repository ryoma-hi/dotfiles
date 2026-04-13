#!/usr/bin/env bash
set -e

mkdir -p "$HOME/.config/research-secrets"

if [[ ! -f "$HOME/.bashrc" ]]; then
  touch "$HOME/.bashrc"
fi

if ! grep -q 'source "$HOME/dotfiles/.bashrc"' "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ''
    echo '# dotfiles'
    echo '[ -f "$HOME/dotfiles/.bashrc" ] && source "$HOME/dotfiles/.bashrc"'
  } >> "$HOME/.bashrc"
fi

if [[ ! -f "$HOME/.bash_profile" ]]; then
  touch "$HOME/.bash_profile"
fi

if ! grep -q 'source "$HOME/.bashrc"' "$HOME/.bash_profile" 2>/dev/null; then
  {
    echo ''
    echo '# load interactive bash settings'
    echo '[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"'
  } >> "$HOME/.bash_profile"
fi

if [[ ! -f "$HOME/.config/research-secrets/env.sh" ]]; then
  cp "$HOME/dotfiles/templates/env.example.sh" "$HOME/.config/research-secrets/env.sh"
  echo "✅ Created: $HOME/.config/research-secrets/env.sh"
fi

echo "✅ Linux setup done"
echo "必要なら ~/.config/research-secrets/env.sh に token を追加してください。"
