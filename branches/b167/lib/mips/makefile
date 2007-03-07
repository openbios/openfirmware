CC=gcc
CFLAGS=-I.. -fno-builtin -nostdlib -nostartfiles

# To build a version of the library for use on Open Firmware
CELLSIZE=

all: libobp.a start.o

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

# Build MAJC-specific startup code and call gateway

start.o: start.s
	as start.s -o start.o

# Hello is a demo program that uses the low level direct firmware calls

hello: hello.o ${all}
	ld -N -Thello.map -noinhibit-exec -e _start hello.o ${all} -o hello

hello.o: hello.c
	${CC} ${CFLAGS} -c hello.c

clean:
	rm *~ *.o

dist:
	(cd ../..; tar cf /tmp/lib.tar lib/*.c lib/*.h lib/mips/*.c lib/mips/*.s lib/mips/makefile)

