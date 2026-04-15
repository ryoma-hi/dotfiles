function gs {
    git status
}

function gl {
    git log --oneline --graph --all
}

function gpush {
    param([string]$msg = "Update")

    git add -A
    if ($LASTEXITCODE -ne 0) { return }

    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        git commit -m $msg
        if ($LASTEXITCODE -ne 0) { return }
    } else {
        Write-Host "[INFO] No changes: skipping commit."
    }

    $branch = git branch --show-current
    if (-not $branch) { $branch = "main" }

    git pull --rebase --autostash origin $branch 2>$null

    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' *> $null
    if ($LASTEXITCODE -eq 0) {
        git push origin $branch
    } else {
        git push -u origin $branch
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Pushed to origin/$branch"
    }
}

function gh_set_remote {
    param(
        [Parameter(Mandatory=$true)][string]$repo
    )

    $repo = $repo.Trim()

    if ($repo -match '^https://github\.com/[^/]+/[^/]+(?:\.git)?/?$') {
        $url = $repo.TrimEnd('/')
        if ($url -notmatch '\.git$') {
            $url = "$url.git"
        }
    }
    elseif ($repo -match '^[^/]+/[^/]+$') {
        $url = "https://github.com/$repo.git"
    }
    else {
        Write-Host "[ERROR] Invalid repository format."
        Write-Host "[INFO] Use one of the following formats:"
        Write-Host "       username/repository"
        Write-Host "       https://github.com/username/repository"
        Write-Host "       https://github.com/username/repository.git"
        return
    }

    git remote get-url origin *> $null
    if ($LASTEXITCODE -eq 0) {
        git remote set-url origin $url
    } else {
        git remote add origin $url
    }

    $branch = git branch --show-current
    if (-not $branch) { $branch = "main" }

    git rev-parse --verify HEAD *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[INFO] No commits yet. Run 'gpush ""Initial commit""' or 'git push -u origin $branch' after your first commit."
        Write-Host "[OK] Remote set to $url."
        return
    }

    git rev-parse --abbrev-ref --symbolic-full-name '@{u}' *> $null
    if ($LASTEXITCODE -eq 0) {
        git push origin $branch
    } else {
        git push -u origin $branch
    }

    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Remote set to $url and pushed $branch."
    }
}

function gh_register {
    param(
        [Parameter(Mandatory=$true)][string]$repo,
        [string]$vis = "private"
    )

    $repo = $repo.Trim()
    $vis = $vis.Trim().ToLower()

    if ($repo -notmatch '^[^/]+/[^/]+$') {
        Write-Host "[ERROR] Invalid repository format."
        Write-Host "[INFO] Usage: gh_register owner/repo [private|public]"
        return
    }

    if ($vis -ne "private" -and $vis -ne "public") {
        Write-Host "[ERROR] Visibility must be 'private' or 'public'."
        return
    }

    git rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        git init
        if ($LASTEXITCODE -ne 0) { return }
    }

    git rev-parse --verify HEAD *> $null
    if ($LASTEXITCODE -ne 0) {
        if (-not (Test-Path "README.md")) {
            $repoName = ($repo -split "/")[-1]
            Set-Content -Path "README.md" -Value "# $repoName"
        }

        git add -A
        if ($LASTEXITCODE -ne 0) { return }

        git commit -m "initial commit"
        if ($LASTEXITCODE -ne 0) { return }
    }

    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if ($ghCmd) {
        gh repo create $repo --$vis --source . --remote origin --push
        if ($LASTEXITCODE -ne 0) { return }
    } else {
        Write-Host "[INFO] gh CLI not found. Create repo on GitHub first:"
        Write-Host "       https://github.com/new"
        gh_set_remote $repo
        if ($LASTEXITCODE -ne 0) { return }
        gpush "initial commit"
        if ($LASTEXITCODE -ne 0) { return }
    }

    Write-Host "[OK] Repository ready: $repo"
}

function gh_branch {
    param(
        [Parameter(Mandatory=$true)][string]$name,
        [string]$base = "HEAD"
    )

    $name = $name.Trim()
    $base = $base.Trim()

    if (-not $name) {
        Write-Host "[ERROR] Branch name is required."
        Write-Host "[INFO] Usage: gh_branch <name> [base]"
        return
    }

    if ($base -eq "main") {
        $base = "origin/main"
    }

    git rev-parse --git-dir *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Not a git repo"
        return
    }

    git fetch origin -q 2>$null

    git show-ref --verify --quiet "refs/heads/$name"
    if ($LASTEXITCODE -eq 0) {
        git switch $name
        if ($LASTEXITCODE -ne 0) { return }
    } else {
        git switch -c $name $base
        if ($LASTEXITCODE -ne 0) { return }
    }

    git push -u origin $name 2>$null | Out-Null

    Write-Host "[OK] Now on branch: $name"
}