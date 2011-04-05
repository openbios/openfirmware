# Wrapper makefile for Unix: FreeBSD, Linux, etc.
# Copyright 1997 FirmWorks. All rights reserved.
#
CC      = mipsel-linux-gnu-gcc-4.3

CFLAGS  = -O -g -D__linux__ -DMIPS -DHOSTMIPS
LFLAGS  = -Xlinker -static -static-libgcc

WRDIR = ${BP}/forth/wrapper
ZIPDIR = ${WRDIR}/zip

ZIPOBJS = adler32.o compress.o crc32.o deflate.o inflate.o trees.o zutil.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth

wrapper.o: ${BP}/forth/wrapper/wrapper.c
        ${CC} ${CFLAGS} -c ${BP}/forth/wrapper/wrapper.c

%.o: ${WRDIR}/%.c
        ${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
        ${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

forth: ${OBJS}
        ${CC} $(LFLAGS) -o $@ ${OBJS}

clean:
        @rm -f forth *.o

install: forth
        cp forth ${BP}/bin/mips/`uname|tr A-Z a-z`/forth
        cp forth ${BP}/bin/mips/`uname|tr A-Z a-z`/mipsfth

dist:
        (cd ${BP}; zip /tmp/wrapper.zip os/unix/mips/makefile ${SRCS})
