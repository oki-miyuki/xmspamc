/* <@LICENSE>
 * Copyright 2004 Apache Software Foundation
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * </@LICENSE>
 */

/*
 *  XMSpamc : SpamC for XMailServer Filter
 *    2005/01/11  OKI Miyuki   blade2001jp@ybb.ne.jp
 *  Based on SpamAssassin 3.0.2 spamc.c
 */

#include "config.h"
#include "version.h"
#include "libspamc.h"
#include "utils.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <malloc.h>

#include <io.h>
#include <fcntl.h>
#include <process.h>

#ifdef SPAMC_SSL
#include <openssl/crypto.h>
#ifndef OPENSSL_VERSION_TEXT
#define OPENSSL_VERSION_TEXT "OpenSSL"
#endif
#endif

#ifdef HAVE_SYSEXITS_H
#include <sysexits.h>
#endif
#ifdef HAVE_ERRNO_H
#include <errno.h>
#endif
#ifdef HAVE_SYS_ERRNO_H
#include <sys/errno.h>
#endif
#ifdef HAVE_TIME_H
#include <time.h>
#endif
#ifdef HAVE_SYS_TIME_H
#include <sys/time.h>
#endif
#ifdef HAVE_SIGNAL_H
#include <signal.h>
#endif
#ifdef HAVE_PWD_H
#include <pwd.h>
#endif

/* SunOS 4.1.4 patch from Tom Lipkis <tal@pss.com> */
#if (defined(__sun__) && defined(__sparc__) && !defined(__svr4__)) /* SunOS */ \
     || (defined(__sgi))  /* IRIX */ \
     || (defined(__osf__)) /* Digital UNIX */ \
     || (defined(hpux) || defined(__hpux)) /* HPUX */ \
     || (defined(__CYGWIN__))				/* CygWin, Win32 */

extern int optind;
extern char *optarg;

#endif

#ifdef _WIN32
#include "replace/getopt.h"
char *__progname = "xmspamc";
#endif


/* safe fallback defaults to on now - CRH */
int flags = SPAMC_RAW_MODE | SPAMC_SAFE_FALLBACK;

static int timeout = 600;
static int max_size = 250 * 1024;
static char *username = NULL;

static struct message m;

/* 
	for CUSTOMOPT 
	@remark different level of flags! additional option 
	must be set custom_opt. because mixing will be make bugs.
*/
static int custom_opt = 0;
#define CUSTOMOPT_NONE		0
#define	CUSTOMOPT_REJECT_BIGMSG	(1 << 0)	/* reject EX_TOOBIG and EX_ISSPAM */

/* input text file name that is replaced if success */
static char* input_text = NULL;
/* input file no */
int in_fd = -1;
/* temp text file name to replace if success */
static char* temp_text = NULL;
/* temp dir */
static char* temp_dir = NULL;
/* output file no */
int out_fd = -1;
/* spam score: deny and remove mail */
static float deny_score = 11.0;


/* XMailServer Filter's exit code */
#define XMAIL_FILTER_STOP				16	/* unload filter command = this program */
#define XMAIL_FILTER_FAIL				0		/* not touch */
#define XMAIL_FILTER_OK					0
#define XMAIL_FILTER_REJECT			5		/* reject spool file mail */
#define XMAIL_FILTER_REJECTMSG	6
#define XMAIL_FILTER_MODIFY			7		/* change spool file mail */



void print_version(void) {
	printf("%s version %s\n", "SpamAssassin Client for XMailServer Filter", VERSION_STRING);
#ifdef SPAMC_SSL
	printf("  compiled with SSL support (%s)\n", OPENSSL_VERSION_TEXT);
#endif
}

static void usg(char *str) {
	printf("%s", str);
}

void print_usage(void)
{
	print_version();
	usg("\n");
	usg("Usage: xmspamc [@@FILE] [tempdir] [options]\n");
	usg("\n");
	usg("Options:\n");

	usg("  -d host             Specify host to connect to.\n"
	    "                      [default: localhost]\n");
	usg("  -H                  Randomize IP addresses for the looked-up\n"
	    "                      hostname.\n");
	usg("  -p port             Specify port for connection to spamd.\n"
	    "                      [default: 783]\n");
#ifdef SPAMC_SSL
	usg("  -S                  Use SSL to talk to spamd.\n");
#endif
#ifndef _WIN32
	usg("  -U path             Connect to spamd via UNIX domain sockets.\n");
#endif
	usg("  -t timeout          Timeout in seconds for communications to\n"
	    "                      spamd. [default: 600]\n");
	usg("  -s size             Specify maximum message size, in k-bytes.\n"
	    "                      [default: 250k]\n");
	usg("  -u username         User for spamd to process this message under.\n"
	    "                      [default: current user]\n");
	usg("  -x                  Don't fallback safely.\n");
	usg("  -l                  Log errors and warnings to stderr.\n");
	usg("  -D remove_score     Spam Score that reject and remove mail.\n"
			"                      [default:11.0]\n");
	usg("  -b                  Reject on error EX_TOOBIG and filterd IS_SPAM.\n"
			"                      [default accept mail]\n");
	usg("  -h                  Print this help message and exit.\n");
	usg("  -V                  Print xmspamc version and exit.\n");
	usg("\n");
}

/**
 * Does the command line parsing for argv[].
 */
void read_args(
	int argc, char **argv,
	char** usr,
	struct transport *ptrn
)
{
#ifndef _WIN32
	const char *opts = "-d:Hp:SU:t:s:u:xlD:bhV";
#else
	const char *opts = "-d:Hp:St:s:u:xlD:bhV";
#endif
	int opt;

	char drive[ _MAX_DRIVE ];
	char dir[ _MAX_DIR ];
	char fname[ _MAX_FNAME ];
	char ext[ _MAX_EXT ];

	if( argc < 3 ) {
		print_usage();
		exit(XMAIL_FILTER_FAIL);
	}
	input_text	=	argv[1];
	++optind;
	temp_dir		=	argv[2];
	++optind;

	_splitpath( input_text, drive, dir, fname, ext );


#ifdef _WIN32
	/* remove "\\?\" from path-string */
	if( !strncmp( input_text, "\\\\?\\", 4 ) ) {
		input_text	+=	4;
	}
#endif
	temp_text	=	malloc( strlen(temp_dir) + strlen(fname) + 6 );
	if( temp_text == NULL ) {
		exit(XMAIL_FILTER_FAIL);
	}
	sprintf( temp_text, "%s\\%s.tmp", temp_dir, fname );

	while ((opt = getopt(argc, argv, opts)) != -1) {
		switch (opt) {
			case 'd': {
				ptrn->type = TRANSPORT_TCP;
				ptrn->hostname = optarg;        /* fix the ptr to point to this string */
				break;
			}
			case 'l': {	flags |= SPAMC_LOG_TO_STDERR; break; }
			case 'H': { flags |= SPAMC_RANDOMIZE_HOSTS; break; }
			case 'p': { ptrn->port = (unsigned short)atoi(optarg); break; }
			case 's': { max_size = atoi(optarg) * 1024; break; }
#ifdef SPAMC_SSL
			case 'S': { flags |= SPAMC_USE_SSL; break; }
#endif
			case 't': { timeout = atoi(optarg); break; }
			case 'u': { *usr = optarg; break; }
			case 'D': { deny_score = (float)atof(optarg); break; }
			case 'b': { custom_opt |= CUSTOMOPT_REJECT_BIGMSG; break; }
#ifndef _WIN32
			case 'U': {
				ptrn->type = TRANSPORT_UNIX;
				ptrn->socketpath = optarg;
				break;
			}
#endif
			case 'x': { flags &= (~SPAMC_SAFE_FALLBACK); break; }
			case '?':
			case ':': {
				libspamc_log(flags, LOG_ERR, "invalid usage");
				print_usage();
				exit(XMAIL_FILTER_FAIL);
			}
			case 'h': {
				print_usage();
				exit(XMAIL_FILTER_OK);
			}
			case 'V': {
				print_version();
				exit(XMAIL_FILTER_OK);
			}
		}
	}
}

/**********************************************************************
 * SET UP TRANSPORT
 *
 * This takes the user parameters and digs up what it can about how
 * we connect to the spam daemon. Mainly this involves lookup up the
 * hostname and getting the IP addresses to connect to.
 */
void setup_message( struct message* m ) {
	m->type			=	MESSAGE_NONE;
	m->out			=	NULL;
	m->raw			=	NULL;
	m->priv			=	NULL;
	m->max_len	=	max_size;
	m->timeout	=	timeout;
	m->is_spam	=	EX_NOHOST; /* default err code if can't reach the daemon */
}


/* open input text file */
int get_input_fd(int *fd) {
	if(*fd == -1) {
		*fd	=	open( input_text, _O_BINARY | _O_RDONLY );
		if(*fd == -1) {
			return EX_OSFILE;
		}
	}
	return EX_OK;
}

/* close file */
void close_fd(int *fd) {
	if(	*fd != -1 ) {
		close( *fd );
		*fd	=	-1;
	}
}

/* open output text file (temporary) */
int get_output_fd(int *fd) {
	if( *fd == -1 ) {
		*fd = open( temp_text, _O_CREAT | _O_BINARY | _O_WRONLY );
		if(*fd == -1) {
		    libspamc_log(flags, LOG_ERR, "fail to create: %m");
			return EX_CANTCREAT;
		}
	}
	return EX_OK;
}

/**
 * Determines the username of the uid spamc is running under.
 *
 * If the program's caller didn't identify the user to run as, use the
 * current user for this. Note that we're not talking about UNIX perm-
 * issions, but giving SpamAssassin a username so it can do per-user
 * configuration (whitelists & the like).
 *
 * Allocates memory for the username, returns EX_OK if successful.
 */
int get_current_user( const char* usr ) {
#ifndef _WIN32
    struct passwd *curr_user;
#endif

	if( username != NULL ) {
		return EX_OK;
	}

    if (usr != NULL) {
        username = strdup(usr);
		if (username == NULL)	return EX_OSERR;
		return EX_OK;
	}

#ifndef _WIN32
    
    /* Get the passwd information for the effective uid spamc is running
     * under. Setting errno to zero is recommended in the manpage.
     */
    errno = 0;
    curr_user = getpwuid(geteuid());
    if (curr_user == NULL) {
        perror("getpwuid() failed");
        return EX_OSERR;
    }
    
    /* Since "curr_user" points to static library data, we don't wish to
     * risk some other part of the system overwriting it, so we copy the 
     * username to our own buffer -- then this won't arise as a problem.
     */
    username = strdup(curr_user->pw_name);
    if (username == NULL) {
        return EX_OSERR;
    }
#endif
    return EX_OK;
}

void transport_cleanup(void) {
#ifdef _WIN32
    WSACleanup();
#endif
}

void cleanup(void) {
	message_cleanup( &m );
	close_fd( &in_fd );
	close_fd( &out_fd );
	if( temp_text != NULL )		remove( temp_text );
	free( temp_text );	temp_text = NULL;
	free( username );	username = NULL;
}

int main(int argc, char *argv[]) {
	struct transport trans;
	char* usr = NULL;

	int ret = EX_OK;


	/* for cleanup code */
	setup_message( &m );
	/* set cleanup code for at exit */
	atexit( cleanup );

	/* for max_len */
	transport_init(&trans);

#ifdef LIBSPAMC_UNIT_TESTS
    /* unit test support; divert execution.  will not return */
    do_libspamc_unit_tests();
#endif

	/* Now parse the command line arguments. First, set the defaults. */
	read_args(argc, argv, &usr, &trans);

	/* set max_len after read_args (option) */
	setup_message( &m );

	if( EX_OK != get_current_user( usr ) ) {
	   return XMAIL_FILTER_FAIL;
	}

	if( (flags & SPAMC_RANDOMIZE_HOSTS) != 0) {
	   /* we don't need strong randomness; this is just so we pick
		* a random host for loadbalancing.
		*/
	   srand(getpid() ^ time(NULL));
	}

	if( EX_OK != transport_setup(&trans, flags) ) {
		return XMAIL_FILTER_FAIL;
	}

	/* set transport cleanup code for exit */
	atexit( transport_cleanup );
	if( EX_OK != get_input_fd( &in_fd ) ) {
		return XMAIL_FILTER_FAIL;
	}

	/* read input text message */
	ret = message_read( in_fd, flags, &m );
	if( EX_OK != ret ) {
		if( EX_TOOBIG == ret && (custom_opt & CUSTOMOPT_REJECT_BIGMSG) != 0 ) {
			/* continue Big Message */
#ifdef _DEBUG
			printf( "TOOBIG : %d \n", m.raw_len );
#endif
			--m.raw_len;
			m.raw[ m.raw_len ]	=	0;
			m.type	=	MESSAGE_RAW;
			m.msg = m.raw;
			m.msg_len = m.raw_len;
			m.out = m.msg;
			m.out_len = m.msg_len;
		} else {
#ifdef _DEBUG
			printf( "fault read\n" );
#endif
			return XMAIL_FILTER_FAIL;
		}
	}

	/* filter input text message */
	if( EX_OK != message_filter(&trans, username, flags, &m) ) {
		return XMAIL_FILTER_FAIL;
	}

	/* open temporary text */
	if( EX_OK != get_output_fd(&out_fd) ) {
		return XMAIL_FILTER_FAIL;
	}

	/* write temporary text */
	if( message_write(out_fd, &m) >= 0 ) {
		close_fd( &in_fd );
		close_fd( &out_fd );
		switch( m.is_spam ) {
			case EX_ISSPAM: {
				if( m.score >= deny_score ) {
#ifdef _DEBUG
					printf( "reject : %s\n", input_text );
#endif
					return XMAIL_FILTER_REJECT;
				}
				/*
					TODO: compare first 6 line between input_text and temp_text
						and if different goto EX_TOOBIG; 
				*/
				/* EX_TOOBIG and EX_ISSPAM */
				if( ret == EX_TOOBIG ) {
					/* Can't MODIFY because temp_text is part of original message */
#ifdef _DEBUG
					printf( "%.3lf/%.3lf\n", m.score, m.threshold );
#endif
					return XMAIL_FILTER_REJECT;
				} else {
					remove( input_text );
					rename( temp_text, input_text );
#ifdef _DEBUG
					printf( "modify : %s\n", input_text );
#endif
					return XMAIL_FILTER_MODIFY;
				}
			}
			case EX_NOTSPAM: {
				if( ret == EX_TOOBIG ) {
					/* Can't MODIFY because temp_text is part of original message */
					return XMAIL_FILTER_OK;
				} else {
					remove( input_text );
					rename( temp_text, input_text );
#ifdef _DEBUG
					printf( "not spam %.3lf/%.3lf: %s\n", m.score, m.threshold, input_text );
#endif
					return XMAIL_FILTER_MODIFY;
				}
			}
			case EX_NOHOST:
			case EX_TOOBIG: 
			default: {
#ifdef _DEBUG
				printf( "EX_XXXX : %s\n", input_text );
#endif
				break;
			}
		}
	}

	/** atexit will call thease methods
	 * cleanup() 
	 * transport_cleanup() 
	 */
	return XMAIL_FILTER_FAIL;
}

