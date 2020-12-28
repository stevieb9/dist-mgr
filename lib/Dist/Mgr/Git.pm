package Dist::Mgr::Git;

use strict;
use warnings;
use version;

use Carp qw(croak cluck);
use Cwd qw(getcwd);
use Data::Dumper;
use Digest::SHA;
use Dist::Mgr::FileData qw(:all);
use File::Copy;
use File::Copy::Recursive qw(rmove_glob);
use File::Path qw(make_path rmtree);
use File::Find::Rule;
use Hook::Output::Tiny;
use Module::Starter;
use PPI;
use Term::ReadKey;
use Tie::File;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    git_commit
    git_push
);
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

our $VERSION = '1.00';

sub git_commit {
    my ($version) = @_;

    croak("git_commit() requires a version sent in") if ! defined $version;

    print "\nCommitting release candidate...\n";

    my $exit;

    if ( _validate_git()) {
        $exit = system("git commit -am 'Release $version candidate'");

        if ($exit != 0) {
            if ($exit == 256) {
                print "\nNothing to commit, proceeding...\n";
            }
            else {
                croak("Git commit failed... needs intervention...") if $exit != 0;
            }
        }
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub git_push {
    print "\nPushing release candidate to Github...\n";

    my $exit;

    if (_validate_git()) {
        $exit = system("git", "push");
        croak("Git push failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub _validate_git {
    my $sep = $^O =~ /win32/i ? ';' : ':';
    return grep {-x "$_/git" } split /$sep/, $ENV{PATH};
}
sub __placeholder {}

1;
__END__

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>
