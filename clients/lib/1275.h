// See license at end of file

#include "types.h"

typedef long phandle;
typedef long ihandle;

typedef struct {
	long hi, lo;
	long size;
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

#ifdef SPRO
typedef long long cell_t;
#else
typedef unsigned long cell_t ;
#endif

#ifdef CIF64
#define LOW(index) ((index*2) + 1)
#else
#define LOW(index) (index)
#endif

extern int call_firmware(ULONG *);
extern void warn(char *fmt, ...);

#ifdef CIF64
#define CIF_HANDLER_IN 6
#else
#define CIF_HANDLER_IN 3
#endif

extern int call_firmware(ULONG *);
extern void warn(char *fmt, ...);
int atoi(const char *s);

void OFClose(ihandle id);
phandle OFPeer(phandle device_id);
phandle OFChild(phandle device_id);
phandle OFParent(phandle device_id);
long OFGetproplen(phandle device_id, char *name);
long OFGetprop(phandle device_id, char *name, char *buf, ULONG buflen);
long OFNextprop(phandle device_id, char *name, char *buf);
long OFSetprop(phandle device_id, char *name, char *buf, ULONG buflen);
phandle OFFinddevice(char *devicename);
ihandle OFOpen(char *devicename);
ihandle OFCreate(char *devicename);
void OFClose(ihandle id);
long OFRead(ihandle instance_id, char *addr, ULONG len);
long OFWrite(ihandle instance_id, char *addr, ULONG len);
long OFSeek(ihandle instance_id, ULONG poshi, ULONG poslo);
ULONG OFClaim(char *addr, ULONG size, ULONG align);
VOID OFRelease(char *addr, ULONG size);
long OFPackageToPath(phandle device_id, char *addr, ULONG buflen);
phandle OFInstanceToPackage(ihandle ih);
long OFCallMethod(char *method, ihandle id, ULONG arg);
long OFInterpret0(char *cmd);
ULONG OFMilliseconds(VOID);
void (*OFSetCallback(void (*func)(void)))(void);
long OFBoot(char *bootspec);
VOID OFEnter(VOID);
VOID OFExit(VOID);
long OFCallMethodV(char *method, ihandle id, int nargs, int nrets, ...);
long OFInterpretV(char *cmd, int nargs, int nrets, ...);

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
