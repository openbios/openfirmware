/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"

VOID
memcpy(char *to, char *from, int len)
{
	while (len--)
		*to++ = *from++;
}

VOID
memset(char *cp, int c, int len)
{
	while (len--)
		*(cp + len) = c;
}

int
memcmp(void *s1, void *s2, int len)
{
	for (; len--; ++s1, ++s2)
		if (*(unsigned char *)s1 != *(unsigned char *)s2)
			return *(unsigned char *)s1 - *(unsigned char *)s2;
	return 0;
}
