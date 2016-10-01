
this document is written "2005-08-25".

    please contact blade2001jp@ybb.ne.jp

  this filter had written based on SpamAssassin-3.0.2's spamc.c.
  xmspamc.exe (windows platform) work well
	XMailServer-1.21
	SpamAssassin-3.0.2, 3.0.3, 3.0.4

  this filter may be work other platforms, building xmspamc.c .
  but only _splitpath in xmspamc.c may be need to fix.
  to build xmspamc.exe rewrite "makefile" spamc -> xmspamc.


¡IMPORTANT

  >>>  Please use this own risk!  <<<

 Perl path is set to "c:/usr/perl" in spamd.bat. 

To use Mail Rule on OutlookExpress . You may set on 
 "C:\usr\Perl\site\etc\mail\spamassassin\local.cf"

rewrite_header Subject *****SPAM*****

¡ HISTORY

ver 0.11
 2005/01/13 FIX bug -b option always enabled.
ver 0.12
 2005/01/23 FIX unmuch perl path between this document and spamd.bat.
ver 0.2
 2005/08/20 FIX miss comment on spamd.bat.
 2005/08/20 FIX bug change filter result code 5 to 4 
                (change "reject and spool" to "reject without spool")
 2005/08/20 FIX report_safe = 0 is no longer needed on local.cf
 2005/08/24 FIX modify last few bytes of LF code to CR+LF code.
                (i don't know why. but some mailer causes a timeout error)
 2005/08/26 stable release
 2005/08/31 ADD -P option. 

¡ xmspamc.exe

SpamAssassin Client Filter ver 0.21 for XMailServer
  based on spamc 3.0.2 mixed spamc 3.0.4

Usage: xmspamc [@@FILE] [tempdir] [options]

Options:
  -d host             Specify host to connect to.
                      [default: localhost]
  -H                  Randomize IP addresses for the looked-up
                      hostname.
  -p port             Specify port for connection to spamd.
                      [default: 783]
  -t timeout          Timeout in seconds for communications to
                      spamd. [default: 600]
  -s size             Specify maximum message size, in k-bytes.
                      [default: 250k]
  -u username         User for spamd to process this message under.
                      [default: current user]
  -x                  Don't fallback safely.
  -l                  Log errors and warnings to stderr.
  -D remove_score     Spam Score that reject and remove mail.
                      [default:11.0]
  -b                  Reject on error EX_TOOBIG and filterd IS_SPAM.
                      [default accept mail]
  -h                  Print this help message and exit.
  -V                  Print xmspamc version and exit.
  -P spool            Spool specification. 0 = without spool, 1 = spool
                      [default: 0]

===========================================================================
  @@FILE is XMailServerFilter parameter.

  tempdir  is temporary directory. 

  on -s option. large value will be looks like hung up. Therefore, 
  we will recommend the thing operated by 250k byte of an initial value. 

  default size is 250k. so large mail pass through by default. -b option 
  is filter to SpamAssassin a part of mail. and reject mail when judged spam.

¡spamd.bat

spamd.bat is rewrite SpamAssassin-3.0.2's  /spamd/spamd.raw. 
referencing http://wiki.apache.org/spamassassin/SpamdOnWindows
to "c:/usr/perl" enveronment.

 spamd is a daemon of SpamAssassin. you must run spamd to use xmspamc.

to install SpamAssassin on windows. please visit
http://wiki.apache.org/spamassassin/InstallingOnWindows


¡ spamassassin.tab
  this is sample of xmspamc's filter.tab for XMailServer. 
please change "Path_to_spamc" to full path of
xmspamc.exe. and change "Path_to_tempdir" to your temporary directory.

 add xmail/MailRoot/filters.in.tab below

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

and copy spamassassin.tab to xmail/MailRoot/filters folder.

