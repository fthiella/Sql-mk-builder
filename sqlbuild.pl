#!/usr/bin/perl

# SQL Markdown Builder
# https://github.com/fthiella/Sql-mk-builder

=head1 NAME

sqlbuild.pl - Perl SQL Markdown Builder

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

our $VERSION = "1.05";
our $RELEASEDATE = "September 13st, 2016";

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
  -f, --format      output format (table -default- or record)

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

sub do_sql_record {
	my $dbh = shift;
	my $sql_query = shift;
	my $max_width = shift;

	my $max_format = '';
	my $nr = 0;

	if (($max_width) && ($max_width> 0))
	{
		$max_format = ".$max_width";
	}

	my $qry = $dbh->prepare($sql_query)
	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr, "\n";

	$qry->execute()
	|| die "````\n", $sql_query, "\n````\n\n", ">", $DBI::errstr;

	my @field = (@{$qry->{NAME}});

	# rows
	while (my @row = $qry->fetchrow_array) {
		print "# Record $nr\n\n";

		my @width = (1,1);

		foreach my $i (0 .. $#row) {
			if (min(length($field[$i]),$max_width)>$width[0])               { $width[0]=min(length($field[$i]),$max_width); }
			if (($row[$i]) && (min(length($row[$i]),$max_width))>$width[1]) { $width[1]=min(length($row[$i]),$max_width);   }
		}

		my $f = join ' | ', (map { "%-".$_."s"} @width);

		print sprintf $f, qw(Column Value);
		print "\n";
		print '-'x$width[0] . '-|-' . '-'x$width[1] . "\n";


		# replace non printable characters with space (should do the same to field names... but it's weird to use non printable characters in field names)

		foreach my $i (0 .. $#row) {
			{
				no warnings 'uninitialized';
				for (@row) { s/[^[:print:]]/ /g; }

				print sprintf $f, (substr($field[$i], 0, $max_width), substr($row[$i], 0, $max_width));
				print "\n";
			}
		}

		print "\n";

		$nr++;
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
my $format;
my $help;

GetOptions(
	'sql|s=s'      => \$source,
	'version|v'    => \$version,
	'conn|c=s'     => \$conn,
	'username|u=s' => \$username,
	'password|p=s' => \$password,
	'maxwidth|w=i' => \$maxwidth,
	'format|f=s'   => \$format,
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
# the regexp is over-simplified but should work on most cases

unless ($conn)     { ($conn) = $sql =~ /conn=\"([^\""]*)\"\s/; }
unless ($username) { ($username) = $sql =~ /username=\"([^\""]*)\"\s/; }
unless ($password) { ($password) = $sql =~ /password=\"([^\""]*)\"\s/; }
unless ($maxwidth) { ($maxwidth) = $sql =~ /maxwidth=\"([^\""]*)\"\s/; }
unless ($format)   { ($format) = $sql =~ /format=\"([^\""]*)\"\s/; }

# default
unless ($format)   { $format = 'table'; }

my $dbh = DBI->connect($conn, $username, $password)
|| die $DBI::errstr;

foreach my $sql_query (split /;\n/, $sql) {
	# remove comments from sql_query (some drivers will remove automatically but other will throw an error)
	# (simple regex, it will work only on simplest cases, please see http://learn.perl.org/faq/perlfaq6.html#How-do-I-use-a-regular-expression-to-strip-C-style-comments-from-a-file)
	$sql_query =~ s/\/\*.*?\*\///gs;
  	if ($format eq 'record') {
  		do_sql_record($dbh, $sql_query, $maxwidth);	
  	} else { 
  		do_sql($dbh, $sql_query, $maxwidth);
  	}
}

print "\n";
