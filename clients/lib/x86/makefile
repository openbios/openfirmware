# This makefile has been tested on a FreeBSD 2.2.5 system with GCC

# -fno-builtin has the effect of suppressing some warnings about
# functions that conflict with gcc builtins
CC=gcc
CFLAGS=-g -m32 -fno-builtin -fno-stack-protector

all: libobp.a hello hello.elf start.o

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

wrappers.o: ../wrappers.c
	${CC} ${CFLAGS} -c ../wrappers.c

malloc.o: ../malloc.c
	${CC} ${CFLAGS} -c ../malloc.c

# Build processor-specific startup code and call gateway

start.o: start.s
	${CC} ${CFLAGS} -c start.s

# Hello is a demo program that uses the stdio library

hello.elf: libobp.a start.o hello.o
	ld -melf_i386 -Bstatic -N -Ttext 0x100000 -o $@ start.o hello.o libobp.a -lc
	cp hello.elf hello.syms
	strip hello.elf

hello.o: ../../hello/hello.c
	${CC} ${CFLAGS} -c ../../hello/hello.c

hello: hello.o
	${CC} -m32 $< -o $@

# Binary to ELF converter program

bintoelf: ../bintoelf.c
	${CC} -o bintoelf ../bintoelf.c


clean:
	rm *~ *.o hello* *.a


dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/x86/*.s lib/x86/makefile hello)
