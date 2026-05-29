# Wheat assembly workflow

Snakemake workflow for assembling wheat genomes from PacBio HiFi reads and scaffolding against a reference. Runs all genotypes in parallel via SLURM on the Atlas HPC.

## Pipeline steps

1. Convert BAM → FASTQ (`pbtk bam2fastq`)
2. Filter and trim SMRTbell adapters (`cutadapt`)
3. Assemble contigs (`hifiasm`)
4. Scaffold against reference (`ragtag`)
5. Plot alignment coverage (`gggenomes`)

## Setup

1. Create the conda environment:

```bash
conda env create -f workflow/envs/assembly_env.yml
```

2. Clone the repository and edit `config/config.yml`:

```yaml
ragtag_ref: "/path/to/reference.fasta"

genotypes:
  MyGenotype:
    pacbio_dir: "/path/to/bam/files"
```

BAM files are discovered automatically via glob from each `pacbio_dir`.

## Running on Atlas (SLURM)

Start a `tmux` session on the login node, then run:

```bash
bash snakemake_batch.sh
```

This activates the conda environment and submits each rule as a separate SLURM job via the profile in `profiles/slurm/`. Snakemake output is saved to a timestamped log file (`logs/snakemake_YYYYMMDD_HHMMSS.log`) so each run's output is preserved. Jobs are routed to the appropriate partition automatically:

| Partition | Rules |
|-----------|-------|
| `bigmem`  | `assemble_contigs` (500 GB, 7 days), `scaffold_contigs` (250 GB, 2 days) |
| `atlas`   | all other rules |

## Running locally

```bash
source activate /project/gbru_wheat2/conda/assembly_env
snakemake --cores all --configfile config/config.yml
```

## Output

Results are written to `results/` namespaced by genotype:

```
results/
  {genotype}/
    fastq/
    filtered/
    trimmed_filtered/
    hifiasm/
    ragtag/
  {genotype}.ragtag.scaffold.fa
  plots/
    {genotype}_ragtag_alignment_coverage.pdf
    {genotype}_ragtag_alignment_coverage.png
    {genotype}_ragtag_alignment_coverage.tsv
```
