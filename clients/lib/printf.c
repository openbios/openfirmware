// See license at end of file

/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"

#include <stdarg.h>

int
atoi(char *s)
{
	int temp = 0, base = 10;

	if (*s == '0') {
		++s;
		if (*s == 'x') {
			++s;
			base = 16;
		} else {
			base = 8;
		}
	}
	while (*s) {
		switch (*s) {
		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			temp = (temp * base) + (*s++ - '0');
			break;
		case 'a': case 'b': case 'c': case 'd': case 'e': case 'f':
			temp = (temp * base) + (*s++ - 'a' + 10);
			break;
		case 'A': case 'B': case 'C': case 'D': case 'E': case 'F':
			temp = (temp * base) + (*s++ - 'A' + 10);
			break;
		default:
			return (temp);
		}
	}
	return (temp);
}

STATIC int
printbase(ULONG x, int base, int fieldlen, char padchar, int upcase)
{
	static char lc_digits[] = "0123456789abcdef";
	static char uc_digits[] = "0123456789ABCDEF";
	ULONG j;
	char buf[32], *s = buf;
	int n = 0;

	memset(buf, 32, 0);

	if (base == 10 && (LONG) x < 0) {
		*s++ = '-';
		x = -x;
	}

	do {
		j = x % base;
		*s++ = upcase ? uc_digits[j] : lc_digits[j];
		x -= j;
		x /= base;
	} while (x);

cvtdone:
	for (fieldlen -= (s-buf); fieldlen > 0; --fieldlen) {
		putchar(padchar);
		n++;
	}

	for (--s; s >= buf; --s) {
		putchar(*s);
		n++;
	}

	return (n);
}

int
_printf(char *fmt, va_list args)
{
	ULONG x;
	char c, *s;
	int n = 0;
        int fieldlen;
	char padchar;

	while (c = *fmt++) {
		if (c != '%') {
			putchar(c);
			n++;
			continue;
		}
                if ((c = *fmt++) == '\0')
			goto out;
		
		if (c == '.')        // Ignore the numeric grouping flag
			if ((c = *fmt++) == '\0')
				goto out;

		padchar = ' ';
		if (c == '0') {
			padchar = c;
			if ((c = *fmt++) == '\0')
				goto out;
		}

                fieldlen = 0;
                while (c >= '0' && c <= '9') {
			fieldlen = (fieldlen * 10) + (c - '0');
			if ((c = *fmt++) == '\0')
				goto out;
		}

		switch (c) {
		case 'x':
			x = va_arg(args, ULONG);
			n += printbase(x, 16, fieldlen, padchar, 0);
			break;
		case 'X':
			x = va_arg(args, ULONG);
			n += printbase(x, 16, fieldlen, padchar, 1);
			break;
		case 'o':
			x = va_arg(args, ULONG);
			n += printbase(x, 8, fieldlen, padchar, 0);
			break;
		case 'd':
			x = va_arg(args, ULONG);
			n += printbase(x, 10, fieldlen, padchar, 0);
			break;
		case 'c':
			c = va_arg(args, int);
			putchar(c);
			n++;
			break;
		case 's':
			s = va_arg(args, char *);
			while (*s) {
				putchar(*s++);
				n++;
			}
			break;
		default:
			putchar(c);
			n++;
			break;
		}
	}
out:
	return(n);
}

int
printf(char *fmt, ...)
{
	va_list args;
	int i;

	va_start(args, fmt);
	i = _printf(fmt, args);
	va_end(args);
	return (i);
}

VOID
warn(char *fmt, ...)
{
	va_list args;

	va_start(args, fmt);
	(void)_printf(fmt, args);
	va_end(args);
}

VOID
fatal(char *fmt, ...)
{
	va_list args;

	va_start(args, fmt);
	(void)_printf(fmt, args);
	OFExit();
	va_end(args);
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
