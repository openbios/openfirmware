# Wrapper makefile for ARM Linux
# Copyright 2008 FirmWorks. All rights reserved.
#
BP=../../..

CFLAGS = -DARM -mlittle-endian

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: armforth
	@ln -sf armforth forth

armforth: ${OBJS}
	${CC} ${CFLAGS} ${LFLAGS} -o $@  ${OBJS}

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f ${OBJS} forth armforth
