#!/usr/bin/perl

# SQL Markdown Builder
# https://github.com/fthiella/Sql-mk-builder

=head1 NAME

sqlbuild.pl - Perl SQL Markdown Builder (for the CLI or for Sublime Text)

=head1 SYNOPSIS

sqlbuild.pl --sql=query.sql --conn="dbi:SQLite:dbname=test.sqlite3" --username=admin --password=pass

=head1 DESCRIPTION

I like text editors, I have fallen in love with Sublime Text,
and everything I write is in Markdown syntax!

This simple Perl sript executes SQL queries and produces
Markdown output. It can be easily integrated with Sublime Text
editor, but it can also be used at the command line.

=head1 LICENSE

This is released under the Artistic 
License. See L<perlartistic>.

=head1 AUTHOR

Federico Thiella - GitHub projects L<https://github.com/fthiella/>
or email L<mailto:fthiella@gmail.com>

=cut

use strict;
use warnings;
 
use DBI;
use File::Slurp;
use Getopt::Long;
use utf8;

our $VERSION = "1.01";
our $RELEASEDATE = "June 20st, 2016";

# CLI Interface

sub do_help {
	print <<endhelp;
Usage: sqlbuild.pl [options]
       perl sqlbuild.pl [options]

Options:
  -s, --sql         source SQL file
  -c, --conn        specify DBI connection string
  -u, --username    specify username
  -p, --password    specify password
  -mw, --maxwidht   maximum width column (if unspecified get from actual data)

Project GitHub page: https://github.com/fthiella/Sql-mk-builder
endhelp
}

sub do_version {
	print "Sql-mk-builder $VERSION ($RELEASEDATE)\n";
}

# Internal functions

sub max ($$) {
	# if second parameter is defined then return max(p1, p2) otherwise return p1
	if ($_[1]) {
		$_[$_[0] < $_[1]];
	} else {
		$_[0];
	}
}

sub min ($$) {
	# if second parameter is defined then return min(p1, p2) otherwise return p1
	if ($_[1]) {
		$_[$_[0] > $_[1]];
	} else {
		$_[0];
	}
}

# SQL Functions

sub do_sql {
	my $dbh = shift;
	my $sql_query = shift;
	my $max_width = shift;

	my $max_format = '';

	if (($max_width) && ($max_width> 0))
	{
		$max_format = ".$max_width";
	}

	my $qry = $dbh->prepare($sql_query)
	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr, "\n";


	$qry->execute()
	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr;

	# get header length
	my @width = map { min(length($_), $max_width) } @{$qry->{NAME}};

	# rows
	my @rows;
	while (my @row = $qry->fetchrow_array) {
		foreach my $i (0 .. $#row) {
			if (($row[$i]) && (min(length($row[$i]),$max_width)>$width[$i])) { $width[$i]=min(length($row[$i]), $max_width); }
		}
		push @rows, [@row];
	}

	if (scalar @rows>0) {
		# format

		my $f = join ' | ', map { "%-".$_.$max_format."s"} @width;

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
				# replace non printable characters with space
				for (@{$row}) { s/[^[:print:]]/ /g; }
				print sprintf $f, @{$row};
			}
			print "\n";
		}
	} else {
		print "0 rows\n";
	}

	$qry->finish();
}

# add utf8 support (still need to verify if it's always working)
use open ':std', ':encoding(UTF-8)';

# Get command line options
my $source;
my $version;
my $conn;
my $username;
my $password;
my $maxwidth;
my $help;

GetOptions(
	'sql|s=s'      => \$source,
	'version|v'    => \$version,
	'conn|c=s'     => \$conn,
	'username|u=s' => \$username,
	'password|p=s' => \$password,
	'maxwidth|w=i' => \$maxwidth,
	'help|h'       => \$help,
);

if ($help)
{
	do_help;
	exit;
}

if ($version)
{
	do_version;
	exit;
}

die "Please specfy sql source with -s or -sql\n" unless ($source);

# read the input file
my $sql = read_file($source);

# get the connection parameters from source sql file (command line will take precedence)

unless ($conn)     { ($conn) = $sql =~ /conn=\"([^\s]*)\"\s/; }
unless ($username) { ($username) = $sql =~ /username=\"([^\s]*)\"\s/; }
unless ($password) { ($password) = $sql =~ /password=\"([^\s]*)\"\s/; }
unless ($maxwidth) { ($maxwidth) = $sql =~ /maxwidth=\"([^\s]*)\"\s/; }

my $dbh = DBI->connect($conn, $username, $password)
|| die $DBI::errstr;

foreach my $sql_query (split /;\n/, $sql) {
  	do_sql($dbh, $sql_query, $maxwidth);
}

print "\n";
