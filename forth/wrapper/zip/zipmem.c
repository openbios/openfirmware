/* gzip (GNU zip) -- compress files with zip algorithm and 'compress' interface
 * Copyright (C) 1992-1993 Jean-loup Gailly
 *
 * See the license_msg below and the file COPYING for the software license.
 * See the file algorithm.doc for the compression algorithms and file formats.
 */

#ifdef notdef
static char  *license_msg[] = {
"   Copyright (C) 1992-1993 Jean-loup Gailly",
"   This program is free software; you can redistribute it and/or modify",
"   it under the terms of the GNU General Public License as published by",
"   the Free Software Foundation; either version 2, or (at your option)",
"   any later version.",
"",
"   This program is distributed in the hope that it will be useful,",
"   but WITHOUT ANY WARRANTY; without even the implied warranty of",
"   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the",
"   GNU General Public License for more details.",
"",
"   You should have received a copy of the GNU General Public License",
"   along with this program; if not, write to the Free Software",
"   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.",
0};
#endif

/* Subroutine to compress memory to memory with zip algorithm
 */

/* Derived from:
 * "$Id: zipmem.c,v 1.2 1997/05/15 01:48:46 wmb Exp $";
 * "$Id: zipmem.c,v 1.2 1997/05/15 01:48:46 wmb Exp $";
 * by removing everything having to do with file operations,
 * non-zip compression methods, decompression, and options.
 */

#include <sys/types.h>

#include "tailor.h"
#include "gzip.h"
#define BITS 16		/* This is the only thing from lzw.h */
#include <setjmp.h>

		/* global buffers */

DECLARE(uch, inbuf,  INBUFSIZ +INBUF_EXTRA);
DECLARE(uch, outbuf, OUTBUFSIZ+OUTBUF_EXTRA);
DECLARE(ush, d_buf,  DIST_BUFSIZE);
DECLARE(uch, window, 2L*WSIZE);
DECLARE(ush, tab_prefix, 1L<<BITS);

		/* local variables */

int method = DEFLATED;/* compression method */
int level = 6;        /* compression level */

long bytes_in;             /* number of input bytes */
long bytes_out;            /* number of output bytes */
unsigned insize;           /* valid bytes in inbuf */
unsigned inptr;            /* index of next byte to be processed in inbuf */
unsigned outcnt;           /* bytes in output buffer */

/* local functions */

local void treat_stdin  OF((void));
local void do_exit      OF((int exitcode));
      int zip_memory    OF((void *inbuf,  int insize,
			    void *outbuf, int outsize));
      int simple_zip OF((void));

local int read_mem	OF((int fd, void *buf, size_t size));

char *in_buf, *in_ptr, *in_end;
char *out_buf, *out_ptr, *out_end;

jmp_buf env;

/* ======================================================================== */
int zip_memory (extinbuf, extinsize, extoutbuf, extoutsize)
    void *extinbuf;
    int extinsize;
    void *extoutbuf;
    int extoutsize;
{
    /* Set the variables that the low-level read/write substitutes use */
    in_ptr = in_buf = extinbuf;
    in_end = in_buf + extinsize;
    out_ptr = out_buf = extoutbuf;
    out_end = out_buf + extoutsize;

    /* Allocate all global buffers (for DYN_ALLOC option) */
    ALLOC(uch, inbuf,  INBUFSIZ +INBUF_EXTRA);
    ALLOC(uch, outbuf, OUTBUFSIZ+OUTBUF_EXTRA);
    ALLOC(ush, d_buf,  DIST_BUFSIZE);
    ALLOC(uch, window, 2L*WSIZE);
    ALLOC(ush, tab_prefix, 1L<<BITS);

    clear_bufs(); /* clear input and output buffers */

    if (setjmp(env)) {
	    bytes_out = 0;
    } else {
	    /* Perform the compression. */
	    if (simple_zip() != OK)
		    bytes_out = 0;
    }

    FREE(inbuf);
    FREE(outbuf);
    FREE(d_buf);
    FREE(window);
    FREE(tab_prefix);

    return(bytes_out);
}

/* ========================================================================
 * Signal and error handler.
 */
void abort_gzip()
{
   longjmp(env, 1);
}

local ulg crc;       /* crc on uncompressed file data */
long header_bytes;   /* number of bytes in gzip header */

/* ===========================================================================
 * Deflate in to out.
 * IN assertions: the input and output buffers are cleared.
 */
int simple_zip()
{
    uch  flags = 0;         /* general purpose bit flags */
    ush  attr = 0;          /* ascii/binary flag */
    ush  deflate_flags = 0; /* pkzip -es, -en or -ex equivalent */

    outcnt = 0;

    /* Write the header to the gzip file. See algorithm.doc for the format */

    method = DEFLATED;
    put_byte(GZIP_MAGIC[0]); /* magic header */
    put_byte(GZIP_MAGIC[1]);
    put_byte(DEFLATED);      /* compression method */

    put_byte(flags);         /* general flags */
    put_long(0);	     /* timestamp */

    /* Write deflated file to zip file */
    crc = updcrc((uch *)0, 0);

    bi_init(1);
    ct_init(&attr, &method);
    lm_init(level, &deflate_flags);

    put_byte((uch)deflate_flags); /* extra flags */
    put_byte(3);                  /* OS identifier for Unix */

    /* The file name would go here if we were including it */

    header_bytes = (long)outcnt;

    (void)deflate();

    /* Write the crc and uncompressed size */
    put_long(crc);
    put_long(isize);
    header_bytes += 2*sizeof(long);

    flush_outbuf();
    return OK;
}

/* ===========================================================================
 * Read a new buffer from the current input file, perform end-of-line
 * translation, and update the crc and input file size.
 * IN assertion: size >= 2 (for end-of-line translation)
 */
int file_read(buf, size)
    char *buf;
    unsigned size;
{
    unsigned len;

    Assert(insize == 0, "inbuf not empty");

    len = read_mem(0, (void *)buf, size);
    if (len == (unsigned)(-1) || len == 0) return (int)len;

    crc = updcrc((uch*)buf, len);
    isize += (ulg)len;
    return (int)len;
}

int read_mem(fd, buf, size)
	int fd;
	void *buf;
	size_t size;
{
	if (size > in_end - in_ptr)
		size = in_end - in_ptr;
	(void)memcpy(buf, in_ptr, size);
	in_ptr += size;
	return(size);
}

int write_mem(fd, buf, size)
	int fd;
	const void *buf;
	size_t size;
{
	if (out_ptr + size > out_end)
		return(-1);
	(void)memcpy(out_buf, buf, size);
	out_buf += size;
	return(size);
}
