# This makefile has been tested on an MkLinux system with GCC

# -fno-builtin has the effect of suppressing some warnings about
# functions that conflict with gcc builtins

ifneq (arm, $(findstring arm,$(shell uname -p)))
ifeq ($(CROSS),)
    CROSS=/usr/local/arm/arm-linux/bin/
endif
  CC    := $(CROSS)gcc
  LD    := $(CROSS)ld
else
  CC    := gcc
endif

CFLAGS = -I.. -O2 -mcpu=strongarm110 -fno-builtin
ifeq (y, $(shell $(CC) -xc -c -fno-stack-protector /dev/null -o /dev/null 2>/dev/null && echo y))
  CFLAGS += -fno-stack-protector
endif

# DEVELOPER = $(shell xcode-select -print-path)
# SDK = $(shell xcodebuild -showsdks | grep iphoneos | head -1 | sed 's/.*-sdk //')
# CC = xcrun -sdk ${SDK} gcc
# 
# Rationale for these flags:
# -Oz optimizes for smallest possible size. (Apple-specific)
# -fno-toplevel-reorder keeps inflate() as the first entry point.
# -ffreestanding means don't assume standard libraries, inlines, and builtins
# -thumb gives 30%-50% improvement over ARM32. 
# -arch armv7 uses more powerful instructions for less space.
# -static -nostartfiles allows us to link this as a static text image.
# CFLAGS = -I.. -Oz -arch armv7 -mthumb -static -nostartfiles \
# 	-I$(DEVELOPER)/Platforms/iPhoneOS.platform/Developer/SDKs/$(SDK).sdk/usr/include \
#          -fno-toplevel-reorder -ffreestanding
# 
LIBOBJS = cellprop.o \
	  debug.o \
	  intprop.o \
	  lib.o \
	  malloc.o \
	  mem.o \
	  printf.o \
	  regprop.o \
	  strings.o \
	  strprop.o \
	  wrappers.o

all: libobp.a hello start.o

libobp.a: ${LIBOBJS}
	ar rcv libobp.a ${LIBOBJS}
	ranlib libobp.a

# Build machine-independent library routines

%.o: ../%.c
	${CC} ${CFLAGS} -c $<

# Build processor-specific startup code and call gateway

start.o: start.c
	${CC} ${CFLAGS} -c start.c

# start.o: start.s
# 	${CC} ${CFLAGS} -c start.s

# Hello is a demo program that uses the stdio library

hello: libobp.a start.o hello.o
	${CC} ${CFLAGS} -e _start -o hello start.o hello.o -L. -lobp

hello.o: ../../hello/hello.c
	${CC} ${CFLAGS} -c ../../hello/hello.c

clean:
	rm -f *~ *.o hello* *.a

dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/ppcgcc/*.c lib/ppcgcc/*.lds lib/ppcgcc/makefile hello)
