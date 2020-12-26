use warnings;
use strict;
use feature 'say';

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

my $mod_dir = 'Test-Module';
my $work_dir = 't/data/work';
my $init_dir = "$work_dir/init";
my $orig = "$cwd/t/data/orig/Changes"; # Custom one created by this dist

my $h = Hook::Output::Tiny->new;

remove_init();
mkdir_init();

# from initial creation
{
    # Change into 'init' dir

    chdir $init_dir or die $!;
    like getcwd(), qr|dist-mgr/$init_dir$|, "in init dir ok";
    die "not in the init dir" if getcwd() !~ m|dist-mgr/$init_dir$|;

    $h->hook;
    init(module_args());
    $h->unhook;

    # Change into module dir

    chdir $mod_dir or die $!;
    like getcwd(), qr|dist-mgr/$init_dir/$mod_dir$|, "in module dir ok";
    die "not in the init dir" if getcwd() !~ m|dist-mgr/$init_dir/$mod_dir$|;

    is
        md5sum('Changes'),
        $module_starter_changes_md5,
        "Changes file created by Module::Starter MD5 match ok";

    changes('Test::Module', 'Changes');

    isnt
        md5sum('Changes'),
        $module_starter_changes_md5,
        "Changes updated has different MD5 as the template ok";

    file_compare('Changes', $orig);

    unlink_changes();
}

chdir $cwd or die $!;
is getcwd(), $cwd, "in $cwd dir ok";
die "not in cwd" if getcwd() ne $cwd;

remove_init();

done_testing;

sub file_compare {
    my ($new, $orig) = @_;

    open my $new_fh, '<', $new or die $!;
    open my $orig_fh, '<', $orig or die $!; # 'original' custom

    my @new = <$new_fh>;
    my @orig = <$orig_fh>;

    close $new_fh or die $!;
    close $orig_fh or die $!;

    for (0..$#new) {
        is $new[$_], $orig[$_], "Updated Changes file line $_ matches template custom ok";
    }
}
