# Wrapper makefile for x86 Unix: FreeBSD, Linux, etc.

BP=../../..

CFLAGS	= -O -g -m32 -DTARGET_X86

# Uncomment these lines to include X windows support to the wrapper
# via libxcb.  The libxcb development package (headers, etc) must be
# present on your compilation machine for this to work.
# CFLAGS += -DUSE_XCB
# LIBS += -lxcb
# OBJS += xcbifce.o

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o

OBJS += wrapper.o logger.o ${ZIPOBJS}

all: forth x86forth ../build/inflate.bin

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: ${OBJS}
	${CC} -m32 -o $@ ${OBJS} ${LIBS}
	@ln -sf forth x86forth

inflate.lo: ${ZIPDIR}/inflate.c
	${CC} -c -m32 -Wall -fno-stack-protector -ffreestanding -D_FORTIFY_SOURCE=0 -DNEED_BCOPY -O3 -fpic $< -o $@

inflate.o: inflate.lo
	${LD} -T inflate.ld $< -o $@

../build/inflate.bin: inflate.o
	objcopy -O binary $< $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f forth x86forth *.o *~ inflate.bin
