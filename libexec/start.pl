#!/usr/bin/perl

#@ begin usage
#@ descrip Start Koha server procesess
#@ end usage

my $site = $ENV{'KOHA_SITE'};

if ($site eq '*') {
    start_plack();
    start_zebra();
}
else {
    start_plack($site);
    start_zebra($site);
}

sub start_zebra {
    if (!@_) {
        @_ = `koha-list --enabled`;
        chomp @_;
    }
    system(qw(/usr/sbin/koha-start-zebra), @_) == 0 or die "start zebra: $!";
}

sub start_plack {
    if (!@_) {
        @_ = `koha-list --enabled --plack`;
        chomp @_;
    }
    system(qw(/usr/sbin/koha-plack --start --quiet), @_) == 0 or die "start plack: $!";
}
