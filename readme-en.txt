¡IMPORTANT

  >>>  Please use this own risk!  <<<

In spamd.bat.  Perl is installed on "C:\usr\Perl".

You must set on "C:\usr\Perl\site\etc\mail\spamassassin\local.cf"

report_safe 0

Otherwize (i.e. report_safe 1 | 2, default is 1) XMail spool file's
first 6 lines will be overwrite ,when judged SPAM by SpamAssassin. 
that brings purge mail !!!

To use Mail Rule on OutlookExpress . You may set on 
 "C:\usr\Perl\site\etc\mail\spamassassin\local.cf"

rewrite_header Subject *****SPAM*****


¡ 
  this document is written "2005-01-11".

    please contact blade2001jp@ybb.ne.jp

on enveronment

	XMail-1.20
	SpamAssassin 3.0.2

 I changed spamc.exe to xmspamc.exe for XMail Server's filter.
if you are not windows user. build xmspamc.c 
 ( but _splitpath may be windows function. sorry )

¡ xmspamc.exe

SpamAssassin Client for XMailServer Filter version 3.0.2

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
to "c:\usr\perl" enveronment.

to install SpamAssassin-3.0.2 on windows. please visit
http://wiki.apache.org/spamassassin/InstallingOnWindows


¡ spamassassin.tab
  this is sample. please change Path_to_spamc to full path of
xmspamc.exe. and change tempdir to your temporary directory.

 add xmail/MailRoot/filters.in.tab below

"*"	"*"	"0.0.0.0/0"	"0.0.0.0/0"	spamassassin.tab

and copy spamassassin.tab to xmail/MailRoot/filters folder.


