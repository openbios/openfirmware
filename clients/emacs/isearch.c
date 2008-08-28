/*
 * The functions in this file implement commands that perform incremental
 * searches in the forward and backward directions.  This "ISearch" command
 * is intended to emulate the same command from the original EMACS 
 * implementation (ITS).  Contains references to routines internal to
 * SEARCH.C.
 *
 * REVISION HISTORY:
 *
 *	D. R. Banks 9-May-86
 *	- added ITS EMACSlike ISearch
 */

#include	"estruct.h"
#include        "edef.h"

/*	string search input parameters	*/

#define	PTBEG	1	/* leave the point at the beginning on search */
#define	PTEND	2	/* leave the point at the end on search */

#define	CMDBUFLEN 256	/* Length of our command buffer */

extern int forscan();			/* Handy search routine */
extern int eq();			/* Compare chars, match case */

/* A couple of "own" variables for re-eat */

int	(*saved_get_char)();		/* Get character routine */
int	eaten_char = -1;		/* Re-eaten char */

/* A couple more "own" variables for the command string */

char	cmd_buff[CMDBUFLEN];	/* Save the command args here */
int	cmd_offset;			/* Current offset into command buff */
int	cmd_reexecute = -1;		/* > 0 if re-executing command */

/* Some character constants within ISearch */

#define	IS_ABORT	0x07	/* Abort the isearch */
#define IS_BACKSP	0x08	/* Delete previous char */
#define	IS_TAB		0x09	/* Tab character (allowed search char) */
#define IS_NEWLINE	0x0D	/* New line from keyboard (Carriage return) */
#define	IS_QUOTE	0x11	/* Quote next character */
#define IS_REVERSE	0x12	/* Search backward */
#define	IS_FORWARD	0x13	/* Search forward */
#define	IS_VMSQUOTE	0x16	/* VMS quote character */
#define	IS_VMSFORW	0x18	/* Search forward for VMS */
#define	IS_QUIT		0x1B	/* Exit the search */
#define	IS_RUBOUT	0x7F	/* Delete previous character */

/*
 * Subroutine to do incremental reverse search.  It actually uses the
 * same code as the normal incremental search, as both can go both ways.
 */
 
int risearch(f, n)
{
    LINE *curline;			/* Current line on entry	      */
    int  curoff;			/* Current offset on entry	      */

    /* remember the initial . on entry: */

    curline = curwp->w_dotp;		/* Save the current line pointer      */
    curoff  = curwp->w_doto;		/* Save the current offset	      */

    /* Make sure the search doesn't match where we already are:		      */

    backchar(TRUE, 1);			/* Back up a character		      */

    if (!(isearch(f, -n)))		/* Call ISearch backwards	      */
    {					/* If error in search:		      */
	curwp->w_dotp = curline;	/* Reset the line pointer	      */
	curwp->w_doto = curoff;		/*  and the offset to original value  */
	curwp->w_flag |= WFMOVE;	/* Say we've moved		      */
	update(FALSE);			/* And force an update		      */
	mlwrite ("[search failed]");	/* Say we died			      */
    } else mlerase ();			/* If happy, just erase the cmd line  */
}

/* Again, but for the forward direction */

int fisearch(f, n)
{
    LINE *curline;			/* Current line on entry	      */
    int  curoff;			/* Current offset on entry	      */

    /* remember the initial . on entry: */

    curline = curwp->w_dotp;		/* Save the current line pointer      */
    curoff  = curwp->w_doto;		/* Save the current offset	      */

    /* do the search */

    if (!(isearch(f, n)))		/* Call ISearch forwards	      */
    {					/* If error in search:		      */
	curwp->w_dotp = curline;	/* Reset the line pointer	      */
	curwp->w_doto = curoff;		/*  and the offset to original value  */
	curwp->w_flag |= WFMOVE;	/* Say we've moved		      */
	update(FALSE);			/* And force an update		      */
	mlwrite ("[search failed]");	/* Say we died			      */
    } else mlerase ();			/* If happy, just erase the cmd line  */
}

/*
 * Subroutine to do an incremental search.  In general, this works similarly
 * to the older micro-emacs search function, except that the search happens
 * as each character is typed, with the screen and cursor updated with each
 * new search character.
 *
 * While searching forward, each successive character will leave the cursor
 * at the end of the entire matched string.  Typing a Control-S or Control-X
 * will cause the next occurrence of the string to be searched for (where the
 * next occurrence does NOT overlap the current occurrence).  A Control-R will
 * change to a backwards search, ESC will terminate the search and Control-G
 * will abort the search.  Rubout will back up to the previous match of the
 * string, or if the starting point is reached first, it will delete the
 * last character from the search string.
 *
 * While searching backward, each successive character will leave the cursor
 * at the beginning of the matched string.  Typing a Control-R will search
 * backward for the next occurrence of the string.  Control-S or Control-X
 * will revert the search to the forward direction.  In general, the reverse
 * incremental search is just like the forward incremental search inverted.
 *
 * In all cases, if the search fails, the user will be feeped, and the search
 * will stall until the pattern string is edited back into something that
 * exists (or until the search is aborted).
 */
 
isearch(f, n)
{
    int			status;		/* Search status */
    int			col;		/* prompt column */
    register int	cpos;		/* character number in search string  */
    register int	c;		/* current input character */
    char		pat_save[NPAT];	/* Saved copy of the old pattern str  */
    LINE		*curline;	/* Current line on entry	      */
    int			curoff;		/* Current offset on entry	      */
    int			init_direction;	/* The initial search direction	      */

    /* Initialize starting conditions */

    cmd_reexecute = -1;		/* We're not re-executing (yet?)      */
    cmd_offset = 0;			/* Start at the beginning of the buff */
    cmd_buff[0] = '\0';		/* Init the command buffer	      */
    strncpy (pat_save, pat, NPAT);	/* Save the old pattern string	      */
    curline = curwp->w_dotp;		/* Save the current line pointer      */
    curoff  = curwp->w_doto;		/* Save the current offset	      */
    init_direction = n;			/* Save the initial search direction  */

    /* This is a good place to start a re-execution: */

start_over:

    /* ask the user for the text of a pattern */
    col = promptpattern("ISearch: ");		/* Prompt, remember the col   */

    cpos = 0;					/* Start afresh		      */
    status = TRUE;				/* Assume everything's cool   */

    /*
       Get the first character in the pattern.  If we get an initial Control-S
       or Control-R, re-use the old search string and find the first occurrence
     */

    c = get_char();				/* Get the first character    */
    if ((c == IS_FORWARD) ||
        (c == IS_REVERSE) ||
        (c == IS_VMSFORW))			/* Reuse old search string?   */
    {
    	for (cpos = 0; pat[cpos] != 0; cpos++)	/* Yup, find the length	      */
    	    col = echochar(pat[cpos],col);	/*  and re-echo the string    */
	if (c == IS_REVERSE) {			/* forward search?	      */
	    n = -1;				/* No, search in reverse      */
	    backchar (TRUE, 1);			/* Be defensive about EOB     */
	} else
	    n = 1;				/* Yes, search forward	      */
	status = scanmore(pat,n,status);	/* Do the search	      */
	c = get_char ();			/* Get another character      */
    }

    /* Top of the per character loop */
        	
    for (;;)					/* ISearch per character loop */
    {
	/* Check for magic characters first: */
	/* Most cases here change the search */

	switch (c)				/* dispatch on the input char */
	{
	  case IS_ABORT:			/* If abort search request    */
	    return(FALSE);			/* Quit searching again	      */

	  case IS_REVERSE:			/* If backward search	      */
	  case IS_FORWARD:			/* If forward search	      */
	  case IS_VMSFORW:			/*  of either flavor	      */
	    if (c == IS_REVERSE)		/* If reverse search	      */
		n = -1;				/* Set the reverse direction  */
	    else				/* Otherwise, 		      */
		n = 1;				/*  go forward		      */
	    status = scanmore(pat,n,TRUE);	/* Start the search again     */
	    c = get_char ();			/* Get the next char	      */
	    continue;				/* Go continue with the search*/

	  case IS_QUIT:				/* Want to quit searching?    */
	    return (TRUE);			/* Quit searching now	      */

	  case IS_NEWLINE:			/* Carriage return	      */
	    c = '\n';				/* Make it a new line	      */
	    break;				/* Make sure we use it	      */

	  case IS_QUOTE:			/* Quote character	      */
	  case IS_VMSQUOTE:			/*  of either variety	      */
	    c = get_char ();			/* Get the next char	      */

	  case IS_TAB:				/* Generically allowed	      */
	  case '\n':				/*  controlled characters     */
	    break;				/* Make sure we use it	      */

	  case IS_BACKSP:			/* If a backspace:            */
	  case IS_RUBOUT:			/*  or if a Rubout:	      */
	    if (cmd_offset <= 1)		/* Anything to delete?	      */
		return (TRUE);			/* No, just exit	      */
	    --cmd_offset;			/* Back up over the Rubout    */
	    cmd_buff[--cmd_offset] = '\0'; /* Yes, delete last char   */
	    curwp->w_dotp = curline;		/* Reset the line pointer     */
	    curwp->w_doto = curoff;		/*  and the offset	      */
	    n = init_direction;			/* Reset the search direction */
	    strncpy (pat, pat_save, NPAT);	/* Restore the old search str */
	    cmd_reexecute = 0;		/* Start the whole mess over  */
	    goto start_over;			/* Let it take care of itself */

	  /* Presumably a quasi-normal character comes here */

	  default:				/* All other chars    	      */
	    if (c < ' ')			/* Is it printable?	      */
	    {					/* Nope.		      */
		reeat (c);			/* Re-eat the char	      */
		return (TRUE);			/* And return the last status */
	    }
	}  /* Switch */

	/* I guess we got something to search for, so search for it	      */

	pat[cpos++] = c;			/* put the char in the buffer */
	if (cpos >= NPAT)			/* too many chars in string?  */
	{					/* Yup.  Complain about it    */
	    mlwrite("? Search string too long");
	    return(TRUE);			/* Return an error	      */
	}
	pat[cpos] = 0;				/* null terminate the buffer  */
	col = echochar(c,col);			/* Echo the character	      */
	if (!status) {				/* If we lost last time	      */
	    (*term.t_putchar)(BELL);		/* Feep again		      */
	    (*term.t_flush)();			/* see that the feep feeps    */
	} else					/* Otherwise, we must have won*/
	    if (!(status = checknext(c,pat,n,status))) /* See if match	      */
		status = scanmore(pat,n,TRUE);	/*  or find the next match    */
	c = get_char ();			/* Get the next char	      */
    } /* for {;;} */
}

/*
 * Trivial routine to insure that the next character in the search string is
 * still true to whatever we're pointing to in the buffer.  This routine will
 * not attempt to move the "point" if the match fails, although it will 
 * implicitly move the "point" if we're forward searching, and find a match,
 * since that's the way forward isearch works.
 *
 * If the compare fails, we return FALSE and assume the caller will call
 * scanmore or something.
 */

int checknext (chr, patrn, dir, sts)/* Check next character in search string */
char	chr;			/* Next char to look for		 */
char	*patrn;			/* The entire search string (incl chr)   */
int	dir;			/* Search direction			 */
int	sts;			/* Search status			 */
{
    register LINE *curline;		/* current line during scan	      */
    register int curoff;		/* position within current line	      */
    register int buffchar;		/* character at current position      */
    int status;				/* how well things go		      */

    if (!sts) return(FALSE);		/* Don't try unless ok so far	      */

    /* setup the local scan pointer to current "." */

    curline = curwp->w_dotp;		/* Get the current line structure     */
    curoff  = curwp->w_doto;		/* Get the offset within that line    */

    if (dir > 0)			/* If searching forward		      */
    {
    	if (curoff == llength(curline)) /* If at end of line		      */
    	{
	    curline = lforw(curline);	/* Skip to the next line	      */
	    if (curline == curbp->b_linep)
		return (FALSE);		/* Abort if at end of buffer	      */
	    curoff = 0;			/* Start at the beginning of the line */
	    buffchar = '\n';		/* And say the next char is NL	      */
	} else
	    buffchar = lgetc(curline, curoff++); /* Get the next char	      */
	if (status = eq(buffchar, chr))	/* Is it what we're looking for?      */
	{
	    curwp->w_dotp = curline;	/* Yes, set the buffer's point	      */
	    curwp->w_doto = curoff;	/*  to the matched character	      */
	    curwp->w_flag |= WFMOVE;	/* Say that we've moved		      */
	}
	return (status);		/* And return the status	      */
    } else				/* Else, if reverse search:	      */
	return (match_pat (patrn));	/* See if we're in the right place    */
}

/*
 * This hack will search for the next occurrence of <pat> in the buffer, either
 * forward or backward.  It is called with the status of the prior search
 * attempt, so that it knows not to bother if it didn't work last time.  If
 * we can't find any more matches, "point" is left where it was before.  If
 * we do find a match, "point" will be at the end of the matched string for
 * forward searches and at the beginning of the matched string for reverse
 * searches.
 */
 
int scanmore(patrn,dir,sts)	/* search forward or back for a pattern	      */
char	*patrn;			/* string to scan for			      */
int	dir;			/* direction to search			      */
int	sts;			/* previous search status		      */
{
    if (sts) 			/* don't try unless successful last time      */
    {
    	if (dir < 0)				/* reverse search?	      */
	    sts = bakscan(patrn);		/* Yes, call our hacky routine*/
	else
	    sts = forscan(patrn,PTEND);		/* Nope. Go forward	      */
    }
    if (!sts) {
    	(*term.t_putchar)(BELL);		/* Feep if search fails       */
	(*term.t_flush)();			/* see that the feep feeps    */
    }
    return(sts);				/* else, don't even try	      */
}

/*
 * The following is a minimal implementation of the reverse of "forscan".
 * We aren't using the routine in SEARCH.C because it likes to type stuff,
 * but the real solution is probably to fix that instead of duplicate the
 * code here like we're doing.  On the other hand, we don't want to touch
 * more modules than we have to for this first round ...
 *
 * This always leaves "." at the beginning of the matched pattern string
 */

int bakscan (patrn)		/* Scan backwards for a match		      */
char	*patrn;			/* Search string to be matched		      */
{
    LINE *initline;			/* initial line pointer before scan   */
    int initoff;			/* position within initial line	      */

    /* Remember "point" on entry: */

    initline = curwp->w_dotp;		/* Get the current line structure     */
    initoff  = curwp->w_doto;		/* Get the offset within that line    */

    /*
     * Loop here, stepping the cursor until we match or until we reach the top
     * of the buffer
     */

    while (backchar(TRUE, 1))			/* As long as there're chars  */
	if (match_pat (patrn))			/* See if we match	      */
	    return (TRUE);			/* Yep.  Stop'er right here   */
    curwp->w_dotp = initline;			/* Top of buffer, just reset  */
    curwp->w_doto = initoff;			/*   to original "point"      */
    curwp->w_flag |= WFMOVE;			/* In case backchar moved us  */
    return (FALSE);				/* And return failure	      */
}

/*
 * The following is a worker subroutine used by the reverse search.  It
 * compares the pattern string with the characters at "." for equality. If
 * any characters mismatch, it will return FALSE.
 *
 * This isn't used for forward searches, because forward searches leave "."
 * at the end of the search string (instead of in front), so all that needs to
 * be done is match the last char input.
 */

int match_pat (patrn)	/* See if the pattern string matches string at "."   */
char	*patrn;		/* String to match to buffer			     */
{
    register int  i;			/* Generic loop index/offset	      */
    register int buffchar;		/* character at current position      */
    register LINE *curline;		/* current line during scan	      */
    register int curoff;		/* position within current line	      */

    /* setup the local scan pointer to current "." */

    curline = curwp->w_dotp;		/* Get the current line structure     */
    curoff  = curwp->w_doto;		/* Get the offset within that line    */

    /* top of per character compare loop: */

    for (i = 0; i < strlen(patrn); i++)	/* Loop for all characters in patrn   */
    {
    	if (curoff == llength(curline)) /* If at end of line		      */
    	{
	    curline = lforw(curline);	/* Skip to the next line	      */
	    curoff = 0;			/* Start at the beginning of the line */
	    if (curline == curbp->b_linep)
		return (FALSE);		/* Abort if at end of buffer	      */
	    buffchar = '\n';		/* And say the next char is NL	      */
	} else
	    buffchar = lgetc(curline, curoff++); /* Get the next char	      */
	if (!eq(buffchar, patrn[i]))	/* Is it what we're looking for?      */
	    return (FALSE);		/* Nope, just punt it then	      */
    }
    return (TRUE);			/* Everything matched? Let's celebrate*/
}

/* Routine to prompt for I-Search string. */

int promptpattern(prompt)
char *prompt;
{
    char tpat[NPAT+20];

    strcpy(tpat, prompt);		/* copy prompt to output string */
    strcat(tpat, " [");			/* build new prompt string */
    expandp(pat, &tpat[strlen(tpat)], NPAT/2);	/* add old pattern */
    strcat(tpat, "]<ESC>: ");

    /* check to see if we are executing a command line */
    if (!clexec) {
	mlwrite(tpat);
    }
    return(strlen(tpat));
}

/* routine to echo i-search characters */

int echochar(c,col)
int	c;	/* character to be echoed */
int	col;	/* column to be echoed in */
{
    movecursor(term.t_nrow,col);		/* Position the cursor	      */
    if ((c < ' ') || (c == 0x7F))		/* Control character?	      */
    {
	switch (c)				/* Yes, dispatch special cases*/
	{
	  case '\n':				/* Newline		      */
	    (*term.t_putchar)('<');
	    (*term.t_putchar)('N');
	    (*term.t_putchar)('L');
	    (*term.t_putchar)('>');
	    col += 3;
	    break;

	  case '\t':				/* Tab			      */
	    (*term.t_putchar)('<');
	    (*term.t_putchar)('T');
	    (*term.t_putchar)('A');
	    (*term.t_putchar)('B');
	    (*term.t_putchar)('>');
	    col += 4;
	    break;

	  case 0x7F:				/* Rubout:		      */
	    (*term.t_putchar)('^');		/* Output a funny looking     */
	    (*term.t_putchar)('?');		/*  indication of Rubout      */
	    col++;				/* Count the extra char       */
	    break;

	  default:				/* Vanilla control char       */
	    (*term.t_putchar)('^');		/* Yes, output prefix	      */
    	    (*term.t_putchar)(c+0x40);		/* Make it "^X"		      */
	    col++;				/* Count this char	      */
	}
    } else
	(*term.t_putchar)(c);			/* Otherwise, output raw char */
    (*term.t_flush)();				/* Flush the output	      */
    return(++col);				/* return the new column no   */
}

/*
 * Routine to get the next character from the input stream.  If we're reading
 * from the real terminal, force a screen update before we get the char. 
 * Otherwise, we must be re-executing the command string, so just return the
 * next character.
 */

int get_char ()
{
    int	c;				/* A place to get a character	      */

    /* See if we're re-executing: */

    if (cmd_reexecute >= 0)		/* Is there an offset?		      */
	if ((c = cmd_buff[cmd_reexecute++]) != 0)
	    return (c);			/* Yes, return any character	      */

    /* We're not re-executing (or aren't any more).  Try for a real char      */

    cmd_reexecute = -1;		/* Say we're in real mode again	      */
    update(FALSE);			/* Pretty up the screen		      */
    if (cmd_offset >= CMDBUFLEN-1)	/* If we're getting too big ...	      */
    {
	mlwrite ("? command too long");	/* Complain loudly and bitterly	      */
	return (IS_QUIT);		/* And force a quit		      */
    }
    c = (*term.t_getchar)();		/* Get the next character	      */
    cmd_buff[cmd_offset++] = c; /* Save the char for next time        */
    cmd_buff[cmd_offset] = '\0';/* And terminate the buffer	      */
    return (c);				/* Return the character		      */
}

/*
 * Hacky routine to re-eat a character.  This will save the character to be
 * re-eaten by redirecting the input call to a routine here.  Hack, etc.
 */

/* Come here on the next term.t_getchar call: */

int uneat()
{
    int c;

    term.t_getchar = saved_get_char;	/* restore the routine address	      */
    c = eaten_char;			/* Get the re-eaten char	      */
    eaten_char = -1;			/* Clear the old char		      */
    return(c);				/* and return the last char	      */
}

int reeat(c)
int	c;
{
    if (eaten_char != -1)		/* If we've already been here	      */
	return (0);			/* Don't do it again		      */
    eaten_char = c;			/* Else, save the char for later      */
    saved_get_char = term.t_getchar;	/* Save the char get routine	      */
    term.t_getchar = uneat;		/* Replace it with ours		      */
}

