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
    _git_add
    _git_commit
    _git_push
    _git_pull
    _git_release
    _git_tag
);
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
);

our $VERSION = '1.00';

my $spinner_count;

sub _git_add {
    print "\nGit adding files...\n";

    my $exit;

    if (_validate_git()) {
        $exit = system("git", "add", ".");
        croak("Git add failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub _git_commit {
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
sub _git_pull {
    print "\nPulling updates from repository...\n";

    my $exit;

    if (_validate_git()) {
        $exit = system("git", "pull");
        croak("Git pull failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub _git_push {
    print "\nPushing release candidate to Github...\n";

    my $exit;

    if (_validate_git()) {
        $exit = system("git", "push");
        $exit = system("git", "push", "--tags");
        croak("Git push failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub _git_release {
    my ($version, $wait_for_ci) = @_;

    croak("git_release() requires a version sent in") if !defined $version;

    $wait_for_ci //= 1;

    _git_pull();
    _git_commit($version);
    _git_push();

    if ($wait_for_ci) {
        `clear`;

        print "\n\nWaiting for CI tests to complete.\n\n";
        print "Hit ENTER on failure, and CTRL-C to continue on...\n\n";

        local $| = 1;

        my $interrupt = 0;
        $SIG{INT} = sub {$interrupt = 1;};

        my $key = '';

        do {
            _wait_spinner("Waiting: ");
            $key = ReadKey(-1);
        }
            until ($interrupt || defined $key && $key eq "\n");

        if ($interrupt) {
            print "\nTests pass, continuing with release\n";
            return 0;
        }
        else {
            print "\nTests failed, halting progress\n";
            return -1;
        }
    }
}
sub _git_tag {
    my ($version) = @_;

    croak("git_tag() requires a version sent in") if ! defined $version;

    print "\nCreating release tag v$version...\n";

    my $exit;

    if (_validate_git()) {
        $exit = system("git", "tag", "v$version");

       # croak("Git tag failed... needs intervention...") if $exit != 0;
    }
    else {
        warn "'git' not installed, can't commit\n";
        $exit = -1;
    }

    return $exit;
}
sub _wait_spinner {
    my ($msg) = @_;

    croak("_wait_spinner() needs a message sent in") if ! $msg;

    $spinner_count //= 0;
    my $num = 20 - $spinner_count;
    my $spinner = '.' x $spinner_count . ' ' x $num;
    $spinner_count++;
    $spinner_count = 0 if $spinner_count == 20;
    print STDERR "$msg: $spinner\r";
    select(undef, undef, undef, 0.1);
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
