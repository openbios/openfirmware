/*
 * The functions in this file negotiate with the operating system for
 * characters, and write characters in a barely buffered fashion on the display.
 * All operating systems.
 */

#include	"estruct.h"
#include        "edef.h"
#include	"stdio.h"

/*
 * This function is called once to set up the terminal device streams.
 */
ttopen()
{
	/* on all screens we are not sure of the initial position
	   of the cursor					*/
	ttrow = 999;
	ttcol = 999;
}

/*
 * This function gets called just before we go back home to the command
 * interpreter. It can be used to put the terminal back in a reasonable state.
 */
ttclose()
{
}

/*
 * Write a character to the display.
 */
ttputc(c)
        char c;
{
        fputc(c, stdout);
}

/*
 * Flush terminal buffer. Does real work where the terminal output is buffered
 * up. A no-operation on systems where byte at a time terminal I/O is done.
 */
ttflush()
{
        fflush(stdout);
}

/*
 * Read a character from the terminal, performing no editing and doing no echo
 * at all.
 */
ttgetc()
{
        return(fgetc(stdin));
}

#if	TYPEAH
/* typahead:	Check to see if any characters are already in the
		keyboard buffer
*/

typahead()
{
	return(FALSE);
}
#endif

