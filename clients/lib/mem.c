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
memcmp(const void *s1, const void *s2, int n)
{
	int diff;
	while (n--) {
		diff = *(unsigned char *)s1++ - *(unsigned char *)s2++;
		if (diff)
			return (diff < 0) ? -1 : 1;
	}
	return 0;
}
