use strict;
use warnings;

use Test::More;

use Devel::Gladiator;
use Scalar::Util qw(weaken);

use Memory::Leak::Hunter;


plan tests => 8;

my $c0 = Devel::Gladiator::arena_ref_counts;
good() for 1..100;
my $c1 = Devel::Gladiator::arena_ref_counts;

leak() for 1..100;
my $c2 = Devel::Gladiator::arena_ref_counts;

good() for 1..100;
my $c3 = Devel::Gladiator::arena_ref_counts;

#diag explain $c0;

is_deeply Memory::Leak::Hunter::_diff($c0, $c1), {
  'HASH' => 1,
  'REF' => 1,
  'REF-HASH' => 1,
  'SCALAR' => 19
}, '100 times weaken';

is_deeply Memory::Leak::Hunter::_diff($c1, $c2), {
  'HASH' => 201,
  'REF' => 201,
  'REF-HASH' => 201,
  'SCALAR' => 219
}, '100 times with memory leak';

is_deeply Memory::Leak::Hunter::_diff($c2, $c3), {
  'HASH' => 1,
  'REF' => 1,
  'REF-HASH' => 1,
  'SCALAR' => 19
}, '100 times weaken';

my $mlh = Memory::Leak::Hunter->new;
$mlh->record('start');
$mlh->record('second');
is_deeply $mlh->last_diff, {'REF-HASH' => 2, SCALAR => 24, HASH => 2, REF => 2}, 'self';
$mlh->record('third');
is_deeply $mlh->last_diff, {SCALAR => 29, REF => 3, 'REF-HASH' => 3,HASH => 3}, 'self + is_deeply';
good();
is_deeply $mlh->last_diff, {'REF-HASH' => 3, HASH => 3, REF => 3, SCALAR => 29}, 'good';

leak();
is_deeply $mlh->last_diff, {HASH => 3, REF => 3, SCALAR => 29, 'REF-HASH' => 3}, 'leak';




my $records = $mlh->records;
isa_ok $records, 'ARRAY';

#diag explain $records;
my $report = $mlh->report;
#diag $report;


sub leak {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
}

sub good {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
	weaken $y->{partner};
}

