// See license at end of file

// -----------------------------------------------------------------
// Type definitions and miscellaneous data structures

#ifndef __1275_h__
#define __1275_h__

#define NULL   0

typedef unsigned char UCHAR;
typedef unsigned long ULONG;

typedef ULONG cell_t ;
typedef ULONG phandle;
typedef ULONG ihandle;

typedef struct {
	ULONG hi, lo;
	ULONG size;
} reg;

#ifdef	putchar
# undef	putchar
#endif
#ifdef	puts
# undef	puts
#endif

typedef enum {
	NOALLOC,
	ALLOC
} allocflag;

#define	new(t)	(t *)zalloc(sizeof(t));

#define LOW(index) (index)

// -----------------------------------------------------------------
// External C library functions, and the like.

#include <stdlib.h>

extern int   decode_int(UCHAR *);
extern void  fatal(char *fmt, ...);
extern cell_t get_cell_prop(phandle, char *);
extern cell_t get_cell_prop_def(phandle, char *, cell_t);
extern int   get_int_prop(phandle, char *);
extern int   get_int_prop_def(phandle, char *, int);
extern char *get_str_prop(phandle, const char *, allocflag);
extern int   printf(char *fmt, ...);
extern int   putchar(int);
extern void  warn(char *fmt, ...);
extern void *zalloc(size_t);

// -----------------------------------------------------------------
// Open Firmware client interface calls.

#define CIF_HANDLER_IN 3
extern int call_firmware(ULONG *);

void OFClose(ihandle id);
phandle OFPeer(phandle device_id);
phandle OFChild(phandle device_id);
phandle OFParent(phandle device_id);
long OFGetproplen(phandle device_id, const char *name);
long OFGetprop(phandle device_id, const char *name, UCHAR *buf, ULONG buflen);
long OFNextprop(phandle device_id, const char *name, UCHAR *buf);
long OFSetprop(phandle device_id, const char *name, UCHAR *buf, ULONG buflen);
phandle OFFinddevice(char *devicename);
ihandle OFOpen(char *devicename);
ihandle OFCreate(char *devicename);
void OFClose(ihandle id);
long OFRead(ihandle instance_id, UCHAR *addr, ULONG len);
long OFWrite(ihandle instance_id, UCHAR *addr, ULONG len);
long OFSeek(ihandle instance_id, ULONG poshi, ULONG poslo);
ULONG OFClaim(UCHAR *addr, ULONG size, ULONG align);
void OFRelease(UCHAR *addr, ULONG size);
long OFPackageToPath(phandle device_id, UCHAR *addr, ULONG buflen);
phandle OFInstanceToPackage(ihandle ih);
long OFCallMethod(char *method, ihandle id, ULONG arg);
long OFInterpret0(const char *cmd);
ULONG OFMilliseconds(void);
void (*OFSetCallback(void (*func)(void)))(void);
void OFBoot(char *bootspec);
void OFEnter(void);
#ifdef __GNUC__
void OFExit(void) __attribute__((noreturn));
#else
void OFExit(void);
#endif
long OFCallMethodV(char *method, ihandle id, int nargs, int nrets, ...);
long OFInterpretV(char *cmd, int nargs, int nrets, ...);

#endif  // __1275_h__

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

