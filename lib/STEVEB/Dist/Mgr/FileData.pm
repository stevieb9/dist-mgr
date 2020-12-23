package STEVEB::Dist::Mgr::FileData;

use warnings;
use strict;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
    _makefile_section_meta_merge
    _makefile_section_bugtracker
    _makefile_section_repo

    _travis_ci
);

sub _makefile_section_meta_merge {
    return (
        "    META_MERGE => {",
        "        'meta-spec' => { version => 2 },",
        "        resources   => {",
        "        },",
        "    },"
    );
}
sub _makefile_section_bugtracker {
    my ($author, $repo) = @_;

    return (
        "            bugtracker => {",
        "                web => 'https://github.com/$author/$repo/issues',",
        "            },"
    );

}
sub _makefile_section_repo {
    my ($author, $repo) = @_;

    return (
        "            repository => {",
        "                type => 'git',",
        "                url => 'https://github.com/$author/$repo.git',",
        "                web => 'https://github.com/$author/$repo',",
        "            },"
    );

}

sub _travis_ci {
    return (
        'language: perl',
        'perl:',
        '    - "5.32"',
        '    - "5.30"',
        '    - "5.24"',
        '    - "5.20"',
        '    - "5.18"',
        '    - "5.14"',
        '    - "5.12"',
        '    - "5.10"',
        '',
        'os:',
        '   - linux',
        '',
        'before_install:',
        '  - git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers',
        '  - source ~/travis-perl-helpers/init',
        '  - build-perl',
        '  - perl -V',
        '  - build-dist',
        '  - cd $BUILD_DIR             # $BUILD_DIR is set by the build-dist command',
        '',
        'install:',
        '  - cpan-install Devel::Cover',
        '  - cpan-install --deps       # installs prereqs, including recommends',
        '  - cpan-install --coverage   # installs converage prereqs, if enabled',
        '',
        'before_script:',
        '  - coverage-setup',
        '',
        'script:',
        '  - PERL5OPT=-MDevel::Cover=-coverage,statement,branch,condition,path,subroutine prove -lrv t',
        '  - cover',
        '',
        'after_success:',
        '  - cover -report coveralls',
        '  - coverage-report',
        '',
        'matrix:',
        '  include:',
        '    - perl: 5.20',
        '      env: COVERAGE=1',
    );
}

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