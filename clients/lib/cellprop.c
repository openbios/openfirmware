// See license at end of file

/* For gcc, compile with -fno-builtin to suppress warnings */

#include "1275.h"

cell_t
decode_cell(UCHAR *p)
{
	int i;
	cell_t res = 0;

	for (i = 0; i < sizeof(cell_t); i++)
	    res = (res << 8) + p[i];
	return res;
}

cell_t
get_cell_prop(phandle node, char *key)
{
	cell_t res;
	UCHAR buf[sizeof(cell_t)];

	res = OFGetprop(node, key, buf, sizeof(cell_t));
	if (res != sizeof(cell_t)) {
		return(-1);
	}
	return(decode_cell((UCHAR *) buf));
}

cell_t
get_cell_prop_def(phandle node, char *key, cell_t defval)
{
	cell_t res;
	UCHAR buf[sizeof(cell_t)];

	res = OFGetprop(node, key, buf, sizeof(cell_t));
	if (res != sizeof(cell_t)) {
		return(defval);
	}
	return(decode_cell((UCHAR *) buf));
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
