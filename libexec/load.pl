#!/usr/bin/perl

#@ begin usage
#@ descrip              Load staged batches of MARC record
#@ opt [-m INT]         Report progress every INT records (default: 50)
#@ opt [-f FRAMEWORK]   Use FRAMEWORK (default: "")
#@ opt [-v]             Be verbose
#@ arg BATCHID          Batch ID as reported by `kcl stage'
#@ end usage

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
#use MARC::File::USMARC;
use Getopt::Std qw(getopts);

my %opt = qw(
    m   50
);
getopts(':f:m:v', \%opt);

usage() if @ARGV < 1;

my $n = 0;

my $framework = $opt{'f'} || '';
my $callback = $opt{'v'} ? \&progress_verbose : \&progress;
my $interval = $opt{'m'};

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

foreach my $batch_id (@ARGV) {
    commit_batch($batch_id);
}

sub commit_batch {
    my ($batch_id) = @_;
    print STDERR "Loading batch $batch_id...\n";
    my ($num_added, $num_updated, $num_items_added, $num_items_replaced, $num_items_errored, $num_ignored) =
        BatchCommitRecords($batch_id, $framework, $interval, $callback);
    $dbh->commit;
    printf STDERR "\rDone:                \n";
    printf STDERR "%6d added\n%6d updated\n%6d items added\n%6d items replaced\n%6d items errored\n%6d ignored\n%6d total",
                $num_added, $num_updated, $num_items_added, $num_items_replaced, $num_items_errored, $num_ignored, $n;
}

sub progress_verbose {
    printf STDERR "\r...%d";
    $n += $interval;
}

sub progress {
    print STDERR '.';
    $n += $interval;
}
