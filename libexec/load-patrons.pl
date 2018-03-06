#!/usr/bin/perl

#@ begin usage
#@ descrip             Load patron records
#@ opt [-f FORMAT]     File format (tsv or kv)
#@ opt [-b]            Match by cardnumber
#@ opt [-u]            Match by userid
#@ opt [-n]            Match by borrowernumber
#@ opt [-D FIELD=VAL]  Set default field values
#@ opt [-p FIELD]      Get password from another field
#@ arg [FILE]          File to load
#@ end usage

#use C4::Auth;
#use C4::Output;
#use C4::Context;
use C4::Members;
use C4::Members::Attributes qw(:all);
use C4::Members::AttributeTypes;
use C4::Members::Messaging;
#use C4::Reports::Guided;
#use C4::Templates;
use Koha::Patron::Debarments;
use Koha::Patrons;
use Koha::DateUtils;
#use Koha::Token;
use Koha::Libraries;
use Koha::Patron::Categories;

use Encode qw( encode );
use Getopt::Long
    qw(:config posix_default gnu_compat require_order bundling no_ignore_case);

use strict;
use warnings;

sub fatal;
sub usage;

my $format;
my ($match_field, %defaults);
my $password_setter;

GetOptions(
    'f|format=s' => \$format,
    'b|match-barcode' => sub { $match_field = 'cardnumber' },
    'u|match-userid' => sub { $match_field = 'userid' },
    'n|match-borrowernumber' => sub { $match_field = 'borrowernumber' },
    'D|default=s' => sub {
        $_[1] =~ /^(\w+)=(.+)$/ or usage;
        $defaults{$1} = $2;
    },
    'p|set-password=s' => sub {
        $password_setter = make_password_setter($_[1]);
    },
) or usage;

my $fh;
if (@ARGV) {
    my ($f) = @ARGV;
    open $fh, '<', $f or die "open $f: $!";
    if (!defined $format) {
        if ($f =~ /\.tsv$|\.txt$/) {
            $format = 'tsv';
        }
        elsif ($f =~ /\.csv$/) {
            $format = 'csv';
        }
        elsif ($f =~ /\.kv$/) {
            $format = 'kv';
        }
        else {
            fatal "unrecognized format: file $f";
        }
    }
}
elsif (!defined $format) {
    fatal "no format specified";
}
else {
    $fh = \*STDIN;
}
my $code = __PACKAGE__->can('proc_'.$format) or fatal "unrecognized format: $format";

$code->($fh);

# --- Functions

sub proc_kv {
    my ($fh) = @_;
    local $/ = '';
    while (<$fh>) {
        my %patron = %defaults;
        foreach (split /\n/) {
            die if !/^(\S+)\s+(.*)$/;
            $patron{$1} = $2;
        }
        process_patron(\%patron);
    }
}

sub proc_tsv {
    my ($fh) = @_;
    my @columns = <$fh>;
    chomp @columns;
    while (<$fh>) {
        chomp;
        my %patron = %defaults;
        my @fields = split /\t/;
        push @fields, '' while @fields < @columns;
        @patron{@columns} = @fields;
        process_patron(\%patron);
    }
}

sub process_patron {
    my ($patron) = @_;
    my $member;
    if ($match_field) {
        my $match_value = $patron->{$match_field};
        die "Bad patron at line $.: $_\n"
            if !defined $match_value;
        $member = GetMember($match_field => $match_value);
        while (my ($field, $value) = each %defaults) {
            $patron->{$field} = $defaults{$field} if !defined $value || !length $value;
        }
    }
    if ($member) {
        prepare_patron_for_update($patron, $member);
        ModMember(%$patron);
        print STDERR "patron updated: ", $patron->{$match_field}, "\n";
    }
    else {
        prepare_patron_for_adding($patron);
        AddMember(%$patron);
        my $str = $patron->{cardnumber} || $patron->{userid} || $patron->{categorycode};
        print STDERR "patron added: ", $str, "\n";
    }
}

sub prepare_patron_for_update {
    my ($patron, $from) = @_;
    my $password;
    if (!defined $patron->{'password'} || !length $patron->{'password'}) {
        if ($password_setter) {
            $password_setter->($patron);
        }
        else {
            delete $from->{'password'};
        }
    }
    #if (!defined $patron->{'password'}) {
    #    $password_setter->($patron);
    #}
    while (my ($field, $value) = each %$from) {
        next if $field eq $match_field;
        my $new_value = $patron->{$field};
        $patron->{$field} = $value if !defined $new_value || !length $new_value;
    }
}

sub prepare_patron_for_adding {
    my ($patron) = @_;
    my @empty = grep {
       my $value = $patron->{$_};
       !defined $value || !length $value
    } keys %$patron;
    if (!defined $patron->{'password'}) {
        $password_setter->($patron) if $password_setter;
    }
    delete @$patron{@empty} if @empty;
}

sub make_password_setter {
    local $_ = shift;
    return sub { $_[0]{'password'} = '' } if /^$/;
    if (/^(\w+)$/) {
        my $field = $1;
        return sub {
            $_[0]{'password'} = $_[0]{$field} // '';
        };
    }
    elsif (/^(\w+):-([1-9]+)$/) {
        my ($field, $n) = ($1, $2);
        return sub {
            $_[0]{'password'} = substr($_[0]{$field}, -$n);
        };
    }
    elsif (/^(\w+):([1-9]+)$/) {
        my ($field, $n) = ($1, $2);
        return sub {
            $_[0]{'password'} = substr($_[0]{$field}, 0, $n);
        };
    }
    elsif (/^(\w+):([1-9]+),([1-9]+)$/) {
        my ($field, $n, $m) = ($1, $2, $3);
        return sub {
            $_[0]{'password'} = substr($_[0]{$field}, $n-1, $m-$n+1);
        };
    }
    else {
        usage;
    }
}


