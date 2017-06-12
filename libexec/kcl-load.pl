#!/usr/bin/perl

# MARC record batch loader for Koha

use strict;
use warnings;

# Koha modules
use lib '/usr/share/koha/lib';
use C4::Context;
use C4::Biblio;
use C4::ImportBatch;
use C4::Matcher;

use POSIX qw(strftime);
use MARC::File::USMARC;
use Getopt::Std qw(getopts);

my %opt = qw(
    s default
    t biblio
    e UTF-8
);
getopts(':s:F:t:e:m:i', \%opt);

usage() if @ARGV != 1;

my $file = shift @ARGV;

my $format = $opt{'F'} ||= filename2format($file) || fatal("unknown record format: $file");
my $record_type = $opt{'t'};
my $encoding = $opt{'e'};
my $comments = $opt{'m'} || strftime('record load %Y-%m-%d %H:%M:%S', localtime);
my $parse_items = $opt{'i'};

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

foreach my $batch_id (@ARGV) {
    commit_batch($batch_id);
}

sub commit_batch {
    my ($batch_id) = @_;
    my $job = undef;
    my ($num_added, $num_updated, $num_items_added, $num_items_replaced, $num_items_errored, $num_ignored) =
        BatchCommitRecords($batch_id, $framework, 50, $callback);
    $dbh->commit;
    printf "batch %d
}

