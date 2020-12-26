package Dist::Mgr;

use strict;
use warnings;
use version;

use Carp qw(croak cluck);
use Cwd qw(getcwd);
use Data::Dumper;
use Dist::Mgr::FileData;
use File::Copy;
use File::Copy::Recursive qw(rmove_glob);
use File::Path qw(make_path rmtree);
use File::Find::Rule;
use Module::Starter;
use PPI;
use Tie::File;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    add_bugtracker
    add_repository
    changes
    changes_bump
    ci_badges
    ci_github
    get_version_info
    git_ignore
    init
    manifest_skip
    move_distribution_files
    remove_unwanted_files
    version_bump
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = '1.00';

use constant {
    GITHUB_CI_FILE      => 'github_ci_default.yml',
    GITHUB_CI_PATH      => '.github/workflows/',
    CHANGES_FILE        => 'Changes',
    CHANGES_ORIG_MD5    => '1f0e16f293c340668219a937272f0d2c', # Module::Starter version
    FSTYPE_IS_DIR       => 1,
    FSTYPE_IS_FILE      => 2,
    DEFAULT_DIR         => 'lib/',
};

# Public

sub add_bugtracker {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_bugtracker(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_bugtracker($author, $repo, $makefile);
}
sub add_repository {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_repository(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_repository($author, $repo, $makefile);
}
sub changes {
    my ($module, $dir) = @_;

    croak("changes() needs a module parameter") if ! defined $module;

    $dir //= '.';

    # Overwrite the Changes file if the MD5 checksum matches the original file
    # created with module-starter

    my @contents;

    if (_md5sum("$dir/Changes") eq CHANGES_ORIG_MD5) {
        @contents = _changes_file($module);
        _changes_write_file($dir, \@contents);
    }

    return @contents;
}
sub changes_bump {}
sub ci_badges {
    if (scalar @_ != 3) {
        croak("ci_badges() needs \$author, \$repo and \$fs_entry sent in");
    }

    my ($author, $repo, $fs_entry) = @_;

    for (_module_find_files($fs_entry)) {
        _module_insert_ci_badges($author, $repo, $_);
    }

    return 0;
}
sub ci_github {
    my ($os) = @_;

    if (defined $os && ref $os ne 'ARRAY') {
        croak("\$os parameter to github_ci() must be an array ref");
    }

    my @contents = _ci_github_file($os);
    _ci_github_write_file(\@contents);

    return @contents;
}
sub get_version_info {
    my ($fs_entry) = @_;

    _validate_fs_entry($fs_entry);

    my @module_files = _module_find_files($fs_entry);

    my %version_info;

    for (@module_files) {
        my $version = _module_extract_file_version($_);
        $version_info{$_} = $version;
    }

    return \%version_info;
}
sub git_ignore {
    my ($dir) = @_;

    $dir //= '.';

    my @content = _git_ignore_file();

    _git_ignore_write_file($dir, \@content);

    return @content;
}
sub init {
    my (%args) = @_;

    my $cwd = getcwd();

    if ($cwd =~ /dist-mgr$/) {
        croak "Can't run init() while in the '$cwd' directory";
    }

    $args{license} = 'artistic2' if ! exists $args{license};
    $args{builder} = 'ExtUtils::MakeMaker';

    for (qw(modules author email)) {
        if (! exists $args{$_}) {
            croak("init() requires '$_' in the parameter hash");
        }
    }

    if (ref $args{modules} ne 'ARRAY') {
        croak("init()'s 'modules' parameter must be an array reference");
    }

    Module::Starter->create_distro(%args);

    my ($module) = (@{ $args{modules} })[0];
    my $module_file = $module;
    $module_file =~ s/::/\//g;
    $module_file = "lib/$module_file.pm";

    my $module_dir = $module;
    $module_dir =~ s/::/-/g;

    chdir $module_dir or croak("Can't change into directory '$module_dir'");

    unlink $module_file
        or croak("Can't delete the Module::Starter module '$module_file': $!");

    _module_write_template($module_file, $module, $args{author}, $args{email});

    chdir '..' or croak "Can't change into original directory";
}
sub manifest_skip {
    my ($dir) = @_;

    $dir //= '.';

    my @content = _manifest_skip_file();

    _manifest_skip_write_file($dir, \@content);

    return @content;
}
sub move_distribution_files {
    my ($module) = @_;

    if (! defined $module) {
        croak("_move_distribution_files() requires a module name sent in");
    }

    my $module_dir = $module;
    $module_dir =~ s/::/-/g;

    my @move_count = rmove_glob("$module_dir/*", '.')
        or croak("Can't move files from the '$module_dir' directory: $!");

    my $dist_count = _default_distribution_file_count();

    for my $outer_idx (0..$#move_count) {
        my $outer = $move_count[$outer_idx];
        for my $inner_idx (0..$#$outer) {
            my $inner = $move_count[$outer_idx][$inner_idx];
            for (0..$#$inner) {
                if ($inner->[$_] != $dist_count->[$outer_idx][$inner_idx][$_]) {
                    croak("Results from the move are mismatched... bailing out");
                }
            }
        }
    }

    rmtree $module_dir or croak("Couldn't remove the '$module_dir' directory");

    return 0;
}
sub remove_unwanted_files {
    for (_unwanted_filesystem_entries()) {
        rmtree $_;
    }

    return 0;
}
sub version_bump {
    my ($version, $fs_entry) = @_;

    my $dry_run = 0;

    if (defined $version && $version =~ /^-/) {
        print "\nDry run\n\n";
        $version =~ s/-//;
        $dry_run = 1;
    }

    _validate_version($version);
    _validate_fs_entry($fs_entry);

    my @module_files = _module_find_files($fs_entry);

    my %files;

    for (@module_files) {
        my $current_version = _module_extract_file_version($_);
        my $version_line    = _module_extract_file_version_line($_);
        my @file_contents   = _module_fetch_file_contents($_);

        if (! defined $version_line) {
            next;
        }

        if (! defined $current_version) {
            next;
        }

        if (version->parse($current_version) >= version->parse($version)) {
            croak(
                "Your new version $version must be greater than the current " .
                    "one, $current_version"
            );
        }

        my $mem_file;

        open my $wfh, '>', \$mem_file or croak("Can't open mem file!: $!");

        for my $line (@file_contents) {
            chomp $line;

            if ($line eq $version_line) {
                $line =~ s/$current_version/$version/;
            }

            $line .= "\n";

            # Write out the line to the in-memory temp file
            print $wfh $line;

            $files{$_}{from}    = $current_version;
            $files{$_}{to}      = $version;
        }

        close $wfh;

        $files{$_}{dry_run} = $dry_run;
        $files{$_}{content} = $mem_file;

        if (! $dry_run) {
            # Write out the actual file
            _module_write_file($_, $mem_file);
        }
    }
    return \%files;
}

# Changes file related

sub _changes_write_file {
    # Writes out the custom Changes file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/Changes" or cluck("Can't open file $dir/Changes: $!");

    for (@$content) {
        print $fh "$_\n"
    }

    close $fh;

    return 0;
}

# CI related

sub _ci_github_write_file {
    # Writes out the Github Actions config file

    my ($contents) = @_;

    if (ref $contents ne 'ARRAY') {
        croak("_ci_github_write_file() requires an array ref of contents");
    }

    my $ci_file //= GITHUB_CI_PATH . GITHUB_CI_FILE;

    make_path(GITHUB_CI_PATH) if ! -d GITHUB_CI_PATH;

    open my $fh, '>', $ci_file or croak $!;

    print $fh "$_\n" for @$contents;
}

# Distribution related

sub _default_distribution_file_count {
    # Returns the file count in a distribution
    # This is used to ensure everything moved OK

    return [
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [3, 2, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [5, 1, 0] ],
        [ [2, 1, 0] ],
    ];
}

# Git related

sub _git_ignore_write_file {
    # Writes out the .gitignore file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/.gitignore" or croak $!;

    for (@$content) {
        print $fh "$_\n"
    }

    return 0;
}

# Makefile related

sub _makefile_tie {
    # Ties the Makefile.PL file to an array

    my ($mf) = @_;
    croak("_makefile_tie() needs a Makefile name sent in") if ! defined $mf;

    my $tie = tie my @mf, 'Tie::File', $mf;
    return (\@mf, $tie);
}
sub _makefile_insert_meta_merge {
    # Inserts the META_MERGE section into Makefile.PL

    my ($mf) = @_;

    croak("_makefile_insert_meta_merge() needs a Makefile tie sent in") if ! defined $mf;

    # Check to ensure we're not duplicating
    return if grep /META_MERGE/, @$mf;

    for (0..$#$mf) {
        if ($mf->[$_] =~ /MIN_PERL_VERSION/) {
            splice @$mf, $_+1, 0, _makefile_section_meta_merge();
            last;
        }
    }
}
sub _makefile_insert_bugtracker {
    # Inserts bugtracker information into Makefile.PL

    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_bugtracker() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_tie($makefile);

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
        if ($mf->[$_] =~ /resources   => \{/) {
            splice @$mf, $_+1, 0, _makefile_section_bugtracker($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}
sub _makefile_insert_repository {
    # Inserts repository information to Makefile.PL

    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_repository() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_tie($makefile);

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
        if ($mf->[$_] =~ /resources   => \{/) {
            splice @$mf, $_+1, 0, _makefile_section_repo($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}

# MANIFEST.SKIP related

sub _manifest_skip_write_file {
    # Writes out the MANIFEST.SKIP file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/MANIFEST.SKIP" or croak $!;

    for (@$content) {
        print $fh "$_\n"
    }

    return 0;
}

# Module related

sub _module_extract_file_version {
    # Extracts the version number from a module's $VERSION definition line

    my ($module_file) = @_;

    my $version_line = _module_extract_file_version_line($module_file);

    if (defined $version_line) {

        if ($version_line =~ /=(.*)$/) {
            my $ver = $1;

            $ver =~ s/\s+//g;
            $ver =~ s/;//g;
            $ver =~ s/[a-zA-Z]+//g;
            $ver =~ s/"//g;
            $ver =~ s/'//g;

            if (! defined eval { version->parse($ver); 1 }) {
                warn("$_: Can't find a valid version\n");
                return undef;
            }

            return $ver;
        }
    }
    else {
        warn("$_: Can't find a \$VERSION definition\n");
    }
    return undef;
}
sub _module_extract_file_version_line {
    # Extracts the $VERSION definition line from a module file

    my ($module_file) = @_;

    my $doc = PPI::Document->new($module_file);

    my $token = $doc->find(
        sub {
            $_[1]->isa("PPI::Statement::Variable")
                and $_[1]->content =~ /\$VERSION/;
        }
    );

    return undef if ref $token ne 'ARRAY';

    my $version_line = $token->[0]->content;

    return $version_line;
}
sub _module_fetch_file_contents {
    # Fetches the file contents of a module file

    my ($file) = @_;

    open my $fh, '<', $file
      or croak("Can't open file '$file' for reading!: $!");

    my @contents = <$fh>;
    close $fh;
    return @contents;
}
sub _module_find_files {
    # Finds module files

    my ($fs_entry, $module) = @_;

    $fs_entry //= DEFAULT_DIR;

    if (defined $module) {
        $module =~ s/::/\//g;
        $module .= '.pm';
    }
    else {
        $module = '*.pm';
    }


    return File::Find::Rule->file()
        ->name($module)
        ->in($fs_entry);
}
sub _module_insert_ci_badges {
    # Inserts the CI and Coveralls badges into POD

    my ($author, $repo, $module_file) = @_;

    my ($mf, $tie) = _module_tie($module_file);

    for (0..$#$mf) {
        if ($mf->[$_] =~ /^=head1 NAME/) {
            splice @$mf, $_+3, 0, _module_section_ci_badges($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}
sub _module_tie {
    # Ties a module file to an array

    my ($mod_file) = @_;
    croak("Test::Module() needs a module file name sent in") if ! defined $mod_file;

    my $tie = tie my @mf, 'Tie::File', $mod_file;
    return (\@mf, $tie);
}
sub _module_write_file {
    # Writes out a Perl module file

    my ($module_file, $content) = @_;

    open my $wfh, '>', $module_file or croak("Can't open '$module_file' for writing!: $!");

    print $wfh $content;

    close $wfh or croak("Can't close the temporary memory module file!: $!");
}
sub _module_write_template {
    # Writes out our custom module template after init()

    my ($module_file, $module, $author, $email) = @_;

    if (! defined $module_file) {
        croak("_module_write_template() needs the module's file name sent in");
    }

    if (! defined $module || ! defined $author || ! defined $email) {
        croak("_module_template_file() requires 'module', 'author' and 'email' parameters");
    }

    my @content = _module_template_file($module, $author, $email);

    open my $wfh, '>', $module_file or croak("Can't open '$module_file' for writing!: $!");

    print $wfh "$_\n" for @content;
}

# Validation related

sub _md5sum {
    my ($file) = @_;

    croak "md5sum needs a file param" if ! defined $file;

    my $md5 = Digest::MD5->new;
    open my $fh, '<', $file or croak "Can't open file $file: $!";
    binmode $fh;
    return $md5->addfile($fh)->hexdigest();
}
sub _validate_fs_entry {
    # Validates a file system entry as valid

    my ($fs_entry) = @_;

    cluck("Need name of dir or file!") if ! defined $fs_entry;

    return FSTYPE_IS_DIR    if -d $fs_entry;
    return FSTYPE_IS_FILE   if -f $fs_entry;

    croak("File system entry '$fs_entry' is invalid");
}
sub _validate_version {
    # Parses a version number to ensure it is valid

    my ($version) = @_;

    croak("version parameter must be supplied!") if ! defined $version;

    if (! defined eval { version->parse($version); 1 }) {
        croak("The version number '$version' specified is invalid");
    }
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
