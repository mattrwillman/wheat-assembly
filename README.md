# Wheat assembly workflow

Snakemake workflow for assembling wheat genomes from PacBio HiFi reads and scaffolding against a reference. Runs all genotypes in parallel via SLURM on the Atlas HPC.

## Pipeline steps

1. Filter SMRTbell adapters from BAM (`HiFiAdapterFilt`)
2. Assemble contigs (`hifiasm`)
3. Remove haplotigs (`purge_dups`) — pauses for manual cutoff inspection
4. Assess completeness (`BUSCO`, `assembly-stats`)
5. Scaffold against reference (`RagTag`)
6. Plot alignment coverage (`gggenomes`)

## Setup

1. Create the conda environment:

```bash
conda env create -f environment.yml -p /project/gbru_wheat2/conda/wheat_assembly_env
```

2. Edit `config/config.yml`:

```yaml
ragtag_ref: "/path/to/reference.fasta"

genotypes:
  MyGenotype:
    pacbio_dir: "/path/to/bam/files"
```

BAM files are discovered automatically via glob from each `pacbio_dir`.

3. Download the BUSCO dataset once before running the workflow. Pre-downloading avoids concurrent download conflicts if multiple genotypes start their BUSCO jobs simultaneously. Run from the project root so the dataset lands where `busco_download_path` in `config/config.yml` expects it:

```bash
module load miniconda3
source activate /project/gbru_wheat2/conda/wheat_assembly_env
busco --download_path busco_downloads --download poales_odb12
```

The download is ~500 MB. If you prefer a different location (e.g. a shared project directory), update `busco_download_path` in `config/config.yml` accordingly.

## Running on Atlas (SLURM)

Start a `tmux` session on the login node, then run:

```bash
tmux new -s assembly
bash snakemake_batch.sh
```

See the comments in `snakemake_batch.sh` for a tmux quick reference (attach, detach, list sessions).

This activates the conda environment and submits each rule as a separate SLURM job via the profile in `profiles/slurm/`. Snakemake output is saved to a timestamped log file (`logs/snakemake_YYYYMMDD_HHMMSS.log`) so each run's output is preserved. Jobs are routed to the appropriate partition automatically:

| Partition | Rules |
|-----------|-------|
| `bigmem`  | `assemble_contigs` (1536 GB, 7 days) |
| `atlas`   | all other rules |

`assemble_contigs` uses all 48 cores of a bigmem node, so the full 1536 GB is available to the job exclusively.

## Running locally

```bash
source activate /project/gbru_wheat2/conda/wheat_assembly_env
snakemake --cores all --configfile config/config.yml
```

## Output

Results are written to `results/` namespaced by genotype:

```
results/
  {genotype}/
    hifiadapterfilt/
    hifiasm/
    purge_dups/
    busco/
      purged/
      scaffold/
    ragtag/
  {genotype}.ragtag.scaffold.fa   ← symlink to ragtag output
  plots/
    {genotype}_ragtag_alignment_coverage.pdf
    {genotype}_ragtag_alignment_coverage.png
    {genotype}_ragtag_alignment_coverage.tsv
```
