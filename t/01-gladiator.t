use strict;
use warnings;

use Test::More;
plan tests => 1;

my %base;
{
	open my $fh, '<', 't/base.txt' or die;
	local $/ = undef;
	my $expected = <$fh>;
	%base = $expected =~ /([A-Za-z:-]+)\s+(\d+)/g
}
#diag explain \%base;

my @out = `$^X eg/gladiator.pl`;
chomp @out;
shift @out;
my %out =  map { /(\d+)\s+(\S+)/; $2, $1 } @out;
#diag explain \%out;

is_deeply \%out, \%base, 'base';


