use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
plan tests => 2;

my @cases = (
	{
		code   => '',
		rebase => {},
		name   => 'base',
	},
	{
	}
);


my $dir = tempdir( CLEANUP => 1 );
my $file = "$dir/code";

my %base;
{
	open my $fh, '<', 't/base.txt' or die;
	local $/ = undef;
	my $expected = <$fh>;
	%base = $expected =~ /([A-Za-z:-]+)\s+(\d+)/g
}
#diag explain \%base;

#diag explain run_gladiator('');

is_deeply run_gladiator(''), \%base, 'base';

is_deeply run_gladiator('my $x;'), rebase( SCALAR => 2 ), 'my $x;';
#diag explain run_gladiator('my $x;');

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
	my %add = @_;
	my %data = %base;
	$data{$_} += $add{$_} for keys %add;
	return \%data;
}
