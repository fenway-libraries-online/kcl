#!/usr/bin/perl

#@ begin usage
#@ descrip              Match bibs by standard methods and insert 999 fields accordingly
#@ opt [-v]             Be verbose
#@ end usage

use strict;
use warnings;

sub usage;
sub fatal;

use C4::Search;
use C4::Biblio;
use MARC::Batch;

use Getopt::Long
    qw(:config posix_default gnu_compat require_order bundling no_ignore_case);

binmode STDOUT;

my %mkquery;
my $max_matches = 10;

GetOptions(
    'o|oclc-number' => sub { $mkquery{'oclc'} = \&query_terms_oclc_number },
    'i|isbn'        => sub { $mkquery{'isbn'} = \&query_terms_isbn },
) or usage;

my @mkqueries = grep { defined $_ } @mkquery{qw(oclc isbn)};
my %match;

my $searcher = Koha::SearchEngine::Search->new({index => $Koha::SearchEngine::BIBLIOS_INDEX});

$/ = "\x1d";
while (defined (my $usmarc = <STDIN>)) {
    eval {
        my $marc_record = MARC::File::USMARC->decode($usmarc);
        my %matched;
        my @terms = map { $_->($marc_record) } @mkqueries;
        if (@terms) {
            my @matches = perform_query(@terms);
            if (@matches > $max_matches) {
                splice @matches, $max_matches;  # XXX Really?  Just chop them off?
            }
            foreach my $m (@matches) {
                my $field = MARC::Field->new('999', '', '', 'c' => $m);
                $marc_record->append_fields($field);
                last MATCHER if scalar(keys %matched) == $max_matches;
            }
            print MARC::File::USMARC->encode($marc_record);
            undef $usmarc;
        }
    };
    print $usmarc if defined $usmarc;  # Fallback -- just print it unchanged
}

sub query_terms_oclc_number {
    my ($marc) = @_;
    my @onums = map {
        /^\(OCoLC\)[^1-9]*([1-9][0-9]*)/ ? ($1) : ()
    } $marc->subfield('035', 'a');
    return if !@onums;
    return map { qq{Other-control-number="(OCoLC)$_"} } @onums;
}

sub perform_query {
    my @terms = @_;
    my $query = join(' or ', @terms);
    my ($error, $searchresults, $total_hits) = $searcher->simple_search_compat($query, 0, $max_matches);
    my @matches;
    foreach (@{$searchresults}) {
        my $marcrecord = marc($_);
        my $result = TransformMarcToKoha($marcrecord, '');
        push @matches, $result->{'biblionumber'} if $result
    }
    return @matches;
}

sub marc {
    my ($marc) = @_;
    my $search_engine = C4::Context->preference("SearchEngine");
    return $marc if $search_engine eq 'Elasticsearch';
    return MARC::Record->new_from_xml($marc, 'UTF-8') if $marc =~ /^</;
    return MARC::Record->new_from_usmarc($marc);
}

