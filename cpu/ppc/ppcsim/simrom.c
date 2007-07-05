// See license at end of file
/*
 * Main routine for calling the PowerPC simulator to simulate ROM images
 */

extern void simulate();
extern char *malloc();

char *loadaddr;

#define MEMSIZE 0x800000

main()
{
	int f;
	if((f = open("fw.img", 0)) < 0) {
		perror("can't open fw.img");
		exit(1);
	}
	loadaddr = malloc(MEMSIZE);
	(void) read(f, loadaddr, MEMSIZE);
	close(f);
	simulate(loadaddr, 0x100, 0, 0, 0, 0, 0, 1 /* 0=POWER, 1=PowerPC */);
	exit(0);
}
int
c_key()
{
	int i;
	if ((i = getchar()) == -1)
		exit (0);
	return (i);
}
void
s_bye()
{
	exit(0);
}

// LICENSE_BEGIN
// Copyright (c) 2007 FirmWorks
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
