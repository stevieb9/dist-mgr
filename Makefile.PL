use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Module::Bump::Version',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Module/Bump/Version.pm',
    ABSTRACT_FROM    => 'lib/Module/Bump/Version.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.010',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/module-bump-version/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/module-bump-version.git',
                web => 'https://github.com/stevieb9/module-bump-version',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'PPI'               => 0,
        'File::Find::Rule'  => 0,
        'version'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Module-Bump-Version-*' },
);
