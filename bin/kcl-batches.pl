#!/usr/bin/perl

# MARC record batches for Koha

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

my %opt;
getopts(':alr', \%opt);

my $sql = <<'EOS';
SELECT *
FROM import_batches
WHERE batch_type = 'batch'
EOS

$sql .= "AND import_status = 'staged'\n" if !$opt{'a'};
$sql .= ( $opt{'r'} ? "ORDER BY import_batch_id DESC\n" : "ORDER BY import_batch_id ASC\n" );

my $dbh = C4::Context->dbh;
$dbh->{AutoCommit} = 0;
my $sth = $dbh->prepare($sql);

$sth->execute;
printf("%6s  %-8.8s  %-6.6s  %7s  %5s  %-19.19s  %-32.32s  %s\n",
        'ID',
        'Status',
        'Type',
        'Records',
        'Items',
        'Timestamp',
        'File name',
        'Comments',
) if $opt{'l'};
while (my $row = $sth->fetchrow_hashref) {
    if ($opt{'l'}) {
        printf(
            "%6d  %-8.8s  %-6.6s  %7d  %5d  %-19.19s  %-32.32s  %s\n",
                $row->{'import_batch_id'},
                $row->{'import_status'},
                $row->{'record_type'},
                $row->{'num_records'},
                $row->{'num_items'},
                $row->{'upload_timestamp'},
                $row->{'file_name'},
                $row->{'comments'} // '(no comments)',
        );
    }
    else {
        print $row->{'import_batch_id'}, ' ', $row->{'file_name'}, "\n";
    }
}

__END__
import_batch_id int(11) NO      PRI             auto_increment
matcher_id      int(11) YES
template_id     int(11) YES
branchcode      varchar(10)     YES     MUL
num_records     int(11) NO              0
num_items       int(11) NO              0
upload_timestamp        timestamp       NO              CURRENT_TIMESTAMP
overlay_action  enum('replace','create_new','use_template','ignore')    NO              create_new
nomatch_action  enum('create_new','ignore')     NO              create_new
item_action     enum('always_add','add_only_for_matches','add_only_for_new','ignore','replace') NO              always_add
import_status   enum('staging','staged','importing','imported','reverting','reverted','cleaned')        NO              staging
batch_type      enum('batch','z3950','webservice')      NO              batch
record_type     enum('biblio','auth','holdings')        NO              biblio
file_name       varchar(100)    YES
comments        mediumtext      YES

