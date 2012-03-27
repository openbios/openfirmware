/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"

void
memcpy(void *to, void *from, size_t len)
{
    while (len-- > 0)
        *(UCHAR *)to++ = *(UCHAR *)from++;
}

void
memset(void *cp, int c, size_t len)
{
    while (len-- > 0)
	*((UCHAR *)cp + len) = c;
}

int
memcmp(const void *s1, const void *s2, size_t n)
{
	int diff;
	while (n-- > 0) {
		diff = *(UCHAR *)s1++ - *(UCHAR *)s2++;
		if (diff)
			return (diff < 0) ? -1 : 1;
	}
	return 0;
}
