use warnings;
use strict;
use feature 'say';

use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);
use Hook::Output::Tiny;

my $cwd = getcwd();
like $cwd, qr/dist-mgr$/, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr$/;

my $module_starter_changes_sha = 'a2da9f4316e1d8942a214038f2136363bb4940b6';

my $work = 't/data/work';
my $orig_changes = 't/data/orig/Changes';
my $tpl = "t/data/module_template/Changes"; # Custom one created by this dist

unlink_changes();

# MD5 & content comparisons
{
    copy_changes();

    is
        sha1sum("$work/Changes"),
        $module_starter_changes_sha,
        "Changes file created by Module::Starter SHA match ok";

    file_compare("$work/Changes", $orig_changes);

    changes('Test::Module', $work);

    isnt
        sha1sum("$work/Changes"),
        $module_starter_changes_sha,
        "Changes updated has different SHA as the template ok";

    file_compare("$work/Changes", $tpl);

    unlink_changes();
}

unlink_changes();

done_testing;