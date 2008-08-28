# Makefile for MicroEMACS 3.7 for use with Forthmacs/386.  To compile EMACS
# for inclusion in the Zortech protected-mode loader (forth.exe), type:
#
#    make objects
#
# It is also possible to compile MicroEMACS by itself, without including it
# in the Forth loader.  To do so, type:
#
#    make emacs.exe
#
# If you make emacs.exe, you must re-make "objects" before attempting to
# recompile the Forth loader (in the dos/zortech directory), because the
# main.obj file is different when compiled for self-contained emacs.exe
# than when compiled for use with Forth (in particular, it does not have a
# main() routine when compiled for Forth - the Forth loader supplies main())

CFLAGS=		-mx -p
CC=		ztc
LFLAGS= 	-mx
LD=		ztc

HFILES=		estruct.h edef.h efunc.h epath.h ebind.h evar.h

OFILES=     	ansi.obj basic.obj   bind.obj     buffer.obj  display.obj  \
		exec.obj     file.obj    fileio.obj ibmpc.obj  \
		input.obj   isearch.obj  line.obj    lock.obj   \
		random.obj  region.obj   search.obj  spawn.obj  termio.obj  \
		window.obj  word.obj

config.h:	config.zth
		cp config.zth config.h

objects:	$(OFILES) config.h
		$(CC) $(CFLAGS) -DNOMAIN -c main.c

emacs.exe:	$(OFILES)
		$(CC) $(CFLAGS) -c main.c
		$(LD) $(LFLAGS) -o $@ *.obj

basic.obj:	basic.c

bind.obj:	bind.c

buffer.obj:	buffer.c

display.obj:	display.c

exec.obj:	exec.c

file.obj:	file.c

fileio.obj:	fileio.c

ibmpc.obj:	ibmpc.c

input.obj:	input.c

isearch.obj:	isearch.c

line.obj:	line.c

lock.obj:	lock.c

random.obj:	random.c

region.obj:	region.c

search.obj:	search.c

spawn.obj:	spawn.c

termio.obj:	termio.c

window.obj:	window.c

word.obj:	word.c

.C.OBJ:
		$(CC) $(CFLAGS) -c $*
