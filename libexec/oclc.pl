#!/usr/bin/perl

#@ begin usage
#@ descrip              Match bibs by OCLC number
#@ opt [-v]             Be verbose
#@ arg OCLC...          One or more OCLC numbers
#@ end usage

use strict;
use warnings;

use C4::Search;
use C4::Biblio;

use Getopt::Std qw(getopts);

binmode STDOUT;

my %opt = qw(
    m   10
);
getopts(':m:', \%opt);

usage() if @ARGV < 1;

my $max_matches = $opt{'m'};
my $n = 0;

my $searcher = Koha::SearchEngine::Search->new({index => $Koha::SearchEngine::BIBLIOS_INDEX});
my $query = join(' or ', map { qq{Other-control-number="(OCoLC)$_"} } @ARGV);
my ($error, $searchresults, $total_hits) = $searcher->simple_search_compat($query, 0, $max_matches);

my %match;
foreach (@{$searchresults}) {
    my $marcrecord = marc($_);
    my $result = TransformMarcToKoha($marcrecord, '');
    if ($result) {
        my $biblionumber = $result->{'biblionumber'};
        next if $match{$biblionumber};
#$marcrecord->append(MARC::Field->new('999', '', '', 'c' => $biblionumber));
        $match{$biblionumber} = $marcrecord->as_usmarc;
    }
}
print values %match;

sub marc {
    my ($marc) = @_;
    my $search_engine = C4::Context->preference("SearchEngine");
    return $marc if $search_engine eq 'Elasticsearch';
    return MARC::Record->new_from_xml($marc, 'UTF-8') if $marc =~ /^</;
    return MARC::Record->new_from_usmarc($marc);
}

