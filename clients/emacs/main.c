/*
 * This program is in public domain; written by Dave G. Conroy.
 * This file contains the main driving routine, and some keyboard processing
 * code, for the MicroEMACS screen editor.
 *
 * REVISION HISTORY:
 *
 * 1.0  Steve Wilhite, 30-Nov-85
 *      - Removed the old LK201 and VT100 logic. Added code to support the
 *        DEC Rainbow keyboard (which is a LK201 layout) using the the Level
 *        1 Console In ROM INT. See "rainbow.h" for the function key defs
 *      Steve Wilhite, 1-Dec-85
 *      - massive cleanup on code in display.c and search.c
 *
 * 2.0  George Jones, 12-Dec-85
 *      - Ported to Amiga.
 *
 * 3.0  Daniel Lawrence, 29-Dec-85
 *      - rebound keys/added new fast buffered I/O for AMIGA
 *	- added META- repeat commands
 *	- added reposition default to center screen (yeah!)
 *	- changed exit with modified buffers message
 *	- made filesave tell us what it is doing
 *	- changed search string entry to terminate with <ESC>
 *	  so we can use <NL> in search/replace strings
 *	- updated version number in mode line to 3.0
 *	12-Jan-86
 *	- Added code to reconize the Search/replace functions
 *	- Added code to perform search/replace & query functions
 *	14-Jan-86
 *	- moved search logic to separate function in search.c
 *	- added replace and query replace functions
 *	- separated out control key expansions to be used by others in search.c
 *	15-Jan-86
 *	- changed "visiting" to finding
 *	- changed yes/no responces to not need return
 *	- cleaned up various messages
 *	16-jan-86
 *	- fixed spurious spawn message in MSDOS
 *	- added ^X-S synonime to save command
 *	- moved escape to shell to ^X-C
 *	21-jan-86
 *	- added code to suspend shell under BSD
 *	22-jan-86
 *	- added function key support (SPEC) under MSDOS
 *	- Abort now prints [Aborted] on message line
 *	23-jan-86
 *	- Added modes and commends to set/unset them
 *	24-jan-86
 *	- Added Goto Line command
 *	- added Rename Buffer command
 *	28-jan-86
 *	- added goto begining and end of paragraph commands (META-P/META-N)
 *	- re-wrote kdelete to use realloc. gained MUCH speed here when
 *	  doing large wipes both on UNIX and MSDOS. Changed kill buffer
 *	  allocation block size from 256 bytes to 1 k
 *	29-jan-86
 *	- moved extern function declarations to efunc.h
 *	- made name[] name binding table
 *	30-jan-86
 *	- fixed Previous/Next paragraph command not to wrap around EOF
 *	- added Fill Paragraph command (META-Q)
 *	4-feb-86
 *	- added code to properly display long lines, scrolling them right
 *	  to left
 *	5-feb-85
 *	- rewrote code to right/left scroll...much better
 *	- added shifted arror keys on IBMPC
 *	6-feb-85
 *	- add option to allow forword-word to jump to begining of
 *	  next word instead of end of current one. This is different from
 *	  other emacs' but can be configured off in estruct.h
 *	- added VIEW mode to allow a buffer to be read only
 *	   (-v switch on command line will activate this)
 *	- changed quick exit to write out ALL changed buffers!!!
 *	  MAKE SURE YOU KNOW THIS WHEN META-Zing
 *	10-feb-86
 *	- added handling of lines longer than allowed on file read in
 *	  (they wrap on additional lines)
 *	- made having space clear the message line and NOT insert itself
 *	  a configuration option in ed.h
 *	11-feb-86
 *	- added Describe-command and Help commands.
 *	13-feb-86
 *	- added View file command (^X ^V) and finished HELP command
 *	14-feb-86
 *	- added option to let main loop skip update if type ahead commands
 *	   are queued up
 *	16-feb-86
 *	- added Insert File command
 *	17-feb-86
 *	- added scroll next window up/down commands
 *	18-feb-86
 *	- added CMODE indentation
 *	- re-arranged header files to standerdize extern and global
 *	  definitions
 *	- changed version number to 3.2
 *	- added numeric arguments to search, reverse search and
 *	  search and replace
 *	24-feb-86
 *	- added Bind To Key function (^C for now) to allow the user
 *	  to change his command keys
 *	- added Unbind key function (M-^C for now)
 *	- added execute named command to execute unbound commands (M-X)
 *	- added describe bindings command (not bound)
 *	- changed version number to 3.3
 *	25-feb-86
 *	- scrapped CERROR mode (too many compilers)
 *	- added EXACT mode for case sensitive searchers
 *	26-feb-86
 *	- added command completion on execute named command and
 *	  all routined grabbing a command name
 *	- adding execute-command-line command and its support functions
 *	  (in preporation for sourcing files)
 *	- added Execute Buffer command
 *	27-feb-86
 *	- added execute(source) file command and added code to automatically
 *	  execute emacs.rc (or .emacsrc on UNIX) before initial read in
 *	- changed version number to 3.4
 *	4-mar-86
 *	- changed word delete to be consistant with word move (it gets
 *	  rid of the inter word space now) This is configurable with the
 *	  NFWORD symbol in estruct.h
 *	- added B_ACTIVE entry to the buffer table. Let emacs read multiple
 *	  file names from the command line and only read them in as needed
 *	5-mar-85
 *	- rewrote command line parser to get rid of my patchy code
 *	- changed version number to 3.5
 *	1-apr-86
 *	- added support for Aztec C 3.20e under MSDOS
 *	- fixed bug in mlwrite on ADM3's and thier ilk under V7
 *	- added insertion of pounds in column one under CMODE
 *	- changed version number to 3.6
 *	3-apr-86
 *	- added next-buffer command (^X-X)
 *	5-apr-86
 *	- added kill paragraph command (M-^W)
 *	- changed fill-paragraph to leave 2 spaces after a period at the
 *	  end of a word.
 *	- added OVERWRITE mode
 *	7-apr-86
 *	- fixed overwrite mode to handle tabs
 *	8-apr-86
 *	- added add/delete global mode (<ESC>M & <ESC> ^M) commands
 *	9-apr-86
 *	- added insert space command
 *	- moved bindings around		^C	insert space
 *					M-K	bind-to-key
 *					INSERT	insert space
 *					DELETE	forwdel
 *	- added hunt forward and hunt reverse commands
 *	10-apr-86
 *	- fixed bug in DOBUF with non-terminated command string
 *	15-apr-86
 *	- fixed tab expansion bug in DISPLAY which hung the AMIGA
 *	  (send in by Dawn Banks)
 *	- fixed curcol problen if forwline/backline during keyboard
 *	  macro execution (sent in by Ernst Christen)
 *	- added AMIGA function/cursor key support
 *	- fixed nonterminating <NL> replacement bug
 *	- fixed word wrapping problems
 *	16-apr-86
 *	- updated documentation and froze development for 3.6 net release
 *	23-apr-86	version 3.6a
 *	- added forground and background colors. Setable with the
 *	  add mode commands for the moment
 *	24-apr-86
 *	- added command to pipe CLI output to a buffer
 *	25-apr-86
 *	- added Dana Hoggat's code to replace lattice's sick system()
 *	  function, now we no longer care what the switchar is.
 *	- cleaned up the positioning on several of the spawing commands
 *	26-apr-86
 *	- added a output flush in vttidy(). Unix really appreciates this.
 *	- added filter-buffer (^X#) command to send a buffer through
 *	  a dos filter
 *	- made automatic CMODE on .c and .h file compilation dependant
 *	  in estruct.h
 *	1-may-86
 *	- optimized some code in update(). It certainly need a lot more.
 *	- added AZTEC profiling capabilities. These are conditional on
 *	  the APROF symbol in estruct.h
 *	2-may-86
 *	- added (u)ndo command in query-replace. undoes last repalce.
 *	6-may-86
 *	- re-orginized and wrote the update() function in display.c
 *	  now my color hacks are in the right places and the code can be
 *	  understood.
 *	[Released version 3.6f for BETA test sites]
 *	8-may-86
 *	- fixed bug in new display routine to wrap cursor on extended
 *	  lines at the right time
 *	- modified the buffer-position command to give reasonable info
 *	9-may-86
 *	- improved the word wrap algorithm as not to discard non-space
 *	  delimiters. The backscan now looks for white space rather than
 *	  !inword().
 *	[Released version 3.6g to Krannert]
 *	10-may-86
 *	- Added IBMPC.C an IBM-PC specific display driver. This makes paging
 *	  4-6 times faster. Also made some conditional changes to DISPLAY.C
 *	  to eliminate the pscreen[] if using the PC driver.
 *	[changed version number to 3.6i]
 *	12-may-86
 *	- added delete-window (^X 0) command to dispose of a single window
 *	- fixed problem with multiple prefixes from a command line which
 *	  was reported by John Gamble
 *	14-may-86
 *	- Added AZTEC support for the IBMPC display driver. Had to
 *	  readjust some includes and defines for this.
 *	- fixed bug in delete-window.
 *	- fixed some bizarre behavior with the cursor after coming back
 *	  from spawn calls.
 *	[changed version number to 3.7 Freezing development for net release]
 *	15-may-86
 *	- (that didn't last long...) Added execute-macro-(1 thru 20) commands
 *	  to execute macro buffers (named "[Macro nn]")
 *	- changed BFTEMP to BFINVS and cleaned up treatment of invisable
 *	  buffers.
 *	16-may-86
 *	- added store-macro (unbound) to store any executed command lines to
 *	  macro buffer.
 *	- added clear-message-line (unbound) command to do just that
 *	- added resize-window command to change a window's size to the
 *	  specified argument
 *	- improved help's logic not to re-read the file if it was already
 *	  in a buffer
 *	- added MAGIC mode to all structures and command tables, but the
 *	  regular expression code that John Gamble is writting is not ready.
 *	18-may-86
 *	- added interactive prompt requests in command line execution. IE
 *	  while executing a macro, a parameter starting with an at sign (@)
 *	  causes emacs to prompt with the rest of the parameter and return
 *	  the resulting input as the value of the parameter.
 *	- added arguments to split-current-window to force the cursor into
 *	  the upper or lower window.
 *	20-may-86
 *	- added support for the Microsoft C compiler as per the changes
 *	  send in by Oliver Sharp
 *	- made some upgrades and fixes for VMS sent in by Guy Streeter
 *	21-may-86
 *	- fixed an AZTEC bug in ttgetc by clearing the upper byte
 *	- fixed buf in CMODE with #preprocesser input (bug fix submitted by
 *	  Willis of unknown path)
 *	- added support of alternative startup file ( @<filename> ) in
 *	  the command line
 *	- added ^Q quoting in interactive input (mlreplyt()).
 *	- added re-binding of meta-prefix and ctlx-prefix
 *	22-may-86
 *	- reorginize getkey routines to make more sense and let prefix
 *	  binding work properly.
 *	23-may-86
 *	- checked new code on BSD4.2 made a few fixes
 *	- added optional fence matching while in CMODE
 *	- added goto and search command line arguments by Mike Spitzer
 *	26-may-86
 *	- added parameter fetching from buffers
 *	27-may-86
 *	- fixed some HP150 bugs......
 *	31-may-86
 *	- Added Wang PC keyboard support from modifications by
 *	  Sid Shapiro @ Wang Institute
 *	- Fixed some reverse video bugs with code submitted by Peter Chubb
 *	- Fixed bug in nextbuffer reported by Dave Forslund
 *	- added system V support (USG) from Linwood Varney
 *	2-jun-86
 *	- changed defines to just define one unix define (for example,
 *	  just define BSD for Unix BSD 4.2)
 *	- Added Incremental search functions written by D. R. Banks
 *	  in file ISEARCH.C
 *	- added insert-string (unbound) command to help the macro
 *	  language out.
 *	- added unmark-buffer (M-~) command to turn off the current buffers
 *	  change flag
 *	- fixed nxtarg to truncate strings longer than asked for max length
 *	4-jun-86
 *	- added special characters in command line tokens. Tidle (~) is
 *	  the special leadin character for "nrtb".
 *	- Fixed bad ifdef in aztec code so it could look at HOME dir
 *	  for startup, help, and emacs.rc files
 *	6-jun-86
 *	- make delete word commands clear the kill buffer if not after another
 *	  kill command
 *	11-jun-86
 *	- made ~@ in string arguments pass as char(192) to nxtarg() so one can
 *	  quote @ at the begining of string arguments
 *	- changed buffer size vars in listbuffers() to long (for big files)
 *	- re-wrote buffer-position command to be much faster
 *	12-jun-86
 *	- added count-words (M-^C) command to count the words/chars and
 *	  lines in a region
 *	- changed regions so they could be larger than 65535 (short ->
 *	  long in the REGION structure)
 *	- changed ldelete() and all callers to use a long size. The kill
 *	  buffer will still have a problem >65535 that can not be solved
 *	  until I restructure it.
 *	- grouped paragraph commands and word count together under symbol
 *	  WORDPRO to allow them to be conditionally made (or not)
 *	13-jun-86
 *	- re-wrote kill buffer routines again. Now they support an unlimited
 *	  size kill buffer, and are (in theory) faster.
 *	- changed delete-next-word (M-D) to not eat the newline after a word,
 *	  instead it checks and eats a newline at the cursor.
 *	17-jun-85
 *	- added numeric argument to next/previous-window to access the nth
 *	  window from the top/bottom
 *	- added support for the data General 10 MSDOS machine
 *	- added save-window (unbound) and restore-window (unbound) commands
 *	  for the use of the menu script. Save-window remembers which window
 *	  is current, and restore-window returns the cursor to that window.
 *	20-jun-86
 *	- fixed a bug with the fence matching locking up near the begining
 *	of a buffer
 *	- added argument to update to selectivaly force a complete update
 *	- added update-screen (unbound) command so macros can force a
 *	  screen update
 *	21-jun-86
 *	- rearranged token() and nxtarg() calls so that command names and
 *	  repeat counts could also be prompted and fetched from buffers
 *	- added write-message (unbound) command to write out a message
 *	  on the message line (for macros)
 *	- changed ifdef's so that color modes are reconized as legal in
 *	  b/w version, and simply do nothing (allowing us to use the same
 *	  script files)
 */


/* make global definitions not external */
#define	maindef

#include        "estruct.h"	/* global structures and defines */
#include	"efunc.h"	/* function declarations and name table	*/
#include	"edef.h"	/* global definitions */
#include	"ebind.h"	/* default key bindings */

#if     VMS
#include        <ssdef.h>
#define GOOD    (SS$_NORMAL)
#endif

#if	IBMPC
#define MIN8BITCHAR	0x80
#else
#define MIN8BITCHAR	0xA0
#endif

#ifndef GOOD
#define GOOD    0
#endif

#if	APROF	/* Declarations needed for AZTEC C profiling */
int _Corg();	/* first address of program */
int _Cend();	/* last address of program */

short monbuf[NBUCK];	/* buffer for gather info */
#endif

#ifndef NOMAIN
main(argc, argv)
char    *argv[];
{
	emacs_main(argc, argv);
}
#endif

int initialized;

#ifdef NOMAIN
#include <setjmp.h>
jmp_buf done;
#endif

emacs_main(argc, argv)
char    *argv[];
{
        register int    c;
        register int    f;
        register int    n;
        register int    mflag;
	register BUFFER *bp;
	register int	ffile;		/* first file flag */
	register int	carg;		/* current arg to scan */
	static   int	startf;		/* startup executed flag */
	int basec;			/* c stripped of meta character */
	register int viewflag;		/* are we starting in view mode? */
        int gotoflag;                   /* do we need to goto a line at start? */
        int gline;                      /* if so, what line? */
        int searchflag;                 /* Do we need to search at start? */
        char bname[NBUFN];		/* buffer name of file to read */

#if	APROF
	/* if we are doing AZTEC C profiling, start it up */
	/*_intr_sp(18);	 set clock interupt for 60/second */
	monitor(_Corg, _Cend, monbuf, NBUCK, 0);
#endif

#ifdef NOMAIN
	if (setjmp(done))
		return;

	if (initialized == TRUE)
		goto skipinit;

	initialized = TRUE;
#endif

	/* initialize the editor and process the command line arguments */
        strcpy(bname, "main");	/* default buffer name */
        vtinit();		/* Displays.            */
        edinit(bname);		/* Buffers, windows.    */
	startf = FALSE;		/* startup file not executed yet */

#ifdef NOMAIN
skipinit:
#endif

	viewflag = FALSE;	/* view mode defaults off in command line */
	gotoflag = FALSE;	/* set to off to begin with */
	searchflag = FALSE;	/* set to off to begin with */
	ffile = TRUE;		/* no file to edit yet */

#if	COLOR
	curwp->w_fcolor = gfcolor;		/* and set colors	*/
	curwp->w_bcolor = gbcolor;
#endif
	
	/* scan through the command line and get the files to edit */
	for (carg = 1; carg < argc; ++carg) {
		/* if its a switch, process it */
		if (argv[carg][0] == '-') {
			switch (argv[carg][1]) {
				case 'v':	/* -v for View File */
				case 'V':
					viewflag = TRUE;
					break;
				case 'e':	/* -e for Edit file */
				case 'E':
					viewflag = FALSE;
					break;
				case 's':	/* -s for initial search string */
				case 'S':
					searchflag = TRUE;
					strcpy(pat,&argv[carg][2]);
					break;
				case 'g':	/* -g for initial goto */
				case 'G':	
					gotoflag = TRUE;
					gline = atoi(&argv[carg][2]);
					break;
				default:	/* unknown switch */
					/* ignore this for now */
					break;
			}
		} else 	/* check for a macro file */
			if (argv[carg][0]== '@') {

			if (startup(&argv[carg][1]) == TRUE)
				startf = TRUE;	/* don't execute emacs.rc */

		} else {	/* process a file name */
			/* if we haven't run emacs.rc, do it now */
			if (startf == FALSE) {
				startup("");
				startf = TRUE;
			}

#ifdef NOMAIN
			/* if this is the first file, read it in */
			if (ffile) {
				if (getfile(argv[carg], (viewflag==FALSE))
								== ABORT) {
					bp = curbp;
					strcpy(bp->b_bname, "main");
					strcpy(bp->b_fname, "");
				}
				bp = curbp;
#else
			/* set up a buffer for this file */
	                makename(bname, argv[carg]);

			/* if this is the first file, read it in */
			if (ffile) {
				bp = curbp;
				makename(bname, argv[carg]);
				strcpy(bp->b_bname, bname);
				strcpy(bp->b_fname, argv[carg]);
				if (readin(argv[carg], (viewflag==FALSE))
								== ABORT) {
					strcpy(bp->b_bname, "main");
					strcpy(bp->b_fname, "");
				}
#endif

				bp->b_dotp = bp->b_linep;
				bp->b_doto = 0;
				ffile = FALSE;
			} else {
				/* set this to inactive */
				bp = bfind(bname, TRUE, 0);
				strcpy(bp->b_fname, argv[carg]);
				bp->b_active = FALSE;
			}

			/* set the view mode appropriatly */
			if (viewflag)
				bp->b_mode |= MDVIEW;
		}
	}

	/* if invoked with nothing, run the startup file here */
	if (startf == FALSE) {
		startup("");
		startf = TRUE;
	}
 
        /* Deal with startup gotos and searches */
 
        if (gotoflag && searchflag) {
        	update(FALSE);
		mlwrite("[Can not search and goto at the same time!]");
	}
        else if (gotoflag) {
                if (gotoline(TRUE,gline) == FALSE) {
                	update(FALSE);
			mlwrite("[Bogus goto argument]");
		}
        } else if (searchflag) {
                if (forscan(&pat[0], 2) == FALSE) {
                	update(FALSE);
			mlwrite("Not found.");
		}
        }

	/* setup to process commands */
#ifdef NOMAIN
	refresh(FALSE,1);
#endif
        lastflag = 0;                           /* Fake last flags.     */
	curbp->b_mode |= gmode;			/* and set default modes*/
	curwp->w_flag |= WFMODE;		/* and force an update	*/
#if	COLOR
	curwp->w_fcolor = gfcolor;		/* and set colors	*/
	curwp->w_bcolor = gbcolor;
#endif

loop:
        update(FALSE);                          /* Fix up the screen    */
        c = getcmd();
        if (mpresf != FALSE) {
                mlerase();
                update(FALSE);
#if	CLRMSG
                if (c == ' ')                   /* ITS EMACS does this  */
                        goto loop;
#endif
        }
        f = FALSE;
        n = 1;

	/* do META-# processing if needed */

	basec = c & ~META;		/* strip meta char off if there */
	if ((c & META) && ((basec >= '0' && basec <= '9') || basec == '-')) {
		f = TRUE;		/* there is a # arg */
		n = 0;			/* start with a zero default */
		mflag = 1;		/* current minus flag */
		c = basec;		/* strip the META */
		while ((c >= '0' && c <= '9') || (c == '-')) {
			if (c == '-') {
				/* already hit a minus or digit? */
				if ((mflag == -1) || (n != 0))
					break;
				mflag = -1;
			} else {
				n = n * 10 + (c - '0');
			}
			if ((n == 0) && (mflag == -1))	/* lonely - */
				mlwrite("Arg:");
			else
				mlwrite("Arg: %d",n * mflag);

			c = getcmd();	/* get the next key */
		}
		n = n * mflag;	/* figure in the sign */
	}

	/* do ^U repeat argument processing */

        if (c == (CTRL|'U')) {                  /* ^U, start argument   */
                f = TRUE;
                n = 4;                          /* with argument of 4 */
                mflag = 0;                      /* that can be discarded. */
                mlwrite("Arg: 4");
                while ((c=getcmd()) >='0' && c<='9' || c==(CTRL|'U') || c=='-'){
                        if (c == (CTRL|'U'))
                                n = n*4;
                        /*
                         * If dash, and start of argument string, set arg.
                         * to -1.  Otherwise, insert it.
                         */
                        else if (c == '-') {
                                if (mflag)
                                        break;
                                n = 0;
                                mflag = -1;
                        }
                        /*
                         * If first digit entered, replace previous argument
                         * with digit and set sign.  Otherwise, append to arg.
                         */
                        else {
                                if (!mflag) {
                                        n = 0;
                                        mflag = 1;
                                }
                                n = 10*n + c - '0';
                        }
                        mlwrite("Arg: %d", (mflag >=0) ? n : (n ? -n : -1));
                }
                /*
                 * Make arguments preceded by a minus sign negative and change
                 * the special argument "^U -" to an effective "^U -1".
                 */
                if (mflag == -1) {
                        if (n == 0)
                                n++;
                        n = -n;
                }
        }

        if (kbdmip != NULL) {                   /* Save macro strokes.  */
                if (c!=(CTLX|')') && kbdmip>&kbdm[NKBDM-6]) {
                        ctrlg(FALSE, 0);
                        goto loop;
                }
                if (f != FALSE) {
                        *kbdmip++ = (CTRL|'U');
                        *kbdmip++ = n;
                }
                *kbdmip++ = c;
        }
        execute(c, f, n);                       /* Do it.               */
        goto loop;
}

/*
 * Initialize all of the buffers and windows. The buffer name is passed down
 * as an argument, because the main routine may have been told to read in a
 * file by default, and we want the buffer name to be right.
 */
edinit(bname)
char    bname[];
{
        register BUFFER *bp;
        register WINDOW *wp;

        bp = bfind(bname, TRUE, 0);             /* First buffer         */
        blistp = bfind("[List]", TRUE, BFINVS); /* Buffer list buffer   */
        wp = (WINDOW *) malloc(sizeof(WINDOW)); /* First window         */
        if (bp==NULL || wp==NULL || blistp==NULL)
                errexit();
        curbp  = bp;                            /* Make this current    */
        wheadp = wp;
        curwp  = wp;
        wp->w_wndp  = NULL;                     /* Initialize window    */
        wp->w_bufp  = bp;
        bp->b_nwnd  = 1;                        /* Displayed.           */
        wp->w_linep = bp->b_linep;
        wp->w_dotp  = bp->b_linep;
        wp->w_doto  = 0;
        wp->w_markp = NULL;
        wp->w_marko = 0;
        wp->w_toprow = 0;
#if	COLOR
	/* initalize colors to global defaults */
	wp->w_fcolor = gfcolor;
	wp->w_bcolor = gbcolor;
#endif
        wp->w_ntrows = term.t_nrow-1;           /* "-1" for mode line.  */
        wp->w_force = 0;
        wp->w_flag  = WFMODE|WFHARD;            /* Full.                */
}

/*
 * This is the general command execution routine. It handles the fake binding
 * of all the keys to "self-insert". It also clears out the "thisflag" word,
 * and arranges to move it to the "lastflag", so that the next command can
 * look at it. Return the status of command.
 */
execute(c, f, n)
{
        register KEYTAB *ktp;
        register int    status;

        ktp = &keytab[0];                       /* Look in key table.   */
        while (ktp->k_fp != NULL) {
                if (ktp->k_code == c) {
                        thisflag = 0;
                        status   = (*ktp->k_fp)(f, n);
                        lastflag = thisflag;
                        return (status);
                }
                ++ktp;
        }

        /*
         * If a space was typed, fill column is defined, the argument is non-
         * negative, wrap mode is enabled, and we are now past fill column,
	 * and we are not read-only, perform word wrap.
         */
        if (c == ' ' && (curwp->w_bufp->b_mode & MDWRAP) && fillcol > 0 &&
	    n >= 0 && getccol(FALSE) > fillcol &&
	    (curwp->w_bufp->b_mode & MDVIEW) == FALSE)
                wrapword();

        if ((c>=0x20 && c<=0x7E)                /* Self inserting.      */
        ||  (c>=MIN8BITCHAR && c<=0xFE)) {
                if (n <= 0) {                   /* Fenceposts.          */
                        lastflag = 0;
                        return (n<0 ? FALSE : TRUE);
                }
                thisflag = 0;                   /* For the future.      */

		/* if we are in overwrite mode, not at eol,
		   and next char is not a tab or we are at a tab stop,
		   delete a char forword			*/
		if (curwp->w_bufp->b_mode & MDOVER &&
		    curwp->w_doto < curwp->w_dotp->l_used &&
			(lgetc(curwp->w_dotp, curwp->w_doto) != '\t' ||
			 (curwp->w_doto) % 8 == 7))
				ldelete(1L, FALSE);

		/* do the appropriate insertion */
		if (c == '}' && (curbp->b_mode & MDCMOD) != 0)
	        	status = insbrace(n, c);
	        else if (c == '#' && (curbp->b_mode & MDCMOD) != 0)
	        	status = inspound();
	        else
	                status = linsert(n, c);

#if	CFENCE
		/* check for CMODE fence matching */
		if ((c == '}' || c == ')') && (curbp->b_mode & MDCMOD) != 0)
			fmatch(c);
#endif

                lastflag = thisflag;
                return (status);
        }
	(*term.t_beep)();
	mlwrite("[Key not bound]");		/* complain		*/
        lastflag = 0;                           /* Fake last flags.     */
        return (FALSE);
}

/*
 * Fancy quit command, as implemented by Norm. If the any buffer has
 * changed do a write on that buffer and exit emacs, otherwise simply exit.
 */
quickexit(f, n)
{
	register BUFFER *bp;	/* scanning pointer to buffers */

	bp = bheadp;
	while (bp != NULL) {
	        if ((bp->b_flag&BFCHG) != 0	/* Changed.             */
        	&& (bp->b_flag&BFINVS) == 0) {	/* Real.                */
			curbp = bp;		/* make that buffer cur	*/
			mlwrite("[Saving %s]",bp->b_fname);
                	filesave(f, n);
		}
	bp = bp->b_bufp;			/* on to the next buffer */
	}
        quit(f, n);                             /* conditionally quit   */
}

/*
 * Quit command. If an argument, always quit. Otherwise confirm if a buffer
 * has been changed and not written out. Normally bound to "C-X C-C".
 */
quit(f, n)
{
        register int    s;

        if (f != FALSE                          /* Argument forces it.  */
        || anycb() == FALSE                     /* All buffers clean.   */
						/* User says it's OK.   */
        || (s=mlyesno("Modified buffers exist. Leave anyway")) == TRUE) {
#if	FILOCK
		if (lockrel() != TRUE) {
			(*term.t_putchar)('\n');
			(*term.t_putchar)('\r');
			(*term.t_close)();
			exit(1);
		}
#endif
                vttidy();
#if	APROF
		/* if doing AZTEC C profiling, close up and write it out */
		monitor(0,0,0,0,0);
#endif
#ifdef NOMAIN
		    longjmp(done,0);
#else
		    exit(GOOD);
#endif
        }
	mlwrite("");
        return (s);
}

/*
 * Begin a keyboard macro.
 * Error if not at the top level in keyboard processing. Set up variables and
 * return.
 */
ctlxlp(f, n)
{
        if (kbdmip!=NULL || kbdmop!=NULL) {
                mlwrite("Not now");
                return (FALSE);
        }
        mlwrite("[Start macro]");
        kbdmip = &kbdm[0];
        return (TRUE);
}

/*
 * End keyboard macro. Check for the same limit conditions as the above
 * routine. Set up the variables and return to the caller.
 */
ctlxrp(f, n)
{
        if (kbdmip == NULL) {
                mlwrite("Not now");
                return (FALSE);
        }
        mlwrite("[End macro]");
        kbdmip = NULL;
        return (TRUE);
}

/*
 * Execute a macro.
 * The command argument is the number of times to loop. Quit as soon as a
 * command gets an error. Return TRUE if all ok, else FALSE.
 */
ctlxe(f, n)
{
        register int    c;
        register int    af;
        register int    an;
        register int    s;

        if (kbdmip!=NULL || kbdmop!=NULL) {
                mlwrite("Not now");
                return (FALSE);
        }
        if (n <= 0)
                return (TRUE);
        do {
                kbdmop = &kbdm[0];
                do {
                        af = FALSE;
                        an = 1;
                        if ((c = *kbdmop++) == (CTRL|'U')) {
                                af = TRUE;
                                an = *kbdmop++;
                                c  = *kbdmop++;
                        }
                        s = TRUE;
                } while (c!=(CTLX|')') && (s=execute(c, af, an))==TRUE);
                kbdmop = NULL;
        } while (s==TRUE && --n);
        return (s);
}

/*
 * Abort.
 * Beep the beeper. Kill off any keyboard macro, etc., that is in progress.
 * Sometimes called as a routine, to do general aborting of stuff.
 */
ctrlg(f, n)
{
        (*term.t_beep)();
        if (kbdmip != NULL) {
                kbdm[0] = (CTLX|')');
                kbdmip  = NULL;
        }
	mlwrite("[Aborted]");
        return (ABORT);
}

/* tell the user that this command is illegal while we are in
   VIEW (read-only) mode				*/

rdonly()

{
	(*term.t_beep)();
	mlwrite("[Key illegal in VIEW mode]");
	return(FALSE);
}

meta()	/* dummy function for binding to meta prefix */
{
}

cex()	/* dummy function for binding to control-x prefix */
{
}

errexit()
{
#ifdef NOMAIN
	longjmp(done, 1);
#else
	exit(1);
#endif
}
