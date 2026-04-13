# ====================
# uv ベースのプロジェクト環境管理
# ====================

# 既定の Python バージョン（uv が使う）
export UV_DEFAULT_PYVER="${UV_DEFAULT_PYVER:-3.11}"

# カレントディレクトリが uv プロジェクトか？
_uv_is_uv_project() {
  [[ -f "pyproject.toml" ]]
}

# プロジェクト名 = カレントディレクトリ名
_uv_project_name() {
  basename "$PWD"
}

# プロジェクト用 .venv を作って依存を同期し、Jupyter カーネルを登録
uvproj_init() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "❌ uv が見つかりません。先に uv をインストールしてください。"
    return 1
  fi

  # pyproject.toml がなければ uv project として初期化
  if ! _uv_is_uv_project; then
    echo "ℹ️ pyproject.toml が無いので、このディレクトリを uv プロジェクトとして初期化します。"

    if [[ -n "$UV_DEFAULT_PYVER" ]]; then
      echo "   → uv init --python ${UV_DEFAULT_PYVER}"
      uv init --python "$UV_DEFAULT_PYVER" || {
        echo "❌ uv init に失敗しました。"
        return 1
      }
    else
      echo "   → uv init"
      uv init || {
        echo "❌ uv init に失敗しました。"
        return 1
      }
    fi
  fi

  local proj envdir py
  proj="$(_uv_project_name)"
  envdir=".venv"

  echo "📦 uv sync: project=${proj} env=${envdir}"
  if [[ -n "$UV_DEFAULT_PYVER" ]]; then
    UV_PYTHON="$UV_DEFAULT_PYVER" uv sync || return 1
  else
    uv sync || return 1
  fi

  py="${envdir}/bin/python"
  if [[ ! -x "$py" ]]; then
    echo "❌ ${py} が見つかりません (.venv の作成に失敗していそうです)。"
    return 1
  fi

  # ipykernel が無ければ入れる
  if ! "$py" -c "import ipykernel" 2>/dev/null; then
    echo "📦 Installing ipykernel into .venv via uv..."
    uv pip install -p "$py" ipykernel || {
      echo "❌ ipykernel のインストールに失敗しました。"
      return 1
    }
  fi

  # Jupyter カーネル登録
  "$py" -m ipykernel install --user --name "${proj}" --display-name "Python (${proj})" || {
    echo "❌ ipykernel の登録に失敗しました。"
    return 1
  }

  echo "✅ uvproj_init 完了: .venv / kernel='${proj}'"
  echo "   → 有効化するには: sour または source .venv/bin/activate"
}
export -f uvproj_init

# プロジェクトの .venv を有効化（なければ uvproj_init を促す）
uvproj_use() {
  if ! _uv_is_uv_project; then
    echo "❌ pyproject.toml が見つかりません。このディレクトリは uv プロジェクトではなさそうです。"
    return 1
  fi

  if [[ ! -f ".venv/bin/activate" ]]; then
    echo "ℹ️ .venv が存在しません。まず uvproj_init を実行してください。"
    return 1
  fi

  # shellcheck disable=SC1091
  source ".venv/bin/activate" || return 1
  echo "✅ Activated uv project: $(_uv_project_name) (env=.venv)"
}
export -f uvproj_use

# 既存の sour を uv 用にそのまま利用
sour() {
  if [[ -f ".venv/bin/activate" ]]; then
    # shellcheck disable=SC1091
    source ".venv/bin/activate"
    echo "✅ Activated: .venv (project: $(_uv_project_name))"
  else
    echo ".venv/bin/activate が見つかりません。まず uvproj_init を実行してください。"
    return 1
  fi
}
export -f sour

# bashrc のリロード
rsta() {
  if [[ -n "${VIRTUAL_ENV:-}" ]] && command -v deactivate >/dev/null 2>&1; then
    echo "🚪 Deactivating: $(basename "$VIRTUAL_ENV")"
    deactivate
  fi
  echo "🔁 Reloading ~/.bashrc..."
  # shellcheck disable=SC1090
  source ~/.bashrc
  echo "✅ .bashrc reloaded."
}
export -f rsta