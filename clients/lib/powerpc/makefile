CC=cc
CFLAGS=-I..

libobp.a: lib.o wrappers.o malloc.o
	ar rcv libobp.a lib.o malloc.o wrappers.o

lib.o: ../lib.c
	${CC} ${CFLAGS} -c ../lib.c

wrappers.o: ../wrappers.c
	${CC} ${CFLAGS} -c ../wrappers.c

malloc.o: ../malloc.c ../malloc.h
	${CC} ${CFLAGS} -c ../malloc.c

start.o: start.S
	as -o start.o   -l -s -m ppc   start.S

clean:
	rm *~ *.o
