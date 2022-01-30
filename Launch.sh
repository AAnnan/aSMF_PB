#! /bin/bash

## Resource Allocation
#SBATCH --time=2-00:00:00
#SBATCH --partition=all
#SBATCH --mem=48G
#SBATCH –-cpus-per-task=8

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="PacBio"

source ${CONDA_ACTIVATE} pacbio

# Requires Pacbio SMRT Link v10
smrtlink10=/home/aannan/smrtlink10/smrtcmds/bin/
export PATH=$PATH:$smrtlink10

# Include the provided scripts in your $PATH if running single_region_m6A_pipeline.sh unmodified:
export PATH=$PATH:./src

# The following command-line tools will also be required:
#       samtools
#       bedops (https://bedops.readthedocs.io/en/latest/)
#       datamash (https://www.gnu.org/software/datamash/)

# Example region EEF-1A
echo -e "III\t6969000\t6973000" > eef1a.bed

# Mapping locations of molecules (HERE ONLY CHRIII)
# (not needed if running whole-genome pbalign on the complete raw subreads)
ZMW_index=chrIII.methyl.bed.gz

# Raw data from GEO
aligned_subreads_met=/mnt/external.data/MeisterLab/mA_PacBio_2022_01_20/SMRTLINK_v8_Aligned_Replica_1_Methyl/aligned.Methyl.bam
#subreads_cont=/scratch/aannan/mA_PB43_20012022/Replica_1_Cont/demultiplex.bc1008_BAK8A_OA--bc1008_BAK8A_OA.bam

# Thresholds for calling base modifications depending on subread coverage per molecule.
thresholds=config/base_mod_thresholds.DS75167.txt

reference=c_elegans.PRJNA13758.WS279.genomic.fa

m6A_pipeline.sh "$aligned_subreads_met" eef1a eef1a.bed "$reference" "$ZMW_index" "$thresholds"

conda deactivate

#sbatch --cpus-per-task 52
