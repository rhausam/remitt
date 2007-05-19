#!/usr/bin/perl
#
#	$Id$
#	$Author$
#
# File: bin/remitt_server.pl
#
# 	REMITT XML-RPC server. This process is run by an init.d script
# 	to provide XML-RPC connectivity for REMITT.
#

# Force internal use of SOAP::Lite patched library and Remitt libs
use FindBin;
use lib "$FindBin::Bin/../lib";

# Actual includes
use XMLRPC::Transport::HTTP;
use Data::Dumper;
use Remitt::Utilities;
use Remitt::DataStore::Log;
use Sys::Syslog;
use POSIX qw(setsid);

my $version = "0.3.3";
my $protocolversion = 0.2;
my $quiet = 0;

my $config = Remitt::Utilities::Configuration ( );

my $port = $config->val('installation', 'port') || 7688;
my $path = $config->val('installation', 'path');

my $debug = 1;

# Open log file
openlog ( 'remitt', 'cons,pid', 'daemon' );

# Enable basic authentication
$auth = 1;

#my $plugin_types = [
#	'Render',
#	'Translation',
#	'Transport'
#];

# Fork off into the background
&daemonize;

$log = Remitt::DataStore::Log->new;

if (!$quiet) {
	print "REMITT (XMLRPC Server) v$version\n";
} else {
	syslog('info', 'REMITT v'.$version.' XML-RPC server started');
	$log->Log('SYSTEM', 2, 'XML-RPC Server', 'REMITT v'.$version.' XML-RPC server started');
}

# Start processor thread
my $processor = new Thread \&Remitt::Utilities::ProcessorThread;

$daemon = XMLRPC::Transport::HTTP::Daemon
	-> new ( 
		LocalPort => $port,
		Reuse => 1
	 )
	-> dispatch_to('Remitt::Interface')
	-> options({ compress_threshold => 10000 });
if (!$quiet) {
	print " * Running at ", $daemon->url, "\n";
	print " * Starting daemon ... \n";
}
$log->Log('SYSTEM', 2, 'XML-RPC Server', 'Daemon running at '.$daemon->url);
$daemon->handle;

#----------------------------------------------------------------------------------------

sub daemonize {
        open STDIN, '/dev/null'   or die "Can't read /dev/null: $!";
        open STDOUT, '>>/var/log/remitt.log' or die "Can't write to /var/log/remitt.log: $!";
	open STDERR, '>>/var/log/remitt.log' or die "Can't write to /var/log/remitt.log: $!";
        defined(my $pid = fork)   or die "Can't fork: $!";
	open PID, ">/var/run/remitt.pid" or die "Can't write to /var/run/remitt.pid: $!";
	print PID $pid;
	close PID;
        exit if $pid;
        setsid                    or die "Can't start a new session: $!";
        umask 0;
}

