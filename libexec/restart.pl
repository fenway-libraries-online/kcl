#!/usr/bin/perl

#@ begin usage
#@ descrip Restart an instance
#@ end usage

system(qw(service apache2 restart)) == 0 or die;
system(qw(/etc/init.d/koha-common restart)) == 0 or die;
