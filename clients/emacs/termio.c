/*
 * The functions in this file negotiate with the operating system for
 * characters, and write characters in a barely buffered fashion on the display.
 * All operating systems.
 */

#include	"estruct.h"
#include        "edef.h"
#ifdef __ZTC__
#include	<dos.h>
#endif
#if     V7 | USG | BSD | OFW
#include	"stdio.h"
#endif

#if     AMIGA
#define NEW 1006
#define AMG_MAXBUF      1024
static long terminal;
static char     scrn_tmp[AMG_MAXBUF+1];
static int      scrn_tmp_p = 0;
#endif

#if     VMS
#include        <stsdef.h>
#include        <ssdef.h>
#include        <descrip.h>
#include        <iodef.h>
#include        <ttdef.h>
#include	<tt2def.h>

#define NIBUF   128                     /* Input buffer size            */
#define NOBUF   1024                    /* MM says bug buffers win!     */
#define EFN     0                       /* Event flag                   */

char    obuf[NOBUF];                    /* Output buffer                */
int     nobuf;                  /* # of bytes in above    */
char    ibuf[NIBUF];                    /* Input buffer          */
int     nibuf;                  /* # of bytes in above  */
int     ibufi;                  /* Read index                   */
int     oldmode[3];                     /* Old TTY mode bits            */
int     newmode[3];                     /* New TTY mode bits            */
short   iochan;                  /* TTY I/O channel             */
#endif

#if     CPM
#include        <bdos.h>
#endif

#if     MSDOS & (LATTICE | MSDOS)
union REGS rg;		/* cpu register for use of DOS calls */
int nxtchar = -1;	/* character held from type ahead    */
#endif

#if RAINBOW
#include "rainbow.h"
#endif

#if	USG			/* System V */
#include	<signal.h>
#include	<termio.h>
struct	termio	otermio;	/* original terminal characteristics */
struct	termio	ntermio;	/* charactoristics to use inside */
#endif

#if V7 | BSD
#undef	CTRL
#include        <sgtty.h>        /* for stty/gtty functions */
#include	<signal.h>
struct  sgttyb  ostate;          /* saved tty state */
struct  sgttyb  nstate;          /* values for editor mode */
struct tchars	otchars;	/* Saved terminal special character set */
struct tchars	ntchars = { 0xff, 0xff, 0xff, 0xff, 0xff, 0xff };
				/* A lot of nothing */
#if BSD
#include <sys/ioctl.h>		/* to get at the typeahead */
extern	int rtfrmshell();	/* return from suspended shell */
#define	TBUFSIZ	128
char tobuf[TBUFSIZ];		/* terminal output buffer */
#endif
#endif

/*
 * This function is called once to set up the terminal device streams.
 * On VMS, it translates TT until it finds the terminal, then assigns
 * a channel to it and sets it raw. On CPM it is a no-op.
 */
ttopen()
{
	/* on all screens we are not sure of the initial position
	   of the cursor					*/
	ttrow = 999;
	ttcol = 999;

#if     AMIGA
        terminal = Open("RAW:1/1/639/199/MicroEMACS 3.7/Amiga", NEW);
#endif
#if     VMS
        struct  dsc$descriptor  idsc;
        struct  dsc$descriptor  odsc;
        char    oname[40];
        int     iosb[2];
        int     status;

        odsc.dsc$a_pointer = "TT";
        odsc.dsc$w_length  = strlen(odsc.dsc$a_pointer);
        odsc.dsc$b_dtype        = DSC$K_DTYPE_T;
        odsc.dsc$b_class        = DSC$K_CLASS_S;
        idsc.dsc$b_dtype        = DSC$K_DTYPE_T;
        idsc.dsc$b_class        = DSC$K_CLASS_S;
        do {
                idsc.dsc$a_pointer = odsc.dsc$a_pointer;
                idsc.dsc$w_length  = odsc.dsc$w_length;
                odsc.dsc$a_pointer = &oname[0];
                odsc.dsc$w_length  = sizeof(oname);
                status = LIB$SYS_TRNLOG(&idsc, &odsc.dsc$w_length, &odsc);
                if (status!=SS$_NORMAL && status!=SS$_NOTRAN)
                        exit(status);
                if (oname[0] == 0x1B) {
                        odsc.dsc$a_pointer += 4;
                        odsc.dsc$w_length  -= 4;
                }
        } while (status == SS$_NORMAL);
        status = SYS$ASSIGN(&odsc, &iochan, 0, 0);
        if (status != SS$_NORMAL)
                exit(status);
        status = SYS$QIOW(EFN, iochan, IO$_SENSEMODE, iosb, 0, 0,
                          oldmode, sizeof(oldmode), 0, 0, 0, 0);
        if (status!=SS$_NORMAL || (iosb[0]&0xFFFF)!=SS$_NORMAL)
                exit(status);
        newmode[0] = oldmode[0];
        newmode[1] = oldmode[1] | TT$M_NOECHO;
        newmode[1] &= ~(TT$M_TTSYNC|TT$M_HOSTSYNC);
        newmode[2] = oldmode[2] | TT2$M_PASTHRU;
        status = SYS$QIOW(EFN, iochan, IO$_SETMODE, iosb, 0, 0,
                          newmode, sizeof(newmode), 0, 0, 0, 0);
        if (status!=SS$_NORMAL || (iosb[0]&0xFFFF)!=SS$_NORMAL)
                exit(status);
        term.t_nrow = (newmode[1]>>24) - 1;
        term.t_ncol = newmode[0]>>16;

#endif
#if     CPM
#endif

#if     MSDOS & (HP150 == 0) & LATTICE
	/* kill the ctrl-break interupt */
	rg.h.ah = 0x33;		/* control-break check dos call */
	rg.h.al = 1;		/* set the current state */
	rg.h.dl = 0;		/* set it OFF */
	intdos(&rg, &rg);	/* go for it! */
#endif

#if	USG
	ioctl(o, TCGETA, &otermio);	/* save old settings */
	ntermio.c_iflag = 0;		/* setup new settings */
	ntermio.c_oflag = 0;
	ntermio.c_cflag = otermio.c_cflag;
	ntermio.c_lflag = 0;
	ntermio.c_line = otermio.c_line;
	ntermio.c_cc[VMIN] = 1;
	ntermio.c_cc[VTIME] = 0;
	ioctl(0, TCSETA, &ntermio);	/* and activate them */
#endif

#if     V7 | BSD
        gtty(0, &ostate);                       /* save old state */
        gtty(0, &nstate);                       /* get base of new state */
        nstate.sg_flags |= RAW;
        nstate.sg_flags &= ~(ECHO|CRMOD);       /* no echo for now... */
        stty(0, &nstate);                       /* set mode */
	ioctl(0, TIOCGETC, &otchars);		/* Save old characters */
	ioctl(0, TIOCSETC, &ntchars);		/* Place new character into K */
#if	BSD
	/* provide a smaller terminal output buffer so that
	   the type ahead detection works better (more often) */
	setbuffer(stdout, &tobuf[0], TBUFSIZ);
	signal(SIGTSTP,SIG_DFL);	/* set signals so that we can */
	signal(SIGCONT,rtfrmshell);	/* suspend & restart emacs */
#endif
#endif
}

/*
 * This function gets called just before we go back home to the command
 * interpreter. On VMS it puts the terminal back in a reasonable state.
 * Another no-operation on CPM.
 */
ttclose()
{
#if     AMIGA
        amg_flush();
        Close(terminal);
#endif
#if     VMS
        int     status;
        int     iosb[1];

        ttflush();
        status = SYS$QIOW(EFN, iochan, IO$_SETMODE, iosb, 0, 0,
                 oldmode, sizeof(oldmode), 0, 0, 0, 0);
        if (status!=SS$_NORMAL || (iosb[0]&0xFFFF)!=SS$_NORMAL)
                exit(status);
        status = SYS$DASSGN(iochan);
        if (status != SS$_NORMAL)
                exit(status);
#endif
#if     CPM
#endif
#if     MSDOS & (HP150 == 0) & LATTICE
	/* restore the ctrl-break interupt */
	rg.h.ah = 0x33;		/* control-break check dos call */
	rg.h.al = 1;		/* set the current state */
	rg.h.dl = 1;		/* set it ON */
	intdos(&rg, &rg);	/* go for it! */
#endif

#if	USG
	ioctl(0, TCSETA, &otermio);	/* restore terminal settings */
#endif

#if     V7 | BSD
        stty(0, &ostate);
	ioctl(0, TIOCSETC, &otchars);	/* Place old character into K */
#endif
#if	OFW
	ansibcol(7);
	ansifcol(0);
	ansieeol();
	ttflush();
	OFInterpret0("false to already-go?");
#endif
}

/*
 * Write a character to the display. On VMS, terminal output is buffered, and
 * we just put the characters in the big array, after checking for overflow.
 * On CPM terminal I/O unbuffered, so we just write the byte out. Ditto on
 * MS-DOS (use the very very raw console output routine).
 */
ttputc(c)
#if     AMIGA
        char c;
#endif
{
#if     AMIGA
        scrn_tmp[scrn_tmp_p++] = c;
        if(scrn_tmp_p>=AMG_MAXBUF)
                amg_flush();
#endif
#if     VMS
        if (nobuf >= NOBUF)
                ttflush();
        obuf[nobuf++] = c;
#endif

#if     CPM
        bios(BCONOUT, c, 0);
#endif

#if     MSDOS & MWC86
        dosb(CONDIO, c, 0);
#endif

#if	MSDOS & (LATTICE | AZTEC | MSC) & ~IBMPC
	bdos(6, c, 0);
#endif

#if RAINBOW
        Put_Char(c);                    /* fast video */
#endif


#if     V7 | USG | BSD | OFW
        fputc(c, stdout);
#endif
}

#if	AMIGA
amg_flush()
{
        if(scrn_tmp_p)
                Write(terminal,scrn_tmp,scrn_tmp_p);
        scrn_tmp_p = 0;
}
#endif

/*
 * Flush terminal buffer. Does real work where the terminal output is buffered
 * up. A no-operation on systems where byte at a time terminal I/O is done.
 */
ttflush()
{
#if     AMIGA
        amg_flush();
#endif
#if     VMS
        int     status;
        int     iosb[2];

        status = SS$_NORMAL;
        if (nobuf != 0) {
                status = SYS$QIOW(EFN, iochan, IO$_WRITELBLK|IO$M_NOFORMAT,
                         iosb, 0, 0, obuf, nobuf, 0, 0, 0, 0);
                if (status == SS$_NORMAL)
                        status = iosb[0] & 0xFFFF;
                nobuf = 0;
        }
        return (status);
#endif

#if     CPM
#endif

#if     MSDOS
#endif

#if     V7 | USG | BSD | OFW
        fflush(stdout);
#endif
}

/*
 * Read a character from the terminal, performing no editing and doing no echo
 * at all. More complex in VMS that almost anyplace else, which figures. Very
 * simple on CPM, because the system can do exactly what you want.
 */
ttgetc()
{
#if     AMIGA
        char ch;
        amg_flush();
        Read(terminal, &ch, 1);
        return(255 & (int)ch);
#endif
#if     VMS
        int     status;
        int     iosb[2];
        int     term[2];

        while (ibufi >= nibuf) {
                ibufi = 0;
                term[0] = 0;
                term[1] = 0;
                status = SYS$QIOW(EFN, iochan, IO$_READLBLK|IO$M_TIMED,
                         iosb, 0, 0, ibuf, NIBUF, 0, term, 0, 0);
                if (status != SS$_NORMAL)
                        exit(status);
                status = iosb[0] & 0xFFFF;
                if (status!=SS$_NORMAL && status!=SS$_TIMEOUT)
                        exit(status);
                nibuf = (iosb[0]>>16) + (iosb[1]>>16);
                if (nibuf == 0) {
                        status = SYS$QIOW(EFN, iochan, IO$_READLBLK,
                                 iosb, 0, 0, ibuf, 1, 0, term, 0, 0);
                        if (status != SS$_NORMAL
                        || (status = (iosb[0]&0xFFFF)) != SS$_NORMAL)
                                exit(status);
                        nibuf = (iosb[0]>>16) + (iosb[1]>>16);
                }
        }
        return (ibuf[ibufi++] & 0xFF);    /* Allow multinational  */
#endif

#if     CPM
        return (biosb(BCONIN, 0, 0));
#endif

#if RAINBOW
        int Ch;

        while ((Ch = Read_Keyboard()) < 0);

        if ((Ch & Function_Key) == 0)
                if (!((Ch & 0xFF) == 015 || (Ch & 0xFF) == 0177))
                        Ch &= 0xFF;

        return Ch;
#endif

#if     MSDOS & MWC86
        return (dosb(CONRAW, 0, 0));
#endif

#if	MSDOS & (LATTICE | MSC)
	int c;		/* character read */

	/* if a char already is ready, return it */
	if (nxtchar >= 0) {
		c = nxtchar;
		nxtchar = -1;
		return(c);
	}

	/* call the dos to get a char */
	rg.h.ah = 7;		/* dos Direct Console Input call */
	intdos(&rg, &rg);
	c = rg.h.al;		/* grab the char */
	return(c & 255);
#endif

#if	MSDOS & AZTEC
	int c;		/* character read */

	/* if a char already is ready, return it */
	if (nxtchar >= 0) {
		c = nxtchar;
		nxtchar = -1;
		return(c);
	}

	/* call the dos to get a char */
	rg.h.ah = 7;		/* dos Direct Console I/O call */
	sysint(33, &rg, &rg);
	c = rg.h.al;		/* grab the char */
	return(c & 255);
#endif

#if     V7 | USG | BSD
        return(127 & fgetc(stdin));
#endif

#if     OFW
        return(fgetc(stdin));
#endif
}

#if	TYPEAH
/* typahead:	Check to see if any characters are already in the
		keyboard buffer
*/

typahead()

{
#if	MSDOS & (LATTICE | AZTEC)
	int c;		/* character read */
	int flags;	/* cpu flags from dos call */

#if	MSC
	if (kbhit() != 0)
		return(TRUE);
	else
		return(FALSE);
#endif

	if (nxtchar >= 0)
		return(TRUE);

	rg.h.ah = 6;	/* Direct Console I/O call */
	rg.h.dl = 255;	/*         does console input */
#if	LATTICE
	flags = intdos(&rg, &rg);
#else
	flags = sysint(33, &rg, &rg);
#endif
	c = rg.h.al;	/* grab the character */

	/* no character pending */
	if ((flags & 64) != 0)
		return(FALSE);

	/* save the character and return true */
	nxtchar = c;
	return(TRUE);
#endif

#if	BSD
	int x;	/* holds # of pending chars */

	return((ioctl(0,FIONREAD,&x) < 0) ? 0 : x);
#endif
	return(FALSE);
}
#endif

