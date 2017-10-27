#!/usr/bin/perl

#@ begin usage
#@ descrip          Run a query against the instance database
#@ opt [-s SQL]     SQL statement to execute (default: read from stdin)
#@ opt [-n NULL]    Print NULL instead of "" for null values
#@ [PARAM...]       Parameters for the statement
#@ end usage

use strict;
use warnings;

use Getopt::Std qw(getopts);

my %opt = ('n' => '');
getopts(':mn:s:', \%opt);

use lib '/usr/share/koha/lib';

use C4::Context;
use C4::Biblio;
use C4::ImportBatch;
use C4::Matcher;

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

my $sql = $opt{'s'};
if (!defined $sql) {
    $sql = '';
    while (<STDIN>) {
        $sql .= $_;
    }
}

my $sth = $dbh->prepare($sql);
$sth->execute(@ARGV);
if ($opt{'m'}) {
    while (my $row = $sth->fetchrow_hashref) {
        foreach my $k (sort keys %$row) {
            my $v = $row->{$k};
            $v = $opt{'n'} if !defined $v;
            print $k, "\t", $v, "\n";
        }
    }
}
else {
    while (my @row = $sth->fetchrow_array) {
        print join("\t", map { defined $_ ? $_ : $opt{'n'} } @row), "\n";
    }
}
$sth->finish;
