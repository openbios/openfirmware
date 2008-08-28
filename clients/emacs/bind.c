/*	This file is for functions having to do with key bindings,
	descriptions, help commands and startup file.

	written 11-feb-86 by Daniel Lawrence
								*/

#include	"estruct.h"
#include	"edef.h"
#include	"epath.h"

extern int foo;
extern int meta(), cex();	/* dummy prefix binding functions */

deskey(f, n)	/* describe the command for a certain key */

{
	register int c;		/* command character to describe */
	register char *ptr;	/* string pointer to scan output strings */
	register KEYTAB *ktp;	/* pointer into the command table */
	register int found;	/* matched command flag */
	register NBIND *nptr;	/* pointer into the name binding table */
	char outseq[80];	/* output buffer for command sequence */

	/* prompt the user to type us a key to describe */
	mlwrite(": describe-key ");

	/* get the command sequence to describe */
	c = getckey(FALSE);			/* get a command sequence */

	/* change it to something we can print as well */
	cmdstr(c, &outseq[0]);

	/* and dump it out */
	ptr = &outseq[0];
	while (*ptr)
		(*term.t_putchar)(*ptr++);
	(*term.t_putchar)(' ');		/* space it out */

	/* find the right ->function */
	ktp = &keytab[0];
	found = FALSE;
	while (ktp->k_fp != NULL) {
		if (ktp->k_code == c) {
			found = TRUE;
			break;
		}
		++ktp;
	}

	if (!found)
		strcpy(outseq,"Not Bound");
	else {
		/* match it against the name binding table */
		nptr = &names[0];
		strcpy(outseq,"[Bad binding]");
		while (nptr->n_func != NULL) {
			if (nptr->n_func == ktp->k_fp) {
				strcpy(outseq, nptr->n_name);
				break;
			}
			++nptr;
		}
	}

	/* output the command sequence */
	ptr = &outseq[0];
	while (*ptr)
		(*term.t_putchar)(*ptr++);
}

cmdstr(c, seq)	/* change a key command to a string we can print out */

int c;		/* sequence to translate */
char *seq;	/* destination string for sequence */

{
	char *ptr;	/* pointer into current position in sequence */

	ptr = seq;

	/* apply meta sequence if needed */
	if (c & META) {
		*ptr++ = 'M';
		*ptr++ = '-';
	}

	/* apply ^X sequence if needed */
	if (c & CTLX) {
		*ptr++ = '^';
		*ptr++ = 'X';
	}

	/* apply SPEC sequence if needed */
	if (c & SPEC) {
		*ptr++ = 'F';
		*ptr++ = 'N';
	}

	/* apply control sequence if needed */
	if (c & CTRL) {
		*ptr++ = '^';
	}

	c = c & 255;	/* strip the prefixes */

	/* and output the final sequence */

	*ptr++ = c;
	*ptr = 0;	/* terminate the string */
}

#if	(MSDOS & (LATTICE | AZTEC | MSC)) | V7 | USG | BSD | OFW
char *homedir;		/* pointer to your home directory */
char *getenv();
char *gethomedir(void);
#endif

help(f, n)	/* give me some help!!!!
		   bring up a fake buffer and read the help file
		   into it with view mode			*/
{
	register int status;	/* status of I/O operations */
	register WINDOW *wp;	/* scaning pointer to windows */
	register BUFFER *bp;	/* buffer pointer to help */
	register int i;		/* index into help file names */
	char fname[NSTRING];	/* buffer to construct file name in */

	/* first check if we are already here */
	bp = bfind("emacs.hlp", FALSE, BFINVS);

	if (bp == NULL) {
#if	(MSDOS & (LATTICE | AZTEC | MSC)) | V7 | USG | BSD | OFW
		/* Look in the Emacs home directory */
#if OFW
		if ((homedir = getenv("EMACSHOME")) != NULL
		  ||(homedir = gethomedir()) != NULL) {
#else
		if ((homedir = getenv("EMACSHOME")) != NULL) {
#endif
			/* build the file name */
			strcpy(fname, homedir);
#if ! OFW
			if ( *homedir
			    && homedir[strlen(homedir)-1] != '/'
			    && homedir[strlen(homedir)-1] != '\\'
		    	)
				strcat(fname, "/");
#endif
			strcat(fname, pathname[1]);

			/* and test it */
			status = ffropen(fname);
			if (status == FIOSUC)
				goto okay;
		}
#endif

		/* search through the list of help files */
		for (i=2; i < NPNAMES; i++) {
			strcpy(fname, pathname[i]);
			strcat(fname, pathname[1]);
			status = ffropen(fname);
			if (status == FIOSUC)
				goto okay;
		}

		if (status == FIOFNF) {
			mlwrite("[Help file is not online]");
			return(FALSE);
		}

okay:
		/* close the file to prepare for to read it in */
		ffclose();
	}

	/* split the current window to make room for the help stuff */
	if (splitwind(FALSE, 1) == FALSE)
			return(FALSE);

	if (bp == NULL) {
		/* and read the stuff in */
		if (getfile(fname, FALSE) == FALSE)
			return(FALSE);
	} else
		swbuffer(bp);

	/* make this window in VIEW mode, update all mode lines */
	curwp->w_bufp->b_mode |= MDVIEW;
	curwp->w_bufp->b_flag |= BFINVS;
	wp = wheadp;
	while (wp != NULL) {
		wp->w_flag |= WFMODE;
		wp = wp->w_wndp;
	}
	return(TRUE);
}

int (*fncmatch(fname))() /* match fname to a function in the names table
			    and return any match or NULL if none		*/

char *fname;	/* name to attempt to match */

{
	register NBIND *ffp;	/* pointer to entry in name binding table */

	/* scan through the table, returning any match */
	ffp = &names[0];
	while (ffp->n_func != NULL) {
		if (strcmp(fname, ffp->n_name) == 0)
			return(ffp->n_func);
		++ffp;
	}
	return(NULL);
}

/* bindtokey:	add a new key to the key binding table
*/

bindtokey(f, n)

int f, n;	/* command arguments [IGNORED] */

{
	register int c;		/* command key to bind */
	register (*kfunc)();	/* ptr to the requexted function to bind to */
	register char *ptr;	/* ptr to dump out input key string */
	register KEYTAB *ktp;	/* pointer into the command table */
	register int found;	/* matched command flag */
	char outseq[80];	/* output buffer for keystroke sequence */
	int (*getname())();

	/* prompt the user to type in a key to bind */
	mlwrite(": bind-to-key ");

	/* get the function name to bind it to */
	kfunc = getname();
	if (kfunc == NULL) {
		mlwrite("[No such function]");
		return(FALSE);
	}
	(*term.t_putchar)(' ');		/* space it out */
	(*term.t_flush)();

	/* get the command sequence to bind */
	c = getckey((kfunc == meta) || (kfunc == cex));

	/* change it to something we can print as well */
	cmdstr(c, &outseq[0]);

	/* and dump it out */
	ptr = &outseq[0];
	while (*ptr)
		(*term.t_putchar)(*ptr++);

	/* if the function is a prefix key */
	if (kfunc == meta || kfunc == cex) {

		/* search for an existing binding for the prefix key */
		ktp = &keytab[0];
		found = FALSE;
		while (ktp->k_fp != NULL) {
			if (ktp->k_fp == kfunc) {
				found = TRUE;
				break;
			}
			++ktp;
		}

		/* reset the appropriate global prefix variable */
		if (kfunc == meta)
			metac = c;
		if (kfunc == cex)
			ctlxc = c;

		/* if we found it, just reset it
		   otherwise, let it fall through and be added to the end */
		if (found) {
			ktp->k_code = c;
			return(TRUE);
		}
	} else {

		/* search the table to see if it exists */
		ktp = &keytab[0];
		found = FALSE;
		while (ktp->k_fp != NULL) {
			if (ktp->k_code == c) {
				found = TRUE;
				break;
			}
			++ktp;
		}
	}

	if (found) {	/* it exists, just change it then */
		ktp->k_fp = kfunc;
	} else {	/* otherwise we need to add it to the end */
		/* if we run out of binding room, bitch */
		if (ktp >= &keytab[NBINDS]) {
			mlwrite("Binding table FULL!");
			return(FALSE);
		}

		ktp->k_code = c;	/* add keycode */
		ktp->k_fp = kfunc;	/* and the function pointer */
		++ktp;			/* and make sure the next is null */
		ktp->k_code = 0;
		ktp->k_fp = NULL;
	}
	return(TRUE);
}

/* unbindkey:	delete a key from the key binding table
*/

unbindkey(f, n)

int f, n;	/* command arguments [IGNORED] */

{
	register int c;		/* command key to unbind */
	register char *ptr;	/* ptr to dump out input key string */
	register KEYTAB *ktp;	/* pointer into the command table */
	register KEYTAB *sktp;	/* saved pointer into the command table */
	register int found;	/* matched command flag */
	char outseq[80];	/* output buffer for keystroke sequence */

	/* prompt the user to type in a key to unbind */
	mlwrite(": unbind-key ");

	/* get the command sequence to unbind */
	c = getckey(FALSE);		/* get a command sequence */

	/* change it to something we can print as well */
	cmdstr(c, &outseq[0]);

	/* and dump it out */
	ptr = &outseq[0];
	while (*ptr)
		(*term.t_putchar)(*ptr++);

	/* search the table to see if the key exists */
	ktp = &keytab[0];
	found = FALSE;
	while (ktp->k_fp != NULL) {
		if (ktp->k_code == c) {
			found = TRUE;
			break;
		}
		++ktp;
	}

	/* if it isn't bound, bitch */
	if (!found) {
		mlwrite("[Key not bound]");
		return(FALSE);
	}

	/* save the pointer and scan to the end of the table */
	sktp = ktp;
	while (ktp->k_fp != NULL)
		++ktp;
	--ktp;		/* backup to the last legit entry */

	/* copy the last entry to the current one */
	sktp->k_code = ktp->k_code;
	sktp->k_fp   = ktp->k_fp;

	/* null out the last one */
	ktp->k_code = 0;
	ktp->k_fp = NULL;
	return(TRUE);
}

desbind(f, n)	/* describe bindings
		   bring up a fake buffer and list the key bindings
		   into it with view mode			*/
{
	register WINDOW *wp;	/* scnaning pointer to windows */
	register KEYTAB *ktp;	/* pointer into the command table */
	register NBIND *nptr;	/* pointer into the name binding table */
	register BUFFER *bp;	/* buffer to put binding list into */
	char *strp;		/* pointer int string to send */
	int cpos;		/* current position to use in outseq */
	char outseq[80];	/* output buffer for keystroke sequence */

	/* split the current window to make room for the binding list */
	if (splitwind(FALSE, 1) == FALSE)
			return(FALSE);

	/* and get a buffer for it */
	bp = bfind("Binding list", TRUE, 0);
	if (bp == NULL || bclear(bp) == FALSE) {
		mlwrite("Can not display binding list");
		return(FALSE);
	}

	/* let us know this is in progress */
	mlwrite("[Building buffer list]");

	/* disconect the current buffer */
        if (--curbp->b_nwnd == 0) {             /* Last use.            */
                curbp->b_dotp  = curwp->w_dotp;
                curbp->b_doto  = curwp->w_doto;
                curbp->b_markp = curwp->w_markp;
                curbp->b_marko = curwp->w_marko;
        }

	/* connect the current window to this buffer */
	curbp = bp;	/* make this buffer current in current window */
	bp->b_mode = 0;		/* no modes active in binding list */
	bp->b_nwnd++;		/* mark us as more in use */
	wp = curwp;
	wp->w_bufp = bp;
	wp->w_linep = bp->b_linep;
	wp->w_flag = WFHARD|WFFORCE;
	wp->w_dotp = bp->b_dotp;
	wp->w_doto = bp->b_doto;
	wp->w_markp = NULL;
	wp->w_marko = 0;

	/* build the contents of this window, inserting it line by line */
	nptr = &names[0];
	while (nptr->n_func != NULL) {

		/* add in the command name */
		strcpy(outseq, nptr->n_name);
		cpos = strlen(outseq);
		
		/* search down any keys bound to this */
		ktp = &keytab[0];
		while (ktp->k_fp != NULL) {
			if (ktp->k_fp == nptr->n_func) {
				/* padd out some spaces */
				while (cpos < 25)
					outseq[cpos++] = ' ';

				/* add in the command sequence */
				cmdstr(ktp->k_code, &outseq[cpos]);
				while (outseq[cpos] != 0)
					++cpos;

				/* and add it as a line into the buffer */
				strp = &outseq[0];
				while (*strp != 0)
					linsert(1, *strp++);
				lnewline();

				cpos = 0;	/* and clear the line */
			}
			++ktp;
		}

		/* if no key was bound, we need to dump it anyway */
		if (cpos > 0) {
			outseq[cpos] = 0;
			strp = &outseq[0];
			while (*strp != 0)
				linsert(1, *strp++);
			lnewline();
		}

		/* and on to the next name */
		++nptr;
	}

	curwp->w_bufp->b_mode |= MDVIEW;/* put this buffer view mode */
	curbp->b_flag &= ~BFCHG;	/* don't flag this as a change */
	wp->w_dotp = lforw(bp->b_linep);/* back to the begining */
	wp->w_doto = 0;
	wp = wheadp;			/* and update ALL mode lines */
	while (wp != NULL) {
		wp->w_flag |= WFMODE;
		wp = wp->w_wndp;
	}
	mlwrite("");	/* clear the mode line */
	return(TRUE);
}

getckey(mflag)	/* get a command key sequence from the keyboard	*/

int mflag;	/* going for a meta sequence? */

{
	register int c;		/* character fetched */
	register char *tp;	/* pointer into the token */
	char tok[NSTRING];	/* command incoming */

	/* check to see if we are executing a command line */
	if (clexec) {
		nxtarg(tok);	/* get the next token */

		/* parse it up */
		tp = &tok[0];
		c = 0;

		/* first, the META prefix */
		if (*tp == 'M' && *(tp+1) == '-') {
			c = META;
			tp += 2;
		} else

			/* next the function prefix */
			if (*tp == 'F' && *(tp+1) == 'N') {
				c |= SPEC;
				tp += 2;
			} else

				/* control-x as well... */
				if (*tp == '^' && *(tp+1) == 'X') {
					c |= CTLX;
					tp += 2;
				}

		/* a control char? */
		if (*tp == '^' & *(tp+1) != 0) {
			c |= CTRL;
			++tp;
		}

		/* make sure we are not lower case */
		if (c >= 'a' && c <= 'z')
			c -= 32;

		/* the final sequence... */
		c |= *tp;

		return(c);
	}

	/* or the normal way */
	if (mflag)
		c = get1key();
	else
		c = getcmd();
	return(c);
}

/* execute the startup file */

startup(sfname)

char *sfname;	/* name of startup file (null if default) */

{
	register int status;	/* status of I/O operations */
	register int i;		/* index into help file names */
	char fname[NSTRING];	/* buffer to construct file name in */
	char *sfroot;		/* root of startup file name */

#if	(MSDOS & (LATTICE | AZTEC | MSC)) | V7 | USG | BSD | OFW
	char *getenv();
	char *homedir;		/* pointer to your home directory */
#endif

	if (sfname[0] == 0)
		sfroot = pathname[0];
	else
		sfroot = sfname;

#if	(MSDOS & (LATTICE | AZTEC | MSC)) | V7 | USG | BSD | OFW
	/* get the HOME from the environment */
#if OFW
	if ((homedir = getenv("HOME")     ) != NULL
	 || (homedir = getenv("EMACSHOME")) != NULL
	 || (homedir = gethomedir()       ) != NULL) {
#else
	if ((homedir = getenv("HOME")     ) != NULL
	 || (homedir = getenv("EMACSHOME")) != NULL) {
#endif
		/* build the file name */
		strcpy(fname, homedir);
#if ! OFW
		if ( *homedir
		    && homedir[strlen(homedir)-1] != '/'
		    && homedir[strlen(homedir)-1] != '\\'
		    )
			strcat(fname, "/");
#endif
		strcat(fname, sfroot);

		/* and test it */
		status = ffropen(fname);
		if (status == FIOSUC) {
			ffclose();
			return(dofile(fname));
		}
	}
#endif

	/* search through the list of startup files */
	for (i=2; i < NPNAMES; i++) {
		strcpy(fname, pathname[i]);
		strcat(fname, sfroot);
		status = ffropen(fname);
		if (status == FIOSUC)
			break;
	}

	/* if it isn't around, don't sweat it */
	if (status == FIOFNF)
		return(TRUE);

	ffclose();	/* close the file to prepare to read it in */

	return(dofile(fname));
}

