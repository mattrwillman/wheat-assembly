#!/bin/bash

#SBATCH --job-name="IL_assembly_filtadapt"
#SBATCH -p bigmem
#SBATCH -A gbru_wheat2
#SBATCH -N 1
#SBATCH -n 48
#SBATCH -t 7-00:00:00
#SBATCH --mail-user=mrwillma@ncsu.edu
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH -o "stdout.%x.%j.%N"
#SBATCH -e "stderr.%x.%j.%N"

# Module load miniconda
module load miniconda3

# Activate the correct environment
source activate /project/gbru_wheat2/conda/assembly_env

# Perform the analysis with a pointer to the config file
snakemake --cores 'all' --configfile config/config.yml
