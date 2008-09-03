# Makefile for MicroEMACS 3.7 for use with Open Firmware.
# 
# To make emacs, type:	make emacs
#	      or just: make	
#

BP=../../..
SRCDIR=..
HLIBDIR=$(BP)/clients/lib
LIBDIR=$(HLIBDIR)/x86

INCS=-I. -I$(SRCDIR) -I$(HLIBDIR)
MODES=-g -m32 -fno-builtin -fno-stack-limit -fno-stack-protector
CFLAGS= $(INCS) $(MODES)

CC=		gcc
LFLAGS= 	-T emacs.lds -N -e _start
LD=		ld

HFILES=		../estruct.h edef.h efunc.h epath.h ebind.h

OFILES=     	ansi.o  basic.o  bind.o  buffer.o  display.o  \
		exec.o  file.o  fileio.o  \
		input.o  isearch.o  line.o  lock.o  main.o \
		random.o  region.o   search.o  spawn.o  termio.o  \
		window.o  word.o

LIBS=		$(LIBDIR)/libobp.a

emacs:	$(LIBDIR)/start.o $(OFILES) $(LIBS) Makefile
	$(LD) $(LFLAGS) -o $@ $(LIBDIR)/start.o $(OFILES) $(LIBS)
	@# size $@
	@# nm -n $@ >emacs.nm
	@strip $@

$(LIBDIR)/start.o:	$(LIBDIR)/start.s
	(cd $(LIBDIR); make start.o)

$(LIBDIR)/libobp.a:	$(HLIBDIR)/lib.c
	(cd $(LIBDIR); make libobp.a)

%.o:$(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $<

main.o: $(SRCDIR)/ebind.h

clean:
	-rm -f *.o *.a emacs
