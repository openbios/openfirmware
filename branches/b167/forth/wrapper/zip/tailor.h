/* tailor.h -- target dependent definitions
 * Copyright (C) 1992-1993 Jean-loup Gailly.
 * This is free software; you can redistribute it and/or modify it under the
 * terms of the GNU General Public License, see the file COPYING.
 */

/* Derived from:
 * $Id: tailor.h,v 1.2 1997/05/15 01:48:45 wmb Exp $
 * by removing nearly everything.
*/

#ifdef DEBUG
#undef DEBUG
#endif

#include <stdlib.h>

#define near
#define DYN_ALLOC
#define fcalloc(items,size) malloc((size_t)(items)*(size_t)(size))
#define fcfree(ptr) free(ptr)


#if defined(__MSDOS__) && !defined(MSDOS)
#  define MSDOS
#endif

#ifdef MSDOS
#  define PROTO
#  define STDC_HEADERS
#  if !defined(NO_ASM) && !defined(ASMV)
#    define ASMV
#  endif
#endif

#ifdef WIN32 /* Windows NT */
#  define PROTO
#  define STDC_HEADERS
#  include <malloc.h>
#endif

#ifdef MACOS
#  define PROTO
#endif
