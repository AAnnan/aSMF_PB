#!/bin/bash
sampleName=larp1_met
thresh=10

# Get the total # reads
tot=$(wc -l < sorted_tracks_m6A.larp1_met.txt)
let tot=tot-1

# Get the # of reads containing > thresh methylated Adenines
awk -v thresh="$thresh" '$10>=thresh {print $10}' sorted_tracks_m6A.${sampleName}.txt > count
met=$(wc -l < count)
rm count

# Calculated and output the ratio
ratio=$(awk -v met="$met" -v tot="$tot" 'BEGIN { print  ( met / tot ) }')
echo "${ratio}% of reads show >10 6mAs in ${sampleName}"
