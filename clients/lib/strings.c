// See license at end of file

/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"
#include "string.h"

int
strcmp(const char *s, const char *t)
{
	int diff = 0;
	int i;

	for (i = 0; 1; ++i) {
		diff = s[i] - t[i];
		if (diff || s[i] == '\0')
			break;
	}
	return(diff);
}

int
strncmp(const char *s, const char *t, size_t len)
{
	int diff = 0;
	int i;

	for (i = 0; i != len; ++i) {
		diff = s[i] - t[i];
		if (diff || s[i] == '\0')
			break;
	}

	return(diff);
}

int
strcasecmp(const char *s, const char *t)
{
	char sc, tc;
	int diff = 0;
	int i;

	for (i = 0; 1; i++) {
		sc = s[i];
		tc = t[i];
		if (ISUPPER(sc))
			sc = TOLOWER(sc);
		if (ISUPPER(tc))
			tc = TOLOWER(tc);
		diff = sc - tc;
		if (diff || sc == '\0')
			break;
	}
	return diff;
}

int
strncasecmp(const char *s, const char *t, size_t len)
{
	char sc, tc;
	int diff = 0;
	int i;

	for (i=0; i < len; i++) {
		sc = s[i];
		if (ISUPPER(sc))
			sc = TOLOWER(sc);
		tc = t[i];
		if (ISUPPER(tc))
			tc = TOLOWER(tc);
		diff = sc - tc;
		if (diff || sc == '\0')
			break;
	}
	return diff;
}

int
strlen(const char *s)
{
	int i;

	for (i = 0; s[i] != '\0'; ++i)
		;
	return i;
}

int
strnlen(const char *s, size_t maxlen)
{
	int i;

	for (i = 0; i < maxlen && s[i] != '\0'; ++i)
		;
	return i;
}

char *
strcpy(char *to, const char *from)
{
	int i = 0;

	while ((to[i] = from[i]))
		i += 1;
	return to;
}

char *
strncpy(char *to, const char *from, size_t maxlen)
{
	int i = 0;

	while ((maxlen != 0) && (to[i] = from[i]))
	{
	   i += 1;
	   maxlen--;
	}
	return to;
}

char *
strcat(char *to, const char *from)
{
	char *ret = to;

	while (*to)
		to += 1;
	strcpy(to, from);
	return ret;
}

char *
strchr(char *s, int c)
{
	while (*s) {
		if (*s == c)
			return s;
		++s;
	}
	return (char *) 0;
}

char *
strctok(char *s, const char sep)
{
	static char *saved_str = NULL;
	char *temp;

	if (s != NULL)
		saved_str = s;
	if (saved_str == NULL)
		return(NULL);
	s = strchr(saved_str, sep);
	if (s != NULL) {
		*s++ = '\0';
		while (*s && (*s == sep))
			++s;
	}
	temp = saved_str;
	saved_str = s;
	return temp;
}

char *
strstr(const char *haystack, const char *needle)
{
	int len = strlen(needle);
	char *s;

	for (s = (char *)haystack; *s; s++)
		if (strncmp(s, needle, len) == 0)
			return s;

	return NULL;
}

char *
strcasestr(const char *haystack, const char *needle)
{
	int len = strlen(needle);
	char *s;

	for (s = (char *)haystack; *s; s++)
		if (strncasecmp(s, needle, len) == 0)
			return s;

	return NULL;
}

void *memchr(const void *s, int c, size_t len)
{
	const unsigned char *p = s;
	while (len--) {
		if (*p == (unsigned char)c)
			return p;
		p++;
	}
	return NULL;
}

int toupper(int c)
{
	return (c >= 'a' && c <= 'z') ? (c - 'a' + 'A') : c;
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
