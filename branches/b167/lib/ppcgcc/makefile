# This makefile has been tested on an MkLinux system with GCC

# -fno-builtin has the effect of suppressing some warnings about
# functions that conflict with gcc builtins
CC=gcc
CFLAGS=-I.. -O -g -fno-builtin

all: libobp.a hello start.o

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

wrappers.o: ../wrappers.c
	${CC} ${CFLAGS} -c ../wrappers.c

malloc.o: ../malloc.c
	${CC} ${CFLAGS} -c ../malloc.c

# Build processor-specific startup code and call gateway

start.o: start.c
	${CC} ${CFLAGS} -c start.c

# Hello is a demo program that uses the stdio library

hello: libobp.a start.o hello.o
	ld -Bstatic -oformat elf32-powerpc -T ofclient.lds -Ttext 0x100000 -o hello start.o hello.o -L. -lobp

hello.o: ../../hello/hello.c
	${CC} ${CFLAGS} -c ../../hello/hello.c

clean:
	rm -f *~ *.o hello* *.a


dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/ppcgcc/*.c lib/ppcgcc/*.lds lib/ppcgcc/makefile hello)
