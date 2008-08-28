/*	This file is for functions dealing with execution of
	commands, command lines, buffers, files and startup files

	written 1986 by Daniel Lawrence				*/

#include	"estruct.h"
#include	"edef.h"

/* namedcmd:	execute a named command even if it is not bound
*/

namedcmd(f, n)

int f, n;	/* command arguments [passed through to command executed] */

{
	register (*kfunc)();	/* ptr to the requexted function to bind to */
	int (*getname())();

	/* prompt the user to type a named command */
	mlwrite(": ");

	/* and now get the function name to execute */
	kfunc = getname();
	if (kfunc == NULL) {
		mlwrite("[No such function]");
		return(FALSE);
	}

	/* and then execute the command */
	return((*kfunc)(f, n));
}

/*	execcmd:	Execute a command line command to be typed in
			by the user					*/

execcmd(f, n)

int f, n;	/* default Flag and Numeric argument */

{
	register int status;		/* status return */
	char cmdstr[NSTRING];		/* string holding command to execute */

	/* get the line wanted */
	if ((status = mlreply(": ", cmdstr, NSTRING)) != TRUE)
		return(status);

	return(docmd(cmdstr));
}

/*	docmd:	take a passed string as a command line and translate
		it to be executed as a command. This function will be
		used by execute-command-line and by all source and
		startup files.

	format of the command line is:

		{# arg} <command-name> {<argument string(s)>}

	Macro storing is turned off by a line:

		[end]
*/

docmd(cline)

char *cline;	/* command line to execute */

{
	register char *tp;	/* pointer to current position in token */
	register int f;		/* default argument flag */
	register int n;		/* numeric repeat value */
	register int i;
	int sign;		/* sign of numeric argument */
	int (*fnc)();		/* function to execute */
	int status;		/* return status of function */
	int oldcle;		/* old contents of clexec flag */
	int llen;		/* length of cline */
	struct LINE *lp;	/* a line pointer */
	char token[NSTRING];	/* next token off of command line */
	int (*fncmatch())();

	/* check to see if this line turns macro storage off */
	if (strcmp(cline, "[end]") == 0) {
		mstore = FALSE;
		bstore = NULL;
		return(TRUE);
	}

	/* if macro store is on, just salt this away */
	if (mstore) {
		/* trim leading indentation */
		while (cline[0] == ' ' || cline[0] == '\t')
			strcpy(cline, &cline[1]);

		/* allocate the space for the line */
		llen = strlen(cline);
		if ((lp=lalloc(llen)) == NULL) {
			mlwrite("Out of memory while storing macro");
			return (FALSE);
		}

		/* copy the text into the new line */
		for (i=0; i<llen; ++i)
			lputc(lp, i, cline[i]);

		/* attach the line to the end of the buffer */
       		bstore->b_linep->l_bp->l_fp = lp;
		lp->l_bp = bstore->b_linep->l_bp;
		bstore->b_linep->l_bp = lp;
		lp->l_fp = bstore->b_linep;
		return (TRUE);
	}
	
	/* first set up the default command values */
	f = FALSE;
	n = 1;

	strcpy(sarg, cline);	/* move string to string argument buffer */
	if ((status = nxtarg(token)) != TRUE)	/* and grab the first token */
		return(status);

	/* check for and process numeric leadin argument */
	if ((token[0] >= '0' && token[0] <= '9') || token[0] == '-') {
		f = TRUE;
		n = 0;
		tp = &token[0];

		/* check for a sign! */
		sign = 1;
		if (*tp == '-') {
			++tp;
			sign = -1;
		}

		/* calc up the digits in the token string */
		while(*tp) {
			if (*tp >= '0' && *tp <= '9')
				n = n * 10 + *tp - '0';
			++tp;
		}
		n *= sign;	/* adjust for the sign */

		/* and now get the command to execute */
		if ((status = nxtarg(token)) != TRUE)
			return(status);		
	}

	/* and match the token to see if it exists */
	if ((fnc = fncmatch(token)) == NULL) {
		mlwrite("[No such Function]");
		return(FALSE);
	}
	
	/* save the arguments and go execute the command */
	oldcle = clexec;		/* save old clexec flag */
	clexec = TRUE;			/* in cline execution */
	status = (*fnc)(f, n);		/* call the function */
	clexec = oldcle;		/* restore clexec flag */
	return(status);
}

/* gettok:	chop a token off a string
		return a pointer past the token
*/

char *gettok(src, tok)

char *src, *tok;	/* source string, destination token string */

{
	register int quotef;	/* is the current string quoted? */

	/* first scan past any whitespace in the source string */
	while (*src == ' ' || *src == '\t')
		++src;

	/* if quoted, record it */
	quotef = (*src == '"');
	if (quotef)
		++src;

	/* scan through the source string */
	while (*src) {
		/* process special characters */
		if (*src == '~') {
			++src;
			if (*src == 0)
				break;
			switch (*src++) {
				case 'r':	*tok++ = 13; break;
				case 'n':	*tok++ = 10; break;
				case 't':	*tok++ = 9;  break;
				case 'b':	*tok++ = 8;  break;
				case 'f':	*tok++ = 12; break;
				case '@':	*tok++ = 192;break;
				default:	*tok++ = *(src-1);
			}
		} else {
			/* check for the end of the token */
			if (quotef) {
				if (*src == '"')
					break;
			} else {
				if (*src == ' ' || *src == '\t')
					break;
			}

			/* record the character */
			*tok++ = *src++;
		}
	}

	/* terminate the token and exit */
	if (*src)
		++src;
	*tok = 0;
	return(src);
}

/* nxtarg:	grab the next token out of sarg, return it, and
		chop it of sarg					*/

nxtarg(tok)

char *tok;	/* buffer to put token into */

{
	register char *newsarg;	/* pointer to new begining of sarg */
	register oldexec;	/* saved execution flag */
	register BUFFER *bp;	/* ptr to buffer to get arg from */
	register int status;
	char *gettok();

	newsarg = gettok(sarg, tok);	/* grab the token */
	strcpy(sarg, newsarg);		/* and chop it of sarg */

	/* check for an interactive argument */
	if (*tok == '@') {		/* get interactive argument */
		oldexec = clexec;	/* save execution flag */
		clexec = FALSE;
		status = mlreply(&tok[1], &tok[0], NSTRING);
		clexec = oldexec;
		if (status != TRUE)
			return(status);
	}

	/* check for a quoted "@" in the first position */
	if ((unsigned char)*tok == 192)
		*tok = '@';

	/* check for an argument from a buffer */
	if (*tok == '#') {

		/* get the referenced buffer */
		bp = bfind(&tok[1], FALSE, 0);
		if (bp == NULL)
			return(FALSE);

		/* make sure we are not at the end */
		if (bp->b_linep == bp->b_dotp)
			return(FALSE);

		/* grab the line as an argument */
		strncpy(tok, bp->b_dotp->l_text, bp->b_dotp->l_used);
		tok[bp->b_dotp->l_used] = 0;

		/* and step the buffer's line ptr ahead a line */
		bp->b_dotp = bp->b_dotp->l_fp;
		bp->b_doto = 0;
	}

	return(TRUE);
}

/*	storemac:	Set up a macro buffer and flag to store all
			executed command lines there			*/

storemac(f, n)

int f;		/* default flag */
int n;		/* macro number to use */

{
	register struct BUFFER *bp;	/* pointer to macro buffer */
	char bname[NBUFN];		/* name of buffer to use */

	/* must have a numeric argument to this function */
	if (f == FALSE) {
		mlwrite("No macro specified");
		return(FALSE);
	}

	/* range check the macro number */
	if (n < 1 || n > 40) {
		mlwrite("Macro number out of range");
		return(FALSE);
	}

	/* construct the macro buffer name */
	strcpy(bname, "[Macro xx]");
	bname[7] = '0' + (n / 10);
	bname[8] = '0' + (n % 10);

	/* set up the new macro buffer */
	if ((bp = bfind(bname, TRUE, BFINVS)) == NULL) {
		mlwrite("Can not create macro");
		return(FALSE);
	}

	/* and make sure it is empty */
	bclear(bp);

	/* and set the macro store pointers to it */
	mstore = TRUE;
	bstore = bp;
	return(TRUE);
}

/*	execbuf:	Execute the contents of a buffer of commands	*/

execbuf(f, n)

int f, n;	/* default flag and numeric arg */

{
        register BUFFER *bp;		/* ptr to buffer to execute */
        register int status;		/* status return */
        char bufn[NBUFN];		/* name of buffer to execute */

	/* find out what buffer the user wants to execute */
        if ((status = mlreply("Execute buffer: ", bufn, NBUFN)) != TRUE)
                return(status);

	/* find the pointer to that buffer */
        if ((bp=bfind(bufn, FALSE, 0)) == NULL) {
		mlwrite("No such buffer");
                return(FALSE);
        }

	/* and now execute it as asked */
	while (n-- > 0)
		if ((status = dobuf(bp)) != TRUE)
			return(status);
	return(TRUE);
}

/*	dobuf:	execute the contents of the buffer pointed to
		by the passed BP				*/

dobuf(bp)

BUFFER *bp;	/* buffer to execute */

{
        register int status;		/* status return */
	register LINE *lp;		/* pointer to line to execute */
	register LINE *hlp;		/* pointer to line header */
	register int linlen;		/* length of line to execute */
	register WINDOW *wp;		/* ptr to windows to scan */
	char eline[NSTRING];		/* text of line to execute */

	/* starting at the beginning of the buffer */
	hlp = bp->b_linep;
	lp = hlp->l_fp;
	while (lp != hlp) {
		/* calculate the line length and make a local copy */
		linlen = lp->l_used;
		if (linlen > NSTRING - 1)
			linlen = NSTRING - 1;
		strncpy(eline, lp->l_text, linlen);
		eline[linlen] = 0;	/* make sure it ends */

		/* if it is not a comment, execute it */
		if (eline[0] != ';' && eline[0] != 0) {
			status = docmd(eline);
			if (status != TRUE) {	/* a command error */
				/* look if buffer is showing */
				wp = wheadp;
				while (wp != NULL) {
					if (wp->w_bufp == bp) {
						/* and point it */
						wp->w_dotp = lp;
						wp->w_doto = 0;
						wp->w_flag |= WFHARD;
					}
					wp = wp->w_wndp;
				}
				/* in any case set the buffer . */
				bp->b_dotp = lp;
				bp->b_doto = 0;
				return(status);
			}
		}
		lp = lp->l_fp;		/* on to the next line */
	}
        return(TRUE);
}

execfile(f, n)	/* execute a series of commands in a file
*/

int f, n;	/* default flag and numeric arg to pass on to file */

{
	register int status;	/* return status of name query */
	char *fname[NSTRING];	/* name of file to execute */

	if ((status = mlreply("File to execute: ", fname, NSTRING -1)) != TRUE)
		return(status);

	/* otherwise, execute it */
	while (n-- > 0)
		if ((status=dofile(fname)) != TRUE)
			return(status);

	return(TRUE);
}

/*	dofile:	yank a file into a buffer and execute it
		if there are no errors, delete the buffer on exit */

dofile(fname)

char *fname;	/* file name to execute */

{
	register BUFFER *bp;	/* buffer to place file to exeute */
	register BUFFER *cb;	/* temp to hold current buf while we read */
	register int status;	/* results of various calls */
	char bname[NBUFN];	/* name of buffer */

	makename(bname, fname);		/* derive the name of the buffer */
	if ((bp = bfind(bname, TRUE, 0)) == NULL) /* get the needed buffer */
		return(FALSE);

	bp->b_mode = MDVIEW;	/* mark the buffer as read only */
	cb = curbp;		/* save the old buffer */
	curbp = bp;		/* make this one current */
	/* and try to read in the file to execute */
	if ((status = readin(fname, FALSE)) != TRUE) {
		curbp = cb;	/* restore the current buffer */
		return(status);
	}

	/* go execute it! */
	curbp = cb;		/* restore the current buffer */
	if ((status = dobuf(bp)) != TRUE)
		return(status);

	/* if not displayed, remove the now unneeded buffer and exit */
	if (bp->b_nwnd == 0)
		zotbuf(bp);
	return(TRUE);
}

/*	cbuf:	Execute the contents of a numbered buffer	*/

cbuf(f, n, bufnum)

int f, n;	/* default flag and numeric arg */
int bufnum;	/* number of buffer to execute */

{
        register BUFFER *bp;		/* ptr to buffer to execute */
        register int status;		/* status return */
	static char bufname[] = "[Macro xx]";

	/* make the buffer name */
	bufname[7] = '0' + (bufnum / 10);
	bufname[8] = '0' + (bufnum % 10);

	/* find the pointer to that buffer */
        if ((bp=bfind(bufname, FALSE, 0)) == NULL) {
        	mlwrite("Macro not defined");
                return(FALSE);
        }

	/* and now execute it as asked */
	while (n-- > 0)
		if ((status = dobuf(bp)) != TRUE)
			return(status);
	return(TRUE);
}

cbuf1(f, n)

{
	cbuf(f, n, 1);
}

cbuf2(f, n)

{
	cbuf(f, n, 2);
}

cbuf3(f, n)

{
	cbuf(f, n, 3);
}

cbuf4(f, n)

{
	cbuf(f, n, 4);
}

cbuf5(f, n)

{
	cbuf(f, n, 5);
}

cbuf6(f, n)

{
	cbuf(f, n, 6);
}

cbuf7(f, n)

{
	cbuf(f, n, 7);
}

cbuf8(f, n)

{
	cbuf(f, n, 8);
}

cbuf9(f, n)

{
	cbuf(f, n, 9);
}

cbuf10(f, n)

{
	cbuf(f, n, 10);
}

cbuf11(f, n)

{
	cbuf(f, n, 11);
}

cbuf12(f, n)

{
	cbuf(f, n, 12);
}

cbuf13(f, n)

{
	cbuf(f, n, 13);
}

cbuf14(f, n)

{
	cbuf(f, n, 14);
}

cbuf15(f, n)

{
	cbuf(f, n, 15);
}

cbuf16(f, n)

{
	cbuf(f, n, 16);
}

cbuf17(f, n)

{
	cbuf(f, n, 17);
}

cbuf18(f, n)

{
	cbuf(f, n, 18);
}

cbuf19(f, n)

{
	cbuf(f, n, 19);
}

cbuf20(f, n)

{
	cbuf(f, n, 20);
}

cbuf21(f, n)

{
	cbuf(f, n, 21);
}

cbuf22(f, n)

{
	cbuf(f, n, 22);
}

cbuf23(f, n)

{
	cbuf(f, n, 23);
}

cbuf24(f, n)

{
	cbuf(f, n, 24);
}

cbuf25(f, n)

{
	cbuf(f, n, 25);
}

cbuf26(f, n)

{
	cbuf(f, n, 26);
}

cbuf27(f, n)

{
	cbuf(f, n, 27);
}

cbuf28(f, n)

{
	cbuf(f, n, 28);
}

cbuf29(f, n)

{
	cbuf(f, n, 29);
}

cbuf30(f, n)

{
	cbuf(f, n, 30);
}

cbuf31(f, n)

{
	cbuf(f, n, 31);
}

cbuf32(f, n)

{
	cbuf(f, n, 32);
}

cbuf33(f, n)

{
	cbuf(f, n, 33);
}

cbuf34(f, n)

{
	cbuf(f, n, 34);
}

cbuf35(f, n)

{
	cbuf(f, n, 35);
}

cbuf36(f, n)

{
	cbuf(f, n, 36);
}

cbuf37(f, n)

{
	cbuf(f, n, 37);
}

cbuf38(f, n)

{
	cbuf(f, n, 38);
}

cbuf39(f, n)

{
	cbuf(f, n, 39);
}

cbuf40(f, n)

{
	cbuf(f, n, 40);
}


