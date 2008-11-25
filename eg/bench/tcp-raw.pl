# $Id: tcp-raw.pl,v 1.1 2008/07/09 09:00:47 dk Exp $
# An echo client-server benchmark
use strict;
use Time::HiRes qw(time);
use IO::Handle;
use IO::Socket::INET;

my $CYCLES = 500;

# benchmark in select() 

my $port      = $ENV{TESTPORT} || 29876;
my $serv_sock = IO::Socket::INET-> new(
	Listen    => 5,
	LocalPort => $port,
	Proto     => 'tcp',
	ReuseAddr => 1,
);
die "listen() error: $!\n" unless $serv_sock;
my $sfh = fileno($serv_sock);
my ($s2fh, $conn);

# prepare connection to the server
sub sock
{
	my $x = IO::Socket::INET-> new(
		PeerAddr  => 'localhost',
		PeerPort  => $port,
		Proto     => 'tcp',
	);
	$x-> autoflush(1);
	die "connect() error: $!\n" unless $x;
	return $x;
}

my $t = time;
for my $cycle ( 1..$CYCLES) {
	my $sock = sock();
	my $cfh = fileno($sock);
	my ($r, $w) = ('','');
	vec($r, $_, 1) = 1 for $cfh, $sfh, $s2fh;
	vec($w, $_, 1) = 1 for $cfh;
	my $n = select( $r, $w, undef, undef);
	die "select:$!\n" unless $n;
	if ( vec($r, $cfh, 1)) {
		close $sock;
	}
	if ( vec($w, $cfh, 1)) {
		print $sock "can write $cycle\n";
	}

	if ( vec($r, $sfh, 1)) {
		$conn = IO::Handle-> new;
		accept( $conn, $serv_sock) or die "accept() error:$!";
		$conn-> autoflush(1);
		$s2fh = fileno($conn);
	}
	if ( vec($r, $s2fh, 1)) {
		my $r = <$conn>;
		print $conn $r;
		close $conn;
	}
}
$t = time - $t;
printf "%.3f sec\n", $t;
