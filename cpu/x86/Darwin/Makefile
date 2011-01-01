# Wrapper makefile for x86 Mac OS X / Darwin

BP=../../..

CFLAGS	= -g -m32 -DTARGET_X86

# Extra CFLAGS needed by Darwin hosts. GCC doesn't define __unix__ here,
# so we must include it ourselves.
CFLAGS += -D__unix__=1 -Wimplicit-function-declaration
#CFLAGS += -DUSE_XCB

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

# Apple's GCC is a bit brain-dead. It's probably best to install gcc43 and
# binutils from macports. See http://macports.macforge.net for how to install
# and use macports. At the very least, binutils from macports seems to be
# required.

# The default compiler on Mac OS X (as of 10.5 anyway) does not honor -fpic.
# GCC will warn about -fpic not being supported, assumes you meant -fPIC,
# and switches to that. That should be okay, but if you're concerned about it
# I'm providing this already defined override for ${CC}. To use it, just 
# uncomment it, or pass CC= on the command line. This is here to make things
# easier for us lazy people.
#CC = /opt/local/bin/gcc-mp-4.3

# Unfortunately, Mac OS X does not ship with objcopy. This means that one must
# install binutils from macports, so we override the OBJCOPY variable here
# and just use that instead of calling 'objcopy' itself.
OBJCOPY = /opt/local/bin/gobjcopy

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth x86forth ../build/inflate.bin

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: ${OBJS}
	${CC} -m32 -o $@ ${OBJS}
	@ln -sf forth x86forth

# Compile with -O0 because with GCC4, higher optimization levels cause the
# functions to be reordered so the "inflate" entry point is no longer at
# the beginning.
inflate.o: ${ZIPDIR}/inflate.c
	${CC} -c -m32 -O0 -fpic $< -o $@

# Well, we're not going to get objcopy in a generic OS X environment, so
# let's just fake it.
../build/inflate.bin: inflate.o
	# ${OBJCOPY} -O binary $< $@
	dd if=$< of=$@ bs=256 skip=1

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

clean:
	@rm -f forth x86forth *.o *~ inflate.bin
