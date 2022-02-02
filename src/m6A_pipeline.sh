#!/bin/bash

if [[ "$#" -ne "6" ]] ; then
    echo -e "Usage:  $0 subreads.bam region_label region_coords.bed reference.fasta mapped_ZMW_index.bed.gz thresholds_by_coverage.tsv" 1>&2
    exit 1
fi

subreads=$1
regionName=$2
regionBed=$3
reference=$4
indexBed=$5
thresholds=$6

##################################################################
# Programs that need to be findable in $PATH :
# - Pacbio SMRTLINK v8 for bamsieve pbalign ipdSummary 
# - bedops suite for bedops and bedmap
# - GNU datamash
# - samtools
# - two utility Perl scripts in this directory
##################################################################
for program in bamsieve ipdSummary bedops bedmap datamash samtools ; do
    if ! [[ -x $(which "$program") ]] ; then
        echo -e "$0:  Failed to find $program in $PATH\n";
        exit 1
    fi 
done

if [[ "$TMPDIR" == "" ]] ; then
    export TMPDIR="/tmp"
fi

if ! [[ -f "${reference}.fai" ]] ; then
    samtools faidx "$reference"
    if ! [[ -f "${reference}.fai" ]] ; then
        echo -e "Failed to write samtools faidx index for $reference" 1>&2
        exit 1
    fi
fi

outdir=results.$regionName
mkdir -p "$outdir"


##################################################################
#  Find ZMW IDs for molecules mapped in our region of interest.  
##################################################################
regionZMW=$outdir/$regionName.list_ZMW_IDS.txt
if ! [[ -s "$regionZMW" ]] ; then
    zcat "$indexBed" | bedops -e 1 - "$regionBed" | cut -f 4 | sort -g > "$regionZMW"
fi


##########################################################################
#  Extract subreads from the full raw data from GEO subread bam file.    
##########################################################################
region_subreads="$outdir/$regionName.subreads.bam"
if ! [[ -s "$region_subreads" ]] ; then
    bamsieve --whitelist "$regionZMW" "$subreads" "$region_subreads"
fi


##########################################
#  Align subreads to reference genome.
##########################################
aligned_region_subreads="$region_subreads"


##########################################################################
#  Extract aligned coordinates and subread depth per ZMW.
##########################################################################

# Setting a minimum subread coverage threshold focuses analysis time on the usable data.
MIN_SUBREAD_COVERAGE=10
# Setting a maximum subread coverage can be helpful to avoid alignment artifacts.  Set to zero here for no limit.
MAX_SUBREAD_COVERAGE=0

mapped_ZMW_list=$outdir/$regionName.unique_ZMW_coords.tsv
if ! [[ -s "$mapped_ZMW_list" ]] ; then
    samtools view "$aligned_region_subreads" \
        | pacbio_cigar2coords.pl \
        | datamash -s -g 1,4  min 2 max 3 count 4 \
        | awk 'BEGIN{OFS="\t"} { print $1, $3, $4, $2, ($4-$3), $5 }' \
        | awk -v mincov=$MIN_SUBREAD_COVERAGE -v maxcov=$MAX_SUBREAD_COVERAGE \
            '($6>=mincov)&&(maxcov<1||$6<=maxcov) { print $0 "\t" $1":"($2+1)"-"$3 }' \
        | sort-bed - > "$mapped_ZMW_list"
fi


##########################################################################
#  Analyze kinetics of each molecule individually.                       #
##########################################################################
blocktrack=$outdir/tracks_m6A.$regionName.txt
if ! [[ -s "$blocktrack" ]] ; then
    while FS='\t' read chrom min0 max1 zmwid span coverage regions ; do
        csv=$outdir/basemods.$zmwid.csv.gz
        if ! [[ -f "$csv" ]] ; then
            output_bam=$TMPDIR/tmp.$zmwid.bam
            bamsieve --whitelist "$zmwid" "$aligned_region_subreads" "$output_bam"
            ipdSummary \
                --reference "$reference" \
                --gff $outdir/basemods.$zmwid.gff \
                --csv $outdir/basemods.$zmwid.csv \
                --pvalue 0.001 --identify m6A \
                -w "$regions" \
                "$output_bam" 
            rm "$output_bam"
            gzip $outdir/basemods.$zmwid.csv
            gzip $outdir/basemods.$zmwid.gff
        fi
        # We will ignore ipdSummary's GFF file of basemod calls,
        # and instead calibrate a threshold on the detailed scores in ipdSummary's CSV file.
        if [[ "$coverage" -lt 12 ]] ; then
            truncated_cov=12
        elif [[ "$coverage" -gt 37 ]] ; then
            truncated_cov=37
        else
            truncated_cov="$coverage"
        fi
        score_threshold=$(cat "$thresholds" | awk -v subread_coverage=$truncated_cov '$1==subread_coverage { print $2 }')
        # Upstream there may be a 1-based coordinate where a 0-based coordinate was expected.
        # The browser track makes it clear with alignment of m6A base mods to A's and T's.
        track_min0=$((min0-1))
        track_max1=$((max1-1))
        track_bed="$chrom\t$track_min0\t$track_max1\t$zmwid\t$span\t$coverage"
        zcat "$csv" | grep -v '^#' \
            | awk -F ',' -v threshold="$score_threshold" 'BEGIN{OFS="\t"} $4=="A" && $5>=threshold { print $1, $2-1, $2, $2-1 }' \
            | tr -d '"' \
            | bedmap --ec --delim '\t' --echo --echo-map-id <(echo -e "$track_bed") - \
            | convert_bedmapped_bases_to_gene_pred_track_lines.pl >> "$blocktrack"
    done<"$mapped_ZMW_list"
fi

sortedtrack=$outdir/sorted_tracks_m6A.$regionName.txt
if ! [[ -s "$sortedtrack" ]] ; then
    # Adding an optional track header to override the default dense visibility mode.
    echo -e "track name=\"$regionName\" description=\"$regionName\" visibility=pack" > "$sortedtrack"
    sort -k1,1 -k2,2n -k3,3n -k4,4n "$blocktrack" >> "$sortedtrack"
fi

sed '1d' "$sortedtrack" > sortedBed.txt
cut -f7 sortedBed.txt > Start.txt
cut -f12 sortedBed.txt > Met.txt
rm sortedBed.txt
