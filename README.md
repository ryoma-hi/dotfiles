# dotfiles（研究環境セットアップ）

本リポジトリは、研究用の開発環境を**簡単に再現・共有**するための dotfiles です。  
Linux（大学PC）とWindows（自宅PC）の両方で操作できます。

---

## 🎯 このリポジトリでできること

- uv を用いた Python 仮想環境の統一管理
- Git / GitHub 操作の簡略化（コマンドラッパー）
- OSをまたいだ一貫した開発環境の構築

---

## 📦 ディレクトリ構成

```
dotfiles/
├─ .bashrc            # bash エントリポイント
├─ bash/              # Linux 用設定
├─ powershell/        # Windows 用設定
├─ templates/         # 環境変数テンプレート
└─ setup/             # セットアップスクリプト
```

---

## 🚀 セットアップ

### ⚠️ 必要なソフトウェア

以下がインストールされていることを確認してください：

- git
- Python（3.10以上推奨）
- uv

確認コマンド：

```
git --version
python --version
uv --version
```

uv が未インストールの場合：

```
pip install uv
```

## 🐧 Linux（大学PC）

```
git clone https://github.com/ryoma-hi/dotfiles.git ~/dotfiles
cd ~/dotfiles
bash setup/linux.sh
source ~/.bashrc
```

## 🪟 Windows（PowerShell）

```
git clone https://github.com/ryoma-hi/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
powershell -ExecutionPolicy Bypass -File .\setup\windows.ps1
```

👉 実行後は PowerShell または VS Code を再起動してください


## 🔐 Git / GitHub 設定（必須） 

この dotfiles は Git / GitHub 操作を前提としているため、  
事前にアカウント設定が必要です。

### ① Git ユーザー設定 
```
git config --global user.name "あなたの名前"
git config --global user.email "あなたのメールアドレス"
```

### ② GitHub 認証

以下のコマンドでログインしてください：

```
gh auth login
```

ログイン後、以下で確認できます：

```
gh auth status
```

### 🔹 GitHub CLI が未インストールの場合

- Linux
```
sudo apt install gh
```
- Windows
```
winget install GitHub.cli
```
---

## 🧪 Python / uv

### 🔹 初期化

```
uvproj_init [python_version]
```

このコマンドは以下を自動で実行します：

- `.venv`（仮想環境）の作成
- 依存関係のインストール（`uv sync`）
- Jupyterカーネルの登録

👉 これ1つで「すぐ実験できる状態」になります

例：

```
uvproj_init
uvproj_init 3.10
```

### 🔹 仮想環境の有効化

```
sour
```

または：

```
uvproj_use
```

👉 `.venv` を有効化し、このプロジェクト専用のPython環境に切り替えます

### 🔹 設定の再読み込み

```
rsta
```

👉 環境変数や関数を再読み込みします

---

## 🔧 Git 操作

### 🔹 保存（最も重要）

```
gpush "commit message"
```

以下をまとめて実行します：

- `git add -A`
- `git commit`
- `git pull --rebase`
- `git push`

👉 日常的な「保存」はこのコマンドだけでOK

例：

```
gpush
gpush "実験結果更新"
```

---

## 🌐 GitHub 操作

### 🔹 既存リポジトリに接続

```
gh_set_remote owner/repo
```

既にGitHub上に存在するリポジトリと接続します。

- remote（origin）を設定
- ローカルとGitHubを紐付け

例：

```
gh_set_remote username/project
gh_set_remote https://github.com/username/project
```

👉 既存リポジトリに接続する場合はこちら

### 🔹 新規リポジトリ作成

```
gh_register owner/repo
```

以下を自動で実行します：

- GitHub上にリポジトリ作成
- remote設定
- 初回 push

例：

```
gh_register username/project
```

👉 新しくGitHubに公開したい場合はこちら（環境によって動かないので、レポジトリをgithubで作って、接続する方を推奨します）

---

## 🌿 ブランチ操作

```
gh_branch branch_name
```

以下を実行します：

- ブランチ作成
- 切り替え
- upstream設定

例：

```
gh_branch feature-x
```

👉 機能追加や実験を分離する際に使用  
main or masterに戻るには以下のコマンドを実行してください。

```
git switch main
```
または
```
git switch master
```

---

## 🔹 Slurm（大学PCのみ）

### GPU環境起動

```
srun_gpu モデル名
```

### 長時間ジョブ

```
intr1 モデル名
```

👉 GPUを使った実験・学習に使用

---

## 🔐 環境変数管理

環境変数はローカルに分離されています（Gitに含まれません）

### Linux

```
~/.config/research-secrets/env.sh
```

### Windows

```
$HOME\.config\research-secrets\env.ps1
```

👉 これらのファイルを各自で編集してください（テンプレートは dotfiles\templates にあります）

---

## ⚠️ uv 環境でのパッケージ管理

### ❌ NG

```
pip install xxx
```

👉 環境が壊れる可能性があります


### ✅ 推奨

```
uv add xxx
```

- `pyproject.toml` に反映
- 再現可能な環境になる


### ✅ 一時インストール

```
uv pip install xxx
```

👉 実験用（環境には残らない）


### 🔁 環境再現

```
uv sync
```

👉 他PCで作業する際に必須


## 🎯 まとめ

| 目的 | コマンド |
|------|--------|
| パッケージ追加 | uv add |
| 一時インストール | uv pip install |
| 環境再現 | uv sync |
