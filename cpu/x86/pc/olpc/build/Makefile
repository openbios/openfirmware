OS := $(shell uname)

BASEDIR= `(cd ../../../../..; pwd;)`
TAGFILES= ../../../build/*.tag *.tag

all: olpc.rom tags

fw.tag: olpc.rom

tags: fw.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

ofw.elf: FORCE build ../../../build/inflate.bin
	./build $@

olpc.rom: FORCE build ../../../build/inflate.bin ../../../../../clients/memtest86/memtest
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

../../../../../clients/memtest86/memtest:
	@make -C ../../../../../clients/memtest86 memtest

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build *.rom ec.version olpc.version

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean

.PHONY: FORCE clean all clean-all
