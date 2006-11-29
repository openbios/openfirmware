# Wrapper makefile for x86 Unix: FreeBSD, Linux, etc.
# Copyright 1997 FirmWorks. All rights reserved.
#
OS := $(shell uname)

BP=../../..

CFLAGS	= -O -g -DUNIX -D${OS} -DX86

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth x86forth ../build/inflate.bin

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: ${OBJS}
	${CC} -o $@ ${OBJS}
	@ln -sf forth x86forth

# Compile with -O0 because with GCC4, higher optimization levels cause the
# functions to be reordered so the "inflate" entry point is no longer at
# the beginning.
inflate.o: ${ZIPDIR}/inflate.c
	${CC} -c -O0 -fpic $< -o $@

../build/inflate.bin: inflate.o
	objcopy -O binary $< $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f forth x86forth *.o *~ inflate.bin
