use warnings;
use strict;
use Test::More;

use Data::Dumper;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

# bad params
{
    for ({}, sub {}, \'string') {
        is eval{github_ci($_); 1}, undef, "github_ci() croaks with param ref " . ref $_;
    }
}

# no params (default: linux, windows)
{
    my @ci = github_ci();

    is grep(/ubuntu-latest/, @ci), 1, "no param linux included ok";
    is grep (/windows-latest/, @ci), 1, "no param windows included ok";
    is grep (/macos-latest/, @ci), 0, "no param no macos included ok";
}

# windows
{
    my @ci = github_ci([qw(w)]);

    is grep(/ubuntu-latest/, @ci), 0, "no param no linux included ok";
    is grep (/windows-latest/, @ci), 1, "no param windows included ok";
    is grep (/macos-latest/, @ci), 0, "no param no macos included ok";
}

# linux
{
    my @ci = github_ci([qw(l)]);

    is grep(/ubuntu-latest/, @ci), 1, "no param linux included ok";
    is grep (/windows-latest/, @ci), 0, "no param no windows included ok";
    is grep (/macos-latest/, @ci), 0, "no param no macos included ok";
}

# macos
{
    my @ci = github_ci([qw(m)]);

    is grep(/ubuntu-latest/, @ci), 0, "no param no linux included ok";
    is grep (/windows-latest/, @ci), 0, "no param no windows included ok";
    is grep (/macos-latest/, @ci), 1, "no param macos included ok";
}

# linux, windows, macos
{
    my @ci = github_ci([qw(l w m)]);

    is grep(/ubuntu-latest/, @ci), 1, "no param linux included ok";
    is grep (/windows-latest/, @ci), 1, "no param windows included ok";
    is grep (/macos-latest/, @ci), 1, "no param macos included ok";
}

done_testing;

