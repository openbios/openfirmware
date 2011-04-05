# Makefile for native PowerPC wrapper to run under Linux

OPT = -O
# OPT =

BP=../../..

CFLAGS = -D__linux__ -DHOSTPOWERPC -DTARGET_POWERPC

CC = gcc

WRDIR = ${BP}/forth/wrapper
ZIPDIR = ${WRDIR}/zip

ZIPOBJS = adler32.o compress.o crc32.o deflate.o inflate.o trees.o zutil.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: ppcforth

ppcforth: forth
	ln -sf $< $@

forth: $(OBJS)
	$(CC) $(LFLAGS)  $(OBJS)  -o $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f *.o forth ppcforth

FRC:
