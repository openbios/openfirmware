/*
 * This file contains the command processing functions for a number of random
 * commands. There is no functional grouping here, for sure.
 */

#include	"estruct.h"
#include        "edef.h"

int     tabsize;                        /* Tab size (0: use real tabs)  */

/*
 * Set fill column to n.
 */
setfillcol(f, n)
{
        fillcol = n;
	mlwrite("[Fill column is %d]",n);
        return(TRUE);
}

/*
 * Display the current position of the cursor, in origin 1 X-Y coordinates,
 * the character that is under the cursor (in hex), and the fraction of the
 * text that is before the cursor. The displayed column is not the current
 * column, but the column that would be used on an infinite width display.
 * Normally this is bound to "C-X =".
 */
showcpos(f, n)
{
        register LINE   *lp;		/* current line */
        register long   numchars;	/* # of chars in file */
        register int	numlines;	/* # of lines in file */
        register long   predchars;	/* # chars preceding point */
        register int	predlines;	/* # lines preceding point */
        register int    curchar;	/* character under cursor */
        int ratio;
        int col;
	int savepos;			/* temp save for current offset */
	int ecol;			/* column pos/end of current line */

	/* starting at the begining of the buffer */
        lp = lforw(curbp->b_linep);

	/* start counting chars and lines */
        numchars = 0;
        numlines = 0;
        while (lp != curbp->b_linep) {
		/* if we are on the current line, record it */
		if (lp == curwp->w_dotp) {
			predlines = numlines;
			predchars = numchars + curwp->w_doto;
			if ((curwp->w_doto) == llength(lp))
				curchar = '\n';
			else
				curchar = lgetc(lp, curwp->w_doto);
		}
		/* on to the next line */
		++numlines;
		numchars += llength(lp) + 1;
		lp = lforw(lp);
        }

	/* if at end of file, record it */
	if (curwp->w_dotp == curbp->b_linep) {
		predlines = numlines;
		predchars = numchars;
	}

	/* Get real column and end-of-line column. */
	col = getccol(FALSE);
	savepos = curwp->w_doto;
	curwp->w_doto = llength(curwp->w_dotp);
	ecol = getccol(FALSE);
	curwp->w_doto = savepos;

        ratio = 0;              /* Ratio before dot. */
        if (numchars != 0)
                ratio = (100L*predchars) / numchars;

	/* summarize and report the info */
	mlwrite("Line %d/%d Col %d/%d Char %D/%D (%d%%) char = 0x%x",
		predlines+1, numlines+1, col, ecol,
		predchars, numchars, ratio, curchar);
        return (TRUE);
}

/*
 * Return current column.  Stop at first non-blank given TRUE argument.
 */
getccol(bflg)
int bflg;
{
        register int c, i, col;
        col = 0;
        for (i=0; i<curwp->w_doto; ++i) {
                c = lgetc(curwp->w_dotp, i);
                if (c!=' ' && c!='\t' && bflg)
                        break;
                if (c == '\t')
                        col |= 0x07;
                else if (c<0x20 || c==0x7F)
                        ++col;
                ++col;
        }
        return(col);
}

/*
 * Twiddle the two characters on either side of dot. If dot is at the end of
 * the line twiddle the two characters before it. Return with an error if dot
 * is at the beginning of line; it seems to be a bit pointless to make this
 * work. This fixes up a very common typo with a single stroke. Normally bound
 * to "C-T". This always works within a line, so "WFEDIT" is good enough.
 */
twiddle(f, n)
{
        register LINE   *dotp;
        register int    doto;
        register int    cl;
        register int    cr;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        dotp = curwp->w_dotp;
        doto = curwp->w_doto;
        if (doto==llength(dotp) && --doto<0)
                return (FALSE);
        cr = lgetc(dotp, doto);
        if (--doto < 0)
                return (FALSE);
        cl = lgetc(dotp, doto);
        lputc(dotp, doto+0, cr);
        lputc(dotp, doto+1, cl);
        lchange(WFEDIT);
        return (TRUE);
}

/*
 * Quote the next character, and insert it into the buffer. All the characters
 * are taken literally, with the exception of the newline, which always has
 * its line splitting meaning. The character is always read, even if it is
 * inserted 0 times, for regularity. Bound to "C-Q"
 */
quote(f, n)
{
        register int    s;
        register int    c;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        c = (*term.t_getchar)();
        if (n < 0)
                return (FALSE);
        if (n == 0)
                return (TRUE);
        if (c == '\n') {
                do {
                        s = lnewline();
                } while (s==TRUE && --n);
                return (s);
        }
        return (linsert(n, c));
}

/*
 * Set tab size if given non-default argument (n <> 1).  Otherwise, insert a
 * tab into file.  If given argument, n, of zero, change to true tabs.
 * If n > 1, simulate tab stop every n-characters using spaces. This has to be
 * done in this slightly funny way because the tab (in ASCII) has been turned
 * into "C-I" (in 10 bit code) already. Bound to "C-I".
 */
tab(f, n)
{
        if (n < 0)
                return (FALSE);
        if (n == 0 || n > 1) {
                tabsize = n;
                return(TRUE);
        }
        if (! tabsize)
                return(linsert(1, '\t'));
        return(linsert(tabsize - (getccol(FALSE) % tabsize), ' '));
}

/*
 * Open up some blank space. The basic plan is to insert a bunch of newlines,
 * and then back up over them. Everything is done by the subcommand
 * procerssors. They even handle the looping. Normally this is bound to "C-O".
 */
openline(f, n)
{
        register int    i;
        register int    s;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if (n < 0)
                return (FALSE);
        if (n == 0)
                return (TRUE);
        i = n;                                  /* Insert newlines.     */
        do {
                s = lnewline();
        } while (s==TRUE && --i);
        if (s == TRUE)                          /* Then back up overtop */
                s = backchar(f, n);             /* of them all.         */
        return (s);
}

/*
 * Insert a newline. Bound to "C-M". If we are in CMODE, do automatic
 * indentation as specified.
 */
newline(f, n)
{
	register int    s;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
	if (n < 0)
		return (FALSE);

	/* if we are in C mode and this is a default <NL> */
	if (n == 1 && (curbp->b_mode & MDCMOD) &&
	    curwp->w_dotp != curbp->b_linep)
		return(cinsert());

	/* insert some lines */
	while (n--) {
		if ((s=lnewline()) != TRUE)
			return (s);
	}
	return (TRUE);
}

cinsert()	/* insert a newline and indentation for C */

{
	register char *cptr;	/* string pointer into text to copy */
	register int tptr;	/* index to scan into line */
	register int bracef;	/* was there a brace at the end of line? */
	register int i;
	char ichar[NSTRING];	/* buffer to hold indent of last line */

	/* grab a pointer to text to copy indentation from */
	cptr = &curwp->w_dotp->l_text[0];

	/* check for a brace */
	tptr = curwp->w_doto - 1;
	bracef = (cptr[tptr] == '{');

	/* save the indent of the previous line */
	i = 0;
	while ((i < tptr) && (cptr[i] == ' ' || cptr[i] == '\t')
		&& (i < NSTRING - 1)) {
		ichar[i] = cptr[i];
		++i;
	}
	ichar[i] = 0;		/* terminate it */

	/* put in the newline */
	if (lnewline() == FALSE)
		return(FALSE);

	/* and the saved indentation */
	i = 0;
	while (ichar[i])
		linsert(1, ichar[i++]);

	/* and one more tab for a brace */
	if (bracef)
		tab(FALSE, 1);

	return(TRUE);
}

insbrace(n, c)	/* insert a brace into the text here...we are in CMODE */

int n;	/* repeat count */
int c;	/* brace to insert (always { for now) */

{
	register int ch;	/* last character before input */
	register int i;
	register int target;	/* column brace should go after */

	/* if we are at the begining of the line, no go */
	if (curwp->w_doto == 0)
		return(linsert(n,c));
		
	/* scan to see if all space before this is white space */
	for (i = curwp->w_doto - 1; i >= 0; --i) {
		ch = lgetc(curwp->w_dotp, i);
		if (ch != ' ' && ch != '\t')
			return(linsert(n, c));
	}

	/* delete back first */
	target = getccol(FALSE);	/* calc where we will delete to */
	target -= 1;
	target -= target % (tabsize == 0 ? 8 : tabsize);
	while (getccol(FALSE) > target)
		backdel(FALSE, 1);

	/* and insert the required brace(s) */
	return(linsert(n, c));
}

inspound()	/* insert a # into the text here...we are in CMODE */

{
	register int ch;	/* last character before input */
	register int i;

	/* if we are at the begining of the line, no go */
	if (curwp->w_doto == 0)
		return(linsert(1,'#'));
		
	/* scan to see if all space before this is white space */
	for (i = curwp->w_doto - 1; i >= 0; --i) {
		ch = lgetc(curwp->w_dotp, i);
		if (ch != ' ' && ch != '\t')
			return(linsert(1, '#'));
	}

	/* delete back first */
	while (getccol(FALSE) >= 1)
		backdel(FALSE, 1);

	/* and insert the required pound */
	return(linsert(1, '#'));
}

/*
 * Delete blank lines around dot. What this command does depends if dot is
 * sitting on a blank line. If dot is sitting on a blank line, this command
 * deletes all the blank lines above and below the current line. If it is
 * sitting on a non blank line then it deletes all of the blank lines after
 * the line. Normally this command is bound to "C-X C-O". Any argument is
 * ignored.
 */
deblank(f, n)
{
        register LINE   *lp1;
        register LINE   *lp2;
        long nld;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        lp1 = curwp->w_dotp;
        while (llength(lp1)==0 && (lp2=lback(lp1))!=curbp->b_linep)
                lp1 = lp2;
        lp2 = lp1;
        nld = 0;
        while ((lp2=lforw(lp2))!=curbp->b_linep && llength(lp2)==0)
                ++nld;
        if (nld == 0)
                return (TRUE);
        curwp->w_dotp = lforw(lp1);
        curwp->w_doto = 0;
        return (ldelete(nld, FALSE));
}

/*
 * Insert a newline, then enough tabs and spaces to duplicate the indentation
 * of the previous line. Assumes tabs are every eight characters. Quite simple.
 * Figure out the indentation of the current line. Insert a newline by calling
 * the standard routine. Insert the indentation by inserting the right number
 * of tabs and spaces. Return TRUE if all ok. Return FALSE if one of the
 * subcomands failed. Normally bound to "C-J".
 */
indent(f, n)
{
        register int    nicol;
        register int    c;
        register int    i;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if (n < 0)
                return (FALSE);
        while (n--) {
                nicol = 0;
                for (i=0; i<llength(curwp->w_dotp); ++i) {
                        c = lgetc(curwp->w_dotp, i);
                        if (c!=' ' && c!='\t')
                                break;
                        if (c == '\t')
                                nicol |= 0x07;
                        ++nicol;
                }
                if (lnewline() == FALSE
                || ((i=nicol/8)!=0 && linsert(i, '\t')==FALSE)
                || ((i=nicol%8)!=0 && linsert(i,  ' ')==FALSE))
                        return (FALSE);
        }
        return (TRUE);
}

/*
 * Delete forward. This is real easy, because the basic delete routine does
 * all of the work. Watches for negative arguments, and does the right thing.
 * If any argument is present, it kills rather than deletes, to prevent loss
 * of text if typed with a big argument. Normally bound to "C-D".
 */
forwdel(f, n)
{
	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if (n < 0)
                return (backdel(f, -n));
        if (f != FALSE) {                       /* Really a kill.       */
                if ((lastflag&CFKILL) == 0)
                        kdelete();
                thisflag |= CFKILL;
        }
        return (ldelete((long)n, f));
}

/*
 * Delete backwards. This is quite easy too, because it's all done with other
 * functions. Just move the cursor back, and delete forwards. Like delete
 * forward, this actually does a kill if presented with an argument. Bound to
 * both "RUBOUT" and "C-H".
 */
backdel(f, n)
{
        register int    s;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if (n < 0)
                return (forwdel(f, -n));
        if (f != FALSE) {                       /* Really a kill.       */
                if ((lastflag&CFKILL) == 0)
                        kdelete();
                thisflag |= CFKILL;
        }
        if ((s=backchar(f, n)) == TRUE)
                s = ldelete((long)n, f);
        return (s);
}

/*
 * Kill text. If called without an argument, it kills from dot to the end of
 * the line, unless it is at the end of the line, when it kills the newline.
 * If called with an argument of 0, it kills from the start of the line to dot.
 * If called with a positive argument, it kills from dot forward over that
 * number of newlines. If called with a negative argument it kills backwards
 * that number of newlines. Normally bound to "C-K".
 */
killtext(f, n)
{
        register LINE   *nextp;
        long chunk;

	if (curbp->b_mode&MDVIEW)	/* don't allow this command if	*/
		return(rdonly());	/* we are in read only mode	*/
        if ((lastflag&CFKILL) == 0)             /* Clear kill buffer if */
                kdelete();                      /* last wasn't a kill.  */
        thisflag |= CFKILL;
        if (f == FALSE) {
                chunk = llength(curwp->w_dotp)-curwp->w_doto;
                if (chunk == 0)
                        chunk = 1;
        } else if (n == 0) {
                chunk = curwp->w_doto;
                curwp->w_doto = 0;
        } else if (n > 0) {
                chunk = llength(curwp->w_dotp)-curwp->w_doto+1;
                nextp = lforw(curwp->w_dotp);
                while (--n) {
                        if (nextp == curbp->b_linep)
                                return (FALSE);
                        chunk += llength(nextp)+1;
                        nextp = lforw(nextp);
                }
        } else {
                mlwrite("neg kill");
                return (FALSE);
        }
        return(ldelete(chunk, TRUE));
}

setmode(f, n)	/* prompt and set an editor mode */

int f, n;	/* default and argument */

{
	adjustmode(TRUE, FALSE);
}

delmode(f, n)	/* prompt and delete an editor mode */

int f, n;	/* default and argument */

{
	adjustmode(FALSE, FALSE);
}

setgmode(f, n)	/* prompt and set a global editor mode */

int f, n;	/* default and argument */

{
	adjustmode(TRUE, TRUE);
}

delgmode(f, n)	/* prompt and delete a global editor mode */

int f, n;	/* default and argument */

{
	adjustmode(FALSE, TRUE);
}

adjustmode(kind, global)	/* change the editor mode status */

int kind;	/* true = set,		false = delete */
int global;	/* true = global flag,	false = current buffer flag */
{
	register char *scan;		/* scanning pointer to convert prompt */
	register int i;			/* loop index */
#if	COLOR
	register int uflag;		/* was modename uppercase?	*/
#endif
	char prompt[50];	/* string to prompt user with */
	char cbuf[NPAT];		/* buffer to recieve mode name into */

	/* build the proper prompt string */
	if (global)
		strcpy(prompt,"Global mode to ");
	else
		strcpy(prompt,"Mode to ");

	if (kind == TRUE)
		strcat(prompt, "add: ");
	else
		strcat(prompt, "delete: ");

	/* prompt the user and get an answer */

	mlreply(prompt, cbuf, NPAT - 1);

	/* make it uppercase */

	scan = cbuf;
#if	COLOR
	uflag = (*scan >= 'A' && *scan <= 'Z');
#endif
	while (*scan != 0) {
		if (*scan >= 'a' && *scan <= 'z')
			*scan = *scan - 32;
		scan++;
	}

	/* test it first against the colors we know */
	for (i=0; i<NCOLORS; i++) {
		if (strcmp(cbuf, cname[i]) == 0) {
			/* finding the match, we set the color */
#if	COLOR
			if (uflag)
				if (global)
					gfcolor = i;
				else
					curwp->w_fcolor = i;
			else
				if (global)
					gbcolor = i;
				else
					curwp->w_bcolor = i;

			curwp->w_flag |= WFCOLR;
#endif
			mlerase();
			return(TRUE);
		}
	}

	/* test it against the modes we know */

	for (i=0; i < NUMMODES; i++) {
		if (strcmp(cbuf, modename[i]) == 0) {
			/* finding a match, we process it */
			if (kind == TRUE)
				if (global)
					gmode |= (1 << i);
				else
					curwp->w_bufp->b_mode |= (1 << i);
			else
				if (global)
					gmode &= ~(1 << i);
				else
					curwp->w_bufp->b_mode &= ~(1 << i);
			/* display new mode line */
			if (global == 0)
				upmode();
			mlerase();	/* erase the junk */
			return(TRUE);
		}
	}

	mlwrite("No such mode!");
	return(FALSE);
}

/*	This function simply clears the message line,
		mainly for macro usage			*/

clrmes(f, n)

int f, n;	/* arguments ignored */

{
	mlwrite("");
	return(TRUE);
}

/*	This function writes a string on the message line
		mainly for macro usage			*/

writemsg(f, n)

int f, n;	/* arguments ignored */

{
	register char *sp;	/* pointer into buf to expand %s */
	register char *np;	/* ptr into nbuf */
	register int status;
	char buf[NPAT];		/* buffer to recieve mode name into */
	char nbuf[NPAT*2];	/* buffer to expand string into */

	if ((status = mlreply("Message to write: ", buf, NPAT - 1)) != TRUE)
		return(status);

	/* expand all '%' to "%%" so mlwrite won't expect arguments */
	sp = buf;
	np = nbuf;
	while (*sp) {
		*np++ = *sp;
		if (*sp++ == '%')
			*np++ = '%';
	}
	*np = '\0';
	mlwrite(nbuf);
	return(TRUE);
}

/*	Close fences are matched against their partners, and if
	on screen the cursor briefly lights there		*/

fmatch(ch)

char ch;	/* fence type to match against */

{
	register LINE *oldlp;	/* original line pointer */
	register int oldoff;	/* and offset */
	register LINE *toplp;	/* top line in current window */
	register int count;	/* current fence level count */
	register char opench;	/* open fence */
	register char c;	/* current character in scan */
	register int i;

	/* first get the display update out there */
	update(FALSE);

	/* save the original cursor position */
	oldlp = curwp->w_dotp;
	oldoff = curwp->w_doto;

	/* setup proper open fence for passed close fence */
	if (ch == ')')
		opench = '(';
	else
		opench = '{';

	/* find the top line and set up for scan */
	toplp = curwp->w_linep->l_bp;
	count = 1;
	backchar(FALSE, 2);

	/* scan back until we find it, or reach past the top of the window */
	while (count > 0 && curwp->w_dotp != toplp) {
		c = lgetc(curwp->w_dotp, curwp->w_doto);
		if (c == ch)
			++count;
		if (c == opench)
			--count;
		backchar(FALSE, 1);
		if (curwp->w_dotp == curwp->w_bufp->b_linep->l_fp &&
		    curwp->w_doto == 0)
			break;
	}

	/* if count is zero, we have a match, display the sucker */
	/* there is a real machine dependant timing problem here we have
	   yet to solve......... */
	if (count == 0) {
		forwchar(FALSE, 1);
		for (i = 0; i < term.t_pause; i++)
			update(FALSE);
	}

	/* restore the current position */
	curwp->w_dotp = oldlp;
	curwp->w_doto = oldoff;
	return(TRUE);
}

istring(f, n)	/* ask for and insert a string into the current
		   buffer at the current point */

int f, n;	/* ignored arguments */

{
	register char *tp;	/* pointer into string to add */
	register int status;	/* status return code */
	char tstring[NPAT+1];	/* string to add */

	/* ask for string to insert */
	status = mlreplyt("String to insert<ESC>: ", tstring, NPAT, 27);
	if (status != TRUE)
		return(status);

	/* insert it */
	tp = &tstring[0];
	while (*tp) {
		if (*tp == 0x0a)
			status = lnewline();
		else
			status = linsert(1, *tp);
		++tp;
		if (status != TRUE)
			return(status);
	}
	return(TRUE);
}

