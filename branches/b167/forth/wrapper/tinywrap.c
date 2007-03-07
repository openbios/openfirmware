// See license at end of file

/* Tiny Wrapper */

/*
 * Dynamic loader for Forth.  This program reads in a binary image of
 * a Forth system and executes it.  It connects standard input to the
 * Forth input stream (key and expect) and puts the Forth output stream
 * (emit and type) on standard output.
 *
 * An array of entry points for system calls is provided to the Forth
 * system, so that Forth doesn't have to know the details of how to
 * invoke system calls.
 *
 * Synopsis:
 *
 * forth [ <forth-binary>.exe ]
 *
 * <forth-binary> is the name of the ".dic" file containing the forth binary
 * image.  The binary image is in a system-independent format, which contains
 * a header, the relocatable program image, and a relocation bitmap.
 *
 */

#include <stdio.h>
#include <string.h>

#define DICT_SIZE  (1024*1024L)		/* Dictionary size */
char loadaddr[DICT_SIZE];

#define CPU_MAGIC 0x464f4657
#define START_OFFSET 8

typedef long quadlet;

long	f_crstr();
long	c_key();
long	s_bye();
long	c_emit();
long	c_keyques();
long	c_cr();
long	fileques();
long	c_expect();
long	c_type();
long	m_alloc();
long	m_free();

long
nop()
{
	return(0L);
}

long ( (*functions[])()) = {
/*	0	4	*/
	c_key,	c_emit,

/*	8	12	16	20	24	28	32 */
	nop,	nop,	nop,	nop,	nop,	nop,	c_keyques,

/*	36	40	44		48		*/
        s_bye,	nop,	nop,	fileques,

/*	52	56		60	*/
	c_type,	c_expect,	nop,

/*	64	68	72	*/
	nop,	nop,	nop,

/*	76	80	*/
	nop,	nop,

/*	84	*/
	nop,

/*	88		92	*/
	nop,		nop,

/*	96		100	*/
	nop,		nop,

/*	104		108		112	*/
	m_alloc,	c_cr,		f_crstr,

/*	116		120		124	*/
	nop,		nop,		nop,

/*	128	*/
	m_free,

/*	132	136	140	144	148 */
	nop,	nop,	nop,	nop,	nop,

/*	152 */
	nop,

/*	156 */
	nop,

/*	160	164	168	172	*/
	nop,	nop,	nop,	nop,

/*	176	*/
	nop,

/*	180  */
	nop,

/*	184  */
	nop,

/*	188  */
	nop,
/*	192  		196 */
	nop,		nop,
/*	200  */
	nop,
};
/*
 * Function semantics:
 *
 * Functions which are the names of Unix system calls have the semantics
 * of those Unix system calls.
 *
 * char c_key();				Gets next input character
 *	no echo or editing, don't wait for a newline.
 * c_emit(char c);				Outputs the character.
 * long c_keyques();				True if a keystroke is pending.
 *	If you can't implement this, return false.
 * s_bye(long status);				Cleans up and exits.
 * long fileques();				True if input stream has been
 *	redirected away from a keyboard.
 * long c_type(long len, char *addr);		Outputs len characters.
 * long c_expect(long max, char *buffer);	Reads an edited line of input.
 * long c_cr();					Advances to next line.
 */

void exit();
void error();

struct {
	quadlet h_magic;  quadlet h_tlen;
	quadlet h_dlen;   quadlet h_blen;
	quadlet h_slen;   quadlet h_entry;
	quadlet h_trlen;  quadlet h_drlen;
} header;

int
main(argc, argv)
	int argc;
	char **argv;
{
	long f;

	/* Open file for reading */
	if( (f = open(argv[1], 0, 0)) < 0L ) {
		error("forth: Can't open dictionary file","");
		exit(1);
	}

	/*
	 * Read the dictionary file into memory.
	 */
	if( read(f, loadaddr, DICT_SIZE) < 0 ) {
		error("forth: Can't read dictionary file","");
		exit(1);
	}

        /* Copy the header into its structure buffer */
        { char *p, *q; int len = sizeof(header);
	  for (p = loadaddr, q = (char *)&header; len; --len)
     	      *q++ = *p++;
        }

	if (header.h_magic != CPU_MAGIC) {
		error("forth: Incorrect dictionary file header", "");
		exit(1);
	}

	close(f);

	/*
	 * Call the Forth interpreter as a subroutine.  If it returns,
	 * exit with its return value as the status code.
	 */
	simulate(0L, loadaddr+sizeof(header)+START_OFFSET,
		 loadaddr, functions, (long)loadaddr+DICT_SIZE,
		 0, 0, 0);
}

/*
 * Returns true if a key has been typed on the keyboard since the last
 * call to c_key().
 */
long
c_keyques()
{
	return(0L);
}

/*
 * Get the next character from the input stream.
 */

long
c_key()
{
	register int c;

	fflush(stdout);
	if ((c = getc(stdin)) != EOF)
		return(c);
	
	s_bye(0L);
	return(0);  /* To avoid compiler warnings */
}

/*
 * Send the character c to the output stream.
 */
long
c_emit(c)
	long c;
{
	putchar((int)c);
	fflush(stdout);
}

/*
 * This routine is called by the Forth system to determine whether
 * its input stream is connected to a file or to a terminal.
 * It uses this information to decide whether or not to
 * prompt at the beginning of a line.  If you are running in an environment
 * where input cannot be redirected away from the terminal, just return 0L.
 */
long
fileques()
{
	return((long)0);
}

/*
 * Get an edited line of input from the keyboard, placing it at buffer.
 * At most "max" characters will be placed in the buffer.
 * The line terminator character is not stored in the buffer.
 */
long
c_expect(max, buffer)
	register long max;
	char * buffer;
{
	register int c = 0;
	register char *p = buffer;

	fflush(stdout);

	while (max--  &&  (c = getc(stdin)) != '\n'  &&  c != EOF )
		*p++ = c;

	return ( (long)(p - buffer) );
}

/*
 * Send len characters from the buffer at addr to the output stream.
 */
long
c_type(len, addr)
	long len;
	register char * addr;
{
	while(len--)
		putchar(*addr++);
}

/*
 * Sends an end-of-line sequence to the output stream.
 */
long
c_cr()
{
	putchar('\n');
}

/*
 * Returns the end-of-line sequence that is used within files as
 * a packed (leading count byte) string.
 */
long
f_crstr()
{
	return((long)"\1\n");
}

long
s_bye(code)
	long code;
{
	fflush(stdout);
	exit((int)code);
}

/*
 * Display the two strings, followed by an newline, on the error output
 * stream.
 */
void
error(str1,str2)
	char *str1, *str2;
{
	write(2,str1,strlen(str1));
	write(2,str2,strlen(str2));
	write(2,"\n",1);
}

long
m_alloc(size)
	long size;
{
	char *mem;

	size = (size+7) & ~7;

/* XXX is this needed? */
size += 0x80;
	mem = (char *)malloc((size_t)size);

	if (mem != NULL)
		memset(mem, '\0', size);

	return((long)mem);
}

/* ARGSUSED */
long
m_free(size, adr)
	long size;
	char *adr;
{
	free(adr);
}

// LICENSE_BEGIN
// Copyright (c) 2006 FirmWorks
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END
