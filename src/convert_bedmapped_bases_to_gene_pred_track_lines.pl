#!/usr/bin/env perl
use strict;
use warnings;

# Convert bedmap output to a UCSC genome browser track, in the style of a gene-prediction track.
# Single-base modification calls are mapped onto the span of the sequenced molecule.
while (<STDIN>) {
    chomp;
    my ($chrom, $min0, $max1, $zmwid, $span, $coverage, $modslist) = split /\t/;
    unless (defined ($modslist)) {
        die "Failed to parse ($_)\n";
    }
    my $chromStart = $min0;
    my $chromEnd = $max1;
    my $thickStart = $chromStart + 1;
    my $thickEnd  = $chromEnd - 1;
    my @mods = split /\;/, $modslist;
    my @offsets = map { $_ - $chromStart } @mods;
    my $blockStarts = join(",", (0, @offsets, $chromEnd-$chromStart-1 ) );
    my $numMods = scalar( @offsets );
    my $blockCount = $numMods + 2;
    my $blockSizes = join(",", ("1") x $blockCount );
    my $itemRgb = 0;
    my $name = $zmwid;
    my $strand = ".";
    my @bedcols = ($chrom, $chromStart, $chromEnd, $name, $coverage, $strand, 
                   $thickStart, $thickEnd,   $itemRgb, 
                   $blockCount, $blockSizes, $blockStarts ); 
    print join("\t", @bedcols ) . "\n";
}

