OS := $(shell uname)
BASEDIR= `(cd ../../../../..; pwd;)`
TAGFILES= ../../../build/*.tag *.tag
CLIENTDIR=../../../../../clients
CLIENTPROGS=${CLIENTDIR}/memtest86/memtest

all: neptune.rom tags

fw.tag: neptune.rom

tags: fw.tag
	@${BASEDIR}/forth/lib/toctags ${BASEDIR} ${TAGFILES}

neptune.rom: FORCE build ../../../build/inflate.bin ${CLIENTPROGS}
	./build $@

../../../${OS}/forth:
	@make -C ../../../${OS} forth

../../../build/inflate.bin:
	@make -C ../../../build inflate.bin

${CLIENTDIR}/memtest86/memtest:
	@make -C ${CLIENTDIR}/memtest86 memtest

build: ../../../${OS}/forth
	@ln -sf ../../../${OS}/forth build

clean:
	rm -f *.dic *.log headers *~ *.elf *.di *.img builton.fth build neptune.rom

clean-all: clean
	@make -C ../../../build clean
	@make -C ../../../${OS} clean
	@make -C ../../../../../clients/memtest86 clean
	@make -C ../../../../../clients/ispvme clean

.PHONY: FORCE clean all clean-all
