CC=/mbin/mgcc
CFLAGS=-I.. -g -fno-builtin -nostdlib -Wlib-calls 

# To build a version of the library for use on Open Firmware
CELLSIZE=

all: libobp.a start.o

# Create a library file containing all the library routines

libobp.a: lib.o printf.o wrappers.o malloc.o strings.o printf.o debug.o main.o intprop.o regprop.o strprop.o mem.o
        /mbin/mar rcv libobp.a lib.o malloc.o wrappers.o strings.o printf.o debug.o main.o intprop.o regprop.o strprop.o mem.o
        /mbin/mranlib libobp.a

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
	/mbin/mas start.s -o start.o

# Bootblk is a demo program that uses the low level direct firmware calls

bootblk: bootblk.o ${all}
	/mbin/mld -N -Tdummy.map bootblk.o ${all} -o bootblk.elf
        /fw/l/arch/quasimodo/q-sys/build/bin2obj bootblk.elf bootblk.img
        /mbin/mld -Ttext=20000 -o bootblk bootblk.img
#	/mbin/mld -N -Ttext 10000 bootblk.o ${all} -o bootblk

bootblk.o: bootblk.c
	${CC} ${CFLAGS} -c bootblk.c

bootfd: bootblk
	dd if=bootblk of=/dev/rfd0 obs=512 seek=1 ibs=7680 conv=sync

clean:
	rm *~ *.o

dist:
	(cd ../..; tar cf /tmp/lib.tar lib/*.c lib/*.h lib/majc/*.c lib/majc/*.s lib/majc/makefile)

