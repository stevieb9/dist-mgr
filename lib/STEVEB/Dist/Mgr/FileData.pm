package STEVEB::Dist::Mgr::FileData;

use warnings;
use strict;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT = qw(
    _makefile_section_meta_merge
    _makefile_section_bugtracker
    _makefile_section_repo
    _github_ci
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

sub _github_ci {
    my ($os) = @_;

    if (! defined $os) {
        $os = [qw(l w)];
    }

    my %os_matrix_map = (
        l => qq{'ubuntu-latest'},
        w => qq{'windows-latest'},
        m => qq{'macos-latest'},
    );

    my $os_matrix = "[ ";
    $os_matrix .= join(', ', map { $os_matrix_map{$_} } @$os);
    $os_matrix .= " ]\n";

    return (
        "name: CI",
        "on:",
        "  push:",
        "    branches: [ master ]",
        "  pull_request:",
        "    branches: [ master ]",
        "  workflow_dispatch:",
        "jobs:",
        "  build:",
        "    runs-on: \${{ matrix.os }}",
        "    strategy:",
        "      matrix:",
        "        os: $os_matrix",
        "        perl: [ '5.32', '5.30' ]",
        "",
        "    name: Perl \${{ matrix.perl }} on \${{ matrix.os }}",
        "    steps:",
        "      - uses: actions/checkout\@v2",
        "      - name: Set up perl",
        "        uses: shogo82148/actions-setup-perl\@v1",
        "        with:",
        "          perl-version: \${{ matrix.perl }}",
        "      - run: perl -V",
        "      - run: cpanm --installdeps .",
        "      - run: prove -lv t",
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