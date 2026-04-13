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