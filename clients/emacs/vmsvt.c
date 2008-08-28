/*
 *  VMS terminal handling routines
 *
 *  Known types are:
 *    VT52, VT100, and UNKNOWN (which is defined to be an ADM3a)
 *    written by Curtis Smith
 */

#include        "estruct.h"
#include	"edef.h"

#if     VMSVT

#define	termdef	1			/* don't define "term" external */

#include <ssdef.h>		/* Status code definitions		*/
#include <descrip.h>		/* Descriptor structures		*/
#include <iodef.h>		/* IO commands				*/
#include <ttdef.h>		/* tty commands				*/

extern  int     ttopen();               /* Forward references.          */
extern  int     ttgetc();
extern  int     ttputc();
extern  int     ttflush();
extern  int     ttclose();
extern  int	vmsopen();
extern  int	vmseeol();
extern  int	vmseeop();
extern  int	vmsbeep();
extern  int	vmsmove();
extern	int	vmsrev();
extern  int	eolexist;
#if	COLOR
extern	int	vmsfcol();
extern	int	vmsbcol();
#endif

#define	NROWS	24			/* # of screen rolls		*/
#define	NCOLS	80			/* # of screen columns		*/
#define	MARGIN	8			/* size of minimim margin and	*/
#define	SCRSIZ	64			/* scroll size for extended lines */
#define	NPAUSE	100			/* # times thru update to pause */

/*
 * Dispatch table. All the
 * hard fields just point into the
 * terminal I/O code.
 */
TERM    term    = {
	NROWS - 1,
	NCOLS,
	MARGIN,
	SCRSIZ,
	NPAUSE,
        &vmsopen,
        &ttclose,
        &ttgetc,
        &ttputc,
        &ttflush,
        &vmsmove,
        &vmseeol,
        &vmseeop,
        &vmsbeep,
        &vmsrev
#if	COLOR
	, &vmsfcol,
	&vmsbcol
#endif
};

char * termeop;			/* Erase to end of page string		*/
int eoppad;			/* Number of pad characters after eop	*/
char * termeol;			/* Erase to end of line string		*/
int eolpad;			/* Number of pad characters after eol	*/
char termtype;			/* Terminal type identifier		*/


/*******
 *  ttputs - Send a string to ttputc
 *******/

ttputs(string)
char * string;
{
	while (*string != '\0')
		ttputc(*string++);
}


/*******
 *  vmspad - Pad the output after an escape sequence
 *******/

vmspad(count)
int count;
{
	while (count-- > 0)
		ttputc('\0');
}


/*******
 *  vmsmove - Move the cursor
 *******/

vmsmove(row, col)
{
	switch (termtype) {
		case TT$_UNKNOWN:
			ttputc('\033');
			ttputc('=');
			ttputc(row+' ');
			ttputc(col+' ');
			break;
		case TT$_VT52:
			ttputc('\033');
			ttputc('Y');
			ttputc(row+' ');
			ttputc(col+' ');
			break;
                case TT$_VT100:         /* I'm assuming that all these  */
                case TT$_VT101:         /* are a super set of the VT100 */
                case TT$_VT102:         /* If I'm wrong, just remove    */
                case TT$_VT105:         /* those entries that aren't.   */
                case TT$_VT125:
                case TT$_VT131:
                case TT$_VT132:
                case TT$_VT200_SERIES:
			{
				char buffer[24];

				sprintf(buffer, "\033[%d;%dH", row+1, col+1);
				ttputs(buffer);
				vmspad(50);
			}
	}
}

/*******
 *  vmsrev - set the reverse video status
 *******/

vmsrev(status)

int status;	/* TRUE = reverse video, FALSE = normal video */
{
	switch (termtype) {
		case TT$_UNKNOWN:
			break;
		case TT$_VT52:
			break;
		case TT$_VT100:
			if (status) {
				ttputc('\033');
				ttputc('[');
				ttputc('7');
				ttputc('m');
			} else {
				ttputc('\033');
				ttputc('[');
				ttputc('m');
			}
			break;
	}
}

#if	COLOR
/*******
 *  vmsfcol - Set the forground color (not implimented)
 *******/
 
vmsfcol()
{
}

/*******
 *  vmsbcol - Set the background color (not implimented)
 *******/
 
vmsbcol()
{
}
#endif

/*******
 *  vmseeol - Erase to end of line
 *******/

vmseeol()
{
	ttputs(termeol);
	vmspad(eolpad);
}


/*******
 *  vmseeop - Erase to end of page (clear screen)
 *******/

vmseeop()
{
	ttputs(termeop);
	vmspad(eoppad);
}


/*******
 *  vmsbeep - Ring the bell
 *******/

vmsbeep()
{
	ttputc('\007');
}


/*******
 *  vmsopen - Get terminal type and open terminal
 *******/

vmsopen()
{
	termtype = vmsgtty();
	switch (termtype) {
		case TT$_UNKNOWN:	/* Assume ADM3a	*/
			eolexist = FALSE;
			termeop = "\032";
			eoppad = 0;
			break;
		case TT$_VT52:
			termeol = "\033K";
			eolpad = 0;
			termeop = "\033H\033J";
			eoppad = 0;
			break;
		case TT$_VT100:
			revexist = TRUE;
			termeol = "\033[K";
			eolpad = 3;
			termeop = "\033[;H\033[2J";
			eoppad = 50;
			break;
		default:
			puts("Terminal type not supported");
			exit (SS$_NORMAL);
	}
        ttopen();
}


struct iosb {			/* I/O status block			*/
	short	i_cond;		/* Condition value			*/
	short	i_xfer;		/* Transfer count			*/
	long	i_info;		/* Device information			*/
};

struct termchar {		/* Terminal characteristics		*/
	char	t_class;	/* Terminal class			*/
	char	t_type;		/* Terminal type			*/
	short	t_width;	/* Terminal width in characters		*/
	long	t_mandl;	/* Terminal's mode and length		*/
	long	t_extend;	/* Extended terminal characteristics	*/
};

/*******
 *  vmsgtty - Get terminal type from system control block
 *******/

vmsgtty()
{
	short fd;
	int status;
	struct iosb iostatus;
	struct termchar tc;
	$DESCRIPTOR(devnam, "SYS$INPUT");

	status = sys$assign(&devnam, &fd, 0, 0);
	if (status != SS$_NORMAL)
		exit (status);

	status = sys$qiow(		/* Queue and wait		*/
		0,			/* Wait on event flag zero	*/
		fd,			/* Channel to input terminal	*/
		IO$_SENSEMODE,		/* Get current characteristic	*/
		&iostatus,		/* Status after operation	*/
		0, 0,			/* No AST service		*/
		&tc,			/* Terminal characteristics buf	*/
		sizeof(tc),		/* Size of the buffer		*/
		0, 0, 0, 0);		/* P3-P6 unused			*/

					/* De-assign the input device	*/
	if (sys$dassgn(fd) != SS$_NORMAL)
		exit(status);

	if (status != SS$_NORMAL)	/* Jump out if bad status	*/
		exit(status);
	if (iostatus.i_cond != SS$_NORMAL)
		exit(iostatus.i_cond);

	return tc.t_type;		/* Return terminal type		*/
}

#else

hellovms()

{
}

#endif	VMSVT
