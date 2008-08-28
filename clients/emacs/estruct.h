/*	ESTRUCT:	Structure and preprocesser defined for
			MicroEMACS 3.7

			written by Dave G. Conroy
			modified by Steve Wilhite, George Jones
			greatly modified by Daniel Lawrence
*/

#include "config.h"

/*	System dependant library redefinitions, structures and includes	*/

#if	MSDOS & AZTEC
#undef	fputc
#undef	fgetc
#define	fputc	aputc
#define	fgetc	agetc
#define	int86	sysint
#define	inp	inportb

struct XREG {
	int ax,bx,cx,dx,si,di;
};

struct HREG {
	char al,ah,bl,bh,cl,ch,dl,dh;
};

union REGS {
	struct XREG x;
	struct HREG h;
};
#endif

#if	MSDOS & LATTICE
#undef	CPM
#undef	LATTICE
#include	<dos.h>
#undef	CPM
#endif

/*	internal constants	*/

#define	NBINDS	200			/* max # of bound keys		*/
#define NFILEN  80                      /* # of bytes, file name        */
#define NBUFN   16                      /* # of bytes, buffer name      */
#define NLINE   256                     /* # of bytes, line             */
#define	NSTRING	256			/* # of bytes, string buffers	*/
#define NKBDM   256                     /* # of strokes, keyboard macro */
#define NPAT    80                      /* # of bytes, pattern          */
#define HUGE    1000                    /* Huge number                  */
#define	NLOCKS	100			/* max # of file locks active	*/
#define	NCOLORS	8			/* number of supported colors	*/
#define	KBLOCK	250			/* sizeof kill buffer chunks	*/
#define	NBLOCK	16			/* line block chunk size	*/

#define AGRAVE  0x60                    /* M- prefix,   Grave (LK201)   */
#define METACH  0x1B                    /* M- prefix,   Control-[, ESC  */
#define CTMECH  0x1C                    /* C-M- prefix, Control-\       */
#define EXITCH  0x1D                    /* Exit level,  Control-]       */
#define CTRLCH  0x1E                    /* C- prefix,   Control-^       */
#define HELPCH  0x1F                    /* Help key,    Control-_       */

#define CTRL    0x0100                  /* Control flag, or'ed in       */
#define META    0x0200                  /* Meta flag, or'ed in          */
#define CTLX    0x0400                  /* ^X flag, or'ed in            */
#define	SPEC	0x0800			/* special key (function keys)	*/

#define FALSE   0                       /* False, no, bad, etc.         */
#define TRUE    1                       /* True, yes, good, etc.        */
#define ABORT   2                       /* Death, ^G, abort, etc.       */

#define FIOSUC  0                       /* File I/O, success.           */
#define FIOFNF  1                       /* File I/O, file not found.    */
#define FIOEOF  2                       /* File I/O, end of file.       */
#define FIOERR  3                       /* File I/O, error.             */
#define	FIOLNG	4			/*line longer than allowed len	*/

#define CFCPCN  0x0001                  /* Last command was C-P, C-N    */
#define CFKILL  0x0002                  /* Last command was a kill      */

#define	BELL	0x07			/* a bell character		*/
#define	TAB	0x09			/* a tab character		*/

/*
 * There is a window structure allocated for every active display window. The
 * windows are kept in a big list, in top to bottom screen order, with the
 * listhead at "wheadp". Each window contains its own values of dot and mark.
 * The flag field contains some bits that are set by commands to guide
 * redisplay; although this is a bit of a compromise in terms of decoupling,
 * the full blown redisplay is just too expensive to run for every input
 * character.
 */
typedef struct  WINDOW {
        struct  WINDOW *w_wndp;         /* Next window                  */
        struct  BUFFER *w_bufp;         /* Buffer displayed in window   */
        struct  LINE *w_linep;          /* Top line in the window       */
        struct  LINE *w_dotp;           /* Line containing "."          */
        short   w_doto;                 /* Byte offset for "."          */
        struct  LINE *w_markp;          /* Line containing "mark"       */
        short   w_marko;                /* Byte offset for "mark"       */
        char    w_toprow;               /* Origin 0 top row of window   */
        char    w_ntrows;               /* # of rows of text in window  */
        char    w_force;                /* If NZ, forcing row.          */
        char    w_flag;                 /* Flags.                       */
#if	COLOR
	char	w_fcolor;		/* current forground color	*/
	char	w_bcolor;		/* current background color	*/
#endif
}       WINDOW;

#define WFFORCE 0x01                    /* Window needs forced reframe  */
#define WFMOVE  0x02                    /* Movement from line to line   */
#define WFEDIT  0x04                    /* Editing within a line        */
#define WFHARD  0x08                    /* Better to a full display     */
#define WFMODE  0x10                    /* Update mode line.            */
#define	WFCOLR	0x20			/* Needs a color change		*/

/*
 * Text is kept in buffers. A buffer header, described below, exists for every
 * buffer in the system. The buffers are kept in a big list, so that commands
 * that search for a buffer by name can find the buffer header. There is a
 * safe store for the dot and mark in the header, but this is only valid if
 * the buffer is not being displayed (that is, if "b_nwnd" is 0). The text for
 * the buffer is kept in a circularly linked list of lines, with a pointer to
 * the header line in "b_linep".
 * 	Buffers may be "Inactive" which means the files accosiated with them
 * have not been read in yet. These get read in at "use buffer" time.
 */
typedef struct  BUFFER {
        struct  BUFFER *b_bufp;         /* Link to next BUFFER          */
        struct  LINE *b_dotp;           /* Link to "." LINE structure   */
        short   b_doto;                 /* Offset of "." in above LINE  */
        struct  LINE *b_markp;          /* The same as the above two,   */
        short   b_marko;                /* but for the "mark"           */
        struct  LINE *b_linep;          /* Link to the header LINE      */
	char	b_active;		/* window activated flag	*/
        char    b_nwnd;                 /* Count of windows on buffer   */
        char    b_flag;                 /* Flags                        */
	char	b_mode;			/* editor mode of this buffer	*/
        char    b_fname[NFILEN];        /* File name                    */
        char    b_bname[NBUFN];         /* Buffer name                  */
}       BUFFER;

#define BFINVS  0x01                    /* Internal invisable buffer    */
#define BFCHG   0x02                    /* Changed since last write     */

/*	mode flags	*/
#define	NUMMODES	7		/* # of defined modes		*/

#define	MDWRAP	0x0001			/* word wrap			*/
#define	MDCMOD	0x0002			/* C indentation and fence match*/
#define	MDSPELL	0x0004			/* spell error parcing		*/
#define	MDEXACT	0x0008			/* Exact matching for searches	*/
#define	MDVIEW	0x0010			/* read-only buffer		*/
#define MDOVER	0x0020			/* overwrite mode		*/
#define MDMAGIC	0x0040			/* regular expresions in search */

/*
 * The starting position of a region, and the size of the region in
 * characters, is kept in a region structure.  Used by the region commands.
 */
typedef struct  {
        struct  LINE *r_linep;          /* Origin LINE address.         */
        short   r_offset;               /* Origin LINE offset.          */
        long	r_size;                 /* Length in characters.        */
}       REGION;

/*
 * All text is kept in circularly linked lists of "LINE" structures. These
 * begin at the header line (which is the blank line beyond the end of the
 * buffer). This line is pointed to by the "BUFFER". Each line contains a the
 * number of bytes in the line (the "used" size), the size of the text array,
 * and the text. The end of line is not stored as a byte; it's implied. Future
 * additions will include update hints, and a list of marks into the line.
 */
typedef struct  LINE {
        struct  LINE *l_fp;             /* Link to the next line        */
        struct  LINE *l_bp;             /* Link to the previous line    */
        short   l_size;                 /* Allocated size               */
        short   l_used;                 /* Used size                    */
        char    l_text[1];              /* A bunch of characters.       */
}       LINE;

#define lforw(lp)       ((lp)->l_fp)
#define lback(lp)       ((lp)->l_bp)
#define lgetc(lp, n)    ((lp)->l_text[(n)]&0xFF)
#define lputc(lp, n, c) ((lp)->l_text[(n)]=(c))
#define llength(lp)     ((lp)->l_used)

/*
 * The editor communicates with the display using a high level interface. A
 * "TERM" structure holds useful variables, and indirect pointers to routines
 * that do useful operations. The low level get and put routines are here too.
 * This lets a terminal, in addition to having non standard commands, have
 * funny get and put character code too. The calls might get changed to
 * "termp->t_field" style in the future, to make it possible to run more than
 * one terminal type.
 */
typedef struct  {
        short   t_nrow;                 /* Number of rows.              */
        short   t_ncol;                 /* Number of columns.           */
	short	t_margin;		/* min margin for extended lines*/
	short	t_scrsiz;		/* size of scroll region "	*/
	int	t_pause;		/* # times thru update to pause */
        int     (*t_open)();            /* Open terminal at the start.  */
        int     (*t_close)();           /* Close terminal at end.       */
        int     (*t_getchar)();         /* Get character from keyboard. */
        int     (*t_putchar)();         /* Put character to display.    */
        int     (*t_flush)();           /* Flush output buffers.        */
        int     (*t_move)();            /* Move the cursor, origin 0.   */
        int     (*t_eeol)();            /* Erase to end of line.        */
        int     (*t_eeop)();            /* Erase to end of page.        */
        int     (*t_beep)();            /* Beep.                        */
	int	(*t_rev)();		/* set reverse video state	*/
#if	COLOR
	int	(*t_setfor)();		/* set forground color		*/
	int	(*t_setback)();		/* set background color		*/
#endif
}       TERM;

/*	structure for the table of initial key bindings		*/

typedef struct  {
        short   k_code;                 /* Key code                     */
        int     (*k_fp)();              /* Routine to handle it         */
}       KEYTAB;

/*	structure for the name binding table		*/

typedef struct {
	char *n_name;		/* name of function key */
	int (*n_func)();	/* function name is bound to */
}	NBIND;

/*	The editor holds deleted text chunks in the KILL buffer. The
	kill buffer is logically a stream of ascii characters, however
	due to its unpredicatable size, it gets implemented as a linked
	list of chunks. (The d_ prefix is for "deleted" text, as k_
	was taken up by the keycode structure			*/

typedef	struct KILL {
	struct KILL *d_next;	/* link to next chunk, NULL if last */
	char d_chunk[KBLOCK];	/* deleted text */
} KILL;

#define NULL  0
