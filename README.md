# dotfiles（研究環境セットアップ）

研究用の開発環境を簡単に再現するための最小構成の dotfiles です。

できること：

- uvベースの仮想環境構築
- Git / GitHub 操作の簡略化
- Linux（大学PC）とWindows（自宅PC）で利用可能

---

## 📦 ディレクトリ構成

```
dotfiles/
├─ .bashrc            # bash エントリポイント
├─ bash/              # Linux 設定
├─ powershell/        # Windows 設定
├─ templates/         # env テンプレート
└─ setup/             # セットアップスクリプト
```

---

## 🚀 セットアップ

### ⚠️ 必要なもの

以下がインストールされていることを確認してください：

- git
- Python（3.10以上推奨）
- uv

確認：

```
git --version
python --version
uv --version
```

uv が無い場合：

```
pip install uv
```

---

## 🐧 Linux（大学PC）

```
git clone <this repo> ~/dotfiles
cd ~/dotfiles
bash setup/linux.sh
source ~/.bashrc
```

---

## 🪟 Windows（PowerShell）

```
git clone <this repo> $HOME\dotfiles
cd $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File .\setup\windows.ps1
```

セットアップ後は PowerShell / VS Code を再起動してください。

---

## 🧪 Python / uv

### 初期化

```
uvproj_init [python_version]
```

このコマンドで以下を自動実行します：

- `.venv` 作成
- 依存関係インストール（uv sync）
- Jupyterカーネル登録

👉 このコマンド1つで「実験できる状態」になる

例：

```
uvproj_init
uvproj_init 3.10
```

---

### 環境の有効化

```
uvproj_use
```

または：

```
sour
```

作成済みの `.venv` を有効化する

👉 Python環境をこのプロジェクト用に切り替える

---

```
rsta
```

シェル設定を再読み込みする

👉 環境変数や追加した関数・コマンドを反映したいときに使用

---

## 🔧 Git

### 保存（基本コマンド）

```
gpush "commit message"
```

内部で実行される処理：

- git add -A
- git commit
- git pull --rebase
- git push

👉 「とりあえず保存」はこれ

例：

```
gpush
gpush "実験更新"
```

* commitメッセージは省略可能
* デフォルトは `"Backup"`

---

## 🌐 GitHub

### 既存リポジトリに接続

```
gh_set_remote owner/repo
```

既存のGitHubリポジトリに接続するコマンド

remote（origin）を設定
既存リポジトリに紐付け

👉 「すでにGitHubにリポジトリがある」場合に使う  
👉 「ローカルとGitHubをつなぐ」ためのコマンド

例：

```
gh_set_remote username/project
gh_set_remote https://github.com/username/project
```

---

### 新規リポジトリ作成

```
gh_register owner/repo
```

新しく作成したGitHubリポジトリに接続するコマンド

* GitHub上のリポジトリに接続
* remote 設定
* 初回 push

👉 「このフォルダをGitHubに上げたい」ときに使う

例：

```bash
gh_register username/project
```
または：

```bash
gh_register https://github.com/username/project
```

---

## 🌿 ブランチ

### 作成＋切り替え

```
gh_branch branch_name
```

新しいブランチを作成して切り替える

* ブランチ作成
* upstream 設定
* GitHubと連携

👉 機能追加や実験を分けたいときに使う

例：

```
gh_branch feature-x
```
---

## 🔹 Slurm（大学PCのみ）

```bash
srun_gpu [gpu_type]
```

GPU付きのインタラクティブ環境を起動する

👉 GPUを使って実験したいとき

例：

```bash
srun_gpu a6000
srun_gpu v100
```

---

```bash
intr1 [gpu_type]
```

長時間のGPUジョブを起動する

👉 長時間の学習・実験用

例：

```bash
intr1
intr1 a100
```

---

# 🔐 環境変数について

このリポジトリでは、環境変数を **ローカルに分離** しています。

実際に使うファイルは以下です。適宜以下のファイルを各自で修正してください：

## Linux

```
~/.config/research-secrets/env.sh
```

## Windows（PowerShell）

```
$HOME\.config\research-secrets\env.ps1
```

テンプレートは dotfiles\templates にありますのでさんこうにしてください。

---

# ⚠️ uv環境でのパッケージ管理について

この環境では **uv を用いて Python パッケージを管理しています**。

---

## ❌ NG（やってはいけない）

```bash
pip install xxx
```

👉 グローバル環境や想定外の場所にインストールされる可能性があります  
👉 環境が壊れる原因になります

---

## ✅ 推奨（基本）

```bash
uv add xxx
```

* `pyproject.toml` に依存関係を追加
* `uv.lock` を更新
* 再現可能な環境になる

👉 パッケージ追加はこれを使う

---

## ✅ 仮想環境内に直接入れる場合

```bash
uv pip install xxx
```

* `.venv` に直接インストール
* `pyproject.toml` には反映されない

👉 一時的な実験用

---

## 🔁 依存関係の反映

```bash
uv sync
```

* `pyproject.toml` と `uv.lock` に基づいて環境を再現

👉 他のPCで作業するときは必須

---

## 🎯 まとめ

| やりたいこと   | コマンド             |
| -------- | ---------------- |
| パッケージ追加  | `uv add`         |
| 一時インストール | `uv pip install` |
| 環境再現     | `uv sync`        |

---

## 💡 補足

* 基本は `uv add` を使う
* `pip install` は使わない
* 環境を共有する場合は `uv sync` を使う

---
