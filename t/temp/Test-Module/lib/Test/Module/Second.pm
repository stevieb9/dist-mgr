package Test::Module::Second;

use warnings;
use strict;

our $VERSION = '0.01';

sub dummy {
    print "Test::Module::Second\n";
}

1;
__END__

=head1 NAME

One - The crappy ol' One module

=for html
<a href="https://github.com/stevieb9/test-module/actions"><img src="https://github.com/stevieb9/test-module/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/test-module?branch=master'><img src='https://coveralls.io/repos/stevieb9/test-module/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>


=head1 SYNOPSIS

    use One;
    ...

=head1 DESCRIPTION

This module does something, but I forget what

=head1 FUNCTIONS

=head2 dummy

This sub does something
