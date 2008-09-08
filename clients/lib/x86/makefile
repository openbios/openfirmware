# This makefile has been tested on a FreeBSD 2.2.5 system with GCC

# -fno-builtin has the effect of suppressing some warnings about
# functions that conflict with gcc builtins
CC=gcc
CFLAGS=-g -m32 -fno-builtin -fno-stack-limit -fno-stack-protector

all: libobp.a hello hello.elf start.o

# Create a library file containing all the library routines

OBJS=lib.o printf.o wrappers.o malloc.o strings.o printf.o debug.o main.o intprop.o regprop.o strprop.o mem.o callofw.o

libobp.a: ${OBJS}
	ar rcv libobp.a ${OBJS}
	ranlib libobp.a

# Build machine-independent library routines

%.o: ../%.c
	${CC} ${CFLAGS} -c $<

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
	rm -f *~ *.o hello* *.a


dist:
	(cd ../..; tar cfh /tmp/lib.tar lib/*.c lib/*.h lib/x86/*.s lib/x86/makefile hello)
