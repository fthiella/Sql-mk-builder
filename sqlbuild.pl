#!/usr/bin/perl

use strict;
use warnings;
 
use DBI;
use File::Slurp;

sub execute_sql {
	my $dbh = shift;
	my $sql_query = shift;

	my $qry = $dbh->prepare($sql_query)
	|| die $DBI::errstr;

	$qry->execute()
	|| die $DBI::errstr;

	# get header length
	my @width = map { length($_) } @{$qry->{NAME}};

	# rows
	my @rows;
	while (my @row = $qry->fetchrow_array) {
		foreach my $i (0 .. $#row) {
			if (($row[$i]) && (length($row[$i])>$width[$i])) { $width[$i]=length($row[$i]); }
		}
		push @rows, [@row];
	}

	if (scalar @rows>0) {
		# format

		my $f = join ' | ', map { "%-".$_."s"} @width;

		# print header

		print "\n";
		print sprintf $f, @{$qry->{NAME}};
		print "\n";

		# print hr
		print join("-|-", map { '-'x$_ } @width ), "\n";

		# print rows
		foreach my $row (@rows) {
			{
				no warnings 'uninitialized';
				print sprintf $f, @{$row};
			}
			print "\n";
		}
	} else {
		print "0 rows\n";
	}

	$qry->finish();
}


# read the input file
my $sql = read_file($ARGV[0]);

# get the connection parameters

my ($conn) = $sql =~ /conn=\"([^\s]*)\"\s/;
my ($username) = $sql =~ /username=\"([^\s]*)\"\s/;
my ($password) = $sql =~ /password=\"([^\s]*)\"\s/;

my $dbh = DBI->connect($conn, $username, $password)
|| die $DBI::errstr;

foreach my $sql_query (split /;\n/, $sql) {
  execute_sql($dbh, $sql_query);
}

print "\n";
