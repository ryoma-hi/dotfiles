# ====================
# slurm / gpu helpers
# ====================

alias sinfo_details="sinfo -e -O nodelist:16,statelong:8,cpus:8,cpusstate:16,gres:16,gresused:24"
alias treeclean='tree -I "*.txt|*.log|*.md|*.csv|*.json|__pycache__" -C'

srun_gpu() {
  srun -p gpu_intr --account=is-nlp --gres=gpu:${1}:1 -c 8 --pty bash
}
export -f srun_gpu

intr1() {
  if [[ "$1" == "a100" ]]; then
    srun --account=lang -p lang_gpu_intr --gres=gpu:a100:1 -c 2 --time=10:00:00 --pty zsh
  else
    srun --account=is-nlp -p gpu_intr --gres=gpu:${1:-a6000}:1 -c 2 --time=10:00:00 --pty zsh
  fi
}
export -f intr1