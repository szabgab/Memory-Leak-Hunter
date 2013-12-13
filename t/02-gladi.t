use strict;
use warnings;

use Test::More;

use Devel::Gladiator;
use Scalar::Util qw(weaken);


plan tests => 3;

my $c0 = Devel::Gladiator::arena_ref_counts;
g() for 1..100;
my $c1 = Devel::Gladiator::arena_ref_counts;

f() for 1..100;
my $c2 = Devel::Gladiator::arena_ref_counts;

g() for 1..100;
my $c3 = Devel::Gladiator::arena_ref_counts;

#diag explain $c0;
is_deeply diff($c0, $c1), {
  'HASH' => 1,
  'REF' => 1,
  'REF-HASH' => 1,
  'SCALAR' => 19
}, '100 times weaken';

is_deeply diff($c1, $c2), {
  'HASH' => 201,
  'REF' => 201,
  'REF-HASH' => 201,
  'SCALAR' => 219
}, '100 times with memory leak';

is_deeply diff($c2, $c3), {
  'HASH' => 1,
  'REF' => 1,
  'REF-HASH' => 1,
  'SCALAR' => 19
}, '100 times weaken';


#diag explain diff($c0, $c1);
#diag explain diff($c1, $c2);



sub diff {
	my ($first, $second) = @_;
	my %diff;
	foreach my $k (keys %$second) {
		my $d = $second->{$k} - ($first->{$k} || 0);
		if ($d) {
			$diff{$k} = $d;
		}
	}
	return \%diff;
}


sub f {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
}

sub g {
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





