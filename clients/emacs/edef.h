/*	EDEF:		Global variable definitions for
			MicroEMACS 3.2

			written by Dave G. Conroy
			modified by Steve Wilhite, George Jones
			greatly modified by Daniel Lawrence
*/

/* some global fuction declarations */

/* char *malloc(); */
#include <stdlib.h>
#include <string.h>

#ifdef	maindef

/* for MAIN.C */

/* initialized global definitions */

int     fillcol = 72;                   /* Current fill column          */
short   kbdm[NKBDM] = {CTLX|')'};       /* Macro                        */
char    pat[NPAT];                      /* Search pattern		*/
char	rpat[NPAT];			/* replacement pattern		*/
char	sarg[NSTRING] = "";		/* string argument for line exec*/
int	eolexist = TRUE;		/* does clear to EOL exist	*/
int	revexist = FALSE;		/* does reverse video exist?	*/
char	*modename[] = {			/* name of modes		*/
	"WRAP", "CMODE", "SPELL", "EXACT", "VIEW", "OVER", "MAGIC"};
char	modecode[] = "WCSEVOM";		/* letters to represent modes	*/
int	gmode = 0;			/* global editor mode		*/
int	gfcolor = 7;			/* global forgrnd color (white)	*/
int	gbcolor	= 0;			/* global backgrnd color (black)*/
int     sgarbf  = TRUE;                 /* TRUE if screen is garbage	*/
int     mpresf  = FALSE;                /* TRUE if message in last line */
int	clexec	= FALSE;		/* command line execution flag	*/
int	mstore	= FALSE;		/* storing text to macro flag	*/
struct	BUFFER *bstore = NULL;		/* buffer to store macro text to*/
int     vtrow   = 0;                    /* Row location of SW cursor */
int     vtcol   = 0;                    /* Column location of SW cursor */
int     ttrow   = HUGE;                 /* Row location of HW cursor */
int     ttcol   = HUGE;                 /* Column location of HW cursor */
int	lbound	= 0;			/* leftmost column of current line
					   being displayed */
int	metac = CTRL | '[';		/* current meta character */
int	ctlxc = CTRL | 'X';		/* current control X prefix char */
int	quotec = 0x11;			/* quote char during mlreply() */
char	*cname[] = {			/* names of colors		*/
	"BLACK", "RED", "GREEN", "YELLOW", "BLUE",
	"MAGENTA", "CYAN", "WHITE"};
KILL *kbufp  = NULL;		/* current kill buffer chunk pointer	*/
KILL *kbufh  = NULL;		/* kill buffer header pointer		*/
int kused = KBLOCK;		/* # of bytes used in kill buffer	*/
WINDOW *swindow = NULL;		/* saved window pointer			*/

/* uninitialized global definitions */

int     currow;                 /* Cursor row                   */
int     curcol;                 /* Cursor column                */
int     thisflag;               /* Flags, this command          */
int     lastflag;               /* Flags, last command          */
int     curgoal;                /* Goal for C-P, C-N            */
WINDOW  *curwp;                 /* Current window               */
BUFFER  *curbp;                 /* Current buffer               */
WINDOW  *wheadp;                /* Head of list of windows      */
BUFFER  *bheadp;                /* Head of list of buffers      */
BUFFER  *blistp;                /* Buffer for C-X C-B           */
short   *kbdmip;                /* Input pointer for above      */
short   *kbdmop;                /* Output pointer for above     */

BUFFER  *bfind();               /* Lookup a buffer by name      */
WINDOW  *wpopup();              /* Pop up window creation       */
LINE    *lalloc();              /* Allocate a line              */

#else

/* for all the other .C files */

/* initialized global external declarations */

extern  int     fillcol;                /* Fill column                  */
extern  short   kbdm[];                 /* Holds kayboard macro data    */
extern  char    pat[];                  /* Search pattern               */
extern	char	rpat[];			/* Replacement pattern		*/
extern	char	sarg[];			/* string argument for line exec*/
extern	int	eolexist;		/* does clear to EOL exist?	*/
extern	int	revexist;		/* does reverse video exist?	*/
extern	char *modename[];		/* text names of modes		*/
extern	char	modecode[];		/* letters to represent modes	*/
extern	KEYTAB keytab[];		/* key bind to functions table	*/
extern	NBIND names[];			/* name to function table	*/
extern	int	gmode;			/* global editor mode		*/
extern	int	gfcolor;		/* global forgrnd color (white)	*/
extern	int	gbcolor;		/* global backgrnd color (black)*/
extern  int     sgarbf;                 /* State of screen unknown      */
extern  int     mpresf;                 /* Stuff in message line        */
extern	int	clexec;			/* command line execution flag	*/
extern	int	mstore;			/* storing text to macro flag	*/
extern	struct	BUFFER *bstore;		/* buffer to store macro text to*/
extern	int     vtrow;                  /* Row location of SW cursor */
extern	int     vtcol;                  /* Column location of SW cursor */
extern	int     ttrow;                  /* Row location of HW cursor */
extern	int     ttcol;                  /* Column location of HW cursor */
extern	int	lbound;			/* leftmost column of current line
					   being displayed */
extern	int	metac;			/* current meta character */
extern	int	ctlxc;			/* current control X prefix char */
extern	int	quotec;			/* quote char during mlreply() */
extern	char	*cname[];		/* names of colors		*/
extern KILL *kbufp;			/* current kill buffer chunk pointer */
extern KILL *kbufh;			/* kill buffer header pointer	*/
extern int kused;			/* # of bytes used in KB        */
extern WINDOW *swindow;			/* saved window pointer		*/

/* initialized global external declarations */

extern  int     currow;                 /* Cursor row                   */
extern  int     curcol;                 /* Cursor column                */
extern  int     thisflag;               /* Flags, this command          */
extern  int     lastflag;               /* Flags, last command          */
extern  int     curgoal;                /* Goal for C-P, C-N            */
extern  WINDOW  *curwp;                 /* Current window               */
extern  BUFFER  *curbp;                 /* Current buffer               */
extern  WINDOW  *wheadp;                /* Head of list of windows      */
extern  BUFFER  *bheadp;                /* Head of list of buffers      */
extern  BUFFER  *blistp;                /* Buffer for C-X C-B           */
extern  short   *kbdmip;                /* Input pointer for above      */
extern  short   *kbdmop;                /* Output pointer for above     */

extern  BUFFER  *bfind();               /* Lookup a buffer by name      */
extern  WINDOW  *wpopup();              /* Pop up window creation       */
extern  LINE    *lalloc();              /* Allocate a line              */

#endif

/* terminal table defined only in TERM.C */

#ifndef	termdef
extern  TERM    term;                   /* Terminal information.        */
#endif
