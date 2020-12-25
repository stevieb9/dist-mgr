use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use File::Find::Rule;
use File::Find;
use Test::More;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);

my $work = 't/data/work';

my $mods = [qw(Test::Module)];
my $cwd = getcwd();

my %module_args = (
    author  => 'Test Author',
    email   => 'test@example.com',
    modules => $mods,
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

my $h = Hook::Output::Tiny->new;

remove_init();

# move_distribution_files()
{
    before();

    # init()

    $h->hook('stderr');
    init(%module_args);
    $h->unhook('stderr');

    # init() verify

    my @stderr = $h->stderr;
    is scalar @stderr, 11, "Module::Starter has proper print output";
    is -d 'Test-Module', 1, "Test-Module directory created ok";

    # move_distribution_files()

    my $r = move_distribution_files($mods->[0]);
    is $r, 0, "proper return from move_distribution_files()";
    is -e 'Test-Module', undef, "distribution dir was removed ok";
    like getcwd(), qr/init$/, "we're in the init dir ok";
    file_count(16);

    # remove_unwanted_files()

    remove_unwanted_files();
    file_count(12);
    check_file('lib/Test/Module.pm', qr/Test Author/, "our custom module template is in place ok");

    # manifest_skip()

    manifest_skip();
    file_count(13);
    is -e 'MANIFEST.SKIP', 1, "MANIFEST.SKIP created ok";
    check_file('MANIFEST.SKIP', qr/BB-Pass/, "it's our custom MANIFEST.SKIP ok");

    # ci_github()

    ci_github();
    file_count(16);
    is -e '.github/workflows/github_ci_default.yml', 1, "CI config in place ok";
    check_file(
        '.github/workflows/github_ci_default.yml',
        qr/PL2Bat/,
        "our custom CI config file is in place ok"
    );

    # git_ignore()

    git_ignore();
    is -e '.gitignore', 1, ".gitignore in place ok";
    check_file('.gitignore', qr/BB-Pass/, "our custom .gitignore is in place ok");

    # ci_badges()

    ci_badges('stevieb9', 'test-module', 'lib/Test/Module.pm');
    check_file('lib/Test/Module.pm', qr/=for html/, "ci_badges() has html for loop ok");
    check_file('lib/Test/Module.pm', qr/coveralls/, "ci_badges() dropped coveralls ok");
    check_file('lib/Test/Module.pm', qr/workflows/, "ci_badges() dropped github actions ok");

    # add_bugtracker()

    add_bugtracker('stevieb9', 'test-module');
    check_file('Makefile.PL', qr/META_MERGE/, "bugtrack META_MERGE added ok");
    check_file('Makefile.PL', qr/bugtracker/, "bugtracker added ok");

    # add_repository()

    add_repository('stevieb9', 'test-module');
    check_file('Makefile.PL', qr/META_MERGE/, "repo META_MERGE added ok");
    check_file('Makefile.PL', qr/repository/, "repository added ok");

    # get_version_info()

    my ($orig_ver) = values %{ (get_version_info('lib/'))[0] };
    is $orig_ver, '0.01', "original version is 0.01 ok";

    # bump_version()

    bump_version('9.66', 'lib/Test/Module.pm');
    my ($new_ver) = values %{ (get_version_info('lib/'))[0] };
    is $new_ver, '9.66', "new version is 9.66 ok";
    is(
        version->parse($new_ver) > version->parse($orig_ver),
        1,
        "$new_ver is greater than $orig_ver ok"
    );

    # Compare all files against the saved template

    is
        getcwd(),
        '/home/spek/repos/dist-mgr/t/data/work/init',
        "in the init dir ok";

    my $template_dir = "$cwd/t/data/module_template/";

    my @template_files = File::Find::Rule->file()
        ->name('*')
        ->in($template_dir);

    my $file_count = 0;

    for my $tf (@template_files) {
        (my $nf = $tf) =~ s/$template_dir//;

        if (-f $nf) {
            open my $tfh, '<', $tf or die $!;
            open my $nfh, '<', $nf or die $!;

            my @tf = <$tfh>;
            my @nf = <$nfh>;

            close $tfh;
            close $nfh;

            for (0 .. $#tf) {
                is $nf[$_], $tf[$_], "$nf file matches the template $tf ok";
            }
            $file_count++;
        }
    }

    is scalar @template_files, $file_count, "file count matches number of files in template";

    # Cleanup

    after();
}

remove_init() if getcwd() !~ /init$/;

done_testing;

sub before {
    like $cwd, qr/dist-mgr/, "in proper directory ok";

    chdir $work or die $!;
    like getcwd(), qr/$work$/, "in $work directory ok";

    if (! -d 'init') {
        mkdir 'init' or die $!;
    }

    is -d 'init', 1, "'init' dir created ok`";

    chdir 'init' or die $!;
    like getcwd(), qr/$work\/init$/, "in $work/init directory ok";
}
sub after {
    chdir $cwd or die $!;
    like getcwd(), qr/dist-mgr/, "back in root directory ok";
}
sub file_count {
    my ($expected_count) = @_;
    my $fs_entry_count;
    find (sub {$fs_entry_count++;}, '.');
    is $fs_entry_count, $expected_count, "$expected_count of files after initial move";
}
sub check_file {
    my ($file, $regex, $msg) = @_;
    open my $fh, '<', $file or die $!;
    my @contents = <$fh>;
    close $fh;
    is grep(/$regex/, @contents) >= 1, 1, $msg;
}
