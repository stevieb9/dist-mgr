use warnings;
use strict;
use Test::More;

use Module::Bump::Version;

is eval { bump_version('aaa'); 1 }, undef, "invalid version croaks ok";

done_testing();

