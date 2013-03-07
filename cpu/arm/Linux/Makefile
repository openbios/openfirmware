# Wrapper makefile for ARM Linux

BP=../../..

CFLAGS = -O -DARM -mlittle-endian

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = adler32.o compress.o crc32.o deflate.o inflate.o trees.o zutil.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth ../build/inflate.bin

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use armforth when you need to compile new dictionaries that will
# run on ARM systems.
forth: armforth
	@ln -sf armforth forth

armforth: ${OBJS}
	${CC} ${CFLAGS} ${LFLAGS} -o $@  ${OBJS}

# This staticly-linked wrapper is used by cpu/x86/Linux/armforth for cross-building
# with the help of QEMU.
armforth.static: ${OBJS}
	${CC} ${CFLAGS} ${LFLAGS} -static -o $@  ${OBJS}

xinflate.lo: ${ZIPDIR}/inflate.c
	${CC} -c ${CFLAGS} -O $< -o $@

xinflate.o: xinflate.lo
	${LD} -T inflate.ld $< -o $@

../build/inflate.bin: xinflate.o
	objcopy -O binary $< $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f ${OBJS} forth armforth
