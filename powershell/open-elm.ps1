param(
    [string]$Gpu = "a100",
    [string]$ProjectPath = "/cl/work13/ryoma-hi/",
    [int]$Cpu = 2,
    [string]$Time = "10:00:00"
)

$ErrorActionPreference = "Stop"

$sshConfig = "$env:USERPROFILE\.ssh\config"

Write-Host "[INFO] Checking SSH route to pine13..." -ForegroundColor Cyan
$pineHost = (ssh pine13 "hostname" 2>$null | Out-String).Trim()

if ($pineHost -ne "pine13") {
    throw "[ERROR] Could not reach pine13 via SSH/config. Got: '$pineHost'"
}

Write-Host "[OK] Connected to pine13" -ForegroundColor Green
Write-Host "[INFO] Requesting GPU node... (GPU=$Gpu, CPU=$Cpu, Time=$Time)" -ForegroundColor Cyan

# --- ① pine13 上で tmux + srun ---
$remoteScript = @'
GPU="$1"
CPU="$2"
TIME_LIMIT="$3"

mkdir -p ~/.cache/vscode-gpu

# 既存セッションがあれば再利用
if tmux has-session -t vscode-gpu 2>/dev/null; then
  echo "REUSE_SESSION"
  exit 0
fi

rm -f ~/.cache/vscode-gpu/current_elm
rm -f ~/.cache/vscode-gpu/srun.log

tmux new-session -d -s vscode-gpu \
  "bash -lc 'srun -p gpu_intr --account is-nlp -c ${CPU} -t ${TIME_LIMIT} --gres=gpu:${GPU}:1 bash -lc \"hostname > ~/.cache/vscode-gpu/current_elm; while true; do sleep 3600; done\" > ~/.cache/vscode-gpu/srun.log 2>&1'"

echo "STARTED_SESSION"
'@

$remoteScript = ($remoteScript -replace "`r", "").Trim()
$remoteResult = ($remoteScript | ssh pine13 "bash -s -- $Gpu $Cpu $Time" 2>$null | Out-String).Trim()

if ($remoteResult -eq "REUSE_SESSION") {
    Write-Host "[INFO] Reusing existing vscode-gpu tmux session on pine13" -ForegroundColor Yellow
} elseif ($remoteResult -eq "STARTED_SESSION") {
    Write-Host "[OK] Started tmux session 'vscode-gpu' on pine13" -ForegroundColor Green
} else {
    Write-Host "[WARN] Unexpected tmux bootstrap output: $remoteResult" -ForegroundColor Yellow
}

# --- ② ノード名待機 ---
$elm = ""
$lastStatus = ""

for ($i = 0; $i -lt 120; $i++) {
    $tmuxState = (ssh pine13 "bash -lc 'if tmux has-session -t vscode-gpu 2>/dev/null; then echo ALIVE; else echo DEAD; fi'" 2>$null | Out-String).Trim()

    $result = ssh pine13 "bash -lc 'if [ -f ~/.cache/vscode-gpu/current_elm ]; then cat ~/.cache/vscode-gpu/current_elm; fi'" 2>$null
    $elm = ($result | Out-String).Trim()

    if ($elm -match '^elm[0-9]+$') {
        break
    }

    $status = ssh pine13 "bash -lc 'if [ -f ~/.cache/vscode-gpu/srun.log ]; then tail -n 5 ~/.cache/vscode-gpu/srun.log; fi'" 2>$null
    $statusText = ($status | Out-String).Trim()

    if ([string]::IsNullOrWhiteSpace($statusText)) {
        if ($tmuxState -eq "ALIVE") {
            $statusText = "tmux session alive on pine13, waiting for srun output..."
        } else {
            $statusText = "tmux session is not alive on pine13"
        }
    }

    if ($statusText -ne $lastStatus) {
        Write-Host "[WAIT] $statusText" -ForegroundColor Yellow
        $lastStatus = $statusText
    }

    Start-Sleep -Seconds 3
}

if (-not ($elm -match '^elm[0-9]+$')) {
    throw "[ERROR] elm node not allocated yet."
}

Write-Host "[OK] Allocated candidate: $elm" -ForegroundColor Green

# --- ③ config 更新 ---
$block = @"
# BEGIN current-elm
Host current-elm
  HostName $elm
  User ryoma-hi
  ProxyJump pine13
  ForwardAgent yes
  IdentityFile C:\Users\ryoma\.ssh\id_ed25519
  IdentitiesOnly yes
# END current-elm
"@

$content = ""
if (Test-Path $sshConfig) {
    $content = Get-Content $sshConfig -Raw
}

if ($content -match '(?ms)^# BEGIN current-elm.*?# END current-elm\s*') {
    $content = [regex]::Replace(
        $content,
        '(?ms)^# BEGIN current-elm.*?# END current-elm\s*',
        "$block`r`n"
    )
} else {
    if ($content.Length -gt 0 -and -not $content.EndsWith("`r`n")) {
        $content += "`r`n"
    }
    $content += "`r`n$block`r`n"
}

Set-Content -Path $sshConfig -Value $content -Encoding ascii
Write-Host "[OK] Updated SSH config for current-elm -> $elm" -ForegroundColor Green

# --- ④ current-elm への疎通確認 ---
Write-Host "[INFO] Verifying SSH to current-elm..." -ForegroundColor Cyan

$ok = $false
for ($i = 0; $i -lt 20; $i++) {
    $test = ssh current-elm "hostname" 2>$null
    $testText = ($test | Out-String).Trim()

    if ($testText -eq $elm) {
        $ok = $true
        break
    }

    Start-Sleep -Seconds 2
}

if (-not $ok) {
    throw "[ERROR] current-elm is not reachable yet (expected: $elm)."
}

Write-Host "[OK] SSH verified: $elm" -ForegroundColor Green

# --- ⑤ VSCode 起動 ---
Write-Host "[INFO] Launching VSCode at: $ProjectPath" -ForegroundColor Cyan

$uri = "vscode-remote://ssh-remote+current-elm$ProjectPath"
code --folder-uri $uri