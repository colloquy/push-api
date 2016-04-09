my $pushServer = "colloquy.mobi";
my $pushServerPort = 7906;

#

use strict;
use warnings;
use Socket;
use IO::Socket::SSL;

BEGIN {
	use Exporter();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = 1.00;
	@ISA = qw(Exporter);
	@EXPORT = qw(&pushChatMessage &pushAlert &disconnectFromPushServer);
	%EXPORT_TAGS = ();
	@EXPORT_OK = ();
}

our @EXPORT_OK;

my $socket;

my %escapedMap = ( 
	"\\" => '\\', 
	"\r" => 'r', 
	"\n" => 'n', 
	"\t" => 't', 
	"\a" => 'a',
	"\b" => 'b',
	"\e" => 'e',
	"\f" => 'f',
	"\"" => '"',
	"\$" => '$',
	"\@" => '@'
);

sub chr2hex {
	my $c = shift;
	return sprintf("%04x", ord($c));
}

sub escape {
	local $_ = shift;
	s/([\a\b\e\f\r\n\t\"\\\$\@])/\\$escapedMap{$1}/sg;
	s/([\x00-\x1f\x{7f}-\x{ffff}])/"\\u" . chr2hex($1)/gse;
	return $_;
}

sub pushChatMessage {
	my $deviceToken = shift;
	my $message = shift;
	my $action = shift;
	my $sender = shift;
	my $room = shift;
	my $server = shift;
	my $sound = shift;
	my $badge = shift;

	my $payload = "{";
	my $first = 1;

	if ($deviceToken) {
		$payload .= '"device-token":"' . escape($deviceToken) . '"';
		$first = 0;
	}

	if ($message) {
		$payload .= ',' unless $first;
		$payload .= '"message":"' . escape($message) . '"';
		$first = 0;
	}

	if ($action) {
		$payload .= ',' unless $first;
		$payload .= '"action":true';
		$first = 0;
	}

	if ($sender) {
		$payload .= ',' unless $first;
		$payload .= '"sender":"' . escape($sender) . '"';
		$first = 0;
	}

	if ($room) {
		$payload .= ',' unless $first;
		$payload .= '"room":"' . escape($room) . '"';
		$first = 0;
	}

	if ($server) {
		$payload .= ',' unless $first;
		$payload .= '"server":"' . escape($server) . '"';
		$first = 0;
	}

	if ($sound) {
		$payload .= ',' unless $first;
		$payload .= '"sound":"' . escape($sound) . '"';
		$first = 0;
	}

	if ($badge) {
		$payload .= ',' unless $first;
		if ($badge =~ /^\d+$/) {
			$payload .= '"badge":' . $badge;
		} else {
			$payload .= '"badge":"' . escape($badge) . '"';
		}
		$first = 0;
	}

	$payload .= "}";

	writePushNotification($payload);
}

sub pushAlert {
	my $deviceToken = shift;
	my $alert = shift;
	my $sound = shift;
	my $badge = shift;

	my $payload = "{";
	my $first = 1;

	if ($deviceToken) {
		$payload .= '"device-token":"' . escape($deviceToken) . '"';
		$first = 0;
	}

	if ($alert) {
		$payload .= ',' unless $first;
		$payload .= '"alert":"' . escape($alert) . '"';
		$first = 0;
	}

	if ($sound) {
		$payload .= ',' unless $first;
		$payload .= '"sound":"' . escape($sound) . '"';
		$first = 0;
	}

	if ($badge) {
		$payload .= ',' unless $first;
		if ($badge =~ /^\d+$/) {
			$payload .= '"badge":' . $badge;
		} else {
			$payload .= '"badge":"' . escape($badge) . '"';
		}
		$first = 0;
	}

	$payload .= "}";

	writePushNotification($payload);
}

sub connectToPushServer {
	{
		local $^W = 0;
		return 1 if $socket and $socket->connected();
	}

	$socket = IO::Socket::SSL->new(Domain => &AF_INET, PeerAddr => $pushServer, PeerPort => $pushServerPort, SSL_verify_mode => 0);
	return ($socket and $socket->connected());
}

sub writePushNotification {
	my $payload = shift or return;

	my $attempts = 0;
	$attempts++ while !connectToPushServer() and $attempts < 10;

	{
		local $^W = 0;
		return unless $socket and $socket->connected();
	}

	print $socket $payload;
}

sub disconnectFromPushServer {
	return unless $socket;
	$socket->close();
	$socket = undef;
}

1;
