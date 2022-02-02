#! /bin/bash

## Resource Allocation
#SBATCH --time=14-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=96G
#SBATCH –-cpus-per-task=16

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

GENOMEWIDE="no" #or yes
# If GENOMEWIDE=yes update your sample name
sampleName="GenomeWide_met"
# If GENOMEWIDE=no update your region of interest and samplename
# and supply the proper ZMW_index (mapping locations of molecules) (ZMW_index)
region_sampleName=eef1a_met
chrom=III
start=6969000
end=6970000

ZMW_index=chrIII.methyl.bed.gz

# Thresholds for calling base modifications depending on subread coverage per molecule.
thresholds=config/base_mod_thresholds.DS75167.txt
##############
##############

# Update $PATH with SMRT tools and src folder:
export PATH=$PATH:./src
export PATH=$PATH:$smrtlink10

if [[ "$GENOMEWIDE" == "no" ]] ; then
	# Create region bed
	echo -e "${chrom}\t${start}\t${end}" > ${region_sampleName}.bed
	# launch region pipeline
	m6A_pipeline.sh "$aligned_subreads" "$region_sampleName" "${region_sampleName}.bed" "$reference" "$ZMW_index" "$thresholds"
elif [[ "$GENOMEWIDE" == "yes" ]] ; then
	# launch Genome wide pipeline
	genome_wide_m6A_pipeline.sh "$aligned_subreads" "$sampleName" "$reference" "$thresholds"
else
	echo -e "GENOMEWIDE variable not properly set\n";
    exit 1
fi


conda deactivate

#sbatch --cpus-per-task 16
