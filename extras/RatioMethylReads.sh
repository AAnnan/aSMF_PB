#! /bin/bash

## Resource Allocation
#SBATCH --time=7-00:00:00
#SBATCH --partition=gpu
#SBATCH --mem=96G
#SBATCH –-cpus-per-task=16

#SBATCH --mail-user=ahrmad.annan@students.unibe.ch
#SBATCH --mail-type=end,fail
#SBATCH --job-name="PacBio"

### TO MODIFY \!/
##############
##############
sampleName=larp1_met
##############
##############

#Set the threshold to count a read as having methylation
thresh=10

# Get the total # reads
tot=$(wc -l < tracks_m6A.${sampleName}.txt)

# Get the # of reads containing > thresh methylated Adenines
awk -v thresh="$thresh" '$10>=thresh {print $10}' tracks_m6A.${sampleName}.txt > count
met=$(wc -l < count)
rm count

# Calculated and output the ratio
ratio=$(awk -v met="$met" -v tot="$tot" 'BEGIN { print  ( met / tot ) }')
echo "${ratio}% of reads show >10 6mAs in ${sampleName}"
