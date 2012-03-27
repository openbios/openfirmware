# This makefile has been tested on OS X 10.6 with GCC

CC=gcc
#CFLAGS=-g -m32 -fno-builtin -fno-stack-limit -fno-stack-protector
CFLAGS=-g -m32 -nostdlib -nostartfiles -fno-builtin -ffreestanding -fno-stack-protector -I..
LFLAGS=-L.

#all: libobp.a hello hello.elf start.o
all: libobp.a hello start.o

# Create a library file containing all the library routines

OBJS=	callofw.o \
	cellprop.o \
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

libobp.a: ${OBJS}
	ar rcv libobp.a ${OBJS}
	ranlib libobp.a

# Build machine-independent library routines

%.o: ../%.c
	${CC} ${CFLAGS} -c $<

# Build processor-specific startup code and call gateway

start.o: start.S
	${CC} ${CFLAGS} -c start.S

# Hello is a demo program that uses the stdio library

#hello.elf: libobp.a start.o hello.o
#	ld -melf_i386 -Bstatic -N -Ttext 0x100000 -o $@ start.o hello.o libobp.a -lc
#	cp hello.elf hello.syms
#	strip hello.elf

hello.o: ../../hello/hello.c
	${CC} ${CFLAGS} -c ../../hello/hello.c

hello: start.o hello.o libobp.a
	${CC} ${CFLAGS} ${LFLAGS} start.o hello.o -o $@ -lobp

# Binary to ELF converter program

bintoelf: ../bintoelf.c
	${CC} -o bintoelf ../bintoelf.c


clean:
	rm -f *~ *.o hello* *.a


dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/x86/*.s lib/x86/makefile hello)
