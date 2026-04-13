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
  local pyver="$1"

  if ! command -v uv >/dev/null 2>&1; then
    echo "[ERROR] uv not found. Please install uv first."
    return 1
  fi

  # 優先順位: 引数 > 環境変数 > 未指定
  if [[ -n "$pyver" ]]; then
    echo "[INFO] Using Python version from argument: $pyver"
  elif [[ -n "$UV_DEFAULT_PYVER" ]]; then
    pyver="$UV_DEFAULT_PYVER"
    echo "[INFO] Using default Python version: $pyver"
  fi

  if ! _uv_is_uv_project; then
    echo "[INFO] No pyproject.toml found. Initializing this directory as a uv project."

    if [[ -n "$pyver" ]]; then
      echo "[INFO] Running: uv init --python $pyver"
      uv init --python "$pyver" || {
        echo "[ERROR] uv init failed."
        return 1
      }
    else
      echo "[INFO] Running: uv init"
      uv init || {
        echo "[ERROR] uv init failed."
        return 1
      }
    fi
  fi

  local proj envdir py
  proj="$(_uv_project_name)"
  envdir=".venv"

  echo "[INFO] Running uv sync: project=${proj} env=${envdir}"
  if [[ -n "$pyver" ]]; then
    UV_PYTHON="$pyver" uv sync || return 1
  else
    uv sync || return 1
  fi

  py="${envdir}/bin/python"
  if [[ ! -x "$py" ]]; then
    echo "[ERROR] ${py} not found. .venv may not have been created correctly."
    return 1
  fi

  if ! "$py" -c "import ipykernel" 2>/dev/null; then
    echo "[INFO] Installing ipykernel into .venv via uv..."
    uv pip install -p "$py" ipykernel || {
      echo "[ERROR] Failed to install ipykernel."
      return 1
    }
  fi

  "$py" -m ipykernel install --user --name "${proj}" --display-name "Python (${proj})" || {
    echo "[ERROR] Failed to register ipykernel."
    return 1
  }

  echo "[OK] uvproj_init completed: .venv / kernel='${proj}'"
  echo "[INFO] To activate it, run: sour"
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