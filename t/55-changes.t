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

my $module_starter_changes_md5 = '1f0e16f293c340668219a937272f0d2c';

my $work = 't/data/work';
my $orig_changes = 't/data/orig/Changes';
my $tpl = "t/data/module_template/Changes"; # Custom one created by this dist

# MD5 & content comparisons
{
    copy_changes();
#    is
#        md5sum("$work/Changes"),
#        $module_starter_changes_md5,
#        "Changes file created by Module::Starter MD5 match ok";

#    file_compare("$work/Changes", $orig_changes);

    changes('Test::Module', $work);

#    isnt
#        md5sum("$work/Changes"),
#        $module_starter_changes_md5,
#        "Changes updated has different MD5 as the template ok";

    file_compare("$work/Changes", $tpl);

#    unlink_changes();
}

#unlink_changes();

done_testing;

sub file_compare {
    my ($gen, $save) = @_;

    open my $gen_fh, '<', $gen or croak("Can't open $gen: $!");
    open my $save_fh, '<', $save or croak("Can't open $save: $!"); # 'original' custom

    my @gen = <$gen_fh>;
    my @save = <$save_fh>;

    close $gen_fh or die $!;
    close $save_fh or die $!;

    for (0..$#gen) {
        is $gen[$_], $save[$_], "Updated Changes file line $_ matches template custom ok";
    }
}
