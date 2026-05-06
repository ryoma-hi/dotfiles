ssh -t pine13 'tmux kill-server'
ssh pine13 'rm -f ~/.cache/vscode-gpu/current_elm ~/.cache/vscode-gpu/srun.log'
Write-Host "[OK] GPU session stopped and cache cleared."