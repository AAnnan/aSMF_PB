## aSMF_PB
Analysis pipeline of adenine methylation single-molecule footprinting (aSMF) experiments with PacBio sequencing. Based on the code by [Stergachis *et al.* (2020)](https://www.science.org/doi/10.1126/science.aaz1646)

## Index

- [Prerequisites](https://github.com/AAnnan/aSMF_PB/#prerequisites)
- [Usage](https://github.com/AAnnan/aSMF_PB/#usage)
- [Output](https://github.com/AAnnan/aSMF_PB/#output)

## Prerequisites

A [conda](https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html) installation with:
* [bedops](https://anaconda.org/bioconda/bedops), [datamash](https://anaconda.org/bioconda/datamash) and [samtools](https://anaconda.org/bioconda/samtools)

The [SMRT LINK Software Suite](https://www.pacb.com/support/software-downloads/).

The *C. elegans* reference genome file (ce11 or later).

## Usage

Take a look at the headers of each of the following scripts, modify them according to your data and run in order:

1. **`01_PB_aligner.sh`**
1. **`02_ZMW_coords_per_chrom.sh`**
1. **`03_Kinetics.sh`**

## Output

BED file that can be opened in a genome viewer showing the 6mA marks over a region.
![](https://i.imgur.com/3zu7mfN.png)

Average methylation profile over a region.
![](https://i.imgur.com/fJgT3x8.png)
