use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;

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
