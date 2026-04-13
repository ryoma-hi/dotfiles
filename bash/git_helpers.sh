# ====================
# Git helpers (minimal)
# ====================

# ---- 基本確認 ----
function gs {
    git status
}

function gl {
    git log --oneline --graph --all
}
# ---- 保存（最重要）----
gpush() {
  local msg="${1:-Update}"
  local branch
  branch="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || echo main)"

  git add -A || return 1

  if ! git diff --cached --quiet; then
    git commit -m "$msg" || return 1
  else
    echo "[INFO] No changes: skipping commit."
  fi

  git pull --rebase --autostash origin "$branch" 2>/dev/null || true

  git push -u origin "$branch" || return 1

  echo "[OK] Pushed to origin/$branch"
}

export -f gpush


# ---- GitHub接続 ----
gh_set_remote() {
  local repo="$1"

  if [[ -z "$repo" ]]; then
    echo "Usage: gh_set_remote <owner/repo>"
    return 2
  fi

  local url

  if [[ "$repo" =~ ^https://github.com/ ]]; then
    url="${repo%/}"
    [[ "$url" != *.git ]] && url="$url.git"
  else
    url="https://github.com/$repo.git"
  fi

  git remote get-url origin >/dev/null 2>&1 \
    && git remote set-url origin "$url" \
    || git remote add origin "$url" || return 1

  echo "[OK] Remote set to $url"
}

export -f gh_set_remote


# ---- GitHub作成＋push ----
gh_register() {
  local repo="$1"
  local vis="${2:-private}"

  if [[ -z "$repo" ]]; then
    echo "Usage: gh_register <owner/repo> [private|public]"
    return 2
  fi

  git rev-parse --git-dir >/dev/null 2>&1 || git init || return 1

  if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo "# ${repo##*/}" > README.md
    git add -A && git commit -m "initial commit" || return 1
  fi

  if command -v gh >/dev/null 2>&1; then
    gh repo create "$repo" --"$vis" --source . --remote origin --push || return 1
  else
    echo "[INFO] Create repo on GitHub first: https://github.com/new"
    gh_set_remote "$repo"
    gpush "initial commit"
  fi

  echo "[OK] Repository ready: $repo"
}

export -f gh_register


# ---- ブランチ ----
gh_branch() {
  local name="$1"
  local base="${2:-HEAD}"

  if [[ -z "$name" ]]; then
    echo "Usage: gh_branch <name> [base]"
    return 2
  fi

  [[ "$base" == "main" ]] && base="origin/main"

  git rev-parse --git-dir >/dev/null 2>&1 || {
    echo "[ERROR] Not a git repo"
    return 1
  }

  git fetch origin -q || true

  if git show-ref --verify --quiet "refs/heads/$name"; then
    git switch "$name"
  else
    git switch -c "$name" "$base"
  fi || return 1

  git push -u origin "$name" 2>/dev/null || true

  echo "[OK] Now on branch: $name"
}

export -f gh_branch