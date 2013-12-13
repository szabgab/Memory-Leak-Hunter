use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;

my $code1 = <<'CODE';
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

CODE

my $code2 = $code1 . 'f();';
my $code3 = $code1 . 'f() for 1..100;';

my $code11 = <<'CODE';
use Scalar::Util qw(weaken);
sub f {
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

CODE


my @cases = (
	{
		code   => '',
		rebase => {},
		name   => 'base',
	},
	{
		code   => 'my $x;',
		rebase => { SCALAR => 2 },
		name   => 'one scalar',
	},
	{
		code   => '{ my $x; }',
		rebase => { SCALAR => 2 },
		name   => 'one scalar in block',
	},
	{
		code   => 'my $x = "abcd";',
		rebase => { SCALAR => 3 },
		name   => 'one scalar with scalar value',
	},
	{
		code   => '{my $x = "abcd";}',
		rebase => { SCALAR => 3 },
		name   => 'one scalar with scalar value in scope',
	},
	{
		code   => 'my $x = 1; $x++;',
		rebase => { SCALAR => 4 },
		name   => 'one scalar with scalar value',
	},
	{
		code   => 'my @x;',
		rebase => { SCALAR => 1, ARRAY => 1 },
		name   => 'one array',
	},
	{
		code   => 'my $x = [];',
		rebase => { SCALAR => 1, ARRAY => 1, REF => 1, 'REF-ARRAY' => 1 },
		name   => 'one array ref',
	},
	{
		code   => 'my %x;',
		rebase => { SCALAR => 1, HASH => 1 },
		name   => 'one hash',
	},
	{
		code   => 'my $x = {};',
		rebase => { SCALAR => 1, HASH => 1, 'REF-HASH' => 1, 'REF' => 1 },
		name   => 'one hash ref',
	},
	{
		code   => $code1,
		rebase => { SCALAR => 12, ARRAY => 2, CODE => 1, GLOB => 1 },
		name   => 'function',
	},
	{
		code   => $code2,
		rebase => { SCALAR => 15, ARRAY => 2, 'REF-HASH' => 2, REF => 2, HASH => 2, 
			CODE => 1, GLOB => 1 },
		name   => 'function + call once',
	},
	{
		code   => $code3,
		rebase => { SCALAR => 217, ARRAY => 2, 'REF-HASH' => 200, REF => 200, HASH => 200, 
			CODE => 1, GLOB => 1 },
		name   => 'function + call 100 times',
	},
	{
		code   => $code11,
		rebase => { REGEXP => 2, REF => 1, 'REF-HASH' => 1, HASH => 7,
			SCALAR => 122, ARRAY => 25, CODE => 31, GLOB => 53 },
		name   => 'function with weaken',
	},
);

plan tests => scalar @cases;

my $dir = tempdir( CLEANUP => 1 );
my $file = "$dir/code";

my $base = run_gladiator('');
#diag explain $base;

foreach my $c (@cases) {
	#diag explain run_gladiator($c->{code});
	is_deeply run_gladiator($c->{code}), rebase($c->{rebase}), $c->{name};
}


sub run_gladiator {
	my ($code) = @_;

	open my $fh, '>', $file or die;
	print $fh "$code\n";
	print $fh q{use Devel::Gladiator qw(arena_ref_counts);}  . "\n";
	print $fh q{print Devel::Gladiator::arena_table;} . "\n";
	close $fh;

	my @out = `$^X $file`;
	chomp @out;
	shift @out;
	my %out =  map { /(\d+)\s+(\S+)/; $2, $1 } @out;
	return \%out;
}

sub rebase {
	my ($add) = @_;
	my %data = %$base;
	$data{$_} += $add->{$_} for keys %$add;
	return \%data;
}
