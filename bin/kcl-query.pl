#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Std qw(getopts);

my %opt;
getopts('v', \%opt);

use lib '/usr/share/koha/lib';

use C4::Context;
use C4::Biblio;
use C4::ImportBatch;
use C4::Matcher;

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

my $sql;
while (<STDIN>) {
    $sql .= $_;
}

my $sth = $dbh->prepare($sql);
$sth->execute(@ARGV);
while (my @row = $sth->fetchrow_array) {
    print join("\t", map { defined $_ ? $_ : '' } @row), "\n";
}
$sth->finish;
