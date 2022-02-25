#! /bin/bash

## Resource Allocation
#SBATCH --time=7-00:00:00
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
sampleName="methyl"
aligned_subreads="aligned_bc1001_MET.bam"
##############
##############

export PATH=$PATH:./src
chroms=("I" "II" "III" "IV" "V" "X" "MtDNA")

##########################################################################
#  Extract aligned coordinates and subread depth per ZMW.
##########################################################################

# Setting a minimum subread coverage threshold focuses analysis time on the usable data.
MIN_SUBREAD_COVERAGE=10
# Setting a maximum subread coverage can be helpful to avoid alignment artifacts.  Set to zero here for no limit.
MAX_SUBREAD_COVERAGE=0

mapped_ZMW_list=$sampleName.unique_ZMW_coords.tsv
if ! [[ -s "$mapped_ZMW_list" ]] ; then
    samtools view "$aligned_subreads" \
        | pacbio_cigar2coords.pl \
        | datamash -s -g 1,4  min 2 max 3 count 4 \
        | awk 'BEGIN{OFS="\t"} { print $1, $3, $4, $2, ($4-$3), $5 }' \
        | awk -v mincov=$MIN_SUBREAD_COVERAGE -v maxcov=$MAX_SUBREAD_COVERAGE \
            '($6>=mincov)&&(maxcov<1||$6<=maxcov) { print $0 "\t" $1":"($2+1)"-"$3 }' \
        | sort-bed - > "$mapped_ZMW_list"
fi

cut --fields=1-4 $sampleName.unique_ZMW_coords.tsv > unique_ZMW_coords.tsv

for chr in "${chroms[@]}"; do 
	grep "^${chr}" unique_ZMW_coords.tsv > "chr${chr}.${sampleName}.bed"
	gzip "chr${chr}.${sampleName}.bed"
done

rm unique_ZMW_coords.tsv

conda deactivate

#sbatch --cpus-per-task 16