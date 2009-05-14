OS := $(shell uname)

BASEDIR= `(cd ../../../../..; pwd;)`
TAGFILES= ../../../build/*.tag *.tag
CLIENTDIR=../../../../../clients
CLIENTPROGS=memtest ${CLIENTDIR}/emacs/x86/emacs

all: olpc.rom tags

fw.tag: olpc.rom

tags: fw.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

ofw.elf: FORCE build ../../../build/inflate.bin
	./build $@

olpc.rom: FORCE build ../../../build/inflate.bin ${CLIENTPROGS}
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

memtest:
	make -C ${CLIENTDIR}/memtest86 VARIANT=OLPCGEODE memtest
	@mv ${CLIENTDIR}/memtest86/memtest .
	@make -C ${CLIENTDIR}/memtest86 clean

${CLIENTDIR}/emacs/x86/emacs:
	@make -C ${CLIENTDIR}/emacs/x86 emacs

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.rom ec.version olpc.version

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean

.PHONY: FORCE clean all clean-all
