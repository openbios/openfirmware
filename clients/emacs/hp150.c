/*
 * The routines in this file provide support for HP150 screens
 * and routines to access the Keyboard through KEYCODE mode.
 * It compiles into nothing if not an HP150 screen device.
 * added by Daniel Lawrence
 */

#define	termdef	1			/* don't define "term" external */

#include        "estruct.h"
#include	"edef.h"

#if     HP150

#define NROW    24                      /* Screen size.                 */
#define NCOL    80                      /* Edit if you want to.         */
#define	MARGIN	8			/* size of minimim margin and	*/
#define	SCRSIZ	64			/* scroll size for extended lines */
#define	NPAUSE	15			/* # times thru update to pause */
#define BEL     0x07                    /* BEL character.               */
#define ESC     0x1B                    /* ESC character.               */

extern  int     openhp();               /* Forward references.          */
extern  int     ttgetc();
extern  int     ttputc();
extern  int     ttflush();
extern	int	hpflush();
extern  int     closehp();
extern  int     hp15move();
extern  int     hp15eeol();
extern  int     hp15eeop();
extern  int     hp15beep();
extern	int	gethpkey();
extern	int	hp15rev();
#if	COLOR
extern	int	hp15fcol();
extern	int	hp15bcol();
#endif

/* weird to ascii translation table */

char trans[][2] = {
	0x24,	9,	/* tab */
	0x25,	13,	/* ret */
	0x27,	8,	/* backspace */
	0x30,	48,	/* zero */
	0x31,	49,	/* one */
	0x32,	50,	/* two */
	0x33,	51,	/* three */
	0x34,	52,	/* four */
	0x35,	53,	/* five */
	0x36,	54,	/* six */
	0x37,	55,	/* seven */
	0x38,	56,	/* eight */
	0x39,	57,	/* nine */
	0x50,	13,	/* enter */
	0x54,	27,	/* break -> ESC */
	0x55,	27,	/* esc */
	0x58,	24,	/* stop -> ^X */
	0x70,	45,	/* N-minus */
	0x71,	42,	/* N-asterisk */
	0x72,	43,	/* N-plus */
	0x73,	47,	/* N-slash */
	0x74,	44,	/* N-comma */
	0x75,	13,	/* N-enter */
	0x76,	9,	/* N-tab */
	0x77,	46	/* N-period */
};

#define NTRANS	sizeof(trans) / 2

union REGS r;		/* register set for bios and dos (AGIOS) calls */
int capslock = 0;	/* caps lock flag */

/*
 * Standard terminal interface dispatch table. Most of the fields point into
 * "termio" code.
 */
TERM    term    = {
        NROW-1,
        NCOL,
	MARGIN,
	SCRSIZ,
	NPAUSE,
	openhp,
        closehp,
	gethpkey,
        ttputc,
        hpflush,
        hp15move,
        hp15eeol,
        hp15eeop,
        hp15beep,
        hp15rev
#if	COLOR
	, hp15fcol,
	hp15bcol
#endif
};

hp15move(row, col)
{
        ttputc(ESC);
        ttputc('&');
        ttputc('a');
        hp15parm(col);
        ttputc('c');
        hp15parm(row);
        ttputc('R');
}

hpflush()

{

}

hp15eeol()
{
        ttputc(ESC);
        ttputc('K');
}

hp15eeop()
{
        ttputc(ESC);
        ttputc('J');
}

hp15rev(status)		/* change the reverse video status */

int status;	/* TRUE = on, FALSE = off */

{
	ttputc(ESC);
	ttputc('&');
	ttputc('d');
	ttputc(status ? 'B': '@');
}

hp15beep()
{
        ttputc(BEL);
        ttflush();
}

hp15parm(n)
register int    n;
{
        register int    q;

        q = n/10;
        if (q != 0)
                hp15parm(q);
        ttputc((n%10) + '0');
}

#if	COLOR
hp15fcol()	/* we really can't do colors here, so just ignore it */
{
}

hp15bcol()	/* we really can't do colors here, so just ignore it */
{
}
#endif

gethpkey()	/* get a key from the HP keyboard while in keycode mode */

{
	static int keepflag = 0;	/* kept ahead char flag */
	static int keepchar = 0;	/* kept ehead flag */
	int c;
	int devid;			/* device ID */
	int ctype;			/* type of character gotten */
	int shiftb;			/* state of shift keys */
	int i;
	
	/* if we are in an extended char sequence, finish it */
	if (keepflag != 0) {
		keepflag = 0;
		return(keepchar);
	}

	/* grab the next 4 char sequence */
next:	shiftb = ttgetc();
	devid = ttgetc();
	c = ttgetc();
	ttgetc();		/* skip null byte */
	
	/* make sure we are from the keyboard */
	if (devid != 192)
		goto next;

	/* if normal ascii, return it */
	if ((shiftb & 0x80) == 0) {
		if (capslock && c >= 'a' && c <= 'z')
			c -= 32;
		return(c);
	}

	/* check specifically for the caps lock key */
	if (c == 0x56) {
		capslock = ~capslock;
		goto next;
	}

	/* check to see if it needs translation */
	for (i=0; i < NTRANS; i++)
		if (trans[i][0] == c)
			return((int)trans[i][1]);

	/* other wise, shove it in the keep char and return the leadin code */
	keepchar = c;
	keepflag = 1;
	return(0);
}

openhp()		/* open the HP150 keyboard for input */

{
	revexist = TRUE;

	/* define key charectoristics with AGIOS call (0, 40) */
	defkey();

	/* Turn on RAW mode with MSDOS call 44h */
	rawon();

	/* Turn off Control-C checking  MS-DOS 33h */
	ckeyoff();

	/* Turn on keycode mode with AGIOS call (0,43) */
	keycon();
}

closehp()		/* close the HP150 keyboard for input */

{
	/* define key charectoristics with AGIOS call (0, 40) */
	undefkey();
	
	/* Turn off RAW mode with MSDOS call 44h */
	rawoff();

	/* Turn on Control-C checking  MS-DOS 33h */
	ckeyon();

	/* Turn off keycode mode with AGIOS call (0,43) */
	keycoff();
}

rawon()		/* put the HP150 keyboard into RAW mode */

{
	/* get the IO control info */

	r.x.ax = 0x4400;	/* IO ctrl get device information */
	r.x.bx = 0x0001;	/* File handle; 1 for console */
	intdos(&r, &r);		/* go fer it */

	r.h.dh = 0;		/* clear high byte for put */
	r.h.dl |= 0x20;		/* set raw bit */

	/* and put it back */

	r.x.ax = 0x4401;	/* IO ctrl put device information */
	r.x.bx = 0x0001;	/* File handle; 1 for console */
	intdos(&r, &r);		/* go fer it */
}

rawoff()	/* put the HP150 keyboard into COOKED mode */

{
	/* get the IO control info */

	r.x.ax = 0x4400;	/* IO ctrl get device information */
	r.x.bx = 0x0001;	/* File handle; 1 for console */
	intdos(&r, &r);		/* go fer it */

	r.h.dh = 0;		/* clear high byte for put */
	r.h.dl &= 0xdf;		/* set raw bit */

	/* and put it back */

	r.x.ax = 0x4401;	/* IO ctrl put device information */
	r.x.bx = 0x0001;	/* File handle; 1 for console */
	intdos(&r, &r);		/* go fer it */
}


ckeyoff()	/* turn control-C trapping off */

{
	r.h.ah = 0x33;	/* ctrl-break check */
	r.h.al = 1;	/* set the state of the ctrl-break check */
	r.h.dl = 0;	/* turn it off */
	intdos(&r, &r);
}

ckeyon()	/* turn control-C trapping on */

{
	r.h.ah = 0x33;	/* ctrl-break check */
	r.h.al = 1;	/* set the state of the ctrl-break check */
	r.h.dl = 1;	/* turn it on */
	intdos(&r, &r);
}

agios(buf, len)	/* perform an AGIOS call */

char *buf;	/* sequence of bytes in command */
int len;	/* length of command in bytes */

{
	r.x.ax = 0x4403;	/* I/O ctrl write */
	r.x.bx = 1;		/* console handle */
	r.x.cx = len;		/* buffer length */
	r.x.dx = (unsigned)buf;	/* buffer address */
	return(intdos(&r, &r));	/* do it */
}

keycon()	/* turn keycode mode on */

{
	static char cmd[] = {43, 0, 1};

	return(agios(&cmd[0], 3));
}

keycoff()	/* turn keycode mode off */

{
	static char cmd[] = {43, 0, 0};

	return(agios(&cmd[0], 3));
}

defkey()	/* change all special keys to intercept mode */

{
	static char cmd[] = {40, 0, 2, 0, 0xfe, 0};

	return(agios(&cmd[0], 6));
}

undefkey()	/* change all special keys to intercept mode */

{
	static char cmd[] = {40, 0, 0, 0, 0xfe, 0};

	return(agios(&cmd[0], 6));
}

#else

h15hello()

{
}
#endif
