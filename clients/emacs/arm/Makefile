# Makefile for MicroEMACS 3.7 for use with Open Firmware.
# 
# To make emacs, type:	make emacs
#	      or just: make	
#

TOOLPREFIX=/usr/local/arm/bin/arm-linux-
CC=$(TOOLPREFIX)gcc
LD=$(TOOLPREFIX)ld
STRIP=$(TOOLPREFIX)strip

BP=../../..
SRCDIR=..
HLIBDIR=$(BP)/clients/lib
LIBDIR=$(HLIBDIR)/arm
GLIBDIR=$(dir $(shell $(CC) -print-libgcc-file-name))

INCS=-I. -I$(SRCDIR) -I$(HLIBDIR)
MODES=-g -O2 -fno-inline
CFLAGS= $(INCS) $(MODES)

LFLAGS= 	-T emacs.lds -N -e _start

HFILES=		../estruct.h edef.h efunc.h epath.h ebind.h

OFILES=     	ansi.o  basic.o  bind.o  buffer.o  display.o  \
		exec.o  file.o  fileio.o  \
		input.o  isearch.o  line.o  lock.o  main.o \
		random.o  region.o   search.o  spawn.o  termio.o  \
		window.o  word.o

LIBS=		$(LIBDIR)/libobp.a

emacs:	emacs.elf
	@$(STRIP) $< -o $@
	@rm emacs.elf

emacs.elf: $(LIBDIR)/start.o $(OFILES) $(LIBS) Makefile emacs.lds
	$(LD) $(LFLAGS) -o $@ $(LIBDIR)/start.o $(OFILES)  $(LIBS) -L$(GLIBDIR) -lgcc

	@# size $@
	@# nm -n $@ >emacs.nm

$(LIBDIR)/start.o:	$(LIBDIR)/start.s
	(cd $(LIBDIR); make start.o)

$(LIBDIR)/libobp.a:	$(HLIBDIR)/lib.c
	(cd $(LIBDIR); make libobp.a)

%.o:$(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $<

main.o: $(SRCDIR)/ebind.h

clean:
	-rm -f *.o *.a emacs
