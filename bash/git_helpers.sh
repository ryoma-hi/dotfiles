# ====================
# Git 関連ヘルパー
# ====================

# add / commit / pull-rebase / push
gpush() {
  local msg="${1:-Backup}"
  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"

  git add -A &&
  (git diff --cached --quiet || git commit -m "$msg") &&
  git pull --rebase --autostash origin "$branch" &&
  git push origin "$branch"
}
export -f gpush

# ==== GitHub への登録（remote作成）＋初回push ====
# 使い方:
#   gh_register <owner/repo> [private|public] [description...]
gh_register() {
  local repo="$1"
  local vis="${2:-private}"
  shift 2 || true
  local desc="${*:-}"

  if [[ -z "$repo" ]]; then
    echo "Usage: gh_register <owner/repo> [private|public] [description...]"
    return 2
  fi

  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    git init || return 1
  fi

  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"
  git symbolic-ref HEAD "refs/heads/$branch" 2>/dev/null || true

  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    [[ -f README.md ]] || echo "# ${repo##*/}" > README.md
    git add -A && git commit -m "chore: initial commit" || return 1
  fi

  if command -v gh >/dev/null 2>&1; then
    gh repo create "$repo" --"$vis" --source . --remote origin \
      ${desc:+--description "$desc"} --push || return 1
    git remote set-url origin "git@github.com:$repo.git"
  else
    echo "ℹ️ gh CLI が無いので、GitHubで先に https://github.com/$repo を作成してください。"
    local url="git@github.com:$repo.git"
    git remote remove origin 2>/dev/null || true
    git remote add origin "$url" || return 1
    git push -u origin "$branch" || return 1
  fi

  echo "✅ 登録完了: origin=git@github.com:$repo.git / branch=$branch"
}
export -f gh_register

# ==== 既存ローカルを別リモートへ付け替え（接続変更）＋push ====
# 使い方:
#   gh_set_remote <owner/repo> [ssh|https]
gh_set_remote() {
  local repo="$1"
  local proto="${2:-ssh}"

  if [[ -z "$repo" ]]; then
    echo "Usage: gh_set_remote <owner/repo> [ssh|https]"
    return 2
  fi

  local url
  if [[ "$proto" == "https" ]]; then
    url="https://github.com/$repo.git"
  else
    url="git@github.com:$repo.git"
  fi

  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$url" || return 1
  else
    git remote add origin "$url" || return 1
  fi

  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"

  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "ℹ️ まだコミットがありません。初回コミット後に 'git push -u origin $branch' を実行してください。"
    echo "✅ remote を $url に設定しました。"
    return 0
  fi

  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push origin "$branch" || return 1
  else
    git push -u origin "$branch" || return 1
  fi

  echo "✅ remote を $url に設定し、$branch を push しました。"
}
export -f gh_set_remote

# ==== 変更をまとめてpush（安全版）====
# 使い方:
#   gp "commit message"
gp() {
  local msg="${1:-Backup}"
  git add -A || return 1

  if ! git diff --cached --quiet; then
    git commit -m "$msg" || return 1
  else
    echo "ℹ️ 変更なし: commit をスキップします。"
  fi

  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"

  git pull --rebase --autostash origin "$branch" 2>/dev/null || true

  if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push origin "$branch" || return 1
  else
    git push -u origin "$branch" || return 1
  fi

  echo "🚀 pushed to origin/$branch"
}
export -f gp

# ==== ブランチ作成/切替 + upstream設定 + 初回push ====
# 使い方:
#   gh_branch <name> [base]
gh_branch() {
  local name="$1"
  local base="${2:-HEAD}"

  if [[ -z "$name" ]]; then
    echo "Usage: gh_branch <name> [base] (base default: HEAD / 'main' は origin/main 扱い)"
    return 2
  fi

  [[ "$base" == "main" ]] && base="origin/main"

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "❌ here is not a git repo"
    return 1
  }

  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "❌ origin が未設定です。先に 'git remote add origin <url>' を実行してください。"
    return 1
  fi

  git fetch -p -q origin || true

  if git show-ref --verify --quiet "refs/heads/$name"; then
    git switch "$name" || return 1
  elif git ls-remote --exit-code --heads origin "$name" >/dev/null 2>&1; then
    git switch -c "$name" --track "origin/$name" || return 1
  else
    git switch -c "$name" "$base" || return 1
  fi

  if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
    git push -u origin "$name" || return 1
  fi

  echo "✅ now on branch: $(git branch --show-current) → upstream: origin/$name"
  echo "   以後このクローンでは 'gp' or 'git push' で origin/$name に保存されます。"
}
export -f gh_branch