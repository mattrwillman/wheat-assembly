#!/bin/bash
# Run from the login node inside a tmux session.
#
# tmux quick reference:
#   tmux new -s assembly       start a new session named 'assembly'
#   tmux attach -t assembly    reattach to an existing session
#   Ctrl+b d                   detach from session (leaves it running)
#   tmux ls                    list active sessions

module load miniconda3
source activate /project/gbru_wheat2/conda/assembly_env

mkdir -p logs
LOG="logs/snakemake_$(date +%Y%m%d_%H%M%S).log"

snakemake --profile profiles/slurm --configfile config/config.yml 2>&1 | tee "$LOG"
