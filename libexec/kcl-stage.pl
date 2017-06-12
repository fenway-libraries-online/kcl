#!/usr/bin/perl

# MARC record batch loader for Koha

use strict;
use warnings;

use POSIX qw(strftime);
use MARC::File::USMARC;
use Getopt::Std qw(getopts);

# Koha modules
use lib '/usr/share/koha/lib';
use C4::Context;
use C4::Biblio;
use C4::ImportBatch;
use C4::Matcher;

my %opt = qw(
    t biblio
    e UTF-8
    O create_new
    N create_new
    I always_add
);
getopts(':nF:t:e:m:id:ONI', \%opt);

usage() if @ARGV != 1;

my $file = shift @ARGV;

my $dry_run = $opt{'n'};
my $format = $opt{'F'} ||= filename2format($file) || fatal("unknown record format: $file");
my $record_type = $opt{'t'};
my $encoding = $opt{'e'};
my $comments = $opt{'m'} || strftime('record load %Y-%m-%d %H:%M:%S', localtime);
my $parse_items = $opt{'i'};

# Matching and actions
my $matcher_code = $opt{'d'};
my $overlay_action = $opt{'O'};
my $nomatch_action = $opt{'N'};
my $item_action = $opt{'I'};
for ($overlay_action) {
    tr/-A-Z/_a-z/;
    s/^add$/create_new/;
    usage() if !/^(replace|create_new|ignore)$/;
}
for ($nomatch_action) {
    tr/-A-Z/_a-z/;
    s/^add$/create_new/;
    usage() if !/^(create_new|ignore)$/;
}
for ($item_action) {
    tr/-A-Z/_a-z/;
    s/^add$/always_add/;
    usage() if !/^(always_add|ignore)$/;
}

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;

# Read records
my ($errors, $marcrecords);
if ($format eq 'MARCXML') {
    ($errors, $marcrecords) = C4::ImportBatch::RecordsFromMARCXMLFile($file, $encoding);
} else {
    ($errors, $marcrecords) = C4::ImportBatch::RecordsFromISO2709File($file, $record_type, $encoding);
}

# Stage records
print STDERR "Staging records...";
my ($batch_id, $num_valid, $num_items, @import_errors) = BatchStageMarcRecords(
    $record_type,
    $encoding,
    $marcrecords,
    $file,
    undef,
    undef,
    $comments,
    '',
    $parse_items,
    0,
    10,
    sub {
        print STDERR '.';
    }
);
print STDERR "done\n";

# Perform matching
my $num_with_matches = 0;
if (defined $matcher_code) {
    my ($matcher_id) = grep { $_->{'code'} eq $matcher_code } C4::Matcher::GetMatcherList();
    fatal("no such matcher: $matcher_code") if !defined $matcher_id;
    my $matcher = C4::Matcher->fetch($matcher_id);
    fatal("no such matcher: $matcher_code") if !defined $matcher;
    print STDERR "Finding matching records...";
    $num_with_matches = BatchFindDuplicates($batch_id, $matcher, 10, 50, sub {
        print STDERR '.';
    });
    print STDERR "done\n";
    SetImportBatchMatcher($batch_id, $matcher_id);
    SetImportBatchOverlayAction($batch_id, $overlay_action);
    SetImportBatchNoMatchAction($batch_id, $nomatch_action);
    SetImportBatchItemAction($batch_id, $item_action);
}

my $num_invalid = scalar @import_errors;
if ($dry_run) {
    printf "batch %s dry run: %d records (%d matches) %d items, %d errors\n", $batch_id, $num_valid + $num_invalid, $num_with_matches, $num_items, $num_invalid;
}
else {
    $dbh->commit;
    printf "batch %s staged: %d records (%d matches) %d items, %d errors\n", $batch_id, $num_valid + $num_invalid, $num_with_matches, $num_items, $num_invalid;
}

sub filename2format {
    my ($file) = @_;
    return 'MARC' if $file =~ /\.ma?rc$/;
    return 'MARCXML' if $file =~ /\.xml$/;
}

sub fatal {
    print STDERR "kstage: @_\n";
    exit 2;
}

__END__


my $num_with_matches = 0;
my $checked_matches = 0;
my $matcher_failed = 0;
my $matcher_code = "";
    $dbh->commit;
}

my $results = {
    staged          => $num_valid,
    matched         => $num_with_matches,
    num_items       => $num_items,
    import_errors   => scalar(@import_errors),
    total           => $num_valid + scalar(@import_errors),
    checked_matches => $checked_matches,
    matcher_failed  => $matcher_failed,
    matcher_code    => $matcher_code,
    import_batch_id => $batch_id
};

# TODO

