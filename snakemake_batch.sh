#!/bin/bash

#SBATCH --job-name="assembly_LA03136E71"          #name of the job submitted
#SBATCH -p atlas                                  #name of the queue you are submitting job to
#SBATCH -A gbru_wheat2
#SBATCH -N 1                                      #number of nodes in this job
#SBATCH -n 48                                     #number of cores/tasks in this job
#SBATCH -t 7-00:00:00                             #time allocated for this job hours:mins:seconds
#SBATCH --mail-user=zjwinn@ncsu.edu               #email address
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH -o "stdout.%x.%j.%N"                      #standard out %x adds job name and %j adds job number to outputfile name and %N adds the node
#SBATCH -e "stderr.%x.%j.%N"                      #optional but it prints our standard error

# Module load miniconda
module load miniconda3

# Activate the correct environment
source activate assembly_env

# Perform the analysis with a pointer to the config file
snakemake --cores 'all' --configfile config/LA03136E71_config.yml
