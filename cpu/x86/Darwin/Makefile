# Wrapper makefile for x86 Mac OS X / Darwin

BP=../../..

# Flags for the OS and CPU
MFLAGS = -m32

OPT = -O
CFLAGS	= -g $(MFLAGS) -DTARGET_X86
LFLAGS  = $(MFLAGS)

# Extra CFLAGS needed by Darwin hosts. GCC doesn't define __unix__ here,
# so we must include it ourselves.
CFLAGS += -D__unix__=1 -Wimplicit-function-declaration
SIMCFLAGS += -D__unix__=1 -Wimplicit-function-declaration

WRTAIL = forth/wrapper
WRDIR = ${BP}/${WRTAIL}

ifdef OMIT_ZIP
ZIPDIR = ${WRDIR}
ZIPOBJS = nullzip.o
INFLATEBIN =
else
ZIPTAIL = ${WRTAIL}/zip
ZIPDIR = ${BP}/${ZIPTAIL}

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o
INFLATEBIN = ../../build/inflate.bin

# Compile with -O0 because with GCC4, higher optimization levels cause the
# functions to be reordered so the "inflate" entry point is no longer at
# the beginning.
inflate.o: ${ZIPDIR}/inflate.c
	${CC} -c ${MFLAGS} -O0 -fpic $< -o $@

# Well, we're not going to get objcopy in a generic OS X environment, so
# let's just fake it.
../build/inflate.bin: inflate.o
	dd if=$< of=$@ bs=256 skip=1
endif

OBJS = wrapper.o logger.o ${ZIPOBJS}

all: forth x86forth ${INFLATEBIN}

# Use forth when you just need to run Forth but don't care what
# native instruction set it is on.
# Use x86forth when you need to compile new dictionaries that will
# run on x86 systems.
forth: ${OBJS}
	${CC} $(MFLAGS) -o $@ ${OBJS}
	@ln -sf forth x86forth

%.o: ${WRDIR}/%.c
	${CC} -c ${OPT} ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${OPT} ${CFLAGS} -I${ZIPDIR} $< -o $@

# ARM simulator wrapper build rules

ARMDIR = ${BP}/cpu/arm
ARMCFLAGS = -g ${MFLAGS} -DARMSIM -DTARGET_ARM -DARM -DSIMNEXT
ARMSIMOBJS = wrapsim.o armsim.o logger.o ${ZIPOBJS}
ARMTRACEOBJS = wrapsim.o armsim.trace.o logger.o ${ZIPOBJS}

# Extra CFLAGS needed by Darwin hosts. GCC doesn't define __unix__ here,
# so we must include it ourselves.
ARMCFLAGS += -D__unix__=1 -Wimplicit-function-declaration

%.o: ${ARMDIR}/%.c
	${CC} -c ${ARMCFLAGS} $< -o $@

wrapsim.o: ${WRDIR}/wrapper.c
	${CC} -c ${ARMCFLAGS} -c $< -o $@

armsim.trace.o: $(ARMDIR)/armsim.c
	${CC} -c ${ARMCFLAGS} -DTRACE=1 -c $< -o $@

armforth: ${ARMSIMOBJS}
	${CC} ${LFLAGS} ${ARMSIMOBJS} -o $@

armforth.trace: ${ARMTRACEOBJS}
	${CC} ${LFLAGS} ${ARMTRACEOBJS}  -o $@

clean:
	@rm -f forth x86forth armforth *.o *~ inflate.bin
