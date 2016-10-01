{@rem = '--*-Perl-*-- 
@echo off
SET LANG=en_US
if "%OS%" == "Windows_NT" goto WinNT
perl -x -S "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
perl -x -S %0 %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl
@rem ';
#!c:\usr\perl\bin\perl.exe -T -w
#line 15

# <@LICENSE>
# Copyright 2004 Apache Software Foundation
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# </@LICENSE>

my $PREFIX          = 'c:/perl/site';             # substituted at 'make' time
my $DEF_RULES_DIR   = 'c:/perl/site/share/spamassassin';      # substituted at 'make' time
my $LOCAL_RULES_DIR = 'c:/perl/site/etc/mail/spamassassin';    # substituted at 'make' time

use lib 'c:/perl/site/lib';                   # substituted at 'make' time

BEGIN {    # added by jm for use inside the distro
  if ( -e '../blib/lib/Mail/SpamAssassin.pm' ) {
    unshift ( @INC, '../blib/lib' );
  }
  else {
    unshift ( @INC, '../lib' );
  }
}

use strict;
use Config;

use IO::Socket;
use IO::Handle;
use IO::Pipe;

use Mail::SpamAssassin;
use Mail::SpamAssassin::NetSet;

use Getopt::Long;
use Pod::Usage;
use POSIX qw(:sys_wait_h);
use POSIX qw(setsid sigprocmask);
use Errno;

use Cwd ();
use File::Spec 0.8;
use File::Path;

# Check to make sure the script version and the module version matches.
# If not, die here!  Also, deal with unchanged VERSION macro.
if ($Mail::SpamAssassin::VERSION ne '@@VERSION@@' && '@@VERSION@@' ne "\@\@VERSION\@\@") {
  die 'ERROR!  spamassassin script is v@@VERSION@@, but using modules v'.$Mail::SpamAssassin::VERSION."!\n";
}

# Load Time::HiRes if it's available
BEGIN {
  eval { require Time::HiRes };
  Time::HiRes->import(qw(time)) unless $@;
}

my %resphash = (
  EX_OK          => 0,     # no problems
  EX_USAGE       => 64,    # command line usage error
  EX_DATAERR     => 65,    # data format error
  EX_NOINPUT     => 66,    # cannot open input
  EX_NOUSER      => 67,    # addressee unknown
  EX_NOHOST      => 68,    # host name unknown
  EX_UNAVAILABLE => 69,    # service unavailable
  EX_SOFTWARE    => 70,    # internal software error
  EX_OSERR       => 71,    # system error (e.g., can't fork)
  EX_OSFILE      => 72,    # critical OS file missing
  EX_CANTCREAT   => 73,    # can't create (user) output file
  EX_IOERR       => 74,    # input/output error
  EX_TEMPFAIL    => 75,    # temp failure; user is invited to retry
  EX_PROTOCOL    => 76,    # remote error in protocol
  EX_NOPERM      => 77,    # permission denied
  EX_CONFIG      => 78,    # configuration error
);


sub print_version {
  printf("%s version %s\n", "SpamAssassin Server", Mail::SpamAssassin::Version());
  printf("  running on Perl %s\n", join(".", map { $_*1 } ($] =~ /(\d)\.(\d{3})(\d{3})/)));
  eval { require IO::Socket::SSL; };
  printf("  with SSL support (%s %s)\n", "IO::Socket::SSL", $IO::Socket::SSL::VERSION) unless ($@);
}

sub print_usage_and_exit {
  my ( $message, $respnam ) = (@_);
  $respnam ||= 'EX_USAGE';

  if ($respnam eq 'EX_OK' ) {
    print_version();
    print("\n");
  }
  pod2usage(
    -verbose => 0,
    -message => $message,
    -exitval => $resphash{$respnam},
  );
}


# defaults
my %opt = (
  'user-config'   => 1,
  'ident-timeout' => 5.0,
);

# Untaint all command-line options and ENV vars, since spamd is launched
# as a daemon from a known-safe environment. Also store away some of the
# vars we need for a SIGHUP later on.
# See also <http://bugzilla.spamassassin.org/show_bug.cgi?id=1725>
# and      <http://bugzilla.spamassassin.org/show_bug.cgi?id=2192>.

# Testing for taintedness only works before detainting %ENV
Mail::SpamAssassin::Util::am_running_in_taint_mode();

# First clean PATH and untaint the environment -- need to do this before
# Cwd::cwd(), else it will croak.
Mail::SpamAssassin::Util::clean_path_in_taint_mode();
Mail::SpamAssassin::Util::untaint_var( \%ENV );

# The zeroth argument will be replaced in daemonize().
my $ORIG_ARG0 = Mail::SpamAssassin::Util::untaint_var($0);

# Getopt::Long clears all arguments it processed (untaint both @ARGVs here!)
my @ORIG_ARGV = Mail::SpamAssassin::Util::untaint_var( \@ARGV );

# daemonize() switches to the root later on and we need to come back here
# somehow -- untaint the dir to be on the safe side.
my $ORIG_CWD = Mail::SpamAssassin::Util::untaint_var( Cwd::cwd() );

# Parse the command line
Getopt::Long::Configure("bundling");
GetOptions(
  'allowed-ips|A=s'          => \@{ $opt{'allowed-ip'} },
  'auth-ident'               => \$opt{'auth-ident'},
  'configpath|C=s'           => \$opt{'configpath'},
  'c'                        => \$opt{'create-prefs'},
  'create-prefs!'            => \$opt{'create-prefs'},
  'daemonize!'               => \$opt{'daemonize'},
  'debug!'                   => \$opt{'debug'},
  'd'                        => \$opt{'daemonize'},
  'D'                        => \$opt{'debug'},
  'helper-home-dir|H:s'      => \$opt{'home_dir_for_helpers'},
  'help|h'                   => \$opt{'help'},
  'ident-timeout=f'          => \$opt{'ident-timeout'},
  'ldap-config!'             => \$opt{'ldap-config'},
  'listen-ip|ip-address|i:s' => \$opt{'listen-ip'},
  'local!'                   => \$opt{'local'},
  'L'                        => \$opt{'local'},
  'max-children|m=i'         => \$opt{'max-children'},
  'max-conn-per-child=i'     => \$opt{'max-conn-per-child'},
  'nouser-config|x'          => sub { $opt{'user-config'} = 0 },
  'paranoid!'                => \$opt{'paranoid'},
  'P'                        => \$opt{'paranoid'},
  'pidfile|r=s'              => \$opt{'pidfile'},
  'port|p=s'                 => \$opt{'port'},
  'Q'                        => \$opt{'setuid-with-sql'},
  'q'                        => \$opt{'sql-config'},
  'server-cert=s'            => \$opt{'server-cert'},
  'server-key=s'             => \$opt{'server-key'},
  'setuid-with-ldap'         => \$opt{'setuid-with-ldap'},
  'setuid-with-sql'          => \$opt{'setuid-with-sql'},
  'siteconfigpath=s'         => \$opt{'siteconfigpath'},
  'socketgroup=s'            => \$opt{'socketgroup'},
  'socketmode=s'             => \$opt{'socketmode'},
  'socketowner=s'            => \$opt{'socketowner'},
  'socketpath=s'             => \$opt{'socketpath'},
  'sql-config!'              => \$opt{'sql-config'},
  'ssl'                      => \$opt{'ssl'},
  'syslog-socket=s'          => \$opt{'syslog-socket'},
  'syslog|s=s'               => \$opt{'syslog'},
  'user-config'              => \$opt{'user-config'},
  'username|u=s'             => \$opt{'username'},
  'version|V'                => \$opt{'version'},
  'virtual-config-dir=s'     => \$opt{'virtual-config-dir'},
  'v'                        => \$opt{'vpopmail'},
  'vpopmail!'                => \$opt{'vpopmail'},

  #
  # NOTE: These are old options.  We should ignore (but warn about)
  # the ones that are now defaults.  Everything else gets a die (see note2)
  # so the user doesn't get us doing something they didn't expect.
  #
  # NOTE2: 'die' doesn't actually stop the process, GetOptions() catches
  # it, then passes the error on, so we'll end up doing a Usage statement.
  # You can avoid that by doing an explicit exit in the sub.
  #
  
  # last in 2.3
  'F:i'                   => sub { warn "The -F option has been removed from spamd, please remove from your commandline and re-run.\n"; exit 2; },
  'add-from!'             => sub { warn "The --add-from option has been removed from spamd, please remove from your commandline and re-run.\n"; exit 2; },

  # last in 2.4
  'stop-at-threshold|S' => sub { warn "The -S option has been deprecated and is no longer supported, ignoring.\n" },

  # last in 2.6
  'auto-whitelist|whitelist|a'      => sub { warn "The -a option has been removed.  Please look at the use_auto_whitelist config option instead.\n"; exit 2; },

) or print_usage_and_exit();
	
if ($opt{'help'}) {
  print_usage_and_exit(qq{For more details, use "man spamd".\n}, 'EX_OK');
}
if ($opt{'version'}) {
  print_version();
  exit($resphash{'EX_OK'});
}

# bug 2228: make the values of (almost) all parameters which accept file paths
# absolute, so they are still valid after daemonize()
foreach my $opt (
  qw(
  configpath
  siteconfigpath
  socketpath
  pidfile
  home_dir_for_helpers
  )
  )
{
  $opt{$opt} = Mail::SpamAssassin::Util::untaint_file_path(
    File::Spec->rel2abs( $opt{$opt} )    # rel2abs taints the new value!
  ) if ( $opt{$opt} );
}

# sanity checking on parameters: if --socketpath is used, it means that we're using
# UNIX domain sockets, none of the IP params are allowed. The code would probably
# work ok if we didn't check it, but it's better if we detect the error and report
# it lest the admin find surprises.

if (
  defined $opt{'socketpath'}
  and ( ( @{ $opt{'allowed-ip'} } > 0 )
    or defined $opt{'ssl'}
    or defined $opt{'auth-ident'}
    or defined $opt{'port'} )
  )
{
  print_usage_and_exit("ERROR: --socketpath mutually exclusive with --allowed-ip/--ssl/--port params");
}

if (
  !$opt{'socketpath'}
  and ( $opt{'socketowner'}
    or $opt{'socketgroup'}
    or $opt{'socketmode'})
  )
{
  print_usage_and_exit("ERROR: --socketowner/group/mode requires --socketpath param");
}

# These can be changed on command line with -A flag
# but only if we're not using UNIX domain sockets
my $allowed_nets = Mail::SpamAssassin::NetSet->new();
if ( not defined $opt{'socketpath'} ) {
  if ( @{ $opt{'allowed-ip'} } ) {
    set_allowed_ip( split /,/, join ( ',', @{ $opt{'allowed-ip'} } ) );
  }
  else {
    set_allowed_ip('127.0.0.1');
  }
}

# ident-based spamc user authentication
if ( $opt{'auth-ident'} ) {
  eval { require Net::Ident };
  die
"fatal: ident-based authentication requested, but Net::Ident is unavailable\n"
    if ($@);

  $opt{'ident-timeout'} = undef if $opt{'ident-timeout'} <= 0.0;
  import Net::Ident qw(ident_lookup);
}

# Check for server certs
$opt{'server-key'}  ||= "$LOCAL_RULES_DIR/certs/server-key.pem";
$opt{'server-cert'} ||= "$LOCAL_RULES_DIR/certs/server-cert.pem";
if ( $opt{'ssl'} ) {
  eval { require IO::Socket::SSL };
  die "fatal: SSL encryption requested, but IO::Socket::SSL is unavailable\n"
    if ($@);

  if ( !-e $opt{'server-key'} ) {
    die "The server key file $opt{'server-key'} does not exist\n";
  }
  if ( !-e $opt{'server-cert'} ) {
    die "The server certificate file $opt{'server-cert'} does not exist\n";
  }
}

### Begin initialization of logging ########################

# The syslog facility can be changed on the command line with the
# --syslog flag. Special cases are:
# * A log facility of 'stderr' will log to STDERR
# * " "   "        "  'null' disables all logging
# * " "   "        "  'file' logs to the file "spamd.log"
# * Any facility containing non-word characters is interpreted as the name
#   of a specific logfile
my $log_facility = $opt{'syslog'} || 'mail';

# The socket to log over can be changed on the command line with the
# --syslog-socket flag. Logging to any file handler (either a specific log
# file or STDERR) is internally represented by a socket 'file', no logging
# at all is 'none'. The latter is different from --syslog-socket=none which
# gets mapped to --syslog=stderr and such --syslog-socket=file. An internal
# socket of 'none' means as much as --syslog=null. Sounds complicated? It is.
# But it works.
my $log_socket = lc( $opt{'syslog-socket'} ) || 'unix';

# This is the default log file; it can be changed on the command line
# via a --syslog flag containing non-word characters.
my $log_file = "spamd.log";

# A specific log file was given (--syslog=/path/to/file).
if ( $log_facility =~ /[^a-z0-9]/ ) {
  $log_file   = $log_facility;
  $log_socket = 'file';
}

# The generic log file was requested (--syslog=file).
elsif ( lc($log_facility) eq 'file' ) {
  $log_socket = 'file';
}

# The casing is kept only if the facility specified a file.
else {
  $log_facility = lc($log_facility);
}

# Either above or at the command line the socket was set
# to 'file' (--syslog-socket=file).
if ( $log_socket eq 'file' ) {
  $log_facility = 'file';
}

# The socket 'none' (--syslog-socket=none) historically
# represents logging to STDERR.
elsif ( $log_socket eq 'none' ) {
  $log_facility = 'stderr';
}

# Either above or at the command line the facility was set
# to 'stderr' (--syslog=stderr).
if ( $log_facility eq 'stderr' ) {
  $log_socket = 'file';
}

my $already_done_syslog_failure_warning;

# Logging via syslog is requested. Falling back to INET and then STDERR
# if opening a UNIX socket fails.
if ( $log_socket ne 'file' and $log_facility ne 'null' ) {
  warn "trying to connect to syslog/${log_socket}...\n" if $opt{'debug'};
  eval {
    defined( setlogsock($log_socket) ) || die $!;

    # The next call is required to actually open the socket.
    openlog_for_spamd();
    syslog( 'debug', "%s", "spamd starting" );
  };
  my $err = $@;
  chomp($err);

  # Solaris sometimes doesn't support UNIX-domain syslog sockets apparently;
  # same is true for perl 5.6.0 build on an early version of Red Hat 7!
  # In that case we try it with INET.
  if ( $err and $log_socket ne 'inet' ) {
    if ( $opt{'debug'} ) {
      warn "connection failed: $err\n";
      warn "trying to connect to syslog/inet...\n";
    }
    eval {
      defined( setlogsock('inet') ) || die $!;
      openlog_for_spamd();
      syslog( 'debug', "%s", "spamd starting, 2nd try" );
      syslog( 'debug', "%s", "failed to setlogsock(${log_socket}): $err" );
      syslog( 'debug', "%s",
        "falling back to inet (you might want to use --syslog-socket=inet)" );
    };
    $log_socket = 'inet' unless $@;
  }

  # fall back to stderr if all else fails
  if ($@) {
    warn "failed to setlogsock(${log_socket}): $err\n"
      . "reporting logs to stderr\n";
    $log_facility = 'stderr';
  }
  else {
    warn "no error connecting to syslog/${log_socket}\n" if $opt{'debug'};
  }
}

# The user wants to log to some file -- open it on STDLOG. Falling back to STDERR
# if opening the file fails.
elsif ( $log_facility eq 'file' ) {
  unless ( open( STDLOG, ">>$log_file" ) ) {
    warn "failed to open logfile ${log_file}: $!\n"
      . "reporting logs to stderr\n";
    $log_facility = 'stderr';
  }
}

# Either one of the above failed ot logging to STDERR is explicitly requested --
# make STDLOG a dup so we don't have to handle so many special cases later on.
if ( $log_facility eq 'stderr' ) {
  open( STDLOG, ">&STDERR" ) || die "Can't duplicate stderr: $!\n";
  $log_socket = 'file';
}

warn "logging enabled:\n"
  . "\tfacility: ${log_facility}\n"
  . "\tsocket:   ${log_socket}\n"
  . "\toutput:   "
  . (
  $log_facility eq 'file' ? ${log_file}
  : $log_facility eq 'stderr' ? 'stderr'
  : $log_facility eq 'null'   ? 'debug'
  : 'syslog'
  )
  . "\n"
  if $opt{'debug'};

# Don't duplicate log messages in debug mode.
if ( $log_facility eq 'stderr' and $opt{'debug'} ) {
  warn "logging to stderr disabled: already debugging to stderr\n";
  $log_facility = 'null';
}

# Either above or at the command line all logging was disabled (--syslog=null).
if ( $log_facility eq 'null' ) {
  $log_socket = 'none';
}

# Close the logfile on exit.
END {
  close(STDLOG) if (defined $log_socket && $log_socket eq 'file');
}

# The code above was quite complicated. Make sure everything fits together.
# These combinations are allowed:
#   * socket = file
#      ^ ^-> facility = stderr
#      '---> facility = file
#   * socket = none
#      ^-> facility = null
#   * socket = (unix|inet|...)
#      --> facility = (mail|daemon|...)
die "fatal: internal error while setting up logging: values don't match:\n"
  . "\targuments:\n"
  . "\t\t--syslog=$opt{'syslog'} --syslog-socket=$opt{'syslog-socket'}\n"
  . "\tvalues:\n"
  . "\t\tfacility: ${log_facility}\n"
  . "\t\tsocket:   ${log_socket}\n"
  . "\t\tfile:     ${log_file}\n"
  . "\tplease report to http://bugzilla.spamassassin.org -- thank you\n"
  if ( $log_socket eq 'file'
  and ( $log_facility ne 'stderr' and $log_facility ne 'file' ) )
  or ( ( $log_facility eq 'stderr' or $log_facility eq 'file' )
  and $log_socket ne 'file' )
  or ( $log_socket   eq 'none' and $log_facility ne 'null' )
  or ( $log_facility eq 'null' and $log_socket   ne 'none' );

### End initialization of logging ##########################

# REIMPLEMENT: if $log_socket is none, fall back to log_facility 'stderr'.
# If log_fac is stderr and $opt{'debug'}, set log_fac to 'null' to avoid
# duplicating log messages.
# TVD: isn't this already done up above?

# support setuid() to user unless:
# run with -u
# we're not root
# doing --vpopmail
# we disable user-config
my $setuid_to_user = (
	$opt{'username'} ||
	$> != 0 ||
	$opt{'vpopmail'} ||
	(!$opt{'user-config'} && !($opt{'setuid-with-sql'}||$opt{'setuid-with-ldap'}))
	) ? 0 : 1;

# always copy the config, later code may disable
my $copy_config_p = 1;

my $current_user;

my $client;               # used for the client connection ...
my $childlimit;           # max number of kids allowed
my $clients_per_child;    # number of clients each child should process
my %children = ();        # current children

if ( defined $opt{'max-children'} ) {
  $childlimit = $opt{'max-children'};

  # Make sure that the values are at least 1
  $childlimit = undef if ( $childlimit < 1 );
}

if ( defined $opt{'max-conn-per-child'} ) {
  $clients_per_child = $opt{'max-conn-per-child'};

  # Make sure that the values are at least 1
  $clients_per_child = undef if ( $clients_per_child < 1 );
}

# Set some "sane" limits for defaults
$childlimit        ||= 5;
$clients_per_child ||= 200;


my $dontcopy = 1;
if ( $opt{'create-prefs'} ) { $dontcopy = 0; }

my $orighome;
if ( defined $ENV{'HOME'} ) {
  if ( defined $opt{'username'} )
  {    # spamd is going to run as another user, so reset $HOME
    if ( my $nh = ( getpwnam( $opt{'username'} ) )[7] ) {
      $ENV{'HOME'} = $nh;
    }
    else {
      die "Can't determine home directory for user '"
        . $opt{'username'} . "'!\n";
    }
  }

  $orighome = $ENV{'HOME'};    # keep a copy for use by Razor, Pyzor etc.
  delete $ENV{'HOME'};         # we do not want to use this when running spamd
}

# Do whitelist later in tmp dir. Side effect: this will be done as -u user.

my ( $port, $addr, $proto );
my ($listeninfo);              # just for reporting

if ( defined $opt{'socketpath'} ) {
  $listeninfo = "UNIX domain socket " . $opt{'socketpath'};
}
else {
  $proto = getprotobyname('tcp');

  $addr = $opt{'listen-ip'};
  if (defined $addr) {
    if ($addr ne '') {
      $addr = ( gethostbyname($addr) )[4];
      die "invalid address: $opt{'listen-ip'}\n" unless $addr;
      $addr = inet_ntoa($addr);
    }
    else {
      $addr = '0.0.0.0';
    }
  }
  else {
    $addr = '127.0.0.1';
  }

  $port = $opt{'port'} || 783;
  if ($port !~ /^(\d+)$/ ) {
    $port = ( getservbyname($port, 'tcp') )[2];
    die "invalid port: $opt{'port'}\n" unless $port;
  }

  $listeninfo = "port $port/tcp";
}

# Be a well-behaved daemon
my $server;
if ( $opt{'socketpath'} ) {
  my $path = $opt{'socketpath'};

  #---------------------------------------------------------------------
  # see if the socket is in use: if we connect to the current socket, it
  # means that spamd is already running, so we have to bail on our own.
  # Yes, there is a window here: best we can do for now. There is almost
  # certainly a better way, but we don't know it. Yet.

  if ( -e $path ) {
    if ( new IO::Socket::UNIX( Peer => $path, Type => SOCK_STREAM ) ) {

      # we connected successfully: must alreadybe running

      undef $opt{'socketpath'};    # so exit handlers won't unlink it!

      die "spamd already running on $path, exiting\n";
    }
    else {
      unlink $path;
    }
  }

  my %socket = (
    Local  => $path,
    Type   => SOCK_STREAM,
    Listen => SOMAXCONN,
  );
  warn("creating UNIX socket:\n" . join("\n", map { "\t$_: " . (defined $socket{$_} ? $socket{$_} : "(undef)") } sort keys %socket) . "\n") if $opt{'debug'};
  $server = new IO::Socket::UNIX(%socket)
         || die "Could not create UNIX socket on $path: $! ($@)\n";

  my $mode = $opt{socketmode};
  if ($mode) {
    $mode = oct $mode;
  } else {
    $mode = 0666;        # default
  }

  my $owner = $opt{socketowner};
  my $group = $opt{socketgroup};
  if ($owner || $group) {
    my $uid = -1;
    my $gid = -1;
    if ($owner) {
      my ($login,$pass,$puid,$pgid) = getpwnam($owner)
                            or die "$owner not in passwd database\n";
      $uid = $puid;
    }
    if ($group) {
      my ($name,$pass,$ggid,$members) = getgrnam($group)
                            or die "$group not in group database\n";
      $gid = $ggid;
    }
    if (!chown $uid, $gid, $path) {
      die "Could not chown $path to $uid/$gid: $! ($@)";
    }
  }

  if (!chmod $mode, $path) {    # make sure everybody can talk to it
    die "Could not chmod $path to $mode: $! ($@)";
  }
}
elsif ( $opt{'ssl'} ) {
  my %socket = (
    LocalAddr       => $addr,
    LocalPort       => $port,
    Proto           => $proto,
    Type            => SOCK_STREAM,
    ReuseAddr       => 1,
    Listen          => SOMAXCONN,
    SSL_verify_mode => 0x00,
    SSL_key_file    => $opt{'server-key'},
    SSL_cert_file   => $opt{'server-cert'}
  );
  warn("creating SSL socket:\n" . join("\n", map { "\t$_:  " . (defined $socket{$_} ? $socket{$_} : "(undef)") } sort keys %socket) . "\n") if $opt{'debug'};
  $server = new IO::Socket::SSL(%socket)
         || die "Could not create SSL socket on $addr:$port: $! ($@)\n";
}
else {
  my %socket = (
    LocalAddr => $addr,
    LocalPort => $port,
    Proto     => $proto,
    Type      => SOCK_STREAM,
    ReuseAddr => 1,
    Listen    => SOMAXCONN
  );
  warn("creating INET socket:\n" . join("\n", map { "\t$_: " . (defined $socket{$_} ? $socket{$_} : "(undef)") } sort keys %socket) . "\n") if $opt{'debug'};
  $server = new IO::Socket::INET(%socket)
         || die "Could not create INET socket on $addr:$port: $! ($@)\n";
}

if ( defined $opt{'pidfile'} ) {
  $opt{'pidfile'} =
    Mail::SpamAssassin::Util::untaint_file_path( $opt{'pidfile'} );
}

# support non-root use (after we bind to the port)
if ( $opt{'username'} ) {
  my ( $uuid, $ugid ) = ( getpwnam( $opt{'username'} ) )[ 2, 3 ];
  if ( !defined $uuid || $uuid == 0 ) {
    die "fatal: cannot run as nonexistent user or root with -u option\n";
  }

  $uuid =~ /^(\d+)$/ and $uuid = $1;    # de-taint
  $ugid =~ /^(\d+)$/ and $ugid = $1;    # de-taint

  # remove the pidfile if it exists.  we'll create it anew later.
  if ( defined $opt{'pidfile'} && -f $opt{'pidfile'} ) {
    unlink $opt{'pidfile'}
      || die "fatal: could not unlink '$opt{'pidfile'}'\n";
  }

  # ditto with the socket file
  if ( defined $opt{'socketpath'} && !$opt{'socketowner'}) {
    chown $uuid, -1, $opt{'socketpath'}
      || die "fatal: could not chown '$opt{'socketpath'}' to uid $uuid\n";
  }

  # Change GID
  $) = "$ugid $ugid";    # effective gid
  $( = $ugid;            # real gid

  # Change UID
  $> = $uuid;            # effective uid
  $< = $uuid;            # real uid. we now cannot setuid anymore
  if ( $> != $uuid and $> != ( $uuid - 2**32 ) ) {
    die "fatal: setuid to uid $uuid failed\n";
  }

}

my $spamtest = Mail::SpamAssassin->new(
  {
    dont_copy_prefs      => $dontcopy,
    rules_filename       => ( $opt{'configpath'} || 0 ),
    site_rules_filename  => ( $opt{'siteconfigpath'} || 0 ),
    local_tests_only     => ( $opt{'local'} || 0 ),
    debug                => ( $opt{'debug'} || 0 ),
    paranoid             => ( $opt{'paranoid'} || 0 ),
    home_dir_for_helpers => (
      defined $opt{'home_dir_for_helpers'}
      ? $opt{'home_dir_for_helpers'}
      : $orighome
    ),
    PREFIX          => $PREFIX,
    DEF_RULES_DIR   => $DEF_RULES_DIR,
    LOCAL_RULES_DIR => $LOCAL_RULES_DIR
  }
);

# if $clients_per_child == 1, there's no point in copying configs around
unless ($clients_per_child > 1) {
  # unset $copy_config_p so we don't bother trying to copy things back
  # after closing the connection
  $copy_config_p = 0;
}

# If we need Storable, and it's not installed, alert now before we daemonize.
die "Required module Storable not found!\n"
  if ($copy_config_p && !$spamtest->_is_storable_available());

## DAEMONIZE! ##

$opt{'daemonize'} and daemonize();

# should be done post-daemonize such that any files created by this
# process are written with the right ownership and everything.
preload_modules_with_tmp_homedir();

# bayes DBs may still be tied() at this point, so untie them and such.
$spamtest->finish_learner();

# If we're going to be switching users in check(), let's backup the
# fresh configuration now for later restoring ...  MUST be placed after
# the M::SA creation.
my %conf_backup = ();
my %msa_backup = ();

if ($copy_config_p) {
  foreach( 'username', 'user_dir', 'userstate_dir', 'learn_to_journal' ) {
    $msa_backup{$_} = $spamtest->{$_} if (exists $spamtest->{$_});
  }

  $spamtest->copy_config(undef, \%conf_backup) ||
    die "error returned from copy_config, no Storable module?\n";
}

# setup signal handlers before the kids since we may have to kill them...
# make sure this happens before setting up the pidfile to avoid a race
# condition.  see bugzilla ticket 3443.
my $got_sighup;
setup_parent_sig_handlers();

# log server started, but processes watching the log to wait for connect
# should wait until they see the pid, after signal handlers are in place
if ( $opt{'debug'} ) {
  warn "server started on $listeninfo (running version "
    . Mail::SpamAssassin::Version() . ")\n";
}

logmsg( "server started on $listeninfo (running version "
    . Mail::SpamAssassin::Version()
    . ")" );

# Fork off our children.
for ( 1 .. $childlimit ) {
  #spawn();
}

# Make the pidfile ...
if (defined $opt{'pidfile'}) {
  if (open PIDF, ">$opt{'pidfile'}") {
    print PIDF "$$\n";
    close PIDF;
  }
  else {
    warn "Can't write to PID file: $!\n";
  }
}

# now allow waiting processes to connect, if they're watching the log.
# The test suite does this!

if ( $opt{'debug'} ) {
  warn "server pid: $$\n";
}

while (1) { 
      # use a large eval scope to catch die()s and ensure they
      # don't kill the server.
      my $evalret = eval { accept_a_conn(); };

      if (!defined ($evalret)) {
        logmsg("error: $@ $!, continuing");
        if ($client) { $client->close(); }  # avoid fd leaks
      }
      elsif ($evalret == -1) {
        # serious error; used for accept() failure
        die("fatal error; respawning server");
      }

      # if we changed UID during processing, change back!
      if ( $> != $< and $> != ( $< - 2**32 ) ) {
        $) = "$( $(";    # change eGID
        $> = $<;         # change eUID
        if ( $> != $< and $> != ( $< - 2**32 ) ) {
          logmsg("fatal: return setuid failed");
          die;           # make it fatal to avoid security breaches
        }
      }

      if ($copy_config_p) {
        while(my($k,$v) = each %msa_backup) {
          $spamtest->{$k} = $v;
        }

        # if we changed user, we would have also loaded up new configs
        # (potentially), so let's restore back the saved version we
        # had before.
        #
        $spamtest->copy_config(\%conf_backup, undef) ||
          die "error returned from copy_config, no Storable module?\n";
      }
      undef $current_user;
} 

while (1) {
  sleep;    # wait for a signal (ie: child's death)

  if ( defined $got_sighup ) {
    if (defined($opt{'pidfile'})) {
      unlink($opt{'pidfile'}) || warn "Can't unlink $opt{'pidfile'}: $!\n";
    }

    # leave Client fds active, and do not kill children; they can still
    # service clients until they exit.  But restart the listener anyway.
    # And close the logfile, so the new instance can reopen it.
    close(STDLOG) if $log_facility eq 'file';
    chdir($ORIG_CWD)
      || die "spamd restart failed: chdir failed: ${ORIG_CWD}: $!\n";
    exec( $ORIG_ARG0, @ORIG_ARGV );

    # should not get past that...
    die "spamd restart failed: exec failed: "
      . join ( ' ', $ORIG_ARG0, @ORIG_ARGV )
      . ": $!\n";
  }

  for ( my $i = keys %children ; $i < $childlimit ; $i++ ) {
    #spawn();
  }
}

# Kicks off a kid ...
sub spawn {
  my $pid;

  # block signal for fork
  my $sigset = POSIX::SigSet->new( POSIX::SIGINT() );
  sigprocmask( POSIX::SIG_BLOCK(), $sigset )
    or die "Can't block SIGINT for fork: $!\n";

  die "fork: $!" unless defined( $pid = fork );

  if ($pid) {
    ## PARENT

    sigprocmask( POSIX::SIG_UNBLOCK(), $sigset )
      or die "Can't unblock SIGINT for fork: $!\n";
    $children{$pid} = 1;
    logmsg("server successfully spawned child process, pid $pid");
    return;
  }
  else {
    ## CHILD

    # Reset signal handling to default settings.
    setup_child_sig_handlers();

    # unblock signals
    sigprocmask( POSIX::SIG_UNBLOCK(), $sigset )
      or die "Can't unblock SIGINT for fork: $!\n";

    # set process name where supported
    # this will help make it clear via process listing which is child/parent
    $0 = 'spamd child';

    # handle $clients_per_child connections, then die in "old" age...
    for ( my $i = 0 ; $i < $clients_per_child ; $i++ ) {

      # use a large eval scope to catch die()s and ensure they
      # don't kill the server.
      my $evalret = eval { accept_a_conn(); };

      if (!defined ($evalret)) {
        logmsg("error: $@ $!, continuing");
        if ($client) { $client->close(); }  # avoid fd leaks
      }
      elsif ($evalret == -1) {
        # serious error; used for accept() failure
        die("fatal error; respawning server");
      }

      # if we changed UID during processing, change back!
      if ( $> != $< and $> != ( $< - 2**32 ) ) {
        $) = "$( $(";    # change eGID
        $> = $<;         # change eUID
        if ( $> != $< and $> != ( $< - 2**32 ) ) {
          logmsg("fatal: return setuid failed");
          die;           # make it fatal to avoid security breaches
        }
      }

      if ($copy_config_p) {
        while(my($k,$v) = each %msa_backup) {
          $spamtest->{$k} = $v;
        }

        # if we changed user, we would have also loaded up new configs
        # (potentially), so let's restore back the saved version we
        # had before.
        #
        $spamtest->copy_config(\%conf_backup, undef) ||
          die "error returned from copy_config, no Storable module?\n";
      }
      undef $current_user;

    }

    # If the child lives to get here, it will die ...  Muhaha.
    exit;
  }
}

sub accept_a_conn {
  $client = $server->accept();

  # Bah!
  if ( !$client ) {

    # this can happen when interrupted by SIGCHLD on Solaris,
    # perl 5.8.0, and some other platforms with -m.
    if ( $! == &Errno::EINTR ) {
      return 0;
    }
    elsif ( $! == 0 && $opt{'ssl'} ) {
      logmsg( "SSL failure: " . &IO::Socket::SSL::errstr() );
      return 0;
    }
    else {
      logmsg("accept failed: $!");
      return -1;
    }
  }

  $client->autoflush(1);

  # keep track of start time
  my $start = time;

  my $remote_hostname;
  my $remote_hostaddr;
  if ( $opt{'socketpath'} ) {
    $remote_hostname = 'localhost';
    $remote_hostaddr = '127.0.0.1';
    logmsg( "got connection over " . $opt{'socketpath'} );
  }
  else {
    my ( $port, $ip ) = sockaddr_in( $client->peername );
    
    $remote_hostaddr = inet_ntoa($ip);
    $remote_hostname = gethostbyaddr($ip, AF_INET)
                    || $remote_hostaddr;

    my $msg = "connection from ${remote_hostname} [${remote_hostaddr}] at port ${port}";
    if ( ip_is_allowed($remote_hostaddr) ) {
      logmsg($msg);
    }
    else {
      logmsg("unauthorized " . $msg);
      $client->close;
      return 0;
    }
  }

  # send the request to the child process
  local ($_) = $client->getline;

  if ( !defined $_ ) {
    protocol_error("(closed before headers)");
    $client->close;
    return 0;
  }

  s/\r?\n//;

  # It may be a SKIP message, meaning that the client (spamc)
  # thinks it is too big to check.  So we don't do any real work
  # in that case.

  if (/SKIP SPAMC\/(.*)/) {
    logmsg( "skipped large message in "
        . sprintf( "%3d", time - $start )
        . " seconds." );
  }

  # It might be a CHECK message, meaning that we should just check
  # if it's spam or not, then return the appropriate response.
  # If we get the PROCESS command, the client is going to send a
  # message that we need to filter.

  elsif (/(PROCESS|CHECK|SYMBOLS|REPORT|REPORT_IFSPAM) SPAMC\/(.*)/) {
    check( $1, $2, $start, $remote_hostname, $remote_hostaddr );
  }

  # Looks like a client is just seeing if we're alive.

  elsif (/PING SPAMC\/(.*)/) {
    print $client "SPAMD/1.2 $resphash{EX_OK} PONG\r\n";
  }

  # If it was none of the above, then we don't know what it was.

  else {
    protocol_error($_);
  }

  # Close out our connection to the client ...
  $client->close();
  return 1;
}

sub check {
  my ( $method, $version, $start_time, $remote_hostname, $remote_hostaddr ) = @_;
  local ($_);
  my $expected_length;

  # Protocol version 1.0 and greater may have "User:" and
  # "Content-length:" headers.  But they're not required.

  if ( $version > 1.0 ) {
    my $hdrs = {};

    # parse_headers returns !=0 on failure
    return 1
      if parse_headers(
      $hdrs, $client,
      {
        'Content-length' => \&got_clen_header,
        'User'           => \&got_user_header
      }
      );

    $expected_length = $hdrs->{expected_length};
  }

  if ( $setuid_to_user && $> == 0 ) {
    if ( $spamtest->{paranoid} ) {
      logmsg("PARANOID: still running as root, closing connection.");
      die;
    }
    logmsg( "Still running as root: user not specified with -u, "
        . "not found, or set to root.  Fall back to nobody." );
    my ( $uid, $gid ) = 'nobody';
    $uid =~ /^(\d+)$/ and $uid = $1;    # de-taint
    $gid =~ /^(\d+)$/ and $gid = $1;    # de-taint

    $) = "$gid $gid";                   # eGID
    $> = $uid;                          # eUID
    if ( !defined($uid) || ( $> != $uid and $> != ( $uid - 2**32 ) ) ) {
      logmsg("fatal: setuid to nobody failed");
      die;
    }
  }

  if ( $opt{'sql-config'} && !defined($current_user) ) {
    unless ( handle_user_sql('nobody') ) {
      service_unavailable_error("Error fetching user preferences via SQL");
      return 1;
    }
  }

  if ( $opt{'ldap-config'} && !defined($current_user) ) {
    handle_user_ldap('nobody');
  }

  my $resp = "EX_OK";

  # Now read in message
  my @msglines;
  my $actual_length = 0;
  while ( $_ = $client->getline() ) {
    $actual_length += length($_);
    push(@msglines, $_);    
    last if (defined $expected_length && $actual_length >= $expected_length);
  }
  
  # Now parse *only* the message headers; the MIME tree won't be generated 
  # yet, check() will do this on demand later on.
  my $mail = $spamtest->parse(\@msglines, 0);
  # Free some mem.
  undef @msglines;

  # Extract the Message-Id(s) for logging purposes.
  my $msgid  = $mail->get_pristine_header("Message-Id");
  my $rmsgid = $mail->get_pristine_header("Resent-Message-Id");
  foreach my $id ((\$msgid, \$rmsgid)) {
    if ( $$id ) {
      while ( $$id =~ s/\([^\(\)]*\)// )
         { }                            # remove comments and
      $$id =~ s/^\s+|\s+$//g;          # leading and trailing spaces
      $$id =~ s/\s+/ /g;               # collapse whitespaces
      $$id =~ s/^.*?<(.*?)>.*$/$1/;    # keep only the id itself
      $$id =~ s/[^\x21-\x7e]/?/g;      # replace all weird chars
      $$id =~ s/[<>]/?/g;              # plus all dangling angle brackets
      $$id =~ s/^(.+)$/<$1>/;          # re-bracket the id (if not empty)
    }
  }

  $msgid        ||= "(unknown)";
  $current_user ||= "(unknown)";
  logmsg( ( $method eq 'PROCESS' ? "processing" : "checking" )
      . " message $msgid"
      . ( $rmsgid ? " aka $rmsgid" : "" )
      . " for ${current_user}:$>"
      . "." );

  # Check length if we're supposed to.
  if ( defined $expected_length && $actual_length != $expected_length ) {
    protocol_error(
      "(Content-Length mismatch: Expected $expected_length bytes, got $actual_length bytes)"
    );
    $mail->finish();
    return 1;
  }

  # Go ahead and check the message
  my $status = $spamtest->check($mail);

  my $msg_score     = sprintf( "%.1f", $status->get_score );
  my $msg_threshold = sprintf( "%.1f", $status->get_required_score );

  my $response_spam_status = "";
  my $was_it_spam;
  if ( $status->is_spam ) {
    $response_spam_status = $method eq "REPORT_IFSPAM" ? "Yes" : "True";
    $was_it_spam = 'identified spam';
  }
  else {
    $response_spam_status = $method eq "REPORT_IFSPAM" ? "No" : "False";
    $was_it_spam = 'clean message';
  }

  my $spamhdr = "Spam: $response_spam_status ; $msg_score / $msg_threshold";

  if ( $method eq 'PROCESS' ) {

    $status->set_tag('REMOTEHOSTNAME', $remote_hostname);
    $status->set_tag('REMOTEHOSTADDR', $remote_hostaddr);

    # Build the message to send back and measure it
    my $msg_resp        = $status->rewrite_mail();
    my $msg_resp_length = length($msg_resp);
    if ( $version >= 1.3 )    # Spamc protocol 1.3 means multi hdrs are OK
    {
      print $client "SPAMD/1.1 $resphash{$resp} $resp\r\n",
        "Content-length: $msg_resp_length\r\n", $spamhdr . "\r\n", "\r\n",
        $msg_resp;
    }
    elsif (
      $version >= 1.2 )    # Spamc protocol 1.2 means it accepts content-length
    {
      print $client "SPAMD/1.1 $resphash{$resp} $resp\r\n",
        "Content-length: $msg_resp_length\r\n", "\r\n", $msg_resp;
    }
    else                   # Earlier than 1.2 didn't accept content-length
    {
      print $client "SPAMD/1.0 $resphash{$resp} $resp\r\n", $msg_resp;
    }
  }
  else                     # $method eq 'CHECK' et al
  {
    print $client "SPAMD/1.1 $resphash{$resp} $resp\r\n";

    if ( $method eq "CHECK" ) {
      print $client "$spamhdr\r\n\r\n";
    }
    else {
      my $msg_resp = '';

      if ( $method eq "REPORT"
        or ( $method eq "REPORT_IFSPAM" and $status->is_spam ) )
      {
        $msg_resp = $status->get_report;
      }
      elsif ( $method eq "REPORT_IFSPAM" ) {

        # message is ham, $msg_resp remains empty
      }
      elsif ( $method eq "SYMBOLS" ) {
        $msg_resp = $status->get_names_of_tests_hit;
        $msg_resp .= "\r\n" if ( $version < 1.3 );
      }
      else {
        die "unknown method $method";
      }

      if ( $version >= 1.3 )    # Spamc protocol > 1.2 means multi hdrs are OK
      {
        printf $client "Content-length: %d\r\n%s\r\n\r\n%s", length($msg_resp),
          $spamhdr, $msg_resp;
      }
      else {
        printf $client "%s\r\n\r\n%s", $spamhdr, $msg_resp;
      }
    }
  }

  my $scantime = sprintf( "%.1f", time - $start_time );

  logmsg( "$was_it_spam ($msg_score/$msg_threshold) for $current_user:$> in"
      . " $scantime seconds, $actual_length bytes." );

  # add a summary "result:" line, based on mass-check format
  my @extra;
  push(@extra, "scantime=".$scantime, "size=$actual_length");
  {
    my $safe = $msgid; $safe =~ s/[\x00-\x20\s,]/_/gs; push(@extra, "mid=$safe");
  }
  if ($rmsgid) {
    my $safe = $rmsgid; $safe =~ s/[\x00-\x20\s,]/_/gs; push(@extra, "rmid=$safe");
  }
  if (defined $status->{bayes_score}) {
    push(@extra, "bayes=".$status->{bayes_score});
  }
  push(@extra, "autolearn=".$status->get_autolearn_status());

  my $yorn = $status->is_spam() ? 'Y' : '.';
  my $score = $status->get_score();
  my $tests = join(",", sort(grep(length,$status->get_names_of_tests_hit())));

  logmsg( sprintf("result: %s %2d - %s %s", $yorn, $score,
                        $tests, join(",", @extra) ));

  $status->finish();    # added by jm to allow GC'ing
  $mail->finish();
}

###########################################################################

# generalised header parser.  
sub parse_headers {
  my ( $hdrs, $client, $subs ) = @_;

  # max 255 headers
  for my $hcount ( 0 .. 255 ) {
    my $line = $client->getline;
    if ( !defined $line ) {
      protocol_error("(EOF during headers)");
      return 1;
    }
    $line =~ s/\r\n$//;
    if ( !$line ) {
      return 0;
    }

    my ( $header, $value ) = split ( /:\s*/, $line, 2 );
    if ( !defined $value ) {
      protocol_error("(header not in 'Name: value' format)");
      return 1;
    }

    my $ent = $subs->{$header};
    if ( $ent && &{$ent}( $hdrs, $header, $value ) ) {
      return 1;
    }
  }

  # avoid too-many-headers DOS attack
  protocol_error("(too many headers)");
  return 1;
}

# We'll run handle user unless we've been told not
# to process per-user config files.  Otherwise
# we'll check and see if we need to try SQL
# lookups.  If $opt{'user-config'} is true, we need to try
# their config file and then do the SQL lookup.
# If $opt{'user-config'} IS NOT true, we skip the conf file and
# only need to do the SQL lookup if $opt{'sql-config'} IS
# true.  (I got that wrong the first time.)
#
sub got_user_header {
  my ( $client, $header, $value ) = @_;

  if ( $value !~ /^([\x20-\xFF]*)$/ ) {
    protocol_error("(User header contains control chars)");
    return 1;
  }

  $current_user = $1;
  if ($opt{'auth-ident'} && !auth_ident($current_user)) {
    return 1;
  }

  if ( !$opt{'user-config'} ) {
    if ( $opt{'sql-config'} ) {
      unless ( handle_user_sql($current_user) ) {
        service_unavailable_error("Error fetching user preferences via SQL");
	return 1;
      }
    }
    elsif ( $opt{'ldap-config'} ) {
      handle_user_ldap($current_user);
    }
    elsif ( $opt{'virtual-config-dir'} ) {
      handle_virtual_config_dir($current_user);
    }
    elsif ( $opt{'setuid-with-sql'} ) {
      unless ( handle_user_setuid_with_sql($current_user) ) {
        service_unavailable_error("Error fetching user preferences via SQL");
	return 1;
      }
      $setuid_to_user = 1;    #to benefit from any paranoia.
    }
    elsif ( $opt{'setuid-with-ldap'} ) {
      handle_user_setuid_with_ldap($current_user);
      $setuid_to_user = 1;    # as above
    }
  }
  else {
    handle_user($current_user);
    if ( $opt{'sql-config'} ) {
      unless ( handle_user_sql($current_user) ) {
        service_unavailable_error("Error fetching user preferences via SQL");
	return 1;
      }
    }
  }
  return 0;
}

sub got_clen_header {
  my ( $hdrs, $header, $value ) = @_;
  if ( $value !~ /^(\d*)$/ ) {
    protocol_error("(Content-Length contains non-numeric bytes)");
    return 1;
  }
  $hdrs->{expected_length} = $1;
  return 0;
}

sub protocol_error {
  my ($err) = @_;
  my $resp = "EX_PROTOCOL";
  print $client "SPAMD/1.0 $resphash{$resp} Bad header line: $err\r\n";
  logmsg("bad protocol: header error: $err");
}

sub service_unavailable_error {
  my ($err) = @_;
  my $resp = "EX_UNAVAILABLE";
  print $client "SPAMD/1.0 $resphash{$resp} Service Unavailable: $err\r\n";
  logmsg("service unavailable: $err");
}

###########################################################################

sub auth_ident {
  my $username = shift;
  my $ident_username = ident_lookup( $client, $opt{'ident-timeout'} );
  my $dn = $ident_username || 'NONE';    # display name
  warn "ident_username = $dn, spamc_username = $username\n" if $opt{'debug'};
  if ( $username ne $ident_username ) {
    logmsg( "fatal: ident username ($dn) does not match "
        . "spamc username ($username)" );
    return 0;
  }
  return 1;
}

sub handle_user {
  my $username = shift;

  #
  # If vpopmail config enabled then look up userinfo for vpopmail uid
  # as defined by $opt{'username'} or as passed via $username
  #
  my $userid = '';
  if ( $opt{'vpopmail'} && $opt{'username'} ) {
    $userid = $opt{'username'};
  }
  else {
    $userid = $username;
  }
  my ( $name, $pwd, $uid, $gid, $quota, $comment, $gcos, $dir, $etc ) =
    'nobody';

  if ( !$spamtest->{'paranoid'} && !defined($uid) ) {

    #if we are given a username, but can't look it up,
    #Maybe NIS is down? lets break out here to allow
    #them to get 'defaults' when we are not running paranoid.
    logmsg("handle_user: unable to find user '$userid'!");
    return 0;
  }

  # not sure if this is required, the doco says it isn't
  $uid =~ /^(\d+)$/ and $uid = $1;    # de-taint
  $gid =~ /^(\d+)$/ and $gid = $1;    # de-taint

  if ($setuid_to_user) {
    $) = "$gid $gid";                 # change eGID
    $> = $uid;                        # change eUID
    if ( !defined($uid) || ( $> != $uid and $> != ( $uid - 2**32 ) ) ) {
      logmsg("fatal: setuid to $username failed");
      die;                            # make it fatal to avoid security breaches
    }
    else {
      logmsg("info: setuid to $username succeeded");
    }
  }

  #
  # If vpopmail config enabled then set $dir to virtual homedir
  #
  if ( $opt{'vpopmail'} ) {
    $dir = `$dir/bin/vuserinfo -d $username`;
    chomp($dir);
  }
  my $cf_file = $dir . "/.spamassassin/user_prefs";

  #
  # If vpopmail config enabled then pass virtual homedir onto create_default_cf_needed
  #
  if ( $opt{'vpopmail'} ) {
    if ( !$opt{'username'} ) {
      warn "cannot use vpopmail without -u\n";
    }
    create_default_cf_if_needed( $cf_file, $username, $dir );
    $spamtest->read_scoreonly_config($cf_file);
    $spamtest->signal_user_changed(
      {
        username => $username,
        user_dir => $dir
      }
    );

  }
  else {
    create_default_cf_if_needed( $cf_file, $username );
    $spamtest->read_scoreonly_config($cf_file);
    $spamtest->signal_user_changed(
      {
        username => $username,
        user_dir => $dir
      }
    );
  }

  return 1;
}

# Handle user configs without the necessity of having individual users or a
# SQL/LDAP database.
sub handle_virtual_config_dir {
  my ($username) = @_;

  my $dir = $opt{'virtual-config-dir'};
  my $userdir;
  my $prefsfile;

  if ( defined $dir ) {
    my $safename = $username;
    $safename =~ s/[^-A-Za-z0-9\+_\.\,\@\=]/_/gs;
    my $localpart = '';
    my $domain    = '';
    if ( $safename =~ /^(.*)\@(.*)$/ ) { $localpart = $1; $domain = $2; }

    $dir =~ s/\%u/${safename}/g;
    $dir =~ s/\%l/${localpart}/g;
    $dir =~ s/\%d/${domain}/g;
    $dir =~ s/\%\%/\%/g;

    $userdir   = $dir;
    $prefsfile = $dir . '/user_prefs';

    # Log that the default configuration is being used for a user.
    logmsg("Using default config for $username: $prefsfile");
  }

  if ( -f $prefsfile ) {

    # Found a config, load it.
    $spamtest->read_scoreonly_config($prefsfile);
  }

  # assume that $userdir will be a writable directory we can
  # use for AWL, Bayes dbs etc.
  $spamtest->signal_user_changed(
    {
      username => $username,
      userstate_dir => $userdir,
      user_dir => $userdir
    }
  );
  return 1;
}

sub handle_user_sql {
  my ($username) = @_;

  unless ( $spamtest->load_scoreonly_sql($username) ) {
    return 0;
  }
  $spamtest->signal_user_changed(
    {
      username => $username,
      user_dir => undef
    }
  );
  return 1;
}

sub handle_user_ldap {
  my $username = shift;
  Mail::SpamAssassin::dbg("handle_user_ldap($username)");
  $spamtest->load_scoreonly_ldap($username);
  $spamtest->signal_user_changed(
    {
      username => $username,
      user_dir => undef
    }
  );
  return 1;
}

sub handle_user_setuid_with_sql {
  my $username = shift;
  my ( $name, $pwd, $uid, $gid, $quota, $comment, $gcos, $dir, $etc ) =
    'nobody';

  if ( !$spamtest->{'paranoid'} && !defined($uid) ) {

    #if we are given a username, but can't look it up,
    #Maybe NIS is down? lets break out here to allow
    #them to get 'defaults' when we are not running paranoid.
    logmsg("handle_user() -> unable to find user [$username]!\n");
    return 0;
  }

  $uid =~ /^(\d+)$/ and $uid = $1;    # de-taint
  $gid =~ /^(\d+)$/ and $gid = $1;    # de-taint

  if ($setuid_to_user) {
    $) = "$gid $gid";                 # change eGID
    $> = $uid;                        # change eUID
    if ( !defined($uid) || ( $> != $uid and $> != ( $uid - 2**32 ) ) ) {
      logmsg("fatal: setuid to $username failed");
      die;                            # make it fatal to avoid security breaches
    }
    else {
      logmsg("info: setuid to $username succeeded, reading scores from SQL.");
    }
  }

  my $spam_conf_dir = $dir . '/.spamassassin';    #needed for AWL, Bayes, etc.
  if ( !-d $spam_conf_dir ) {
    if ( mkdir $spam_conf_dir, 0700 ) {
      logmsg("info: created $spam_conf_dir for $username.");
    }
    else {
      logmsg("info: failed to create $spam_conf_dir for $username.");
    }
  }

  unless ( $spamtest->load_scoreonly_sql($username) ) {
    return 0;
  }

  $spamtest->signal_user_changed( { username => $username } );
  return 1;
}

sub handle_user_setuid_with_ldap {
  my $username = shift;
  my ( $name, $pwd, $uid, $gid, $quota, $comment, $gcos, $dir, $etc ) =
    'nobody';

  if ( !$spamtest->{'paranoid'} && !defined($uid) ) {

    #if we are given a username, but can't look it up,
    #Maybe NIS is down? lets break out here to allow
    #them to get 'defaults' when we are not running paranoid.
    logmsg("handle_user() -> unable to find user [$username]!\n");
    return 0;
  }

  if ($setuid_to_user) {
    $) = "$gid $gid";    # change eGID
    $> = $uid;           # change eUID
    if ( !defined($uid) || ( $> != $uid and $> != ( $uid - 2**32 ) ) ) {
      logmsg("fatal: setuid to $username failed");
      die;               # make it fatal to avoid security breaches
    }
    else {
      logmsg("info: setuid to $username succeeded, reading scores from LDAP.");
    }
  }

  my $spam_conf_dir = $dir . '/.spamassassin';    #needed for AWL, Bayes, etc.
  if ( !-d $spam_conf_dir ) {
    if ( mkdir $spam_conf_dir, 0700 ) {
      logmsg("info: created $spam_conf_dir for $username.");
    }
    else {
      logmsg("info: failed to create $spam_conf_dir for $username.");
    }
  }

  $spamtest->load_scoreonly_ldap($username);

  $spamtest->signal_user_changed( { username => $username } );
  return 1;
}

sub create_default_cf_if_needed {
  my ( $cf_file, $username, $userdir ) = @_;

  # Parse user scores, creating default .cf if needed:
  if ( !-r $cf_file && !$spamtest->{'dont_copy_prefs'} ) {
    logmsg("Creating default_prefs [$cf_file]");

    # If vpopmail config enabled then pass virtual homedir onto
    # create_default_prefs via $userdir
    $spamtest->create_default_prefs( $cf_file, $username, $userdir );

    if ( !-r $cf_file ) {
      logmsg("Couldn't create readable default_prefs for [$cf_file]");
    }
  }
}

# sig handlers: parent process
sub setup_parent_sig_handlers {
  $SIG{HUP}  = \&restart_handler;
  $SIG{CHLD} = \&child_handler;
  $SIG{INT}  = \&kill_handler;
  $SIG{TERM} = \&kill_handler;
}

# sig handlers: child processes
sub setup_child_sig_handlers {
  # note: all the signals changed in setup_parent_sig_handlers() must
  # be reset to appropriate values here!
  $SIG{HUP} = $SIG{CHLD} = $SIG{INT} = $SIG{TERM} = 'DEFAULT';
}

sub logmsg {
  my $msg = join ( " ", @_ );
  $msg =~ s/[\r\n]+$//;       # remove any trailing newlines
  $msg =~ s/[\x00-\x1f]/_/g;  # replace all other control chars with underscores

  warn "logmsg: $msg\n" if $opt{'debug'};

  # log to file:
  #   bug 1360 <http://bugzilla.spamassassin.org/show_bug.cgi?id=1360>
  #   enable logging to a file via --syslog=file or --syslog=/path/to/file
  # log to STDERR:
  #   bug 605  <http://bugzilla.spamassassin.org/show_bug.cgi?id=605>
  #   more efficient for daemontools if --syslog=stderr is used
  if ( $log_socket eq 'file' ) {
    logmsg_file ($msg);
  }

  # log to syslog (if logging isn't disabled completely via 'null')
  elsif ( $log_socket ne 'none' ) {
    logmsg_syslog ($msg);
  }
}

sub logmsg_file {
  my $msg = shift;
  my @date = reverse( ( gmtime(time) )[ 0 .. 5 ] );
  $date[0] += 1900;
  $date[1] += 1;
  syswrite(
    STDLOG,
    sprintf(
      "%04d-%02d-%02d %02d:%02d:%02d [%s] %s: %s\n",
      @date, $$, 'i', $msg
    )
  );
}

sub logmsg_syslog {
  my $msg = shift;

  # install a new handler for SIGPIPE -- this signal has been
  # found to occur with syslog-ng after syslog-ng restarts.
  local $SIG{'PIPE'} = sub {
    $main::SIGPIPE_RECEIVED++;
    # force a log-close.
    closelog();
  };

  # important: do not call syslog() from the SIGCHLD handler
  # child_handler().   otherwise we can get into a loop if syslog()
  # forks a process -- as it does in syslog-ng apparently! (bug 3625)
  $main::INHIBIT_LOGGING_IN_SIGCHLD_HANDLER = 1;    #{
  eval { syslog( 'info', "%s", $msg ); };
  $main::INHIBIT_LOGGING_IN_SIGCHLD_HANDLER = 0;    #}

  if ($@) {
    if (check_syslog_sigpipe($msg)) {
      # dealt with
    }
    else {
      warn "syslog() failed: $@"; # includes a \n

      # only write this warning once.  it gets annoying fast
      if (!$already_done_syslog_failure_warning) {
        warn "try using --syslog-socket={unix,inet} or --syslog=file\n";
        $already_done_syslog_failure_warning = 1;
      }
    }
  }
  else {
    check_syslog_sigpipe($msg);       # check for SIGPIPE anyway (bug 3625)
  }
}

sub check_syslog_sigpipe {
  my ($msg) = @_;

  if ($main::SIGPIPE_RECEIVED)
  {
    # SIGPIPE received when writing to syslog -- close and reopen
    # the log handle, then try again.
    closelog();
    openlog_for_spamd();
    syslog( 'debug', "%s", "syslog reopened" );
    syslog( 'info', "%s", $msg );

    # now report what happend
    $msg = "SIGPIPE received, reopening log socket";
    warn "logmsg: $msg\n" if $opt{'debug'};
    syslog( 'warning', "%s", $msg );

    # if we've received multiple sigpipes, logging is probably
    # still broken.
    if ( $main::SIGPIPE_RECEIVED > 1 ) {
      warn "logging failure: multiple SIGPIPEs received\n";
    }

    $main::SIGPIPE_RECEIVED = 0;
    return 1;
  }

  return 0;     # didn't have a SIGPIPE
}

sub openlog_for_spamd {
  openlog( 'spamd', 'cons,pid,ndelay', $log_facility );
}

sub kill_handler {
  my ($sig) = @_;
  logmsg("server killed by SIG$sig, shutting down");
  $server->close;

  if (defined($opt{'pidfile'})) {
    unlink($opt{'pidfile'}) || warn "Can't unlink $opt{'pidfile'}: $!\n";
  }

  # the UNIX domain socket
  if (defined($opt{'socketpath'})) {
    unlink($opt{'socketpath'}) || warn "Can't unlink $opt{'socketpath'}: $!\n";
  }

  $SIG{CHLD} = 'DEFAULT';    # we're going to kill our children
  kill 'INT' => keys %children;
  exit 0;
}

# takes care of dead children
sub child_handler {
  my ($sig) = @_;

  unless ($main::INHIBIT_LOGGING_IN_SIGCHLD_HANDLER) {
    logmsg("server hit by SIG$sig");
  }

  # clean up any children which have exited
  while((my $pid = waitpid(-1, WNOHANG)) > 0) {
    # remove them from our child listing
    delete $children{$pid};

    unless ($main::INHIBIT_LOGGING_IN_SIGCHLD_HANDLER) {
      logmsg("handled cleanup of child pid $pid");
    }
  }

  $SIG{CHLD} = \&child_handler;    # reset as necessary, should be at end
}

sub restart_handler {
  my ($sig) = @_;
  logmsg("server hit by SIG$sig, restarting");

  $SIG{CHLD} = 'DEFAULT';    # we're going to kill our children
  foreach (keys %children) {
    kill 'INT' => $_;
    my $pid = waitpid($_, 0);
    logmsg("child $pid killed successfully");
  }
  %children = ();

  unless ( $server->eof ) {
    $server->shutdown(2);
    $server->close;

    # the UNIX domain socket
    if (defined($opt{'socketpath'})) {
      unlink($opt{'socketpath'}) || warn "Can't unlink $opt{'socketpath'}: $!\n";
    }

    warn "server socket closed\n" if $opt{'debug'};
  }
  $got_sighup = 1;
}

sub daemonize {

  # Pretty command line in ps
  $0 = join ( ' ', $ORIG_ARG0, @ORIG_ARGV ) unless ( $opt{'debug'} );

  # Be a nice daemon and chdir() to the root so we don't block any unmount attempts
  chdir '/' or die "Can't chdir to /: $!\n";

  # Redirect all warnings to logmsg()
  $SIG{__WARN__} = sub { logmsg( $_[0] ); };

  # Redirect in and out to the bit bucket
  open STDIN,  "</dev/null" or die "Can't read from /dev/null: $!\n";
  open STDOUT, ">/dev/null" or die "Can't write to /dev/null: $!\n";

  # Here we go...
  defined( my $pid = fork ) or die "Can't fork: $!\n";
  exit if $pid;
  setsid or die "Can't start new session: $!\n";

  # Now we can redirect the errors, too.
  open STDERR, '>&STDOUT' or die "Can't duplicate stdout: $!\n";

  Mail::SpamAssassin::dbg('daemonized.');
}

sub set_allowed_ip {
  foreach (@_) {
    $allowed_nets->add_cidr($_) or die "Aborting.\n";
  }
}

sub ip_is_allowed {
  $allowed_nets->contains_ip(@_);
}

sub preload_modules_with_tmp_homedir {

  # set $ENV{HOME} in /tmp while we compile and preload everything.
  # File::Spec->tmpdir uses TMPDIR, TMP, TEMP, C:/temp, /tmp etc.
  my $tmpdir = File::Spec->tmpdir();
  if ( !$tmpdir ) {
    die "cannot find writable tmp dir! set TMP or TMPDIR in env";
  }

  # If TMPDIR isn't set, File::Spec->tmpdir() will set it to undefined.
  # that then breaks other things ...
  delete $ENV{'TMPDIR'} if ( !defined $ENV{'TMPDIR'} );

  my $tmphome = File::Spec->catdir( $tmpdir, "spamd-$$-init" );
  $tmphome = Mail::SpamAssassin::Util::untaint_file_path($tmphome);

  my $tmpsadir = File::Spec->catdir( $tmphome, ".spamassassin" );

  Mail::SpamAssassin::dbg("Preloading modules with HOME=$tmphome");

  mkdir( $tmphome,  0700 ) or die "fatal: Can't create $tmphome: $!";
  mkdir( $tmpsadir, 0700 ) or die "fatal: Can't create $tmpsadir: $!";
  $ENV{HOME} = $tmphome;

  $spamtest->compile_now(0,1);  # ensure all modules etc. are loaded
  $/ = "\n";                    # argh, Razor resets this!  Bad Razor!

  # now clean up the stuff we just created, and make us taint-safe
  delete $ENV{HOME};

  # bug 2015, bug 2223: rmpath() is not taint safe, so we've got to implement
  # our own poor man's rmpath. If it fails, we report only the first error.
  my $err;
  foreach my $d ( ( $tmpsadir, $tmphome ) ) {
    opendir( TMPDIR, $d ) or $err ||= "open $d: $!";
    unless ($err) {
      foreach my $f ( File::Spec->no_upwards( readdir(TMPDIR) ) ) {
        $f =
          Mail::SpamAssassin::Util::untaint_file_path(
          File::Spec->catfile( $d, $f ) );
        unlink($f) or $err ||= "remove $f: $!";
      }
      closedir(TMPDIR) or $err ||= "close $d: $!";
    }
    rmdir($d) or $err ||= "remove $d: $!";
  }

  # If the dir still exists, log a warning.
  if ( -d $tmphome ) {
    $err ||= "do something: $!";
    warn "Failed to remove $tmphome: Could not $err\n";
  }
}

__DATA__

=head1 NAME

spamd - daemonized version of spamassassin

=head1 SYNOPSIS

spamd [options]

Options:

 -c, --create-prefs                 Create user preferences files
 -C path, --configpath=path         Path for default config files
 --siteconfigpath=path              Path for site configs
 -d, --daemonize                    Daemonize
 -h, --help                         Print usage message.
 -i [ipaddr], --listen-ip=ipaddr    Listen on the IP ipaddr
 -p port, --port                    Listen on specified port
 -m num, --max-children=num         Allow maximum num children
 --max-conn-per-child=num	    Maximum connections accepted by child 
                                    before it is respawned
 -q, --sql-config                   Enable SQL config (only useful with -x)
 -Q, --setuid-with-sql              Enable SQL config (only useful with -x,
                                    enables use of -H)
 --ldap-config                      Enable LDAP config (only useful with -x)
 --setuid-with-ldap                 Enable LDAP config (only useful with -x,
                                    enables use of -a and -H)
 --virtual-config-dir=dir           Enable pattern based Virtual configs
                                    (needs -x)
 -r pidfile, --pidfile              Write the process id to pidfile
 -s facility, --syslog=facility     Specify the syslog facility
 --syslog-socket=type               How to connect to syslogd
 -u username, --username=username   Run as username
 -v, --vpopmail                     Enable vpopmail config
 -x, --nouser-config                Disable user config files
 --auth-ident                       Use ident to authenticate spamc user
 --ident-timeout=timeout            Timeout for ident connections
 -A host,..., --allowed-ips=..,..   Limit ip addresses which can connect
 -D, --debug                        Print debugging messages
 -L, --local                        Use local tests only (no DNS)
 -P, --paranoid                     Die upon user errors
 -H [dir], --helper-home-dir[=dir]  Specify a different HOME directory
 --ssl                              Run an SSL server
 --server-key keyfile               Specify an SSL keyfile
 --server-cert certfile             Specify an SSL certificate
 --socketpath=path                  Listen on given UNIX domain socket
 --socketowner=name                 Set UNIX domain socket file's owner
 --socketgroup=name                 Set UNIX domain socket file's group
 --socketmode=mode                  Set UNIX domain socket file's mode

=head1 DESCRIPTION

The purpose of this program is to provide a daemonized version of the
spamassassin executable.  The goal is improving throughput performance for
automated mail checking.

This is intended to be used alongside C<spamc>, a fast, low-overhead C client
program.

See the README file in the C<spamd> directory of the SpamAssassin distribution
for more details.

Note: Although C<spamd> will check per-user config files for every message, any
changes to the system-wide config files will require either restarting spamd
or forcing it to reload itself via B<SIGHUP> for the changes to take effect.

Note: If C<spamd> receives a B<SIGHUP>, it internally reloads itself, which means
that it will change its pid and might not restart at all if its environment
changed  (ie. if it can't change back into its own directory).  If you plan
to use B<SIGHUP>, you should always start C<spamd> with the B<-r> switch to know its
current pid.

=head1 OPTIONS

Options of the long form can be shortened as long as they remain
unambiguous.  (i.e. B<--dae> can be used instead of B<--daemonize>)
Also, boolean options (like B<--user-config>) can be negated by
adding I<no> (B<--nouser-config>), however, this is usually unnecessary.

=over 4

=item B<-c>, B<--create-prefs>

Create user preferences files if they don't exist (default: don't).

=item B<-C> I<path>, B<--configpath>=I<path>

Use the specified path for locating the distributed configuration files.
Ignore the default directories (usually C</usr/share/spamassassin> or similar).

=item B<--siteconfigpath>=I<path>

Use the specified path for locating site-specific configuration files.  Ignore
the default directories (usually C</etc/mail/spamassassin> or similar).

=item B<-d>, B<--daemonize>

Detach from starting process and run in background (daemonize).

=item B<-h>, B<--help>

Print a brief help message, then exit without further action.

=item B<-i> [I<ipaddress>], B<--listen-ip>[=I<ipaddress>], B<--ip-address>[=I<ipaddress>]

Tells spamd to listen on the specified IP address (defaults to 127.0.0.1).  If
you specify no IP address after the switch, spamd will listen on all interfaces.
(This is equal to the address 0.0.0.0).  You can also use a valid hostname which
will make spamd listen on the first address that name resolves to.

=item B<-p> I<port>, B<--port>=I<port>

Optionally specifies the port number for the server to listen on (default: 783).

Note: If spamd is set to run as a non-root user (-u), and is to run on
a privileged port (any < 1024), the parent will not be able to be sent
a SIGHUP to reload the configuration.

=item B<-q>, B<--sql-config>

Turn on SQL lookups even when per-user config files have been disabled
with B<-x>. this is useful for spamd hosts which don't have user's
home directories but do want to load user preferences from an SQL
database.

If your spamc client does not support sending the C<User:> header,
like C<exiscan>, then the SQL username used will always be B<nobody>.

=item B<--ldap-config>

Turn on LDAP lookups. This is completely analog to C<--sql-config>,
only it is using an LDAP server.

=item B<-Q>, B<--setuid-with-sql>

Turn on SQL lookups even when per-user config files have been disabled
with B<-x> and also setuid to the user.  This is useful for spamd hosts
which want to load user preferences from an SQL database but also wish to
support the use of B<-a> (AWL) and B<-H> (Helper home directories.)

=item B<--setuid-with-ldap>

Turn on LDAP lookups even when per-user config files have been disabled
with B<-x> and also setuid to the user.  This is again completely analog
to C<--setuid-with-sql>, only it is using an LDAP server.

=item B<--virtual-config-dir>=I<pattern>

This option specifies where per-user preferences can be found for virtual
users, for the B<-x> switch. The I<pattern> is used as a base pattern for the
directory name.  Any of the following escapes can be used:

=over 4

=item %u -- replaced with the full name of the current user, as sent by spamc.

=item %l -- replaced with the 'local part' of the current username.  In other
words, if the username is an email address, this is the part before the C<@>
sign.

=item %d -- replaced with the 'domain' of the current username.  In other
words, if the username is an email address, this is the part after the C<@>
sign.

=item %% -- replaced with a single percent sign (%).

=back

So for example, if C</vhome/users/%u/spamassassin> is specified, and spamc
sends a virtual username of C<jm@example.com>, the directory
C</vhome/users/jm@example.com/spamassassin> will be used.

The set of characters allowed in the virtual username for this path are
restricted to:

	A-Z a-z 0-9 - + _ . , @ =

All others will be replaced by underscores (C<_>).

This path must be a writable directory.  It will be created if it does not
already exist.  If a file called B<user_prefs> exists in this directory (note:
B<not> in a C<.spamassassin> subdirectory!), it will be loaded as the user's
preferences.  The auto-whitelist and/or Bayes databases for that user will be
stored in this directory.

Note that this B<requires> that B<-x> is used, and cannot be combined with
SQL- or LDAP-based configuration.

The pattern B<must> expand to an absolute directory when spamd is running
daemonized (B<-d>).

=item B<-r> I<pidfile>, B<--pidfile>=I<pidfile>

Write the process ID of the spamd parent to the file specified by I<pidfile>.
The file will be unlinked when the parent exits.  Note that when running
with the B<-u> option, the file must be writable by that user.

=item B<-v>, B<--vpopmail>

Enable vpopmail config.  If specified with with B<-u> set to the vpopmail user,
this allows spamd to lookup/create user_prefs in the vpopmail user's own
maildir.  This option is useful for vpopmail virtual users who do not have an
entry in the system /etc/passwd file.

Currently, use of this without B<-u> is not supported.

=item B<-s> I<facility>, B<--syslog>=I<facility>

Specify the syslog facility to use (default: mail).  If C<stderr> is specified,
output will be written to stderr. (This is useful if you're running C<spamd>
under the C<daemontools> package.) With a I<facility> of C<file>, all output
goes to spamd.log. I<facility> is interpreted as a file name to log to if it
contains any characters except a-z and 0-9. C<null> disables logging completely
(used internally).

Examples:
	spamd -s mail                 # use syslog, facility mail (default)
	spamd -s ./mail               # log to file ./mail
	spamd -s stderr 2>/dev/null   # log to stderr, throw messages away
	spamd -s null                 # the same as above
	spamd -s file                 # log to file ./spamd.log
	spamd -s /var/log/spamd.log   # log to file /var/log/spamd.log

If logging to a file is enabled and that log file is rotated, the spamd server
must be restarted with a SIGHUP. (If the log file is just truncated, this is
not needed but still recommended.)

=item B<--syslog-socket>=I<type>

Specify how spamd should send messages to syslogd.  The options are C<unix>,
C<inet> or C<none>.   The default is to try C<unix> first, falling back to
C<inet> if perl detects errors in its C<unix> support.

Some platforms, or versions of perl, are shipped with dysfunctional versions of
the B<Sys::Syslog> package which do not support some socket types, so you may
need to set this.  If you get error messages regarding B<__PATH_LOG> or similar
from spamd, try changing this setting.

The socket type C<file> is used internally and should not be specified.

=item B<-u> I<username>, B<--username>=I<username>

Run as the named user.  If this option is not set, the default behaviour
is to setuid() to the user running C<spamc>, if C<spamd> is running
as root.

Note: "--username=root" disables the setuid() functionality and leaves
spamd running as root.

Note: If this option is set to a non-root user, and spamd is to run on
a privileged port (any < 1024, default 783 or via -p), the parent will
not be able to be sent a SIGHUP to reload the configuration.

=item B<-x>, B<--nouser-config>, B<--user-config>

Turn off(on) reading of per-user configuration files (user_prefs) from the
user's home directory.  The default behaviour is to read per-user
configuration from the user's home directory.

This option does not disable or otherwise influence the SQL, LDAP or
Virtual Config Dir settings.

=item B<--auth-ident>

Verify the username provided by spamc using ident.  This is only
useful if connections are only allowed from trusted hosts (because an
identd that lies is trivial to create) and if spamc REALLY SHOULD be
running as the user it represents.  Connections are terminated
immediately if authentication fails.  In this case, spamc will pass
the mail through unchecked.  Failure to connect to an ident server,
and response timeouts are considered authentication failures.  This
requires that Net::Ident be installed.

=item B<--ident-timeout>=I<timeout>

Wait at most I<timeout> seconds for a response to ident queries.
Authentication that takes long that I<timeout> seconds will fail, and
mail will not be processed.  Setting this to 0.0 or less results in no
timeout, which is STRONGLY discouraged.  The default is 5 seconds.

=item B<-A> I<host,...>, B<--allowed-ips>=I<host,...>

Specify a list of authorized hosts or networks which can connect to this spamd
instance. Single IP addresses can be given, ranges of IP addresses in
address/masklength CIDR format, or ranges of IP addresses by listing 3 or less
octets with a trailing dot.  Hostnames are not supported, only IP addresses.
This option can be specified multiple times, or can take a list of addresses
separated by commas.  Examples:

B<-A 10.11.12.13> -- only allow connections from C<10.11.12.13>.

B<-A 10.11.12.13,10.11.12.14> -- only allow connections from C<10.11.12.13> and
C<10.11.12.14>.

B<-A 10.200.300.0/24> -- allow connections from any machine in the range
C<10.200.300.*>.

B<-A 10.> -- allow connections from any machine in the range C<10.*.*.*>.

By default, connections are only accepted from localhost [127.0.0.1].

=item B<-D>, B<--debug>

Print debugging messages

=item B<-L>, B<--local>

Perform only local tests on all mail.  In other words, skip DNS and other
network tests.  Works the same as the C<-L> flag to C<spamassassin(1)>.

=item B<-P>, B<--paranoid>

Die on user errors (for the user passed from spamc) instead of falling back to
user I<nobody> and using the default configuration.

=item B<-m> I<number> , B<--max-children>=I<number>

This option specifies the maximum number of children to spawn.
Spamd will spawn that number of children, then sleep in the background
until a child dies, wherein it will go and spawn a new child.

Incoming connections can still occur if all of the children are busy,
however those connections will be queued waiting for a free child.
The minimum value is C<1>, the default value is C<5>.

Please note that there is a OS specific maximum of connections that can be
queued (Try C<perl -MSocket -e'print SOMAXCONN'> to find this maximum).

=item B<--max-conn-per-child>=I<number>

This option specifies the maximum number of connections each child
should process before dying and letting the master spamd process spawn
a new child.  The minimum value is C<1>, the default value is C<200>.

=item B<-H> I<directory>, B<--helper-home-dir>=I<directory>

Specify that external programs such as Razor, DCC, and Pyzor should have
a HOME environment variable set to a specific directory.  The default
is to use the HOME environment variable setting from the shell running
spamd.  By specifying no argument, spamd will use the spamc caller's
home directory instead.

=item B<--ssl>

Accept only SSL connections.  The B<IO::Socket::SSL> perl module must be
installed.

=item B<--server-key> I<keyfile>

Specify the SSL key file to use for SSL connections.

=item B<--server-cert> I<certfile>

Specify the SSL certificate file to use for SSL connections.

=item B<--socketpath> I<pathname>

Listen on UNIX domain path I<pathname> instead of a TCP socket.

=item B<--socketowner> I<name>

Set UNIX domain socket to be owned by the user named I<name>.  Note
that this requires that spamd be started as C<root>, and if C<-u>
is used, that user should have write permissions to unlink the file
later, for when the C<spamd> server is killed.

=item B<--socketgroup> I<name>

Set UNIX domain socket to be owned by the group named I<name>.  See
C<--socketowner> for notes on ownership and permissions.

=item B<--socketmode> I<mode>

Set UNIX domain socket to use the octal mode I<mode>.  Note that if C<-u> is
used, that user should have write permissions to unlink the file later, for
when the C<spamd> server is killed.

=back

=head1 SEE ALSO

spamc(1)
spamassassin(1)
Mail::SpamAssassin::Conf(3)
Mail::SpamAssassin(3)

=head1 PREREQUISITES

C<Mail::SpamAssassin>

=head1 AUTHORS

The SpamAssassin(tm) Project (http://spamassassin.apache.org/)

=head1 LICENSE

SpamAssassin is distributed under the Apache License, Version 2.0, as
described in the file C<LICENSE> included with the distribution.

=cut

__END__
:endofperl
