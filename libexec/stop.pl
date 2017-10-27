#!/usr/bin/perl

#@ begin usage
#@ descrip Stop Koha server processes
#@ end usage

use strict;
use warnings;

my $site = $ENV{'KOHA_SITE'};

if ($site eq '*') {
    stop_zebra();
    stop_plack();
}
else {
    stop_zebra($site);
    stop_plack($site);
}

sub stop_zebra {
    if (!@_) {
        @_ = `koha-list --enabled`;
        chomp @_;
    }
    system(qw(/usr/sbin/koha-stop-zebra), @_) == 0 or die "stop zebra: $!";
}

sub stop_plack {
    if (!@_) {
        @_ = `koha-list --enabled --plack`;
        chomp @_;
    }
    system(qw(/usr/sbin/koha-plack --stop --quiet), @_) == 0 or die "stop plack: $!";
}
