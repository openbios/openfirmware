// See license at end of file

/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"

void *
zalloc(size_t size)
{
	void *vp;

	vp = malloc(size);
	memset(vp, size, 0);
	return (vp);
}

char *
get_str_prop(phandle node, const char *key, allocflag alloc)
{
	ULONG len;
	int res;
	static char *priv_buf;
	static ULONG priv_buf_len = 0;
	char *cp;

	len = OFGetproplen(node, key);
	/*
	 * Properly encoded properties have a null terminator,
	 * so if len == 1 we have a null string.
	 */
	if (len == -1 || len == 0 || len == 1) {
		return((char *) 0);
	}

	if (alloc == ALLOC)
		cp = (char *) zalloc(len);
	else {
		if (len > priv_buf_len) {
			if (priv_buf_len)
				free(priv_buf);
			priv_buf = (char *) zalloc(len);
			priv_buf_len = len;
		} else
			memset((void *)priv_buf, len, 0);
		cp = priv_buf;
	}

	res = OFGetprop(node, key, (UCHAR *)cp, len);
	if (res != len) {
		fatal(
		    "get_str_prop(node %x, key '%s', len %x) returned len %x\n",
		    node, key, len, res);
		return((char *) 0);
	}
	return(cp);
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
