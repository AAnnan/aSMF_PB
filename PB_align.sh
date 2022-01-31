#! /bin/bash

## Resource Allocation
#SBATCH --time=7-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=420G
#SBATCH –-cpus-per-task=64

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="PacBio"

source ${CONDA_ACTIVATE} pacbio

# Requires Pacbio SMRT Link v10 
smrtlink10=/home/aannan/smrtlink10/smrtcmds/bin/
export PATH=$PATH:$smrtlink10

# Raw PacBio seq data
subreads_cont=/mnt/external.data/MeisterLab/mA_PacBio_2022_01_20/Replica_1_Cont/demultiplex.bc1008_BAK8A_OA--bc1008_BAK8A_OA.bam
subreads_met=/mnt/external.data/MeisterLab/mA_PacBio_2022_01_20/Replica_1_Methyl/demultiplex.bc1001_BAK8A_OA--bc1001_BAK8A_OA.bam

#ref Genome
ref=c_elegans.PRJNA13758.WS279.genomic.fa
ref_mmi=ce11.WS279.mmi


pbmm2 index "$ref" "$ref_mmi"

pbmm2 align --sort --sort-memory 10G \
			--num-threads 48 --sort-threads 8 \
			"$ref_mmi" "$subreads_cont" aligned_bc1008_CONT.bam

pbmm2 align --sort --sort-memory 10G \
			--num-threads 48 --sort-threads 8 \
			"$ref_mmi" "$subreads_met" aligned_bc1001_MET.bam

pbindex aligned_bc1008_CONT.bam
pbindex aligned_bc1001_MET.bam

conda deactivate

#sbatch --cpus-per-task 102