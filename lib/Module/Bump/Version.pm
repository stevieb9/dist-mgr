package Module::Bump::Version;

use strict;
use warnings;
use version;

use Carp qw(croak);
use Data::Dumper;
use File::Find::Rule;
use PPI;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bump_version get_version);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '0.01';

my $default_dir = 'lib/';

sub bump_version {
    my ($version, $dir) = @_;

    _validate_version($version);
    _validate_dir($dir);

    my @module_files = _find_modules($dir);

    for (@module_files) {
        printf "%s\n", _find_version_line($_);
    }
}
sub get_version {
    my ($dir) = @_;

    _validate_dir($dir);

    my @module_files = _find_modules($dir);

    my %version_info;

    for (@module_files) {
        my $version = _find_version($_);
        $version_info{$_} = $version;
    }

    return \%version_info;
}
sub _find_modules {
    my ($dir) = @_;

    $dir //= $default_dir;

    return File::Find::Rule->file()
                            ->name('*.pm')
                            ->in($dir);
}
sub _find_version {
    my ($module_file) = @_;

    my $version_line = _find_version_line($module_file);

    if ($version_line =~ /=(.*)$/) {
        my $ver = $1;

        $ver =~ s/\s+//g;
        $ver =~ s/;//g;
        $ver =~ s/[:alpha:]+//g;
        $ver =~ s/"//g;
        $ver =~ s/'//g;

        if (! defined eval { version->parse($ver); 1 }) {
            croak("Can't find a valid version in file '$_'");
        }

        return $ver;
    }
}
sub _find_version_line {
    my ($module_file) = @_;

    my $doc = PPI::Document->new($module_file);

    my $version_line = (
        $doc->find(
            sub {
                $_[1]->isa("PPI::Statement::Variable")
                    and $_[1]->content =~ /\$VERSION/;
            }
        )
    )->[0]->content;

    return $version_line;
}
sub _validate_dir {
    return if ! defined $_[0];
    croak("Directory '$_[0]' is invalid") if ! -d $_[0];
}
sub _validate_version {
    my ($version) = @_;

    croak("version parameter must be supplied!") if ! defined $version;

    if (! defined eval { version->parse($version); 1 }) {
        croak("The version number '$version' specified is invalid");
    }
}

1;
__END__

=head1 NAME

Module::Bump::Version - Prepare a Perl distribution for its next release cycle

=head1 DESCRIPTION

=head1 SYNOPSIS

    use Module::Bump::Version;

=head1 FUNCTIONS

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
