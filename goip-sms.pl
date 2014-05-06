#!/usr/bin/perl 
use strict;
use warnings;
use open IO => ':locale';
use IO::Socket;
use Email::MIME;
use Email::Sender::Simple qw(sendmail);
use Encode qw( decode encode );

$| = 1;
my $MAXLEN = 512;

my ($port, $from, $to) = @ARGV;
unless ($to) {
	print "Usage: $0 port from_email to_email\n";
}

my $sock = IO::Socket::INET->new(LocalPort => $port, Proto => "udp") or die "Couldn't be a udp server on port $port : $@\n";

while ($sock->recv(my $msg, $MAXLEN)) {
    my ($port, $ipaddr) = sockaddr_in($sock->peername);
	my $msgu = decode('utf8', $msg);
	print "IN: ", $msgu, "\n";
	my %pp = map { split /\:/, $_ } split(/\;/, $msgu);
	($pp{msg}) = ($msgu =~ /msg\:(.+)$/ms) if $pp{msg};
	if (defined $pp{RECEIVE}) {
		$sock->send(sprintf("RECEIVE %d OK", $pp{RECEIVE}));
		send_email( $pp{msg}, $pp{msg} );
	}
	elsif (defined $pp{req}) {
		$sock->send(sprintf("reg:%d;status:200;", $pp{req}));
	}
	elsif (defined $pp{STATE}) {
		$sock->send(sprintf("STATE %d OK", $pp{STATE}));
	}
	elsif (defined $pp{RECORD}) {
		$sock->send(sprintf("RECORD %d OK", $pp{RECORD}));
	}
}


sub send_email {
	my ($subj, $text) = @_;
	my $message = Email::MIME->create(
		header_str => [
			From    => $from,
			To      => $to,
			Subject => $subj,
		],
		attributes => {
			encoding => 'quoted-printable',
			charset  => 'UTF-8',
		},
		body_str => $text
	);
	sendmail($message);
}
