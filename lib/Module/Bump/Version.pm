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
our @EXPORT = qw(bump_version);

our $VERSION = '0.01';

my $default_dir = 'lib/';

sub bump_version {
    my ($version, $dir) = @_;

    _validate_version($version);
    _validate_dir($dir);

    my @module_files = _find_modules($dir);

    print Dumper \@module_files;
}
sub _find_modules {
    my ($dir) = @_;

    $dir //= $default_dir;

    return File::Find::Rule->file()
                            ->name('*.pm')
                            ->in($dir);
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
