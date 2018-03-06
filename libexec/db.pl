#!/usr/bin/perl

#@ begin usage
#@ descrip              Interact with the MySQL database
#@ end usage

use strict;
use warnings;

use XML::XPath;

my $conf = $ENV{'KOHA_CONF'};
my $xp = XML::XPath->new(filename => $conf);

my $db_scheme = $xp->findvalue('/yazgfs/config/db_scheme');
my $db   = $xp->findvalue('/yazgfs/config/database');
my $host = $xp->findvalue('/yazgfs/config/hostname');
my $port = $xp->findvalue('/yazgfs/config/port');
my $user = $xp->findvalue('/yazgfs/config/user');
my $pass = $xp->findvalue('/yazgfs/config/pass');

if ($db_scheme eq 'mysql') {
    exec('mysql', -u => $user, "-p$pass", $db);
}
