use warnings;
use strict;
use Test::More;

use Data::Dumper;
use STEVEB::Dist::Mgr qw(:all);

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';
my $orig = 't/data/orig';

my $live_file = ".github/workflow/github_ci_default.yml";

unlink_ci_files();
copy_ci_files();

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

    my $os_line = "        os: [ 'ubuntu-latest', 'windows-latest' ]";
    compare_contents('none', $os_line, @ci);
    clean();
}

# windows
{
    my @ci = github_ci([qw(w)]);

    is grep(/ubuntu-latest/, @ci), 0, "no param no linux included ok";
    is grep (/windows-latest/, @ci), 1, "no param windows included ok";
    is grep (/macos-latest/, @ci), 0, "no param no macos included ok";

    my $os_line = "        os: [ 'windows-latest' ]";
    compare_contents('w', $os_line, @ci);
    clean();
}

# linux
{
    my @ci = github_ci([qw(l)]);

    is grep(/ubuntu-latest/, @ci), 1, "no param linux included ok";
    is grep (/windows-latest/, @ci), 0, "no param no windows included ok";
    is grep (/macos-latest/, @ci), 0, "no param no macos included ok";

    my $os_line = "        os: [ 'ubuntu-latest' ]";
    compare_contents('l', $os_line, @ci);
    clean();
}

# macos
{
    my @ci = github_ci([qw(m)]);

    is grep(/ubuntu-latest/, @ci), 0, "no param no linux included ok";
    is grep (/windows-latest/, @ci), 0, "no param no windows included ok";
    is grep (/macos-latest/, @ci), 1, "no param macos included ok";

    my $os_line = "        os: [ 'macos-latest' ]";
    compare_contents('m', $os_line, @ci);
    clean();
}

# linux, windows, macos
{
    my @ci = github_ci([qw(l w m)]);

    is grep(/ubuntu-latest/, @ci), 1, "no param linux included ok";
    is grep (/windows-latest/, @ci), 1, "no param windows included ok";
    is grep (/macos-latest/, @ci), 1, "no param macos included ok";

    my $os_line = "        os: [ 'ubuntu-latest', 'windows-latest', 'macos-latest' ]";
    compare_contents('l w m', $os_line, @ci);
    clean();
}

# Let's put back a file for production, shall we? ;)

github_ci([qw(l w m)]);

sub clean {
    is -e $live_file, 1, "CI file created ok";
    unlink $live_file or die $!;
    is -e $live_file, undef, "CI file removed ok";
}
sub contents {
    open my $fh, '<', $orig or die $!;
    my @contents = <$fh>;
    return @contents;
}
sub compare_contents {
    my ($params, $os_line, @new) = @_;

    my @orig = contents();

    for my $i (0..$#orig) {
        chomp $orig[$i];
        chomp $new[$i];
        $orig[$i] =~ s/^"//;
        $orig[$i] =~ s/",$//;

        if ($new[$i] =~ /^\s+os: \[/) {
            is $new[$i], $os_line, "OS matrix ok for params '$params'";
            next;
        }
        is $new[$i], $orig[$i], "CI file line '$i' with params '$params' matches ok";
    }
}

done_testing;

