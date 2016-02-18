#!/usr/bin/perl

use strict;
use warnings;
 
use DBI;
use File::Slurp;

# read the input file
my $sql = read_file($ARGV[0]);

my $dbo = DBI->connect("database", "username", "password")
|| die $DBI::errstr;

my $qry = $dbo->prepare($sql);

$qry->execute();

# get header length
my @width = map { length($_) } @{$qry->{NAME}};

# rows
my @rows;
while (my @row = $qry->fetchrow_array) {
	foreach my $i (0 .. $#row) {
		if (length($row[$i])>$width[$i]) { $width[$i]=length($row[$i]); }
	}
	push @rows, [@row];
}

# format

my $f = join ' | ', map { "%-".$_."s"} @width;

# print header

print sprintf $f, @{$qry->{NAME}};
print "\n";

# print hr
print join("-|-", map { '-'x$_ } @width ), "\n";

# print rows
foreach my $row (@rows) {
	print sprintf $f, @{$row};
	print "\n";
}

$qry->finish();