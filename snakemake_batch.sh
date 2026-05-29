#!/bin/bash
# Run from the login node inside a tmux session.

module load miniconda3
source activate /project/gbru_wheat2/conda/assembly_env

mkdir -p logs
LOG="logs/snakemake_$(date +%Y%m%d_%H%M%S).log"

snakemake --profile profiles/slurm --configfile config/config.yml 2>&1 | tee "$LOG"
