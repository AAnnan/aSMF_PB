#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=400G
#SBATCH –-cpus-per-task=52

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="PacBio"

source ${CONDA_ACTIVATE} pacbio

# Requires Pacbio SMRT Link v8.0 
smrtlink8=/home/aannan/smrtlink8/smrtcmds/bin/
export PATH=$PATH:$smrtlink8

# Include the provided scripts in your $PATH if running single_region_m6A_pipeline.sh unmodified:
export PATH=$PATH:./src

# The following command-line tools will also be required:
#       samtools
#       bedops (https://bedops.readthedocs.io/en/latest/)
#       datamash (https://www.gnu.org/software/datamash/)

# Raw data from GEO
subreads_met=/scratch/aannan/mA_PB43_20012022/Replica_1_Methyl/demultiplex.bc1001_BAK8A_OA--bc1001_BAK8A_OA.bam
subreads_cont=/scratch/aannan/mA_PB43_20012022/Replica_1_Cont/demultiplex.bc1008_BAK8A_OA--bc1008_BAK8A_OA.bam

# Thresholds for calling base modifications depending on subread coverage per molecule.
thresholds=config/base_mod_thresholds.DS75167.txt

reference=c_elegans.PRJNA13758.WS279.genomic.fa

genome_wide_m6A_pipeline.sh "$subreads_met" Methyl "$reference" "$thresholds"

genome_wide_m6A_pipeline.sh "$subreads_cont" Control "$reference" "$thresholds"

conda deactivate

#sbatch --cpus-per-task 52
