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
		code   => 'my $x;',
		rebase => { SCALAR => 2 },
		name   => 'one scalar',
	}
);


my $dir = tempdir( CLEANUP => 1 );
my $file = "$dir/code";

#my %base;
#{
#	open my $fh, '<', 't/base.txt' or die;
#	local $/ = undef;
#	my $expected = <$fh>;
#	%base = $expected =~ /([A-Za-z:-]+)\s+(\d+)/g
#}
#diag explain \%base;
#diag explain run_gladiator('');
my $base = run_gladiator('');

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
