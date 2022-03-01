#! /bin/bash

## Resource Allocation
#SBATCH --time=14-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=96G
#SBATCH --cpus-per-task=16

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="PacBio"

source ${CONDA_ACTIVATE} pacbio


### TO MODIFY \!/
##############
##############
# Requires Pacbio SMRT Link v10
# Download from https://www.pacb.com/support/software-downloads/
# install with smrtlink-*.run --rootdir smrtlink10 --smrttools-only
smrtlink10=/home/aannan/smrtlink10/smrtcmds/bin/

# Path to reference file
reference=c_elegans.PRJNA13758.WS279.genomic.fa

# Path to aligned PacBio data (with .bai and .pbi)
aligned_subreads=aligned_bc1001_MET.bam

sampleName="methyl"
region_sampleName=eef1a_met
chrom=III
start=6969000
end=6970000

# region BED
echo -e "${chrom}\t${start}\t${end}" > ${region_sampleName}.bed
# supply the proper ZMW_index (mapping locations of molecules) (ZMW_index)
ZMW_index=chrIII.methyl.bed.gz

# Thresholds for calling base modifications depending on subread coverage per molecule.
thresholds=config/base_mod_thresholds.DS75167.txt
##############
##############

# Update $PATH with SMRT tools and src folder:
export PATH=$PATH:./src
export PATH=$PATH:$smrtlink10

m6A_pipeline.sh "$aligned_subreads" "$region_sampleName" "${region_sampleName}.bed" "$reference" "$ZMW_index" "$thresholds"


conda deactivate

#sbatch --cpus-per-task 16
