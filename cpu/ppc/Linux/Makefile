# Flags for the simulator version
WRAPPER = pforth
OPT = -O
# OPT =
CFLAGS = -DUNIX -DSYS5 -DSIM -DPOWERPC -DARGREGS -DSIMNEXT

CC = gcc

WRDIR = ${BP}/forth/wrapper
ZIPDIR = ${WRDIR}/zip
SIMDIR = ../ppcsim

ZIPOBJS = zipmem.o deflate.o trees.o bits.o util.o inflate.o

OBJS = wrapper.o ppcsim.o logger.o ${ZIPOBJS}
TRACEOBJS = wrapper.o ppcsim.trace.o logger.o ${ZIPOBJS}
SIMROMOBJS = simrom.o ppcsim.simrom.o

all: ppcforth ppcforth.trace

ppcforth: $(OBJS)
	$(CC) $(LFLAGS)  $(OBJS)  -o $@

ppcforth.trace: $(TRACEOBJS)
	$(CC) $(LFLAGS)  $(TRACEOBJS)  -o $@

simrom: $(SIMROMOBJS)
	$(CC) $(LFLAGS)  $(SIMROMOBJS)  -o $@

%.o: ${WRDIR}/%.c
	${CC} -c ${CFLAGS} $< -o $@

%.o: ${ZIPDIR}/%.c
	${CC} -c ${CFLAGS} -I${ZIPDIR} $< -o $@

ppcsim.o: $(SIMDIR)/ppcsim.c
	$(CC) $(OPT) $(CFLAGS) -c $< -o $@

ppcsim.trace.o: $(SIMDIR)/ppcsim.c
	$(CC) $(OPT) $(CFLAGS) -DTRACE -c $< -o $@

ppcsim.simrom.o: $(SIMDIR)/ppcsim.c
	$(CC) $(CFLAGS) -DTRACE -DSIMROM -c $< -o $@

simrom.o: $(SIMDIR)/simrom.c
	$(CC) $(CFLAGS) -DTRACE -DSIMROM -c $< -o $@

clean:
	@rm -f *.o ppcforth ppcforth.trace

FRC:
