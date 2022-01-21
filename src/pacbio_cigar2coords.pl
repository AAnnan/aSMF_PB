#!/usr/bin/env perl
use strict;
use warnings;

# Extract the mapped reference span and ZMW ID from SAM lines of the aligned Pacbio subreads.

while (<STDIN>) {
    chomp;
    my ($readName, $flag, $refName, $refOffset, $mapQuality, $cigar, $ignore1, $ignore2, $ignore3, $seq, $qual, @tags) = split /\t/;
    my $min0 = $refOffset - 1;
    my $alignedSpan = referenceBasesConsumed( $cigar );
    my $max1 = $min0 + $alignedSpan; 
    my $zmwid;
    for my $zmwField (@tags) {
        if ($zmwField =~ /^zm:i:([\d]+)$/) {
            $zmwid = $1;
            last;
        }
    }
    unless (defined($zmwid)) {
        die "Failed to parse ZMWID from (" . join("\t", @tags ) . ") at $_\n";
    }
    print join("\t", ($refName, $min0, $max1, $zmwid, $alignedSpan ) ) . "\n";
}

sub referenceBasesConsumed {
    my $cigar = shift;
    my $remainder = $cigar;
    my $refSpan = 0;
    while (length($remainder) > 0) {
        if ($remainder =~ /^([\d]+)[MDNP\=X](.*)$/) {
            $refSpan += $1;
            $remainder = $2;
        } elsif ($remainder =~ /^([\d]+)[ISH](.*)$/) {
            # no reference bases consumed
            $remainder = $2;
        } else {
            die "Failed to parse cigar $remainder\n";
        }
    }
    return $refSpan;
}


