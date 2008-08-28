/*
 * The functions in this file handle redisplay. There are two halves, the
 * ones that update the virtual display screen, and the ones that make the
 * physical display screen the same as the virtual display screen. These
 * functions use hints that are left in the windows by the commands.
 *
 */

#include	"estruct.h"
#include        "edef.h"

#define WFDEBUG 0                       /* Window flag debug. */

typedef struct  VIDEO {
        int	v_flag;                 /* Flags */
#if	COLOR
	int	v_fcolor;		/* current forground color */
	int	v_bcolor;		/* current background color */
	int	v_rfcolor;		/* requested forground color */
	int	v_rbcolor;		/* requested background color */
#endif
        char    v_text[1];              /* Screen data. */
}       VIDEO;

#define VFCHG   0x0001                  /* Changed flag			*/
#define	VFEXT	0x0002			/* extended (beyond column 80)	*/
#define	VFREV	0x0004			/* reverse video status		*/
#define	VFREQ	0x0008			/* reverse video request	*/
#define	VFCOL	0x0010			/* color change requested	*/

VIDEO   **vscreen;                      /* Virtual screen. */
#if	IBMPC == 0
VIDEO   **pscreen;                      /* Physical screen. */
#endif

/*
 * Initialize the data structures used by the display code. The edge vectors
 * used to access the screens are set up. The operating system's terminal I/O
 * channel is set up. All the other things get initialized at compile time.
 * The original window has "WFCHG" set, so that it will get completely
 * redrawn on the first call to "update".
 */
vtinit()
{
    register int i;
    register VIDEO *vp;

    (*term.t_open)();
    (*term.t_rev)(FALSE);
    vscreen = (VIDEO **) malloc(term.t_nrow*sizeof(VIDEO *));

    if (vscreen == NULL)
	errexit();

#if	IBMPC == 0
    pscreen = (VIDEO **) malloc(term.t_nrow*sizeof(VIDEO *));

    if (pscreen == NULL)
	errexit();
#endif

    for (i = 0; i < term.t_nrow; ++i)
        {
        vp = (VIDEO *) malloc(sizeof(VIDEO)+term.t_ncol);

        if (vp == NULL)
	    errexit();

	vp->v_flag = 0;
#if	COLOR
	vp->v_rfcolor = 7;
	vp->v_rbcolor = 0;
#endif
        vscreen[i] = vp;
#if	IBMPC == 0
        vp = (VIDEO *) malloc(sizeof(VIDEO)+term.t_ncol);

        if (vp == NULL)
	    errexit();

	vp->v_flag = 0;
        pscreen[i] = vp;
#endif
        }
}

/*
 * Clean up the virtual terminal system, in anticipation for a return to the
 * operating system. Move down to the last line and clear it out (the next
 * system prompt will be written in the line). Shut down the channel to the
 * terminal.
 */
vttidy()
{
    mlerase();
    movecursor(term.t_nrow, 0);
    (*term.t_flush)();
    (*term.t_close)();
}

/*
 * Set the virtual cursor to the specified row and column on the virtual
 * screen. There is no checking for nonsense values; this might be a good
 * idea during the early stages.
 */
vtmove(row, col)
{
    vtrow = row;
    vtcol = col;
}

/*
 * Write a character to the virtual screen. The virtual row and column are
 * updated. If the line is too long put a "$" in the last column. This routine
 * only puts printing characters into the virtual terminal buffers. Only
 * column overflow is checked.
 */
vtputc(c)
    int c;
{
    register VIDEO      *vp;

    vp = vscreen[vtrow];

    if (vtcol >= term.t_ncol) {
        vtcol = (vtcol + 0x07) & ~0x07;
        vp->v_text[term.t_ncol - 1] = '$';
    } else if (c == '\t')
        {
        do
            {
            vtputc(' ');
            }
        while ((vtcol&0x07) != 0);
        }
    else if (c < 0x20 || c == 0x7F)
        {
        vtputc('^');
        vtputc(c ^ 0x40);
        }
    else
	vp->v_text[vtcol++] = c;
}

/*	put a character to the virtual screen in an extended line. If we are
	not yet on left edge, don't print it yet. check for overflow on
	the right margin						*/

vtpute(c)

int c;

{
    register VIDEO      *vp;

    vp = vscreen[vtrow];

    if (vtcol >= term.t_ncol) {
        vtcol = (vtcol + 0x07) & ~0x07;
        vp->v_text[term.t_ncol - 1] = '$';
    } else if (c == '\t')
        {
        do
            {
            vtpute(' ');
            }
        while (((vtcol + lbound)&0x07) != 0);
        }
    else if (c < 0x20 || c == 0x7F)
        {
        vtpute('^');
        vtpute(c ^ 0x40);
        }
    else {
	if (vtcol >= 0)
		vp->v_text[vtcol] = c;
	++vtcol;
    }
}

/*
 * Erase from the end of the software cursor to the end of the line on which
 * the software cursor is located.
 */
vteeol()
{
    register VIDEO      *vp;

    vp = vscreen[vtrow];
    while (vtcol < term.t_ncol)
        vp->v_text[vtcol++] = ' ';
}

/* upscreen:	user routine to force a screen update
		always finishes complete update		*/

upscreen(f, n)

{
	update(TRUE);
	return(TRUE);
}

/*
 * Make sure that the display is right. This is a three part process. First,
 * scan through all of the windows looking for dirty ones. Check the framing,
 * and refresh the screen. Second, make sure that "currow" and "curcol" are
 * correct for the current window. Third, make the virtual and physical
 * screens the same.
 */
update(force)

int force;	/* force update past type ahead? */

{
	register WINDOW *wp;

#if	TYPEAH
	if (force == FALSE && typahead())
		return(TRUE);
#endif

	/* update any windows that need refreshing */
	wp = wheadp;
	while (wp != NULL) {
		if (wp->w_flag) {
			/* if the window has changed, service it */
			reframe(wp);	/* check the framing */
			if ((wp->w_flag & ~WFMODE) == WFEDIT)
				updone(wp);	/* update EDITed line */
			else if (wp->w_flag & ~WFMOVE)
				updall(wp);	/* update all lines */
#if	~WFDEBUG
			if (wp->w_flag & WFMODE)
				modeline(wp);	/* update modeline */
#endif
			wp->w_flag = 0;
			wp->w_force = 0;
		}
#if	WFDEBUG
		modeline();
#endif
		/* on to the next window */
		wp = wp->w_wndp;
	}

	/* recalc the current hardware cursor location */
	updpos();

#if	IBMPC
	/* update the cursor and flush the buffers */
	movecursor(currow, curcol - lbound);
#endif

	/* check for lines to de-extend */
	upddex();

	/* if screen is garbage, re-plot it */
	if (sgarbf != FALSE)
		updgar();

	/* update the virtual screen to the physical screen */
	updupd(force);

	/* update the cursor and flush the buffers */
	movecursor(currow, curcol - lbound);
	(*term.t_flush)();
	return(TRUE);
}

/*	reframe:	check to see if the cursor is on in the window
			and re-frame it if needed or wanted		*/

reframe(wp)

WINDOW *wp;

{
	register LINE *lp;
	register int i;

	/* if not a requested reframe, check for a needed one */
	if ((wp->w_flag & WFFORCE) == 0) {
		lp = wp->w_linep;
		for (i = 0; i < wp->w_ntrows; i++) {

			/* if the line is in the window, no reframe */
			if (lp == wp->w_dotp)
				return(TRUE);

			/* if we are at the end of the file, reframe */
			if (lp == wp->w_bufp->b_linep)
				break;

			/* on to the next line */
			lp = lforw(lp);
		}
	}

	/* reaching here, we need a window refresh */
	i = wp->w_force;

	/* how far back to reframe? */
	if (i > 0) {		/* only one screen worth of lines max */
		if (--i >= wp->w_ntrows)
			i = wp->w_ntrows - 1;
	} else if (i < 0) {	/* negative update???? */
		i += wp->w_ntrows;
		if (i < 0)
			i = 0;
	} else
		i = wp->w_ntrows / 2;

	/* backup to new line at top of window */
	lp = wp->w_dotp;
	while (i != 0 && lback(lp) != wp->w_bufp->b_linep) {
		--i;
		lp = lback(lp);
	}

	/* and reset the current line at top of window */
	wp->w_linep = lp;
	wp->w_flag |= WFHARD;
	wp->w_flag &= ~WFFORCE;
	return(TRUE);
}

/*	updone:	update the current line	to the virtual screen		*/

updone(wp)

WINDOW *wp;	/* window to update current line in */

{
	register LINE *lp;	/* line to update */
	register int sline;	/* physical screen line to update */
	register int i;

	/* search down the line we want */
	lp = wp->w_linep;
	sline = wp->w_toprow;
	while (lp != wp->w_dotp) {
		++sline;
		lp = lforw(lp);
	}

	/* and update the virtual line */
	vscreen[sline]->v_flag |= VFCHG;
	vscreen[sline]->v_flag &= ~VFREQ;
	vtmove(sline, 0);
	for (i=0; i < llength(lp); ++i)
		vtputc(lgetc(lp, i));
#if	COLOR
	vscreen[sline]->v_rfcolor = wp->w_fcolor;
	vscreen[sline]->v_rbcolor = wp->w_bcolor;
#endif
	vteeol();
}

/*	updall:	update all the lines in a window on the virtual screen */

updall(wp)

WINDOW *wp;	/* window to update lines in */

{
	register LINE *lp;	/* line to update */
	register int sline;	/* physical screen line to update */
	register int i;

	/* search down the lines, updating them */
	lp = wp->w_linep;
	sline = wp->w_toprow;
	while (sline < wp->w_toprow + wp->w_ntrows) {

		/* and update the virtual line */
		vscreen[sline]->v_flag |= VFCHG;
		vscreen[sline]->v_flag &= ~VFREQ;
		vtmove(sline, 0);
		if (lp != wp->w_bufp->b_linep) {
			/* if we are not at the end */
			for (i=0; i < llength(lp); ++i)
				vtputc(lgetc(lp, i));
			lp = lforw(lp);
		}

		/* on to the next one */
#if	COLOR
		vscreen[sline]->v_rfcolor = wp->w_fcolor;
		vscreen[sline]->v_rbcolor = wp->w_bcolor;
#endif
		vteeol();
		++sline;
	}

}

/*	updpos:	update the position of the hardware cursor and handle extended
		lines. This is the only update for simple moves.	*/

updpos()

{
	register LINE *lp;
	register int c;
	register int i;

	/* find the current row */
	lp = curwp->w_linep;
	currow = curwp->w_toprow;
	while (lp != curwp->w_dotp) {
		++currow;
		lp = lforw(lp);
	}

	/* find the current column */
	curcol = 0;
	i = 0;
	while (i < curwp->w_doto) {
		c = lgetc(lp, i++);
		if (c == '\t')
			curcol |= 0x07;
		else
			if (c < 0x20 || c == 0x7f)
				++curcol;

		++curcol;
	}

	/* if extended, flag so and update the virtual line image */
	if (curcol >=  term.t_ncol - 1) {
		vscreen[currow]->v_flag |= (VFEXT | VFCHG);
		updext();
	} else
		lbound = 0;
}

/*	upddex:	de-extend any line that derserves it		*/

upddex()

{
	register WINDOW *wp;
	register LINE *lp;
	register int i,j;

	wp = wheadp;

	while (wp != NULL) {
		lp = wp->w_linep;
		i = wp->w_toprow;

		while (i < wp->w_toprow + wp->w_ntrows) {
			if (vscreen[i]->v_flag & VFEXT) {
				if ((wp != curwp) || (lp != wp->w_dotp) ||
				   (curcol < term.t_ncol - 1)) {
					vtmove(i, 0);
					for (j = 0; j < llength(lp); ++j)
						vtputc(lgetc(lp, j));
					vteeol();

					/* this line no longer is extended */
					vscreen[i]->v_flag &= ~VFEXT;
					vscreen[i]->v_flag |= VFCHG;
				}
			}
			lp = lforw(lp);
			++i;
		}
		/* and onward to the next window */
		wp = wp->w_wndp;
	}
}

/*	updgar:	if the screen is garbage, clear the physical screen and
		the virtual screen and force a full update		*/

updgar()

{
	register char *txt;
	register int i,j;

	for (i = 0; i < term.t_nrow; ++i) {
		vscreen[i]->v_flag |= VFCHG;
#if	REVSTA
		vscreen[i]->v_flag &= ~VFREV;
#endif
#if	COLOR
		vscreen[i]->v_fcolor = gfcolor;
		vscreen[i]->v_bcolor = gbcolor;
#endif
#if	IBMPC == 0
		txt = pscreen[i]->v_text;
		for (j = 0; j < term.t_ncol; ++j)
			txt[j] = ' ';
#endif
	}

	movecursor(0, 0);		 /* Erase the screen. */
	(*term.t_eeop)();
	sgarbf = FALSE;			 /* Erase-page clears */
	mpresf = FALSE;			 /* the message area. */
#if	COLOR
	mlerase();			/* needs to be cleared if colored */
#endif
}

/*	updupd:	update the physical screen from the virtual screen	*/

updupd(force)

int force;	/* forced update flag */

{
	register VIDEO *vp1;
	register int i;

	for (i = 0; i < term.t_nrow; ++i) {
		vp1 = vscreen[i];

		/* for each line that needs to be updated*/
		if ((vp1->v_flag & VFCHG) != 0) {
#if	TYPEAH
			if (force == FALSE && typahead())
				return(TRUE);
#endif
#if	IBMPC
			updateline(i, vp1);
#else
			updateline(i, vp1, pscreen[i]);
#endif
		}
	}

#if	OFW
	/* Restore the colors to those for the current line */
	(*term.t_setfor)(vscreen[currow]->v_rfcolor);
	(*term.t_setback)(vscreen[currow]->v_rbcolor);
#endif

	return(TRUE);
}

/*	updext: update the extended line which the cursor is currently
		on at a column greater than the terminal width. The line
		will be scrolled right or left to let the user see where
		the cursor is
								*/

updext()

{
	register int rcursor;	/* real cursor location */
	register LINE *lp;	/* pointer to current line */
	register int j;		/* index into line */

	/* calculate what column the real cursor will end up in */
	rcursor = ((curcol - term.t_ncol) % term.t_scrsiz) + term.t_margin;
	lbound = curcol - rcursor + 1;

	/* scan through the line outputing characters to the virtual screen */
	/* once we reach the left edge					*/
	vtmove(currow, -lbound);	/* start scanning offscreen */
	lp = curwp->w_dotp;		/* line to output */
	for (j=0; j<llength(lp); ++j)	/* until the end-of-line */
		vtpute(lgetc(lp, j));

	/* truncate the virtual line */
	vteeol();

	/* and put a '$' in column 1 */
	vscreen[currow]->v_text[0] = '$';
}

/*
 * Update a single line. This does not know how to use insert or delete
 * character sequences; we are using VT52 functionality. Update the physical
 * row and column variables. It does try an exploit erase to end of line. The
 * RAINBOW version of this routine uses fast video.
 */
#if	IBMPC
/*	UPDATELINE specific code for the IBM-PC and other compatables */

updateline(row, vp1)

int row;		/* row of screen to update */
struct VIDEO *vp1;	/* virtual screen image */

{
#if	COLOR
	scwrite(row, vp1->v_text, vp1->v_rfcolor, vp1->v_rbcolor);
	vp1->v_fcolor = vp1->v_rfcolor;
	vp1->v_bcolor = vp1->v_rbcolor;
#else
	if (vp1->v_flag & VFREQ)
		scwrite(row, vp1->v_text, 0, 7);
	else
		scwrite(row, vp1->v_text, 7, 0);
#endif
	vp1->v_flag &= ~(VFCHG | VFCOL);	/* flag this line as changed */

}

#else

updateline(row, vp1, vp2)

int row;		/* row of screen to update */
struct VIDEO *vp1;	/* virtual screen image */
struct VIDEO *vp2;	/* physical screen image */

{
#if RAINBOW
/*	UPDATELINE specific code for the DEC rainbow 100 micro	*/

    register char *cp1;
    register char *cp2;
    register int nch;

    /* since we don't know how to make the rainbow do this, turn it off */
    flags &= (~VFREV & ~VFREQ);

    cp1 = &vp1->v_text[0];                    /* Use fast video. */
    cp2 = &vp2->v_text[0];
    putline(row+1, 1, cp1);
    nch = term.t_ncol;

    do
        {
        *cp2 = *cp1;
        ++cp2;
        ++cp1;
        }
    while (--nch);
    *flags &= ~VFCHG;
#else
/*	UPDATELINE code for all other versions		*/

	register char *cp1;
	register char *cp2;
	register char *cp3;
	register char *cp4;
	register char *cp5;
	register int nbflag;	/* non-blanks to the right flag? */
	int rev;		/* reverse video flag */
	int req;		/* reverse video request flag */


	/* set up pointers to virtual and physical lines */
	cp1 = &vp1->v_text[0];
	cp2 = &vp2->v_text[0];

#if	COLOR
	(*term.t_setfor)(vp1->v_rfcolor);
	(*term.t_setback)(vp1->v_rbcolor);
#endif

#if	REVSTA | COLOR
	/* if we need to change the reverse video status of the
	   current line, we need to re-write the entire line     */
	rev = (vp1->v_flag & VFREV) == VFREV;
	req = (vp1->v_flag & VFREQ) == VFREQ;
	if ((rev != req)
#if	COLOR
	    || (vp1->v_fcolor != vp1->v_rfcolor) || (vp1->v_bcolor != vp1->v_rbcolor)
#endif
			) {
		movecursor(row, 0);	/* Go to start of line. */
		/* set rev video if needed */
		if (rev != req)
			(*term.t_rev)(req);

		/* scan through the line and dump it to the screen and
		   the virtual screen array				*/
		cp3 = &vp1->v_text[term.t_ncol];
		while (cp1 < cp3) {
			(*term.t_putchar)(*cp1);
			++ttcol;
			*cp2++ = *cp1++;
		}
		/* turn rev video off */
		if (rev != req)
			(*term.t_rev)(FALSE);

		/* update the needed flags */
		vp1->v_flag &= ~VFCHG;
		if (req)
			vp1->v_flag |= VFREV;
		else
			vp1->v_flag &= ~VFREV;
#if	COLOR
		vp1->v_fcolor = vp1->v_rfcolor;
		vp1->v_bcolor = vp1->v_rbcolor;
#endif
		return(TRUE);
	}
#endif

	/* advance past any common chars at the left */
	while (cp1 != &vp1->v_text[term.t_ncol] && cp1[0] == cp2[0]) {
		++cp1;
		++cp2;
	}

/* This can still happen, even though we only call this routine on changed
 * lines. A hard update is always done when a line splits, a massive
 * change is done, or a buffer is displayed twice. This optimizes out most
 * of the excess updating. A lot of computes are used, but these tend to
 * be hard operations that do a lot of update, so I don't really care.
 */
	/* if both lines are the same, no update needs to be done */
	if (cp1 == &vp1->v_text[term.t_ncol])
		return(TRUE);

	/* find out if there is a match on the right */
	nbflag = FALSE;
	cp3 = &vp1->v_text[term.t_ncol];
	cp4 = &vp2->v_text[term.t_ncol];

	while (cp3[-1] == cp4[-1]) {
		--cp3;
		--cp4;
		if (cp3[0] != ' ')		/* Note if any nonblank */
			nbflag = TRUE;		/* in right match. */
	}

	cp5 = cp3;

	/* Erase to EOL ? */
	if (nbflag == FALSE && eolexist == TRUE && (req != TRUE)) {
		while (cp5!=cp1 && cp5[-1]==' ')
			--cp5;

		if (cp3-cp5 <= 3)		/* Use only if erase is */
			cp5 = cp3;		/* fewer characters. */
	}

	movecursor(row, cp1 - &vp1->v_text[0]);	/* Go to start of line. */
#if	REVSTA
	(*term.t_rev)((vp1->v_flag & VFREV) == VFREV);
#endif

	while (cp1 != cp5) {		/* Ordinary. */
		(*term.t_putchar)(*cp1);
		++ttcol;
		*cp2++ = *cp1++;
	}

	if (cp5 != cp3) {		/* Erase. */
		(*term.t_eeol)();
		while (cp1 != cp3)
			*cp2++ = *cp1++;
	}
#if	REVSTA
	(*term.t_rev)(FALSE);
#endif
	vp1->v_flag &= ~VFCHG;		/* flag this line is changed */
	return(TRUE);
#endif
}
#endif

/*
 * Redisplay the mode line for the window pointed to by the "wp". This is the
 * only routine that has any idea of how the modeline is formatted. You can
 * change the modeline format by hacking at this routine. Called by "update"
 * any time there is a dirty window.
 */
modeline(wp)
    WINDOW *wp;
{
    register char *cp;
    register int c;
    register int n;		/* cursor position count */
    register BUFFER *bp;
    register i;			/* loop index */
    register lchar;		/* character to draw line in buffer with */
    register firstm;		/* is this the first mode? */
    char tline[NLINE];		/* buffer for part of mode line */

    n = wp->w_toprow+wp->w_ntrows;      	/* Location. */
    vscreen[n]->v_flag |= VFCHG | VFREQ | VFCOL;/* Redraw next time. */
#if	COLOR
    vscreen[n]->v_rfcolor = 0;			/* black on */
    vscreen[n]->v_rbcolor = 7;			/* white.....*/
#endif
    vtmove(n, 0);                       	/* Seek to right line. */
    if (wp == curwp)				/* mark the current buffer */
	lchar = '=';
    else
#if	REVSTA
	if (revexist)
		lchar = ' ';
	else
#endif
		lchar = '-';

    vtputc(lchar);
    bp = wp->w_bufp;

    if ((bp->b_flag&BFCHG) != 0)                /* "*" if changed. */
        vtputc('*');
    else
        vtputc(lchar);

    n  = 2;
    strcpy(tline, " MicroEMACS 3.7 (");		/* Buffer name. */

    /* display the modes */

	firstm = TRUE;
	for (i = 0; i < NUMMODES; i++)	/* add in the mode flags */
		if (wp->w_bufp->b_mode & (1 << i)) {
			if (firstm != TRUE)
				strcat(tline, " ");
			firstm = FALSE;
			strcat(tline, modename[i]);
		}
	strcat(tline,") ");

    cp = &tline[0];
    while ((c = *cp++) != 0)
        {
        vtputc(c);
        ++n;
        }

#if WFDEBUG
    vtputc(lchar);
    vtputc((wp->w_flag&WFCOLR) != 0  ? 'C' : lchar);
    vtputc((wp->w_flag&WFMODE) != 0  ? 'M' : lchar);
    vtputc((wp->w_flag&WFHARD) != 0  ? 'H' : lchar);
    vtputc((wp->w_flag&WFEDIT) != 0  ? 'E' : lchar);
    vtputc((wp->w_flag&WFMOVE) != 0  ? 'V' : lchar);
    vtputc((wp->w_flag&WFFORCE) != 0 ? 'F' : lchar);
    vtputc(lchar);
    n += 8;
#endif

    vtputc(lchar);
    vtputc(lchar);
    vtputc(' ');
    n += 3;
    cp = &bp->b_bname[0];

    while ((c = *cp++) != 0)
        {
        vtputc(c);
        ++n;
        }

    vtputc(' ');
    vtputc(lchar);
    vtputc(lchar);
    n += 3;

    if (bp->b_fname[0] != 0)            /* File name. */
        {
	vtputc(' ');
	++n;
        cp = "File: ";

        while ((c = *cp++) != 0)
            {
            vtputc(c);
            ++n;
            }

        cp = &bp->b_fname[0];

        while ((c = *cp++) != 0)
            {
            vtputc(c);
            ++n;
            }

        vtputc(' ');
        ++n;
        }

    while (n < term.t_ncol)             /* Pad to full width. */
        {
        vtputc(lchar);
        ++n;
        }
}

upmode()	/* update all the mode lines */

{
	register WINDOW *wp;

	wp = wheadp;
	while (wp != NULL) {
		wp->w_flag |= WFMODE;
		wp = wp->w_wndp;
	}
}

/*
 * Send a command to the terminal to move the hardware cursor to row "row"
 * and column "col". The row and column arguments are origin 0. Optimize out
 * random calls. Update "ttrow" and "ttcol".
 */
movecursor(row, col)
    {
    if (row!=ttrow || col!=ttcol)
        {
        ttrow = row;
        ttcol = col;
        (*term.t_move)(row, col);
        }
    }

/*
 * Erase the message line. This is a special routine because the message line
 * is not considered to be part of the virtual screen. It always works
 * immediately; the terminal buffer is flushed via a call to the flusher.
 */
mlerase()
    {
    int i;
    
    movecursor(term.t_nrow, 0);
#if	COLOR
     (*term.t_setfor)(7);
     (*term.t_setback)(0);
#endif
    if (eolexist == TRUE)
	    (*term.t_eeol)();
    else {
        for (i = 0; i < term.t_ncol - 1; i++)
            (*term.t_putchar)(' ');
        movecursor(term.t_nrow, 1);	/* force the move! */
        movecursor(term.t_nrow, 0);
    }
    (*term.t_flush)();
    mpresf = FALSE;
    }

/*
 * Write a message into the message line. Keep track of the physical cursor
 * position. A small class of printf like format items is handled. Assumes the
 * stack grows down; this assumption is made by the "++" in the argument scan
 * loop. Set the "message line" flag TRUE.
 */

mlwrite(fmt, arg)
    char *fmt;
    {
    register int c;
    register char *ap;

#if	COLOR
	(*term.t_setfor)(7);
	(*term.t_setback)(0);
#endif
    if (eolexist == FALSE) {
        mlerase();
        (*term.t_flush)();
    }

    movecursor(term.t_nrow, 0);
    ap = (char *) &arg;
    while ((c = *fmt++) != 0) {
        if (c != '%') {
            (*term.t_putchar)(c);
            ++ttcol;
            }
        else
            {
            c = *fmt++;
            switch (c) {
                case 'd':
                    mlputi(*(int *)ap, 10);
                    ap += sizeof(int);
                    break;

                case 'o':
                    mlputi(*(int *)ap,  8);
                    ap += sizeof(int);
                    break;

                case 'x':
                    mlputi(*(int *)ap, 16);
                    ap += sizeof(int);
                    break;

                case 'D':
                    mlputli(*(long *)ap, 10);
                    ap += sizeof(long);
                    break;

                case 's':
                    mlputs(*(char **)ap);
                    ap += sizeof(char *);
                    break;

		case 'f':
		    mlputf(*(int *)ap);
		    ap += sizeof(int);
		    break;

                default:
                    (*term.t_putchar)(c);
                    ++ttcol;
                }
            }
        }
    if (eolexist == TRUE)
        (*term.t_eeol)();
    (*term.t_flush)();
    mpresf = TRUE;
    }

/*
 * Write out a string. Update the physical cursor position. This assumes that
 * the characters in the string all have width "1"; if this is not the case
 * things will get screwed up a little.
 */
mlputs(s)
    char *s;
    {
    register int c;

    while ((c = *s++) != 0)
        {
        (*term.t_putchar)(c);
        ++ttcol;
        }
    }

/*
 * Write out an integer, in the specified radix. Update the physical cursor
 * position.
 */
mlputi(i, r)
    {
    register int q;
    static char hexdigits[] = "0123456789ABCDEF";

    if (i < 0)
        {
        i = -i;
        (*term.t_putchar)('-');
        }

    q = i/r;

    if (q != 0)
        mlputi(q, r);

    (*term.t_putchar)(hexdigits[i%r]);
    ++ttcol;
    }

/*
 * do the same except as a long integer.
 */
mlputli(l, r)
    long l;
    {
    register long q;

    if (l < 0)
        {
        l = -l;
        (*term.t_putchar)('-');
        }

    q = l/r;

    if (q != 0)
        mlputli(q, r);

    (*term.t_putchar)((int)(l%r)+'0');
    ++ttcol;
    }

/*
 *	write out a scaled integer with two decimal places
 */

mlputf(s)

int s;	/* scaled integer to output */

{
	int i;	/* integer portion of number */
	int f;	/* fractional portion of number */

	/* break it up */
	i = s / 100;
	f = s % 100;

	/* send out the integer portion */
	mlputi(i, 10);
	(*term.t_putchar)('.');
	(*term.t_putchar)((f / 10) + '0');
	(*term.t_putchar)((f % 10) + '0');
	ttcol += 3;
}	

#if RAINBOW

putline(row, col, buf)
    int row, col;
    char buf[];
    {
    int n;

    n = strlen(buf);
    if (col + n - 1 > term.t_ncol)
        n = term.t_ncol - col + 1;
    Put_Data(row, col, n, buf);
    }
#endif

