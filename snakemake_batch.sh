#!/bin/bash
# Run from the login node inside a tmux session.

module load miniconda3
source activate /project/gbru_wheat2/conda/assembly_env

snakemake --profile profiles/slurm --configfile config/config.yml
