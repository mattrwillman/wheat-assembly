# Wheat assembly workflow

1. Install software into a conda environment

```
conda create --name assembly_env
source activate assembly_env
conda install snakemake pbtk cutadapt hifiasm ragtag r-pafr
```

2. Clone the repository and edit config.yaml and snakemake_batch.sh files to fit your job.

3. Run [snakemake](https://snakemake.readthedocs.io/en/stable/)

Use batch script to submit job to SLURM. See example script below.

```
sbatch snakemake.slurm
```

Or, run snakemake locally.

```
snakemake --cores 'all' --configfile config/config.yml
```

### SLURM file

Example SLURM file named "snakemake.slurm":

```
#!/bin/bash
#SBATCH --job-name="assembly"		#name of the job submitted
#SBATCH -p atlas			#name of the queue you are submitting job to
#SBATCH -A project			#enter your project neame
#SBATCH -N 1				#number of nodes in this job
#SBATCH -n 48				#number of cores/tasks in this job
#SBATCH -t 7-00:00:00			#time allocated for this job hours:mins:seconds
#SBATCH --mail-user=emailAddress	#enter your email address
#SBATCH --mail-type=BEGIN,END,FAIL	#you will receive an email when job starts, ends, or fails
#SBATCH -o "stdout.%x.%j.%N"		#standard output, %x.%j.%N adds job name.number.node to outputfile name
#SBATCH -e "stderr.%x.%j.%N"		#standard error

# Module load miniconda
module load miniconda3

# Activate the correct environment
source activate assembly_env

# Perform the analysis with a pointer to the config file
snakemake --cores 'all' --configfile config/config.yml
```