#! /usr/bin/perl
# $Id: 10_override.t,v 1.1 2008/05/18 09:27:06 dk Exp $

use strict;
use warnings;

use Test::More tests => 7;
use IO::Lambda qw(:all);

# override and pass
my $q = lambda {
	context lambda { 42 };
	&tail;
};

my $bypass = 0;
sub bypass
{
	my ( $self, $method, @param) = @_;
	$bypass++;
	$self-> $method( @param);
}

$q-> override( \&bypass);
ok($q-> wait == 42 && $bypass == 1, 'single override pass');

# override and deny
$bypass = 0;
$q-> reset;
$q-> override(undef);
$q-> override( sub { 43 } );
ok($q-> wait == 43 && $bypass == 0, 'single override deny');

# clean override 
$bypass = 0;
$q-> reset;
$q-> override(undef);
ok( $q-> wait == 42, 'remove override');

# two overrides, both increment
$bypass = 0;
$q-> reset;
$q-> override(undef);
$q-> override( \&bypass);
$q-> override( \&bypass);
$q-> wait;
ok( $bypass == 2, 'two passing overrides');

# one leftover override
$bypass = 0;
$q-> override(undef);
$q-> reset;
$q-> wait;
ok( $bypass == 1, 'one leftover override');

# one deny, one pass override
$bypass = 0;
$q-> override( sub { 43 } );
$q-> reset;
$q-> wait;
ok( $q-> wait == 43 && $bypass == 0, 'one deny, one pass');

# one pass, one deny override
$bypass = 0;
$q-> override(undef);
$q-> override(undef);
$q-> override( sub { 43 } );
$q-> override( \&bypass);
$q-> reset;
$q-> wait;
ok( $q-> wait == 43 && $bypass == 1, 'one pass, one deny');
