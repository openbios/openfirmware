CC=gcc
CFLAGS=-I.. -g -fno-builtin

# To build a version of the library for use on Open Firmware
# systems with a 64-bit client interface, set CELLSIZE to -DCIF64
CELLSIZE=
# CELLSIZE=-DCIF64

all: libobp.a hello start.o start64.o

# Create a library file containing all the library routines

libobp.a: lib.o printf.o wrappers.o malloc.o strings.o printf.o debug.o main.o intprop.o regprop.o strprop.o mem.o
	ar rcv libobp.a lib.o malloc.o wrappers.o strings.o printf.o debug.o main.o intprop.o regprop.o strprop.o mem.o
	ranlib libobp.a

# Build machine-independent library routines

main.o: ../main.c
	${CC} ${CFLAGS} -c ../main.c

lib.o: ../lib.c
	${CC} ${CFLAGS} -c ../lib.c

printf.o: ../printf.c
	${CC} ${CFLAGS} -c ../printf.c

debug.o: ../debug.c
	${CC} ${CFLAGS} -c ../debug.c

strings.o: ../strings.c
	${CC} ${CFLAGS} -c ../strings.c

mem.o: ../mem.c
	${CC} ${CFLAGS} -c ../mem.c

intprop.o: ../intprop.c
	${CC} ${CFLAGS} -c ../intprop.c

regprop.o: ../regprop.c
	${CC} ${CFLAGS} -c ../regprop.c

strprop.o: ../strprop.c
	${CC} ${CFLAGS} -c ../strprop.c

wrappers.o: ../wrappers.c makefile
	${CC} ${CFLAGS} ${CELLSIZE} -c ../wrappers.c

malloc.o: ../malloc.c
	${CC} ${CFLAGS} -c ../malloc.c

# Build SPARC-specific startup code and call gateway

start.o: start.s
	${CC} ${CFLAGS} -c start.s

start64.o: start64.s
	${CC} ${CFLAGS} -c start64.s

# Hello is a demo program that uses the stdio library

hello.elf: hello bintoelf makefile
	dd if=hello of=hello.img bs=32 skip=1
	bintoelf  -e 0x10000  -p 2  -b  <hello.img >hello.elf

hello: libobp.a start64.o hello.o
	ld -N -T 10000 -o hello start64.o hello.o libobp.a -lc
	cp hello hello.syms
	strip hello

hello.o: ../../hello/hello.c
	${CC} ${CFLAGS} -c ../../hello/hello.c

# Bootblk is a demo program that uses the low level direct firmware calls

bootblk.elf: bootblk bintoelf makefile
	dd if=bootblk of=bootblk.img bs=32 skip=1
	bintoelf  -e 0x10000  -p 2  -b  <bootblk.img >bootblk.elf

bootblk: bootblk.o start64.o libobp.a
	ld -N -T 10000 -o bootblk start64.o bootblk.o libobp.a -lc
	cp bootblk bootblk.syms
	strip bootblk

bootblk.o: bootblk.c
	${CC} ${CFLAGS} -c bootblk.c

bootfd: bootblk
	dd if=bootblk of=/dev/rfd0 obs=512 seek=1 ibs=7680 conv=sync

# This is an easy way to get an image of a sun label sector - format
# a floppy disk with a Sun label and just read back the label sector
# into a file.

fdlabel:
	fdformat
	dd </dev/rfd0 count=1 >fdlabel

# Binary to ELF converter program

bintoelf: bintoelf.c
	${CC} -o bintoelf bintoelf.c


clean:
	rm *~ *.o

dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/sparc/*.c lib/sparc/*.s lib/sparc/makefile hello)

