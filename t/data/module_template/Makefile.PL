use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::Module',
    AUTHOR           => q{Test Author <test@example.com>},
    VERSION_FROM     => 'lib/Test/Module.pm',
    ABSTRACT_FROM    => 'lib/Test/Module.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/test-module.git',
                web => 'https://github.com/stevieb9/test-module',
            },
            bugtracker => {
                web => 'https://github.com/stevieb9/test-module/issues',
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
        #'ABC'              => '1.6',
        #'Foo::Bar::Module' => '5.0401',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-Module-*' },
);
