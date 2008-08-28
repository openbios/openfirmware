/*	INPUT:	Various input routines for MicroEMACS 3.7
		written by Daniel Lawrence
		5/9/86						*/

#include	"estruct.h"
#include	"edef.h"

/*
 * Ask a yes or no question in the message line. Return either TRUE, FALSE, or
 * ABORT. The ABORT status is returned if the user bumps out of the question
 * with a ^G. Used any time a confirmation is required.
 */

mlyesno(prompt)

char *prompt;

{
	char c;			/* input character */
	char buf[NPAT];		/* prompt to user */

	for (;;) {
		/* build and prompt the user */
		strcpy(buf, prompt);
		strcat(buf, " [y/n]? ");
		mlwrite(buf);

		/* get the responce */
		c = (*term.t_getchar)();

		if (c == BELL)		/* Bail out! */
			return(ABORT);

		if (c=='y' || c=='Y')
			return(TRUE);

		if (c=='n' || c=='N')
			return(FALSE);
	}
}

/*
 * Write a prompt into the message line, then read back a response. Keep
 * track of the physical position of the cursor. If we are in a keyboard
 * macro throw the prompt away, and return the remembered response. This
 * lets macros run at full speed. The reply is always terminated by a carriage
 * return. Handle erase, kill, and abort keys.
 */

mlreply(prompt, buf, nbuf)
    char *prompt;
    char *buf;
{
	return(mlreplyt(prompt,buf,nbuf,'\n'));
}

/*	A more generalized prompt/reply function allowing the caller
	to specify the proper terminator. If the terminator is not
	a return ('\n') it will echo as "<NL>"
							*/
mlreplyt(prompt, buf, nbuf, eolchar)

char *prompt;
char *buf;
char eolchar;

{
	register int cpos;	/* current character position in string */
	register int i;
	register int c;
	register int quotef;	/* are we quoting the next char? */
	register int status;	/* status return value */


	cpos = 0;
	quotef = FALSE;

	if (kbdmop != NULL) {
		while ((c = *kbdmop++) != '\0')
			buf[cpos++] = c;

		buf[cpos] = 0;

		if (buf[0] == 0)
			return(FALSE);

		return(TRUE);
	}

	/* check to see if we are executing a command line */
	if (clexec) {
		status = nxtarg(buf);
		buf[nbuf-1] = 0;	/* make sure we null terminate it */
		return(status);
	}

	mlwrite(prompt);

	for (;;) {
	/* get a character from the user. if it is a <ret>, change it
	   to a <NL>							*/
		c = (*term.t_getchar)();
		if (c == 0x0d)
			c = '\n';

		if (c == eolchar && quotef == FALSE) {
			buf[cpos++] = 0;

			if (kbdmip != NULL) {
				if (kbdmip+cpos > &kbdm[NKBDM-3]) {
					ctrlg(FALSE, 0);
					(*term.t_flush)();
					return(ABORT);
				}

				for (i=0; i<cpos; ++i)
					*kbdmip++ = buf[i];
				}

				(*term.t_move)(term.t_nrow, 0);
				ttcol = 0;
				(*term.t_flush)();

				if (buf[0] == 0)
					return(FALSE);

				return(TRUE);

			} else if (c == 0x07 && quotef == FALSE) {
				/* Bell, abort */
				(*term.t_putchar)('^');
				(*term.t_putchar)('G');
				ttcol += 2;
				ctrlg(FALSE, 0);
				(*term.t_flush)();
				return(ABORT);

			} else if ((c==0x7F || c==0x08) && quotef==FALSE) {
				/* rubout/erase */
				if (cpos != 0) {
					(*term.t_putchar)('\b');
					(*term.t_putchar)(' ');
					(*term.t_putchar)('\b');
					--ttcol;

					if (buf[--cpos] < 0x20) {
						(*term.t_putchar)('\b');
						(*term.t_putchar)(' ');
						(*term.t_putchar)('\b');
						--ttcol;
					}

					if (buf[cpos] == '\n') {
						(*term.t_putchar)('\b');
						(*term.t_putchar)('\b');
						(*term.t_putchar)(' ');
						(*term.t_putchar)(' ');
						(*term.t_putchar)('\b');
						(*term.t_putchar)('\b');
						--ttcol;
						--ttcol;
					}

					(*term.t_flush)();
				}

			} else if (c == 0x15 && quotef == FALSE) {
				/* C-U, kill */
				while (cpos != 0) {
					(*term.t_putchar)('\b');
					(*term.t_putchar)(' ');
					(*term.t_putchar)('\b');
					--ttcol;

					if (buf[--cpos] < 0x20) {
						(*term.t_putchar)('\b');
						(*term.t_putchar)(' ');
						(*term.t_putchar)('\b');
						--ttcol;
					}
				}

				(*term.t_flush)();

			} else if (c == quotec && quotef == FALSE) {
				quotef = TRUE;
			} else {
				quotef = FALSE;
				if (cpos < nbuf-1) {
					buf[cpos++] = c;

					if ((c < ' ') && (c != '\n')) {
						(*term.t_putchar)('^');
						++ttcol;
						c ^= 0x40;
					}

					if (c != '\n')
						(*term.t_putchar)(c);
					else {	/* put out <NL> for <ret> */
						(*term.t_putchar)('<');
						(*term.t_putchar)('N');
						(*term.t_putchar)('L');
						(*term.t_putchar)('>');
						ttcol += 3;
					}
				++ttcol;
				(*term.t_flush)();
			}
		}
	}
}

/* get a command name from the command line. Command completion means
   that pressing a <SPACE> will attempt to complete an unfinished command
   name if it is unique.
*/

int (*getname())()

{
	register int cpos;	/* current column on screen output */
	register int c;
	register char *sp;	/* pointer to string for output */
	register NBIND *ffp;	/* first ptr to entry in name binding table */
	register NBIND *cffp;	/* current ptr to entry in name binding table */
	register NBIND *lffp;	/* last ptr to entry in name binding table */
	char buf[NSTRING];	/* buffer to hold tentative command name */
	int (*fncmatch())();

	/* starting at the begining of the string buffer */
	cpos = 0;

	/* if we are executing a keyboard macro, fill our buffer from there,
	   and attempt a straight match */
	if (kbdmop != NULL) {
		while ((c = *kbdmop++) != '\0')
			buf[cpos++] = c;

		buf[cpos] = 0;

		/* return the result of a match */
		return(fncmatch(&buf[0]));
	}

	/* if we are executing a command line get the next arg and match it */
	if (clexec) {
		if (nxtarg(buf) != TRUE)
			return(FALSE);
		return(fncmatch(&buf[0]));
	}

	/* build a name string from the keyboard */
	while (TRUE) {
		c = (*term.t_getchar)();

		/* if we are at the end, just match it */
		if (c == 0x0d) {
			buf[cpos] = 0;

			/* save keyboard macro string if needed */
			if (kbdtext(&buf[0]) == ABORT)
				return( (int (*)()) NULL);

			/* and match it off */
			return(fncmatch(&buf[0]));

		} else if (c == 0x07) {	/* Bell, abort */
			(*term.t_putchar)('^');
			(*term.t_putchar)('G');
			ttcol += 2;
			ctrlg(FALSE, 0);
			(*term.t_flush)();
			return( (int (*)()) NULL);

		} else if (c == 0x7F || c == 0x08) {	/* rubout/erase */
			if (cpos != 0) {
				(*term.t_putchar)('\b');
				(*term.t_putchar)(' ');
				(*term.t_putchar)('\b');
				--ttcol;
				--cpos;
				(*term.t_flush)();
			}

		} else if (c == 0x15) {	/* C-U, kill */
			while (cpos != 0) {
				(*term.t_putchar)('\b');
				(*term.t_putchar)(' ');
				(*term.t_putchar)('\b');
				--cpos;
				--ttcol;
			}

			(*term.t_flush)();

		} else if (c == ' ') {
/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
	/* attempt a completion */
	buf[cpos] = 0;		/* terminate it for us */
	ffp = &names[0];	/* scan for matches */
	while (ffp->n_func != NULL) {
		if (strncmp(buf, ffp->n_name, strlen(buf)) == 0) {
			/* a possible match! More than one? */
			if ((ffp + 1)->n_func == NULL ||
			   (strncmp(buf, (ffp+1)->n_name, strlen(buf)) != 0)) {
				/* no...we match, print it */
				sp = ffp->n_name + cpos;
				while (*sp)
					(*term.t_putchar)(*sp++);
				(*term.t_flush)();
				return(ffp->n_func);
			} else {
/* << << << << << << << << << << << << << << << << << */
	/* try for a partial match against the list */

	/* first scan down until we no longer match the current input */
	lffp = (ffp + 1);
	while ((lffp+1)->n_func != NULL) {
		if (strncmp(buf, (lffp+1)->n_name, strlen(buf)) != 0)
			break;
		++lffp;
	}

	/* and now, attempt to partial complete the string, char at a time */
	while (TRUE) {
		/* add the next char in */
		buf[cpos] = ffp->n_name[cpos];

		/* scan through the candidates */
		cffp = ffp + 1;
		while (cffp <= lffp) {
			if (cffp->n_name[cpos] != buf[cpos])
				goto onward;
			++cffp;
		}

		/* add the character */
		(*term.t_putchar)(buf[cpos++]);
	}
/* << << << << << << << << << << << << << << << << << */
			}
		}
		++ffp;
	}

	/* no match.....beep and onward */
	(*term.t_beep)();
onward:;
	(*term.t_flush)();
/* <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< */
		} else {
			if (cpos < NSTRING-1 && c > ' ') {
				buf[cpos++] = c;
				(*term.t_putchar)(c);
			}

			++ttcol;
			(*term.t_flush)();
		}
	}
}

kbdtext(buf)	/* add this text string to the current keyboard macro
		   definition						*/

char *buf;	/* text to add to keyboard macro */

{
	/* if we are defining a keyboard macro, save it */
	if (kbdmip != NULL) {
		if (kbdmip+strlen(buf) > &kbdm[NKBDM-4]) {
			ctrlg(FALSE, 0);
			(*term.t_flush)();
			return(ABORT);
		}

		/* copy string in and null terminate it */
		while (*buf)
			*kbdmip++ = *buf++;
		*kbdmip++ = 0;
	}
	return(TRUE);
}

/*	GET1KEY:	Get one keystroke. The only prefixs legal here
			are the SPEC and CTRL prefixes.
								*/

get1key()

{
	int    c;
#if	AMIGA
	int	d;
#endif

	/* get a keystroke */
        c = (*term.t_getchar)();
#if 0
        (*term.t_putchar)("0123456789abcdef"[(c>>4)&0xf]);
        (*term.t_putchar)("0123456789abcdef"[c&0xf]);
        (*term.t_putchar)('\r');
        (*term.t_putchar)('\n');
#endif

#if RAINBOW

        if (c & Function_Key)
                {
                int i;

                for (i = 0; i < lk_map_size; i++)
                        if (c == lk_map[i][0])
                                return lk_map[i][1];
                }
        else if (c == Shift + 015) return CTRL | 'J';
        else if (c == Shift + 0x7F) return META | 0x7F;
#endif

#if	MSDOS
	if (c == 0) {				/* Apply SPEC prefix	*/
	        c = (*term.t_getchar)();
	        if (c>=0x00 && c<=0x1F)		/* control key? */
        	        c = CTRL | (c+'@');
		return(SPEC | c);
	}
#endif

#if	AMIGA
	/* apply SPEC prefix */
	if ((unsigned)c == 155) {
		c = (*term.t_getchar)();

		/* first try to see if it is a cursor key */
		if ((c >= 'A' && c <= 'D') || c == 'S' || c == 'T')
			return(SPEC | c);

		/* next, a 2 char sequence */
		d = (*term.t_getchar)();
		if (d == '~')
			return(SPEC | c);

		/* decode a 3 char sequence */
		c = d + 32;
		/* if a shifted function key, eat the tilde */
		if (d >= '0' && d <= '9')
			d = (*term.t_getchar)();
		return(SPEC | c);
	}
#endif

#if  WANGPC
	if (c == 0x1F) {			/* Apply SPEC prefix    */
	        c = (*term.t_getchar)();
		return(SPEC | c);
	}
#endif

#if	OFW
	if (c == 0x9b) {			/* Apply SPEC prefix	*/
	        c = (*term.t_getchar)();
		if (c == 'O')			/* Function key		*/
		    c = (*term.t_getchar)();
		return(SPEC | c);
	}
#endif

        if (c>=0x00 && c<=0x1F)                 /* C0 control -> C-     */
                c = CTRL | (c+'@');
        return (c);
}

/*	GETCMD:	Get a command from the keyboard. Process all applicable
		prefix keys
							*/
getcmd()

{
	int c;		/* fetched keystroke */

	/* get initial character */
	c = get1key();

	/* process META prefix */
	if (c == metac) {
		c = get1key();
	        if (c>='a' && c<='z')		/* Force to upper */
        	        c -= 0x20;
	        if (c>=0x00 && c<=0x1F)		/* control key */
	        	c = CTRL | (c+'@');
		return(META | c);
	}

	/* process CTLX prefix */
	if (c == ctlxc) {
		c = get1key();
	        if (c>='a' && c<='z')		/* Force to upper */
        	        c -= 0x20;
	        if (c>=0x00 && c<=0x1F)		/* control key */
	        	c = CTRL | (c+'@');
		return(CTLX | c);
	}

	/* otherwise, just return it */
	return(c);
}
