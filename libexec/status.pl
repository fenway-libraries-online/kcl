#!/usr/bin/perl

#@ begin usage
#@ descrip Show Koha server process statuses
#@ end usage

system(qw(service apache2 status)) == 0 or die;
system(qw(/etc/init.d/koha-common status), $ENV{'KOHA_SITE'}) == 0 or die;
